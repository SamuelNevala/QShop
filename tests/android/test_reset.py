"""UI-009: real swipes and drawer Reset checks preserve order across restart."""

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

from undo_bar import undo_bar_frame


PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-reset"))
    parser.add_argument("--case", choices=("all", "exact", "mixed", "pending", "clear", "remove"), default="all")
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
            shell("rm", "-f", "/sdcard/qshopper-reset.xml")
            if "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-reset.xml"):
                return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-reset.xml"))
        raise RuntimeError("Could not read the current UI")

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.attrib["bounds"])))

    def rows(ui):
        return sorted({bounds(n) for n in ui.iter("node") if n.get(
            "resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
            and bounds(n)[3] > bounds(n)[1]}, key=lambda rect: rect[1])

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def saved():
        snapshot = case_dir / "saved.sqlite"
        snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(snapshot)) as db:
            return db.execute(f'SELECT name,checked,id FROM "{TABLE}" ORDER BY rowid').fetchall()

    results = []

    def check(name, passed, ui):
        if ui is not None:
            (case_dir / (name + ".xml")).write_bytes(ET.tostring(ui))
        (case_dir / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
        results.append(dict(case=case + "_" + name, passed=bool(passed), saved=saved()))
        (args.output / "results.json").write_text(json.dumps(results, indent=2))
        print(("PASS " if passed else "FAIL ") + case + "_" + name, flush=True)
        assert passed, case + "_" + name

    def launch():
        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
              "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
        for _ in range(5):
            foreground = any(PACKAGE in line for line in shell("dumpsys", "activity", "activities").splitlines()
                             if "ResumedActivity" in line)
            if foreground:
                try:
                    ui = tree()
                except RuntimeError:
                    ui = None
                if ui is not None and len(rows(ui)) == len(initial):
                    return ui
            time.sleep(0.3)
        raise RuntimeError("App did not load the expected shopping rows")

    def enter_edit(ui):
        shell("input", "swipe", width // 2, (rows(ui)[0][1] + rows(ui)[0][3]) // 2,
              width // 2, height - 100, 1200)
        time.sleep(0.7)
        ui = tree()
        assert editor(ui) is not None, "Could not enter edit mode"
        return ui

    def drawer_action(ui):
        left, top, right, bottom = bounds(editor(ui))
        shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
        ui = tree()
        label = {"clear": "Clear", "remove": "Remove"}.get(case, "Reset")
        buttons = [n for n in ui.iter("node") if n.get("class") == "android.widget.Button"
                   and n.get("content-desc", "").startswith(label)]
        assert len(buttons) == 1, "Drawer action button was not found: " + label
        left, top, right, bottom = bounds(buttons[0])
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
        if case in ("clear", "remove"):
            time.sleep(1)
            return None
        ui = tree()
        assert not any(n.get("content-desc") == "Dark" for n in ui.iter("node")), "Drawer did not close"
        return ui

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    cases = ("exact", "mixed", "pending") if args.case == "all" else (args.case,)
    with tempfile.TemporaryDirectory(prefix="qshopper-reset-") as temporary:
        for case in cases:
            case_dir = args.output / case
            case_dir.mkdir(parents=True, exist_ok=True)
            mixed = case in ("mixed", "clear", "remove")
            initial = ["A", "B", "1", "2", "3"] if mixed else ["1", "2", "3"]
            checked_order = ["A", "B", "2", "1", "3"] if mixed else ["2", "1", "3"]
            expected = ["A", "B", "3", "1", "2"] if mixed else ["3", "1", "2"]
            identities = {name: str(uuid.uuid4()) for name in initial}
            fixture = Path(temporary) / (case + ".sqlite")
            with closing(sqlite3.connect(fixture)) as db:
                schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                db.execute("CREATE TABLE lists " + schema)
                db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                               [(identities[name], name) for name in initial])
                db.commit()
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/reset-{uuid.uuid4().hex}"
            (case_dir / "data-path.txt").write_text(data)
            staging = "/data/local/tmp/qshopper-reset-" + uuid.uuid4().hex + ".sqlite"
            adb("push", fixture, staging)
            shell("am", "force-stop", PACKAGE)
            shell("run-as", PACKAGE, "mkdir", "-p", data)
            shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
            try:
                ui = launch()
                display = shell("dumpsys", "window", "displays")
                width, height = map(int, re.search(r"DisplayFrames w=(\d+) h=(\d+)", display).groups())
                assert width < height, "Use the portrait phone emulator"
                for name in ("3", "1", "2"):
                    names = [record[0] for record in saved()]
                    left, top, right, bottom = rows(ui)[names.index(name)]
                    y = (top + bottom) // 2
                    shell("input", "swipe", left + int((right - left) * 0.85), y,
                          left + int((right - left) * 0.15), y, 70)
                    ui = tree()
                records = saved()
                check("selection_order", [r[0] for r in records] == checked_order and all(
                    bool(r[1]) == (r[0] in ("1", "2", "3")) for r in records), ui)
                ui = enter_edit(ui)
                if case == "pending":
                    left, top, right, bottom = rows(ui)[checked_order.index("3")]
                    x, y = (left + right) // 2, (top + bottom) // 2
                    shell("input", "tap", x, y)
                    shell("input", "tap", x, y)
                    ui = tree()
                    assert editor(ui).get("text") == "3", "Could not edit the last checked item"
                ui = drawer_action(ui)
                if case in ("clear", "remove"):
                    remaining = [] if case == "clear" else ["A", "B"]
                    check("drawer_removes_expected_items", [r[0] for r in saved()] == remaining, ui)
                    raw = adb("exec-out", "screencap", "-p")
                    frame = undo_bar_frame(raw, 0) or undo_bar_frame(raw, 1)
                    assert frame is not None, "Floating Undo action was not found"
                    shell("input", "tap", frame["action_x"], frame["action_y"])
                    ui = tree()
                    check("undo_icon_restores_order_checks_and_ids", saved() == records, ui)
                else:
                    records = saved()
                    check("reset_restores_checking_order_and_clears_checks", [r[0] for r in records] == expected
                          and all(not r[1] for r in records), ui)
                    if case == "pending":
                        check("reset_preserves_edit_text", editor(ui).get("text") == "3", ui)
                    ui = drawer_action(ui)
                    check("second_reset_is_unchanged", saved() == records, ui)
                    shell("am", "force-stop", PACKAGE)
                    ui = launch()
                    check("restart_preserves_order_flags_and_ids", saved() == records and all(
                        str(uuid.UUID(r[2])) == identities[r[0]] for r in records), ui)
            finally:
                shell("am", "force-stop", PACKAGE)
                shell("rm", staging)


if __name__ == "__main__":
    main()
