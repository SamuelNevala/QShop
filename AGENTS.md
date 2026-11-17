# Agent workflow

Human build instructions are in [BUILDING.md](BUILDING.md); tests are in
[tests/README.md](tests/README.md). This file contains automation constraints.

## Project and change scope

- C++20, Qt 6.12+, CMake 3.25+. Validated desktop: Qt 6.12.0 MSVC 2022 x64.
- Production C++/QML/assets are in `app/`; root CMake owns project/tests and
  app/CMakeLists owns the app/module. Build outside app/ so Android scans cannot
  include tests or historical build copies. Keep QShopper URI/resource URLs and
  build/QShopper module output unchanged.
- Read [DESIGN.md](DESIGN.md) before changing UI, gestures, ordering, sizing or
  entry. Preserve deliberate pullback, 9.27 mm rows, large fitting text, movable
  editor/continuous IME, checked-stack order and animated visual character.
- KISS is a standing preference. [CODING_GUIDELINES.md](CODING_GUIDELINES.md) is
  authoritative; accepted formatter settings take precedence over blanket style
  adoption. Use braces for all edited if bodies; no new/edited C++ continue.
- Reports and feature requests enter [BACKLOG.md](BACKLOG.md)/tickets until the
  user selects implementation. Distinguish bugs, review candidates and validation
  gaps. Preserve resolved history and later successful acceptance.

## Review and formatting

- Review QML one file at a time, tracing definition, base/content, derivation,
  callers, dynamic loaders and tests. Reading a caller is not its independent
  review. Record justified no-change decisions. Preserve DEV-006 coverage.
- Trace implicit size versus parent allocation/position/Layout hints. Prefer
  Layouts over positioning-only Item/Row/Column wrappers. Custom button content
  honors inherited display modes and declares its intentional default.
- Bounded test-asset findings may be fixed directly during review; keep behavior
  changes separate. Do not invent regressions for unused-code deletion.
- Use format-qml.ps1 and format-cpp.ps1, then their -Check modes. New sources
  must be tracked. QML imports stay sorted; qualify overlapping types. Retain
  include/child order; inspect inserted braces. Keep formatting separate from
  behavior/analyzer refactors and require a stable second formatting pass.
- Analyze with analyze-cpp.ps1; -SkipBuild requires current generated headers.
  Use the committed broad profile and local named exceptions. Do not blindly
  apply exported fixes, patch the SDK or suppress QML warnings globally.

## Verification and isolation

- Every bug fix needs an automated test of the actual failure: fail before,
  pass after. Record name/location/results in its ticket. Manual acceptance adds
  evidence; it cannot replace the regression. Blocked reproduction stays open.
- Choose model QTest, production-control Qt Quick Test, native rendering or
  Android coverage appropriate to the trigger. Offscreen does not certify fonts,
  system bars, IME or native edge gestures. Report exactly what ran and any gap.
- verify-windows.ps1 configures/builds/runs CTest from PowerShell and initializes
  MSVC. -Action Build/Test selects a phase; Qt/CMake/Ninja parameters allow other
  installs. Each checkout has its own out/windows-agent build/cache.
- Full-app automated launches use unique QSHOPPER_DATA_DIR/settings. QML/model
  fixtures use memory/temporary data. Parallel tests need separate data.
- Use a dedicated, explicitly identified emulator only. Never install on a
  physical device without authorization. Genuine Release tests require fresh
  disposable userdata because Debug redirection/run-as do not apply.
- Hold gestures/animated Undo need rendered targets/receiver checks, not idle-only
  accessibility snapshots. Settled flows wait for readiness; test interruptions
  separately. Do not hide failures with XFAIL/skip or weaker assertions.
- English QWERTY Gboard is the native entry baseline. Ordinary entry tests never
  activate a microphone. Restore altered OS settings and stop owned fixtures.

## Platform contracts

- Theme.pixels/mm uses the attached window Screen.pixelDensity without a DPR
  adjustment. Theme is parented to window.contentItem. No Dimensions passing.
  Android/Release scale=1; desktop Debug scale 0.25–4, default 2, persists in
  QtCore.Settings. Page Up/Down adjusts 0.1; Ctrl+0 resets. Queue window resizing
  with Qt.callLater; no view reload. Preserve the existing debug density correction.
- Window size follows the 76.6 × 162.8 mm reference; x/y settings persist under
  Window. LoaderWindow and DefaultAnimation belong to QShopper.
- Resolved owning Material.theme controls effective colors; Theme.theme retains
  the user's Light/Dark/System choice for selection indicators.
- Drawer catalog alone uses QtQml.Models.SortFilterProxyModel, ValueFilter on
  checked=false and RoleSorter on name. Its model alias is valid for Qt 6.12;
  recheck this preview API on upgrades. Shopping order remains in Model.
- Android Back closes only the foremost selector/About/privacy layer, then
  drawer, IME, edit mode; shopping mode backgrounds. Selector dismissal waits
  for outside release so a cancelled edge press cannot prematurely close it.
- Desktop keyboard option AUTO/ON/OFF: AUTO enables single-config desktop Debug;
  multi-config requires explicit ON/OFF. Android always uses its native IME.
  Desktop InputPanel sizes once from window width, not Theme.scale twice. Return
  keeps entry open; drawer/hide closes it and tapping the editor reopens it.
- The desktop keyboard .qml.in resource/imports are conditional. Keep Qt's known
  PopupList contentWidth override warning visible (DEV-001).
- About uses cached exact UTF-8 paragraph lists, a virtualized non-selectable
  ListView and attached scrollbar. Do not replace it with a full-license TextArea.
  View owns safe geometry; Close is a centered accessible Font Awesome icon button;
  logos use VectorImage.CurveRenderer. Drawer entries use the existing model and
  About GroupBox. Preserve draft/data and drawer on close/Back.
- Keep App/Qt/Font Awesome notices and provenance complete. Qt notices follow the
  actual platform runtime/keyboard selection; ordinary builds need no network or
  Python regeneration. Changes to dependencies require refreshed inventory/checks.
- Deployment uses qt_import_plugins, not deleting SDK files. Preserve Android
  platform/IME, JPEG/built-in PNG, SQLite, Material/Basic and Fusion editor. QML
  tooling is explicit opt-in and absent from Release/MinSizeRel. Verify the actual
  APK/AAB with build-android.ps1 -VerifyPackage, not only source configuration.

## Parallel work and publishing

If coding workers are requested, give each a worktree and bounded task. Inspect
uncommitted changes first; agree a committed baseline or transfer edits explicitly.
Use separate build caches, cap build jobs, coordinate shared interfaces/CMake and
integrate one result at a time, then verify the combined tree.

Do not publish placeholders, keys, normal app data or workstation paths. Public
contact details belong only in the explicitly approved terms/contact locations.
Keep actual notices/licences unchanged during prose cleanup. Source artifacts
need the accepted revision, matching binary and verified public downloads;
local preparation is not publication. Follow [RELEASE.md](RELEASE.md).
