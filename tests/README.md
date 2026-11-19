# Testing QShopper

Python commands below assume Python 3 is on PATH; otherwise use its full
executable path. Python is optional for ordinary app builds.

## Windows

Install the desktop kit described in [BUILDING.md](../BUILDING.md). From the
checkout in PowerShell:

```powershell
./tools/verify-windows.ps1
```

This configures/builds the application and tests, initializes MSVC if needed,
and runs CTest. `-Action Build` builds only; `-Action Test` runs an existing build.
Override Qt/CMake/Ninja locations with the helper's named options.

List or select tests directly after building:

```powershell
& C:/Qt/Tools/CMake_64/bin/ctest.exe --test-dir out/windows-agent -N
& C:/Qt/Tools/CMake_64/bin/ctest.exe --test-dir out/windows-agent -R qshopper_about --output-on-failure
```

The main entries cover model/persistence behavior, user flows, swipe/cancellation,
preview sizing, keyboard, About/privacy, Undo, backgrounds and color contrast.
Windows rendering entries use native windows with D3D11 WARP. Offscreen/software
tests establish behavior, not actual typography/pixels; Android tests establish
native IME/gesture/system-bar behavior. Physical shopping/sizing remain separate.

Fixtures use in-memory SQLite and temporary settings. Any automated full-app
launch must set a unique `QSHOPPER_DATA_DIR`; ordinary launches use normal data.
Run native Android suites serially, and keep parallel desktop fixtures isolated.

## Android tests

Create a **dedicated** API-36 x86_64 phone emulator with host GPU, gesture
navigation and English QWERTY Gboard. Build/install the x86_64 Debug APK using
[ANDROID.md](../ANDROID.md). Do not use normal phone data for automation.

```powershell
$sdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
$adb = Join-Path $sdk 'platform-tools/adb.exe'
& $adb devices
$serial = 'emulator-5554' # replace with your dedicated emulator's serial
python tests/android/test_about.py --adb $adb --serial $serial --output out/test-about
```

All native test scripts expose `--help`. Most accept `--adb`, `--serial` and
`--output`; add the options in the table for a particular regression.

| Behavior | Script / extra options |
| --- | --- |
| Entry, insertion, replacement, checked rows | `test_entry.py` |
| Clear text without closing the IME; continue typing/Return | `test_entry.py --clear-only` |
| Catalog Undo with continuously open IME (open UI-037; currently fails) | `test_entry.py --catalog-ime-only` |
| Back layers and backgrounding | `test_back.py` |
| Back during selector popup | `test_back.py --selector-back` |
| Cancelled Back/long-press recovery | `test_back.py --matrix --gesture-jar out/android-emulator/back-gesture/gesture.jar` |
| Swipe thresholds and both modes | `test_swipes.py` |
| Reset order/pending edits/restart | `test_reset.py`; `--case cleanup` checks per-action Undo |
| Long-list editor and IME | `test_recovery_entry.py --case scroll --count 40`; repeat with 200; `--case keyboard` checks end-editor reveal |
| Floating Undo, expiry and resume | `test_undorecovery.py` |
| Undo during retiring Clear-list rows | `test_fastundo.py` |
| Selector endpoints/rotation | `test_popups.py --matrix`; `test_portrait.py` |
| List fill at 34/35/80 items | `test_listbackground.py` |
| Safe areas and system theme | `test_safeborder.py`; `--drawer` covers System drawer colors |
| App, Qt, Font Awesome and privacy readers | `test_about.py`; `--application` or `--privacy` selects the added documents |
| Text fitting and ellipsis | `test_textfitting.py` |
| Ink/fill and slider contrast | `test_filledcontrast.py`, `test_popupcontrast.py`, `test_customcolors.py` |
| Swipe strip/cart/bin contrast | `test_swipecontrast.py` |
| Arrow replay/centering | `test_arrowfeedback.py` |
| Launcher icon | `test_icon.py` |

Held gestures require the test-only injector; it is not packaged with the app:

```powershell
./tools/build-android-gesture-test.ps1
```

Screenshot-analysis tests require Pillow (`python -m pip install Pillow` in your
chosen test environment). Gboard entry tests never activate the microphone.
Dictation and display-matrix controls have specialized setup in
[QA-001](../reviews/QA-001.md) and [QA-002](../reviews/QA-002.md).

Native harnesses seed disposable data, save results/screenshots under the chosen
output directory, and restore the OS settings they change. Check their `--help`
and isolation requirements before running; an emulator serial alone is not proof
that its data is disposable. An animated Undo bar must be located from rendered
frames: idle-only UIAutomator dumps can wait until recovery expires.

### Genuine Release test

Use a freshly created disposable AVD; this test clears QShopper on that device.
Release ignores Debug data-directory intent extras and denies `run-as`.

```powershell
python tests/android/test_release.py --adb $adb --serial $serial --disposable-device --apk /path/to/signed-release-test.apk --output out/test-release
```

It covers real startup/entry, themes/selectors, notices/privacy, Undo and restart.
Use a compatible **test** signing identity. Never install a test APK on a physical
phone without its owner's authorization or uninstall to bypass a signature error.

## Package and source verification

```powershell
./build-android.ps1 -Architecture arm64 -Configuration MinSizeRel -VerifyPackage
python tests/test_source_delivery.py
python tools/export-privacy-policy.py --check
```

`-VerifyPackage` checks the actual payload, manifest/permissions, native closure,
16 KB alignment, QML scan roots, Maven/NDK notice hashes and unchanged source
inputs. AAB checks also require `-Bundletool`. Normal builds do not require Python.
The source-tool CTest entry is registered when CMake finds Python.

QTest reconstructs bundled App/Qt/font notices exactly. About suites verify actual
drawer controls, scrolling, Back/Close, safe geometry and draft/data retention;
native rendering checks logo antialiasing and text. [License inventory](../app/licenses/README.md)
and [source delivery](../SOURCE_DISTRIBUTION.md) describe regeneration/publication.

## Formatting and analysis

```powershell
./tools/format-qml.ps1
./tools/format-cpp.ps1
./tools/format-qml.ps1 -Check
./tools/format-cpp.ps1 -Check
./tools/analyze-cpp.ps1
```

Use repository configurations, Qt 6.12 qmlformat and clang-format 22.1.8. Helpers
format tracked sources; add new files first. QML imports are sorted, include
order is retained, and C++ formatting inserts braces. Inspect/repeat until stable.
Keep mechanical formatting separate from behavior changes. Analysis settings and
exceptions are in [STATIC_ANALYSIS.md](STATIC_ANALYSIS.md).

## Model line coverage

Enable `QSHOPPER_MODEL_COVERAGE=ON` with MSVC and Microsoft's code-coverage tool,
then build target `model_coverage`. The helper checks model.h/model.cpp at an
80% line threshold. Coverage measures exercised lines, not correctness or UI
completeness; retain meaningful assertions and actual SQL fault stages.

## Interpreting results

- New bug fixes need a test that fails with the original bug and passes with
  the fix. Use actual model/UI triggers, not a check for replacement source text.
- Wait for settled list transitions in ordinary flow tests; intentional fast
  input/retirement/cancellation gets its own focused test.
- Preserve exact identities/order/storage and notification checks. Do not relax
  an assertion, add a skip or suppress warnings solely to make a run pass.
- The Qt keyboard PopupList `contentWidth` diagnostic is upstream DEV-001; keep
  it visible and recheck on a Qt upgrade. Do not patch the installed SDK.
- Report which checks ran and which device/rendering gaps remain. Old successful
  checks and later owner acceptance are not invalidated by an earlier note.

[INTERACTIONS.md](INTERACTIONS.md) maps user behavior to coverage. Detailed
before/after reports, acceptance dates and historical commands remain in linked
[tickets](../tickets/) and Git history; the former long guide is available with
`git show 73ada02:tests/README.md`.
