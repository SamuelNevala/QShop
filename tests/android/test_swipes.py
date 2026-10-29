"""UI-004: exercise the installed debug APK on an isolated Android emulator.

Requires Python 3 and adb. Never installs an APK or accesses a physical phone.
Each case uses a fresh QSHOPPER_DATA_DIR; fixtures use SQLite, actions use touch.
"""

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
    parser.add_argument("--output", type=Path, default=Path("out/android-swipes"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output(
            [args.adb, "-s", args.serial, *map(str, command)], timeout=45
        )

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def hierarchy():
        shell("uiautomator", "dump", "/sdcard/qshopper-swipes.xml")
        return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-swipes.xml"))

    def bounds(node):
        return list(map(int, re.findall(r"\d+", node.attrib["bounds"])))

    def editor(ui):
        return ui.find('.//node[@content-desc="Tap to add items"]')

    def rows(ui):
        return sorted(
            (bounds(n) for n in ui.findall('.//node[@resource-id="chooser"]')),
            key=lambda rect: rect[1],
        )

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    results = []
    screen_height = int(re.search(r"\d+x(\d+)", shell("wm", "size"))[1])
    with tempfile.TemporaryDirectory(prefix="qshopper-swipes-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
            db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
            db.executemany(
                f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                [(str(uuid.uuid4()), "milk"), (str(uuid.uuid4()), "bread")],
            )
            db.commit()
        settings = Path(temporary) / "QShopper.ini"
        settings.write_text("[General]\nactiveList=default\nswipeSensitivity=1\n")
        # A unique staging name also avoids collisions with another test runner.
        staging = "/data/local/tmp/qshopper-swipes-" + uuid.uuid4().hex
        adb("push", fixture, staging + ".sqlite")
        adb("push", settings, staging + ".ini")
        try:
            for edit in (False, True):
                for right in (False, True):
                    for fast in (False, True):
                        tag = "_".join(("edit" if edit else "shop", "right" if right else "left",
                                        "velocity" if fast else "distance"))
                        data = f"/data/user/0/{PACKAGE}/files/agent-testing/swipes-{uuid.uuid4().hex}"
                        shell("am", "force-stop", PACKAGE)
                        shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                        shell("run-as", PACKAGE, "cp", staging + ".sqlite", data + "/shop_list.sqlite")
                        shell("run-as", PACKAGE, "cp", staging + ".ini", data + "/Nevala/QShopper.ini")
                        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                              "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                        # Qt startup can take longer when the build machine is busy.
                        # Wait for the actual fixture instead of timing the splash screen.
                        for _ in range(4):
                            time.sleep(1)
                            ui = hierarchy()
                            if len(rows(ui)) == 2 and editor(ui) is None:
                                break
                        else:
                            (args.output / (tag + "-startup.xml")).write_bytes(ET.tostring(ui))
                            raise RuntimeError("Shopping fixture did not load")
                        if edit:
                            # Pull empty space down past the app's 30 mm mode threshold.
                            last = rows(ui)[-1]
                            x = (last[0] + last[2]) // 2
                            shell("input", "swipe", x, last[3] + 80, x, screen_height - 140, 1200)
                            time.sleep(0.8)
                            ui = hierarchy()
                            assert editor(ui) is not None, "Pull gesture did not enter edit mode"
                        candidates = rows(ui)
                        if edit:
                            candidates.remove(bounds(editor(ui)))
                        left, top, right_edge, bottom = candidates[0]
                        width = right_edge - left
                        start = left + int(width * (0.12 if right else 0.88))
                        distance = int(width * (0.4 if fast else 0.75))
                        end = start + (distance if right else -distance)
                        y = (top + bottom) // 2
                        shell("input", "swipe", start, y, end, y, 70 if fast else 600)
                        time.sleep(1.2)
                        snapshot = args.output / (tag + ".sqlite")
                        snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
                        with closing(sqlite3.connect(snapshot)) as db:
                            actual = db.execute(f'SELECT name, checked FROM "{TABLE}" ORDER BY rowid').fetchall()
                        expected = [("bread", 0)] if edit and right else [("bread", 0), ("milk", 1)]
                        passed = actual == expected
                        results.append(dict(case=tag, passed=passed, actual=actual, expected=expected, data=data))
                        (args.output / (tag + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
                        print(("PASS " if passed else "FAIL ") + tag + ": " + str(actual), flush=True)
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("rm", staging + ".sqlite", staging + ".ini")
            (args.output / "results.json").write_text(json.dumps(results, indent=2))
    return 0 if len(results) == 8 and all(result["passed"] for result in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
