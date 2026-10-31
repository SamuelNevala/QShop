"""UI-005: native theme surfaces, system bars and checked contrast, with isolated data.

Requires Pillow. Tests Light/Dark, both real Android System modes and an open IME.
Pixel ranges allow the deliberate 20% wallpaper contribution to each surface.
"""

import argparse
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


PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-safeborder"))
    parser.add_argument("--profile", choices=("all", "light", "dark", "system_light", "system_dark",
                                             "keyboard_light", "light_on_dark_system"), default="all")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree():
        for _ in range(3):
            shell("rm", "-f", "/sdcard/qshopper-safeborder.xml")
            if "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-safeborder.xml"):
                return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-safeborder.xml"))
        raise RuntimeError("Could not read current Android UI")

    def bounds(node):
        return tuple(map(int, re.findall(r"-?\d+", node.attrib["bounds"])))

    def rows(ui):
        return sorted({bounds(n) for n in ui.iter("node") if n.get(
            "resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
            and bounds(n)[3] > bounds(n)[1]}, key=lambda rect: rect[1])

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def tap(node):
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    results = []

    def check(name, passed, **details):
        results.append(dict(profile=profile, case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + profile + "_" + name, flush=True)

    def surface(name, point, light):
        rgb = image.getpixel(tuple(map(int, point)))
        check(name, min(rgb) >= 180 if light else max(rgb) <= 100, rgb=rgb, expected_light=light)

    def status_icons(name, light, top):
        clock = [sum(image.getpixel((x, y))) / 3
                 for x in range(int(width * 0.04), int(width * 0.22), 2)
                 for y in range(int(top * 0.25), int(top * 0.8), 2)]
        check(name, min(clock) < 100 if light else max(clock) > 180,
              minimum=min(clock), maximum=max(clock))

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    old_mode = shell("cmd", "uimode", "night").rsplit(":", 1)[-1].strip()
    assert old_mode in ("auto", "yes", "no"), "Cannot safely restore the current emulator night mode"
    profiles = [("light", "Light", "no", True, False),
                ("dark", "Dark", "no", False, False),
                ("system_light", "System", "no", True, False),
                ("system_dark", "System", "yes", False, False),
                ("keyboard_light", "Light", "no", True, True),
                ("light_on_dark_system", "Light", "yes", True, False)]
    if args.profile != "all":
        profiles = [item for item in profiles if item[0] == args.profile]
    with tempfile.TemporaryDirectory(prefix="qshopper-safeborder-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
            db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
            db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, ?)',
                           [(str(uuid.uuid4()), "Milk", 0), (str(uuid.uuid4()), "Bread", 1)])
            db.commit()
        staging = "/data/local/tmp/qshopper-safeborder-" + uuid.uuid4().hex + ".sqlite"
        adb("push", fixture, staging)
        try:
            for profile, theme, night, light, keyboard in profiles:
                folder = args.output / profile
                folder.mkdir(parents=True, exist_ok=True)
                shell("am", "force-stop", PACKAGE)
                shell("cmd", "uimode", "night", night)
                data = f"/data/user/0/{PACKAGE}/files/agent-testing/safeborder-{uuid.uuid4().hex}"
                (folder / "data-path.txt").write_text(data, encoding="utf-8")
                shell("run-as", PACKAGE, "mkdir", "-p", data)
                shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
                shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                      "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                # A scheme change or a just-installed APK can delay the first
                # accessible frame. Wait for the fixture, not a fixed launch delay.
                ui = None
                for _ in range(6):
                    try:
                        ui = tree()
                    except RuntimeError:
                        ui = None
                    if ui is not None and len(rows(ui)) == 2:
                        break
                    time.sleep(0.3)
                assert ui is not None and len(rows(ui)) == 2, "Shopping fixture did not load"
                raw = adb("exec-out", "screencap", "-p")
                width, height = Image.open(BytesIO(raw)).size
                assert width < height and len(rows(ui)) == 2, "Portrait fixture did not load"
                first = rows(ui)[0]
                shell("input", "swipe", width // 2, (first[1] + first[3]) // 2,
                      width // 2, height - 120, 1200)
                ui = tree()
                field = editor(ui)
                assert field is not None, "Could not enter edit mode"
                left, top, right, bottom = bounds(field)
                shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
                ui = tree()
                button = [n for n in ui.iter("node") if n.get("class") == "android.widget.Button"
                          and n.get("content-desc") == theme]
                assert len(button) == 1, "Theme button was not found: " + theme
                tap(button[0])
                shell("input", "tap", int(width * 0.98), height // 2)
                ui = tree()
                if keyboard:
                    tap(editor(ui))
                    time.sleep(0.5)
                    ui = tree()
                    check("native_keyboard_open", "mInputShown=true" in shell("dumpsys", "input_method"))
                display = shell("dumpsys", "window", "displays")
                (folder / "display.txt").write_text(display, encoding="utf-8")
                top_safe, bottom_safe = 0, height
                for kind, a, b, c, d in re.findall(
                        r"type=(statusBars|navigationBars|ime) frame=\[(\d+),(\d+)\]\[(\d+),(\d+)\][^\n]*visible=true", display):
                    a, b, c, d = map(int, (a, b, c, d))
                    if kind == "statusBars":
                        top_safe = max(top_safe, d)
                    elif kind == "navigationBars" or keyboard:
                        bottom_safe = min(bottom_safe, b)
                assert top_safe > 0 and bottom_safe < height, "Native system bar frames were not found"
                image = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
                image.save(folder / "surfaces.png")
                (folder / "ui.xml").write_bytes(ET.tostring(ui))
                visible = rows(ui)
                assert len(visible) == 2, "The fixture rows are not available"
                normal, checked = visible
                surface("normal_surface", (normal[2] - 20, (normal[1] + normal[3]) / 2), light)
                surface("checked_contrast", (checked[2] - 20, (checked[1] + checked[3]) / 2), not light)
                surface("top_border", (width * 0.63, top_safe * 0.6), light)
                status_icons("status_icon_contrast", light, top_safe)
                if not keyboard:
                    surface("bottom_border", (width * 0.88, bottom_safe + 15), light)
                check("content_in_safe_area", bounds(editor(ui))[1] >= top_safe - 2
                      and checked[3] <= bottom_safe + 2, top=top_safe, bottom=bottom_safe)
                if profile == "system_light":
                    shell("cmd", "uimode", "night", "yes")
                    time.sleep(0.7)
                    ui = tree()
                    image = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
                    image.save(folder / "live_system_dark.png")
                    normal, checked = rows(ui)
                    surface("live_system_dark_normal", (normal[2] - 20, (normal[1] + normal[3]) / 2), False)
                    surface("live_system_dark_checked", (checked[2] - 20, (checked[1] + checked[3]) / 2), True)
                    surface("live_system_dark_border", (width * 0.63, top_safe * 0.6), False)
                    status_icons("live_system_dark_icons", False, top_safe)
                if profile == "dark":
                    shell("input", "keyevent", "KEYCODE_HOME")
                    shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                          "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                    ui = tree()
                    image = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
                    image.save(folder / "resumed.png")
                    status_icons("resume_status_icon_contrast", False, top_safe)
                snapshot = folder / "saved.sqlite"
                snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
                with closing(sqlite3.connect(snapshot)) as db:
                    saved = db.execute(f'SELECT name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()
                check("items_preserved", saved == [("Milk", 0), ("Bread", 1)])
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("cmd", "uimode", "night", old_mode)
            shell("rm", staging)
    assert all(record["passed"] for record in results), "Native safe-border checks failed; see results.json"


if __name__ == "__main__":
    main()
