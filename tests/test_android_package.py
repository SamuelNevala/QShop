"""Check QShopper's Android runtime payload and scan isolation (DEV-008)."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--abi", required=True, choices=("arm64-v8a", "x86_64"))
    parser.add_argument("--report", type=Path)
    parser.add_argument("--deployment-settings", type=Path, required=True)
    parser.add_argument("--readelf", type=Path, required=True)
    parser.add_argument("--bundletool", type=Path)
    parser.add_argument("--java", default="java")
    parser.add_argument("--qml-debug", action="store_true",
                        help="Expect the explicitly enabled QML debugging/profiling plugins")
    args = parser.parse_args()

    with zipfile.ZipFile(args.apk) as package:
        prefix = "base/" if args.apk.suffix.lower() == ".aab" else ""
        libraries = [entry for entry in package.infolist()
                     if entry.filename.startswith(prefix + "lib/") and entry.filename.endswith(".so")]
        names = {entry.filename.removeprefix(prefix) for entry in libraries}
        actual_abis = {name.split("/")[1] for name in names}
        assert actual_abis == {args.abi}, f"Unexpected native ABIs: {actual_abis}"
        required = {f"lib/{args.abi}/libQt6{module}_{args.abi}.so"
                    for module in ("Core", "Gui", "Qml", "Quick", "Sql", "Svg", "QuickVectorImage",
                                   "QmlCore", "QmlModels", "QuickLayouts", "LabsQmlModels",
                                   "QuickControls2Material", "QuickControls2Fusion",
                                   "QuickVectorImageHelpers", "QuickShapes")}
        required.add(f"lib/{args.abi}/libapplication_{args.abi}.so")
        required.add(f"lib/{args.abi}/libplugins_platforms_qtforandroid_{args.abi}.so")
        required.add(f"lib/{args.abi}/libplugins_imageformats_qjpeg_{args.abi}.so")
        required.add(f"lib/{args.abi}/libplugins_sqldrivers_qsqlite_{args.abi}.so")
        assert required <= names, f"Missing runtime libraries: {sorted(required - names)}"
        forbidden = ("virtualkeyboard", "canvas", "libqt6test_", "libqt6quicktest_",
                     "libqml_qttest_", "quickcontrols2imagine", "quickcontrols2universal",
                     "quickcontrols2fluentwinui3", "controls_imagine_", "controls_universal_",
                     "controls_fluentwinui3_", "libqt6widgets_", "qlottie", "libqt6lottie",
                     "libqt6svgwidgets_", "qtquick_controls_qtquickcontrols2plugin", "qoffscreen",
                     "qsvgicon", "quick3dprofiler", "libqt6quick3dutils_",
                     "libplugins_tls_", "libplugins_networkinformation_")
        unwanted = sorted(name for name in names if any(token in name.lower() for token in forbidden)
                          or ("libplugins_imageformats_" in name.lower()
                              and "_qjpeg_" not in name.lower()))
        tooling = sorted(name for name in names if "libplugins_qmltooling_" in name.lower())
        if not args.qml_debug:
            unwanted.extend(tooling)
        needed = {}
        with tempfile.TemporaryDirectory(prefix="qshopper-apk-check-") as temporary:
            for entry in libraries:
                local = Path(temporary) / Path(entry.filename).name
                local.write_bytes(package.read(entry))
                output = subprocess.check_output([str(args.readelf), "--needed-libs", str(local)],
                                                 text=True)
                dependencies = re.findall(r"^\s+(\S+\.so)\s*$", output, re.MULTILINE)
                needed[entry.filename.removeprefix(prefix)] = dependencies
                bundled = {name for name in dependencies
                           if name.startswith(("libQt6", "libqml_", "libplugins_"))
                           or name == "libc++_shared.so"}
                missing = {f"lib/{args.abi}/{name}" for name in bundled} - names
                assert not missing, f"Broken native dependency closure for {entry.filename}: {missing}"
        report = {
            "apk": str(args.apk),
            "apk_bytes": args.apk.stat().st_size,
            "abi": args.abi,
            "native_library_count": len(libraries),
            "native_bytes": sum(entry.file_size for entry in libraries),
            "unexpected_libraries": unwanted,
            "canvas_libraries": sorted(name for name in names
                                       if "canvas" in name.lower()),
            "native_dependencies": needed,
            "qml_debug_requested": args.qml_debug,
            "qml_tooling_libraries": tooling,
            "passed": not unwanted and bool(tooling) == args.qml_debug,
        }
    if args.deployment_settings:
        settings = json.loads(args.deployment_settings.read_text(encoding="utf-8-sig"))
        repository = Path(__file__).resolve().parents[1]
        cmake = (repository / "CMakeLists.txt").read_text()
        version = re.search(r"project\(QShopper VERSION ([0-9.]+)", cmake).group(1)
        code = re.search(r"set\(QSHOPPER_ANDROID_VERSION_CODE (\d+)\)", cmake).group(1)
        aapt2 = Path(settings["sdk"]) / "build-tools" / settings["sdkBuildToolsRevision"] / "aapt2.exe"
        if prefix:
            assert args.bundletool and args.bundletool.is_file(), "AAB inspection needs --bundletool"
            manifest = ET.fromstring(subprocess.check_output([args.java, "-jar", str(args.bundletool),
                "dump", "manifest", "--bundle", str(args.apk)], text=True))
            android = "{http://schemas.android.com/apk/res/android}"
            actual = (manifest.get("package"), manifest.get(android + "versionCode"),
                      manifest.get(android + "versionName"))
            report["debuggable"] = manifest.find("application").get(android + "debuggable", "false") == "true"
            report["min_sdk"] = int(manifest.find("uses-sdk").get(android + "minSdkVersion"))
            report["target_sdk"] = int(manifest.find("uses-sdk").get(android + "targetSdkVersion"))
            permissions = {entry.get(android + "name") for entry in manifest.findall("uses-permission")}
        else:
            badging = subprocess.check_output([str(aapt2), "dump", "badging", str(args.apk)], text=True)
            metadata = re.search(r"^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",
                                 badging, re.MULTILINE)
            assert metadata, "APK metadata missing"
            actual = metadata.groups()
            report["debuggable"] = "application-debuggable" in badging
            report["min_sdk"] = int(re.search(r"^(?:minSdkVersion|sdkVersion):'(\d+)'", badging, re.MULTILINE).group(1))
            report["target_sdk"] = int(re.search(r"^targetSdkVersion:'(\d+)'", badging, re.MULTILINE).group(1))
            permission_dump = subprocess.check_output([str(aapt2), "dump", "permissions", str(args.apk)], text=True)
            permissions = set(re.findall(r"^uses-permission: name='([^']+)'", permission_dump, re.MULTILINE))
        expected_permissions = {"shopper.nevala.com.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"}
        if args.qml_debug:
            expected_permissions.add("android.permission.INTERNET")
        report["permissions"] = sorted(permissions)
        assert permissions == expected_permissions, f"Unexpected Android permissions: {sorted(permissions - expected_permissions)}; missing: {sorted(expected_permissions - permissions)}"
        assert actual == ("shopper.nevala.com", code, version), f"Package version does not match CMake: {actual}"
        report["version_name"] = version
        report["version_code"] = int(code)
        app = repository / "app"
        roots = [Path(path).resolve() for path in settings["qml-root-path"]]
        generated = args.deployment_settings.resolve().parent / "generated"
        report["qml_scan_roots"] = [str(path) for path in roots]
        invalid_roots = [str(path) for path in roots
                         if not (path.is_relative_to(app) or path == generated)]
        report["invalid_qml_scan_roots"] = invalid_roots
        report["passed"] = report["passed"] and bool(roots) and not invalid_roots
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    assert not unwanted, "Unexpected Android payload: " + ", ".join(unwanted)
    assert bool(tooling) == args.qml_debug, "QML tooling must match the requested debug feature"
    if args.deployment_settings:
        assert roots, "No QML scan roots"
        assert not invalid_roots, "Scanner includes tests or historical builds: " + ", ".join(invalid_roots)
    print(f"PASS {args.abi}: app runtime present; unused payload absent; QML roots isolated")



if __name__ == "__main__":
    main()
