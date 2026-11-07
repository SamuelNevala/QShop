"""QA-003: English QWERTY Gboard entry, real Return, drawer and cold settings.

Only the isolated QShopper_API_36 emulator is supported. Requires Pillow.
Key coordinates are relative to native IME/navigation insets for its configured
Gboard layout. Screenshots and coordinates are saved; other IMEs are rejected.
No microphone or speech service is activated.
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

from undo_bar import undo_bar_frame

PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-entry"))
    parser.add_argument("--gesture-jar", type=Path, default=Path("out/android-emulator/back-gesture/gesture.jar"))
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator serial is allowed")
    if not args.gesture_jar.is_file():
        parser.error("Build the gesture helper with tools/build-android-gesture-test.ps1 first")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree():
        for _ in range(3):
            path = "/data/local/tmp/qshopper-entry-" + uuid.uuid4().hex + ".xml"
            try:
                if "dumped to" in shell("uiautomator", "dump", path):
                    return ET.fromstring(adb("exec-out", "cat", path))
            finally:
                shell("rm", "-f", path)
        raise RuntimeError("Could not read Android UI")

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def keyboard():
        return "mInputShown=true" in shell("dumpsys", "input_method")

    def tap(node, position="center"):
        left, top, right, bottom = bounds(node)
        x = left + (bottom - top) // 2 if position == "left" else (
            right - (bottom - top) // 2 if position == "right" else (left + right) // 2)
        shell("input", "tap", x, (top + bottom) // 2)

    def saved(table=TABLE):
        path = args.output / "saved.sqlite"
        path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(path)) as db:
            return db.execute(f'SELECT name,checked,id FROM "{table}" ORDER BY rowid').fetchall()

    results = []

    def check(name, passed, ui):
        if ui is not None:
            (args.output / (name + ".xml")).write_bytes(ET.tostring(ui))
        (args.output / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
        results.append(dict(case=name, passed=bool(passed), saved=saved()))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        assert passed, name

    def launch():
        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
              "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
        for _ in range(6):
            ui = tree()
            if any(n.get("package") == PACKAGE and n.get("class") == "android.widget.EditText"
                   or n.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                   for n in ui.iter("node")):
                return ui
            time.sleep(0.3)
        raise RuntimeError("App fixture did not load")

    def open_keyboard(ui):
        field = editor(ui)
        assert field is not None, "Editor was not found"
        tap(field)
        for _ in range(20):
            if keyboard():
                break
            time.sleep(0.1)
        assert keyboard(), "Gboard did not open"
        display = shell("dumpsys", "window", "displays")
        ime = re.search(r"type=ime frame=\[0,(\d+)\]\[\d+,\d+\][^\n]*visible=true", display)
        nav = re.search(r"type=navigationBars frame=\[0,(\d+)\]\[\d+,\d+\][^\n]*visible=true", display)
        assert ime and nav, "Native keyboard insets were not found"
        return int(ime[1]), int(nav[1])

    def gboard_key(x, y, insets):
        top, bottom = insets
        point = (round(width * x), round(top + (bottom - top) * y))
        shell("input", "tap", *point)
        return point

    def back():
        shell("input", "swipe", 1, height // 3, width // 3, height // 3, 250)
        return tree()

    def item_rect(ui, name, table=TABLE):
        rectangles = sorted({bounds(n) for n in ui.iter("node") if n.get("resource-id", "")
                             .rsplit(".", 1)[-1].startswith("TextDelegate_")}, key=lambda rect: rect[1])
        names = [record[0].lower() for record in saved(table)]
        assert len(rectangles) == len(names), "Fixture rows are not all visible"
        return rectangles[names.index(name.lower())]

    def item_tap(ui, name, table=TABLE, twice=False):
        left, top, right, bottom = item_rect(ui, name, table)
        if twice:
            adb("shell", f"CLASSPATH={staging}.jar app_process /system/bin BackGesture "
                f"double-tap {(left + right) // 2} {(top + bottom) // 2}")
        else:
            shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
        return tree()

    def item_swipe(ui, name, table=TABLE, rightward=False):
        left, top, right, bottom = item_rect(ui, name, table)
        start, end = (.15, .85) if rightward else (.85, .15)
        shell("input", "swipe", int(left + (right - left) * start), (top + bottom) // 2,
              int(left + (right - left) * end), (top + bottom) // 2, 250)
        if rightward:
            time.sleep(.8)
            return None
        return tree()

    def pull_mode(ui, short=False):
        rectangles = sorted({bounds(node) for node in ui.iter("node")
                             if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")})
        assert rectangles, "Mode pull needs a real shopping row"
        left, top, right, bottom = rectangles[0]
        start_y = (top + bottom) // 2
        shell("input", "swipe", width // 2, start_y, width // 2,
              start_y + 60 if short else height - 140, 350 if short else 1200)
        time.sleep(.6)  # The production pulley delays mode changes after release.
        return tree()

    def enter_text(ui, text, replace=False):
        if replace:
            tap(editor(ui), "right")
            ui = tree()
        insets = open_keyboard(ui)
        shell("input", "text", text)
        gboard_key(.925, .82, insets)
        return tree()

    def select_list(ui, name):
        tap(editor(ui), "left")
        ui = tree()
        combo = next(n for n in ui.iter("node") if n.get("class") == "android.widget.Spinner"
                     and "ColorComboBox_" not in n.get("resource-id", ""))
        tap(combo)
        ui = tree()
        options = [n for n in ui.iter("node") if "Popup" in n.get("resource-id", "")
                   and name in (n.get("text"), n.get("content-desc")) and bounds(n)[3] > bounds(n)[1]]
        assert len(options) == 1, "List option was not found: " + name
        tap(options[0])
        return tree()

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    assert "com.google.android.inputmethod.latin" in shell("settings", "get", "secure", "default_input_method"), "Use configured Gboard"
    assert shell("settings", "get", "secure", "navigation_mode") == "2", "Use gesture navigation"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    assert width < height, "Use the portrait phone emulator"
    data = f"/data/user/0/{PACKAGE}/files/agent-testing/entry-{uuid.uuid4().hex}"
    (args.output / "data-path.txt").write_text(data, encoding="utf-8")
    with tempfile.TemporaryDirectory(prefix="qshopper-entry-") as temporary:
        fixture = Path(temporary) / "fixture.sqlite"
        with closing(sqlite3.connect(fixture)) as db:
            schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
            db.execute("CREATE TABLE lists " + schema)
            db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
            db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
            db.commit()
        staging = "/data/local/tmp/qshopper-entry-" + uuid.uuid4().hex + ".sqlite"
        adb("push", fixture, staging)
        adb("push", args.gesture_jar, staging + ".jar")
        shell("am", "force-stop", PACKAGE)
        shell("run-as", PACKAGE, "mkdir", "-p", data)
        shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")
        try:
            ui = launch()
            insets = open_keyboard(ui)
            check("native_keyboard_open", keyboard(), tree())
            # English QWERTY key centers, relative to native IME insets.
            positions = {"m": (.8, .62), "i": (.75, .25), "l": (.9, .44), "k": (.8, .44),
                         "b": (.6, .62), "r": (.35, .25), "e": (.25, .25), "a": (.1, .44), "d": (.3, .44)}
            coordinates = []
            for word in ("milk", "bread"):
                for character in word:
                    coordinates.append(gboard_key(*positions[character], insets))
                coordinates.append(gboard_key(.925, .82, insets))
                ui = tree()
                expected = ["milk"] if word == "milk" else ["milk", "bread"]
                check(word + "_native_return_keeps_keyboard", [r[0].lower() for r in saved()] == expected
                      and editor(ui).get("text") == "" and keyboard(), ui)
            (args.output / "key-coordinates.json").write_text(json.dumps(coordinates), encoding="utf-8")
            original = saved()
            gboard_key(.925, .82, insets)
            ui = tree()
            check("empty_native_return_is_noop", saved() == original and keyboard(), ui)
            shell("input", "text", "discard")
            ui = tree()
            tap(editor(ui), "right")
            ui = tree()
            check("clear_editor_preserves_list", editor(ui).get("text") == "" and saved() == original, ui)
            tap(editor(ui))
            shell("input", "text", "unfinished")
            ui = tree()
            tap(editor(ui), "left")
            ui = tree()
            check("drawer_hides_native_keyboard", not keyboard(), ui)
            light = ui.find('.//node[@class="android.widget.Button"][@content-desc="Light"]')
            assert light is not None, "Light theme button was not found"
            tap(light)
            ui = tree()
            sliders = ui.findall('.//node[@class="android.widget.SeekBar"]')
            assert len(sliders) == 1, "Sensitivity slider was not found"
            left, top, right, bottom = bounds(sliders[0])
            shell("input", "tap", right - 4, (top + bottom) // 2)
            ui = tree()
            slider = ui.find('.//node[@class="android.widget.SeekBar"]')
            check("sensitivity_control_reaches_maximum", float(slider.get("content-desc")) == 3, ui)
            settings = shell("run-as", PACKAGE, "cat", data + "/Nevala/QShopper.ini")
            check("theme_and_sensitivity_saved", re.search(r"(?m)^theme=0$", settings)
                  and re.search(r"(?m)^swipeSensitivity=3$", settings), ui)
            shell("input", "tap", width - 20, height // 2)
            ui = tree()
            check("drawer_dismissal_keeps_draft", editor(ui).get("text") == "unfinished", ui)
            open_keyboard(ui)
            ui = back()
            check("back_hides_keyboard_keeps_draft", not keyboard()
                  and editor(ui).get("text") == "unfinished", ui)
            ui = back()
            check("back_discards_draft_leaves_edit", editor(ui) is None and saved() == original, ui)
            ui = item_tap(ui, original[0][0])
            check("shopping_single_tap_preserves_mode_and_items", editor(ui) is None
                  and saved() == original, ui)
            ui = item_tap(ui, original[0][0], twice=True)
            check("shopping_double_tap_preserves_mode_and_items", editor(ui) is None
                  and saved() == original, ui)
            ui = pull_mode(ui, short=True)
            check("short_pull_keeps_shopping_mode", editor(ui) is None and saved() == original, ui)
            ui = pull_mode(ui)
            check("mode_pull_enters_edit", editor(ui) is not None and saved() == original, ui)
            tap(editor(ui), "left")
            ui = tree()
            remove = next(node for node in ui.iter("node") if node.get("class") == "android.widget.Button"
                          and node.get("content-desc", "").startswith("Remove"))
            left, top, right, bottom = bounds(remove)
            assert remove.get("enabled") == "true" and 0 <= left < right <= width and 0 <= top < bottom <= height
            tap(remove)
            time.sleep(.5)
            ui = tree()
            frame = undo_bar_frame(adb("exec-out", "screencap", "-p"), 0)
            drawer_closed = not any(node.get("class") == "android.widget.Button"
                                    and node.get("content-desc") in ("Dark", "Light", "System")
                                    for node in ui.iter("node"))
            check("remove_checked_without_checks_is_noop", saved() == original
                  and editor(ui) is not None and frame is None and drawer_closed, ui)
            ui = pull_mode(ui, short=True)
            check("short_pull_keeps_edit_mode", editor(ui) is not None and saved() == original, ui)
            ui = pull_mode(ui)
            check("mode_pull_leaves_edit", editor(ui) is None and saved() == original, ui)
            shell("am", "force-stop", PACKAGE)
            ui = launch()
            frame = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
            rows = sorted({bounds(n) for n in ui.iter("node") if n.get("resource-id", "")
                           .rsplit(".", 1)[-1].startswith("TextDelegate_")}, key=lambda rect: rect[1])
            left, top, right, bottom = rows[0]
            rgb = frame.getpixel((right - 20, (top + bottom) // 2))
            check("cold_restart_restores_light_theme_and_items", min(rgb) > 180 and saved() == original, ui)
            shell("input", "swipe", width // 2, rows[-1][3] + 80, width // 2, height - 140, 1200)
            ui = tree()
            tap(editor(ui), "left")
            ui = tree()
            slider = ui.find('.//node[@class="android.widget.SeekBar"]')
            check("cold_restart_restores_sensitivity_control", slider is not None
                  and float(slider.get("content-desc")) == 3, ui)
            shell("input", "tap", width - 20, height // 2)
            ui = tree()
            ui = item_tap(ui, "milk")
            ui = enter_text(ui, "butter")
            check("tap_places_editor_for_insertion", [r[0].lower() for r in saved()] == ["milk", "butter", "bread"], ui)
            butter_id = saved()[1][2]
            butter_name = saved()[1][0]
            ui = item_tap(ui, "butter", twice=True)
            assert editor(ui).get("text") == butter_name, "Double tap did not start replacement"
            ui = enter_text(ui, "oats", replace=True)
            check("double_tap_replaces_preserving_identity", [r[0].lower() for r in saved()] == ["milk", "oats", "bread"]
                  and saved()[1][2] == butter_id, ui)
            replacement_original = saved()
            ui = item_tap(ui, "oats", twice=True)
            tap(editor(ui), "right")
            ui = tree()
            open_keyboard(ui)
            shell("input", "text", "unfinished")
            ui = back()
            check("pending_edit_back_hides_ime_only", not keyboard()
                  and editor(ui).get("text") == "unfinished", ui)
            ui = back()
            check("pending_edit_back_restores_original", editor(ui) is None and saved() == replacement_original, ui)
            rows = sorted({bounds(n) for n in ui.iter("node") if n.get("resource-id", "")
                           .rsplit(".", 1)[-1].startswith("TextDelegate_")}, key=lambda rect: rect[1])
            shell("input", "swipe", width // 2, rows[-1][3] + 80, width // 2, height - 140, 1200)
            ui = tree()
            ui = item_swipe(ui, "oats", rightward=True)
            check("single_delete_through_swipe", [r[0].lower() for r in saved()] == ["milk", "bread"], ui)
            frame = undo_bar_frame(adb("exec-out", "screencap", "-p"), 0)
            assert frame is not None, "Floating Undo action was not found"
            shell("input", "tap", frame["action_x"], frame["action_y"])
            ui = tree()
            check("single_delete_undo_icon", saved() == replacement_original, ui)
            ui = item_swipe(ui, "milk")
            insertion = bounds(editor(ui))
            ui = item_tap(ui, "milk")
            left, top, right, bottom = item_rect(ui, "milk")
            shell("input", "swipe", (left + right) // 2, (top + bottom) // 2,
                  (left + right) // 2, (top + bottom) // 2, 1200)
            ui = tree()
            check("checked_tap_and_hold_leave_editor_and_order", bounds(editor(ui)) == insertion
                  and [r[0].lower() for r in saved()] == ["oats", "bread", "milk"] and saved()[-1][1] == 1, ui)
            ui = item_swipe(ui, "milk")
            check("correction_restores_unchecked_order", saved() == replacement_original, ui)
            ui = select_list(ui, "lists")
            ui = enter_text(ui, "weekly")
            weekly = next(record for record in saved("lists") if record[0].lower() == "weekly")
            weekly_name = weekly[0]
            weekly_id = str(uuid.UUID(weekly[2]))
            check("catalog_create_through_editor", bool(weekly_id), ui)
            ui = select_list(ui, weekly_name)
            ui = enter_text(ui, "eggs")
            eggs = saved(weekly_id)
            check("new_list_has_independent_contents", len(eggs) == 1 and eggs[0][0].lower() == "eggs"
                  and saved() == replacement_original, ui)
            ui = select_list(ui, "lists")
            ui = item_tap(ui, "weekly", "lists", twice=True)
            assert editor(ui).get("text") == weekly_name, "Catalog rename did not start"
            ui = enter_text(ui, "weekend", replace=True)
            catalog = saved("lists")
            renamed = next(record for record in catalog if record[0].lower() == "weekend")
            check("catalog_rename_keeps_identity_and_contents", str(uuid.UUID(renamed[2])) == weekly_id
                  and saved(weekly_id) == eggs, ui)
            ui = item_swipe(ui, "weekend", "lists", rightward=True)
            check("catalog_delete_through_swipe", all(r[0].lower() != "weekend" for r in saved("lists")), ui)
            frame = undo_bar_frame(adb("exec-out", "screencap", "-p"), 0)
            assert frame is not None, "Catalog floating Undo action was not found"
            shell("input", "tap", frame["action_x"], frame["action_y"])
            ui = tree()
            check("catalog_delete_undo_restores_identity_and_order", saved("lists") == catalog, ui)
            ui = select_list(ui, renamed[0])
            check("renamed_list_remains_selectable", saved(weekly_id) == eggs, ui)
            ui = select_list(ui, "default")
            check("catalog_workflow_preserves_original_list", saved() == replacement_original, ui)
            tap(editor(ui), "left")
            ui = tree()
            system = ui.find('.//node[@class="android.widget.Button"][@content-desc="System"]')
            assert system is not None, "System theme button was not found"
            tap(system)
            ui = tree()
            system = ui.find('.//node[@class="android.widget.Button"][@content-desc="System"]')
            assert system is not None and system.get("checked") == "true"
            settings = shell("run-as", PACKAGE, "cat", data + "/Nevala/QShopper.ini")
            assert re.search(r"(?m)^theme=2$", settings), "Wait for System selection to be stored before restarting"
            shell("am", "force-stop", PACKAGE)
            ui = launch()
            ui = pull_mode(ui)
            tap(editor(ui), "left")
            ui = tree()
            system = ui.find('.//node[@class="android.widget.Button"][@content-desc="System"]')
            settings = shell("run-as", PACKAGE, "cat", data + "/Nevala/QShopper.ini")
            check("cold_restart_restores_system_choice_and_items", system is not None
                  and system.get("checked") == "true" and re.search(r"(?m)^theme=2$", settings)
                  and saved() == replacement_original, ui)
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("run-as", PACKAGE, "rm", "-rf", data)
            shell("rm", staging)
            shell("rm", staging + ".jar")


if __name__ == "__main__":
    main()
