"""UI-028: held native swipes, actual glyph pixels and saved action outcomes.

Requires Pillow and the test gesture helper. Only an isolated emulator is allowed.
Body contrast uses opaque glyph cores and adjacent tinted pixels from one frame,
so moving slideshow images cannot invalidate a separate background reference.
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
from test_filledcontrast import PACKAGE, TABLE, matches, ratio


PROFILES = {}
for theme in (0, 1):
    for editing in (False, True):
        for checked in (False, True):
            for right in (False, True):
                name = "-".join(("light" if theme == 0 else "dark", "edit" if editing else "shop",
                                 "checked" if checked else "unchecked", "right" if right else "left"))
                PROFILES[name] = (theme, theme == 1, editing, checked, right)
for dark in (False, True):
    for editing in (False, True):
        PROFILES[f"system-{'dark' if dark else 'light'}-{'delete' if editing else 'check'}"] = (2, dark, editing, editing, True)


def feedback_pixel(pixel, tint):
    # A fixed .8 action tint over any RGB photograph stays inside these bounds.
    return all(round(.8 * color) - 3 <= value <= round(.8 * color + .2 * 255) + 3
               for value, color in zip(pixel, tint))


def measure_body(image, box, tint):
    left, top, right, bottom = box
    candidates = ((0, 0, 0), (28, 27, 31), (255, 251, 254))
    cores = {ink: [(x, y) for y in range(top + 3, bottom - 3) for x in range(left + 3, right - 3)
                   if matches(image.getpixel((x, y)), ink, 2)] for ink in candidates}
    ink = max(cores, key=lambda color: len(cores[color]))
    assert len(cores[ink]) >= 30, "Actual body cores missing"
    ratios = []
    for x, y in cores[ink]:
        for dx, dy in ((-4, 0), (4, 0), (0, -4), (0, 4)):
            adjacent = image.getpixel((x + dx, y + dy))
            if feedback_pixel(adjacent, tint):
                ratios.append(ratio(ink, adjacent))
    assert len(ratios) >= 30, "Actual adjacent feedback pixels missing"
    return ink, len(cores[ink]), min(ratios), len(ratios)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--profile", choices=["all", *PROFILES], default="all")
    parser.add_argument("--output", type=Path, default=Path("out/android-swipecontrast"))
    parser.add_argument("--gesture-jar", type=Path, default=Path("out/android-emulator/back-gesture/gesture.jar"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    assert args.gesture_jar.is_file(), "Build the existing BackGesture helper"
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def screenshot(name):
        raw = adb("exec-out", "screencap", "-p")
        (args.output / (name + ".png")).write_bytes(raw)
        return Image.open(BytesIO(raw)).convert("RGB")

    def tree():
        for _ in range(3):
            shell("rm", "-f", "/sdcard/qshopper-swipecontrast.xml")
            if "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-swipecontrast.xml"):
                return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-swipecontrast.xml"))
        raise RuntimeError("Could not read a current Android UI tree")

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def target(ui, checked):
        candidates = sorted({bounds(node) for node in ui.iter("node")
                             if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                             and bounds(node)[3] > bounds(node)[1]})
        assert len(candidates) == 3, "Three fixture delegates must be visible"
        # The fixture puts Milk first when unchecked and last when checked.
        # Native Qt's delegate nodes do not expose their content text here.
        return candidates[-1 if checked else 0]

    def saved(data):
        with tempfile.TemporaryDirectory(prefix="qshopper-swipecontrast-read-") as temporary:
            path = Path(temporary) / "saved.sqlite"
            path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
            with closing(sqlite3.connect(path)) as database:
                entries = database.execute(f'SELECT id,name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()
        return [(str(uuid.UUID(identifier.strip("{}"))), text, checked) for identifier, text, checked in entries]

    def check(name, passed, **details):
        results.append(dict(case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, details, flush=True)

    assert shell("getprop", "ro.kernel.qemu") == "1"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    original_night = re.search(r"(yes|no|auto)", shell("cmd", "uimode", "night")).group(1)
    helper = "/data/local/tmp/qshopper-swipecontrast-" + uuid.uuid4().hex + ".jar"
    adb("push", args.gesture_jar, helper)
    results = []
    profiles = PROFILES if args.profile == "all" else {args.profile: PROFILES[args.profile]}
    try:
        for name, (theme, dark, editing, checked, right) in profiles.items():
            shell("am", "force-stop", PACKAGE)
            shell("cmd", "statusbar", "collapse")
            shell("cmd", "uimode", "night", "yes" if dark else "no")
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/swipecontrast-{uuid.uuid4().hex}"
            with tempfile.TemporaryDirectory(prefix="qshopper-swipecontrast-") as temporary:
                fixture = Path(temporary) / "shop_list.sqlite"
                entries = [(str(uuid.uuid4()), text, int(checked and text == "Milk")) for text in ("Milk", "Bread", "Coffee")]
                if checked:
                    entries = entries[1:] + entries[:1]
                milk = next(entry for entry in entries if entry[1] == "Milk")
                with closing(sqlite3.connect(fixture)) as database:
                    schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                    database.execute("CREATE TABLE lists " + schema)
                    database.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                    database.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                    database.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)', entries)
                    database.commit()
                settings = Path(temporary) / "QShopper.ini"
                settings.write_text(f"[General]\ntheme={theme}\nprimary=4\naccent=9\nswipeSensitivity=0\nactiveList={TABLE}\n", encoding="utf-8")
                shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                for source, destination in ((fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")):
                    staging = "/data/local/tmp/qshopper-swipecontrast-" + uuid.uuid4().hex
                    adb("push", source, staging)
                    shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                    shell("rm", "-f", staging)
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            time.sleep(1.2)
            ui = tree()
            if editing:
                rows = sorted({bounds(node) for node in ui.iter("node") if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_") and bounds(node)[3] > bounds(node)[1]})
                first = rows[0]
                shell("input", "swipe", width // 2, (first[1] + first[3]) // 2, width // 2, height - 140, 1200)
                ui = tree()
                assert ui.find('.//node[@class="android.widget.EditText"]') is not None, "Edit mode did not open"
            left, top, right_edge, bottom = target(ui, checked)
            size = bottom - top
            start_x, end_x = round(width * (.15 if right else .85)), round(width * (.8 if right else .2))
            y = (top + bottom) // 2
            tint = (244, 67, 54) if editing and right else (76, 175, 80)
            icon_left = left if right else right_edge - size
            icon_right = icon_left + size

            # Validate beyond the icon, so antialiased glyph/outline edges are
            # never mistaken for an invalid background reference.
            clear = [(round(left + size * x if right else right_edge - size * x), round(top + size * py))
                     for x in (1.25, 1.4, 1.6, 1.8) for py in (.2, .35, .5, .65, .8)]
            screenshot(name + "-before")
            command = f"CLASSPATH={helper} app_process /system/bin BackGesture {start_x} {end_x} {y} true 0 {y} -1"
            gesture = subprocess.Popen([args.adb, "-s", args.serial, "shell", command],
                                       stdin=subprocess.PIPE, stdout=subprocess.PIPE)
            assert gesture.stdout.readline().strip() == b"HELD", "Gesture did not reach its held position"
            time.sleep(.3)
            moving = screenshot(name + "-arrow")
            # Sample the outgoing arrow while visible, then let the body fade
            # settle. CartOut deliberately moves its arrow outside the clip.
            time.sleep(.65)
            actual = screenshot(name + "-held")
            gesture.stdin.write(b"\n")
            gesture.stdin.flush()
            gesture.wait(timeout=10)
            time.sleep(.35)
            valid = sum(feedback_pixel(actual.getpixel(point), tint) for point in clear)
            check(name + "-feedback-color", valid / len(clear) >= .95, matching=valid, total=len(clear))
            assert valid / len(clear) >= .95, "Actual red/green strip was not revealed"
            ink, core_count, minimum, pairs = measure_body(actual, (icon_left, top, icon_right, bottom), tint)
            check(name + "-body", minimum >= 3, minimum=minimum, foreground=ink, corePixels=core_count, adjacentSamples=pairs)
            arrow_frame = moving if checked and not (editing and right) else actual
            arrow = [arrow_frame.getpixel((x, py)) for py in range(top + 3, bottom - 3)
                     for x in range(icon_left + 3, icon_right - 3)
                     if min(arrow_frame.getpixel((x, py))) > 190
                     and max(arrow_frame.getpixel((x, py))) - min(arrow_frame.getpixel((x, py))) < 15]
            arrow_contrast = min((ratio(pixel, ink) for pixel in arrow), default=0)
            check(name + "-arrow", len(arrow) >= 15 and arrow_contrast >= 3,
                  pixels=len(arrow), minimum=arrow_contrast)
            check(name + "-cancel-preserves-data", saved(data) == entries)
            shell("input", "swipe", start_x, y, end_x, y, 350)
            time.sleep(.6)
            current = saved(data)
            if editing and right:
                check(name + "-delete", current == [entry for entry in entries if entry[0] != milk[0]])
            else:
                expected = {identifier: (text, int(not flag) if identifier == milk[0] else flag) for identifier, text, flag in entries}
                check(name + "-toggle", {identifier: (text, flag) for identifier, text, flag in current} == expected)
    finally:
        shell("am", "force-stop", PACKAGE)
        shell("cmd", "uimode", "night", original_night)
        shell("rm", "-f", helper)
    assert all(row["passed"] for row in results), "Native swipe regression failures recorded"


if __name__ == "__main__":
    main()
