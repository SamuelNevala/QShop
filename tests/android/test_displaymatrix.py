"""QA-002 native rendering at simulated phone sizes/densities, not physical calibration.

Runs the existing text and selector regressions sequentially on an isolated
emulator. Attempts all original-setting restorations and records failures.
"""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import time

from PIL import Image


PROFILES = (("baseline", "1440x3120", "560"),
            ("compact", "1080x1920", "480"),
            ("roomy", "1440x3120", "420"))


def effective_wm(text):
    override = re.search(r"Override (?:size|density):\s*(\S+)", text)
    physical = re.search(r"Physical (?:size|density):\s*(\S+)", text)
    assert override or physical, "Unrecognized wm geometry output"
    return (override or physical).group(1)


def validate_geometry(profile, text_output=None):
    assert effective_wm(profile["size"]) == profile["requested_size"], "Requested size was not applied"
    assert effective_wm(profile["density"]) == profile["requested_density"], "Requested density was not applied"
    if text_output is not None:
        expected = tuple(map(int, profile["requested_size"].split("x")))
        sizes = {}
        for theme in ("dark", "light"):
            with Image.open(text_output / theme / "shopping.png") as frame:
                sizes[theme] = list(frame.size)
                assert frame.size == expected, "Native screenshot must use the requested geometry"
        profile["screenshot_sizes"] = sizes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-displaymatrix"))
    parser.add_argument("--profile", choices=("all", *(profile[0] for profile in PROFILES)), default="all")
    args = parser.parse_args()
    if not re.fullmatch(r"emulator-\d+", args.serial):
        parser.error("Only an isolated emulator is allowed")
    args.output.mkdir(parents=True, exist_ok=True)

    def shell(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, "shell", *command],
                                       timeout=45).decode().strip()

    assert shell("getprop", "ro.kernel.qemu") == "1"
    original = {key: shell("wm", key) for key in ("size", "density")}
    original_rotation = shell("wm", "user-rotation")
    original_auto = shell("settings", "get", "system", "accelerometer_rotation")
    assert original_rotation.split()[0] in ("free", "lock"), "Unrecognized rotation mode"
    metadata = dict(original=original, serial=args.serial, profiles=[],
                    os=shell("getprop", "ro.build.fingerprint"),
                    ime=shell("settings", "get", "secure", "default_input_method"),
                    font_scale=shell("settings", "get", "system", "font_scale"),
                    original_rotation=original_rotation, original_auto=original_auto,
                    scope="Simulated viewport/logical density only; no physical mm or usability certification")
    apk = shell("pm", "path", "shopper.nevala.com").splitlines()[0].removeprefix("package:")
    metadata["installed_apk_sha256"] = shell("sha256sum", apk).split()[0]
    manifest = args.output / "results.json"
    try:
        for name, size, density in PROFILES:
            if args.profile not in ("all", name):
                continue
            shell("am", "force-stop", "shopper.nevala.com")
            shell("wm", "size", size)
            shell("wm", "density", density)
            time.sleep(1)
            folder = args.output / name
            folder.mkdir(parents=True, exist_ok=True)
            profile = dict(name=name, requested_size=size, requested_density=density,
                           size=shell("wm", "size"), density=shell("wm", "density"), suites=[])
            metadata["profiles"].append(profile)
            validate_geometry(profile)
            (folder / "display.txt").write_text(shell("dumpsys", "display"), encoding="utf-8")
            (folder / "window.txt").write_text(shell("dumpsys", "window", "displays"), encoding="utf-8")
            for script, extra, child in (("test_textfitting.py", [], "text"),
                                         ("test_popups.py", ["--restart"], "popups")):
                output = folder / child
                command = [sys.executable, str(Path(__file__).with_name(script)), "--adb", args.adb,
                           "--serial", args.serial, "--output", str(output), *extra]
                with (folder / (child + ".log")).open("w", encoding="utf-8") as log:
                    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=False)
                report_path = output / "results.json"
                records = json.loads(report_path.read_text(encoding="utf-8")) if report_path.exists() else []
                passed = result.returncode == 0 and bool(records) and all(row["passed"] for row in records)
                profile["suites"].append(dict(name=child, passed=passed, records=len(records), exit_code=result.returncode))
                if child == "text" and (output / "dark/shopping.png").exists():
                    validate_geometry(profile, output)
                    profile["row_bounds"] = [row["row"] for row in records if row["case"].startswith("Dark_line_limit_")]
                manifest.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
                print(("PASS " if passed else "FAIL ") + name + " " + child,
                      "records=", len(records), flush=True)
                if not passed:
                    raise RuntimeError(f"{name} {child} failed; inspect {folder / (child + '.log')}")
    finally:
        errors = {}

        def attempt(label, *command):
            try:
                return shell(*command)
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
                errors[label] = str(error)
                return None

        attempt("force_stop", "am", "force-stop", "shopper.nevala.com")
        for key, text in original.items():
            override = re.search(r"Override (?:size|density):\s*(\S+)", text)
            attempt(key, "wm", key, override.group(1) if override else "reset")
        attempt("rotation", "wm", "user-rotation", *original_rotation.split())
        attempt("auto", "settings", "put", "system", "accelerometer_rotation", original_auto)
        metadata["restored"] = {key: attempt("read_" + key, "wm", key) for key in original}
        metadata["restored_rotation"] = attempt("read_rotation", "wm", "user-rotation")
        metadata["restored_auto"] = attempt("read_auto", "settings", "get", "system", "accelerometer_rotation")
        metadata["restore_errors"] = errors
        metadata["restore_matches"] = (not errors and metadata["restored"] == original
                                       and metadata["restored_rotation"] == original_rotation
                                       and metadata["restored_auto"] == original_auto)
        manifest.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
        assert metadata["restore_matches"], "Emulator settings restoration failed; inspect results.json"


if __name__ == "__main__":
    main()
