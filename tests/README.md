# Model QTest suite (MSVC)

The test executable compiles only `test_model.cpp` and links to the production
`QShopper` QML backing library. The application links to the same library, so
`model.cpp` and `undoremove.cpp` are compiled once.

The suite covers roles, insertion/reordering, check/reset, deletion/undo,
editors, read-only item mutations, list management, persistence, and rollback.
Edit regressions cover pending data preservation, cancellation, first/last rows,
editor positions, adjusted editor row tagging, invalid calls, identity, checked
state, and list switching.
Each test gets fresh in-memory SQLite storage.

Toggle regressions cover empty models, negative and out-of-range indexes,
extreme indexes, read-only calls, reordering, identity, and persistence.

Read-only bulk removal regressions verify unchanged rows, editor position,
pending edits, undo history, and saved contents. Internal reloads still replace
read-only model contents from the database.

An unfinished edit retains the original saved row. Submitting at the editor
position preserves its UUID and checked state. Removing the editor restores the
original; reload or list switching cancels the edit. A second edit is rejected
until the current one is submitted or cancelled.

Use CMake 3.22+, the MSVC Qt kit, and an x64 Native Tools Command Prompt (or
Developer PowerShell) for Visual Studio. Configure from the project root so the
production library target is available:

```powershell
cmake -S . -B build-model-msvc-ninja -G Ninja -DCMAKE_CXX_COMPILER=cl -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=C:/Qt/6.12.0/msvc2022_64
cmake --build build-model-msvc-ninja --target qshopper_tests
ctest --test-dir build-model-msvc-ninja --output-on-failure
```

Test setup stays in `tests/CMakeLists.txt`. The root includes it when
`BUILD_TESTING=ON`. CTest supplies the Qt DLL search path and writes
`tests/model-tests.xml`.

## Model line coverage

Coverage uses [Microsoft.CodeCoverage.Console](https://learn.microsoft.com/en-us/visualstudio/test/microsoft-code-coverage-console-tool),
MSVC Debug PDBs, and Python 3 (no Python packages). A Visual Studio installation
with native C++ coverage support is required. CMake searches installed Visual
Studio coverage tools; set `MODEL_COVERAGE_TOOL` explicitly if necessary.

```powershell
cmake -S . -B build-model-msvc-ninja -G Ninja -DCMAKE_CXX_COMPILER=cl -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=C:/Qt/6.12.0/msvc2022_64 -DQSHOPPER_MODEL_COVERAGE=ON
cmake --build build-model-msvc-ninja --target model_coverage
```

For a Visual Studio multi-configuration generator, pass `--config Debug` when
building and `-C Debug` when running CTest.

The collector instruments the linked test executable and restores it afterward.
The target requires fresh passing QTest results and at least **80% aggregate line
coverage of model.cpp + model.h**. Dependencies, tests, QML, and generated code
are excluded from the summary. Reports are in `tests/coverage/summary.md`,
`summary.json`, and `model.cobertura.xml` inside the build directory.

Verified with MSVC 19.44 / Qt 6.12: **94.56% (452/478 lines)**.

## UI behavior verification

For the current control-to-test map, new user-flow suite, platform gaps and
native commands, see [INTERACTIONS.md](INTERACTIONS.md). Historical counts below
describe earlier verification stages. QA-003 adds a separate flow CTest entry
with explicit input-readiness checks. UI-015 remains a transition-time validation
candidate; normal flow assertions have no expected-failure or skip markers.
Remaining native/dictation gaps are recorded explicitly. UI-016 subsequently
fixes the selector Back regression: all 26 native left/right checks pass. The
selector waits for outside release, so Android cancelling the initial edge
touch cannot dismiss it before Back arrives. See the UI-016 section below.

Run `./tools/verify-windows.ps1` from the project root to build the app and both
suites, then run CTest. Qt Quick Test must be installed in the Qt kit.
The UI harness uses the production QShopper module,
in-memory SQLite and temporary settings. Its report is written to
`out/windows-agent/tests/ui-tests.xml`.

Seven scenarios cover empty-list edit mode, keyboard item submission, empty
submission, leaving/re-entering edit mode, a pointer swipe to check an item and
resetting it, bulk removal/undo through view actions, and a pointer click on the
editor menu button. Tests wait for delegate animations before pointer input.
Bulk removal/undo calls the view action and editor signal; it does not click
full-app drawer buttons.

Before a full-app test, set `QSHOPPER_DATA_DIR` to a unique disposable directory.
It isolates the app database and default settings. The QML harness instead uses
in-memory storage without launching main.cpp.

Verified on Windows, 2026-10-03: seven UI scenarios passed (nine QTest records
including setup/cleanup), and all 52 model QTest records passed. A separate
visible Windows run verified startup/rendering, typing and submitting Milk,
left-swipe checking (strikethrough and reordering), opening the drawer, and
switching from Dark to Light theme. Personal shopping data was not used.

Earlier full-app finding, resolved as UI-001 on 2026-10-31:

- On fresh data, the Lists combo box had blank selected text although the
  default list was active. See the UI-001 regression evidence below.

The former null-dimensions startup error (UI-002) is resolved by the Theme migration:
components use Theme.pixels() directly and no longer wait for a Dimensions assignment.

## Theme sizing verification

Theme.qml replaces ThemeManager.qml while retaining the preference keys.
Theme.pixels(millimeter) multiplies millimeters by the QML Screen.pixelDensity,
preserving fractional values. Non-Android Debug builds additionally apply the desktop
preview scale and any monitor correction described below. Android and release builds
use the screen density alone. There is no additional devicePixelRatio adjustment.
The inverse conversion, Theme.millimeters(pixels), is used for swipe distances.
The app attaches the singleton Theme Item to window.contentItem, allowing its
Screen attached properties to follow the app window. LoaderWindow loads the view
without creating or passing Dimensions. Dimensions-based scale, orientation and
geometry persistence are unused. QtCore.Settings aliases now persist Theme.scale
and window x/y, as described below. main.qml sets a 76.6 by 162.8 millimeter
reference window size using Theme.pixels(), with
resizing deferred through Qt.callLater() after density or preview-scale changes.
LoaderWindow and DefaultAnimation belong to the QShopper module.

Two sizing scenarios use the real attached Screen density to verify conversion,
inverse conversion, and component construction and fractional sizing without a
Dimensions reference. Together with the seven interaction scenarios, four preview
scenarios, two persistence scenarios and a popup sizing regression, the QML suite contains 16 scenarios
(26 QTest records including setup/cleanup).
The model suite passes 52 QTest records. Both CTest entries pass on Windows.
The suites also pass with QT_SCALE_FACTOR=2; sizing expectations come from the
test scene's Screen.pixelDensity rather than a fabricated screen object.
After removing Dimensions usage, a separate offscreen full-app startup with
disposable data reached the loaded shopping view without QML binding errors or
Dimensions initialization messages.
This startup check does not certify visual appearance.
An earlier visible Windows run with disposable data verified startup and the
drawer's list and color selector geometry. The former blank fresh-install selection
is resolved as UI-001, with current rendering verification documented below.
That earlier run did not cover the later changes.

The offscreen suite does not validate the complete drawer, list switching,
long-press reordering, touch input, actual monitor/DPI switching, or Android behavior.

## Desktop Debug preview scale

Theme declares scaleable with a default of false. Before loading the main
view, main.cpp obtains the existing Theme singleton through singletonInstance()
and sets this property to true only in non-Android Debug builds. Android builds
(including Debug) and non-Debug desktop builds use effective scale 1, without
the TV correction. The preview flag uses no context property, additional
singleton, startup environment variable, or forced QT_SCALE_FACTOR.

In a desktop Debug run, Page Up increases scale by 0.1 and Page Down decreases
it by 0.1 through Theme.scaleUp() and Theme.scaleDown(). Both functions return
immediately when scaleable is false. Ctrl+0 resets scale to 1. The allowed range is 0.25 to 4.0 and the current
percentage appears in the window title. Theme uses its inherited Item.scale and
sets visible: false so the singleton is not rendered. Its scale restores from settings,
with a fresh-install default of 2.0. Set it directly for manual adjustment.

The LG TV SSCR2 receives a separate debug-only density correction of 1.5 because
its HDMI physical-size report is incorrect. Other displays use correction 1.
Preview zoom is independent of this calibration and of Qt's normal high-DPI support.

No refresh signal or view reconstruction is needed: QML tracks property reads
inside Theme.pixels()/Theme.millimeters(). A preview-scale change updates the
effective density, which recalculates existing bindings and queues a window resize.
Geometry must remain a binding (for example, height: Theme.pixels(9.27)); assigning
a numeric height once from JavaScript does not create such a binding.

The PreviewScaling suite verifies the build/platform gate, live resizing of
existing components, inverse conversions, bounds, keyboard zoom, window resizing,
and preservation of list data. The same tests run in Debug and Release, with
an independent CMake-provided expectation for whether preview should be enabled.

Verified on Windows, 2026-10-25: Debug and Release application builds and both
CTest suites passed. Native Windows preview tests passed, including keyboard
zoom, component recalculation and unchanged shopping-list data. A separate
native test moved a 150% preview between the LG TV and LG ULTRAFINE repeatedly;
window dimensions settled correctly with no binding-loop warnings. Existing
Windows DPI-transition setGeometry diagnostics remain (also reproducible with
a plain fixed-size Qt window). The Android ARM64 Debug QShopper backing library also
cross-compiled successfully; Android device behavior was not tested.

## Window and scale persistence

QtCore.Settings aliases automatically restore and save Theme.scale at key `scale`
and window coordinates at `Window/x` and `Window/y`. Width and height are calculated
from millimeters and the effective scale. Android and release builds still use an
effective scale of 1 regardless of the saved scale value.

Two isolated persistence scenarios verify the saved scale in a fresh QML engine
and the saved coordinates after destroying and recreating the production main window.
The window test loads the view synchronously so it does not depend on frame-driven
asynchronous incubation. Existing sizing and preview tests reset scale to 1 in setup.

Verified on Windows, 2026-10-26: Debug and Release builds and both CTest suites passed
(52 model records and 23 QML records). The two persistence scenarios also passed on
the native Windows platform. That native session exposed a disconnected WinDisc screen
with invalid physical density, producing geometry and startup QML warnings; it does
not certify visual sizing on the TV or another real display. Android was not tested
for this change.

## ComboBox popup sizing

ComboBox and ColorComboBox use the same millimeter rowHeight. Popup height is
calculated from row count plus padding and capped to the window height minus
popup margins. It does not depend on ListView.contentHeight, whose viewport-driven
updates could re-enter Material's inherited popup height binding.

The popup regression opens the Lists, Accent and Primary selectors repeatedly,
scrolls their options, changes the window height and adjusts Theme.scale. Binding
loops fail the test. The native Windows reproduction failed before the fix and
passed afterward; the full offscreen QML and model suites also passed. Existing
Windows geometry clamping diagnostics can still occur at maximum preview zoom.

## Desktop virtual keyboard

`QSHOPPER_DESKTOP_KEYBOARD=AUTO` enables the embedded Qt Virtual Keyboard in desktop
single-configuration Debug builds and disables it in other builds. Set it to `ON`
or `OFF` in Qt Creator's CMake configuration to override the desktop default.
Multi-configuration generators require an explicit ON/OFF choice. Android always
uses its native keyboard. The selected desktop Qt kit must contain Virtual Keyboard
when enabled. Startup sets the required input-plugin environment internally before
constructing QGuiApplication; no shell variables or source edits are required.

DevelopmentKeyboard reserves space at the bottom of View without changing the
phone window's size. InputPanel follows the available width and supplies its own
height, so preview zoom scales the keyboard once. Enter adds an item and retains
focus. InputDelegate sets EnterKey.type to Qt.EnterKeyReturn so Android native keyboards
receive a Return/no-Enter-action hint rather than the default Done action. The desktop
InputPanel setting alone does not affect Android. The keyboard hide key and opening
the drawer dismiss it. Tapping the editor
opens it again, including when that field already has focus.

The keyboard-only InputPanel is packaged conditionally from `keyboard/DesktopKeyboard.qml.in`.
The generated loader has no Virtual Keyboard import in disabled builds. CMake adds
Virtual Keyboard module dependencies only when enabled, keeping deployment scans
from finding desktop-only imports in Android and default Release builds. The
keyboard test's API adapter uses runtime imports for the same reason.

The normal QML suite verifies the build gate. Enabled builds add a separate
`qshopper_keyboard_tests` CTest entry using the actual input plugin. Three scenarios
exercise on-screen letter and Enter keys, submission of committed preedit text,
hide/reopen without resizing the window, preview resize, and drawer dismissal.
Its JUnit report is `out/windows-agent/tests/keyboard-tests.xml`.
These tests use the same in-memory database and temporary settings as the ordinary
UI suite. Native Windows rendering checks complement the offscreen CTest run.

Verified on Windows, 2026-10-27: Debug application build and all three CTest entries
passed (52 model records, 27 ordinary QML records, 5 keyboard records). Release
application build and both applicable CTest entries passed. All three keyboard
scenarios passed in three consecutive native Windows runs after making editor taps
explicitly restore focus. A native screenshot confirmed the editor and full-width
keyboard render in separate areas. An isolated actual application startup registered
the embedded panel without external input-plugin environment variables. Qt Creator's
Debug application output was rebuilt. Android ARM64 QShopper and application native
targets compiled, and Android/default Release import scans exclude Virtual Keyboard.
Android device behavior and APK installation were not tested for this change.

The field-level Return hint follow-up passed all Debug CTest entries, the native
Windows keyboard scenarios, and Android ARM64 native compilation. The keyboard
harness now waits for the editor's slide-in animation before clicking it; otherwise
a native pointer test could click outside the window. Android IME behavior still
requires a device check. The Qt Creator executable could not be relinked during
this follow-up because its application was running; close it and rebuild to update.
Android emulator verification on 2026-10-27: the production x86_64 APK ran on
QShopper_API_36 (Android 16 Google Play image, Gboard). Real on-screen typing and
Return submitted Milk and retained the keyboard; empty Return retained it too.
Opening the drawer dismissed the IME, and tapping the editor after closing the
drawer reopened it. Android reported IME_FLAG_NO_ENTER_ACTION. Host GPU rendering
removed SwiftShader artifacts. The app used a unique QSHOPPER_DATA_DIR provided
through Qt's debug intent extra. The visible emulator was left running for the user.
See ANDROID.md for build/start commands; a physical phone was not tested.

Android adjustResize follow-up, 2026-10-27: the manifest now requests native
resizing explicitly. On the Android 16/Gboard emulator, the end of an isolated
35-item list and its editor remained reachable with the IME visible, including
scrolling away and back. Ten hide/show cycles passed. A 39.96-second recording
with 975 captured frames contained no near-black app frames under the documented
threshold; final and darkest-frame visual checks showed no broken rendering.
Native Return still submitted a new item and kept the IME visible. Windows
configure/build and all three CTest entries passed. This does not certify other
Android versions or physical-device graphics drivers. See ANDROID.md for artifacts.

## UI-004 swipe regression

`qml/tst_swipe.qml` adds 20 parameter cases to normal Windows verification:
distance actions with mouse and touch, velocity-only actions with touch, and
short/slow and pullback rejection, in both directions and both modes. Distance
cases disable the velocity alternative to test the half-width fallback alone.
Touch timestamps exercise velocity; native mouse cursor delivery is asynchronous.
Fixtures use the model to seed data, then actual pointer events drive each action.

Before the fix, the four rightward distance cases failed: checking and deletion
did not occur. The fixed component passes them and the rejection/left-swipe
controls. Windows configure/build and all three CTest entries passed on
2026-10-28. A separate native Windows rendering run of this file passed all
22 records, including setup/cleanup; DirectWrite font fallback warnings occurred.
That run checks the swipe view, not the full application's menus or appearance.

Android has a separate repeatable test using Python 3's standard library and ADB.
Start QShopper_API_36 and build/install the x86_64 debug APK as in ANDROID.md, then:

```powershell
python tests/android/test_swipes.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/ui004-after
```

The script accepts only an emulator serial and also checks the emulator property.
It does not install APKs. It creates isolated databases/settings per case, enters
edit mode using the real pull gesture, and injects native horizontal touch swipes.
Eight cases separate direction, mode, 75% slow travel and 40% fast travel.
It verifies the saved item names, order and checked state, and saves screenshots,
SQLite snapshots and `results.json` under the output directory. It stops the app
afterward; disposable data stays available for diagnosis. Run against an English
emulator with the keyboard hidden and the screen unlocked.

On the Android 16 emulator, the original APK failed both rightward distance cases
and passed the other six cases. The rebuilt APK passed all eight. Screenshots
confirmed the remaining bread row and undo control after deleting milk. The
affected Android 17 Pixel was not connected during that initial run. Its 10 ms
velocity cases did not reproduce the reported effort problem; see the follow-up
below. The subsequent phone assessment accepted the tuning at 150%. System Back
cancellation belongs to UI-007 and is not established by pullback tests.

### Swipe resistance follow-up, 2026-10-29

The user confirmed the half-width fix on the phone but reported excessive swipe
resistance and little apparent benefit from the sensitivity control. The initial
10 ms velocity test was too fast to represent a comfortable gesture. The native
Android test now uses 40% row travel over 70 ms; all four velocity cases failed
with gravity 9810, while all four long-drag cases still passed.

`qml/tst_swipesensitivity.qml` uses a 76.6 mm-wide view and timed touch strokes
shorter than half the row. Four checking/deletion cases use 25 mm over 70 ms.
A real drag of the drawer slider verifies that the same 12 mm / 50 ms gesture is
rejected at 100% and accepted at 300%, and that the value is saved. Another test
verifies opening the controls preserves 240%. Two limit cases check that 20%
still requires a firmer swipe and 300% still rejects short, slow motion.

Before tuning, the four comfortable-stroke cases and the 300% gesture failed;
opening the controls preserved the value. Gravity is now 1000 mm/s² rather than
9810; sensitivity still multiplies the velocity-derived force. At 100%, this
lowers the required speed on a 76.6 mm row from about 867 to 277 mm/s. The
half-width threshold, pullback and settings range are unchanged.

The eight sensitivity cases pass offscreen and with native Windows rendering
(ten records including setup/cleanup). Normal Windows configure/build and CTest
cover the new file automatically. Reports are `tests/ui004-sensitivity-before.xml`
and `tests/ui004-sensitivity-windows.xml` under `out/windows-agent`. Android
before/after snapshots and results are under
`out/android-emulator/ui004-sensitivity-before` and `ui004-sensitivity-after`.
All eight Android cases passed after tuning, including the four comfortable
velocity gestures that failed before it.
The Android runner waits for the fixture to appear, avoiding splash-screen
timing failures under build load. The signed ARM64 APK was rebuilt, and the user
confirmed on 2026-10-29 that 150% sensitivity feels good on the phone.
UI-004 is resolved with the automated regression evidence and user feedback.
This report does not claim an exhaustive physical-phone interaction matrix;
system Back handling remains UI-007 and broader phone coverage remains QA-001.

Default calibration, 2026-10-29: the user requested that 100% match the accepted
150% feel. SwipeHandler now uses the literal gravity value **666.67 mm/s²**.
Sensitivity defaults and saved settings are unchanged; an existing 150% setting
should be returned to 100% for the same effort. The added
`test_default_matches_phone_tested_effort` gesture failed at gravity 1000.
It uses a wider row to give the timed threshold test room for event-loop jitter.
The actual slider comparison now uses 10 mm / 50 ms to remain below the lighter
default threshold and above the high-sensitivity threshold.
The literal-value Windows build and all three CTest entries passed (60 UI, 52
model and 5 keyboard records). The sensitivity file passed eleven records with
native Windows rendering, and all eight native Android swipe cases passed.
The timed calibration stroke allows for native event-delivery overhead while
remaining below the former threshold. Reports use `ui004-default-*` under
`out/windows-agent/tests` and `out/android-emulator/ui004-default-after`.
The shared-key ARM64 APK was rebuilt and its signature verified.

## UI-006 Android Back navigation

Android-only `Back` shortcuts in View.qml handle one layer per gesture: close
the modal drawer, hide the keyboard in edit mode, then leave edit mode. The view
shortcut is disabled while the drawer owns input and in shopping mode. Qt 6.12
then performs native task backgrounding. This uses `Back`, not the wider
StandardKey.Back mapping, and both shortcuts disable auto-repeat.

The user selected the existing mode-exit policy: hiding the keyboard keeps text;
leaving edit mode discards the draft and restores the original item if an edit
was unfinished. TextDelegate also clears its held-row state when its TapHandler
is disabled by mode exit. It does not reset indiscriminately on pointer
cancellation: an intentional reorder also transfers that grab.

`qml/tst_back.qml` sends real Qt.Key_Back events while replacing only the Android
platform gate for desktop tests. It checks drawer priority, focus-independent
mode exit, discarded drafts, pending-edit restoration, shopping-mode fallthrough,
Back during a held row, and a deliberate-reordering control. The extra keyboard
case in `keyboard/tst_keyboard.qml` uses the real plugin and verifies that the
first Back hides only the keyboard and the second leaves edit mode.

Before the feature, all four initial Back cases and the new keyboard case failed.
The held-row test then reproduced a stuck drag after mode exit; it passes with
disabled-handler cleanup. Final normal Windows CTest passes 68 UI records,
6 keyboard records and 52 model records. Native Windows rendering passes all
8 records in the Back file. Reports under `out/windows-agent/tests` include
`ui006-before.xml`, `ui006-keyboard-before.xml`, `ui006-drag-before.xml`,
`ui006-after.xml`, `ui006-windows.xml` and the normal suite reports.

Native Android coverage uses the English Android 16 QShopper_API_36 emulator,
Gboard, gesture navigation and a fresh QSHOPPER_DATA_DIR:

```powershell
python tests/android/test_back.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/ui006-after
```

The baseline APK hid Gboard but failed the next step by backgrounding from edit
mode. All seven UI-006 checks pass on the final APK. The flow checks
drawer/keyboard/mode priority, native backgrounding,
the same PID after return, and unchanged saved names/order/checked state. These
are actual screen-edge gestures, not emitted QML signals or KEYCODE_BACK.
See ANDROID.md for prerequisites and the Qt 6.12 backgrounding dependency.

## UI-007 cancelled touches and Back recovery

`qml/tst_cancel.qml` delivers a real `QTouchEvent::TouchCancel` through the test
setup helper, before any synthetic release can mask the failure. Seven cases
cover cancellation before/after long press, during reorder, and during left/right
swipes in edit/shopping modes. They check restored parenting and position, no
late long press or swipe action, an unpressed recognizer, and working subsequent
long press and swipe. These run in the normal CTest UI suite.

Before the fix, the early cancellation left Qt's tap recognizer pressed and its
timer later activated drag with an invalid point. Cancelled swipes could also
commit an action. Guards alone avoided the orphan but failed immediate native
reordering; the pressed-state assertion detects that incomplete fix.

All nine records in this file pass offscreen and with native Windows rendering.
Normal verification passes 77 UI, 6 keyboard and 52 model records across all
three CTest entries. Reports include `ui007-before.xml`,
`ui007-recognizer-before.xml`, `ui007-after.xml`, `ui007-windows.xml` and the normal
suite reports under `out/windows-agent/tests`.

Native Android tests use a test-only Java injector with one continuous pointer
and downTime. The first post-cancellation interaction is a real long-press
reorder/restore; a checking swipe and its correction follow. This avoids counting
an apparently restored row as recovered while its next interaction is broken.
Use the English API 36 emulator with Gboard and gesture navigation:

```powershell
./tools/build-android-gesture-test.ps1
python tests/android/test_back.py --adb C:/android/sdk/platform-tools/adb.exe --matrix --gesture-jar out/android-emulator/back-gesture/gesture.jar --output out/android-emulator/ui007-matrix-after
```

The matrix checks both edges, keyboard states, completion/cancellation and early
holds, with a one-second hold after system takeover. See ANDROID.md for SDK/JDK
requirements and the Back recognition timing constraint. Before evidence is in
`out/android-emulator/ui007-continuous-before`; the incomplete-guard recovery
failure is in `ui007-control-after`. Final results are in `ui007-matrix-after`.
All 69 matrix checks passed on 2026-10-29. The user also confirmed that the fix
works on the affected Android 17 phone. A follow-up explicit `TapHandler` cast
for `Loader.item` removes the analyser's `enabled` missing-property warning;
`qmllint -I out/windows-agent TextDelegate.qml` is clean. Before/after lint output
is saved in `ui007-lint-before.txt` and `ui007-lint-after.txt` in the Windows test
directory.
After the cast and brace changes, the Windows build and all three CTest entries
passed again; see `ui007-followup-verify.txt`. The signed ARM64 APK was rebuilt
and its shared-key signature verified.

## UI-010 selector endpoint reachability

`qml/tst_popupsafearea.qml` uses the production main window and drawer with 30
saved lists. Qt's public `SafeArea.additionalMargins` simulates asymmetric bars
and cutouts on the window content item. All six data cases (first/last option in
Lists, Accent and Primary) fail on the original popup layout. After the margin
fix, all eight records pass offscreen and with native Windows rendering.

The test resizes the window and changes safe margins while the popup is open,
asserts the viewport and full endpoint row are within usable bounds, preserves
row height, and clicks the endpoint to verify activation and the actual selected
list/color. It fails on binding-loop warnings and runs in the normal UI suite,
alongside the earlier repeated scroll/resize/zoom popup test.

Native Android coverage uses `android/test_popups.py`; see ANDROID.md for the
repeatable command. It scrolls and taps real controls, checking Android's actual
insets, persisted selections and unchanged shopping items. Original UI-010
coverage included true landscape before UI-011 restricted the phone app to
portrait. The current `rotated` profile requests landscape while asserting that
the app stays portrait; `portrait` and `keyboard_resize` profiles remain available.
The original first and last color rows
each fail the safe-area assertion. Reports are `ui010-before.xml`,
`ui010-after.xml`, `ui010-windows.xml` under `out/windows-agent/tests` and
`ui010-regression-before`, `ui010-last-before`, `ui010-after` (portrait),
`ui010-after-keyboard` and `ui010-landscape-verified` under
`out/android-emulator`. `ui010-matrix-after` combines the passing profile results
and records their source paths. The user confirmed the fix on the affected
Android 17 phone on 2026-10-29.
All 54 native checks pass. Windows configure/build and all three CTest entries
also pass: 85 UI, 6 keyboard and 52 model records. The normal verification log is
`out/windows-agent/tests/ui010-verify.txt`. The shared-key ARM64 APK was rebuilt
and its signature verified.

## UI-011 portrait-only Android phones

`android/test_portrait.py` verifies actual orientation with auto-rotate enabled
and real emulated acceleration sensors. A Settings control first proves that
the display can rotate. The original APK then fails cold launch held landscape.
Checks cover portrait/landscape launch, both rotation directions in shopping
mode, editing with the native keyboard hidden/visible, an open drawer,
unsubmitted text, process continuity and saved item ordering/checked state.

Use the commands in ANDROID.md. The script reads geometry before and after
accessibility inspection and permits the activity launch transition to settle.
It restores sensor/rotation settings and uses isolated data on an emulator only.
Reports are under `out/android-emulator/ui011-before` and `ui011-after`.
The existing popup matrix now tests the portrait app with a rotated-device
request rather than expecting landscape. Its follow-up report is
`out/android-emulator/ui011-popups-after`.

The manifest request is tested on the sw411dp API 36 phone emulator. Android
large-screen/windowing overrides remain a platform limit, documented in
ANDROID.md. The user waived physical Android 17 phone testing for UI-011;
no physical-phone verification is claimed.

On 2026-10-29 all 11 native orientation/state checks and 18 updated popup checks
passed. Windows configure/build and all three CTest entries passed with 85 UI,
6 keyboard and 52 model records (`out/windows-agent/tests/ui011-verify.txt`).
The shared-key ARM64 APK was rebuilt and its signature verified.

## UI-009 Reset checks ordering

The corrected user requirement is chronological checking order: initial `1,2,3`,
check `3,1,2`, checked stack `2,1,3`, then Reset to unchecked `3,1,2`. For unchecked
`A,B` followed by checked `C,D`, Reset keeps the unchecked prefix and produces
`A,B,D,C`. This supersedes the earlier preserve-visible-order instruction.

`reset_restores_checking_order`, `reset_reverses_checked_group` (five editor
positions) and `reset_during_checked_item_edit` (first/middle/last checked item)
in `test_model.cpp` verify order, flags, identity, free editor position,
idempotence, list switching and reload. All nine data cases fail against the
previous local implementation after updating the expected order. Eleven targeted
records including setup/cleanup pass with the reversal fix.

`qml/tst_reset.qml` uses real touch swipes, double taps and the drawer's Reset
button. It checks the main example, mixed lists, editing each of the three
checked positions, retained text, repeated Reset and a fresh main window.
The three initial UI cases fail the corrected expectation before the fix; two
additional edit positions extend coverage. Seven records pass afterward.
The normal suite timeout is 150 seconds for the added gestures and transitions.

`android/test_reset.py` checks the original sequence, mixed list and pending edit
with native input and isolated data. It verifies the saved chronological order,
cleared flags and item identities through a cold restart. See ANDROID.md for its
command. Revised reports are `ui009-revised-model-before.xml`,
`ui009-revised-model-after.xml`, `ui009-revised-ui-before.xml`,
`ui009-revised-ui-after.xml`, `ui009-revised-windows.xml` under
`out/windows-agent/tests`, and `ui009-revised-before`, `ui009-revised-after` under
`out/android-emulator`. Reports without `revised` record the superseded policy.

Final verification on 2026-10-30 passes all three normal Windows CTest entries:
92 UI, 6 keyboard and 61 model records. All seven targeted records also pass with
native Windows rendering, and all 13 revised Android checks pass. Both APKs were
rebuilt and the shared-key ARM64 signature verified. The normal verification log
is `out/windows-agent/tests/ui009-revised-verify.txt`.

The simplicity follow-up collects checked positions, clears their flags, reverses
the recorded pairs with normal row moves, and saves once. It uses no `continue`
or predicate-based search. Existing regression coverage is rerun against this
implementation; follow-up reports use the `ui009-simple-*` prefix.

The simplified implementation passes all three Windows CTest entries (92 UI,
6 keyboard, 61 model records), the targeted model/native Windows checks, and
13 native Android checks. The Android launch helper now waits for the foreground
app and expected rows before inspection. Exact/mixed checks and a pending-case
retry are combined with source paths in `out/android-emulator/ui009-simple-verified`.
Both APKs were rebuilt and the shared-key ARM64 signature verified.
The user confirmed the supplied test APK works and requested closure on 2026-10-30.

## Long-list background regression (UI-008)

`qml/tst_listbackground.qml` uses the production ShopView over a solid test
background. It compares rendered pixels inside rows and checks the filler against
the end of the complete model, inferred from a real delegate's position and the
fixed row height. It covers 34, 35 and 80 items at compact/tall viewport heights,
Light/Dark themes, down/up scrolling, actual touch flicks, viewport resizing,
empty/short lists, checking, editor movement and bulk removal. Fractional row
edges are excluded from pixel samples. It runs in the normal Windows verification
workflow; the UI timeout is 180 seconds to accommodate the added scenarios.

With the original geometry, five of nine focused QTest records failed with visible
opacity discontinuities. All ten final records (including a later mutation-control
scenario) pass offscreen and with real Windows rendering. The complete Windows
workflow passes 102 UI, 6 keyboard and 61 model records on 2026-10-31.

Run the focused real-window check with the Qt kit on PATH and
`QT_QUICK_BACKEND` unset:

```powershell
./out/windows-agent/qshopper_ui_tests.exe -input ./tests/qml/tst_listbackground.qml -import ./out/windows-agent -o out/windows-agent/tests/ui008-windows.xml,junitxml
```

The separate Android regression requires Python with Pillow and the fixed APK
installed on the isolated emulator. It uses disposable data, actual native swipes,
raw rendered frames and SQLite identity/order/check comparisons. To keep the
animated artwork from invalidating pixel comparisons, it observes a real slideshow
transition, waits for the new image to settle and captures the scroll pair before
the next transition. Screenshots are encoded after capture. A timing failure is a
harness gap, not evidence of a product defect.

```powershell
python tests/android/test_listbackground.py --adb C:/android/sdk/platform-tools/adb.exe --count 80 --output out/android-emulator/ui008-after-80
python tests/android/test_listbackground.py --adb C:/android/sdk/platform-tools/adb.exe --count 34 --output out/android-emulator/ui008-after-34
python tests/android/test_listbackground.py --adb C:/android/sdk/platform-tools/adb.exe --count 35 --output out/android-emulator/ui008-after-35
python tests/android/test_listbackground.py --adb C:/android/sdk/platform-tools/adb.exe --count 80 --keyboard --output out/android-emulator/ui008-after-keyboard
```

The native before-fix APK fails the synchronized pixel comparison: 78/816 sampled
pixels change (9.56%). The fixed 34-, 35- and 80-item runs pass both directions with no
changed sampled pixels. Together with the native-IME profile, all 15 native checks
pass. The native-IME profile passes all six checks, including
keyboard opening, scrolling, dismissal and unchanged saved data. It masks the
actual IME inset because accessibility can expose cached rows behind the keyboard.
If scrolling recycles the editor and already dismisses the keyboard, the harness
does not send an additional Back action.

Reports, UI XML and screenshots stay in the requested output folder. Never target
a physical device with this script. The emulator does not certify the affected
phone's appearance. The user confirmed the supplied fix on the affected phone and
requested closure and a commit on 2026-10-31.

## List selection regression (UI-001)

`qml/tst_listselection.qml` opens the real drawer through the editor menu button
and clicks selector popup rows. It covers fresh default display, distinct shopping
contents when switching, reopening the drawer, refresh after adding a list, the
special lists-management entry and persistence. `UiSetup::restoredActiveList()`
reads the setting through a fresh QQmlEngine; the QML test also recreates the main
window and checks its contents and selected label.

The original code fails two of six focused QTest records (initial default and
refresh). All six pass after the fix, both offscreen and with real Windows
rendering. The complete Windows configure/build/CTest run passes 108 UI, 6 keyboard
and 61 model records on 2026-10-31. Reports use the `ui001-*` prefix under
`out/windows-agent/tests`.

The model resolves the initial `default` alias to a UUID. ShopView now persists
that resolved UUID, and the drawer binds `currentValue` to the active setting
instead of maintaining duplicate index assignments. The writable ComboBox value
is supported by the project's Qt 6.10 minimum. Display names and UUIDs keep their
separate roles; the zero-UUID lists-management entry is preserved.

The native popup script now checks initial list selection and optionally verifies
the displayed selection after a real process force-stop/cold restart:

```powershell
python tests/android/test_popups.py --adb C:/android/sdk/platform-tools/adb.exe --selector lists --restart --output out/android-emulator/ui001-after
```

All ten checks pass for the default and lists-management endpoints, including
preserved shopping data. Windows covers switching to another shopping list with
distinct contents. Android reports and screenshots use isolated emulator data.
Both APKs were rebuilt and the shared-key ARM64 signature verified; no physical
phone installation or verification was performed by the agent.

The user accepted UI-001 and requested a commit on 2026-10-31, explicitly waiving
fresh-install phone verification to preserve existing phone data.

## Safe-area surface and theme regression (UI-005)

`qml/tst_safeborder.qml` compares the production window's rendered safe-area
strips with normal rows and the empty-area filler over a controlled solid
underlay. It uses real SafeArea propagation for all four edges, covers Light,
Dark and the host's resolved System theme, changes themes while open, checks
inverse checked surfaces and resizes the editing viewport. The original source
fails five of seven QTest records. All seven pass afterward offscreen and with
real Windows rendering. Reports are `out/windows-agent/tests/ui005-*.xml`.

The final normal Windows workflow passes 115 UI, 6 keyboard and 61 model records
on 2026-10-31. The UI CTest timeout is 210 seconds for the expanded rendering suite;
the passing UI run took 174.62 seconds. Existing earlier timeout/count notes above
record their historical runs.

The native regression requires Pillow, the fixed x86_64 APK on emulator-5580,
and disposable app data. It changes only the emulator's Android night setting
and restores it afterward. It checks actual rendered top/bottom surfaces, checked
contrast and status-icon readability using ranges that allow the deliberate 20%
wallpaper contribution. Native XML/system inset frames verify geometry; SQLite
snapshots verify preserved items and checks. A bounded loaded-row wait handles
first-launch/theme setup delays instead of treating an early frame as a bug.

```powershell
python tests/android/test_safeborder.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/ui005-final
```

`--profile` can isolate light, dark, system_light, system_dark, keyboard_light or
light_on_dark_system. The System-Light case changes Android to dark mode while
the app remains open. The Dark case backgrounds/resumes the live task. The
keyboard case verifies the visible app area; the IME owns its own navigation bar.
All 47 final native checks pass. The original APK fails six of the initial thirty
surface/contrast checks, and a separate Dark probe fails native status-icon
contrast. Reports and screenshots are in `ui005-before`,
`ui005-before-native-icons` and `ui005-final` under `out/android-emulator`.

Android appearance follows the resolved window backing color using the native
WindowInsetsController API on API 30+, with a flag-preserving Android 9/10 fallback.
The modern path was exercised on Android 16/API 36; the older path was compiled
in both architectures but lacks runtime verification. No physical-phone install
was performed by the agent. The user confirmed the supplied fix on the affected
phone and requested closure and a commit on 2026-10-31.

## Android System drawer colors (UI-014)

This failure is reported and reproduced on Android. Desktop passing results are
regression controls, not proof of reproducing or fixing this platform case.
The native theme harness adds an opt-in drawer comparison mode:

```powershell
python tests/android/test_safeborder.py --adb C:/android/sdk/platform-tools/adb.exe --drawer --output out/android-emulator/ui014-after
```

Use all profiles with `--drawer` so the test captures actual explicit Light and
Dark references before selecting System through the real drawer buttons. It
compares the rendered drawer padding and seven controls: list selector, action
buttons, primary/accent selectors and sensitivity slider. Matching control crops must
have equal dimensions and at most two RGB levels of pixel difference. The three theme
buttons intentionally have different checked positions and are excluded from
image comparison. Complete drawer images and native UI XML remain in each profile.

The System-Light case changes Android to Dark and back while the drawer stays
open. Every profile closes and reopens the drawer, waiting for the close transition
before using the editor menu button again. The other native surface, status-icon,
IME, resume and saved-data controls continue running. Data/settings are isolated
and the original Android night setting is restored.

Before the one-binding Menu.qml fix, 24 of 137 checks fail in live, initial and
reopened System/Dark: the drawer background is (209,209,209) instead of the
explicit Dark reference (20,20,20), altering the control composites. After the fix,
all 137 pass (90 drawer comparisons plus 47 UI-005 controls). Reports are in
`out/android-emulator/ui014-before` and `ui014-after`. Native screenshots were
also inspected. The normal Windows workflow passes 115 UI, 6 keyboard and 61
model records on 2026-10-31.

The source compares the drawer's effective `root.Material.theme` rather than the
raw preference, whose System value is neither explicit Light nor explicit Dark.
Existing explicit-theme shades and primary/accent values are preserved. Both
APKs were rebuilt and the shared-key ARM64 signature verified. The user confirmed
the fix on an Android emulator and requested closure and a commit on 2026-10-31.
This is emulator confirmation; no physical-phone verification is claimed.

## Shopping text line limit (UI-003)

`qml/tst_textfitting.qml` checks the production TextDelegate at 55/76.6/90 mm
widths and preview scales 1/2. It covers short, long, unbroken and oversized names,
checked styling, reuse and resizing (33 focused records including lifecycle).
The production change is just `maximumLineCount: 3`; keep `Text.Fit`, the 7 mm
reference font and Qt's existing ellipsis behavior. No extra scaler is used.

The normal Windows workflow includes these tests. Offscreen may have only a
dummy/icon font, so also run the actual-font assertions with native rendering:

```powershell
$env:PATH = 'C:/Qt/6.12.0/msvc2022_64/bin;' + $env:PATH
Remove-Item Env:QT_QUICK_BACKEND -ErrorAction SilentlyContinue
./out/windows-agent/qshopper_ui_tests.exe -input tests/qml/tst_textfitting.qml -import out/windows-agent -o out/ui003-nativeqt/after-windows.txt,txt
```

With the x86_64 APK installed on the isolated portrait emulator, run:

```powershell
python tests/android/test_textfitting.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/ui003-nativeqt
```

Requires Pillow. It counts actual screenshot text bands in Light/Dark, checks
large short text and smaller long text, and verifies stored names/flags remain
intact. Each profile uses unique data/settings; only emulator serials are allowed.
Screenshots, row crops, UI XML, SQLite and results remain in the output folder.
The script stops the app afterward and never installs an APK or touches a phone.

The original Windows preview can render four lines; this is the before/after
regression trigger for the three-line cap. The tested Android configuration
already limited extreme text to three lines geometrically, so its checks are
platform controls rather than a claim of Android reproduction. Earlier reports
for a strict two-line/custom-scaler approach are superseded by ui003-nativeqt.

Final Qt-native results: four of 33 native Windows records fail with the original
eight-line limit; all 33 pass with the three-line cap. The normal Windows workflow
passes 148 UI, 6 keyboard and 61 model records. All 20 Android controls pass.
Reports are in `out/ui003-nativeqt` and `out/android-emulator/ui003-nativeqt`.
The user confirmed the desktop appearance and accepted closure on 2026-10-31;
physical-phone verification is not claimed.

## UI-016 selector popup Back priority

The native edge touch used to close a selector on press before Android delivered
Back, so the same gesture also closed the drawer. `ComboBox.qml` now uses modal
popups with `CloseOnEscape | CloseOnReleaseOutsideParent`. Modal delivery supports
the release policy and prevents a dismissing tap from activating a control below.
Back-key routing remains unchanged; outside taps dismiss on release.

`tests/qml/tst_back.qml` tests Lists, Accent and Primary with real Back keys,
followed by drawer-only Back and draft cancellation. Six additional touch cases
check outside press/cancellation/release: all six fail with the original component
at the initial-press assertion; all 17 focused records pass with the fix.

Native regression commands (run serially against emulator-5580):

```powershell
python tests/android/test_back.py --adb C:/android/sdk/platform-tools/adb.exe --selector-back --edge left --output out/android-emulator/ui016-after-left
python tests/android/test_back.py --adb C:/android/sdk/platform-tools/adb.exe --selector-back --edge right --output out/android-emulator/ui016-after-right
```

All 13 checks per edge pass, including popup-only and following drawer-only Back,
unchanged drafts/settings/list data, keyboard/edit priority and background/return.
The original native APK fails all three popup cases; seven other controls pass.
Reports and build/verification commands are recorded in `tickets/UI-016.json`.
The shared-key ARM64 APK is `dist/QShopper-arm64-debug.apk`; no physical-device
installation or phone validation is claimed.

The final Windows configure/build/CTest workflow passes all four entries: 157 UI,
19 flow, 6 keyboard and 61 model records. The focused native Windows Back/touch
file also passes all 17 records. The user confirmed the fix on an Android emulator
on 2026-11-01 and requested closure and commit; UI-016 is resolved. This is
emulator confirmation, not physical-phone validation.
