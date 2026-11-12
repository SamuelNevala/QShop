"""Exercise a genuine non-debuggable Release APK on a disposable emulator.

Requires --disposable-device because Release ignores Qt debugging intent extras
and denies run-as. Use a fresh emulator userdata disk; this test clears only
QShopper on that disposable device. No physical serial is accepted.
"""

import argparse
from io import BytesIO
import json
from pathlib import Path
import re
import subprocess
import time
import uuid
import xml.etree.ElementTree as ET

from PIL import Image
from undo_bar import undo_bar_frame


PACKAGE = "shopper.nevala.com"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="C:/android/sdk/platform-tools/adb.exe")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--disposable-device", action="store_true", required=True)
    parser.add_argument("--smoke", action="store_true", help="Only startup, native entry and both offline notice tabs")
    parser.add_argument("--apk", type=Path, help="Install this signed Release test APK")
    parser.add_argument("--upgrade-from", type=Path, help="Seed this same-key Debug APK, then update to --apk")
    parser.add_argument("--output", type=Path, default=Path("out/android-release"))
    args = parser.parse_args()
    assert re.fullmatch(r"emulator-\d+", args.serial), "Only a disposable emulator is allowed"
    args.output.mkdir(parents=True, exist_ok=True)
    remote_ui = "/data/local/tmp/qshopper-release-" + uuid.uuid4().hex + ".xml"

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode(errors="replace").replace("\r", "").strip()

    def tree():
        shell("rm", "-f", remote_ui)
        result = shell("uiautomator", "dump", remote_ui)
        if "dumped to" not in result:
            raise RuntimeError("Android accessibility did not reach idle")
        return ET.fromstring(adb("exec-out", "cat", remote_ui))

    def bounds(node):
        assert node is not None, "Required control was not found"
        return tuple(map(int, re.findall(r"-?\d+", node.attrib["bounds"])))

    def named(ui, name):
        return next((n for n in ui.iter("node") if n.get("text") == name or n.get("content-desc") == name), None)

    def editor(ui):
        return next((n for n in ui.iter("node") if n.get("package") == PACKAGE
                     and n.get("class") == "android.widget.EditText"), None)

    def rows(ui):
        return sorted((n for n in ui.iter("node") if n.get("resource-id", "").rsplit(".", 1)[-1]
                       .startswith("TextDelegate_") and bounds(n)[3] > bounds(n)[1]), key=lambda n: bounds(n)[1])

    def verify_item_text(ui, expected):
        # Shopping rows do not expose their text to Android accessibility.
        # Read it through the real double-tap editor, then submit it unchanged.
        ui = wait_ui(lambda state: len(rows(state)) == 1
                     and bounds(rows(state)[0])[2] - bounds(rows(state)[0])[0] >= width * .98)
        tap(rows(ui)[0])
        tap(rows(ui)[0])
        ui = wait_ui(lambda state: editor(state) is not None and editor(state).get("text") == expected)
        shell("input", "keyevent", "KEYCODE_ENTER")
        return wait_ui(lambda state: len(rows(state)) == 1 and editor(state).get("text", "") in ("", "Tap to add items"))

    def wait_ui(predicate):
        ui = ET.Element("hierarchy")
        for _ in range(5):
            try:
                ui = tree()
            except RuntimeError:
                time.sleep(.3)
                continue
            if predicate(ui):
                return ui
            time.sleep(.3)
        (args.output / "failure-ui.xml").write_bytes(ET.tostring(ui))
        capture("failure")
        raise AssertionError("Release UI did not reach the expected state")

    def tap(node):
        left, top, right, bottom = bounds(node)
        shell("input", "tap", (left + right) // 2, (top + bottom) // 2)

    def capture(name):
        Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).save(args.output / (name + ".png"))

    def open_drawer(ui):
        left, top, right, bottom = bounds(editor(ui))
        shell("input", "tap", left + (bottom - top) // 2, (top + bottom) // 2)
        return wait_ui(lambda state: named(state, "Dark") is not None)

    def drawer_light(ui):
        spinners = [bounds(n) for n in ui.iter("node") if n.get("class") == "android.widget.Spinner"]
        frame = Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).convert("RGB")
        pixel = frame.getpixel((max(rect[2] for rect in spinners) + 6, height // 2))
        return min(pixel) > 180

    records = []

    def check(name, condition):
        records.append(dict(case=name, passed=bool(condition)))
        (args.output / "results.json").write_text(json.dumps(records, indent=2), encoding="utf-8")
        assert condition, name
        print("PASS " + name, flush=True)

    assert shell("getprop", "ro.kernel.qemu") == "1"
    shell("am", "force-stop", PACKAGE)
    if args.upgrade_from:
        assert args.apk, "--upgrade-from requires --apk"
        if shell("pm", "path", PACKAGE).startswith("package:"):
            adb("uninstall", PACKAGE)
        adb("install", args.upgrade_from)
    elif args.apk:
        adb("install", "-r", args.apk)
    assert "Success" in shell("pm", "clear", PACKAGE)
    shell("logcat", "-c")
    try:
        if args.upgrade_from:
            # Deliberately exercise normal storage on the fresh disposable disk:
            # Debug's injected INI path would not represent a real phone update.
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity")
            ui = wait_ui(lambda state: editor(state) is not None)
            _, _, width, height = bounds(next(n for n in ui.iter("node") if n.get("package") == PACKAGE))
            tap(editor(ui))
            shell("input", "text", "Release-milk")
            shell("input", "keyevent", "KEYCODE_ENTER")
            ui = wait_ui(lambda state: len(rows(state)) == 1)
            shell("input", "keyevent", "KEYCODE_BACK")
            ui = open_drawer(tree())
            tap(named(ui, "Light"))
            wait_ui(lambda state: named(state, "Light") is not None)
            time.sleep(1.2)  # Allow QtCore.Settings' deferred write to reach normal preferences.
            shell("am", "force-stop", PACKAGE)
            adb("install", "-r", args.apk)
        check("non_debuggable_release", not re.search(r"\bDEBUGGABLE\b", shell("dumpsys", "package", PACKAGE)))
        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity")
        # A fresh empty list starts in edit mode. Wait for the actual field;
        # pulling here would toggle the app back into shopping mode.
        ui = wait_ui(lambda state: len(rows(state)) == 1) if args.upgrade_from else wait_ui(lambda state: editor(state) is not None)
        capture("startup")
        root = next(n for n in ui.iter("node") if n.get("package") == PACKAGE)
        _, _, width, height = bounds(root)
        if args.upgrade_from:
            left, top, right, bottom = bounds(rows(ui)[0])
            shell("input", "swipe", width // 2, bottom + 80, width // 2, height - 140, 1200)
            ui = wait_ui(lambda state: editor(state) is not None)
        else:
            tap(editor(ui))
            shell("input", "text", "Release-milk")
            shell("input", "keyevent", "KEYCODE_ENTER")
        ui = wait_ui(lambda state: len(rows(state)) == 1)
        ui = verify_item_text(ui, "Release-milk")
        check("debug_to_release_preserves_item" if args.upgrade_from else "native_return_inserts_item", len(rows(ui)) == 1)
        shell("input", "keyevent", "KEYCODE_BACK")
        ui = tree()
        ui = open_drawer(ui)
        if args.upgrade_from:
            check("debug_to_release_preserves_theme", drawer_light(ui))
        check("drawer_controls", named(ui, "Light") is not None and named(ui, "System") is not None)
        if not args.smoke:
            for mode in ("Light", "Dark", "System", "Dark"):
                tap(named(ui, mode))
                ui = tree()
                if mode != "System":
                    check("theme_" + mode.lower(), drawer_light(ui) == (mode == "Light"))
            for index in range(3):
                ui = tree()
                spinners = [n for n in ui.iter("node") if n.get("class") == "android.widget.Spinner"]
                tap(spinners[index])
                ui = wait_ui(lambda state: any("Popup" in n.get("resource-id", "") for n in state.iter("node")))
                shell("input", "keyevent", "KEYCODE_BACK")
                ui = wait_ui(lambda state: named(state, "Dark") is not None
                             and not any("Popup" in n.get("resource-id", "") for n in state.iter("node")))
                check("selector_" + str(index) + "_back_preserves_drawer", named(ui, "Dark") is not None)
        shell("input", "swipe", width // 3, height * 3 // 4, width // 3, height // 3, 350)
        ui = wait_ui(lambda state: named(state, "Licenses") is not None)
        tap(named(ui, "Licenses"))
        ui = wait_ui(lambda state: named(state, "Open-source licenses") is not None)
        check("qt_notice", any("Qt 6.12" in (n.get("text", "") + n.get("content-desc", "")) for n in ui.iter("node")))
        capture("qt-notice")
        tap(named(ui, "Font Awesome"))
        ui = wait_ui(lambda state: any("Font Awesome 7 Free Solid" in (n.get("text", "") + n.get("content-desc", ""))
                                      for n in state.iter("node")))
        check("font_awesome_notice", named(ui, "Open-source licenses") is not None)
        capture("font-awesome-notice")
        shell("input", "keyevent", "KEYCODE_BACK")
        ui = wait_ui(lambda state: named(state, "Open-source licenses") is None)
        tap(named(ui, "Privacy policy"))
        ui = wait_ui(lambda state: any("samuel.nevala@gmail.com" in (n.get("text", "") + n.get("content-desc", ""))
                                      for n in state.iter("node")))
        check("bundled_privacy_policy", any("Android backup" in (n.get("text", "") + n.get("content-desc", ""))
                                            for n in ui.iter("node")))
        capture("privacy-policy")
        shell("input", "keyevent", "KEYCODE_BACK")
        ui = wait_ui(lambda state: named(state, "Licenses") is not None)
        check("privacy_back_preserves_drawer", named(ui, "Privacy policy") is not None)
        shell("input", "keyevent", "KEYCODE_BACK")
        wait_ui(lambda state: named(state, "Dark") is None)
        if not args.smoke:
            ui = tree()
            row = rows(ui)[0]
            left, top, right, bottom = bounds(row)
            shell("input", "swipe", int(width * .25), (top + bottom) // 2,
                  int(width * .95), (top + bottom) // 2, 350)
            # The countdown continuously updates accessibility. Locate its actual
            # rendered fill without waiting for UIAutomator idle past expiry.
            time.sleep(.4)
            raw = adb("exec-out", "screencap", "-p")
            (args.output / "undo.png").write_bytes(raw)
            bar = undo_bar_frame(raw, 1)
            assert bar is not None, "Rendered Undo action was not found"
            shell("input", "tap", width // 2, bar["action_y"])
            ui = wait_ui(lambda state: len(rows(state)) == 1)
            ui = verify_item_text(ui, "Release-milk")
            check("delete_and_undo", len(rows(ui)) == 1)
        shell("am", "force-stop", PACKAGE)
        shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity")
        ui = wait_ui(lambda state: len(rows(state)) == 1)
        capture("restored")
        left, top, right, bottom = bounds(rows(ui)[0])
        shell("input", "swipe", width // 2, bottom + 80, width // 2, height - 140, 1200)
        ui = wait_ui(lambda state: editor(state) is not None)
        ui = verify_item_text(ui, "Release-milk")
        check("cold_restart_preserves_item", len(rows(ui)) == 1)
        log = shell("logcat", "-d", "-v", "brief")
        (args.output / "logcat.txt").write_text(log, encoding="utf-8")
        check("no_native_or_qml_load_failure", not re.search(r"FATAL EXCEPTION|QQmlApplicationEngine failed|module .*not installed|plugin .*not found|UnsatisfiedLinkError", log))
    finally:
        (args.output / "logcat.txt").write_text(shell("logcat", "-d", "-v", "brief"), encoding="utf-8")
        shell("am", "force-stop", PACKAGE)
        shell("rm", "-f", remote_ui)
        shell("pm", "clear", PACKAGE)


if __name__ == "__main__":
    main()
