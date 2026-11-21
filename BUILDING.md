# Build QShopper

## Install the tools

Use Qt's installer to install **Qt 6.12+**, Qt Creator, CMake and Ninja.
The validated kit is Qt **6.12.0 MSVC 2022 x64** with Visual Studio's C++ desktop
tools. Core, Qml, Quick, QuickControls2, Sql and SVG/VectorImage support are
required. Qt Linguist tools in the host kit compile the Finnish catalog. The
default desktop Debug build also uses Qt Virtual Keyboard.

For Android, install the matching ARM64 Qt kit, Android SDK/NDK and JDK 21.
The validated SDK platform/build-tools are 36/36.0.0 and NDK is 27.2.12479018.
Configure their locations in Qt Creator's Android settings. Add the x86_64 Qt kit
only if you want an emulator build.

## Qt Creator

1. Clone `https://github.com/SamuelNevala/QShop.git`.
2. Open the checkout's `CMakeLists.txt`.
3. Select the Qt 6.12 desktop or Android kit and an out-of-source build directory.
4. Configure, build, then Run. For Android, select your device or emulator.

Keep all build directories outside `app/`: Android scans that directory for QML.
Creator discovers Qt's tools from the selected kit. Use `.qmlformat.ini` and
`.clang-format`; if Beautifier cannot find clang-format, select
`C:/Qt/Tools/QtCreator/bin/clang/bin/clang-format.exe` (adjust for your installation).

## PowerShell

Run commands from the checkout. The Windows helper initializes Visual Studio:

```powershell
./tools/verify-windows.ps1 -Action Build
$env:PATH = 'C:/Qt/6.12.0/msvc2022_64/bin;' + $env:PATH
./out/windows-agent/application.exe
```

The existing helper uses `out/windows-agent`. Override `-QtRoot`, `-CMakeBin` or
`-Ninja` if Qt is installed elsewhere. To build **and** run tests, omit
`-Action Build`; to test an existing build, use `-Action Test`.

For an Android debug APK:

```powershell
./build-android.ps1 -Architecture arm64
```

The APK is `dist/QShopper-arm64-debug.apk`. See [ANDROID.md](ANDROID.md) for
installation, signing compatibility, emulator and Release/AAB options.

## Useful CMake settings

| Setting | Purpose |
| --- | --- |
| `QSHOPPER_DESKTOP_KEYBOARD=AUTO/ON/OFF` | AUTO enables the embedded keyboard for desktop Debug; Android always uses its system keyboard |
| `BUILD_TESTING=OFF` | Build the app without desktop tests |
| `QSHOPPER_MODEL_COVERAGE=ON` | Optional MSVC model coverage run; see the test guide |

To refresh the editable Finnish strings after changing UI copy, build the
`update_translations` target. The normal build compiles the catalog and fails if
it contains unfinished entries.

Set cache options in Qt Creator's CMake configuration. For a multi-configuration
generator, choose the desktop keyboard ON or OFF explicitly.

## Common problems

- **No C++ compiler:** install Visual Studio C++ tools and select the MSVC kit.
- **Missing Qt module:** add it to the same Qt version/architecture as the kit.
- **Android prerequisites:** check SDK, NDK and JDK paths; script options are
  `-SdkRoot`, `-NdkVersion`, `-JavaHome`, `-QtRoot` and `-QtVersion`.
- **App not installed on update:** the APK must use the installed app's signing
  certificate and an acceptable version code. Do not uninstall to work around
  signing errors if you need the existing lists.
- **Analysis warning:** confirm it against behavior before applying a fix.

Tests and formatters: [tests/README.md](tests/README.md).
Release publication: [RELEASE.md](RELEASE.md).
Qt reference: [building Android apps](https://doc.qt.io/qt-6/android-building-projects-from-commandline.html).
