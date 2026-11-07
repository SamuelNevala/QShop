"""UI-017: compare visible arrows on settled and rapid repeated native swipes.

Run only against an isolated emulator; creates and removes disposable app data.
Requires Pillow and the BackGesture test helper. Android uses preview scale 1;
live preview resizing is covered by the Windows Qt Quick Test instead.
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
from test_filledcontrast import PACKAGE, TABLE


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-arrowfeedback"))
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
        path = "/data/local/tmp/qshopper-arrow-" + uuid.uuid4().hex + ".xml"
        try:
            shell("uiautomator", "dump", path)
            return ET.fromstring(adb("exec-out", "cat", path))
        finally:
            shell("rm", "-f", path)

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def rows(ui):
        return sorted({bounds(node) for node in ui.iter("node")
                       if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                       and bounds(node)[3] > bounds(node)[1]})

    assert shell("getprop", "ro.kernel.qemu") == "1"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    helper = "/data/local/tmp/qshopper-arrow-" + uuid.uuid4().hex + ".jar"
    adb("push", args.gesture_jar, helper)
    results = []
    data = None
    try:
        for theme in (0, 1):
            for variant in ("in", "out", "trash"):
                name = ("light-" if theme == 0 else "dark-") + variant
                shell("am", "force-stop", PACKAGE)
                data = f"/data/user/0/{PACKAGE}/files/agent-testing/arrow-{uuid.uuid4().hex}"
                with tempfile.TemporaryDirectory(prefix="qshopper-arrow-") as temporary:
                    fixture = Path(temporary) / "shop_list.sqlite"
                    with closing(sqlite3.connect(fixture)) as database:
                        schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                        database.execute("CREATE TABLE lists " + schema)
                        database.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                        database.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                        database.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)',
                                             [(str(uuid.uuid4()), text, int(variant == "out"))
                                              for text in ("Milk", "Bread", "Coffee")])
                        database.commit()
                    settings = Path(temporary) / "QShopper.ini"
                    settings.write_text(f"[General]\ntheme={theme}\nswipeSensitivity=0\nactiveList={TABLE}\n", encoding="utf-8")
                    shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                    for source, destination in ((fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")):
                        staging = "/data/local/tmp/qshopper-arrow-" + uuid.uuid4().hex
                        adb("push", source, staging)
                        shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                        shell("rm", "-f", staging)
                shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                      "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                time.sleep(1.5)
                ui = tree()
                if variant == "trash":
                    first = rows(ui)[0]
                    shell("input", "swipe", width // 2, (first[1] + first[3]) // 2,
                          width // 2, height - 140, 1200)
                    ui = tree()
                    assert ui.find('.//node[@class="android.widget.EditText"]') is not None
                left, top, right, bottom = rows(ui)[0]
                size = bottom - top
                x, y = round(width * .3), (top + bottom) // 2
                measurements = []
                for repeat in (False, True):
                    command = f"CLASSPATH={helper} app_process /system/bin BackGesture arrow-repeat {x} {x + size * 1.6} {y} {str(repeat).lower()}"
                    with subprocess.Popen([args.adb, "-s", args.serial, "shell", command],
                                          stdin=subprocess.PIPE, stdout=subprocess.PIPE) as gesture:
                        try:
                            assert gesture.stdout.readline().strip() == b"HELD"
                            time.sleep(.22)
                            raw = adb("exec-out", "screencap", "-p")
                            (args.output / f"{name}-{'repeat' if repeat else 'control'}.png").write_bytes(raw)
                            image = Image.open(BytesIO(raw)).convert("RGB")
                            pixels = [py for py in range(top, bottom)
                                      for px in range(left, left + size)
                                      if min(image.getpixel((px, py))) > 235]
                            measurements.append(dict(count=len(pixels),
                                                     center=sum(pixels) / len(pixels) if pixels else None))
                        finally:
                            gesture.stdin.write(b"\n")
                            gesture.stdin.flush()
                            gesture.wait(timeout=15)
                    time.sleep(1)
                control, repeated = measurements
                with tempfile.TemporaryDirectory(prefix="qshopper-arrow-read-") as temporary:
                    saved = Path(temporary) / "saved.sqlite"
                    saved.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
                    with closing(sqlite3.connect(saved)) as database:
                        entries = database.execute(f'SELECT name,checked FROM "{TABLE}"').fetchall()
                unchanged = sorted(entries) == sorted((text, int(variant == "out"))
                                                       for text in ("Milk", "Bread", "Coffee"))
                passed = (control["count"] >= 5 and repeated["count"] >= 5
                          and abs(control["center"] - repeated["center"]) < size * .09 and unchanged)
                results.append(dict(case=name, passed=passed, control=control, repeated=repeated,
                                    size=size, list_unchanged=unchanged))
                (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
                print(("PASS " if passed else "FAIL ") + name, measurements, flush=True)
                shell("am", "force-stop", PACKAGE)
                shell("run-as", PACKAGE, "rm", "-rf", data)
                data = None
    finally:
        shell("am", "force-stop", PACKAGE)
        if data:
            shell("run-as", PACKAGE, "rm", "-rf", data)
        shell("rm", "-f", helper)
    return 0 if all(result["passed"] for result in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
