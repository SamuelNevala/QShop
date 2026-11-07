"""UX-003/UI-029/UI-030: native custom ink and thumb boundaries.

Uses real pulls, pressed editor controls and both license tabs with disposable data.
Requires Pillow and the rebuilt BackGesture helper. Emulator only.
"""

import argparse
from collections import Counter
from contextlib import closing
from io import BytesIO
import json
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET

from PIL import Image
from test_filledcontrast import PACKAGE, TABLE, fill_bounds, matches, ratio

PROFILES = {
    "yellow-light": (0, False, 12, (255, 235, 59), (255, 234, 0)),
    "purple-dark": (1, True, 2, (206, 147, 216), (224, 64, 251)),
    "deep-purple-light": (0, False, 3, (103, 58, 183), (101, 31, 255)),
    "yellow-dark": (1, True, 12, (255, 245, 157), (255, 255, 0)),
    "system-light": (2, False, 12, (255, 235, 59), (255, 234, 0)),
    "system-dark": (2, True, 3, (179, 157, 219), (124, 77, 255)),
}


def measure_ink(image, box, selected, surface, opacity):
    left, top, right, bottom = map(int, box)
    left, top = max(0, left), max(0, top)
    right, bottom = min(image.width, right), min(image.height, bottom)
    colors = Counter(image.crop((left, top, right, bottom)).getdata())
    # Locate actual opaque cores, accepting either original or adjusted ink.
    # This does not presume that the adjustment happened or provides contrast.
    candidates = {tuple(round(channel * .9 ** step + end * (1 - .9 ** step)) for channel in selected)
                  for end in (0, 255) for step in range(31)}
    ink = max(colors, key=lambda pixel: colors[pixel] if any(matches(pixel, c, 2) for c in candidates) else 0)
    assert colors[ink] >= 12 and any(matches(ink, c, 2) for c in candidates), "Opaque colored glyph missing"
    values = []
    for y in range(max(4, top), min(image.height - 4, bottom), 2):
        for x in range(max(4, left), min(image.width - 4, right), 2):
            if matches(image.getpixel((x, y)), ink, 1):
                for dx, dy in ((-4, 0), (4, 0), (0, -4), (0, 4)):
                    behind = image.getpixel((x + dx, y + dy))
                    if all(round(opacity * c) - 3 <= v <= round(opacity * c + (1 - opacity) * 255) + 3
                           for c, v in zip(surface, behind)):
                        values.append(ratio(ink, behind))
    assert len(values) >= 10, "Adjacent neutral surface pixels missing"
    return min(values), ink, colors[ink], len(values)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--profile", choices=("all", *PROFILES), default="all")
    parser.add_argument("--output", type=Path, default=Path("out/android-customcolors"))
    parser.add_argument("--gesture-jar", type=Path, default=Path("out/android-emulator/back-gesture/gesture.jar"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def tree():
        for _ in range(3):
            shell("rm", "-f", "/sdcard/qshopper-customcolors.xml")
            if "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-customcolors.xml"):
                raw = adb("exec-out", "cat", "/sdcard/qshopper-customcolors.xml")
                (args.output / "latest-ui.xml").write_bytes(raw)
                return ET.fromstring(raw)
        raise RuntimeError("Could not read a current UI tree")

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def named(ui, text):
        return next((node for node in ui.iter("node") if node.get("text") == text or node.get("content-desc") == text), None)

    def tap(node):
        assert node is not None
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    def screenshot(name):
        raw = adb("exec-out", "screencap", "-p")
        (args.output / (name + ".png")).write_bytes(raw)
        return Image.open(BytesIO(raw)).convert("RGB")

    def held(start_x, end_x, start_y, end_y, filename):
        command = f"CLASSPATH={helper} app_process /system/bin BackGesture {start_x} {end_x} {start_y} true 0 {end_y} -1"
        with subprocess.Popen([args.adb, "-s", args.serial, "shell", command], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as gesture:
            assert gesture.stdout.readline().strip() == b"HELD"
            time.sleep(.3)
            frame = screenshot(filename)
            gesture.stdin.write(b"\n")
            gesture.stdin.flush()
            gesture.wait(timeout=10)
        return frame

    def check(name, passed, **details):
        results.append(dict(case=profile + "-" + name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + results[-1]["case"], details, flush=True)

    def ink_check(name, frame, box, selected, surface, opacity, minimum):
        contrast, ink, cores, pairs = measure_ink(frame, box, selected, surface, opacity)
        check(name, contrast >= minimum, minimum=contrast, ink=ink, cores=cores, adjacentSamples=pairs)

    def saved():
        with tempfile.TemporaryDirectory(prefix="qshopper-custom-read-") as folder:
            path = Path(folder) / "saved.sqlite"
            path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
            with closing(sqlite3.connect(path)) as db:
                return [(str(uuid.UUID(identifier.strip("{}"))), text, flag)
                        for identifier, text, flag in db.execute(f'SELECT id,name,checked FROM "{TABLE}" ORDER BY rowid')]

    assert shell("getprop", "ro.kernel.qemu") == "1"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    original_night = re.search(r"(yes|no|auto)", shell("cmd", "uimode", "night")).group(1)
    helper = "/data/local/tmp/qshopper-customcolors-" + uuid.uuid4().hex + ".jar"
    adb("push", args.gesture_jar, helper)
    results = []
    profiles = PROFILES if args.profile == "all" else {args.profile: PROFILES[args.profile]}
    try:
        for profile, (theme, dark, family, primary, accent) in profiles.items():
            shell("am", "force-stop", PACKAGE)
            shell("cmd", "uimode", "night", "yes" if dark else "no")
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/customcolors-{uuid.uuid4().hex}"
            (args.output / (profile + "-data-path.txt")).write_text(data)
            entries = [(str(uuid.uuid4()), text, 0) for text in ("Milk", "Bread", "Coffee")]
            with tempfile.TemporaryDirectory(prefix="qshopper-custom-") as folder:
                fixture = Path(folder) / "shop_list.sqlite"
                with closing(sqlite3.connect(fixture)) as db:
                    schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                    db.execute("CREATE TABLE lists " + schema)
                    db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                    db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                    db.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)', entries)
                    db.commit()
                settings = Path(folder) / "QShopper.ini"
                settings.write_text(f"[General]\ntheme={theme}\nprimary={family}\naccent={family}\nswipeSensitivity=1\nactiveList={TABLE}\n")
                shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                for source, destination in ((fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")):
                    staging = "/data/local/tmp/qshopper-custom-" + uuid.uuid4().hex
                    adb("push", source, staging)
                    shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                    shell("rm", "-f", staging)
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity", "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            time.sleep(1)
            ui = tree()
            rows = sorted({bounds(node) for node in ui.iter("node") if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")})
            first = rows[0]
            row_height = first[3] - first[1]
            start_y = (first[1] + first[3]) // 2
            normal = (28, 27, 31) if dark else (255, 251, 254)
            inverse = (255, 251, 254) if dark else (28, 27, 31)
            image = held(width // 2, width // 2, start_y, height - 230, profile + "-pull")
            circle = fill_bounds(image, primary, (0, 100, width // 3, height * 2 // 3))
            left, top, right, bottom = circle
            diameter = bottom - top
            ink_check("day-name", image, (max(0, left - 20), top - diameter, right + 20, top), primary, normal, .8, 4.5)
            header_top = top - row_height * .55
            ink_check("armed-pulley", image, (width * .35, 145, width * .65, max(200, header_top)), accent, normal, .8, 3)
            time.sleep(.6)
            shell("input", "swipe", width // 2, start_y, width // 2, height - 140, 1200)
            ui = tree()
            field = ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')
            assert field is not None, "Edit mode did not open"
            left, top, right, bottom = bounds(field)
            size = bottom - top
            image = held(left + size // 2, left + size // 2, (top + bottom) // 2, (top + bottom) // 2, profile + "-pressed")
            ink_check("pressed-editor-icon", image, (left, top, left + size, bottom), accent, inverse, .8, 3)
            ui = tree()
            if named(ui, "Lists") is not None:
                shell("input", "keyevent", 4)
                time.sleep(.3)
            # Open with an ordinary tap after the separately held press capture.
            shell("input", "tap", left + size // 2, (top + bottom) // 2)
            ui = tree()
            slider = next(node for node in ui.iter("node") if node.get("class") == "android.widget.SeekBar")
            left, top, right, bottom = bounds(slider)
            diameter = row_height * 4 / 9.27
            x = round(left + diameter / 2 + (right - left - diameter) * (.8 / 2.8))
            y = round((top + bottom) / 2)
            image = screenshot(profile + "-slider")
            surface = image.getpixel((round(left + (right - left) * .8), top + 3))
            boundary = max(ratio(image.getpixel((x, round(y - diameter / 2) + offset)), surface) for offset in (1, 2, 3))
            check("slider-fill", matches(image.getpixel((x, y)), accent, 3))
            check("slider-boundary", boundary >= 3, minimum=boundary, surface=surface)
            # Independently exercise the normal keyboard -> drawer -> About path;
            # the earlier phase deliberately synthesizes a long held icon press.
            shell("am", "force-stop", PACKAGE)
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity", "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            time.sleep(1)
            ui = tree()
            rows = sorted({bounds(node) for node in ui.iter("node") if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")})
            first = rows[0]
            shell("input", "swipe", width // 2, (first[1] + first[3]) // 2, width // 2, height - 140, 1200)
            ui = tree()
            field = ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')
            tap(field)
            time.sleep(.7)
            left, top, right, bottom = bounds(field)
            shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
            ui = tree()
            shell("input", "swipe", width // 3, height * 3 // 4, width // 3, height // 3, 350)
            ui = tree()
            tap(named(ui, "Licenses"))
            screenshot(profile + "-about-open")
            ui = tree()
            for name in ("Qt", "Font Awesome"):
                node = named(ui, name)
                tap(node)
                time.sleep(.5)
                ui = tree()
                box = bounds(named(ui, name))
                image = screenshot(profile + "-" + name.replace(" ", "-"))
                ink_check("tab-" + name.replace(" ", "-"), image, box, accent, normal, 1, 4.5)
            shell("input", "keyevent", 4)
            check("data-preserved", saved() == entries)
    finally:
        shell("am", "force-stop", PACKAGE)
        shell("cmd", "uimode", "night", original_night)
        shell("rm", "-f", helper)
    assert all(row["passed"] for row in results), "Native custom-color regression failures"


if __name__ == "__main__":
    main()
