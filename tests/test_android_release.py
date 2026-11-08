"""Verify unsigned Release APK/AAB metadata, payload, symbols and 16 KB alignment."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--abi", required=True, choices=("arm64-v8a", "x86_64"))
    parser.add_argument("--deployment-settings", type=Path, required=True)
    parser.add_argument("--readelf", type=Path, required=True)
    parser.add_argument("--bundletool", type=Path)
    parser.add_argument("--java", default="java")
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    aab = args.artifact.suffix.lower() == ".aab"
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="qshopper-release-check-") as temporary:
        temporary = Path(temporary)
        inventory = temporary / "inventory.json"
        command = [sys.executable, str(Path(__file__).with_name("test_android_package.py")),
                   str(args.artifact), "--abi", args.abi, "--deployment-settings", str(args.deployment_settings),
                   "--readelf", str(args.readelf), "--report", str(inventory)]
        if aab:
            assert args.bundletool and args.bundletool.is_file(), "AAB check needs --bundletool"
            command.extend(["--bundletool", str(args.bundletool), "--java", args.java])
        subprocess.run(command, check=True)
        report = json.loads(inventory.read_text(encoding="utf-8"))
        assert not report["debuggable"], "Release must not be debuggable"
        assert report["min_sdk"] == 28 and report["target_sdk"] >= 36
        with zipfile.ZipFile(args.artifact) as package:
            expected = {line.strip().replace("{abi}", args.abi) for line in
                        (Path(__file__).resolve().parents[1] / "android/runtime-libraries.txt").read_text(encoding="utf-8").splitlines()
                        if line.strip() and not line.startswith("#")}
            actual = {Path(name).name for name in report["native_dependencies"]}
            assert actual == expected, f"Unexpected Release native payload; extra={actual - expected}, missing={expected - actual}"
            assert not any(re.search(r"^META-INF/[^/]+\.(RSA|DSA|EC|SF)$", name, re.I)
                           for name in package.namelist()), "Expected unsigned preparation artifact"
            alignments = {}
            debug_sections = []
            for entry in package.infolist():
                if entry.filename.endswith(".so") and "/" + args.abi + "/" in entry.filename:
                    local = temporary / Path(entry.filename).name
                    local.write_bytes(package.read(entry))
                    headers = subprocess.check_output([str(args.readelf), "-lW", str(local)], text=True)
                    loads = [line.split() for line in headers.splitlines() if line.strip().startswith("LOAD ")]
                    assert loads, "No ELF LOAD segments: " + entry.filename
                    for fields in loads:
                        assert int(fields[-1], 16) >= 16384, "ELF is not 16 KB aligned: " + entry.filename
                        assert int(fields[1], 16) % 16384 == int(fields[2], 16) % 16384
                    alignments[entry.filename] = [int(fields[-1], 16) for fields in loads]
                    sections = subprocess.check_output([str(args.readelf), "-SW", str(local)], text=True)
                    if re.search(r"\.(debug_info|debug_line)\s", sections):
                        debug_sections.append(entry.filename)
            assert not debug_sections, "Debug information is embedded in delivered libraries: " + str(debug_sections)
            report["elf_load_alignments"] = alignments
            report["delivered_debug_sections"] = debug_sections
            report["dex_bytes"] = sum(e.file_size for e in package.infolist() if e.filename.endswith(".dex"))
            report["bundle_metadata_bytes"] = sum(e.file_size for e in package.infolist()
                                                   if e.filename.startswith("BUNDLE-METADATA/"))
            report["compressed_native_bytes"] = sum(e.compress_size for e in package.infolist()
                                                     if e.filename.endswith(".so"))
            report["native_zip_methods"] = sorted({e.compress_type for e in package.infolist()
                                                    if e.filename.endswith(".so")})
        settings = json.loads(args.deployment_settings.read_text(encoding="utf-8-sig"))
        tools = Path(settings["sdk"]) / "build-tools" / settings["sdkBuildToolsRevision"]
        if aab:
            subprocess.run([args.java, "-jar", str(args.bundletool), "validate", "--bundle", str(args.artifact)], check=True)
            config = json.loads(subprocess.check_output([args.java, "-jar", str(args.bundletool), "dump", "config",
                                                        "--bundle", str(args.artifact)], text=True))
            native_config = config["optimizations"]["uncompressNativeLibraries"]
            assert native_config["enabled"], "Play native APK splits must support direct loading"
            assert native_config["alignment"] == "PAGE_ALIGNMENT_16K"
        else:
            subprocess.run([str(tools / "zipalign.exe"), "-c", "-P", "16", "4", str(args.artifact)], check=True)
            verification = subprocess.run([str(tools / "apksigner.bat"), "verify", str(args.artifact)],
                                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            assert verification.returncode != 0 and "DOES NOT VERIFY" in verification.stdout, \
                "Expected an unsigned APK; signing-tool result: " + verification.stdout
        report["unsigned"] = True
        report["artifact_bytes"] = args.artifact.stat().st_size
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"PASS unsigned Release {args.artifact.suffix}: metadata, payload, symbols and 16 KB alignment")


if __name__ == "__main__":
    main()
