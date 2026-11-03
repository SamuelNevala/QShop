# Android APK

The project requires Qt 6.12+ including Qt Canvas Painter and its QtCanvas2D QML
plugin. UndoIcon uses the Qt 6.12 Canvas2D technology preview. Windows, Android
x86_64 and ARM64 kits must contain that module; runtime verification is recorded
separately from kit availability.

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
ARM64 Android devices running Android 9 (API 28) or later. By default it is signed
with the local Android debug key. To update an existing installation built on
another machine, supply the original debug keystore:

```powershell
./build-android.ps1 -Architecture arm64 -DebugKeystore ../debug.keystore
```

This re-signs and verifies the output APK using the standard `androiddebugkey`
alias and `android` debug passwords. The keystore stays outside the repository.
The supplied key must match the installed app's certificate; the shared source
folder alone does not share each machine's default `~/.android/debug.keystore`.
Store publication requires a release build
signed with the production keystore.

CMake stages the manifest and launcher icons from `android/`; Qt supplies
the Gradle configuration and wrapper appropriate to the installed Qt version.
The older Gradle files in `android/` are not used by this build.

Install on an attached device with USB debugging enabled:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r .\dist\QShopper-arm64-debug.apk
```

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

## Catalog proxy migration verification (DEV-007)

The drawer uses QtQml.Models.SortFilterProxyModel; the Android package must deploy
the QtQml.Models plugin as well as the native QmlModels library. On 2026-11-03,
the fresh Qt 6.12 x86_64 APK at
`out/dev007/android/android-build/build/outputs/apk/debug/android-build-debug.apk`
contained both and passed ten list-selector/cold-restart checks and 28 native
entry/catalog lifecycle checks on QShopper_API_36. Those checks use unique
QSHOPPER_DATA_DIR values and target only emulator-5580:

```powershell
python tests/android/test_popups.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --selector lists --restart --output out/dev007/android-popups
python tests/android/test_entry.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --gesture-jar out/dev007/gesture-helper/gesture.jar --output out/dev007/android-entry
```

The test-only gesture helper was built with `tools/build-android-gesture-test.ps1`.
Results include actual create/rename/delete/Undo, preserved UUIDs/list contents,
selection after process restart, Gboard entry and Back. The headless emulator was
stopped afterward. No physical phone was installed; Qt 6.10/6.11 and ARM64 runtime
were not retested. The model property preserves the older documented QML API,
retained as an alias in the validated Qt 6.12 kit.

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

## Android Back navigation (UI-006)

The view and drawer handle Back using Android-only window shortcuts. The drawer
owns a separate shortcut because its modal popup blocks the view's shortcut.
Each gesture closes an open selector popup first, then the drawer, hides the
keyboard while editing, or leaves edit mode, in that priority. Selector popups
are modal and dismiss on outside release: an initial edge press must survive
until Android recognizes Back and cancels its touch stream (UI-016). Outside
taps still dismiss the popup on release without activating controls below it. In shopping mode both shortcuts are disabled: the validated
Qt 6.12 Android platform backgrounds the task and keeps its process alive.
`Window.onClosing` is not used. This backgrounding behavior is documented in
[Qt's Android platform notes](https://doc.qt.io/qt-6/android-platform-notes.html#back-key-and-back-gesture).
Older Qt 6.10/6.11 background behavior has not been certified by these tests.

Hiding the keyboard keeps the draft. Leaving edit mode uses the existing policy
selected by the user: discard unsubmitted text and restore an original item if
its replacement was unfinished.

With the x86_64 debug APK installed on the unlocked English QShopper_API_36
emulator, Gboard enabled and gesture navigation selected, run:

```powershell
python tests/android/test_back.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/ui006-after
```

The script permits only an emulator, seeds a unique QSHOPPER_DATA_DIR and drives
native screen-edge swipes. It checks keyboard/editor/drawer priority, task
backgrounding, unchanged process ID after return, and saved list order/state.
It saves screenshots, UI XML, SQLite and results under the output directory, and
stops the test app afterward. It never installs an APK or touches a physical phone.

## Back gesture cancellation (UI-007)

UI-007 covers cancelled touches and immediate interaction recovery. Compile its
test-only continuous-touch injector, then run the matrix against the installed
emulator APK:

```powershell
./tools/build-android-gesture-test.ps1
python tests/android/test_back.py --adb C:/android/sdk/platform-tools/adb.exe --matrix --gesture-jar out/android-emulator/back-gesture/gesture.jar --output out/android-emulator/ui007-matrix-after
```

The helper requires JDK 21, Android SDK platform 36 and build-tools 36.0.0;
`-JavaHome` and `-SdkRoot` override the script defaults. It runs under the emulator
shell and is not packaged with QShopper. Unlike separate `input motionevent`
calls, it preserves one pointer and one downTime for the whole gesture.

The matrix covers both screen edges, keyboard open/closed, cancelled gestures
with 0 or 150 ms initial holds, and completed gestures with a 150 ms initial
hold. Each holds for a full second after Back recognition to expose a leaked
long-press timer. Android rejects a Back gesture when the initial stationary
hold exceeds its roughly 250 ms recognition timeout; such a hold is an app long
press rather than a Back cancellation test.

Checks cover row parenting, unchanged saved items, Back priority, and immediate
long-press reordering followed by checking/correction after every gesture. A
reorder/restore control precedes the matrix. Screenshots, accessibility XML,
SQLite and results are saved under the output directory. The default command
without `--matrix` still runs the seven UI-006 checks without needing the helper.

The continuous-touch reproduction failed before the fix: a row was orphaned
and the next checking swipe deleted it. Preventing only the late long-press
callback kept the row visible but still broke the next reorder. The final fix
replaces only a cancelled, still-pressed tap recognizer and rejects cancelled
swipes as actions. All 69 checks in the final matrix passed on 2026-10-29.
The Android 16/API 36 matrix is automated coverage. On 2026-10-29 the user also
confirmed that the fix works on the affected Pixel 10 Pro XL running Android 17.
This phone confirmation does not imply an exhaustive physical-device matrix.

## Selector safe areas (UI-010)

Long Lists, Accent and Primary popups use the full-window safe-area margins plus
the existing 2 mm spacing. They live in the window overlay, so the drawer's own
safe-area padding cannot constrain them. Option rows remain 9.27 mm high.

With the x86_64 debug APK installed on the English API 36 emulator, run:

```powershell
python tests/android/test_popups.py --adb C:/android/sdk/platform-tools/adb.exe --matrix --output out/android-emulator/ui010-matrix-after
```

The script seeds 30 saved lists and two shopping items in unique isolated data
directories. Native swipes reach both scroll limits, endpoint bounds are checked
against Android's reported system-bar/cutout bounds, and taps must persist the
expected list or color. SQLite checks that the shopping items remain intact.
The current matrix covers portrait, opening Gboard before the drawer (which
dismisses it and resizes the window), and requesting a rotated-device orientation
while the phone app remains portrait. Display and accessibility rotation are
asserted. Sensor-driven auto-rotation is covered separately by UI-011 below.
Rotation settings are restored and
the test app is stopped afterward. The script only accepts emulator serials and
does not install an APK. Use `--selector accent --endpoint first` for a narrow run.

On the original APK, both Accent endpoints failed the safe-bounds assertions;
evidence is in `out/android-emulator/ui010-regression-before` and
`ui010-last-before`. The first row overlapped the status bar and the last row
extended into the navigation-bar area.

The original UI-010 validation, before the UI-011 portrait restriction, uses the
portrait checks in `ui010-after`, the completed
`ui010-after-keyboard` profile and the rotation-asserted
`ui010-landscape-verified` profile. Their combined results and source paths are
recorded under `ui010-matrix-after`. Those true-landscape results are historical
coverage for that build. The current harness uses `--profile keyboard_resize`
or `--profile rotated` to run profiles separately.
All 54 checks passed on 2026-10-29. The shared-key ARM64 debug APK was rebuilt
and its signature verified. The user confirmed the fix on the affected Android 17
phone on 2026-10-29; this complements the automated emulator coverage.

## Portrait-only phone orientation (UI-011)

QtActivity requests `android:screenOrientation="portrait"` in the manifest.
Shopping, editing, the native keyboard and the drawer stay portrait when the
phone rotates. The request does not need a runtime orientation handler.

With the x86_64 APK installed on the English QShopper_API_36 phone emulator:

```powershell
python tests/android/test_portrait.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/ui011-after
python tests/android/test_popups.py --adb C:/android/sdk/platform-tools/adb.exe --profile rotated --output out/android-emulator/ui011-popups-after
```

The orientation test enables auto-rotate and changes the emulator's actual
acceleration sensors. Android Settings is a control that must rotate to landscape
before QShopper is tested. Cold launches held portrait/landscape, shopping
rotation in both directions, edit mode with keyboard hidden/visible, an
unfinished draft, and the open drawer are checked. Saved item order/checked
state and process continuity must survive. Display geometry is inspected before
and after accessibility dumps, with a bounded wait for activity launch
transitions. This avoids counting a system rotation lock as an app orientation
fix. The test uses isolated data, restores sensors/rotation settings, stops the
app, and only accepts an emulator serial.

The original APK fails `launch_held_landscape` at 3120x1440, rotation 1, after
the sensor control passes. Before/after artifacts are under
`out/android-emulator/ui011-before` and `ui011-after`.

On 2026-10-29 all 11 orientation/state checks and all 18 updated selector checks
passed. The Windows build and all three CTest entries also passed. The shared-key
ARM64 APK was rebuilt and its signature verified. The user waived physical
Android 17 phone testing and requested the commit; no physical-phone test is claimed.

Android can override orientation restrictions on large displays and in some
windowing/user configurations. In particular, the platform ignores these
restrictions on displays of at least sw600dp for apps targeting API 36 or newer;
the temporary API 36 opt-out does not apply when targeting API 37. The APK
currently targets API 37. Phone-emulator coverage uses sw411dp and does not
certify tablets, foldable inner displays or multi-window behavior. See the
[Android orientation restriction guidance](https://developer.android.com/about/versions/16/behavior-changes-16#large-screens).

## Reset checks ordering (UI-009)

Reset reverses the checked stack into the order in which items were checked.
Starting with `1,2,3` and checking `3,1,2` produces checked `2,1,3`; Reset must
produce unchecked `3,1,2`. For unchecked `A,B` before checked `C,D`, Reset produces
`A,B,D,C`. Unchecked entries stay in place. An edited checked item participates
through its pending original, and its draft follows that item's new position.
A free insertion point stays in place. A second Reset must not reverse again.

With the current x86_64 APK installed on the English API 36 phone emulator:

```powershell
python tests/android/test_reset.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/ui009-revised-after
```

The three isolated cases use actual left swipes, double taps and the drawer's
Reset checks button. They check chronological order and cleared flags, repeated
Reset, retained edit text and cold-restart persistence of order, flags and item
identities. The test only accepts emulator serials and stops the app afterward.

The corrected expectation fails against the previous APK: `2,1,3` stays `2,1,3`
instead of becoming `3,1,2`. Its evidence is in
`out/android-emulator/ui009-revised-before`. Earlier `ui009-*` reports without
`revised` refer to the superseded preserve-visible-order instruction, and are
not evidence for the final chronological-order requirement.

On 2026-10-30 all 13 revised native checks pass. The seven ResetChecks records
also pass with native Windows rendering; full Windows verification passes
92 UI, 6 keyboard and 61 model records. The updated shared-key ARM64 APK was
rebuilt and its signature verified. The user confirmed the supplied test APK
works and requested closure on 2026-10-30.
