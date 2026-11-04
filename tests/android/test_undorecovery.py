"""UI-023: native offscreen-editor Undo, scrolling, batches, IME and expiry.

Requires Pillow. Uses only an isolated emulator and disposable app data.
"""

import argparse
from contextlib import closing
import json
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET

from undo_bar import undo_bar_frame

PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-undorecovery"))
    parser.add_argument("--theme", choices=("light", "dark", "both"), default="both")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree():
        shell("rm", "-f", "/sdcard/qshopper-recovery.xml")
        result = shell("uiautomator", "dump", "/sdcard/qshopper-recovery.xml")
        assert "dumped to" in result, "UI dump did not produce a current tree: " + result
        raw = adb("exec-out", "cat", "/sdcard/qshopper-recovery.xml")
        (args.output / "latest-ui.xml").write_bytes(raw)
        return ET.fromstring(raw)

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def undo(ui):
        return ui.find('.//node[@content-desc="Undo"][@enabled="true"]')

    def tap(node):
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    def rows(ui, limit):
        return sorted({bounds(node) for node in ui.iter("node")
                       if node.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                       and bounds(node)[1] > 100 and bounds(node)[3] < limit - 40
                       and bounds(node)[3] - bounds(node)[1] > 40}, key=lambda r: r[1])

    results = []

    def check(name, passed, ui=None, **details):
        if ui is not None:
            (args.output / f"{theme}-{name}.xml").write_bytes(ET.tostring(ui))
        (args.output / f"{theme}-{name}.png").write_bytes(adb("exec-out", "screencap", "-p"))
        results.append(dict(case=f"{theme}_{name}", passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + f"{theme}_{name}", flush=True)
        assert passed, name

    assert shell("getprop", "ro.kernel.qemu") == "1", "Target is not an emulator"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    themes = (0, 1) if args.theme == "both" else (0 if args.theme == "light" else 1,)
    for theme in themes:
        data = f"/data/user/0/{PACKAGE}/files/agent-testing/recovery-{uuid.uuid4().hex}"
        staging = "/data/local/tmp/qshopper-recovery-" + uuid.uuid4().hex
        shell("am", "force-stop", PACKAGE)
        with tempfile.TemporaryDirectory(prefix="qshopper-recovery-") as temporary:
            fixture = Path(temporary) / "shop_list.sqlite"
            with closing(sqlite3.connect(fixture)) as db:
                schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                db.execute("CREATE TABLE lists " + schema)
                db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                               [(str(uuid.uuid4()), f"Item {i}") for i in range(30)])
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
                records = db.execute(f'SELECT name,checked,id FROM "{TABLE}" ORDER BY rowid').fetchall()
                return [(name, checked, str(uuid.UUID(identifier))) for name, checked, identifier in records]

        def launch(read_tree=True):
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            if not read_tree:
                time.sleep(.7)
                return None
            for _ in range(6):
                ui = tree()
                if rows(ui, height):
                    return ui
                time.sleep(.3)
            raise RuntimeError("Fixture did not load")

        def delete(ui, limit=height):
            visible = rows(ui, limit)
            assert visible, "No fully visible row to delete"
            left, top, right, bottom = visible[len(visible) // 2]
            before = saved()
            shell("input", "swipe", left + int((right - left) * .15), (top + bottom) // 2,
                  left + int((right - left) * .85), (top + bottom) // 2, 350)
            started = time.monotonic()
            for _ in range(15):
                if len(saved()) == len(before) - 1:
                    time.sleep(.8)
                    return started
                time.sleep(.1)
            raise RuntimeError("Deliberate right swipe did not delete exactly one item")

        def keyboard_top():
            for _ in range(25):
                display = shell("dumpsys", "window", "displays")
                match = re.search(r"type=ime frame=\[0,(\d+)\]\[\d+,\d+\][^\n]*visible=true", display)
                if match:
                    return int(match[1])
                time.sleep(.1)
            (args.output / f"{theme}-ime-timeout.png").write_bytes(adb("exec-out", "screencap", "-p"))
            raise AssertionError("Native IME not visible after waiting for its opening transition")

        def bar_frame(name, limit=height):
            # UiAutomator waits for accessibility idle, which a live animated
            # progress control need not reach. Inspect its real pixels instead.
            raw = adb("exec-out", "screencap", "-p")
            (args.output / f"{theme}-{name}-frame.png").write_bytes(raw)
            return undo_bar_frame(raw, theme, limit)

        def activate_bar(bar, fraction=.5):
            assert bar is not None, "Rendered Undo bar was not found"
            shell("input", "tap", round(width * fraction), bar["action_y"])
            time.sleep(.5)

        try:
            ui = launch()
            first = rows(ui, height)[0]
            shell("input", "swipe", width // 2, (first[1] + first[3]) // 2,
                  width // 2, height - 140, 1200)
            ui = tree()
            assert editor(ui) is not None, "Pull did not enter edit mode"
            original = saved()
            (args.output / f"original-{theme}.json").write_text(json.dumps(original, indent=2), encoding="utf-8")
            shell("input", "swipe", width // 2, int(height * .75), width // 2, int(height * .25), 700)
            ui = tree()
            check("editor_offscreen", editor(ui) is None or bounds(editor(ui))[3] <= 100, ui)
            delete(ui)
            bar = bar_frame("offscreen-delete")
            check("reachable_undo_after_offscreen_delete", bar is not None, bar=bar)
            shell("input", "swipe", width // 2, int(height * .6), width // 2, int(height * .3), 400)
            after_scroll = bar_frame("after-scroll")
            check("scroll_preserves_undo", after_scroll is not None and len(saved()) == 29
                  and abs(after_scroll["top"] - bar["top"]) <= 2
                  and after_scroll["fraction"] < bar["fraction"], bar=after_scroll)
            activate_bar(after_scroll, .1)
            check("offscreen_undo_restores_order_ids_flags", saved() == original)

            ui = tree()
            visible = rows(ui, height)
            left, top, right, bottom = visible[len(visible) // 2]
            shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
            ui = tree()
            assert editor(ui) is not None, "Row tap did not bring editor into view"
            tap(editor(ui))
            time.sleep(.5)
            ime_top = keyboard_top()
            ui = tree()
            delete(ui, ime_top)
            bar = bar_frame("keyboard-delete", ime_top)
            check("undo_above_native_keyboard", bar is not None and bar["bottom"] <= ime_top, bar=bar)
            limit = bar["top"]
            delete(ui, limit)
            bar = bar_frame("batch-delete", ime_top)
            check("consecutive_delete_batch", len(saved()) == 28 and bar is not None, bar=bar)
            shell("input", "text", "new")
            shell("input", "keyevent", 66)
            bar = bar_frame("after-submit", keyboard_top())
            check("submission_keeps_recovery_and_ime", bar is not None
                  and len(saved()) == 29, bar=bar)
            activate_bar(bar)
            restored = saved()
            added = [row for row in restored if row[0].casefold() == "new"]
            check("batch_undo_preserves_new_entry_and_original_ids", len(restored) == 31
                  and len(added) == 1
                  and [row for row in restored if row[0].casefold() != "new"] == original)
            check("undo_keeps_native_keyboard_open", keyboard_top() > 0)

            shell("input", "keyevent", 4)
            ui = tree()
            started = delete(ui)
            remaining = saved()
            time.sleep(max(0, started + 16 - time.monotonic()))
            ui = tree()
            check("actual_expiry_closes_bar_keeps_deletion", undo(ui) is None and saved() == remaining, ui)

            if theme == 0:
                delete(ui)
                bar = bar_frame("before-background")
                process = shell("pidof", PACKAGE)
                shell("input", "keyevent", 3)
                time.sleep(16)
                launch(read_tree=False)
                resumed = bar_frame("resumed")
                check("background_pauses_recovery_window", shell("pidof", PACKAGE) == process
                      and resumed is not None and resumed["fraction"] > .5, bar=resumed)
                activate_bar(resumed, .92)
                check("resume_undo_restores_saved_data", saved() == remaining)
        finally:
            shell("am", "force-stop", PACKAGE)
            shell("run-as", PACKAGE, "rm", "-rf", data)
            shell("rm", "-f", staging + ".sqlite", staging + ".ini")


if __name__ == "__main__":
    main()
