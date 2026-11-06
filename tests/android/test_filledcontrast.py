"""UI-025: actual day-header, selected-theme icon and Undo fill contrast.

Only an isolated emulator is allowed. Requires Pillow and the existing gesture
helper. Each profile uses disposable data; no physical phone is installed to.
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
PROFILES = {
    "defaults-light": (0, 4, 9, False, (63, 81, 181), (0, 230, 118)),
    "defaults-dark": (1, 4, 9, True, (159, 168, 218), (105, 240, 174)),
    "yellow-light": (0, 12, 11, False, (255, 235, 59), (198, 255, 0)),
    "purple-light": (0, 4, 3, False, (63, 81, 181), (101, 31, 255)),
    "system-light": (2, 4, 9, False, (63, 81, 181), (0, 230, 118)),
    "system-dark": (2, 4, 9, True, (159, 168, 218), (105, 240, 174)),
}


def matches(a, b, tolerance=4):
    return max(abs(x - y) for x, y in zip(a, b)) <= tolerance


def ratio(front, back):
    def luminance(rgb):
        values = [channel / 255 for channel in rgb]
        values = [value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4
                  for value in values]
        return sum(a * b for a, b in zip(values, (.2126, .7152, .0722)))
    a, b = sorted((luminance(front), luminance(back)))
    return (b + .05) / (a + .05)


def fill_bounds(image, color, region):
    pixels = image.load()
    left, top, right, bottom = region
    spans, start = [], None
    for y in range(top, bottom):
        count = sum(matches(pixels[x, y], color) for x in range(left, right, 2))
        if count >= 12 and start is None:
            start = y
        if count < 12 and start is not None:
            spans.append((start, y))
            start = None
    if start is not None:
        spans.append((start, bottom))
    assert spans, f"Filled shape not found: {color} in {region}"
    top, bottom = max(spans, key=lambda span: span[1] - span[0])
    positions = [x for y in range(top, bottom, 2) for x in range(left, right, 2)
                 if matches(pixels[x, y], color)]
    return min(positions), top, max(positions) + 1, bottom


def glyph_color(image, box, candidates):
    crop = image.crop(box)
    pixels = crop.load()
    counts = [sum(matches(pixels[x, y], color) for y in range(crop.height) for x in range(crop.width))
              for color in candidates]
    best = max(range(len(counts)), key=counts.__getitem__)
    assert counts[best] >= 15, f"No actual glyph core pixels in {box}: {counts}"
    return candidates[best]


def undo_fill(image):
    # The leading padding is opaque and text-free. Its saturated flat run cannot
    # come from the shopping background under the normal 80% neutral surface.
    x = round(image.width * .05)
    pixels = image.load()
    spans, start, color = [], None, None
    for y in range(round(image.height * .65), image.height - 80):
        pixel = pixels[x, y]
        inside = max(pixel) - min(pixel) > 55
        if start is not None and (not inside or not matches(pixel, color, 2)):
            spans.append((start, y, color))
            start = None
        if inside and start is None:
            start, color = y, pixel
    spans = [span for span in spans if image.height * .03 < span[1] - span[0] < image.height * .1]
    assert spans, "Opaque Undo fill was not found"
    return max(spans, key=lambda span: span[1] - span[0])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--profile", choices=["all", *PROFILES], default="all")
    parser.add_argument("--checked-underlay", action="store_true",
                        help="Also verify the opaque Undo surface above inverse checked rows")
    parser.add_argument("--gesture-jar", type=Path, default=Path("out/android-emulator/back-gesture/gesture.jar"))
    parser.add_argument("--output", type=Path, default=Path("out/android-filledcontrast"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    assert args.gesture_jar.is_file(), "Build the existing BackGesture helper first"
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
        assert "dumped to" in shell("uiautomator", "dump", "/sdcard/qshopper-contrast.xml")
        return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-contrast.xml"))

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def rows(ui):
        return sorted({bounds(node) for node in ui.iter("node")
                       if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                       and bounds(node)[3] > bounds(node)[1] and bounds(node)[1] > 100})

    def saved(data):
        with tempfile.TemporaryDirectory(prefix="qshopper-contrast-read-") as temporary:
            path = Path(temporary) / "saved.sqlite"
            path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
            with closing(sqlite3.connect(path)) as database:
                records = database.execute(f'SELECT id,name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()
                return [(str(uuid.UUID(identifier.strip("{}"))), name, checked)
                        for identifier, name, checked in records]

    results = []

    def check(name, passed, **details):
        results.append(dict(case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, details, flush=True)

    assert shell("getprop", "ro.kernel.qemu") == "1"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    night = re.search(r"(yes|no|auto)", shell("cmd", "uimode", "night")).group(1)
    helper = "/data/local/tmp/qshopper-contrast-" + uuid.uuid4().hex + ".jar"
    adb("push", args.gesture_jar, helper)
    profiles = PROFILES if args.profile == "all" else {args.profile: PROFILES[args.profile]}
    try:
        for name, (theme, primary, accent, dark, primary_rgb, accent_rgb) in profiles.items():
            shell("am", "force-stop", PACKAGE)
            shell("cmd", "statusbar", "collapse")
            if theme == 2:
                shell("cmd", "uimode", "night", "yes" if dark else "no")
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/contrast-{uuid.uuid4().hex}"
            with tempfile.TemporaryDirectory(prefix="qshopper-contrast-") as temporary:
                fixture = Path(temporary) / "shop_list.sqlite"
                entries = [(str(uuid.uuid4()), text, 0) for text in ("Milk", "Bread", "Coffee")]
                if args.checked_underlay:
                    entries.extend((str(uuid.uuid4()), f"Checked {index}", 1) for index in range(24))
                with closing(sqlite3.connect(fixture)) as database:
                    schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                    database.execute("CREATE TABLE lists " + schema)
                    database.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                    database.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                    database.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)', entries)
                    database.commit()
                settings = Path(temporary) / "QShopper.ini"
                settings.write_text(f"[General]\ntheme={theme}\nprimary={primary}\naccent={accent}\n"
                                    f"swipeSensitivity=3\nactiveList={TABLE}\n", encoding="utf-8")
                shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                for source, destination in ((fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")):
                    staging = "/data/local/tmp/qshopper-contrast-" + uuid.uuid4().hex
                    adb("push", source, staging)
                    shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                    shell("rm", "-f", staging)
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            time.sleep(1.2)
            ui = tree()
            first = rows(ui)[0]
            if not args.checked_underlay:
                # Hold a real pull below the mode-change threshold while taking the frame.
                command = f"CLASSPATH={helper} app_process /system/bin BackGesture {width // 2} {width // 2} {(first[1] + first[3]) // 2} false 0 {(first[1] + first[3]) // 2 + 800} 2500"
                gesture = subprocess.Popen([args.adb, "-s", args.serial, "shell", command], stdout=subprocess.DEVNULL)
                time.sleep(.65)
                image = screenshot(name + "-day")
                gesture.wait(timeout=10)
                circle = fill_bounds(image, primary_rgb, (0, 100, width // 3, height // 3))
                left, top, right, bottom = circle
                inset = min(right - left, bottom - top) // 5
                assert bottom - top >= (right - left) * .7, "Header circle was clipped; capture during the held pull"
                foreground = glyph_color(image, (left + inset, top + inset, right - inset, bottom - inset),
                                         ((0, 0, 0), (255, 255, 255)))
                check(name + "-day", ratio(foreground, primary_rgb) >= 4.5,
                      ratio=ratio(foreground, primary_rgb), foreground=foreground, fill=primary_rgb)
                time.sleep(.6)
            ui = tree()
            first = rows(ui)[0]
            shell("input", "swipe", width // 2, (first[1] + first[3]) // 2,
                  width // 2, height - 140, 1200)
            time.sleep(.8)
            ui = tree()
            field = ui.find('.//node[@class="android.widget.EditText"]')
            assert field is not None, "Pull did not enter edit mode"
            left, top, _, bottom = bounds(field)
            shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
            ui = tree()
            label = "System" if theme == 2 else "Dark" if dark else "Light"
            button = next(node for node in ui.iter("node") if node.get("class") == "android.widget.Button"
                          and (node.get("content-desc") == label or node.get("text") == label))
            box = bounds(button)
            image = screenshot(name + "-selected")
            fill = fill_bounds(image, accent_rgb, (box[0], box[1], box[2], box[3]))
            left, top, right, bottom = fill
            inset = (right - left) // 6
            foreground = glyph_color(image, (left + inset, top + inset, right - inset, bottom - inset),
                                     ((0, 0, 0), (255, 255, 255)))
            check(name + "-selected", ratio(foreground, accent_rgb) >= 3,
                  ratio=ratio(foreground, accent_rgb), foreground=foreground, fill=accent_rgb)
            shell("input", "tap", round(width * .98), height // 2)
            ui = tree()
            left, top, right, bottom = rows(ui)[0]
            shell("input", "swipe", round(width * .15), (top + bottom) // 2,
                  round(width * .85), (top + bottom) // 2, 350)
            time.sleep(.8)
            assert len(saved(data)) == len(entries) - 1, "Delete did not remove one fixture row"
            image = screenshot(name + "-undo")
            top, bottom, color = undo_fill(image)
            foreground = (255, 255, 255) if dark else tuple(round(channel * (1 - 221 / 255)) for channel in color)
            glyph_color(image, (round(width * .07), top + 10, round(width * .4), bottom - 10), (foreground,))
            check(name + "-undo", ratio(foreground, color) >= 4.5,
                  ratio=ratio(foreground, color), foreground=foreground, fill=color)
            if args.checked_underlay:
                # At this point a checked row fills the bottom of the viewport.
                # Wait until the right-hand message/icon area is uncovered by progress.
                time.sleep(8)
                image = screenshot(name + "-undo-checked-underlay")
                expected = (28, 27, 31) if dark else (255, 251, 254)
                samples = [image.getpixel((round(width * x), round(top + (bottom - top) * .85)))
                           for x in (.6, .7, .8)]
                check(name + "-opaque-unchecked-surface", all(matches(pixel, expected, 2) for pixel in samples),
                      pixels=samples, expected=expected)
                glyph_color(image, (round(width * .07), top + 10, round(width * .4), bottom - 10),
                            ((255, 255, 255) if dark else (34, 33, 34), foreground))
            shell("input", "tap", round(width * .2), (top + bottom) // 2)
            time.sleep(.5)
            check(name + "-undo-restores-data", saved(data) == entries)
    finally:
        shell("am", "force-stop", PACKAGE)
        shell("cmd", "uimode", "night", night)
        shell("rm", "-f", helper)
    assert all(result["passed"] for result in results), "Native contrast failures recorded"


if __name__ == "__main__":
    main()
