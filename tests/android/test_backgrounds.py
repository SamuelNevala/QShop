"""UI-013: identify all ten packaged backgrounds in actual Android frames.

Requires Pillow; uses only an isolated emulator and disposable shopping data.
Correlation removes the uniform Light/Dark row tint before matching the artwork.
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

from PIL import Image, ImageOps


PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"
ROOT = Path(__file__).resolve().parents[2]


def fingerprint(image):
    gray = image.convert("L")
    # Below the three fixture rows, clear of status/navigation bars and text.
    samples = [gray.getpixel((round(image.width * x / 10), round(image.height * y / 20)))
               for y in range(11, 19) for x in range(1, 10)]
    mean = sum(samples) / len(samples)
    centered = [value - mean for value in samples]
    magnitude = math.sqrt(sum(value * value for value in centered))
    return [value / max(magnitude, 0.001) for value in centered]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-backgrounds"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    exports = json.loads((ROOT / "artwork/UI-013/exports.json").read_text(encoding="utf-8-sig"))
    results = []
    data_paths = []
    entries = [(str(uuid.uuid4()), "Milk", 0),
               (str(uuid.uuid4()), "Whole grain bread with sunflower seeds and no added sugar", 0),
               (str(uuid.uuid4()), "Coffee", 1)]
    try:
        for theme in (0, 1):
            shell("am", "force-stop", PACKAGE)
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/artwork-{uuid.uuid4().hex}"
            data_paths.append(data)
            with tempfile.TemporaryDirectory(prefix="qshopper-artwork-") as temporary:
                fixture = Path(temporary) / "shop_list.sqlite"
                with closing(sqlite3.connect(fixture)) as database:
                    schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                    database.execute("CREATE TABLE lists " + schema)
                    database.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                    database.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                    database.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)', entries)
                    database.commit()
                settings = Path(temporary) / "QShopper.ini"
                settings.write_text(f"[General]\ntheme={theme}\nactiveList={TABLE}\n", encoding="utf-8")
                shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                for source, destination in [(fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")]:
                    staging = "/data/local/tmp/qshopper-artwork-" + uuid.uuid4().hex
                    adb("push", source, staging)
                    shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                    shell("rm", "-f", staging)
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            expected = None
            visited = []
            deadline = time.monotonic() + 82
            while len(visited) < 10 and time.monotonic() < deadline:
                frame = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
                assert frame.width < frame.height, "Expected portrait rendering"
                if expected is None:
                    expected = []
                    for asset in exports:
                        with Image.open(ROOT / asset["file"]) as image:
                            fitted = ImageOps.fit(image, frame.size, method=Image.Resampling.BILINEAR)
                            expected.append(fingerprint(fitted))
                actual = fingerprint(frame)
                scores = [sum(a * b for a, b in zip(actual, reference)) for reference in expected]
                ranked = sorted(range(10), key=lambda index: scores[index], reverse=True)
                best = ranked[0]
                if scores[best] > 0.96 and scores[best] - scores[ranked[1]] > 0.03:
                    number = best + 1
                    if number not in visited:
                        assert number == len(visited) + 1, f"Unexpected slideshow order: {visited} -> {number}"
                        frame.save(args.output / f"theme-{theme}-{number:02d}.png")
                        visited.append(number)
                        result = dict(theme=theme, background=number, correlation=scores[best], passed=True)
                        results.append(result)
                        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
                        print(f"PASS theme {theme}, background {number:02d}, correlation {scores[best]:.4f}", flush=True)
                time.sleep(0.4)
            assert visited == list(range(1, 11)), f"Missing native backgrounds for theme {theme}: {visited}"
            # Rendering the full slideshow must not reorder/check/edit the shopping data.
            with tempfile.TemporaryDirectory(prefix="qshopper-artwork-saved-") as temporary:
                saved = Path(temporary) / "saved.sqlite"
                saved.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
                with closing(sqlite3.connect(saved)) as database:
                    assert database.execute(f'SELECT id,name,checked FROM "{TABLE}" ORDER BY rowid').fetchall() == entries
            print(f"PASS theme {theme}, shopping data unchanged", flush=True)
    finally:
        shell("am", "force-stop", PACKAGE)
        (args.output / "data-paths.json").write_text(json.dumps(data_paths, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
