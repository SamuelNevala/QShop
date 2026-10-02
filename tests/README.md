# Model QTest suite (MSVC)

The test executable compiles only `test_model.cpp` and links to the production
`QShopper` QML backing library. The application links to the same library, so
`model.cpp` and `undoremove.cpp` are compiled once.

The suite covers roles, insertion/reordering, check/reset, deletion/undo,
editors, read-only item mutations, list management, persistence, and rollback.
Edit regressions cover pending data preservation, cancellation, first/last rows,
editor positions, invalid calls, identity, checked state, and list switching.
Each test gets fresh in-memory SQLite storage.

Toggle regressions cover empty models, negative and out-of-range indexes,
extreme indexes, read-only calls, reordering, identity, and persistence.

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

Verified with MSVC 19.44 / Qt 6.12: **96.03% (411/428 lines)**.
