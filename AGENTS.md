# QShopper agent workflow

QShopper uses C++17, Qt 6.10 or newer, and CMake.
The validated Windows development kit is Qt 6.12.0 MSVC 2022 x64.
Qt Creator and its MCP server are optional; all verification runs from PowerShell.

## Product design

Read [DESIGN.md](DESIGN.md) before changing UI, gestures, list ordering, sizing,
or text entry. It records the user's design intent for one-handed shopping:
deliberate horizontal swipes with pullback, nearby correction through first-in,
last-out checked-item ordering, 9.27 mm reference rows, large item text that
shrinks and wraps to two lines for long entries, a movable editor,
user-controlled shopping order, continuous keyboard/dictation entry, and an
animated visual style. Evaluate proposed changes against these principles and
make any tradeoffs explicit.

## Simplicity

KISS is a standing user preference for QML, C++, CMake, and development tooling.
Prefer clear, direct implementations. Add abstraction or generalization only when
it makes the actual code easier to understand and maintain. Fewer lines alone do
not make a design simpler; preserve necessary safety, error handling, and product
behavior. The full code review and coding-guide task is tracked as DEV-006.

Use braces for every `if` body in QML/JavaScript and C++, including single-line
bodies. Apply this to new or edited code; keep broad formatting in DEV-002/DEV-003.
Do not use `continue` in new or edited C++ code; prefer structured conditionals.

## Backlog

Use [BACKLOG.md](BACKLOG.md) to collect bugs and missing features, with linked reports in `tickets/`.
The current phase is backlog gathering; do not implement fixes until the user asks
to start fixing. Newly reported feature and code-quality requests also remain
backlog items unless the user explicitly asks for immediate implementation.
Distinguish user reports, observed bugs, source-review candidates,
and validation gaps. Record evidence, reproduction details, expected behavior, and
severity when known. Keep resolved history and avoid reopening old issues solely
because an earlier verification note predates a later successful check.

## Verification

Every bug fix must include an automated regression test that reproduces the
reported failure. Add or strengthen the test first, confirm it fails with the
original bug, then confirm it passes with the fix. Test observable behavior and
the real trigger, not just the replacement implementation.

Use the appropriate level: QTest for model behavior, Qt Quick Test for QML
interactions, and platform/rendering coverage for Android gestures, native IME,
safe areas, and visual defects that desktop/offscreen tests cannot establish.
Manual verification complements regression coverage; it does not replace it.
Use isolated data. Keep regression tests in the normal repeatable verification
workflow where possible and document any additional platform-specific command.

This applies to all existing and future bug tickets, including bugs found during
static analysis or cleanup. Record the test name/location and before/after
results in the ticket resolution. Do not close a bug without its regression test;
if reproduction or automation is blocked, keep the ticket open and record the gap.

Run `./tools/verify-windows.ps1` to configure, build the app and model tests, and run CTest.
Use `-Action Build` for configure/build or `-Action Test` to run already-built tests.
Override `-QtRoot`, `-CMakeBin`, and `-Ninja` for another local installation.
The script initializes the Visual Studio x64 environment when necessary.
Build products are in `out/windows-agent` relative to each checkout.
The preset requires CMake 3.25 or newer.

The suites test model behavior and seven ShopView interaction scenarios with in-memory SQLite.
Two additional QML scenarios verify Theme conversion using the real attached Screen density
and component sizing without a Dimensions reference. Four preview scenarios verify build/platform
gating, reactive geometry, limits, keyboard zoom, and preserved list data. Two persistence scenarios verify scale restoration in a fresh engine and window position restoration in a new window.
A popup regression opens all three drawer selectors while scrolling, resizing, and zooming; binding-loop warnings fail the test.
A list-background regression samples rendered row interiors while scrolling
34/35/80-item lists and checks empty/short lists, both themes, touch flicks,
viewport resizing, checks, editor movement and removal. Its native Android
companion compares actual frames between slideshow transitions with isolated data;
see tests/README.md for commands and the Pillow requirement.
The Qt Quick Test suite runs offscreen; it does not certify the full app's menu or visual appearance.
Coverage is optional and separate from the normal verification command.

## QML sizing

Use Theme.pixels(millimeter) for component geometry and Theme.millimeters(pixels)
for converting logical pixel distances back to millimeters. main.qml attaches the Theme
singleton Item to window.contentItem so its Screen attached properties follow the app window.
Theme uses Screen.pixelDensity without a devicePixelRatio adjustment. Android and release builds
always use preview scale 1 with no desktop density correction. Non-Android Debug builds allow
Theme.scale (0.25 to 4.0), restored from settings with a fresh-install default of 2. main.cpp enables Theme.scaleable directly on the existing singleton. Page Up/Down adjust
it by 0.1; Ctrl+0 resets it. The LG TV SSCR2 has a debug-only density correction of 1.5.
QML bindings calling Theme.pixels() update automatically; main.qml queues window resizing
with Qt.callLater() to avoid re-entering screen/DPI handling. Do not reload the view for zoom.
Do not divide or multiply this density by devicePixelRatio. Do not pass Dimensions through components.
LoaderWindow loads the view without creating or passing Dimensions.
Dimensions-based scale, orientation and geometry persistence are unused. QtCore.Settings
persists Theme.scale at key scale, and main.qml persists x/y under the Window category.
Window dimensions remain calculated from the 76.6 by 162.8 millimeter reference size
using Theme.pixels().
QShopper supplies LoaderWindow and DefaultAnimation in its own QML module.

## Desktop virtual keyboard

QSHOPPER_DESKTOP_KEYBOARD is a CMake cache string: AUTO (default), ON, or OFF.
AUTO enables Qt Virtual Keyboard in non-Android single-configuration Debug builds.
For multi-configuration generators choose ON or OFF explicitly. Android always uses
its system keyboard, regardless of this option. Enabled builds require the Qt Virtual
Keyboard module in the selected desktop kit. main.cpp selects the embedded input
plugin before QGuiApplication; no manual runtime environment setup is needed.

View reserves space below ShopView for DevelopmentKeyboard. InputPanel sizes itself
from the preview window width; do not apply Theme.scale to it again. Enter submits
without dismissing the keyboard. InputDelegate also sets EnterKey.type to
Qt.EnterKeyReturn for the native Android IME; InputPanel settings do not affect Android.
Its hide button and opening the drawer dismiss it;
tapping the editor reopens it. LoaderWindow and DefaultAnimation belong to QShopper.
The desktop-only InputPanel is a conditional resource from a .qml.in source so whole-tree
QML deployment scans do not pull it into disabled builds. CMake declares its imports
as module dependencies only when enabled.

The separate qshopper_keyboard_tests CTest entry runs with the real keyboard plugin
and isolated data. It checks virtual-key submission, composed text, hide/reopen,
preview resizing, and drawer dismissal. Ordinary UI tests also verify the build gate.

## Parallel development

Give each coding worker a separate Git worktree and a bounded task.
Use separate build directories per worktree; never reuse a CMake cache from another checkout.
Inspect local changes first: Git worktrees do not copy uncommitted changes, including submodule edits.
Agree on a committed baseline or explicitly transfer required changes before dispatching work.
Coordinate edits to shared CMake files and changes to public C++/QML interfaces.
Integrate worker results one at a time, then rerun verification on the combined tree.
Limit each worker's build jobs to avoid oversubscribing the machine.

## Android emulator

See ANDROID.md for QShopper_API_36 and the x86_64 emulator build. Use
./build-android.ps1 -Architecture x86_64, host GPU rendering, and a unique
QSHOPPER_DATA_DIR via Qt debug intent extras for automated launches. Target only
the isolated emulator serial (currently emulator-5580); do not install test APKs
on connected physical devices without user authorization.

## App testing

Set QSHOPPER_DATA_DIR to a unique temporary directory before automated app launches.
This redirects the app database and default QSettings storage; normal launches retain their usual data.
The QML harness uses an in-memory database and temporary settings without launching main.cpp.
Each parallel UI test must use separate data. Model tests already use in-memory storage.
Use Qt Quick Test for QML interactions and a real Windows rendering check for visual behavior.
Report exactly which checks ran and distinguish passing model tests from unverified UI behavior.
