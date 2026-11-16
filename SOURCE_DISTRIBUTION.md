# Source and modified builds

QShopper is GPL-3.0-or-later. Official Android builds use the GPLv3 option for
Qt's open-source runtime modules. Third-party licenses remain in force; see
[LICENSING.md](LICENSING.md) and the offline **Licenses → App / Qt / Font Awesome**
reader. Charging for the official build does not remove recipients' rights to
study, modify or redistribute the covered software.

## Match a binary to its sources

A released APK/AAB must be accompanied by a source-set manifest identifying its
SHA-256, version/code/ABI, exact project snapshot and Qt source commits, plus the
named source archives and their SHA-256 hashes. Download the manifest and all its
archives from the same release's source download link. A moving `master` branch
alone is not the exact source record for an older binary.

The release maintainer prepares these with `tools/create-source-set.py`. A
candidate source set is local preparation until its files and download link have
been published and verified. No production store release or source-download
release is claimed merely because this guide is present.

The set contains:

- The complete selected QShopper checkout: C++, QML, assets, notices and build
  scripts. A candidate manifest explicitly marks an uncommitted snapshot.
- Complete Qt Base, Qt Declarative and Qt SVG source archives at the commits
  recorded by the actual kit's SPDX documents, including Qt's Android Java
  bridge sources and bundled third-party source/license files.
- The resolved Android Maven source JARs/POMs and upstream legal files, NDK
  runtime notices, and the kit configuration/source metadata used for the audit.

Compilers, SDK/JDK, host Qt tools, CMake and Ninja are separately installed build
tools. The NDK C++ runtime is retained under its own permissive terms. Its
version/source information is included; it does not require a developer signing
key to modify or use it.

## Build the app

Use the versions in the source manifest. The current baseline is Qt 6.12.0,
CMake 3.25+, Ninja, JDK 21.0.12, Android NDK 27.2.12479018, SDK platform 36 and
build-tools 36.0.0. [ANDROID.md](ANDROID.md) describes the
ordinary PowerShell build. No paid Qt license is needed for the documented
open-source licensing route.

From the extracted QShopper source directory:

```powershell
./build-android.ps1 -Architecture arm64 -SdkRoot C:/android/sdk
```

The resulting `dist/QShopper-arm64-debug.apk` uses the builder's own local debug
key. `-Configuration MinSizeRel` instead produces an unsigned optimized APK;
sign it with your own key before installation. Ordinary builds use the bundled
notices and need no Python or notice-download step.

## Try a modified app without replacing shopping data

In your independent source copy, change the application target's
`QT_ANDROID_PACKAGE_NAME` in `app/CMakeLists.txt` from `shopper.nevala.com` to,
for example, `shopper.nevala.modified`. Optionally change `QT_ANDROID_APP_NAME`
to distinguish its launcher label. Keep the QShopper QML module URI unchanged.
Use a fresh build directory for this copy, then build and install its APK:

```powershell
adb install dist/QShopper-arm64-debug.apk
```

The different package has separate private data. Your modified APK is not an
update signed by the original developer; Android's normal signing checks still
apply. Do not uninstall the original app to experiment. Existing production
signing keys are not needed and are not part of Corresponding Source.

## Modify Qt and use the rebuilt libraries

Unpack the Qt source archives at their recorded commits. Keep their licenses,
third-party files and your changes. Follow Qt's version-matched
[Android source-build instructions](https://doc.qt.io/qt-6/android-building.html).
For Qt 6.12 on Windows, those instructions require MinGW-w64 13.1; MSVC is not
the supported host compiler for building Qt for Android itself. This differs
from using the validated prebuilt MSVC host tools to build QShopper normally.

Use a same-version host Qt, the recorded Android SDK/NDK and a separate install
prefix. Build/install Qt Base, then Qt SVG and Qt Declarative against that
prefix, retaining the Quick/Material/Fusion/Basic, SQLite, JPEG and VectorImage
features required by the app. Qt's configure/build/install commands and the
recorded kit configuration identify the relevant inputs. Do not overwrite an
existing SDK installation while experimenting.

Point QShopper at the rebuilt SDK explicitly:

Use another fresh source/build copy when switching Qt installations; do not
reuse a CMake cache created for the stock SDK.

```powershell
./build-android.ps1 -Architecture arm64 -SdkRoot C:/android/sdk -AndroidQtPrefix C:/qt-modified/android_arm64_v8a -HostQtPrefix C:/Qt/6.12.0/mingw_64
```

This selects the modified Android SDK's `qt-cmake` and libraries while keeping
the chosen host tools separate. Build a separately named app as above and sign
with your own key. No QShopper license check, private key, developer server or
special device unlock is required by the app to build or run this copy; normal
Android installation permissions and device policies apply.

The audit tests the app-source rebuild and side-by-side install path. It does
not claim a complete vendor Qt framework rebuild or identical binary output
from different compiler versions. Preserve Qt's configuration and use its
documented prerequisites when rebuilding the framework.

## Release maintainer procedure

1. Generate/check the offline notices from the actual Release Gradle runtime
   graph and NDK. Rebuild and verify the final APK/AAB.
2. Prepare a source set for the exact accepted source revision and artifact.
   Candidate snapshots are explicitly marked and cannot be advertised as an
   accepted release source set.
3. Retain and publish all source-set files, not just the application archive or
   links to moving upstream branches. Provide the source download link alongside
   the binary/store distribution and in the release notes/source guide.
4. Verify the published files against the manifest. Keep them available for the
   distributed versions and retain any applicable source-delivery commitments.

Never put production/debug private keys, credentials, normal app data or build
directories into the source set. The helper includes tracked source files only
and refuses sensitive tracked filenames. Review its manifest before publishing.
