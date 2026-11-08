"""Remove optional QML wrappers one at a time and exercise real Release UI.

Uses a disposable emulator and the existing standard debug signing key only.
The production signing identity is never used. Retains a required-style negative
control and checks cumulative removals, preserving native libraries and qmldirs.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path, help="Unsigned optimized x86_64 Release APK")
    parser.add_argument("--kit", type=Path, default=Path("C:/Qt/6.12.0/android_x86_64"))
    parser.add_argument("--sdk", type=Path, default=Path("C:/android/sdk"))
    parser.add_argument("--java-home", type=Path, default=Path("C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot"))
    parser.add_argument("--debug-keystore", type=Path, required=True)
    parser.add_argument("--disposable-device", action="store_true", required=True)
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/optional-qml-plugins"))
    args = parser.parse_args()
    assert re.fullmatch(r"emulator-\d+", args.serial)
    args.output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, JAVA_HOME=str(args.java_home))
    tools = args.sdk / "build-tools/37.0.0"
    adb = args.sdk / "platform-tools/adb.exe"
    assert subprocess.check_output([str(adb), "-s", args.serial, "shell", "getprop", "ro.kernel.qemu"], env=env).strip() == b"1"
    modules = {}
    for path in (args.kit / "qml").rglob("qmldir"):
        source = path.read_text(encoding="utf-8")
        declaration = re.search(r"^optional plugin (\S+)", source, re.MULTILINE)
        if declaration:
            modules["lib" + declaration.group(1) + "_x86_64.so"] = source.splitlines()[0]
    with zipfile.ZipFile(args.apk) as package:
        candidates = sorted(Path(name).name for name in package.namelist()
                            if name.startswith("lib/x86_64/") and Path(name).name in modules)
    assert candidates, "No declared optional plugins found"
    accepted = []
    results = []

    def variant(removed, name):
        unaligned = args.output / "variant-unaligned.apk"
        aligned = args.output / "variant-aligned.apk"
        signed = args.output / "variant-signed.apk"
        with zipfile.ZipFile(args.apk) as source, zipfile.ZipFile(unaligned, "w") as target:
            for entry in source.infolist():
                if Path(entry.filename).name not in removed:
                    target.writestr(entry, source.read(entry))
        subprocess.run([str(tools / "zipalign.exe"), "-P", "16", "-f", "4", str(unaligned), str(aligned)], check=True, env=env)
        subprocess.run([str(tools / "apksigner.bat"), "sign", "--ks", str(args.debug_keystore),
                        "--ks-key-alias", "androiddebugkey", "--ks-pass", "pass:android", "--key-pass", "pass:android",
                        "--out", str(signed), str(aligned)], check=True, env=env)
        subprocess.run([str(adb), "-s", args.serial, "install", "-r", str(signed)], check=True, env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        folder = args.output / name
        with (args.output / (name + ".txt")).open("w", encoding="utf-8") as output:
            result = subprocess.run([sys.executable, str(Path(__file__).with_name("test_release.py")),
                "--adb", str(adb), "--serial", args.serial, "--disposable-device", "--smoke", "--output", str(folder)],
                env=env, stdout=output, stderr=subprocess.STDOUT)
        return result.returncode, folder

    code, folder = variant([], "baseline")
    assert code == 0, "Release baseline failed; do not assess removals until the harness/environment passes"
    required = "libqml_QtQuick_Controls_Material_qtquickcontrols2materialstyleplugin_x86_64.so"
    code, folder = variant([required], "required-style-negative-control")
    log = (folder / "logcat.txt").read_text(encoding="utf-8")
    assert code != 0 and re.search(r"plugin .*not found|module .*not installed|QQmlApplicationEngine failed", log), \
        "Required-style negative control did not expose the missing-plugin failure"
    results.append(dict(case="required_style_negative_control", passed=True, retained=required))
    for index, candidate in enumerate(candidates):
        code, folder = variant([*accepted, candidate], f"{index:02d}-{candidate}")
        if code == 0:
            accepted.append(candidate)
        else:
            log = (folder / "logcat.txt").read_text(encoding="utf-8")
            assert re.search(r"plugin .*not found|module .*not installed|QQmlApplicationEngine failed", log), \
                "Candidate test failed outside the expected import path: " + candidate
        results.append(dict(case=candidate, removable=code == 0, module=modules[candidate], cumulative_removed=list(accepted)))
        (args.output / "results.json").write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
        print(("REMOVE " if code == 0 else "KEEP ") + candidate, flush=True)
    code, _ = variant(accepted, "final-combination")
    assert code == 0, "Combined final plugin selection failed"
    (args.output / "removed.json").write_text(json.dumps(accepted, indent=2) + "\n", encoding="utf-8")
    print(f"PASS {len(accepted)} optional wrappers removed; required style retained; combined Release smoke passed")


if __name__ == "__main__":
    main()
