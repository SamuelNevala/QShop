# QShopper verification

Production sources are under `app/`; the QShopper URI and resource URLs are
unchanged. Build outputs remain under `out/` or the Android build directory.
Android package regression commands are in [ANDROID.md](../ANDROID.md#package-regression-dev-008).
`tests/test_android_package.py` checks real APK contents, ABI, native dependency
closure and scan isolation; use `build-android.ps1 -VerifyPackage` to include it
in a repeatable Android build. It accepts a Python interpreter via `-Python`.

## Swipe feedback contrast (UI-028)

The normal workflow includes `qshopper_swipecontrast_tests` (offscreen/software)
and `qshopper_swipecontrast_rendering_tests` (native Windows, D3D11 WARP).
`swipecontrast/tst_swipecontrast.qml` holds a real touch swipe beyond half width
on the production ShopView. It checks actual body/arrow contrast, changes the
theme and primary/accent while held, then releases and verifies check/delete
and Undo outcomes. Light/Dark, both modes/directions/check states and four
backgrounds produce 64 cases; native Windows adds two System cases. Including
setup/cleanup, the suites report 66 and 68 records. Only the fixture's arrow
animation is paused to compare identical body/arrow/background render frames.

The native Android companion requires Pillow, the installed x86_64 APK and the
existing `BackGesture` helper, rebuilt with its held-position signal. Run only on the isolated
emulator, without other emulator workflows:

```powershell
./tools/build-android-gesture-test.ps1 -SdkRoot C:/android/sdk
python tests/android/test_swipecontrast.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-swipecontrast
```

It uses disposable SQLite/settings and restores OS night mode afterward. Twenty
profiles cover Light/Dark/System, modes, directions and checked states. Each
checks the actual tinted strip, body contrast against adjacent pixels from the
same frame, visible arrow pixels, unchanged saved data after a cancelled held
swipe, and exact UUID/name/check outcomes after a separate committed swipe.
The capture waits for the helper's actual held-position signal and explicitly
releases its hold after both frames, avoiding shell/screenshot latency races. CartOut
deliberately animates its arrow out of the clip, so an earlier frame
checks that cue and a later frame samples the settled body. Separate background
frames cannot establish contrast reliably during slideshow movement. These are
ordinary RGB captures, not Android color-correction/simulator output or evidence
of recognition by users with color-vision differences.

## About and offline notices (UI-012)

REL-001 adds a second About button, **Privacy policy**, and two Light/Dark cases
to the same normal and native-rendering suites. `AboutLicenses::test_privacy_policy`
opens the actual drawer button, reads the bundled policy, drags the body without
selection or IME, resizes within safe margins, reaches the final line, and checks
Back/Close preserve the drawer and exact draft/list state. The original app fails
both cases because offline policy access is missing. The large license reader
remains a virtualized ListView; only the small privacy document uses Qt's built-in
TextDocument source and a TextArea attached to Flickable.

Native Android policy coverage uses the same isolated harness and restores radios:

```powershell
python tests/android/test_about.py --privacy --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-privacy
python tools/export-privacy-policy.py --check
```

Sixteen Android checks cover both palettes, offline text, touch body scrolling,
both Back edges, Close and retained draft/items. The original installed app fails
at the absent button. The default command below still runs the full license
coverage. `tests/test_android_package.py` also checks actual APK/AAB permissions:
only the generated internal signature permission normally; explicit development
QML debugging additionally permits Internet. The original APK fails for three
unnecessary permissions. See [the privacy audit](../reviews/REL-001-privacy.md).

The normal verification workflow includes `qshopper_about_tests`, using
`about/tst_about.qml` and the real application window. It opens the actual drawer
entry, reads the complete Qt/Font Awesome texts, scrolls both to the end, changes
safe margins/viewport size, and closes with Back or Close. Both themes preserve
the drawer, unfinished draft and exact item IDs/order/checks. The original app
fails at the missing drawer entry. The original license coverage has eleven records, including
opening under one second and tab-to-render under 500 ms. Native Windows measured
273–289 ms opening and 29–40 ms switching; the original reader took 3,338 ms.
Dragging text also failed on the previous selectable TextArea and passes with
the paragraph reader. QTest's `license_notices_preserve_resources` compares both
complete reconstructed strings with their actual bundled resource files.
The entry is a GroupBox titled "About" in the existing drawer model, containing
an information IconButton captioned "Licenses". The test rejects the earlier
ungrouped button and plain "About and licenses" footer.
The reader is a standalone ListView with an attached scrollbar; touch and mouse
drags scroll its body. Its sole header is Open-source licenses; the close icon
is centred in the footer. The normal qshopper_about_rendering_tests entry uses
native D3D11 WARP and compares actual CurveRenderer logo edge pixels with the
same SVGs through the un-antialiased geometry renderer. Body swipes, footer
geometry and all four inherited tab-button display modes are also covered.

Focused native Windows rendering (use disposable settings/data):

```powershell
$env:QSG_RHI_BACKEND = 'd3d11'
$env:QSG_RHI_PREFER_SOFTWARE_RENDERER = '1'
./out/windows-agent/qshopper_ui_tests.exe -input tests/about -import out/windows-agent -o out/about-native.txt,txt
```

The QML harness supplies isolated storage. Native Windows confirms actual text
layout/scrollbar geometry; offscreen alone does not establish Android safe areas
or edge Back. The emulator companion requires Pillow and the installed x86_64 APK:

```powershell
python tests/android/test_about.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-about
```

It uses unique disposable app data, disables Wi-Fi/mobile data during reading and
restores their original state in `finally`. Twenty-six checks cover both themes,
offline header and accessible final paragraphs, rendered scrollbar endpoints,
safe bounds, IME state, both native Back edges, Close and unchanged saved data.
It force-stops its app launch afterward. Do not run other emulator workflows in
parallel. Complete document integrity is tested by QTest; the native tree exposes
only instantiated paragraphs. Request a fresh frame with window.update() before
waitForRendering() when testing an already-settled virtualized list. Reports are
under `out/ui012/`. User confirmed the final feature works on the phone on
2026-11-05; UI-012 is resolved.

Notice inventory, upstream hashes and regeneration are in
[app/licenses/README.md](../app/licenses/README.md). Ordinary builds and readers
use bundled resources and require no Python/network.

## Model QTest suite (MSVC)

For optional clang-tidy and Clazy checks, commands, scope and finding dispositions,
see [STATIC_ANALYSIS.md](STATIC_ANALYSIS.md). Runtime verification remains separate.

The test executable compiles only `test_model.cpp` and links to the production
`QShopper` QML backing library. The application links to the same library, so
`model.cpp` and `undoremove.cpp` are compiled once.

The suite covers roles, insertion/reordering, check/reset, deletion/undo,
editors, read-only item mutations, list management, persistence, and rollback.
Edit regressions cover pending data preservation, cancellation, first/last rows,
editor positions, adjusted editor row tagging, invalid calls, identity, checked
state, and list switching.
Each test gets fresh in-memory SQLite storage.

DEV-006 strengthened `readonly_blocks_item_mutations_and_allows_reload` with
otherwise-valid forward/backward moves, unchanged row identities/storage and a
usable Undo command after writes are re-enabled. An isolated build with only the
move read-only guard removed passed all 93 earlier records; the stronger test
rejects that mutation, while the normal production model passes all 93 records.
The mutation lives only under ignored `out/dev006/test-review`; production code
was not changed for this test-quality improvement.

The safe-border live-theme test also checks that Light/Dark produce different
surface colors, System matches its resolved palette, and returning to Light
restores the original color. Popup stress waits for the drawer's actual opened
state. Native Windows verifies those two focused files; Android behavior retains
its separate platform coverage requirements.

UI-018's `week_model_has_no_child_rows` exercises the production WeekModel in
the same normal QTest suite. It checks seven root rows and zero child rows for
every valid day index, including rejected child-index creation. It failed on the
original ignored-parent implementation and passes with the parent validity guard.

UI-019's data-driven `week_model_date_refresh` exercises the production date-update
path called by WeekModel's timer. It supplies fixed dates without changing the
system clock and checks seven name/number roles and reset notifications. Same-day
numbers in a different month/year (including backward changes) failed with the
original comparison; full-date comparison passes. Unchanged dates, next-day,
month/year boundaries, leap day, multi-day resume and repeated refresh are controls.
These model checks do not simulate Android suspension or certify timer delivery.

UI-021's `cleanup_requires_complete_catalog` exercises production cleanup with
initial and mid-iteration SQLite catalog-read errors. Fault views establish the
error stage before Model creation; assertions check table presence, row names,
checked flags and UUIDs afterward. Healthy, empty-catalog and read-only controls
preserve the intended orphan-cleanup policy. All five data rows run in normal
model CTest coverage with isolated in-memory storage.

UI-022's `reload_applies_only_complete_reads` injects initial and mid-iteration
SQLite read failures into an already loaded list, restores the readable table,
then inserts normally. It checks persisted names, order, UUIDs and checked flags
so an empty/partial replacement cannot overwrite the original data. Healthy,
read-only and empty-list controls verify successful refresh behavior.
`failed_reload_preserves_edit_and_undo` verifies the editor position, pending
identity, notifications and the usable Undo command after recovery.
`failed_list_switch_preserves_source_and_target` verifies that a failed switch
retains the source list ID, leaves the target's data intact after a later edit,
and succeeds when retried. All 13 data cases run in normal model CTest coverage
with fresh in-memory storage. The ten fault cases failed before the correction;
all 15 focused records (including setup/cleanup) pass afterward.

Toggle regressions cover empty models, negative and out-of-range indexes,
extreme indexes, read-only calls, reordering, identity, and persistence.

The DEV-005 `editor_index_property_matches_accessor` regression compares the
actual Qt property meta-type with the C++ getter's return type, then reads the
property through editor creation, movement, row removal, editor removal and
reload. It fails on the original int/qsizetype mismatch. The getter now returns
int, preserving the existing QML property and -1 sentinel; internal storage still
uses qsizetype, with an explicit conversion like rowCount(). See
[STATIC_ANALYSIS.md](STATIC_ANALYSIS.md) for before/after results and remaining findings.

`pending_editor_restore_respects_readonly` characterizes cancellation when a
rowsInserted receiver makes the model read-only during pending-edit restoration.
Both removeEditor() and remove(editorIndex()) must preserve the placeholder and
original item identity until writes are re-enabled, then retain the saved rows.
It passes before and after the DEV-005 recursion simplification.

Read-only bulk removal regressions verify unchanged rows, editor position,
pending edits, undo history, and saved contents. Internal reloads still replace
read-only model contents from the database.

An unfinished edit retains the original saved row. Submitting at the editor
position preserves its UUID and checked state. Removing the editor restores the
original; successful reload or list switching cancels the edit. A second edit is rejected
until the current one is submitted or cancelled.

Use CMake 3.25+, the MSVC Qt kit, and an x64 Native Tools Command Prompt (or
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

UI-023 replaces the editor-owned countdown icon with `UndoBar.qml`, a separate
Qt Quick Controls `Popup` using `ProgressBar` for the receding whole-background
fill, using the opaque theme accent without an alpha tint. The ProgressBar
itself is the Popup background; UI-027 makes its neutral background fully opaque
and UI-025 retains readable normal text over a compatible accent fill.
Progress fill, message and icon remain solid, with no
default popup surface or elevation shadow behind them.
A whole-surface TapHandler performs Undo without taking editor focus. TextIcon
reuses the existing Font Awesome font through Popup.font.family. The view
positions it above the safe area/keyboard and reserves bottom
scrolling space. UX-005 replaces the original restore-all batch policy with one
Undo step per user deletion action, including one coherent step per bulk action.
Each deletion restarts the shared 15-second window. Undo also restarts it when
an earlier pending action becomes the next recovery step (UI-032).
Further taps restore earlier pending actions. Expiry discards all remaining steps.
Scrolling, checking, typing, submission and editor movement preserve recovery.
Opening the drawer or backgrounding pauses its clock.
Successful reload/list switching and process termination end recovery; failed
loads preserve it. Recovery is in memory, not a persistent deletion archive.

`qml/tst_undorecovery.qml` reproduces offscreen-editor deletion and activates the
actual floating action after scrolling and editor movement/submission. Model
regressions verify names, UUIDs, flags and order across separate actions, bulk
operations, new insertions,
pending edits, reorder/check operations and reloads. The existing flow expiry
case checks real 15-second delivery. Before the fix, all three new interaction
cases and five new model cases failed; the original APK also failed reachable
Undo after deleting with an offscreen editor. A further three-position whole-bar
click regression fails on the original icon-only hit area (message/middle) and
passes with the TapHandler.

`test_disabled_undo_bar_creation_is_warning_free` and
`test_idle_drawer_does_not_pause_animation` fail on the original unguarded
pause binding. They cover disabled creation, idle drawer opening, live pause,
stopping while paused and a later idle drawer opening. The suite fails on any
`setPaused() ... isn't running` warning. The production pause binding now guards
with `running`; `Application.font` and `Application.state` use Qt Quick's typed
singleton so qmllint/qmlls can resolve both properties.

Removal messages are full Qt translation units in `undoremove.cpp`:
`%1 removed` and plural-aware `%n items removed`, both in the `UndoBar` context.
`lupdate undoremove.cpp UndoBar.qml -ts out/undo-messages.ts` extracts them,
including the plural/numerus marker. Item names remain user data, not translated
message fragments.

General QML entries run offscreen/software. The separate Windows
`qshopper_undo_rendering_tests` runs `rendering/tst_undopopup.qml` in a native
window using D3D11 WARP. Its fourteen records compare actual fill pixels directly
with the compatible theme accent tone, compare uncovered pixels against the
opaque normal theme surface over known underlays without disabling production effects,
verify solid message and
Undo glyph pixels, and check fixed
action geometry, Light/Dark, two sizes/scales, restart, drawer pause/resume and
Undo without losing draft focus. It requires a Windows desktop session.

UI-024 adds Light-first/Dark-first foreground regressions against a production
TextItem. Both cases fail with the original inverted palette. They check live
theme changes, current System resolution and rendered message/icon pixels over
full and empty progress fill. Larger preview glyphs provide fully covered pixels
for color comparisons despite font antialiasing. This Windows check does not
certify Android appearance or independently force both OS color schemes.

```powershell
./tools/verify-windows.ps1 -Jobs 2
```

The Android companion uses the production APK, isolated disposable data and
actual right swipes, scrolling, Gboard entry and screenshot-located Undo taps.
Its 22 checks cover both themes, original row identities/order/flags, consecutive
deletions, native IME placement, submission, expiry and background/resume. It
requires Pillow and accepts only an emulator. `undo_bar.py` locates the rendered
bar: UiAutomator's idle wait can outlast a live animated ProgressBar. Accessibility
snapshots are used only while the countdown is absent. The older entry and bulk
removal scripts use the same pixel locator while Undo is active.

```powershell
python tests/android/test_undorecovery.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-undorecovery
```

DEV-011's Canvas2D arc is historical; UI-023 removes its source, renderer tests
and explicit module/link dependencies. Qt 6.12 remains the supported baseline.
Current APKs still contain Canvas2D/CanvasPainter libraries: source removal does
not establish payload removal. DEV-008 tracks deployment investigation; UI-012
and REL-001 must inventory the actual shipped libraries and their license terms.
ARM64 build/signature verification does not establish phone runtime behavior.

DEV-007's `qml/tst_catalogproxy.qml` exercises the actual drawer proxy and selector.
The same six characterization records run against the original C++ wrapper and
its QtQml.Models replacement. They verify unchecked-only catalog filtering,
case-sensitive lexical order (including digits and accented names) under C,
Finnish and Swedish default locales, stable duplicate-name UUIDs, the synthetic
catalog entry, and live check/uncheck/rename/delete/Undo with selection preserved.
The test-only locale bridge restores the previous process locale after each case.
Existing selector persistence and catalog user-flow tests remain in normal CTest.
Qt's model property keeps the Qt 6.10/6.11 API while using its retained alias in
the validated Qt 6.12 kits; this preview API must be rechecked on Qt upgrades.
DEV-001 diagnoses the pre-existing PopupList member-override warning as upstream
Qt, separate from the proxy migration; binding-loop warnings still fail the
characterization. Its optional Qt-only reproduction is documented in
[reviews/DEV-001.md](../reviews/DEV-001.md).

For the current control-to-test map, new user-flow suite, platform gaps and
native commands, see [INTERACTIONS.md](INTERACTIONS.md). Historical counts below
describe earlier verification stages. QA-003 adds a separate flow CTest entry
  with explicit input-readiness checks. UI-015 now has separate fast-input coverage
  during row retirement; no current failure is reproduced. Normal flow assertions
  have no expected-failure or skip markers.
Remaining native/dictation gaps are recorded explicitly. UI-016 subsequently
fixes the selector Back regression: all 26 native left/right checks pass. The
selector waits for outside release, so Android cancelling the initial edge
touch cannot dismiss it before Back arrives. See the UI-016 section below.

Run `./tools/verify-windows.ps1` from the project root to build the app and both
suites, then run CTest. Qt Quick Test must be installed in the Qt kit.
The UI harness uses the production QShopper module,
in-memory SQLite and temporary settings. Its report is written to
`out/windows-agent/tests/ui-tests.xml`.

UI-020's `tests/qml/tst_modelproperties.qml` binds a real QML property to the
production Model's `canUndo`, then toggles `readOnly` in both directions.
Pending-Undo cases failed on the stale binding before the fix; empty-stack
controls passed. All four data rows now pass, including no-op setters, effective
notification counts, round trips and later use of the preserved command. The
file runs in the normal UI CTest entry.

Seven scenarios cover empty-list edit mode, keyboard item submission, empty
submission, leaving/re-entering edit mode, a pointer swipe to check an item and
resetting it, bulk removal/undo through view actions, and a pointer click on the
editor menu button. Tests wait for delegate animations before pointer input.
Bulk removal/undo calls the view action and model Undo; it does not click
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

## IconButton layout and display modes

`qml/tst_iconbutton.qml` checks the production IconButton's six drawer labels at
preview scales 1/2, glyph/caption/circle geometry and resizing. It also checks all
four inherited AbstractButton display modes, live changes, mouse click delivery
and disabled-click rejection. Captions have a shared two-line limit, grow with
their text, and shrink again when it becomes shorter; callers need no line-count
override. Binding-loop warnings fail the tests. Text font and
line assertions run where real text fonts are available; offscreen fallback fonts
alone do not certify captions. Run the same file natively with the Qt kit on PATH:

```powershell
./out/windows-agent/qshopper_ui_tests.exe -input tests/qml/tst_iconbutton.qml -import out/windows-agent -platform windows
```

It is automatically part of the normal QML CTest suite. DEV-010 records its
failing-before/passing-after display-mode results and Android drawer checks.

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

The harness does not certify every full-app drawer/list/reordering interaction,
actual monitor/DPI switching, or Android behavior; use the linked native checks
and interaction inventory for the current coverage.

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
UI suite. Native Windows rendering checks complement the offscreen CTest run;
DEV-011 adds its focused native rendering entry to normal Windows verification.

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

## Foreground contrast on colored fills (UI-025)

`contrast/tst_filledcontrast.qml` exercises production Weekdays, IconButton and
UndoBar over actual artwork. All 19 primary/accent families are checked in Light
and Dark, including all four inherited button display modes, fully rendered
foreground glyphs, fixed normal-theme Undo text, and opaque fills. Nine samples
across the Undo message area cover full/half/empty progress over all ten artworks.
The suite has 136 records. Independent sRGB luminance/alpha calculations check
actual rendered backgrounds; it does not call the replacement contrast helper
to determine success.

The offscreen `qshopper_contrast_tests` and native Windows
`qshopper_contrast_rendering_tests` CTest entries run normally. On Windows the
offscreen entry explicitly loads `%WINDIR%/Fonts` because glyph-core assertions
require real text fonts. Native rendering remains the typography check. Evidence
and the initial before/after failures are recorded in `tickets/UI-025.json`.

For actual Android controls, with the new x86_64 APK installed only on the test
emulator:

```powershell
./tools/build-android-gesture-test.ps1 -SdkRoot C:/android/sdk
python tests/android/test_filledcontrast.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/ui025/android-after
```

Requires Pillow. Six disposable profiles cover Light/Dark, both actual Android
System schemes, Yellow/Lime and a dark-purple accent. The harness holds a real
vertical pull to expose the day header, opens the actual drawer, deletes through
a right swipe, samples native glyph/fill pixels and taps the whole Undo bar.
It checks contrast plus restored names/order/UUIDs/flags, then restores the
original Android night-mode setting. `--profile defaults-dark` is a focused
before/after reproduction. The gesture helper's optional final argument extends
its hold; existing calls retain the original one-second behavior.

`undo_bar.py` recognizes both old and UI-025 default Green tones for the existing
entry/recovery harnesses; contrast is asserted independently by the new harness.
The existing `test_undorecovery.py` was rerun in both themes to cover offscreen
editor recovery, IME, batches, expiry and background/resume after the visual fix.

## Selected popup text contrast (UI-026)

`popupcontrast/tst_popupcontrast.qml` uses the production Lists, Accent and Primary
selectors. Both explicit themes cover all 19 accent families; native Windows also
covers Green/Purple/Grey in both System schemes. Every case samples the actual
selected-row background with the caption hidden, checks independent composited
contrast of at least 4.5:1 and rendered caption pixels, and exercises keyboard
highlight movement, a changed current entry and a live accent change. The current
entry remains bold, preserves the caller's font size and retains vivid swatches.
Native Windows uses preview scale 2 so caption strokes have fully covered pixels;
the offscreen palette run retains scale 1. Antialiased edge colors are not used
as the nominal foreground when evaluating contrast.
There are 116 offscreen and 134 native Windows records, including setup/cleanup.
The dedicated `qshopper_popupcontrast_tests` and
`qshopper_popupcontrast_rendering_tests` entries run in normal verification.

```powershell
python tests/android/test_popupcontrast.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/ui026/android-after
```

Requires Pillow and an already installed test APK on the isolated emulator.
Six disposable profiles cover bright/dark/neutral accents, Light/Dark and actual
Android System Light/Dark. Actual screenshot caption pixels must meet 4.5:1;
popup-only Back and saved row identity/order/flags are checked. Original Android
night mode is restored. `--profile light-green` is the original reproduction.
About tab ink and other accent state/focus cues remain separate UX-003 candidates.

## Opaque Undo over checked rows (UI-027)

`rendering/tst_undopopup.qml::test_opaque_surface_over_checked_row` checks that the
empty/half-progress surface equals the normal unchecked theme background over
white, black and colored underlays, at both preview scales in Light/Dark. Normal
foreground roles remain, with native glyph-core checks at the larger scale on the
fully uncovered surface. Existing fill/timing/interaction tests remain active.

```powershell
python tests/android/test_filledcontrast.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --profile defaults-dark --checked-underlay --output out/ui026/undo-android-dark
python tests/android/test_filledcontrast.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --profile defaults-light --checked-underlay --output out/ui026/undo-android-light
```

This mode adds 24 checked rows to the fixture, waits eight seconds to uncover the
surface and samples actual Android pixels above the inverse rows, then verifies
Undo restores all identities/order/checks. It omits the unrelated pulled-day
header check; the normal six UI-025 profiles retain that coverage. Long-list
gesture targeting excludes zero-sized offscreen accessibility nodes, and setup
collapses the emulator notification shade before launching the disposable app.

## Original slideshow artwork (UI-013)

`backgrounds/tst_backgrounds.qml` loads all ten production resources, verifies
1080 × 1920 decoding, traverses the slideshow forward and backward, and checks
resizing plus portrait cropping with short/long/checked delegates in both themes.
The `qshopper_background_tests` and native Windows
`qshopper_background_rendering_tests` CTest entries run it normally. Each writes
twenty `ui013-*.png` frames under the build's `tests/` directory; native rendering
is the typography/visual check, while offscreen establishes resource behavior.

With the x86_64 APK installed only on the isolated emulator:

```powershell
python tests/android/test_backgrounds.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/ui013/android
```

Requires Pillow. The harness uses fresh data directories and explicit Light/Dark
settings. It matches native screenshot patterns against the JPEGs after portrait
cropping, independently of the uniform translucent row tint. It verifies all ten
images in order in both themes and exact saved list data, saving twenty frames
and correlations. Runtime is about 150 seconds for the real seven-second timer.
No physical phone or existing list data is used.

Source artwork, generation prompts, references and repeatable JPEG export hashes
are recorded in `artwork/UI-013/README.md`. The PNG originals are not packaged.

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
is supported by the project's Qt 6.12 minimum. Display names and UUIDs keep their
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

## QML formatting (DEV-002)

Use Qt 6.12.0 `qmlformat` with the root `.qmlformat.ini`:

```powershell
./tools/format-qml.ps1
./tools/format-qml.ps1 -Check
```

Override `-QtRoot` to select another compatible desktop kit. The default is
`C:/Qt/6.12.0/msvc2022_64`. The script uses Git's tracked source list: add new
QML files to Git first. It includes application QML, tests and `.qml.in`
templates, and excludes ignored build outputs and external Qt files. `-Check`
formats to memory, reports drift and fails without changing source files.

The settings use four spaces, a 100-column wrapping target, LF newlines,
semicolons, spacing between functions/objects, and compact empty objects.
Attribute categories follow Qt's order while keeping their relative order
within each category (`GroupAttributesTogether=true`, `NormalizeOrder=false`).
Child objects retain their order. `.gitattributes` keeps QML checkouts at LF even
when Git's Windows newline conversion is enabled.

`SortImports=true` is the user's explicit choice. Sorting overlapping imports
can change type selection. Existing generic controls are qualified through the
`Controls` alias in Icon, Menu, Pulley and Weekdays; InputDelegate explicitly uses
`Fusion.TextField`. These retain the original selections after sorting. Preserve
that qualification when editing imports. All existing unbraced `if` bodies were
wrapped mechanically; qmlformat itself does not enforce that project rule.

Qt 6.12 cannot parse the `.qml.in` suffix directly. The script formats temporary
`.qml` copies outside the checkout and copies the result back with the original
suffix and placeholders. Keeping the temporary files outside the checkout avoids
exposing optional Virtual Keyboard imports to whole-tree deployment scans.
The script also enables console-only Qt diagnostics for unattended execution,
then restores the process environment.

In Qt Creator, use **Preferences → Qt Quick → Code Style → Formatter Selection →
QMLFormat** (or the per-project **Projects → Code Style** override). Creator's
qmlformat integration discovers `.qmlformat.ini` in the source directory or its
parents. A custom formatter can select this kit's `bin/qmlformat.exe`. Use the
PowerShell script for `.qml.in` templates. These are documented setup steps;
Automatic configuration discovery was verified with qmlformat on root and nested
sources. Creator preferences were not changed or interactively verified.

References: [Qt QML coding conventions](https://doc.qt.io/qt-6/qml-codingconventions.html),
[qmlformat settings](https://doc.qt.io/qt-6/qtqml-tooling-qmlformat.html),
[Qt Quick best practices](https://doc.qt.io/qt-6/qtquick-bestpractices.html), and
[Qt Creator formatter setup](https://doc.qt.io/qtcreator/creator-preferences-qtquick-code-style.html).
The best-practices review remains separate from this mechanical formatting pass.

Verified on 2026-11-01 with qmlformat 6.12.0: all 54 sources pass `-Check` and a
repeated final in-place pass is byte-identical. Module sets, template placeholders
and the five deliberate control qualifications were audited. Windows configure,
build and all four CTest entries pass (157 UI, 19 flow, 6 keyboard, 61 model
records; zero failures/skips). All 19 flow records also pass with native Windows
rendering. Reports are under `out/dev002`. No Qt Creator UI preference change
or physical-device validation is claimed for this formatting pass.

## C++ formatting (DEV-003)

Use the root `.clang-format` with **clang-format 22.1.8**, bundled at
`C:/Qt/Tools/QtCreator/bin/clang/bin/clang-format.exe`:

```powershell
./tools/format-cpp.ps1
./tools/format-cpp.ps1 -Check
```

Override `-ClangFormat` with a compatible executable path when needed. The helper
formats Git-tracked `.cpp` and `.h` files, including tests; add new sources to Git
first. Generated files, build trees and external Qt sources are excluded. `-Check`
uses `--dry-run --Werror`; unknown options and incomplete formatting are failures.
Neither a compilation database nor a Qt Creator session is needed for formatting.
Use the validated formatter version for repeatable output; review configuration
compatibility and formatting differences when upgrading it.

The configuration follows Qt's WebKit-based style with four-space indentation,
eight-space continuations, a 100-column target, aligned wrapped arguments, and
pointer/reference symbols next to the variable. Function/class/struct opening
braces start a new line; control-flow braces stay attached. Namespaces are not
indented. Preprocessor indentation uses two spaces after `#` without reordering
directives. Qt declarations and statement/attribute macros are configured explicitly.

Project-specific choices: `InsertBraces=true` enforces braces for control bodies,
including single statements. Review these edits: clang-format does not have full
semantic information, and it deliberately skips some preprocessor/macro cases.
`SortIncludes.Enabled=false` and `IncludeBlocks=Preserve` retain include order.
Comments and string literals are not reflowed; qualifiers, parentheses and
semicolons are not rewritten. The 100-column target can therefore be exceeded by
an unbroken literal or comment. Git attributes preserve LF in C++ checkouts.

The initial pass covers 11 files. The one existing `continue` in
`UiSetup::cancelTouch()` was replaced with a guarded touch-device body to honor
the standing project rule; the same devices receive the same cancellation event.
All other code-token changes are added braces. This is not an application bug fix
or a broader model/ownership cleanup. Includes retain their original sequence.

Qt Creator uses Clang LibFormat. In **Projects → Code Style**, select **C++**,
clear **Use global settings**, and use the repository `.clang-format` rather than
custom editor settings. **Full Formatting** enables formatter-based Ctrl+I;
format-on-save is optional. No Creator preferences are changed by the helper.
Automatic `.clang-format` discovery is also available through the native tool's
`--style=file`; the helper supplies the root configuration explicitly. If using
**Beautifier → ClangFormat**, set **ClangFormat command** to the full executable
path above; the bare name requires that directory to be on PATH.

References: [Qt coding style](https://wiki.qt.io/Qt_Coding_Style),
[Qt's upstream formatter configuration](https://github.com/qt/qt5/blob/dev/_clang-format),
[Clang format options](https://clang.llvm.org/docs/ClangFormatStyleOptions.html),
[Qt Creator C++ style](https://doc.qt.io/qtcreator/creator-preferences-cpp-code-style.html),
and [project style setup](https://doc.qt.io/qtcreator/creator-code-style-settings.html).

Verified on 2026-11-01 with clang-format 22.1.8: all 11 sources pass `-Check`, and
repeated final in-place formatting is byte-identical. Ordered code tokens and
include lists match the original snapshot, allowing added braces and the one
equivalent touch-device guard. Windows configure/build/CTest passes all four
entries (157 UI, 19 flow, 6 keyboard and 61 model records, zero failures/skips;
285.97 seconds). All nine focused cancellation records also pass with native
Windows rendering, exercising the adjusted helper. Reports are in `out/dev003`.
No GUI settings were changed and no Android/physical-device run is claimed.

## Build configuration (DEV-004)

The root build requires **CMake 3.25+**, **C++20**, and **Qt 6.12+**. The normal
Windows workflow remains `./tools/verify-windows.ps1`; its preset and target names
are unchanged. Qt's standard project setup supplies AUTOMOC. App and test targets
still share the production QShopper library, so model code is compiled once per
build. The root/test CMake files keep direct target and test declarations, with
shared QML test environment and Windows DLL-path properties set once.

`QSHOPPER_DESKTOP_KEYBOARD` retains AUTO/ON/OFF. AUTO enables the desktop keyboard
for single-configuration Debug builds; choose ON or OFF explicitly for multi-
configuration builds. Android always disables the loader and its QML dependency,
even with ON requested. The conditional raw `.qml.in` resource/import setup and
Android manifest/icon staging are retained. The source/test lists, test commands,
timeouts, environment values, data isolation and optional coverage workflow remain.

Use a separate build directory for every additional configuration. From an x64
Visual Studio Developer PowerShell, a Release/AUTO build can be checked with:

```powershell
cmake -S . -B out/windows-release -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=C:/Qt/6.12.0/msvc2022_64 -DCMAKE_MAKE_PROGRAM=C:/Qt/Tools/Ninja/ninja.exe -DBUILD_TESTING=ON
cmake --build out/windows-release --parallel 2
ctest --test-dir out/windows-release -R '^qshopper_tests$' --output-on-failure
```

For Ninja Multi-Config, use `-G "Ninja Multi-Config"`, a fresh directory, and an
explicit `-DQSHOPPER_DESKTOP_KEYBOARD=ON` or `OFF`. Omit CMAKE_BUILD_TYPE; select
`--config Release` at build time and `-C Release` for CTest. Android build commands
remain documented in ANDROID.md. C++20 uses the stable MSVC mode rather than
CMake 3.30's C++23 mapping to c++latest; no C++23 features are required.

Validation on 2026-11-01 (CMake 3.30.5, Qt 6.12, MSVC 19.51, Android NDK r27c /
Clang 18.0.3):

| Configuration | Validation |
| --- | --- |
| Desktop Debug/AUTO | App/build and all four CTest entries pass: 157 UI, 19 flow, 6 keyboard, 61 model records |
| Fresh Release/AUTO | App and tests build; 61 model, 5 theme/build-gate and 6 preview records pass with keyboard disabled |
| Fresh Debug/OFF | Configure, generated loader/module dependencies and three-test registration checked; no build/run claimed |
| Ninja Multi-Config/ON, Release | App and tests build; 61 model, 5 theme/build-gate, 6 preview and 6 real-keyboard records pass |
| Ninja Multi-Config/OFF and AUTO | Fresh configurations, disabled loader/dependencies and three-test registration checked; no build/run claimed |
| Android x86_64 Debug with desktop keyboard ON | Fresh C++20 APK built with loader disabled, installed only on emulator-5580; all 13 native Back/IME/popup/data checks pass |
| Optional model coverage ON | Fresh configuration finds the collector/Python, generates model_coverage and retains PROFILE/DEBUG:FULL/INCREMENTAL:NO flags; no new collection run |

The original and new main CTest plans have identical commands, timeouts and
environment values; all three generated resource manifests retain identical
content after line-ending normalization.
Reports are in `out/dev004`. The primary development build was restored after the
configuration matrix. No physical-device installation or macOS build is claimed.

Package inspection found the same Virtual Keyboard native plugin/library bytes
in both the previous and new Android APKs. This does not establish a native-IME
regression; investigate required deployment payload separately under DEV-008.

## Custom primary/accent roles (UX-003, UI-029/UI-030)

`qshopper_customcolor_tests` and `qshopper_customcolor_rendering_tests` are normal
CTest entries for `customcolors/tst_customcolors.qml`. The latter uses native
Windows D3D11 WARP. Seven scenarios cover all 19 families in Light/Dark; native
Windows adds System Light/Dark. Persistent controls receive live palette changes.
Checks cover actual day/tab/icon ink against black/white photographic extremes,
a real editor press, the actual drawer surface propagated to a child, painted
selector focus borders and the actual thumb boundary with its vivid fill retained.
The suites contain 268 and 282 records including setup/cleanup.

For glyph/background comparisons, Layout-owned captions retain their allocation
with opacity zero; control-owned TextIcon content can be hidden without reflow.
Do not sample during TextIcon's opacity animation or let a hidden Layout caption
move a logo under its old position. Native RGB checks do not certify color-vision
recognition, outdoor use or the displayed Android correction output.

The emulator-only companion uses real held pulls/editor presses, the drawer
slider and both license tabs. It requires Pillow and the current BackGesture
helper's bidirectional capture handshake:

```powershell
./tools/build-android-gesture-test.ps1 -SdkRoot C:/android/sdk
python tests/android/test_customcolors.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-customcolors
```

## Per-action Undo after list reuse (UX-005)

`ModelTest::post_reset_cleanup_undoes_one_action` verifies the actual check/reset/
three-removal sequence, exact identities/checks/order and repeated Undo. Additional
model cases cover a new deletion after Undo, coherent bulk steps, older pending
actions, mutation/pending-editor preservation and persistence. The actual QML
swipe/whole-bar-tap scenario is
`UndoRecovery::test_post_reset_cleanup_undoes_one_swipe_at_a_time`; it also checks
that Undo keeps the countdown running without extending its deadline. The expiry
case discards every pending step, complementing the real 15-second flow test.

The emulator cleanup case is included in the reset script's default four cases:

```powershell
python tests/android/test_reset.py --adb C:/android/sdk/platform-tools/adb.exe --case cleanup --output out/android-cleanup
python tests/android/test_undorecovery.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-undorecovery
```

The first performs real check swipes, drawer Reset, three cleanup deletions,
individual Undo taps and a cold restart with exact saved UUID/order/flag checks.
The second covers offscreen-editor reachability, scrolling, two separate Undo
steps above Gboard after submitting a new entry, expiry and background/resume.
No microphone or physical-device installation is used. Physical one-handed store
use remains complementary acceptance evidence.

## Arrow replay and preview resizing (UI-017)

The normal workflow includes `qshopper_arrowfeedback_tests` (offscreen) and
`qshopper_arrowfeedback_rendering_tests` (native Windows, D3D11 WARP).
`arrowfeedback/tst_arrowfeedback.qml` drives the production TextDelegate with
touch input. It compares visible arrow trajectories on a first and rapid second
swipe, preserves the one-animation-per-excursion latch, and exposes feedback below
the animation threshold after changing preview scale. All three variants run in
both themes; pullbacks must deliver no check/delete action. Screenshots accompany
the position assertions. This fixture isolates feedback; ShopView/model action
outcomes remain covered by the existing swipe suites.

Build the gesture helper with `tools/build-android-gesture-test.ps1`, then run:

```powershell
python tests/android/test_arrowfeedback.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-arrowfeedback
```

This native companion uses disposable data and actual app rows. It compares white
arrow pixels between a settled control and a second swipe following a quick
pullback, then checks the saved names/checkmarks are unchanged. Six profiles cover
Light/Dark and incoming/outgoing cart/bin arrows. Android uses preview scale 1;
the Windows tests establish the live preview resize case. The original Android
build loses the outgoing arrow on the repeated swipe in both themes.

## Fast Clear/Undo during row retirement (UI-015)

`qshopper_fastundo_tests` and `qshopper_fastundo_rendering_tests` run
`fastundo/tst_fastundo.qml` offscreen and with native Windows D3D11 WARP.
The test opens the real app/drawer, clicks Clear list, then uses the first
enabled, rendered Undo bar without waiting for list settlement. It proves
outgoing delegates still exist in the remove transition at press time, captures
the bar's actual pixels and sends input through window coordinates. Signal spies
verify Undo receives one request and outgoing rows receive no press. Restoration
checks exact names, flags, order and UUIDs immediately and after row cleanup.
Light/Dark, 3/30 items, mouse/touch and fast/settled controls give 18 records per
entry, including setup/cleanup. The production code is unchanged.

Build `tools/build-android-gesture-test.ps1`, then run:

```powershell
python tests/android/test_fastundo.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-fastundo
```

The native companion uses disposable app data and the `clear-undo` helper mode.
It captures an on-device raw frame before pressing, then transfers/encodes it
afterward so PNG/ADB latency cannot turn a fast case into a settled one.
Press timestamps must stay below the production 500 ms removal sequence;
missed timing is a failed validation, never an application-bug finding or a pass.
The captured frame must contain Undo at the target. Eight records cover both
themes and list lengths with fast and settled controls, comparing exact saved
order/checks/UUIDs after recovery and cleanup. UUID comparison normalizes optional
braces, preserving identity checks. Windows supplies the direct retiring-delegate
and input-receiver assertions; Android supplies native input, actual frames,
measured timing and persistence. Current production builds pass without an app fix.

## Remaining physical validation and native display simulation

[QA-001](../reviews/QA-001.md) records the actual one-handed shopping, dictation
and affected-phone Back acceptance procedure.
[QA-002](../reviews/QA-002.md) separates native geometry tests from physical
row measurements, touch comfort and reading on distinct real displays.
Passing emulator tests does not fill their physical acceptance fields.

The entry driver additionally covers shopping single/double taps, short/full
mode pulls, Remove checked with no checks, and cold restoration of the System
choice. These use actual controls and saved records; the microphone is not used.

Build the test helper, then run the display matrix serially on its own emulator:

```powershell
./tools/build-android-gesture-test.ps1 -SdkRoot C:/android/sdk
python tests/android/test_displaymatrix.py --adb C:/android/sdk/platform-tools/adb.exe --serial emulator-5580 --output out/android-displaymatrix
```

`--profile baseline|compact|roomy` runs a bounded subset. Every profile reuses
the existing text-fitting and all-selector endpoint/cold-restart checks. The
runner verifies effective size/density and both-theme screenshot dimensions,
records display/window/IME/font-scale metadata and installed APK hash, and
attempts both override and rotation restorations even if a child test or cleanup
fails. Restoration errors are retained in results.json and fail the run; an
unavailable emulator/ADB transport requires recovery before a passing claim.

The controller's offline disconnect regression needs no emulator:

```powershell
python tests/android/test_displaymatrix_control.py
```

It simulates the actual transport-loss boundary and verifies that failed cleanup
is recorded, every setting restoration is attempted, and no success is claimed.

Native popup tests now require the helper jar (override `--gesture-jar` for
another build). Their navigation setup uses one continuous pull with requested
1200 ms motion and a 200 ms final hold before release, then waits for the editor.
This makes the intended armed gesture explicit; it does not retry a failed
gesture or alter app thresholds. Immediate-release/rejected-pull behavior is
covered separately. Original compact immediate-release setup failures are
retained in the QA-002 record rather than reported as a fixed app bug.

These drivers use unique shell-temporary UI dumps and remove their disposable
app data. Do not run another native script concurrently with the display runner.

For DEV-001's optional standalone Qt keyboard diagnostic, see
[the investigation](../reviews/DEV-001.md). Its exact original-source warning
remains visible and is rechecked when upgrading the SDK; no global warning
filter or patched Qt file is part of QShopper.

### Connected Windows monitor checks (optional)

Configure the Windows Debug preset with `-DQSHOPPER_CONNECTED_DISPLAY_TESTS=ON`
and the desktop keyboard enabled (the preset's AUTO default enables it).
Initialize the Visual Studio environment as described above, then run:

```powershell
cmake --preset windows-agent -DQSHOPPER_CONNECTED_DISPLAY_TESTS=ON
cmake --build --preset windows-agent --parallel 2
ctest --test-dir out/windows-agent -R '^qshopper_connected_display_tests$' --output-on-failure
```

This serial, native Windows test opens the actual app on every connected monitor
in both themes at preview scales 1 and 2. With two monitors it also moves the
same editing window between them, preserving its draft, list data and keyboard.
It checks current-screen density, native render-target DPR, text pixels/fitting
and settled reference geometry. Captures and XML are written to the CTest
working directory. Keep other interactive UI automation stopped. The default
is OFF because foreground windows and connected hardware are required; turn it
off again with `-DQSHOPPER_CONNECTED_DISPLAY_TESTS=OFF` for unattended suites.
See [QA-002](../reviews/QA-002.md) for the actual-monitor record and the remaining
physical measurement/comfort checks.

### Synthetic English Gboard dictation (explicit opt-in)

`android/test_dictation.py` exercises the real voice button and Return with two
synthetic WAV files. It never enables the host microphone. It requires the
configured English Gboard layout, voice typing enabled, guest RECORD_AUDIO
permission and completed first-use prompts (decline optional improvement/data
sharing). Ordinary entry tests remain microphone-free. Do not run another
Android driver concurrently.

Install optional dependencies into an ignored task directory; generate bindings
from the installed emulator's own protocol, rather than committing generated SDK
files or adding dependencies to the app:

```powershell
New-Item -ItemType Directory -Force out/android-audio | Out-Null
python -m pip install --target out/android-audio/deps grpcio==1.85.1 grpcio-tools==1.85.1 cryptography==50.0.2
$env:PYTHONPATH = (Resolve-Path out/android-audio/deps).Path
python -m grpc_tools.protoc -I C:/android/sdk/emulator/lib --python_out=out/android-audio --grpc_python_out=out/android-audio C:/android/sdk/emulator/lib/emulator_controller.proto
```

For this test, start only the isolated QShopper_API_36 AVD described in ANDROID.md
with additional `-grpc 8554 -grpc-use-jwt -grpc-allowlist <absolute-access.json>`
arguments. Never use bare `-grpc` without authentication. The task-local access
file contains:

```json
{"unprotected": [], "allowlist": [{"iss": "qshopper-local-test", "protected": [
  "/android.emulation.control.EmulatorController/getMicrophoneState",
  "/android.emulation.control.EmulatorController/injectAudio"
]}]}
```

Select the `pid_*.ini` under `$env:TEMP/avd/running` whose `avd.id` is
QShopper_API_36 and `port.serial` is 5580. The test validates those fields,
connects only to loopback, registers an ephemeral public JWK and removes it in
cleanup. Private signing keys/tokens stay in memory. It refuses host microphone
access, checks before/after injection, and has no API for enabling it. Use paced
real-time PCM; do not issue nested state RPCs from an audio stream iterator.

Example offline Windows fixture generation (file output only; no playback):

```powershell
$voice = New-Object -ComObject SAPI.SpVoice
$english = $null
foreach ($candidate in $voice.GetVoices()) {
    if ($candidate.GetDescription() -match 'Zira') { $english = $candidate }
}
if ($null -eq $english) { throw 'Install the English Zira desktop voice first.' }
$voice.Voice = $english
foreach ($fixture in @(
    @{ Name = 'milk.wav'; Speech = 'Two cartons of milk' },
    @{ Name = 'bread.wav'; Speech = 'Bread comma six rolls' }
)) {
    $stream = New-Object -ComObject SAPI.SpFileStream
    $stream.Format.Type = 38 # 48 kHz, 16-bit, mono
    $stream.Open((Join-Path $PWD ('out/android-audio/' + $fixture.Name)), 3)
    try {
        $voice.AudioOutputStream = $stream
        [void]$voice.Speak($fixture.Speech)
    } finally { $stream.Close() }
}
python tests/android/test_dictation.py --adb C:/android/sdk/platform-tools/adb.exe --grpc-discovery "$env:TEMP/avd/running/pid_<owned-emulator>.ini" --proto-python out/android-audio --wav out/android-audio/milk.wav --wav out/android-audio/bread.wav --expected "Two cartons of milk" --expected "Bread, 6 rolls" --output out/android-dictation
```

The report requires the expected transcript for each WAV and retains hashes and
raw recognized/committed/saved text. `cleanup.json` records errors while every
key/channel, app, data and staging cleanup is attempted independently. Direct
Return accepts only an exact match or the observed single terminal ASCII space;
the Space-then-Return control requires exact committed-string equality. Both
paths assert one new row, draft clearing, retained Gboard and exact cold-restart
records. Recognition/service failures fail the speech case; they are not by
themselves evidence of application text loss. Restore any guest permissions
changed for setup, and stop the task-owned authenticated emulator afterward.
See [the actual run](../reviews/QA-001.md), the
[AOSP authentication guide](https://android.googlesource.com/platform/external/qemu/+/686efa16baf59d776cadc3f975d12570fe44bbb9/android/android-grpc/docs/README.md)
and the installed `emulator_controller.proto` for audio semantics.

With the optional dependencies installed, the driver cleanup controls run
without an emulator or microphone: `python tests/android/test_dictation_control.py`.
They simulate channel acquisition/closure failures and a disconnected ADB,
requiring removal of the trusted public key and an independent attempt/report
for every cleanup action.

### Font Awesome update and glyph coverage (DEV-012)

QShopper bundles the unmodified Font Awesome Free Solid 7.3.1 desktop OTF as
`app/fa-solid-900.otf`; only that font is shipped. The About tab uses the matching
brand SVG with the existing blue fill. Version 7's web archive uses WOFF2; the
desktop OTF is suitable for Qt's FontLoader and requires no conversion/subsetting.
Source URLs, notice hashes and the font hash are in `app/licenses/manifest.json`.

`qshopper_iconfont_tests` is included in the normal Windows build/test preset.
Its 14 data rows load the bundled font with QRawFont, check the expected Free
Solid family/style, Unicode coverage, nonzero glyph indexes and actual outlines.
It also verifies that the old TTF resource is absent. This prevents a system-font
fallback from disguising an omitted icon. Existing button, About, color,
arrow-animation and Undo suites exercise the production callers.

The full UI entry now has a 300-second outer timeout: all 205 original records completed
in 219 seconds during this update, and the former 225-second limit expired in
the first concurrent build/test pass. The added editor-font regression brings the
final UI entry to 210 passing records. Per-assertion deadlines remain unchanged.
The license scrollbar test uses at most three continuous drags from the actual
thumb position, letting variable-height paragraphs update the estimated extent
over rendered frames. Its strict endpoint and safe-area/data assertions remain.

The software swipe-contrast entry checks actual body contrast, glyph presence,
outline configuration, palette stability and gesture/action outcomes. It does
not certify the rasterized OTF outline's 3:1 contrast. Native Windows and Android
retain the strict rendered contrast checks. The distinction uses
`GraphicsInfo.Software`, including a Windows process deliberately using that
adaptation; it is not an offscreen-platform skip. Qt's software adaptation does
draw outlines, through shifted native glyph runs, and differs from RHI rendering.
Matched row/font sizes and an identical paused arrow position reproduced the
19-pixel software difference while native Windows passed at both 18 and 19 pixels.
See [Qt's software glyph implementation](https://raw.githubusercontent.com/qt/qtdeclarative/v6.12.0/src/quick/scenegraph/adaptations/software/qsgsoftwareglyphnode.cpp).

Update evidence is in `out/fontawesome`, including the official release digest,
old/new glyph comparison, the initial and corrected harness reports, both APK
payload reports, and the native Android checks. See `tickets/DEV-012.json` for
the final verification record. Icon sizes and gesture behavior are preserved.
CartInIcon/CartOutIcon now inherit ArrowIcon's symmetric padding instead of offsets
tailored to the old cart. Their matching arrival/departure position is height *
0.1875, centering the whole arrow in the basket. The arrow-feedback suite compares
actual arrow and basket midpoints at that position for both directions, themes
and preview scales (16 alignment/endpoint cases), and retains the tip/floor check.
The Android driver checks both mirrored cart directions and rapid repeats in all
ten profiles, including a settled CartIn screenshot checked against the basket
floor and vertical center; `--profile light-in-left` provides a bounded reproduction.

`tests/qml/tst_inputfont.qml` drives the production editor with the real icon-font
parent. Font Awesome 7's desktop font contains ASCII glyphs and icon-name ligatures;
the text field explicitly uses the application's normal font. Three data rows
compare observable text shaping against a plain TextInput using the same render
type and normal font, then submit the exact
text through Return. All three fail before the fix and pass afterward. The normal
UI entry and native Windows `qshopper_inputfont_rendering_tests` both run this test.

### Recovery timing and end-editor visibility (UI-032/UI-033)

`qml/tst_undorecovery.qml::test_near_expiry_undo_restarts_previous_action` uses
the production View and floating action. After two actual deletion swipes it
waits until the recovery window is almost exhausted, restores the newest action,
checks a fresh window for the previous action, crosses the original deadline,
and restores the earlier item. Its clock is shortened to two seconds for this
test; the native test uses the actual 15-second duration. Existing expiry,
whole-bar, paused-drawer, bulk and identity/order controls remain in the suites.

`keyboard/tst_keyboard.qml::test_end_editor_remains_visible_when_keyboard_opens`
moves the production editor to the end of 80 items with the real desktop keyboard
closed, opens it by tapping the field and checks actual viewport containment,
Return submission at that insertion point and retained keyboard visibility.
It runs in the normal `qshopper_keyboard_tests` entry.

The companion uses actual Android touches, native Gboard/insets, screenshots,
saved IDs/order/checks and isolated data in both themes:

```powershell
python tests/android/test_recovery_entry.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-recovery-entry
```

Use `--case keyboard` or `--case undo`, and optionally `--theme light|dark`, for a
bounded reproduction. Keyboard setup scrolls to the end and moves/reveals the
editor before tapping it; it does not pre-scroll after the IME opens. Two open/
Return/hide cycles preserve all 80 original rows and append the exact new text.
Undo measurement uses real countdown pixels without accessibility polling while
the animated bar is active. The earlier action must receive over 85% of a fresh
window and remain recoverable after the original deadline. All task data/staging
paths are removed in `finally`. No microphone is activated.

### Drawer safe-area dimming (UI-034)

`qml/tst_safeborder.qml::test_drawer_dims_safe_areas` opens the production drawer
with four nonzero insets and a uniform backdrop. Rendered pixels in the exposed
top/bottom/right safe areas must exactly match the dimmed normal row in
Light/Dark/System. The left inset must receive the drawer's native panel/shadow
treatment (or scrim with software rendering).
Closing restores the existing normal/inverse surfaces. The window color used by
native system-bar contrast handling follows the resolved dimmed palette too.
This runs in the normal `qshopper_ui_tests` entry.

```powershell
python tests/android/test_safeborder.py --adb C:/android/sdk/platform-tools/adb.exe --drawer --dimming --output out/android-drawer-dimming
```

Native screenshots compare simultaneous safe-area and exposed-content pixels.
The slideshow contributes 20% of each base surface, so the tolerance is bounded
by that contribution after the measured scrim transmission, plus native rounding.
This avoids requiring identical wallpaper across separate Android screencaps;
the QML test retains exact equality with a controlled backdrop. The script checks
close/restore, clock visibility, explicit/System palette equivalence, live scheme
changes, resume, native IME and preserved list data. Only isolated emulator data
is used and removed afterward. Use `--profile light --dimming` for a bounded run.

### Release logging and versions (DEV-013)

`qshopper.app` covers startup/storage/license failures; `qshopper.model` covers
model diagnostics. Debug defaults to debug output. Release defaults to warnings
and above, preserving actionable failures. Qt/platform diagnostics are unaffected.
For troubleshooting, set `QT_LOGGING_RULES=qshopper.model.debug=true` or
`qshopper.*.debug=true`; `qshopper.*.debug=false` silences Debug diagnostics.

After configuring a separate Release build with the desktop keyboard OFF:

```powershell
python tests/test_release_logging.py --app out/windows-release-agent/application.exe --debug-app out/windows-agent/application.exe --qt-bin C:/Qt/6.12.0/msvc2022_64/bin --output out/release-logging
```

The real executable starts with disposable storage. Checks cover quiet Release
startup, opt-in diagnostics, independent categories, retained Debug defaults,
runtime version and a controlled storage failure with an actionable warning.
The regular Android package test also checks installed-package metadata against
the root CMake version name/code using the deployment kit's `aapt2`.

### Android launcher icon (UX-006)

See [the editable artwork and export commands](../artwork/UX-006/README.md).
The static `tests/test_launcher_icon.py` check covers the original artwork hash,
shared native paths, all six PNG density exports, round transparency and adaptive
safe-circle geometry. Native API 33+ verification uses the installed package's
actual `AdaptiveIconDrawable` and Android renderer:

```powershell
python tests/android/test_icon.py --serial emulator-5580 --output out/android-icon
```

It builds the small Java probe using JDK 21/SDK 36, checks the adaptive mask,
foreground, background, monochrome silhouette and installed version/code, and
saves a Settings icon screenshot. It never launches QShopper or accesses list
data. Native rasterization has slightly different edge coverage for black/white
paints; silhouette comparison allows less than 0.1% edge pixels. No physical
phone or other launcher's appearance is certified by this emulator check.

### Android Release payload and native smoke (REL-001)

[RELEASE.md](../RELEASE.md) documents the selected MinSizeRel/ThinLTO/R8 profile,
personal Play account, unsigned artifacts, signing ownership and remaining gates.
`build-android.ps1 -Configuration MinSizeRel -VerifyPackage` runs the static
Release contract. Add `-AppBundle -Bundletool <official-jar>` to verify an AAB.
Both ABIs must retain the exact inventory in `android/runtime-libraries.txt`,
resolve native dependencies, exclude debug/tooling payload and pass ELF 16 KB
checks. APKs also pass zipalign; bundles enable uncompressed, 16 KB-aligned
Play native splits. Actual 16 KB runtime coverage remains a separate gate.

The native harness requires **a fresh disposable emulator userdata disk**.
It accepts only an emulator serial and requires `--disposable-device`; it clears
QShopper data on that device. Genuine Release denies `run-as` and ignores Qt
debug environment injection, so `QSHOPPER_DATA_DIR` extras cannot isolate it.
Never run this against a normal emulator profile containing wanted list data.
Start the AVD with a new temporary `-data <directory>/userdata-qemu.img`, a
temporary `-cache`, and `-no-snapshot`; stop it and remove only that verified
temporary directory afterwards. See [ANDROID.md](../ANDROID.md) for the AVD.

Sign the unsigned emulator APK with the existing **test/debug certificate**
using SDK apksigner, verify the signature, and run:

```powershell
$env:ANDROID_USER_HOME = "$env:USERPROFILE/.android"
python tests/android/test_release.py --disposable-device --apk out/rel001/final-release-test-x86.apk --output out/rel001/release-native
python tests/android/test_release.py --disposable-device --apk out/rel001/final-release-test-x86.apk --upgrade-from out/rel001/upgrade-from-debug-v2.apk --output out/rel001/release-upgrade
```

The update source must be an older, same-certificate Debug build. The test seeds
an item and Light theme in normal storage, updates without clearing data, then
checks both. The initial disposable fixture may be uninstalled to allow seeding
the older version; the update under test uses `install -r`. The full harness
checks the non-debuggable manifest, native keyboard entry, theme/drawer controls,
selector Back, both offline notices, the bundled privacy policy and its Back
layer, delete/Undo and exact text after restart. The code-4 full standalone
Release run has 16 checks (two theme-dark observations are deliberate).
Its Undo check reads the actual rendered action while the countdown is active;
waiting for accessibility idle would let it expire.

Use bundletool `get-device-spec`, `build-apks --device-spec ...` and
`extract-apks` with that spec, signing only with the test key. Check each extracted
APK with `zipalign -c -P 16 4`, install the device-targeted split set with
`adb -s emulator-5580 install-multiple -r <all-splits>`, then run the harness
without `--apk`. A universal APK does not certify Play's device split packaging.

`tests/android/test_optional_plugins.py` records the one-by-one removal experiment:

```powershell
python tests/android/test_optional_plugins.py out/rel001/optimized-before-pruning.apk --debug-keystore ../debug.keystore --disposable-device --output out/rel001/optional-plugins
```

Its input is an optimized, unsigned x86_64 baseline **before optional-wrapper
exclusions** (53 libraries in Qt 6.12.0), not the final 40-library artifact. On a
Qt upgrade, build this baseline in a disposable checkout with only the Gradle
exclusion list disabled; preserve the production contract. The matrix confirms
baseline operation, deliberately removes a required Material plugin to prove
failure detection, then tests each declared-optional wrapper cumulatively and
the complete accepted combination. Native backing modules remain included.

Verified 2026-11-08: original Release payload fails the minimal inventory check;
all 13 optional-wrapper removals and the required-plugin negative control pass
their expected outcomes. Both ABI APK/AAB contracts pass. A same-key code 2 to
code 3 update preserves the exact item and theme; final standalone and
device-targeted bundle split builds pass native Release interactions. Evidence
is retained under `out/rel001`. Physical shopping, minimum/API 37 devices,
actual 16 KB runtime, production-key migration and Play testing remain open.

### Offscreen editor and native keyboard (UI-035)

`DevelopmentKeyboard::test_offscreen_editor_keeps_draft_focus_and_keyboard`
uses the production view and real desktop input plugin with 40 and 200 items.
It opens the keyboard, keeps a draft in the index-0 editor, scrolls to the end,
then returns and submits. The 200-row case also checks that ordinary offscreen
rows are released. Both cases fail the original 20-row-cache/unretained editor
with a keyboard dismissal. The test belongs to the normal keyboard CTest entry.

The Qt 5 view buffered 40 reference rows; the Qt 6 target is now the same,
selected by the user as a rough weekly family-shopping cache. This is a distance
on each side of the viewport, not a maximum list length. The editor is retained
independently as ListView.currentItem. Highlight following and automatic list
key navigation are disabled so the user can scroll away and keep editing focus.
The Qt 6 reuseItems default remains unchanged: pooling would require a separate
review of per-row gesture/animation state and measured performance benefit.

Native regression, with the Debug x86_64 APK installed on the isolated emulator:

```powershell
python tests/android/test_recovery_entry.py --adb C:/android/sdk/platform-tools/adb.exe --case scroll --count 40 --output out/ui035/android-40
python tests/android/test_recovery_entry.py --adb C:/android/sdk/platform-tools/adb.exe --case scroll --count 200 --output out/ui035/android-200
```

Both themes use disposable SQLite/settings and the real Gboard IME. The test
checks keyboard visibility after every actual upward swipe beyond the full
list extent, scrolls back, verifies the exact draft, submits with native Return,
compares original saved names/IDs/checks/order and confirms Back can still hide
the keyboard. Run serially with other Android UI tests. The existing
`--case keyboard` path separately checks the end-editor/IME-opening behavior
(UI-033). Evidence is under `out/ui035`; phone acceptance is separate.

Native UI-035 result, 2026-11-11: original APK closes Gboard at scroll step 3
with 40 items. The final 40-row-cache/editor-retention APK passes ten checks for
40 items and ten for 200, across both themes. The existing end-editor visibility
case adds eight passing native checks. Both actual APK payload contracts pass;
the agent did not install on the phone. The user subsequently confirmed the
fix works on the phone and requested closure/commit on 2026-11-11.

Final UI-035 Windows build: ui 214, flow 19, fastundo 18, keyboard 9, model 104 records pass in all five affected CTest entries. Report: `out/ui035/windows-tests-final.txt`.
