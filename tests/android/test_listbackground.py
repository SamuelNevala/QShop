"""UI-008: compare native rendered row backgrounds before/after real scrolling.

Requires Pillow. Uses only an isolated emulator and disposable app data.
The app's slideshow stays fixed during each timed screenshot pair, so the
right edge of unchecked rows must retain the same color at each screen pixel.
"""

import argparse
from contextlib import closing
import json
from pathlib import Path
import re
import sqlite3
import subprocess
import struct
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET

from PIL import Image


PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-listbackground"))
    parser.add_argument("--count", type=int, choices=(34, 35, 80), default=80)
    parser.add_argument("--keyboard", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree(name):
        for _ in range(3):
            shell("rm", "-f", "/sdcard/qshopper-background.xml")
            if "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-background.xml"):
                raw = adb("exec-out", "cat", "/sdcard/qshopper-background.xml")
                (args.output / (name + ".xml")).write_bytes(raw)
                return ET.fromstring(raw)
        raise RuntimeError("Could not read current Android UI")

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.attrib["bounds"])))

    visible_bottom = 100000

    def rows(ui):
        visible = set()
        for node in ui.iter("node"):
            if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_"):
                left, top, right, bottom = bounds(node)
                bottom = min(bottom, visible_bottom)
                if bottom > top and right > left:
                    visible.add((left, top, right, bottom))
        return sorted(visible, key=lambda rect: rect[1])

    def screenshot(name=None):
        # Raw capture avoids slow PNG compression on the emulator, keeping
        # both frames within one stationary slideshow image.
        raw = adb("exec-out", "screencap")
        width, height, pixel_format, _ = struct.unpack("<4I", raw[:16])
        assert pixel_format == 1 and len(raw) == 16 + width * height * 4, "Expected RGBA screenshot"
        image = Image.frombytes("RGBA", (width, height), raw[16:]).convert("RGB")
        if name:
            image.save(args.output / (name + ".png"))
        return image

    results = []

    def check(name, passed, **details):
        results.append(dict(case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        assert passed, name

    def saved():
        snapshot = args.output / "saved.sqlite"
        snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(snapshot)) as db:
            return db.execute(f'SELECT id,name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()

    def compare_rows(before, after, initial_rows, current_rows, name):
        # Stay away from text, editor icons, fractional row edges and system bars.
        changed = 0
        sampled = 0
        for left, top, right, bottom in current_rows:
            for y in range(top + 8, bottom - 8, 9):
                if any(start + 8 <= y < end - 8 for _, start, _, end in initial_rows):
                    for x in (right - 20, right - 25, right - 30):
                        error = max(abs(a - b) for a, b in zip(before.getpixel((x, y)), after.getpixel((x, y))))
                        changed += error > 3
                        sampled += 1
        check(name, sampled > 100 and changed / sampled < 0.02,
              changed=changed, sampled=sampled, changed_fraction=changed / max(1, sampled))

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    with tempfile.TemporaryDirectory(prefix="qshopper-background-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
            db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
            db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                           [(str(uuid.uuid4()), f"Item {i:02d}") for i in range(args.count)])
            db.commit()
        data = f"/data/user/0/{PACKAGE}/files/agent-testing/background-{uuid.uuid4().hex}"
        (args.output / "data-path.txt").write_text(data, encoding="utf-8")
        staging = "/data/local/tmp/qshopper-background-" + uuid.uuid4().hex + ".sqlite"
        adb("push", fixture, staging)
        shell("am", "force-stop", PACKAGE)
        shell("run-as", PACKAGE, "mkdir", "-p", data)
        shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
        try:
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            time.sleep(1.5)
            ui = tree("initial")
            initial = rows(ui)
            assert len(initial) > 3, "Shopping rows not loaded"
            original = saved()
            width, height = screenshot("launch").size
            assert width < height, "Use the portrait phone emulator"
            visible_bottom = height - 150
            initial = rows(ui)
            if args.keyboard:
                shell("input", "swipe", width // 2, (initial[0][1] + initial[0][3]) // 2,
                      width // 2, height - 120, 1200)
                ui = tree("edit")
                field = ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')
                assert field is not None, "Could not enter edit mode"
                left, top, right, bottom = bounds(field)
                shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
                time.sleep(0.6)
                check("native_keyboard_open", "mInputShown=true" in shell("dumpsys", "input_method"))
                ui = tree("keyboard")
                display = shell("dumpsys", "window", "displays")
                (args.output / "keyboard-display.txt").write_text(display, encoding="utf-8")
                ime = re.search(r"type=ime frame=\[0,(\d+)\]\[\d+,\d+\][^\n]*visible=true", display)
                assert ime, "Visible native IME inset was not found"
                visible_bottom = int(ime.group(1))
                initial = rows(ui)
                check("keyboard_reduces_available_area", visible_bottom < height * 0.8)
                screenshot("keyboard_open")
            # Observe an actual slideshow change, then its stable image. The
            # activity launch time is not the QML timer's start time.
            for direction in ("down", "up"):
                previous = screenshot()
                transition_seen = False
                for attempt in range(15):
                    candidate = screenshot()
                    probes = [(width - 25, y) for y in range(initial[0][1] + 20,
                              min(initial[-1][3] - 20, height - 150), 37)]
                    changed = sum(max(abs(a - b) for a, b in zip(previous.getpixel(point),
                                  candidate.getpixel(point))) > 3 for point in probes)
                    fraction = changed / len(probes)
                    transition_seen = transition_seen or fraction > 0.1
                    if transition_seen and fraction < 0.01:
                        before = candidate
                        break
                    previous = candidate
                else:
                    raise RuntimeError("Could not find a stable slideshow image after a transition")
                started = time.monotonic()
                top = max(initial[0][1] + 50, int(height * 0.15))
                bottom = min(initial[-1][3] - 50, int(height * 0.85))
                start, end = (bottom, top) if direction == "down" else (top, bottom)
                shell("input", "swipe", width // 2, start, width // 2, end, 120)
                time.sleep(1.5)
                after = screenshot()
                assert time.monotonic() - started < 4, "Screenshot pair exceeded the stable slideshow interval"
                # Encode files on the host after both frames have been captured.
                before.save(args.output / (direction + "_before.png"))
                after.save(args.output / (direction + "_after.png"))
                ui = tree(direction)
                current = rows(ui)
                assert len(current) > 3, "No shopping rows after scrolling"
                compare_rows(before, after, initial, current, direction + "_background_continuity")
                initial = current
            if args.keyboard:
                # Recycling the editor during a long scroll can already dismiss
                # the IME. Back with a closed IME has a different app action.
                if "mInputShown=true" in shell("dumpsys", "input_method"):
                    shell("input", "keyevent", "KEYCODE_BACK")
                    time.sleep(0.6)
                ui = tree("keyboard_hidden")
                screenshot("keyboard_hidden")
                visible_bottom = height - 150
                check("keyboard_hidden_and_rows_visible", "mInputShown=true" not in shell(
                    "dumpsys", "input_method") and rows(ui)[-1][3] > height * 0.8)
            check("scroll_preserves_items", saved() == original)
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("rm", staging)


if __name__ == "__main__":
    main()
