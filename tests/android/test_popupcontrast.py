"""UI-026: measure actual selected popup text in the isolated Android app.

Requires Pillow. Uses disposable SQLite/settings, restores Android night mode,
and never installs to or targets a physical phone.
"""

import argparse
from collections import Counter
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

from test_filledcontrast import PACKAGE, TABLE, ratio, matches


PROFILES = {
    "light-green": (0, 9, False, "Green"),
    "dark-purple": (1, 2, True, "Purple"),
    "light-purple": (0, 3, False, "Deep purple"),
    "light-grey": (0, 17, False, "Grey"),
    "system-light": (2, 9, False, "Green"),
    "system-dark": (2, 9, True, "Green"),
}


def caption_colors(image, rect, color_picker):
    left, top, right, bottom = rect
    height = bottom - top
    # Exclude the color swatch, row edges, ripple boundaries and popup corners.
    region = image.crop((left + round(height * (1.05 if color_picker else .4)),
                         top + round(height * .25), right - round(height * .3),
                         bottom - round(height * .25)))
    counts = Counter(region.getdata())
    background, _ = counts.most_common(1)[0]
    ink = [(color, count) for color, count in counts.items()
           if not matches(color, background, 8) and ratio(color, background) > 1.01]
    assert ink, "No actual caption pixels"
    foreground, count = max(ink, key=lambda entry: entry[1])
    assert count >= 15, "Insufficient actual caption core pixels"
    return foreground, background


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--profile", choices=["all", *PROFILES], default="all")
    parser.add_argument("--output", type=Path, default=Path("out/android-popupcontrast"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def tree():
        shell("rm", "-f", "/sdcard/qshopper-popupcontrast.xml")
        assert "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-popupcontrast.xml")
        return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-popupcontrast.xml"))

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def tap(node):
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    def check(case, passed, **details):
        results.append(dict(case=case, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + case, details, flush=True)

    assert shell("getprop", "ro.kernel.qemu") == "1"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    original_night = re.search(r"(yes|no|auto)", shell("cmd", "uimode", "night")).group(1)
    results = []
    profiles = PROFILES if args.profile == "all" else {args.profile: PROFILES[args.profile]}
    try:
        for name, (theme, accent, dark, accent_name) in profiles.items():
            shell("am", "force-stop", PACKAGE)
            shell("cmd", "uimode", "night", "yes" if dark else "no")
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/popupcontrast-{uuid.uuid4().hex}"
            with tempfile.TemporaryDirectory(prefix="qshopper-popupcontrast-") as temporary:
                database_path = Path(temporary) / "shop_list.sqlite"
                with closing(sqlite3.connect(database_path)) as database:
                    schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                    database.execute("CREATE TABLE lists " + schema)
                    database.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                    database.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                    entries = [(str(uuid.uuid4()), text, 0) for text in ("Milk", "Bread", "Coffee")]
                    database.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)', entries)
                    database.commit()
                settings = Path(temporary) / "QShopper.ini"
                settings.write_text(f"[General]\ntheme={theme}\nprimary=4\naccent={accent}\nactiveList={TABLE}\n", encoding="utf-8")
                shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                for source, destination in ((database_path, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")):
                    staging = "/data/local/tmp/qshopper-popupcontrast-" + uuid.uuid4().hex
                    adb("push", source, staging)
                    shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                    shell("rm", "-f", staging)
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            time.sleep(1)
            ui = tree()
            rows = sorted({bounds(node) for node in ui.iter("node")
                           if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")})
            assert rows, "Fixture rows did not load"
            shell("input", "swipe", width // 2, (rows[0][1] + rows[0][3]) // 2,
                  width // 2, height - 140, 1200)
            ui = tree()
            field = ui.find('.//node[@class="android.widget.EditText"]')
            assert field is not None, "Edit mode did not open"
            left, top, _, bottom = bounds(field)
            shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
            for selector, wanted in (("lists", "default"), ("accent", accent_name), ("primary", "Indogo")):
                combo = None
                for _ in range(6):
                    ui = tree()
                    combo = next((node for node in ui.iter("node")
                                  if node.get("class") == "android.widget.Spinner"
                                  and node.get("content-desc") == wanted
                                  and bounds(node)[1] >= 120 and bounds(node)[3] < height - 100), None)
                    if combo is not None:
                        break
                    shell("input", "swipe", width // 3, height - 400, width // 3, 300, 400)
                assert combo is not None, f"{selector} was not reachable"
                tap(combo)
                ui = tree()
                candidates = [node for node in ui.iter("node")
                              if "Popup" in node.get("resource-id", "")
                              and (node.get("text") == wanted or node.get("content-desc") == wanted)
                              and bounds(node)[3] > bounds(node)[1]]
                assert len(candidates) == 1, f"Selected popup caption not found: {wanted}"
                raw = adb("exec-out", "screencap", "-p")
                (args.output / f"{name}-{selector}.png").write_bytes(raw)
                (args.output / f"{name}-{selector}.xml").write_bytes(ET.tostring(ui))
                foreground, background = caption_colors(Image.open(BytesIO(raw)).convert("RGB"),
                                                        bounds(candidates[0]), selector != "lists")
                contrast = ratio(foreground, background)
                check(f"{name}-{selector}-contrast", contrast >= 4.5,
                      ratio=contrast, foreground=foreground, background=background)
                shell("input", "keyevent", "KEYCODE_BACK")
                ui = tree()
                check(f"{name}-{selector}-back-keeps-drawer",
                      any(node.get("class") == "android.widget.Spinner" for node in ui.iter("node"))
                      and not any("Popup" in node.get("resource-id", "") for node in ui.iter("node")))
            saved_path = args.output / f"{name}-saved.sqlite"
            saved_path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
            with closing(sqlite3.connect(saved_path)) as database:
                saved = database.execute(f'SELECT id,name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()
            normalized = [(str(uuid.UUID(identifier.strip("{}"))), text, checked) for identifier, text, checked in saved]
            check(f"{name}-preserves-data", normalized == entries)
    finally:
        shell("am", "force-stop", PACKAGE)
        shell("cmd", "uimode", "night", original_night)
    assert all(row["passed"] for row in results), "Native popup contrast failures recorded"


if __name__ == "__main__":
    main()
