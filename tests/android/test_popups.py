"""UI-010 popup bounds and UI-001 initial/cold-restart list selection."""

import argparse
from contextlib import closing
import json
import math
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET


PACKAGE = "shopper.nevala.com"
DEFAULT = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-popups"))
    parser.add_argument("--selector", choices=("all", "lists", "accent", "primary"), default="all")
    parser.add_argument("--endpoint", choices=("all", "first", "last"), default="all")
    parser.add_argument("--matrix", action="store_true",
                        help="Also test a rotated-device request and a real keyboard resize")
    parser.add_argument("--profile", choices=("portrait", "keyboard_resize", "rotated"), default="portrait")
    parser.add_argument("--restart", action="store_true", help="UI-001: verify list selection after a cold restart")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    args.output.mkdir(parents=True, exist_ok=True)
    expected_rotation = 0

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree():
        # A failed dump can leave an old XML file; never accept that as current UI.
        for _ in range(3):
            shell("rm", "-f", "/sdcard/qshopper-popups.xml")
            result = shell("uiautomator", "dump", "/sdcard/qshopper-popups.xml")
            if "dumped to" in result:
                ui = ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-popups.xml"))
                assert int(ui.attrib["rotation"]) == expected_rotation, "Accessibility dump changed the requested rotation"
                return ui
        raise RuntimeError("Could not read the current Android UI")

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.attrib["bounds"])))

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@content-desc="Tap to add items"]')

    def tap(node):
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    def rotate(value):
        shell("wm", "user-rotation", "lock", value)
        # UI-011 keeps the phone app portrait even with a landscape user setting.
        # Verify actual bounds before UIAutomator can restore its captured rotation.
        time.sleep(0.5)
        for _ in range(20):
            width, height, actual = map(int, re.search(
                r"DisplayFrames w=(\d+) h=(\d+) r=(\d+)",
                shell("dumpsys", "window", "displays")).groups())
            if actual == expected_rotation and width < height:
                return width, height
            time.sleep(0.1)
        raise RuntimeError("The phone app did not remain portrait")

    def safe_rect():
        display = shell("dumpsys", "window", "displays")
        (case_dir / "display.txt").write_text(display)
        width, height = map(int, re.search(r"DisplayFrames w=(\d+) h=(\d+)", display).groups())
        left, top, right, bottom = 0, 0, width, height
        for kind, a, b, c, d in re.findall(
                r"InsetsSource .*?type=(statusBars|navigationBars|displayCutout) "
                r"frame=\[(\d+),(\d+)\]\[(\d+),(\d+)\] visible=true", display):
            a, b, c, d = map(int, (a, b, c, d))
            if c - a > d - b:
                if b == 0:
                    top = max(top, d)
                elif d == height:
                    bottom = min(bottom, b)
            else:
                if a == 0:
                    left = max(left, c)
                elif c == width:
                    right = min(right, a)
        assert top > 0 or left > 0, "No real system safe area was found"
        return left, top, right, bottom

    def capture(name, ui):
        (case_dir / (name + ".xml")).write_bytes(ET.tostring(ui))
        (case_dir / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))

    results = []

    def check(name, passed, ui, **details):
        capture(name, ui)
        results.append(dict(case=case_name + "_" + name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2))
        print(("PASS " if passed else "FAIL ") + case_name + "_" + name, flush=True)
        assert passed, case_name + "_" + name

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    old_auto = shell("settings", "get", "system", "accelerometer_rotation")
    old_rotation = shell("settings", "get", "system", "user_rotation")
    selectors = ("lists", "accent", "primary") if args.selector == "all" else (args.selector,)
    endpoints = ("first", "last") if args.endpoint == "all" else (args.endpoint,)
    profiles = [("portrait", 0, False), ("keyboard_resize", 0, True), ("rotated", 1, False)]
    if not args.matrix:
        profiles = [profile for profile in profiles if profile[0] == args.profile]

    with tempfile.TemporaryDirectory(prefix="qshopper-popups-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            for i in range(30):
                key = DEFAULT if i == 0 else str(uuid.uuid4())
                db.execute("INSERT INTO lists VALUES (?, ?, 0)",
                           (key, "default" if i == 0 else f"list {i:02d}"))
                db.execute(f'CREATE TABLE "{key}" ' + schema)
            db.executemany(f'INSERT INTO "{DEFAULT}" VALUES (?, ?, 0)',
                           [(str(uuid.uuid4()), "milk"), (str(uuid.uuid4()), "bread")])
            db.commit()
        staging = "/data/local/tmp/qshopper-popups-" + uuid.uuid4().hex + ".sqlite"
        adb("push", fixture, staging)
        try:
            shell("settings", "put", "system", "accelerometer_rotation", 0)
            for profile, rotation, with_keyboard in profiles:
                for selector in selectors:
                    for endpoint in endpoints:
                        case_name = f"{profile}_{selector}_{endpoint}"
                        case_dir = args.output / case_name
                        case_dir.mkdir(parents=True, exist_ok=True)
                        data = f"/data/user/0/{PACKAGE}/files/agent-testing/popups-{uuid.uuid4().hex}"
                        (case_dir / "data-path.txt").write_text(data)
                        shell("am", "force-stop", PACKAGE)
                        shell("run-as", PACKAGE, "mkdir", "-p", data)
                        shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
                        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                              "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                        width, height = rotate(0)
                        ui = tree()
                        rows = [bounds(n) for n in ui.iter("node")
                                if n.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")]
                        assert len(rows) == 2, "Shopping fixture did not load"
                        first = min(rows, key=lambda r: r[1])
                        shell("input", "swipe", width // 2, (first[1] + first[3]) // 2,
                              width // 2, height - 100, 1200)
                        time.sleep(0.7)
                        ui = tree()
                        field = editor(ui)
                        if rotation != 0:
                            # Request rotation with an existing editor; the app stays portrait.
                            width, height = rotate(rotation)
                            ui = tree()
                            field = editor(ui)
                        capture("edit_setup", ui)
                        assert field is not None, "Could not enter edit mode"
                        if with_keyboard:
                            tap(field)
                            for _ in range(20):
                                if "mInputShown=true" in shell("dumpsys", "input_method"):
                                    break
                                time.sleep(0.1)
                            assert "mInputShown=true" in shell("dumpsys", "input_method"), "Gboard did not open"
                        left, top, right, bottom = bounds(field)
                        shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
                        ui = tree()
                        assert "mInputShown=true" not in shell("dumpsys", "input_method"), "Drawer must hide keyboard"
                        # Find the actual selector while scrolling the drawer into view.
                        wanted = "Green" if selector == "accent" else "Indogo"
                        combo = None
                        safe = safe_rect()
                        for _ in range(8):
                            for node in ui.iter("node"):
                                if node.get("class") != "android.widget.Spinner":
                                    continue
                                is_color = "ColorComboBox_" in node.get("resource-id", "")
                                if (selector == "lists" and not is_color) or (
                                        selector != "lists" and node.get("content-desc") == wanted):
                                    rect = bounds(node)
                                    if rect[3] > rect[1] and rect[1] >= safe[1] and rect[3] <= safe[3]:
                                        combo = node
                            if combo is not None:
                                break
                            shell("input", "swipe", width // 3, safe[3] - 150,
                                  width // 3, safe[1] + 150, 400)
                            ui = tree()
                        assert combo is not None, "Selector was not reachable in drawer"
                        if selector == "lists":
                            check("initial_selection", combo.get("content-desc") == "default", ui)
                        combo_rect = bounds(combo)
                        tap(combo)
                        x = (combo_rect[0] + combo_rect[2]) // 2
                        start, end = safe[1] + (safe[3] - safe[1]) // 5, safe[3] - (safe[3] - safe[1]) // 5
                        if endpoint == "last":
                            start, end = end, start
                        # More than the total content length: reach the real scroll limit.
                        count = 31 if selector == "lists" else 19
                        row_height = bounds(field)[3] - bounds(field)[1]
                        for _ in range(math.ceil(count * row_height / abs(end - start)) + 1):
                            shell("input", "swipe", x, start, x, end, 250)
                        time.sleep(0.5)
                        ui = tree()
                        label = ("default" if endpoint == "first" else "lists") if selector == "lists" else (
                            "Red" if endpoint == "first" else "Blue grey")
                        candidates = [n for n in ui.iter("node") if "Popup" in n.get("resource-id", "")
                                      and (n.get("text") == label or n.get("content-desc") == label)
                                      and bounds(n)[3] > bounds(n)[1]]
                        assert len(candidates) == 1, "Could not locate the popup endpoint: " + label
                        row = candidates[0]
                        rect = bounds(row)
                        check("reachable", rect[0] >= safe[0] - 1 and rect[1] >= safe[1] - 1
                              and rect[2] <= safe[2] + 1 and rect[3] <= safe[3] + 1, ui,
                              row_bounds=rect, safe_bounds=safe)
                        tap(row)
                        ui = tree()
                        settings = shell("run-as", PACKAGE, "cat", data + "/Nevala/QShopper.ini")
                        (case_dir / "settings.ini").write_text(settings)
                        expected = (DEFAULT if endpoint == "first" else "00000000-0000-0000-0000-000000000000") if selector == "lists" else (
                            "0" if endpoint == "first" else "18")
                        key = "activeList" if selector == "lists" else selector
                        check("selected", re.search(rf"(?m)^{key}={re.escape(expected)}$", settings) is not None, ui)
                        snapshot = adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite")
                        (case_dir / "saved.sqlite").write_bytes(snapshot)
                        with closing(sqlite3.connect(case_dir / "saved.sqlite")) as db:
                            saved = db.execute(f'SELECT name,checked FROM "{DEFAULT}" ORDER BY rowid').fetchall()
                        check("items_preserved", saved == [("milk", 0), ("bread", 0)], ui)
                        if args.restart and selector == "lists":
                            shell("am", "force-stop", PACKAGE)
                            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                            time.sleep(1.5)
                            ui = tree()
                            rows = [bounds(n) for n in ui.iter("node") if n.get(
                                "resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                                and bounds(n)[3] > bounds(n)[1]]
                            assert rows, "Restart did not load shopping rows"
                            first = min(rows, key=lambda rect: rect[1])
                            shell("input", "swipe", width // 2, (first[1] + first[3]) // 2,
                                  width // 2, height - 100, 1200)
                            ui = tree()
                            field = editor(ui)
                            assert field is not None, "Restart did not enter edit mode"
                            left, top, right, bottom = bounds(field)
                            shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
                            ui = tree()
                            selected = [n for n in ui.iter("node") if n.get("class") == "android.widget.Spinner"
                                        and "ColorComboBox_" not in n.get("resource-id", "")]
                            check("restart_selection", len(selected) == 1
                                  and selected[0].get("content-desc") == label, ui)
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("rm", staging)
            shell("wm", "user-rotation", "lock", old_rotation)
            shell("settings", "put", "system", "accelerometer_rotation", old_auto)


if __name__ == "__main__":
    main()
