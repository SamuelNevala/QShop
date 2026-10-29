"""UI-011: portrait launch/rotation with real emulator sensors and auto-rotate."""

import argparse
from contextlib import closing
import json
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET


PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-portrait"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def display():
        state = shell("dumpsys", "window", "displays")
        geometry = re.search(r"DisplayFrames w=(\d+) h=(\d+) r=(\d+)", state)
        return tuple(map(int, geometry.groups())), state

    def tree():
        for _ in range(3):
            shell("rm", "-f", "/sdcard/qshopper-portrait.xml")
            if "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-portrait.xml"):
                return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-portrait.xml"))
        raise RuntimeError("Could not read current Android UI")

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.attrib["bounds"])))

    def keyboard():
        return "mInputShown=true" in shell("dumpsys", "input_method")

    def sensor(acceleration):
        # UIAutomator may restore a frozen user rotation. Re-enable actual sensor
        # rotation for each attempt; this test must never pass due to system lock.
        shell("wm", "user-rotation", "free")
        shell("settings", "put", "system", "accelerometer_rotation", 1)
        adb("emu", "sensor", "set", "acceleration", acceleration)
        time.sleep(1.2)
        assert shell("settings", "get", "system", "accelerometer_rotation") == "1"

    results = []

    def check(name, condition, ui, geometry, state):
        (args.output / (name + ".xml")).write_bytes(ET.tostring(ui))
        (args.output / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
        (args.output / (name + "-display.txt")).write_text(state)
        results.append(dict(case=name, passed=bool(condition), display=geometry))
        (args.output / "results.json").write_text(json.dumps(results, indent=2))
        print(("PASS " if condition else "FAIL ") + name, flush=True)
        assert condition, name

    def portrait(name, predicate):
        # Activity resume can precede the system's orientation transition from
        # the previously open landscape activity. Wait for that transition.
        for _ in range(15):
            geometry, state = display()
            if geometry[0] < geometry[1] and geometry[2] == 0:
                break
            time.sleep(0.2)
        ui = tree()
        width, height, rotation = geometry
        # Check both before and after accessibility inspection to avoid a dump
        # silently rotating the screen and hiding the original failure.
        after, _ = display()
        check(name, width < height and rotation == 0 and after == geometry
              and int(ui.attrib["rotation"]) == 0 and predicate(ui), ui, geometry, state)
        return ui

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    old_auto = shell("settings", "get", "system", "accelerometer_rotation")
    old_rotation = shell("settings", "get", "system", "user_rotation")
    acceleration = adb("emu", "sensor", "get", "acceleration").decode()
    old_acceleration = re.search(r"acceleration = ([^\r\n]+)", acceleration).group(1).strip()
    data = f"/data/user/0/{PACKAGE}/files/agent-testing/portrait-{uuid.uuid4().hex}"
    (args.output / "data-path.txt").write_text(data)

    def launch():
        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
              "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
        for _ in range(20):
            if any(PACKAGE in line for line in shell("dumpsys", "activity", "activities").splitlines()
                   if "ResumedActivity" in line):
                time.sleep(0.5)
                return
            time.sleep(0.1)
        raise RuntimeError("QShopper did not enter the foreground")

    def preserved(name, ui):
        snapshot = args.output / (name + ".sqlite")
        snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(snapshot)) as db:
            items = db.execute(f'SELECT name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()
        geometry, state = display()
        check(name, items == [("milk", 0), ("bread", 1)], ui, geometry, state)

    with tempfile.TemporaryDirectory(prefix="qshopper-portrait-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
            db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
            db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, ?)',
                           [(str(uuid.uuid4()), "milk", 0), (str(uuid.uuid4()), "bread", 1)])
            db.commit()
        staging = "/data/local/tmp/qshopper-portrait-" + uuid.uuid4().hex + ".sqlite"
        adb("push", fixture, staging)
        shell("am", "force-stop", PACKAGE)
        shell("run-as", PACKAGE, "mkdir", "-p", data)
        shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
        try:
            # A system activity is the control: prove these sensors can really
            # rotate this display before expecting QShopper to resist rotation.
            shell("am", "start", "-a", "android.settings.SETTINGS")
            sensor("9.81:0:0")
            for _ in range(20):
                geometry, state = display()
                if geometry[0] > geometry[1]:
                    break
                time.sleep(0.2)
            check("sensor_control_rotates_settings", geometry[0] > geometry[1], tree(), geometry, state)
            sensor("9.81:0:0")
            launch()
            ui = portrait("launch_held_landscape", lambda ui: editor(ui) is None)
            preserved("cold_launch_preserves_items", ui)
            shell("am", "force-stop", PACKAGE)
            sensor("0:9.81:0")
            launch()
            ui = portrait("launch_held_portrait", lambda ui: editor(ui) is None)
            pid = shell("pidof", PACKAGE)
            for side, acceleration in (("left", "9.81:0:0"), ("right", "-9.81:0:0")):
                sensor(acceleration)
                ui = portrait("shopping_rotate_" + side, lambda ui: editor(ui) is None)
            sensor("0:9.81:0")
            width, height, _ = display()[0]
            shell("input", "swipe", width // 2, height // 5, width // 2, height - 100, 1200)
            time.sleep(0.7)
            ui = tree()
            assert editor(ui) is not None, "Could not enter edit mode"
            sensor("9.81:0:0")
            ui = portrait("edit_keyboard_closed", lambda ui: editor(ui) is not None and not keyboard())
            left, top, right, bottom = bounds(editor(ui))
            shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
            for _ in range(20):
                if keyboard():
                    break
                time.sleep(0.1)
            assert keyboard(), "Gboard did not open"
            shell("input", "text", "unfinished")
            sensor("-9.81:0:0")
            ui = portrait("edit_keyboard_open_keeps_draft", lambda ui: keyboard() and editor(ui) is not None
                          and editor(ui).get("text") == "unfinished")
            left, top, right, bottom = bounds(editor(ui))
            shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
            ui = tree()
            assert any(n.get("content-desc") == "Dark" for n in ui.iter("node")), "Drawer did not open"
            sensor("9.81:0:0")
            ui = portrait("drawer_open", lambda ui: not keyboard() and any(
                n.get("content-desc") == "Dark" for n in ui.iter("node")))
            shell("input", "tap", width - 50, height // 2)
            ui = tree()
            geometry, state = display()
            check("drawer_return_keeps_draft_and_process", editor(ui) is not None
                  and editor(ui).get("text") == "unfinished" and shell("pidof", PACKAGE) == pid,
                  ui, geometry, state)
            preserved("rotation_preserves_order_and_checks", ui)
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("rm", staging)
            adb("emu", "sensor", "set", "acceleration", old_acceleration)
            shell("wm", "user-rotation", "lock", old_rotation)
            shell("settings", "put", "system", "accelerometer_rotation", old_auto)


if __name__ == "__main__":
    main()
