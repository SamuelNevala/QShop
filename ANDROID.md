# Android APK

Build an installable ARM64 debug APK from PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build-android.ps1
```

Output: `dist/QShopper-arm64-debug.apk`.

The script defaults to Qt 6.12.0 in `C:\Qt`, the Android SDK in
`%LOCALAPPDATA%\Android\Sdk`, NDK 27.2.12479018, and the installed Adoptium
JDK 21. Override `-QtRoot`, `-QtVersion`, `-SdkRoot`, `-NdkVersion`, or
`-JavaHome` for other installations. This build uses compile SDK 36 and build tools 36.0.0. Gradle downloads build dependencies on the first run.

The APK uses package `shopper.nevala.com`, version 0.1 (code 1), and supports
ARM64 Android devices running Android 9 (API 28) or later. It is signed with
the local Android debug key. Store publication requires a release build
signed with the production keystore.

CMake stages the manifest and launcher icons from `android/`; Qt supplies
the Gradle configuration and wrapper appropriate to the installed Qt version.
The older Gradle files in `android/` are not used by this build.

Install on an attached device with USB debugging enabled:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r .\dist\QShopper-arm64-debug.apk
```

The build may report unresolved `Components` and `Shop.timer` imports in the
unused `Swipeable.qml` file, which is outside the app's QML module.

Qt command-line build reference:
<https://doc.qt.io/qt-6/android-building-projects-from-commandline.html>

## Android emulator

A local virtual phone named `QShopper_API_36` is registered with the Android SDK.
It uses the installed Android 16 (API 36) Google Play x86_64 image and Pixel 6 Pro
hardware profile. Its data is in `out/android-emulator/QShopper_API_36.avd`.
It is separate from physical phones and their app data. The profile does not
reproduce the Pixel 10 Pro XL's exact physical dimensions.

Start its visible window from PowerShell:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd QShopper_API_36 -port 5580 -gpu host -memory 3072 -scale 0.3
```

Host GPU rendering works on this PC; the emulator's software SwiftShader mode
produced rendering artifacts in Qt Quick. No production rendering override was added.

Build the emulator APK using the installed Qt Android x86_64 kit:

```powershell
./build-android.ps1 -Architecture x86_64
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s emulator-5580 install -r ./dist/QShopper-x86_64-debug.apk
```

The emulator build uses `out/android-emulator-build`. The default `arm64`
architecture continues to produce `dist/QShopper-arm64-debug.apk` for phones.
The CMake target explicitly selects compile SDK 36 because automatic SDK selection
picked the older android-33-ext5, which fails the current AndroidX requirements.

For automated launches, Qt's debug intent extras can set QSHOPPER_DATA_DIR without
changing the application's regular storage:

```powershell
$probeData = '/data/user/0/shopper.nevala.com/files/agent-testing/' + [guid]::NewGuid().ToString('N')
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s emulator-5580 shell am start -n shopper.nevala.com/org.qtproject.qt.android.bindings.QtActivity --es extraenvvars_QSHOPPER_DATA_DIR $probeData
```

Start this way with the app stopped so main.cpp receives the new environment.

Verified on 2026-10-27 with the real Android Gboard IME: typing Milk using on-screen
keys and tapping its Return key adds the item, clears the editor, and keeps Gboard
visible. Empty Return also keeps it open. Opening the drawer hides Gboard, and
closing the drawer then tapping the editor reopens it. Android dumpsys reports
`imeOptions=0x40000000` (IME_FLAG_NO_ENTER_ACTION) for the editor. Screenshots and
inspection output are in `out/android-emulator`; the check used a unique isolated
data directory. This is an emulator check, not a physical Pixel device check.
## Keyboard resize verification

The activity manifest explicitly sets `android:windowSoftInputMode="adjustResize"`.
Qt's default had selected adjustPan for the editor, leaving the bottom of a long
list behind the keyboard. Native resizing keeps the final list item and editor
reachable above the IME without adding a second keyboard-height padding in QML.

Verified on 2026-10-27 with Qt 6.12.0, Android 16, Gboard, and host GPU rendering:

- A fresh isolated 35-item list could be scrolled away from and back to its final
  item and editor with Gboard open.
- Ten keyboard hide/show cycles passed, including reopening the editor after each
  resize. Its center moved from screen y=2933 with the IME hidden to above Gboard
  when visible.
- A 39.96-second screen recording contained 975 captured frames. Automated analysis
  found no near-black app frames in the region above the keyboard; visual checks
  also showed no broken rendering. This checks this emulator configuration, not
  every device/GPU. Analysis thresholds are recorded alongside the video.
- Tapping Gboard Return added another item and retained the keyboard.
- The Windows verification script passed all three CTest entries after the change.

Artifacts are `out/android-emulator/resize-transitions.mp4`, `resize-cycles.json`,
`resize-frame-analysis.json`, and `resize-final.png`. The rebuilt emulator APK is
`dist/QShopper-x86_64-debug.apk`. The updated app remains running on the emulator.
