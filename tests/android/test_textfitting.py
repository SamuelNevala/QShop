"""UI-003: count actual rendered text lines in isolated Android shopping rows.

Requires Pillow. Only an emulator is allowed. Uses native screenshots rather
than accessibility labels, which contain the full source even when elided.
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
ENTRIES = [
    "Milk",
    "Whole grain bread with sunflower seeds and no added sugar",
    "Shopping ingredients for a large family dinner including potatoes carrots onions mushrooms tomatoes pasta and cheese",
    "W" * 100,
    "Very long shopping entry " * 40,
    "Kaurahiutaleita ja taysjyvaleipaa ilman lisattya sokeria koko perheelle",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-textfitting"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree(folder):
        for _ in range(3):
            if "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-text.xml"):
                raw = adb("exec-out", "cat", "/sdcard/qshopper-text.xml")
                (folder / "ui.xml").write_bytes(raw)
                return ET.fromstring(raw)
        raise RuntimeError("Could not read Android UI")

    results = []

    def check(name, passed, **details):
        results.append(dict(case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, flush=True)

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    with tempfile.TemporaryDirectory(prefix="qshopper-text-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
            db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
            db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                           [(str(uuid.uuid4()), text) for text in ENTRIES])
            db.commit()
        staging = "/data/local/tmp/qshopper-text-" + uuid.uuid4().hex + ".sqlite"
        adb("push", fixture, staging)
        try:
            for theme, light in (("Dark", False), ("Light", True)):
                folder = args.output / theme.lower()
                folder.mkdir(exist_ok=True)
                data = f"/data/user/0/{PACKAGE}/files/agent-testing/text-{uuid.uuid4().hex}"
                (folder / "data-path.txt").write_text(data, encoding="utf-8")
                shell("am", "force-stop", PACKAGE)
                shell("run-as", PACKAGE, "mkdir", "-p", data)
                shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
                # QSettings uses an INI file under the isolated root on Android.
                settings = Path(temporary) / "QShopper.conf"
                settings.write_text("[General]\ntheme=" + ("0" if light else "1") + "\n", encoding="utf-8")
                adb("push", settings, staging + ".conf")
                shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                shell("run-as", PACKAGE, "cp", staging + ".conf", data + "/Nevala/QShopper.ini")
                shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                      "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                for _ in range(6):
                    ui = tree(folder)
                    rows = sorted({tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))
                                   for node in ui.iter("node") if node.get("resource-id", "").rsplit(".", 1)[-1]
                                   .startswith("TextDelegate_")}, key=lambda rect: rect[1])
                    if len(rows) == len(ENTRIES):
                        break
                    time.sleep(0.3)
                assert len(rows) == len(ENTRIES), "Shopping fixture did not load"
                image = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
                image.save(folder / "shopping.png")
                width, height = image.size
                assert width < height, "Use the portrait phone emulator"
                ink_heights = []
                for index, (left, top, right, bottom) in enumerate(rows):
                    # Resting rows have no action icons. Their 80% surface
                    # keeps wallpaper below/above the text threshold.
                    if index == 0:
                        edge = image.getpixel((right - 15, (top + bottom) // 2))
                        check(f"{theme}_surface", min(edge) > 180 if light else max(edge) < 100, rgb=edge)
                    bands = []
                    for y in range(top + 2, bottom - 2):
                        ink = sum((max(image.getpixel((x, y))) < 100 if light
                                   else min(image.getpixel((x, y))) > 150)
                                  for x in range(left + 8, right - 8))
                        if ink >= 3:
                            if bands and bands[-1][1] == y - 1:
                                bands[-1][1] = y
                            else:
                                bands.append([y, y])
                    image.crop((left, top, right, bottom)).save(folder / f"row-{index}.png")
                    check(f"{theme}_line_limit_{index}", 1 <= len(bands) <= 3,
                          bands=bands, text=ENTRIES[index], row=[left, top, right, bottom])
                    ink_heights.append(max((end - start + 1 for start, end in bands), default=0))
                    if index == 0:
                        check(f"{theme}_short_stays_large", len(bands) == 1
                              and bands[0][1] - bands[0][0] > (bottom - top) * 0.4, bands=bands)
                check(f"{theme}_long_text_shrinks", 0 < ink_heights[1] < ink_heights[0]
                      and 0 < ink_heights[2] < ink_heights[0],
                      short=ink_heights[0], ordinary=ink_heights[1], long=ink_heights[2])
                snapshot = folder / "saved.sqlite"
                snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
                with closing(sqlite3.connect(snapshot)) as db:
                    saved = db.execute(f'SELECT name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()
                check(f"{theme}_source_text_preserved", saved == [(text, 0) for text in ENTRIES])
        finally:
            shell("am", "force-stop", PACKAGE)
    assert all(result["passed"] for result in results), "Native text fitting failed; see results.json"


if __name__ == "__main__":
    main()
