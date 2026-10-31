"""UI-006/UI-007 native Back gestures and recovery with isolated emulator data."""

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
                        help="Also check UI-007 cancellation and immediate interaction recovery")
    parser.add_argument("--matrix", action="store_true",
                        help="Check both edges, keyboard states, and pre-held/completed gestures")
    parser.add_argument("--gesture-jar", type=Path,
                        help="Compiled BackGesture test helper; required for cancellation checks")
    parser.add_argument("--edge", choices=("left", "right"), default="left")
    parser.add_argument("--hold-start", type=int, default=0,
                        help="Initial hold in ms; keep below Android's Back long-press timeout")
    parser.add_argument("--with-keyboard", action="store_true")
    parser.add_argument("--complete-gesture", action="store_true")
    parser.add_argument("--selector-back", action="store_true", help="Also exercise Back with each drawer selector popup open")
    args = parser.parse_args()
    if args.matrix:
        args.check_cancellation = True
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    if args.check_cancellation and (args.gesture_jar is None or not args.gesture_jar.is_file()):
        parser.error("--check-cancellation requires a compiled --gesture-jar")
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

    def check(name, passed, ui, fatal=True, **details):
        (args.output / (name + ".xml")).write_bytes(ET.tostring(ui))
        (args.output / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
        results.append(dict(case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2))
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        if fatal:
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
        start = 1 if args.edge == "left" else screen_width - 4
        end = screen_width // 3 if args.edge == "left" else screen_width * 2 // 3
        shell("input", "swipe", start, screen_height // 3, end, screen_height // 3, 250)
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

    def reorder_pair(ui, prefix):
        for restore in (False, True):
            candidates = [rect for rect in rows(ui) if list(rect) != bounds(editor(ui))]
            source, destination = (candidates[-1], candidates[0]) if restore else (candidates[0], candidates[-1])
            x = (source[0] + source[2]) // 2
            y = (source[1] + source[3]) // 2
            end_y = (destination[1] + destination[3]) // 2
            adb("shell", f"CLASSPATH={gesture_path} app_process /system/bin BackGesture "
                f"{x} {x} {y} false 1000 {end_y}")
            ui = tree()
            expected = [("milk", 0), ("bread", 0)] if restore else [("bread", 0), ("milk", 0)]
            check(prefix + ("_restore" if restore else ""), saved_items() == expected, ui)
        return ui

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
        gesture_path = staging + ".jar"
        if args.check_cancellation:
            adb("push", args.gesture_jar, gesture_path)
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
            if args.selector_back:
                def popup_visible(current):
                    return any("Popup" in n.get("resource-id", "") and bounds(n)[3] > bounds(n)[1]
                               for n in current.iter("node"))

                for selector, label in (("lists", "default"), ("accent", "Green"), ("primary", "Indogo")):
                    left, top, right, bottom = bounds(editor(ui))
                    shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
                    ui = wait_ui(lambda current: any(n.get("content-desc") == "Dark" for n in current.iter("node")))
                    options = [n for n in ui.iter("node") if n.get("class") == "android.widget.Spinner"
                               and n.get("content-desc") == label]
                    assert len(options) == 1, "Drawer selector not found: " + selector
                    left, top, right, bottom = bounds(options[0])
                    shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
                    ui = wait_ui(popup_visible)
                    assert popup_visible(ui), "Selector popup did not open"
                    back()
                    ui = wait_ui(lambda current: not popup_visible(current))
                    drawer_open = any(n.get("content-desc") == "Dark" for n in ui.iter("node"))
                    check(selector + "_popup_back_closes_only_selector", foreground() and editor(ui) is not None
                          and not popup_visible(ui) and drawer_open
                          and saved_items() == [("milk", 0), ("bread", 0)], ui,
                          fatal=False, drawer_still_open=drawer_open)
                    if drawer_open:
                        back()
                        ui = wait_ui(lambda current: not any(n.get("content-desc") == "Dark" for n in current.iter("node")))
                        check(selector + "_next_back_closes_drawer_only", foreground() and editor(ui) is not None
                              and not any(n.get("content-desc") == "Dark" for n in ui.iter("node")), ui)
            if args.check_cancellation:
                ui = reorder_pair(ui, "reorder_control")
                scenarios = [(args.edge, args.hold_start, args.with_keyboard, not args.complete_gesture)]
                if args.matrix:
                    # Android rejects Back if the initial hold exceeds its ~250 ms timeout.
                    # Hold for a full second after recognition instead, to expose stale timers.
                    scenarios = [(edge, hold, ime, True) for edge in ("left", "right")
                                 for hold in (0, 150) for ime in (False, True)]
                    scenarios += [(edge, 150, ime, False) for edge in ("left", "right")
                                  for ime in (False, True)]
                for edge, hold, ime, cancel in scenarios:
                    prefix = f"{edge}_hold{hold}_ime{int(ime)}_{'cancel' if cancel else 'complete'}_"
                    if ime and not keyboard():
                        left, top, right, bottom = bounds(editor(ui))
                        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
                        ui = wait_ui(lambda current: keyboard())
                        assert keyboard(), "Keyboard did not open for gesture scenario"
                    elif not ime and keyboard():
                        back()
                        ui = wait_ui(lambda current: not keyboard())
                        assert not keyboard() and editor(ui) is not None
                    candidates = [rect for rect in rows(ui) if list(rect) != bounds(editor(ui))]
                    y = (candidates[0][1] + candidates[0][3]) // 2
                    start = 1 if edge == "left" else screen_width - 4
                    outward = screen_width // 3 if edge == "left" else screen_width * 2 // 3
                    # One continuous pointer stream, including the return/cancel path.
                    adb("shell", f"CLASSPATH={gesture_path} app_process /system/bin BackGesture "
                        f"{start} {outward} {y} {str(cancel).lower()} {hold}")
                    ui = tree()
                    if cancel:
                        text_rows = [node for node in ui.iter("node") if node.attrib.get(
                            "resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")]
                        healthy = len(text_rows) == 2 and all(".DelegateChoser_" in node.attrib.get(
                            "resource-id", "") for node in text_rows)
                        check(prefix + "state", foreground() and editor(ui) is not None and healthy
                              and keyboard() == ime and saved_items() == [("milk", 0), ("bread", 0)], ui)
                    else:
                        check(prefix + "state", foreground() and (editor(ui) is not None) == ime
                              and not keyboard() and saved_items() == [("milk", 0), ("bread", 0)], ui)
                        if editor(ui) is None:
                            ui = enter_edit(ui)
                    # The very first new interaction is a deliberate long-press reorder.
                    ui = reorder_pair(ui, prefix + "reorder")
                    for checked in (True, False):
                        candidates = [rect for rect in rows(ui) if list(rect) != bounds(editor(ui))]
                        left, top, right, bottom = candidates[-1] if not checked else candidates[0]
                        y = (top + bottom) // 2
                        shell("input", "swipe", left + int((right - left) * 0.85), y,
                              left + int((right - left) * 0.15), y, 70)
                        time.sleep(0.7)
                        ui = tree()
                        expected = [("bread", 0), ("milk", 1)] if checked else [("milk", 0), ("bread", 0)]
                        check(prefix + ("swipe" if checked else "correction"), saved_items() == expected, ui)
            if keyboard():
                back()
                ui = wait_ui(lambda current: not keyboard())
                assert editor(ui) is not None, "Keyboard Back also left edit mode"
            back()
            ui = wait_ui(lambda current: editor(current) is None)
            check("back_leaves_edit_after_drawer", foreground() and editor(ui) is None and len(rows(ui)) == 2, ui)
            check("saved_items_unchanged", saved_items() == [("milk", 0), ("bread", 0)], ui)
            assert all(result["passed"] for result in results), "Native Back checks failed; see results.json"
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("rm", staging)
            if args.check_cancellation:
                shell("rm", gesture_path)


if __name__ == "__main__":
    main()
