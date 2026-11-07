"""UI-015: tap rendered Undo before Clear-list row retirement, plus settled controls.

Requires Pillow and BackGesture.jar. Uses only disposable emulator data; never
waits for accessibility idle between Clear and the timed Undo press.
"""

import argparse
from contextlib import closing
from io import BytesIO
import json
from pathlib import Path
import re
import sqlite3
import struct
import subprocess
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET

from PIL import Image
from test_reset import PACKAGE, TABLE
from undo_bar import undo_bar_frame


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-fastundo"))
    parser.add_argument("--gesture-jar", type=Path,
                        default=Path("out/android-emulator/back-gesture/gesture.jar"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def tree():
        path = "/data/local/tmp/qshopper-fastundo-" + uuid.uuid4().hex + ".xml"
        try:
            shell("uiautomator", "dump", path)
            return ET.fromstring(adb("exec-out", "cat", path))
        finally:
            shell("rm", "-f", path)

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def saved():
        with tempfile.TemporaryDirectory(prefix="qshopper-fastundo-read-") as temporary:
            path = Path(temporary) / "saved.sqlite"
            path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
            with closing(sqlite3.connect(path)) as database:
                entries = database.execute(f'SELECT name,checked,id FROM "{TABLE}" ORDER BY rowid').fetchall()
            # QUuid saves with braces; compare identities rather than their SQL spelling.
            return [(name, checked, str(uuid.UUID(identifier))) for name, checked, identifier in entries]

    def capture(name):
        raw = adb("exec-out", "screencap", "-p")
        (args.output / (name + ".png")).write_bytes(raw)
        return raw

    def clear_button():
        ui = tree()
        editor = ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')
        assert editor is not None, "Editor must be reachable"
        left, top, right, bottom = bounds(editor)
        shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
        ui = tree()
        buttons = [node for node in ui.iter("node") if node.get("class") == "android.widget.Button"
                   and node.get("content-desc", "").startswith("Clear")]
        assert len(buttons) == 1
        left, top, right, bottom = bounds(buttons[0])
        return (left + right) // 2, (top + bottom) // 2

    assert shell("getprop", "ro.kernel.qemu") == "1"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    helper = "/data/local/tmp/qshopper-fastundo-" + uuid.uuid4().hex + ".jar"
    frame_path = "/data/local/tmp/qshopper-fastundo-" + uuid.uuid4().hex + ".raw"
    adb("push", args.gesture_jar, helper)
    results = []
    data = None
    try:
        for theme in (0, 1):
            for count in (3, 30):
                profile = ("light-" if theme == 0 else "dark-") + str(count)
                shell("am", "force-stop", PACKAGE)
                data = f"/data/user/0/{PACKAGE}/files/agent-testing/fastundo-{uuid.uuid4().hex}"
                with tempfile.TemporaryDirectory(prefix="qshopper-fastundo-") as temporary:
                    fixture = Path(temporary) / "shop_list.sqlite"
                    with closing(sqlite3.connect(fixture)) as database:
                        schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                        database.execute("CREATE TABLE lists " + schema)
                        database.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                        database.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                        database.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)',
                                             [(str(uuid.uuid4()), "Item " + str(index), int(index == count - 1))
                                              for index in range(count)])
                        database.commit()
                    settings = Path(temporary) / "QShopper.ini"
                    settings.write_text(f"[General]\ntheme={theme}\nactiveList={TABLE}\n", encoding="utf-8")
                    shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                    for source, destination in ((fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")):
                        staging = "/data/local/tmp/qshopper-fastundo-" + uuid.uuid4().hex
                        adb("push", source, staging)
                        shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                        shell("rm", "-f", staging)
                shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                      "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                time.sleep(1.2)
                ui = tree()
                rows = sorted({bounds(node) for node in ui.iter("node")
                               if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                               and bounds(node)[3] > bounds(node)[1]})
                assert rows
                shell("input", "swipe", width // 2, (rows[0][1] + rows[0][3]) // 2,
                      width // 2, height - 140, 1200)
                time.sleep(.5)
                before = saved()
                clear_x, clear_y = clear_button()
                shell("input", "tap", clear_x, clear_y)
                time.sleep(.7)
                raw = capture(profile + "-settled-press")
                bar = undo_bar_frame(raw, theme)
                assert bar is not None, "The settled control must visibly offer Undo"
                assert saved() == [], "Clear must remove all fixture entries"
                # Same rendered center is used for the timed press after the next Clear.
                undo_x, undo_y = width // 2, (bar["top"] + bar["bottom"]) // 2
                shell("input", "tap", undo_x, undo_y)
                time.sleep(.6)
                restored = saved()
                capture(profile + "-settled-after")
                control_ok = restored == before
                results.append(dict(case=profile + "-settled", passed=control_ok,
                                    before=before, restored=restored, bar=bar, point=[undo_x, undo_y]))
                (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
                assert control_ok, "Settled Undo must restore exact order, flags and IDs"
                clear_x, clear_y = clear_button()
                command = f"CLASSPATH={helper} app_process /system/bin BackGesture clear-undo {clear_x} {clear_y} {undo_x} {undo_y} 200 {frame_path}"
                with subprocess.Popen([args.adb, "-s", args.serial, "shell", command],
                                      stdin=subprocess.PIPE, stdout=subprocess.PIPE) as gesture:
                    try:
                        frame_ms = int(gesture.stdout.readline().decode().split()[1])
                        assert gesture.stdout.readline().strip() == b"READY"
                    finally:
                        gesture.stdin.write(b"\n")
                        gesture.stdin.flush()
                    elapsed = int(gesture.stdout.readline().decode().split()[1])
                    gesture.wait(timeout=15)
                frame_bytes = adb("exec-out", "cat", frame_path)
                # AOSP screencap raw header: width, height, RGBA_8888 format, dataspace.
                frame_width, frame_height, format_code, _ = struct.unpack("<4I", frame_bytes[:16])
                assert format_code == 1 and len(frame_bytes) == 16 + frame_width * frame_height * 4
                image = Image.frombytes("RGBA", (frame_width, frame_height), frame_bytes[16:]).convert("RGB")
                buffer = BytesIO()
                image.save(buffer, format="PNG")
                raw = buffer.getvalue()
                (args.output / (profile + "-fast-press.png")).write_bytes(raw)
                actual = undo_bar_frame(raw, theme)
                assert actual is not None, "Fast target must be the rendered Undo bar"
                assert actual["top"] < undo_y < actual["bottom"]
                time.sleep(.7)
                exact = saved() == before
                passed = 0 < elapsed < 500 and exact
                results.append(dict(case=profile + "-fast", passed=passed, press_ms=elapsed,
                                    frame_start_ms=frame_ms, frame=actual, exact_restoration=exact))
                (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
                print(("PASS " if passed else "FAIL ") + profile, "press_ms=", elapsed, flush=True)
                assert passed, "Fast Undo must precede row retirement and restore exact saved data"
                shell("am", "force-stop", PACKAGE)
                shell("run-as", PACKAGE, "rm", "-rf", data)
                data = None
    finally:
        shell("am", "force-stop", PACKAGE)
        if data:
            shell("run-as", PACKAGE, "rm", "-rf", data)
        shell("rm", "-f", helper)
        shell("rm", "-f", frame_path)


if __name__ == "__main__":
    main()
