"""UI-012: offline Qt/Font Awesome texts, scrolling and Android Back layers.

Uses disposable data on an isolated emulator only. Requires Pillow.
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

PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"
ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-about"))
    parser.add_argument("--privacy", action="store_true", help="Exercise the bundled privacy policy instead of licenses")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def tree():
        result = shell("uiautomator", "dump", "/sdcard/qshopper-about.xml")
        assert "dumped to" in result, result
        return ET.fromstring(adb("exec-out", "cat", "/sdcard/qshopper-about.xml"))

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def named(ui, name):
        return next((node for node in ui.iter("node")
                     if node.get("text") == name or node.get("content-desc") == name), None)

    def editor(ui):
        return next((node for node in ui.iter("node")
                     if node.get("package") == PACKAGE and node.get("class") == "android.widget.EditText"
                     and node.get("content-desc") != "License text"), None)

    def wait_ui(predicate):
        for _ in range(8):
            ui = tree()
            if predicate(ui):
                return ui
            time.sleep(0.15)
        raise AssertionError("Android UI did not reach the expected state")

    def tap(node):
        assert node is not None
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    def keyboard():
        return "mInputShown=true" in shell("dumpsys", "input_method")

    def back(edge):
        start = 1 if edge == "left" else width - 4
        end = width // 3 if edge == "left" else width * 2 // 3
        shell("input", "swipe", start, height // 3, end, height // 3, 250)

    def saved():
        path = args.output / "saved.sqlite"
        path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(path)) as database:
            return database.execute(f'SELECT id,name,checked FROM "{TABLE}" ORDER BY rowid').fetchall()

    results = []

    def check(name, passed, ui, **details):
        (args.output / f"{theme}-{name}.xml").write_bytes(ET.tostring(ui))
        (args.output / f"{theme}-{name}.png").write_bytes(adb("exec-out", "screencap", "-p"))
        results.append(dict(case=f"{theme}_{name}", passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + f"{theme}_{name}", flush=True)
        assert passed, name

    def open_drawer(ui):
        field = editor(ui)
        assert field is not None
        left, top, _, bottom = bounds(field)
        shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
        wait_ui(lambda state: named(state, "Lists") is not None or named(state, "Licenses") is not None)
        shell("input", "swipe", width // 3, height * 3 // 4, width // 3, height // 3, 350)
        return wait_ui(lambda state: named(state, "Licenses") is not None)

    def open_about(ui):
        tap(named(ui, "Licenses"))
        return wait_ui(lambda state: named(state, "License text") is not None)

    def visible_text(ui):
        return [(node.get("text") or node.get("content-desc", "")).replace("\u2029", "\n").replace("\u2028", "\n").strip()
                for node in ui.iter("node")]

    def privacy_policy(ui):
        button = named(ui, "Privacy policy")
        assert button is not None, "Drawer must provide Privacy policy"
        tap(button)
        ui = wait_ui(lambda state: any("samuel.nevala@gmail.com" in text for text in visible_text(state)))
        check("privacy_offline_text", all(any(marker in text for text in visible_text(ui))
              for marker in ("Android backup", "Google Play purchases", "samuel.nevala@gmail.com"))
              and not keyboard(), ui)

        def bar(state):
            return next(node for node in state.iter("node")
                        if node.get("resource-id", "").endswith("privacyScrollBar"))

        left, top, right, bottom = bounds(bar(ui))
        x = left // 2
        initial = float(bar(ui).get("content-desc", "0"))
        shell("input", "swipe", x, top + (bottom - top) * 4 // 5,
              x, top + (bottom - top) // 4, 700)
        ui = wait_ui(lambda state: float(bar(state).get("content-desc", "0")) > initial)
        moved = float(bar(ui).get("content-desc", "0"))
        check("privacy_body_swipe_up", moved > initial and not keyboard(), ui)
        shell("input", "swipe", x, top + (bottom - top) // 4,
              x, top + (bottom - top) * 4 // 5, 700)
        ui = wait_ui(lambda state: float(bar(state).get("content-desc", "0")) < moved)
        check("privacy_body_swipe_down", not keyboard(), ui)
        for edge in ("left", "right"):
            back(edge)
            ui = wait_ui(lambda state: named(state, "Licenses") is not None
                         and not any("samuel.nevala@gmail.com" in text for text in visible_text(state)))
            check(edge + "_back_only_privacy", named(ui, "Privacy policy") is not None and not keyboard(), ui)
            tap(named(ui, "Privacy policy"))
            ui = wait_ui(lambda state: any("samuel.nevala@gmail.com" in text for text in visible_text(state)))
        tap(named(ui, "Close"))
        ui = wait_ui(lambda state: named(state, "Licenses") is not None
                     and not any("samuel.nevala@gmail.com" in text for text in visible_text(state)))
        check("privacy_close_preserves_drawer", named(ui, "Privacy policy") is not None and not keyboard(), ui)
        return ui

    def select_notice(ui, tab, filename):
        expected = (ROOT / "app/licenses" / filename).read_text(encoding="utf-8").split("\n\n")[0].strip()
        if expected not in visible_text(ui):
            tap(named(ui, tab))
            ui = wait_ui(lambda state: expected in visible_text(state))
        check(tab.lower().replace(" ", "-") + "_offline_header", expected in visible_text(ui), ui)
        return ui

    def body_swipes(ui):
        left, top, right, bottom = bounds(named(ui, "License text"))
        def position(state):
            bars = [node for node in state.iter("node")
                    if node.get("class") == "android.widget.Scroller"
                    and "licenseScroll" in node.get("resource-id", "")
                    and bounds(node)[3] - bounds(node)[1] > bounds(node)[2] - bounds(node)[0]]
            assert len(bars) == 1
            return float(bars[0].get("content-desc", "0"))
        shell("input", "swipe", (left + right) // 2, top + (bottom - top) * 4 // 5,
              (left + right) // 2, top + (bottom - top) // 4, 700)
        ui = wait_ui(lambda state: position(state) > 0)
        moved = position(ui)
        check("body_swipe_up", moved > 0 and not keyboard(), ui)
        shell("input", "swipe", (left + right) // 2, top + (bottom - top) // 4,
              (left + right) // 2, top + (bottom - top) * 4 // 5, 700)
        ui = wait_ui(lambda state: position(state) < moved)
        check("body_swipe_down", position(ui) < moved and not keyboard(), ui)
        return ui

    def scroll_end(ui, label, filename):
        bars = [node for node in ui.iter("node") if node.get("class") == "android.widget.Scroller"
                and "licenseScroll" in node.get("resource-id", "")
                and bounds(node)[3] - bounds(node)[1] > bounds(node)[2] - bounds(node)[0]]
        assert len(bars) == 1, "Vertical license scrollbar missing"
        left, top, right, bottom = bounds(bars[0])
        # The minimum thumb height is the same 9.27 mm as a list row.
        thumb = (right - left) * 9.27 / 3
        position = float(bars[0].get("content-desc", "0")) / 100
        shell("input", "swipe", (left + right) // 2, round(top + thumb / 2 + position * (bottom - top - thumb)),
              (left + right) // 2, bottom - 2, 700)
        ui = wait_ui(lambda state: any(float(node.get("content-desc", "0")) > 0
                     for node in state.iter("node") if node.get("class") == "android.widget.Scroller"
                     and "licenseScroll" in node.get("resource-id", "")
                     and bounds(node)[3] - bounds(node)[1] > bounds(node)[2] - bounds(node)[0]))
        image = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
        column = [image.getpixel(((left + right) // 2, y)) for y in range(top + 4, bottom - 4)]
        background = Counter(column).most_common(1)[0][0]
        thumb_pixels = [top + 4 + y for y, pixel in enumerate(column)
                        if max(abs(a - b) for a, b in zip(pixel, background)) > 10]
        ending = (ROOT / "app/licenses" / filename).read_text(encoding="utf-8").strip().rsplit("\n\n", 1)[-1].strip()
        check(label + "_scroll_end", bool(thumb_pixels) and max(thumb_pixels) >= bottom - 9,
              ui, thumb_bottom=max(thumb_pixels) if thumb_pixels else None, track_bottom=bottom)
        assert any(ending in text for text in visible_text(ui)), "Last notice paragraph must be accessible"
        return ui

    assert shell("getprop", "ro.kernel.qemu") == "1"
    assert shell("settings", "get", "secure", "navigation_mode") == "2"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    wifi = shell("settings", "get", "global", "wifi_on") == "1"
    mobile = shell("settings", "get", "global", "mobile_data") == "1"
    try:
        shell("svc", "wifi", "disable")
        shell("svc", "data", "disable")
        for theme in (0, 1):
            shell("am", "force-stop", PACKAGE)
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/about-{uuid.uuid4().hex}"
            with tempfile.TemporaryDirectory(prefix="qshopper-about-") as temporary:
                fixture = Path(temporary) / "shop_list.sqlite"
                with closing(sqlite3.connect(fixture)) as database:
                    schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                    database.execute("CREATE TABLE lists " + schema)
                    database.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                    database.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                    database.executemany(f'INSERT INTO "{TABLE}" VALUES (?,?,?)',
                                         [(str(uuid.uuid4()), name, int(index == 2))
                                          for index, name in enumerate(["milk", "bread", "oats"])])
                    database.commit()
                settings = Path(temporary) / "QShopper.ini"
                settings.write_text(f"[General]\ntheme={theme}\nactiveList={TABLE}\n", encoding="utf-8")
                shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                for source, destination in [(fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")]:
                    staging = "/data/local/tmp/qshopper-about-" + uuid.uuid4().hex
                    adb("push", source, staging)
                    shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                    shell("rm", "-f", staging)
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            ui = wait_ui(lambda state: any(node.get("resource-id") == "chooser"
                         or node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                         for node in state.iter("node")))
            rows = [bounds(node) for node in ui.iter("node") if node.get("resource-id") == "chooser"
                    or node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")]
            shell("input", "swipe", width // 2, max(row[3] for row in rows) + 80,
                  width // 2, height - 140, 1200)
            ui = wait_ui(lambda state: editor(state) is not None)
            tap(editor(ui))
            shell("input", "text", "licensedraft")
            ui = wait_ui(lambda state: editor(state) is not None
                         and editor(state).get("text") == "licensedraft")
            before = saved()
            ui = open_drawer(ui)
            if args.privacy:
                ui = privacy_policy(ui)
                check("privacy_keeps_saved_items", saved() == before, ui)
                back("right")
                ui = wait_ui(lambda state: editor(state) is not None and named(state, "Licenses") is None)
                check("privacy_keeps_draft", editor(ui).get("text") == "licensedraft"
                      and saved() == before and not keyboard(), ui)
                continue
            ui = open_about(ui)
            display = shell("dumpsys", "window", "displays")
            top_safe, bottom_safe = 0, height
            for kind, _, top, _, bottom in re.findall(
                    r"type=(statusBars|navigationBars) frame=\[(\d+),(\d+)\]\[(\d+),(\d+)\][^\n]*visible=true", display):
                if kind == "statusBars":
                    top_safe = max(top_safe, int(bottom))
                else:
                    bottom_safe = min(bottom_safe, int(top))
            assert top_safe > 0 and bottom_safe < height
            check("safe_bounds_and_no_ime", not keyboard()
                  and bounds(named(ui, "Open-source licenses"))[1] >= top_safe
                  and bounds(named(ui, "Open-source licenses"))[3] <= bottom_safe, ui,
                  safe_top=top_safe, safe_bottom=bottom_safe)
            ui = select_notice(ui, "Qt", "Qt-Android.txt")
            image = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
            left, top, right, _ = bounds(named(ui, "Open-source licenses"))
            surface = image.getpixel(((left + right) // 2, top + 20))
            check("theme_surface", min(surface) > 200 if theme == 0 else max(surface) < 110,
                  ui, rgb=surface)
            ui = body_swipes(ui)
            ui = scroll_end(ui, "qt", "Qt-Android.txt")
            ui = select_notice(ui, "Font Awesome", "FontAwesome.txt")
            ui = scroll_end(ui, "font", "FontAwesome.txt")
            check("reading_preserves_data", saved() == before and not keyboard(), ui)
            back("left")
            ui = wait_ui(lambda state: named(state, "License text") is None)
            check("left_back_only_about", named(ui, "Licenses") is not None and saved() == before, ui)
            back("right")
            ui = wait_ui(lambda state: named(state, "Licenses") is None and editor(state) is not None)
            check("next_back_only_drawer", editor(ui).get("text") == "licensedraft"
                  and saved() == before and not keyboard(), ui)
            ui = open_about(open_drawer(ui))
            back("right")
            ui = wait_ui(lambda state: named(state, "License text") is None)
            check("right_back_only_about", named(ui, "Licenses") is not None and saved() == before, ui)
            ui = open_about(ui)
            tap(named(ui, "Close"))
            ui = wait_ui(lambda state: named(state, "License text") is None)
            check("close_button_keeps_drawer", named(ui, "Licenses") is not None and saved() == before, ui)
    finally:
        shell("am", "force-stop", PACKAGE)
        shell("svc", "wifi", "enable" if wifi else "disable")
        shell("svc", "data", "enable" if mobile else "disable")


if __name__ == "__main__":
    main()
