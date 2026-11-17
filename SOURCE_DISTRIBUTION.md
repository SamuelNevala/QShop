# Source and modified builds

QShopper is GPL-3.0-or-later; official Android builds use the GPLv3 option for
Qt runtime modules. Dependencies retain their own terms. Paying for a build does
not remove modification/redistribution rights. See [LICENSING.md](LICENSING.md)
and the offline **Licenses → App / Qt / Font Awesome** reader.

## Match a binary to its sources

Each released APK/AAB needs a source-set manifest recording its hash, version/code,
ABI, exact project/Qt revisions and all archive hashes. Download **every archive**
from that release's source link; moving master is not an exact historical source.
`tools/create-source-set.py` prepares local candidates; publication and verified
public downloads are separate release steps.

The set includes the complete selected project, Qt Base/Declarative/SVG at the
actual kit's SPDX commits, bundled third-party/Android bridge sources, resolved
Maven source JARs/POMs/legal files, NDK runtime notices and kit configuration.
Compilers, SDK/JDK, host Qt, CMake and Ninja are separately installed build tools.
Private signing keys are neither required nor included.

## Build the app

Use the manifest's versions. Baseline: Qt 6.12.0, CMake 3.25+, Ninja, JDK 21.0.12,
NDK 27.2.12479018, platform/build-tools 36/36.0.0. Follow [BUILDING.md](BUILDING.md)
and [ANDROID.md](ANDROID.md); the documented open-source route needs no paid Qt licence.

```powershell
./build-android.ps1 -Architecture arm64
```

`dist/QShopper-arm64-debug.apk` uses your local debug key. MinSizeRel produces an
unsigned optimized APK; sign it with your own key. Ordinary builds use bundled
notices and need no Python/network notice-generation step.

## Try modifications safely

In an independent source copy, change `QT_ANDROID_PACKAGE_NAME` in
app/CMakeLists.txt to a distinct ID such as `shopper.nevala.modified`; optionally
change the launcher name. Keep the QShopper module URI. Use a fresh build cache,
build, then `adb install dist/QShopper-arm64-debug.apk` on your selected test device.
The separate package keeps its own data. Do not uninstall the original app or
expect your key to sign an update for the developer's package.

## Rebuild Qt

Unpack the recorded sources, retain their notices and follow the version-matched
[Qt Android source-build instructions](https://doc.qt.io/qt-6/android-building.html).
Qt 6.12's Windows source build uses MinGW-w64 13.1; using prebuilt MSVC host
tools for an ordinary app build is a different workflow.

Use same-version host Qt and recorded SDK/NDK. Build/install Base, SVG and
Declarative into a **separate prefix**, retaining Quick, Material/Fusion/Basic,
SQLite, JPEG and VectorImage. Do not overwrite the stock SDK. In a fresh app
source/build copy, select your rebuilt kit explicitly:

```powershell
./build-android.ps1 -Architecture arm64 -AndroidQtPrefix C:/qt-modified/android_arm64_v8a -HostQtPrefix C:/Qt/6.12.0/mingw_64
```

Use a separate package/key as above. The app requires no developer key, server,
licence check or special unlock; ordinary Android installation/device rules apply.
App-source rebuild/side-by-side installation was tested. A complete vendor Qt
rebuild or bit-identical compiler output is not claimed.

## Maintainer checklist

1. Refresh notices from the actual Release runtime graph/NDK; rebuild/verify the
   final artifact and binding to source inputs.
2. Create the source set for the accepted revision and exact binary; candidate
   or uncommitted snapshots must not be advertised as accepted release sources.
3. Review the manifest and publish **all** files beside the binary/store source
   link; verify public hashes. Keep sources available for distributed versions
   and honor applicable delivery commitments.

The helper uses tracked files and rejects sensitive filenames. Still inspect
for credentials, local data, build output and private keys before publication.
