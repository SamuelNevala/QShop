"""Regenerate offline Qt/Font Awesome notices from the installed Qt SBOMs.

Development-only tool. Requires network access to the pinned upstream sources;
the app and its ordinary build never download notices.
"""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import posixpath
import re
from urllib.request import Request, urlopen
import uuid

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "out/ui012/license-source-cache"
SOURCES = {}
FONT_AWESOME_VERSION = "7.3.1"
FONT_AWESOME_FILE = "fa-solid-900.otf"
FONT_AWESOME_DOWNLOAD = ("https://github.com/FortAwesome/Font-Awesome/releases/download/"
                         f"{FONT_AWESOME_VERSION}/fontawesome-free-{FONT_AWESOME_VERSION}-desktop.zip")


def fetch(url):
    cached = CACHE / hashlib.sha256(url.encode()).hexdigest()
    if not cached.exists():
        cached.parent.mkdir(parents=True, exist_ok=True)
        temporary = cached.with_suffix("." + uuid.uuid4().hex)
        temporary.write_bytes(urlopen(Request(url, headers={"User-Agent": "QShopper-notices"}),
                                      timeout=45).read())
        temporary.replace(cached)
    data = cached.read_bytes()
    SOURCES[url] = hashlib.sha256(data).hexdigest()
    return data.decode("utf-8-sig").replace("\r\n", "\n")


def load_kit(kit, version, keyboard=False):
    modules = ["qtbase", "qtdeclarative", "qtsvg"] + (["qtvirtualkeyboard"] if keyboard else [])
    documents = {}
    for module in modules:
        path = kit / "sbom" / f"{module}-{version}.spdx.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        document["repository"] = module
        location = document["packages"][0]["downloadLocation"]
        document["commit"] = location.rsplit("@", 1)[1] if "@" in location else "v" + version
        documents[module] = document
    return documents


def select(documents, seed_names=None, native_names=None, keyboard=False):
    packages = {p["SPDXID"]: (p, doc) for doc in documents.values() for p in doc["packages"]}
    relationships = [r for doc in documents.values() for r in doc["relationships"]]
    if native_names is not None:
        files = {f["SPDXID"] for doc in documents.values() for f in doc["files"]
                 if PurePosixPath(f["fileName"]).name in native_names}
        seeds = {r["spdxElementId"] for r in relationships
                 if r["relationshipType"] == "CONTAINS" and r["relatedSpdxElement"] in files}
    else:
        seeds = {key for key, (p, _) in packages.items() if p["name"] in seed_names}
    if keyboard:
        seeds.update(p["SPDXID"] for p in documents["qtvirtualkeyboard"]["packages"]
                     if "qt-module" in p["SPDXID"] or "qt-plugin" in p["SPDXID"])
    dependencies = {}
    for relation in relationships:
        if relation["relationshipType"] == "DEPENDS_ON":
            dependencies.setdefault(relation["spdxElementId"], []).append(
                relation["relatedSpdxElement"].split(":")[-1])
    seen, pending = set(), list(seeds)
    while pending:
        key = pending.pop()
        if key not in seen:
            seen.add(key)
            pending.extend(dependencies.get(key, []))
    # Qt's platform CMake helper attributions describe build tools, not runtime code.
    attributions = [packages[key] for key in sorted(seen) if key in packages
                    and "Information extracted from:" in packages[key][0].get("comment", "")
                    and not packages[key][0]["name"].startswith("Platform_Attribution_")]
    return attributions, sorted(packages[key][0]["name"] for key in seeds)


def attribution(package, document):
    comment = package["comment"]
    path = re.search(r"/src_dir/(\S+/qt_attribution.json)", comment).group(1)
    index = int(re.search(r"Entry index: (\d+)", comment).group(1))
    relative = PurePosixPath(path).relative_to(document["repository"])
    base = f"https://raw.githubusercontent.com/qt/{document['repository']}/{document['commit']}/"
    # Qt attribution descriptions can contain literal line breaks inside strings.
    metadata = json.loads(fetch(base + str(relative)), strict=False)
    entry = metadata[index] if isinstance(metadata, list) else metadata
    sections = [entry["Name"], "Version: " + package.get("versionInfo", "unspecified"),
                "License: " + package["licenseConcluded"],
                package.get("copyrightText", ""), "Source: " + base + str(relative)]
    license_files = entry.get("LicenseFiles", [])
    if entry.get("LicenseFile"):
        license_files.append(entry["LicenseFile"])
    if entry.get("CopyrightFile"):
        license_files.append(entry["CopyrightFile"])
    for name in license_files:
        # Normalize Qt's relative attribution paths before constructing the URL.
        url = base + posixpath.normpath(str(relative.parent / name))
        sections.extend(["\n" + name + "\n", fetch(url)])
    return entry["Id"], "\n".join(sections), package["licenseConcluded"]


def font_awesome_notice(spdx_commit):
    source = f"https://raw.githubusercontent.com/FortAwesome/Font-Awesome/{FONT_AWESOME_VERSION}/LICENSE.txt"
    cc_by = f"https://raw.githubusercontent.com/spdx/license-list-data/{spdx_commit}/text/CC-BY-4.0.txt"
    return (f"Font Awesome 7 Free Solid, version {FONT_AWESOME_VERSION}\n"
            "Copyright (c) 2026 Fonticons, Inc. (https://fontawesome.com)\n"
            f"The included {FONT_AWESOME_FILE} font is licensed under the SIL Open Font License 1.1.\n"
            "The tab logo is the Font Awesome brand SVG (CC BY 4.0), with its fill changed to blue.\n"
            f"Logo source: https://github.com/FortAwesome/Font-Awesome/blob/{FONT_AWESOME_VERSION}/svgs/brands/font-awesome.svg\n"
            "https://fontawesome.com\n\n" + fetch(source) + "\n\n" + fetch(cc_by))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-report", type=Path, required=True)
    parser.add_argument("--qt-root", type=Path, default=Path("C:/Qt/6.12.0"))
    parser.add_argument("--qt-version", default="6.12.0")
    parser.add_argument("--output", type=Path, default=ROOT / "app/licenses")
    args = parser.parse_args()
    payload = json.loads(args.package_report.read_text(encoding="utf-8"))
    android_kit = {"arm64-v8a": "android_arm64_v8a", "x86_64": "android_x86_64"}[payload["abi"]]
    android = load_kit(args.qt_root / android_kit, args.qt_version)
    android_rows, seeds = select(android, native_names={PurePosixPath(p).name
                                                       for p in payload["native_dependencies"]})
    desktop = load_kit(args.qt_root / "msvc2022_64", args.qt_version, keyboard=True)
    desktop_seeds = set(seeds) - {"QAndroidIntegrationPlugin"} | {"QWindowsIntegrationPlugin"}
    desktop_rows, _ = select(desktop, seed_names=desktop_seeds)
    keyboard_rows, _ = select(desktop, seed_names=desktop_seeds, keyboard=True)
    selections = {"Qt-Android.txt": android_rows, "Qt-Windows.txt": desktop_rows,
                  "Qt-Windows-Keyboard.txt": keyboard_rows}
    all_rows = {(doc["repository"], doc["commit"], row["SPDXID"]): (row, doc)
                for rows in selections.values() for row, doc in rows}
    rendered = {key: attribution(*pair) for key, pair in all_rows.items()}
    spdx_commit = json.loads(fetch("https://api.github.com/repos/spdx/license-list-data/commits/main"))["sha"]
    extracted = {item["licenseId"]: item["extractedText"]
                 for doc in [*android.values(), *desktop.values()]
                 for item in doc.get("hasExtractedLicensingInfos", [])}
    qt_base = android["qtbase"]
    qt_source = f"https://raw.githubusercontent.com/qt/qtbase/{qt_base['commit']}/LICENSES/"
    qt_license = fetch(qt_source + "LGPL-3.0-only.txt") + "\n\n" + fetch(qt_source + "GPL-3.0-only.txt")
    outputs, inventories = {}, {}
    for filename, rows in selections.items():
        entries = {}
        for row, doc in rows:
            item = rendered[(doc["repository"], doc["commit"], row["SPDXID"])]
            entries.setdefault(item[0], item)
        parts = [f"Qt {args.qt_version}", "Copyright (C) The Qt Company Ltd. and other contributors.",
                 "Qt and the Qt logo are trademarks of The Qt Company Ltd. and/or its subsidiaries.",
                 "This application uses Qt. The LGPL v3 and GPL v3 license texts are provided below,\n"
                 "along with notices for third-party code included in the Qt libraries.",
                 "https://www.qt.io/licensing/open-source-lgpl-obligations",
                 "Qt source: https://code.qt.io/cgit/qt/qtbase.git/ and https://code.qt.io/cgit/qt/qtdeclarative.git/"]
        if "Keyboard" in filename:
            parts.append("Qt Virtual Keyboard is included in this desktop development build under GPL v3.\n"
                         "Source: https://code.qt.io/cgit/qt/qtvirtualkeyboard.git/")
        parts.extend(["\nQT OPEN-SOURCE LICENSE TEXTS\n", qt_license,
                      "\nBUNDLED THIRD-PARTY NOTICES\n"])
        license_ids = set()
        for _, text, expression in sorted(entries.values()):
            parts.extend(["\n" + "=" * 60 + "\n", text])
            license_ids.update(re.findall(r"[A-Za-z0-9][A-Za-z0-9.+-]*", expression))
        parts.append("\nCOMPLETE STANDARD LICENSE TEXTS\n")
        for license_id in sorted(license_ids - {"AND", "OR", "WITH"}):
            text = extracted.get(license_id)
            if text is None:
                text = fetch(f"https://raw.githubusercontent.com/spdx/license-list-data/{spdx_commit}/text/{license_id}.txt")
            parts.extend(["\n" + license_id + "\n", text])
        outputs[filename] = "\n".join(parts) + "\n"
        inventories[filename] = sorted(entries)
    outputs["FontAwesome.txt"] = font_awesome_notice(spdx_commit)
    for filename, text in outputs.items():
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output / filename).write_text(text, encoding="utf-8", newline="\n")
    manifest = {"qt_version": args.qt_version, "android_runtime_seeds": seeds,
                "font_version": FONT_AWESOME_VERSION, "font_file": FONT_AWESOME_FILE,
                "font_source": FONT_AWESOME_DOWNLOAD,
                "font_sha256": hashlib.sha256((ROOT / "app" / FONT_AWESOME_FILE).read_bytes()).hexdigest(),
                "components": inventories, "sources": dict(sorted(SOURCES.items())),
                "files": {name: hashlib.sha256(text.encode()).hexdigest() for name, text in outputs.items()}}
    (args.output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("Generated offline notices:", {name: len(text.encode()) for name, text in outputs.items()})


if __name__ == "__main__":
    main()
