"""DEV-011: native Undo arc progression, expiry and restoration in both themes.

Requires Pillow. Runs only against an isolated emulator with disposable app data.
Screenshots sample the ring outside the glyph; no test-only renderer is used.
"""

import argparse
from contextlib import closing
from io import BytesIO
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

from PIL import Image

PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-undocanvas"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree():
        shell("uiautomator", "dump", "/sdcard/qshopper-undo.xml")
        return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-undo.xml"))

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    results = []

    def check(name, passed, **details):
        results.append(dict(case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        assert passed, name

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    for theme in (0, 1):
        data = f"/data/user/0/{PACKAGE}/files/agent-testing/undo-{uuid.uuid4().hex}"
        staging = "/data/local/tmp/qshopper-undo-" + uuid.uuid4().hex
        shell("am", "force-stop", PACKAGE)
        with tempfile.TemporaryDirectory(prefix="qshopper-undo-") as temporary:
            fixture = Path(temporary) / "shop_list.sqlite"
            with closing(sqlite3.connect(fixture)) as db:
                schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                db.execute("CREATE TABLE lists " + schema)
                db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                               [(str(uuid.uuid4()), name) for name in ("Milk", "Bread")])
                db.commit()
            settings = Path(temporary) / "QShopper.ini"
            settings.write_text(f"[General]\ntheme={theme}\nswipeSensitivity=3\n", encoding="utf-8")
            adb("push", fixture, staging + ".sqlite")
            adb("push", settings, staging + ".ini")
        shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
        shell("run-as", PACKAGE, "cp", staging + ".sqlite", data + "/shop_list.sqlite")
        shell("run-as", PACKAGE, "cp", staging + ".ini", data + "/Nevala/QShopper.ini")

        def saved():
            local = args.output / f"saved-{theme}.sqlite"
            local.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
            with closing(sqlite3.connect(local)) as db:
                return db.execute(f'SELECT name FROM "{TABLE}" ORDER BY rowid').fetchall()

        try:
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            for _ in range(6):
                ui = tree()
                if any(n.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                       for n in ui.iter("node")):
                    break
                time.sleep(.3)
            rows = sorted({bounds(n) for n in ui.iter("node") if n.get("resource-id", "")
                           .rsplit(".", 1)[-1].startswith("TextDelegate_")}, key=lambda r: r[1])
            assert len(rows) == 2, "Fixture rows were not loaded"
            width, screen_height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
            shell("input", "swipe", width // 2, rows[-1][3] + 80, width // 2, screen_height - 140, 1200)
            ui = tree()
            editor = ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')
            assert editor is not None, "Pull must enter edit mode"
            field = bounds(editor)
            rows = sorted({bounds(n) for n in ui.iter("node") if n.get("resource-id", "")
                           .rsplit(".", 1)[-1].startswith("TextDelegate_")}, key=lambda r: r[1])
            row = rows[0]
            left, top, right, bottom = row
            height = bottom - top
            # The editor's left square owns UndoIcon. The ring has .5 mm
            # button inset, .2 mm canvas margin and .5 mm radius allowance.
            cx, cy = field[0] + height / 2, (field[1] + field[3]) / 2
            radius = height * (0.5 - 1.2 / 9.27)

            def delete():
                shell("input", "swipe", left + int((right - left) * .15), (top + bottom) // 2,
                      left + int((right - left) * .85), (top + bottom) // 2, 250)
                return time.monotonic()

            def frame(name):
                raw = adb("exec-out", "screencap", "-p")
                (args.output / f"{theme}-{name}.png").write_bytes(raw)
                return Image.open(BytesIO(raw)).convert("RGB")

            def samples(image):
                painted = 0
                green = 0
                for step in range(36):
                    angle = math.pi * .6 + (step + .5) * math.pi / 18
                    inside = image.getpixel((round(cx + radius * .85 * math.cos(angle)),
                                             round(cy + radius * .85 * math.sin(angle))))
                    green += inside[1] > 150 and inside[1] - inside[0] > 70 and inside[1] - inside[2] > 20
                    x, y = round(cx + radius * math.cos(angle)), round(cy + radius * math.sin(angle))
                    pixels = [image.getpixel((x + dx, y + dy))
                              for dx in range(-2, 3) for dy in range(-2, 3)]
                    matches = any(max(p) < 75 if theme == 0 else min(p) > 210 for p in pixels)
                    painted += matches
                # Once timeout flips back to the menu, its dark background
                # must not be counted as the dark arc's foreground.
                return painted if green >= 10 else 0

            started = delete()
            time.sleep(.7)
            early = samples(frame("early"))
            check(f"{theme}_arc_initial", 26 <= early <= 36, samples=early)
            check(f"{theme}_delete", saved() == [("Bread",)])
            time.sleep(max(0, started + 7.5 - time.monotonic()))
            middle = samples(frame("middle"))
            check(f"{theme}_arc_half", 12 <= middle <= 22 and middle < early - 5, samples=middle)
            time.sleep(max(0, started + 16 - time.monotonic()))
            ended = samples(frame("expired"))
            check(f"{theme}_arc_expired", ended <= 2, samples=ended)
            check(f"{theme}_expiry_keeps_deletion", saved() == [("Bread",)])
            # Delete the remaining row and activate the actual Undo button.
            remaining = next(n for n in tree().iter("node") if n.get("resource-id", "")
                             .rsplit(".", 1)[-1].startswith("TextDelegate_"))
            left, top, right, bottom = bounds(remaining)
            delete()
            time.sleep(.7)
            assert saved() == [], "Remaining item was not deleted before Undo"
            shell("input", "tap", round(cx), round(cy))
            time.sleep(.7)
            check(f"{theme}_undo_restores", saved() == [("Bread",)])
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("run-as", PACKAGE, "rm", "-rf", data)
            shell("rm", "-f", staging + ".sqlite", staging + ".ini")


if __name__ == "__main__":
    main()
