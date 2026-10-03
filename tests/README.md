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
The UI harness uses the production QShopper module and QDynamics plugin,
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
  default list is active. ThemeManager.activeList starts as `default`, while
  the combo box matches UUID values.
- Startup logs `ComboBox.qml:21: TypeError: Cannot call method 'mm' of null`.
  The label x binding uses dimensions before LoaderWindow supplies it.

The offscreen suite does not validate the complete drawer, list switching,
long-press reordering, touch input, DPI variants, or Android behavior.
