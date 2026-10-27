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

Unresolved full-app findings:

- On fresh data, the Lists combo box has blank selected text although the
  default list is active. Theme.activeList starts as `default`, while
  the combo box matches UUID values.

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
drawer's list and color selector geometry. The blank fresh-install list selection
remains deferred as UI-001. Visual behavior has not been retested after dropping
Dimensions usage.

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
