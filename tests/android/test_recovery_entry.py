"""UI-032/UI-033/UI-035: Undo, end-editor visibility and offscreen-editor IME.

Only an isolated emulator is accepted. Uses disposable data and no microphone.
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
    parser.add_argument("--output", type=Path, default=Path("out/android-recovery-entry"))
    parser.add_argument("--case", choices=("keyboard", "scroll", "undo", "both"), default="both")
    parser.add_argument("--count", type=int, choices=(40, 80, 200), default=80,
                        help="List length for the offscreen-editor scroll case")
    parser.add_argument("--theme", choices=("light", "dark", "both"), default="both")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().strip()

    def tree():
        path = "/data/local/tmp/qshopper-recovery-entry-" + uuid.uuid4().hex + ".xml"
        try:
            result = shell("uiautomator", "dump", path)
            assert "dumped to" in result, "Could not obtain an idle accessibility tree"
            return ET.fromstring(adb("exec-out", "cat", path))
        finally:
            shell("rm", "-f", path)

    def bounds(node):
        return tuple(map(int, re.findall(r"\d+", node.get("bounds", ""))))

    def editor(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def rows(ui):
        return sorted({bounds(n) for n in ui.iter("node")
                       if n.get("resource-id", "").rsplit(".", 1)[-1].startswith("TextDelegate_")
                       and bounds(n)[3] > bounds(n)[1]})

    def tap(node):
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    def keyboard():
        return "mInputShown=true" in shell("dumpsys", "input_method")

    def ime_bounds():
        display = shell("dumpsys", "window", "displays")
        ime = re.search(r"type=ime frame=\[0,(\d+)\]\[\d+,\d+\][^\n]*visible=true", display)
        nav = re.search(r"type=navigationBars frame=\[0,(\d+)\]\[\d+,\d+\][^\n]*visible=true", display)
        assert ime and nav, "Visible native IME/navigation insets not found"
        return int(ime[1]), int(nav[1])

    def saved():
        path = args.output / "saved.sqlite"
        path.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(path)) as db:
            return db.execute(f'SELECT name,checked,id FROM "{TABLE}" ORDER BY rowid').fetchall()

    results = []

    def check(name, passed, **details):
        raw = adb("exec-out", "screencap", "-p")
        (args.output / f"{case}-{theme}-{name}.png").write_bytes(raw)
        results.append(dict(case=f"{case}-{theme}-{name}", passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + results[-1]["case"], details, flush=True)
        assert passed, name

    def bar_frame():
        return undo_bar_frame(adb("exec-out", "screencap", "-p"), theme)

    assert shell("getprop", "ro.kernel.qemu") == "1"
    width, height = map(int, re.search(r"(\d+)x(\d+)", shell("wm", "size")).groups())
    themes = (0, 1) if args.theme == "both" else (0 if args.theme == "light" else 1,)
    cases = ("keyboard", "undo") if args.case == "both" else (args.case,)
    for case in cases:
        for theme in themes:
            data = f"/data/user/0/{PACKAGE}/files/agent-testing/recovery-entry-{uuid.uuid4().hex}"
            staging = "/data/local/tmp/qshopper-recovery-entry-" + uuid.uuid4().hex
            shell("am", "force-stop", PACKAGE)
            try:
                with tempfile.TemporaryDirectory(prefix="qshopper-recovery-entry-") as temporary:
                    fixture = Path(temporary) / "shop_list.sqlite"
                    with closing(sqlite3.connect(fixture)) as db:
                        schema = "(id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, checked INTEGER NOT NULL DEFAULT 0)"
                        db.execute("CREATE TABLE lists " + schema)
                        db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                        db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                        count = args.count if case == "scroll" else (80 if case == "keyboard" else 3)
                        db.executemany(f'INSERT INTO "{TABLE}" VALUES (?, ?, 0)',
                                       [("{" + str(uuid.uuid4()) + "}", f"Item {i:02d}") for i in range(count)])
                        db.commit()
                    settings = Path(temporary) / "QShopper.ini"
                    settings.write_text(f"[General]\ntheme={theme}\nswipeSensitivity=0\n", encoding="utf-8")
                    shell("run-as", PACKAGE, "mkdir", "-p", data + "/Nevala")
                    for source, destination in ((fixture, "shop_list.sqlite"), (settings, "Nevala/QShopper.ini")):
                        adb("push", source, staging)
                        shell("run-as", PACKAGE, "cp", staging, data + "/" + destination)
                shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                      "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
                time.sleep(1)
                ui = tree()
                original = saved()
                first = rows(ui)[0]
                shell("input", "swipe", width // 2, (first[1] + first[3]) // 2,
                      width // 2, height - 140, 1200)
                ui = tree()
                assert editor(ui) is not None, "Pull did not enter editing"
                if keyboard():
                    shell("input", "keyevent", "KEYCODE_BACK")
                if case == "keyboard":
                    # Enough real upward motion to pass the full 80-row extent.
                    # Qt exposes row bounds here, but not their text captions.
                    for _ in range(12):
                        shell("input", "swipe", width // 2, height * 3 // 4,
                              width // 2, height // 4, 350)
                        time.sleep(.6)
                    ui = tree()
                    left, top, right, bottom = rows(ui)[-1]
                    shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
                    time.sleep(.8)
                    # Moving the editor can leave it just below the closed-IME
                    # viewport; reveal it with real scrolling before tapping it.
                    shell("input", "swipe", width // 2, height * 3 // 4,
                          width // 2, height // 2, 350)
                    time.sleep(.6)
                    if keyboard():
                        shell("input", "keyevent", "KEYCODE_BACK")
                    ui = tree()
                    assert editor(ui) is not None and not keyboard(), "End editor must start with IME closed"
                    assert bounds(editor(ui))[3] > bounds(editor(ui))[1] > 0, "End editor must be visible before opening IME"
                    (args.output / f"keyboard-{theme}-before-open.png").write_bytes(adb("exec-out", "screencap", "-p"))
                    for iteration in range(2):
                        tap(editor(ui))
                        time.sleep(.8)
                        assert keyboard(), "Native keyboard did not open"
                        ime_top, nav_top = ime_bounds()
                        ui = tree()
                        (args.output / f"keyboard-{theme}-open-{iteration}.xml").write_bytes(ET.tostring(ui))
                        field = editor(ui)
                        rect = bounds(field) if field is not None else None
                        check(f"end_editor_visible_{iteration}", rect is not None and rect[1] >= 0
                              and rect[3] <= ime_top, editor_bounds=rect, ime_top=ime_top)
                        shell("input", "text", f"Tailentry{iteration}")
                        shell("input", "tap", round(width * .925), round(ime_top + (nav_top - ime_top) * .82))
                        time.sleep(.8)
                        current = saved()
                        check(f"return_preserves_order_and_ime_{iteration}", keyboard()
                              and current[:80] == original
                              and [r[0] for r in current[80:]] == [f"Tailentry{i}" for i in range(iteration + 1)],
                              keyboard_open=keyboard(), original_rows_match=current[:80] == original,
                              appended=[r[0] for r in current[80:]])
                        shell("input", "keyevent", "KEYCODE_BACK")
                        ui = tree()
                elif case == "scroll":
                    tap(editor(ui))
                    time.sleep(.8)
                    assert keyboard(), "Scroll case must start with native Gboard open"
                    shell("input", "text", "ScrollDraft")
                    ime_top, nav_top = ime_bounds()
                    row_height = first[3] - first[1]
                    start = round(ime_top * .8)
                    end = round(ime_top * .3)
                    # Pass the entire list using actual vertical touch motion,
                    # well beyond either the Qt 5 or Qt 6 delegate cache.
                    for step in range(count * row_height // (start - end) + 4):
                        shell("input", "swipe", width // 2, start, width // 2, end, 250)
                        time.sleep(.2)
                        if not keyboard():
                            check(f"scroll_keeps_native_ime_step_{step}", False)
                    check("scroll_keeps_native_ime", keyboard())
                    check("offscreen_editor_preserves_saved_rows", saved() == original)
                    for _ in range(count * row_height // (start - end) + 4):
                        shell("input", "swipe", width // 2, end, width // 2, start, 250)
                        time.sleep(.2)
                    ui = tree()
                    field = editor(ui)
                    check("scroll_back_preserves_draft", field is not None
                          and field.get("text") == "ScrollDraft" and keyboard())
                    ime_top, nav_top = ime_bounds()
                    shell("input", "tap", round(width * .925), round(ime_top + (nav_top - ime_top) * .82))
                    time.sleep(.8)
                    current = saved()
                    check("return_keeps_original_order_and_ime", keyboard()
                          and len(current) == count + 1 and current[0][0] == "ScrollDraft"
                          and current[1:] == original)
                    shell("input", "keyevent", "KEYCODE_BACK")
                    time.sleep(.5)
                    check("back_still_hides_keyboard", not keyboard())
                else:
                    row = rows(ui)[0]
                    left, top, right, bottom = row
                    for _ in range(2):
                        last_deletion = time.monotonic()
                        shell("input", "swipe", round(width * .15), (top + bottom) // 2,
                              round(width * .85), (top + bottom) // 2, 350)
                        time.sleep(.8)
                    after_deletions = saved()
                    assert len(after_deletions) == 1, "Two actual swipes must remove two rows"
                    time.sleep(max(0, last_deletion + 12 - time.monotonic()))
                    frame = bar_frame()
                    assert frame and 0 < frame["fraction"] < .3, "Undo must be close to expiry"
                    shell("input", "tap", frame["action_x"], frame["action_y"])
                    time.sleep(.3)
                    refreshed = bar_frame()
                    check("previous_action_gets_full_window", len(saved()) == 2 and refreshed
                          and refreshed["fraction"] > .85, old_frame=frame, refreshed=refreshed)
                    time.sleep(max(0, last_deletion + 16 - time.monotonic()))
                    frame = bar_frame()
                    check("previous_action_survives_old_deadline", frame is not None and len(saved()) == 2)
                    shell("input", "tap", frame["action_x"], frame["action_y"])
                    time.sleep(.8)
                    check("earlier_undo_restores_exact_data", saved() == original and bar_frame() is None)
            finally:
                shell("am", "force-stop", PACKAGE)
                shell("run-as", PACKAGE, "rm", "-rf", data)
                shell("rm", "-f", staging)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
