"""UI-006 native edge Back gestures with Gboard and isolated emulator data."""

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
    parser.add_argument("--output", type=Path, default=Path("out/android-back"))
    parser.add_argument("--check-cancellation", action="store_true",
                        help="Also reproduce the unresolved UI-007 cancellation/next-swipe bug")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def tree():
        shell("uiautomator", "dump", "/sdcard/qshopper-back.xml")
        return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-back.xml"))

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def bounds(node):
        return list(map(int, re.findall(r"\d+", node.attrib["bounds"])))

    def rows(ui):
        rectangles = set()
        for node in ui.iter("node"):
            resource = node.attrib.get("resource-id", "")
            leaf = resource.rsplit(".", 1)[-1]
            if resource == "chooser" or leaf.startswith(("TextDelegate_", "InputDelegate_")):
                rectangles.add(tuple(bounds(node)))
        return sorted(rectangles, key=lambda r: r[1])

    def foreground():
        return any(PACKAGE in line for line in shell("dumpsys", "activity", "activities").splitlines()
                   if "ResumedActivity" in line)

    def keyboard():
        return "mInputShown=true" in shell("dumpsys", "input_method")

    def wait_ui(predicate):
        for _ in range(5):
            ui = tree()
            if predicate(ui):
                return ui
            time.sleep(0.3)
        return ui

    results = []

    def check(name, passed, ui):
        (args.output / (name + ".xml")).write_bytes(ET.tostring(ui))
        (args.output / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
        results.append(dict(case=name, passed=bool(passed)))
        (args.output / "results.json").write_text(json.dumps(results, indent=2))
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        assert passed, name

    if shell("getprop", "ro.kernel.qemu") != "1":
        raise RuntimeError("Target is not an emulator")
    assert shell("settings", "get", "secure", "navigation_mode") == "2", "Enable gesture navigation first"
    screen_width, screen_height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    data = f"/data/user/0/{PACKAGE}/files/agent-testing/back-{uuid.uuid4().hex}"
    (args.output / "data-path.txt").write_text(data)

    def launch():
        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
              "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)

    def back():
        # A real system edge gesture, not KEYCODE_BACK.
        shell("input", "swipe", 1, screen_height // 3, screen_width // 3, screen_height // 3, 250)
        time.sleep(0.5)

    def enter_edit(ui):
        last = rows(ui)[-1]
        shell("input", "swipe", screen_width // 2, last[3] + 80,
              screen_width // 2, screen_height - 140, 1200)
        ui = wait_ui(lambda current: editor(current) is not None)
        assert editor(ui) is not None, "Could not enter edit mode"
        return ui

    def saved_items():
        snapshot = args.output / "saved.sqlite"
        snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(snapshot)) as db:
            return db.execute(f'SELECT name, checked FROM "{TABLE}" ORDER BY rowid').fetchall()

    with tempfile.TemporaryDirectory(prefix="qshopper-back-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
            db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
            db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                           [(str(uuid.uuid4()), "milk"), (str(uuid.uuid4()), "bread")])
            db.commit()
        staging = "/data/local/tmp/qshopper-back-" + uuid.uuid4().hex + ".sqlite"
        adb("push", fixture, staging)
        shell("am", "force-stop", PACKAGE)
        shell("run-as", PACKAGE, "mkdir", "-p", data)
        shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
        try:
            launch()
            ui = wait_ui(lambda current: len(rows(current)) == 2)
            assert foreground() and len(rows(ui)) == 2, "Shopping fixture did not load"
            original_pid = shell("pidof", PACKAGE)
            ui = enter_edit(ui)
            left, top, right, bottom = bounds(editor(ui))
            shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
            shell("input", "text", "unfinished")
            assert keyboard(), "Real Android keyboard did not open"
            back()
            ui = wait_ui(lambda current: not keyboard())
            check("back_hides_keyboard_only", foreground() and editor(ui) is not None
                  and editor(ui).attrib.get("text") == "unfinished", ui)
            back()
            ui = wait_ui(lambda current: editor(current) is None)
            check("back_leaves_edit_only", foreground() and editor(ui) is None and len(rows(ui)) == 2, ui)
            back()
            ui = wait_ui(lambda current: not foreground())
            check("shopping_back_backgrounds_live_process", not foreground() and shell("pidof", PACKAGE) == original_pid, ui)
            launch()
            ui = wait_ui(lambda current: foreground() and len(rows(current)) == 2)
            check("return_keeps_process_and_list", foreground() and shell("pidof", PACKAGE) == original_pid
                  and editor(ui) is None and len(rows(ui)) == 2, ui)
            ui = enter_edit(ui)
            left, top, right, bottom = bounds(editor(ui))
            shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
            ui = wait_ui(lambda current: any(n.attrib.get("content-desc") == "Dark"
                                           for n in current.iter("node")))
            assert any(n.attrib.get("content-desc") == "Dark" for n in ui.iter("node")), "Drawer did not open"
            back()
            ui = wait_ui(lambda current: editor(current) is not None)
            check("drawer_back_preserves_edit", foreground() and editor(ui) is not None
                  and not any(n.attrib.get("content-desc") == "Dark" for n in ui.iter("node")), ui)
            if args.check_cancellation:
                y = (rows(ui)[1][1] + rows(ui)[1][3]) // 2
                # Return to the edge while held to cancel the predictive Back gesture.
                adb("shell", f"input motionevent DOWN 1 {y}; input motionevent MOVE 400 {y}; "
                    f"sleep 1; input motionevent MOVE 1 {y}; input motionevent UP 1 {y}")
                ui = wait_ui(lambda current: editor(current) is not None and len(rows(current)) == 3)
                check("cancelled_edge_gesture_preserves_edit", foreground() and editor(ui) is not None
                      and len(rows(ui)) == 3 and saved_items() == [("milk", 0), ("bread", 0)], ui)
                # A stuck long press disables swiping: exercise the same row after cancellation.
                for checked in (True, False):
                    candidates = [rect for rect in rows(ui) if list(rect) != bounds(editor(ui))]
                    left, top, right, bottom = candidates[-1] if not checked else candidates[0]
                    y = (top + bottom) // 2
                    shell("input", "swipe", left + int((right - left) * 0.85), y,
                          left + int((right - left) * 0.15), y, 70)
                    time.sleep(0.7)
                    ui = tree()
                    expected = [("bread", 0), ("milk", 1)] if checked else [("milk", 0), ("bread", 0)]
                    check("swipe_after_cancel" if checked else "correction_after_cancel", saved_items() == expected, ui)
            back()
            ui = wait_ui(lambda current: editor(current) is None)
            check("back_leaves_edit_after_drawer", foreground() and editor(ui) is None and len(rows(ui)) == 2, ui)
            check("saved_items_unchanged", saved_items() == [("milk", 0), ("bread", 0)], ui)
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("rm", staging)


if __name__ == "__main__":
    main()
