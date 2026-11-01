# C++ static analysis (DEV-005)

Static analysis is optional and separate from normal builds and CTest. The
Windows preset exports `compile_commands.json` for tooling; it does not invoke
analyzers during compilation. Do not apply exported fixes automatically.

## Tools and checks

Validated with Qt Creator's bundled LLVM **22.1.8** clang-tidy and **Clazy 1.16**
(6d570cd), both under `C:/Qt/Tools/QtCreator/bin/clang/bin`. No separate install or
Qt Creator preference change is needed. Override `-ClangTidy` and `-Clazy` to use
compatible executables; config verification detects unsupported tidy checks.

The current baseline is the user's **Samuel** configuration exported from Qt
Creator: **505 clang-tidy checks** in the root `.clang-tidy` and **all 100 Clazy
checks** in `tools/clazy-checks.txt`. The helper reads that Clazy selection; the
file is not a native Clazy configuration format. Check names are stored explicitly
so a tool upgrade does not silently enable new Clazy checks.

Samuel includes correctness, CERT, core-guideline, modernization, performance and
readability checks, all Clazy levels, and manual Qt/JNI checks. Broad selection
does not make every warning a bug or every proposed fix correct. The captured
baseline is intentionally not clean: see the Samuel triage below. No check was
removed or newly suppressed merely to make that baseline pass. Formatting remains
handled by `.clang-format`.

Only the Creator check selection is ported. Creator's compiler-warning setting
`-w` and its IDE flag-selection mode are not copied into the command-line build;
the actual CMake compilation commands remain authoritative. Exact config snapshots,
enabled-check lists and executable versions are written into each report directory.
Reassess selections and dispositions when upgrading tools.

The project-specific options exclude exactly QSignalSpy from
misc-const-correctness because signal callbacks mutate its records, and exclude
macro expansion from the cognitive-complexity metric. Other types and authored
control flow remain checked. The Samuel check names themselves remain unchanged;
see the follow-ups below for controls and results.

In Qt Creator, select **Preferences > Analyzer > Clang Tools > Prefer
.clang-tidy file, if present** to apply this repository's tidy options as well as
its checks. This is the documented
[file-configuration preference](https://doc.qt.io/qtcreator/creator-how-to-configure-clang-diagnostics.html).
The user's Creator preferences have not been changed by the CLI workflow.

References: [clang-tidy configuration](https://clang.llvm.org/extra/clang-tidy/),
[Clazy levels and standalone usage](https://github.com/KDE/clazy),
[qualified meta-object types](https://github.com/KDE/clazy/blob/master/docs/checks/README-fully-qualified-moc-types.md),
and [optional-access reasoning](https://clang.llvm.org/extra/clang-tidy/checks/bugprone/unchecked-optional-access.html).

## Running

From PowerShell in the checkout:

```powershell
./tools/analyze-cpp.ps1
```

This runs the existing Windows configure/build helper first, including Visual
Studio environment initialization, then scans all seven tracked `.cpp` files
(five application units and two test units) serially with both tools. It uses the
real C++20 compiler commands, defines, Qt includes and generated headers. It
does not rewrite the compilation database or substitute generic compiler flags.
Normal Windows verification remains `./tools/verify-windows.ps1`.

To reuse an already configured and built directory:

```powershell
./tools/analyze-cpp.ps1 -SkipBuild -ReportDirectory out/analysis-repeat
```

`-SkipBuild` requires up-to-date generated headers and an exported compilation
database. The helper rejects missing sources rather than reporting partial
coverage as success. A custom build must be configured/built separately, then
passed with `-BuildDirectory` and `-SkipBuild`. Match the selected compiler's
environment if it cannot discover its standard-library headers automatically.

For an Android build configured with `BUILD_TESTING=OFF`, add `-ApplicationOnly`
to scan all five application units without requiring desktop test sources:

```powershell
# Configure the desired Android kit/build as described in ANDROID.md, also
# passing -DCMAKE_EXPORT_COMPILE_COMMANDS=ON, and build its application target.
./tools/analyze-cpp.ps1 -SkipBuild -ApplicationOnly -BuildDirectory out/dev004/android-x86 -ReportDirectory out/analysis-android
```

The validated Android directory uses Qt 6.12 x86_64, NDK r27c/Clang 18.0.3 and
gnu++20. LLVM 22 analyzers successfully parse those actual cross-compilation
commands, including `main.cpp`'s JNI/system-bar branch. Desktop and Android
databases/results are kept separate. This is not ARM64 or physical-device
certification, and static analysis does not exercise Android runtime behavior.

Reports default to `out/analysis`. They contain build metadata/database hash,
versions/check lists, per-source logs and suggested-fix YAML, and `results.json`.
All files are ignored build artifacts; keep the committed triage below as durable
evidence. Any analyzer failure or displayed warning/error makes the helper fail,
including Clazy warnings that otherwise return exit code zero. Every source is
processed before reporting diagnostic failures. No fixes are applied.

## Scope and limits

Tracked application/test translation units are scanned; generated moc/QML-cache
units and external implementation sources are not scanned as primary files.
Both tools report the four project headers through their including sources.
The header filters list those current header basenames explicitly; update both
`.clang-tidy` and the helper when adding a project header. Qt/system headers are
still parsed for types, but their implementation diagnostics are outside scope.
Parser errors are failures, not a clean analysis result. Some Clazy property
checks require a moc translation unit and are not established by this scope.

Passing this profile does not prove absence of defects or replace runtime tests.
If a finding reveals a real bug, add a regression that fails before the fix and
passes afterward, as required by AGENTS.md. Keep the finding open if that cannot
be established. Do not label every analyzer recommendation a reproduced bug.

## Initial conservative-profile triage, 2026-11-01 (historical)

The Windows baseline produced **17 emitted diagnostics at 13 distinct locations**;
four extra emissions repeat the same header warning. Seven of fourteen analyzer
runs needed review. Reports are in `out/dev005/before`; the original selected
checks were retained for the final run.

| Finding | Assessment and disposition |
| --- | --- |
| `fully-qualified-moc-types`: `Model::moveEditor`'s `Force` argument; repeated in five units | Qualify the declaration as `Model::Force` for unambiguous meta-object metadata. The actual typed meta-object call already passes before the change on Qt 6.12, so no runtime bug is claimed. `move_editor_through_meta_object` characterizes forced editor movement, return to the saved list and compatibility with the existing interface. |
| `unchecked-optional-access`: two reads in `Model::editItem`, plus one in `restorePendingEdit` under Android's standard-library configuration | Conservative local dataflow warnings after member calls. `editItem` populates the optional from `takeAt`; `restorePendingEdit` checks it on entry. The intervening notifications, `moveEditor` and `save` preserve it in these operations. Retain three line-local, named `NOLINTNEXTLINE` comments with those reasons. No blanket suppression or change to edit behavior. Existing position/cancellation/persistence tests exercise this invariant; arbitrary reentrant model mutation from external signal handlers is not certified. |
| `narrowing-conversions`: two test helper calls | The fixture contains only A/B after removal. Explicitly cast its `indexOf` results to the helper's int row type; no large-list truncation defect is reproduced. |
| `no-module-include`: the test's QtTest umbrella header | Include QTest and QSignalSpy directly. Compile-time/dependency cleanup only. |
| `detaching-temporary`: `names(model).first()` in a test | Use `constFirst()` for read access. The temporary is owned locally; no incorrect test result or user-visible failure was reproduced. |
| `range-loop-detach`: four model-test loops and two UI-helper loops | Give read-only Qt containers const local names; reuse the expected order in the first Reset test. These are fresh results/lists, with no demonstrated shared-data detach or behavior defect. The touch-device and database-table snapshots retain their prior iteration order and lifetimes. |

The additional Android warning is recorded in
`out/dev005/android-model-intermediate.txt` before its local suppression. It adds
one distinct location to the Windows findings.

These are quality/compatibility improvements and three documented analyzer
exceptions. There is no confirmed application bug fix in this change, so the
meta-object characterization passes both before and after rather than being
presented as a failing-before bug regression. No existing UI ticket is reopened.

## Initial conservative-profile validation, 2026-11-01 (historical)

- Both tools pass all seven Windows units (14 runs) and all five Android units
  (10 runs), with no displayed diagnostics or parser failures. The profile enables
  169 tidy checks and 53 Clazy checks in the validated executables.
- The default helper path, including configure/build, passes. Missing-source
  checks reject incomplete scope; Android explicitly uses application-only mode.
- An isolated unchecked-optional control still fails with the named check and
  exit code 1, confirming the three local exceptions do not disable it globally.
- `./tools/verify-windows.ps1` passes all four CTest entries: 157 UI, 19 flow,
  6 keyboard and 62 model records, zero failures/skips, 273.23 seconds. This
  includes the meta-object characterization, which also passed before cleanup.
- All nine native Windows `tst_cancel.qml` records pass, exercising the touched
  touch-device helper. Formatter checks pass for all 11 C++ files.
- The Android x86_64 application shared library builds. No new APK installation,
  native Android runtime test, ARM64 build or physical-phone check is claimed.

The normal header filter intentionally omits external implementation warnings.
A separate audit with system headers enabled confirms vendor-library diagnostics
outside project sources; these are not project fixes or blanket suppressions in
QShopper. Full audit output is retained in `out/dev005/external-diagnostic-audit.txt`.

Reports are under `out/dev005`: `before`, `final`, `android-after`,
`android-results-intermediate.json`, `optional-control.txt`, `meta-before.txt`,
`verify-windows.txt` and `cancel-native-windows.txt`. Detailed limits and artifact
paths are also recorded in `tickets/DEV-005.json`. Run the normal suites and native
cancellation scenario after changes to the test helper; Android analysis uses its
own compilation database.

## Stricter-profile trial, 2026-11-01

The user questioned whether the initial selection should be stricter. The
installed binaries expose 604 tidy checks and 100 Clazy checks; the current
169/53 selection is a conservative starting point, and only Clazy matches its
upstream default level. No configuration or application code was changed by this
follow-up trial.

A read-only run over all seven Windows units enabled all `bugprone-*` plus
selected member-initialization, slicing, virtual-destructor, override, nullptr,
defaulted-function and redundant-expression checks. Together with the existing
profile this enables 257 tidy checks; all seven units pass.

Clazy's trial uses `level2` plus `assert-with-side-effects`,
`qproperty-type-mismatch`, `jni-signatures`, `qstring-varargs`,
`unexpected-flag-enumerator-value`, `unused-result-check` and
`used-qunused-variable` (75 checks total). Its additional findings are:

- One property/accessor type mismatch: `editorIndex` is declared as an int
  Q_PROPERTY but its accessor returns qsizetype (long long on this target).
  The same header finding is emitted in five units. This is a concrete type
  inconsistency to investigate, without a reproduced user-visible failure yet.
- 94 QString allocation recommendations, predominantly in test fixtures, plus
  two constructor-parent recommendations for the standalone test fixture classes.
  These need disposition separately from runtime correctness findings.

Recommendation: tighten the normal correctness profile using this evidence and
appropriate Qt manual checks, then rerun both platform configurations before
closing DEV-005. Keep test-fixture advice proportional to its actual benefit.
The stricter profile is a proposal, not an already-applied configuration. Logs,
expanded check lists and per-source exits are in `out/dev005/strict-trial`.

## Samuel baseline and initial triage, 2026-11-01

After locating the user's existing Creator profile, the user selected Samuel as
the baseline and anticipated false positives. The repository now retains that
exact check selection. Both tools completed every intended translation unit:

| Configuration | Units / analyzer runs | Emitted diagnostics | Distinct diagnostics within that configuration |
| --- | --- | --- | --- |
| Windows Debug, C++20 | 7 / 14 | 265 | 261 |
| Android x86_64 Debug, gnu++20 | 5 / 10 | 38 | 36 |

Across configurations there are 273 distinct file/line/column/message/check
records, grouped into 25 check combinations. These are diagnostics, not 273 bugs.
Twelve Windows runs and eight Android runs contain findings. There are no parser
errors; the helper correctly fails because the findings remain visible, including
Clazy warnings that return exit zero. Exported fixes are suggestions only.

Reports: `out/dev005/samuel-windows`, `out/dev005/samuel-android`,
`out/dev005/samuel-baseline-summary.json` and the deduplicated location list
`out/dev005/samuel-findings.json`. Both report directories include the exact
configuration snapshot. The following initial dispositions account for every
reported check group; individual hygiene/style suggestions are not all accepted
as required changes.

| Check or combined checks | Windows / Android emissions | Assessment and next action |
| --- | --- | --- |
| Clazy `qproperty-type-mismatch` | 5 / 3 | One concrete contract inconsistency, repeated by includes: editorIndex was an int Q_PROPERTY with a qsizetype getter. Addressed in the focused follow-up below; retain these baseline counts as history. |
| Clazy `qstring-allocations` | 94 / 2 | Valid allocation advice, predominantly test fixtures. Review the two production conversions first; do not rewrite the test suite solely to remove these warnings. |
| Clazy `reserve-candidates` | 2 / 1 | Optional performance advice for list accumulation. Check whether a meaningful bound/count is already available; do not add counting passes or abstractions just to reserve. |
| Clazy `qt-keywords` | 2 / 0 | Test fixtures use slots rather than Q_SLOTS. Valid consistency advice; Qt keywords currently work. |
| Clazy `ctor-missing-parent-argument` | 2 / 0 | Standalone test fixtures are default-constructed by the test runners. A parent-taking constructor adds no current ownership benefit; framework-specific exception candidate. |
| Clazy `qvariant-template-instantiation` | 2 / 0 | toModelIndex is clearer than value<QModelIndex> here. Small cleanup, no wrong result demonstrated. |
| `misc-const-correctness` | 37 / 0 | Mixed. QSignalSpy mutates its recorded list through signal callbacks even when the test only reads it; making those spies const is inappropriate. Ordinary copied fixture values can be reviewed separately. |
| `modernize-use-bool-literals` | 2 / 0 | Unsafe proposed fix: replacing bool(QSHOPPER_...MACRO) with true freezes this Debug configuration's expanded value. Retain configuration dependence; do not apply the fix. IgnoreMacros is already true, but this cast of an expanded object-like macro still triggers it. |
| `readability-convert-member-functions-to-static` | 15 / 0 | Mixed helpers and Qt test/Q_INVOKABLE entry points. Preserve framework discovery and callable interfaces; review ordinary helpers individually. Lack of explicit member access alone does not justify changing reflected APIs. |
| `readability-redundant-access-specifiers` | 1 / 0 | The second public label introduces a slots section. Treat it as Qt-aware syntax, not an ordinary duplicate label to delete blindly. |
| `misc-include-cleaner` | 40 / 7 | Mixed direct-include hygiene and Qt macro/provider-header attribution. Review missing public includes; retain supported public Qt headers rather than importing private implementation headers to silence suggestions. |
| `cppcoreguidelines-pro-bounds-avoid-unchecked-container-access` | 10 / 9 | Most accesses have explicit bounds guards or a pending-editor invariant. Review each site against those conditions; do not infer an out-of-bounds bug solely from operator[]. Existing invalid-index/edit-position tests remain relevant. |
| `cppcoreguidelines-pro-type-vararg`, `hicpp-vararg` | 0 / 3 | Calls to Qt's documented explicit-signature JNI vararg API. This is API/policy advice, not proof of a bad JNI signature; the manual JNI check reports no signature finding. |
| `hicpp-signed-bitwise` | 0 / 5 | Android system-bar flags use JNI jint as required by the API. Review representation/operations; avoid changing JNI argument types solely to satisfy a generic unsigned-bitmask rule. |
| `misc-no-recursion` | 2 / 2 | Real but bounded internal cycle: removing the pending editor restores its item and clears the pending state before the inner remove. This is a policy exception candidate, not evidence of infinite recursion. |
| `google-readability-casting`, `modernize-avoid-c-style-cast` | 22 / 0 | Mostly functional casts of fixed test values. Safe explicit-cast cleanup can be reviewed; distinguish these from the unsafe macro-to-literal fix above. |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay`, `hicpp-no-array-decay` | 1 / 0 | Qt's default-connection name is passed to the database API. Required interface conversion; no buffer traversal or bounds failure demonstrated. |
| `cppcoreguidelines-avoid-magic-numbers`, `readability-magic-numbers` | 3 / 1 | Fixture boundary values and the Android API-30 threshold. Optional naming/readability decisions, not behavior defects. |
| `readability-function-cognitive-complexity` | 12 / 0 | Large test scenarios. Review readability while keeping setup/action/verification together; avoid a helper framework merely to reduce a metric. |
| `misc-use-internal-linkage` | 2 / 0 | Test-fixture linkage advice; no conflicting definition. Lower priority than actual contracts or behavior. |
| `modernize-make-unique` | 2 / 2 | Straightforward RAII readability improvement; already-owned pointers do not establish a leak. |
| `modernize-use-ranges` | 1 / 1 | C++20 simplification opportunity for any_of; not a correctness defect. |
| `modernize-use-nodiscard` | 3 / 0 | Optional annotation on test Q_INVOKABLE helpers; consider actual C++ call sites and Qt invocation behavior. |
| `readability-implicit-bool-conversion` | 3 / 0 | Idiomatic pointer checks in test setup. Policy choice; no incorrect truth value. |
| `readability-use-concise-preprocessor-directives` | 2 / 2 | #ifdef versus #if defined style preference; both preserve the platform gate. |

The callback behavior of [QSignalSpy](https://doc.qt.io/qt-6/qsignalspy.html) is
documented by Qt. Clang documents both
[const-correctness limitations/options](https://clang.llvm.org/extra/clang-tidy/checks/misc/const-correctness.html)
and [macro handling for bool literals](https://clang.llvm.org/extra/clang-tidy/checks/modernize/use-bool-literals.html).
Local headers confirm the explicit-signature JNI overload and QSignalSpy's
non-const recording operation.

No additional application source fixes or suppressions were applied in the
Samuel-baseline phase. Prior runtime checks remain evidence for the unchanged
source tree, not a claim that this broader analyzer profile passes. DEV-005 stays
open for targeted corrections and reviewed, narrow exceptions. Start with the
property/getter contract; preserve the raw baseline when doing follow-up work.

## editorIndex property contract follow-up (DEV-005)

Qt requires a READ accessor to return the property type or a const reference to
it: [property requirements](https://doc.qt.io/qt-6/properties.html#requirements-for-declaring-properties).
The new `ModelTest::editor_index_property_matches_accessor` regression observes
the actual QMetaProperty and the getter's C++ meta-type. With the original code,
it fails: the property is QMetaType::Int (2), while the getter is LongLong (4) in
the tested 64-bit kit. This establishes the declaration-contract defect; it is
not a claim that ordinary phone lists already displayed a wrong row.

The correction retains the existing int QML property and changes editorIndex()
to return int, converting the stored index explicitly. Qt model rowCount/index
APIs already use int, and rowCount() already follows this conversion pattern.
No storage, ordering, gesture or editor behavior redesign is included.

The test also reads the property through no editor (-1), creation (0), movement
(2), removal before the editor (1), editor removal (-1) and reload (-1), checking
saved list contents. It runs in the normal model suite with in-memory SQLite.

The focused test fails before the fix (one failure) and passes after it (all
three focused records). Full Windows configure/build/CTest passes: 157 UI,
19 flow, 6 keyboard and 63 model records, zero failures/skips, 283.60 seconds.
The Android x86_64 application shared library builds; no new APK installation or
native Android runtime check is claimed for this platform-independent contract fix.

Both full Samuel scans completed after the correction. The property mismatch
warning is absent in all five Windows and three Android includers that previously
reported it. Other findings remain visible: 260 Windows diagnostic emissions
(11 of 14 runs need review) and 35 Android emissions (7 of 10 runs need review).
No checks were disabled and no suppression was added for this fix.
The test and its direct includes add two test-string allocation suggestions and
one complexity suggestion while removing three include-cleaner findings; those
style/hygiene findings remain visible for separate review.

Reports are under `out/dev005/editor-index`: before.txt, after.txt,
verify-windows.txt, android-build.txt, windows-analysis and android-analysis.
The baseline in the previous section remains an immutable comparison. The overall
DEV-005 ticket remains open for the other findings.

## Confirmed false-positive follow-up (DEV-005)

The next accepted step handles three specific cases while retaining all 505
tidy and 100 Clazy checks:

- `misc-const-correctness.AllowedTypes: '^QSignalSpy$'` excludes only that Qt
  recorder type. It removes 24 callback-blind suggestions to make spies const.
  Thirteen other const suggestions remain visible for review.
- The two expected-build-flag values in test_ui.cpp now use `MACRO != 0` instead
  of `bool(MACRO)`. This expresses the same conversion for zero and nonzero
  configurations and avoids an unsafe suggested replacement with literal true.
  Both the bool-literal check and the casting checks remain enabled everywhere.
- One named NOLINTNEXTLINE on `public slots:` explains why the access label is
  required for Qt test-setup discovery. The redundant-access check remains active
  at other declarations; the separate Clazy Qt-keyword advice is not hidden.

No application behavior fix is claimed in this phase. Only the test harness's
equivalent Boolean expressions, one annotation and the type-specific analyzer
option change. The earlier property-contract regression remains in the normal
model suite. No blanket file/test-directory exclusions were added.

An isolated analyzer control reports three findings before the option: the spy,
an ordinary mutable int and an integer-to-bool literal cast. Afterward it reports
the latter two and exits 1, proving that normal positive diagnostics remain
active. The raw control and logs are in `out/dev005/false-positives`.

The Release/AUTO harness rebuild passes all five ThemeSizing and six
PreviewScaling records with both expected flags zero. The normal Debug/AUTO
suites exercise the true branches. These existing build-gate tests would reject
freezing the expected flags to true in Release. Offscreen results establish these
gates and setup behavior, not native typography or complete app appearance.

Full Windows verification passes all four entries: 157 UI, 19 flow, 6 keyboard
and 63 model records, zero failures/skips, 280.74 seconds. Both Samuel reruns
complete with the same 505/100 selections. Windows emissions fall from 260 to
231: 24 spy suggestions, two unsafe macro-literal suggestions, one slots-label
suggestion and two cast suggestions are removed. Android remains at 35 emissions;
its application sources are unchanged by this step. The helper still fails on
the other visible findings (11 Windows and 7 Android runs need review).

These are verified analyzer exceptions and equivalent harness cleanup, not a new
application bug fix. No Android runtime/phone check is claimed. Reports and the
summary are in `out/dev005/false-positives`; the normal Windows development build
is restored after the separate Release verification. DEV-005 remains open for
the remaining dependency, ownership and policy reviews.

## Public includes and ownership cleanup (DEV-005)

The next accepted pass addresses direct dependencies and small ownership
simplifications without changing list algorithms or JNI calls:

- Add public headers for the environment functions, Android jint/QColor usage,
  proxy dependencies, and directly used test classes/macros. Qt documents
  [QtEnvironmentVariables](https://doc.qt.io/qt-6/qtenvironmentvariables.html)
  as the environment-function header. QTest assertions use the public
  QtTest/qtestcase.h; no private Qt or NDK implementation headers were added.
- Construct the two already-owned UndoRemove commands with std::make_unique.
  Their existing release to QUndoStack, undo behavior and failure paths remain.
- Use QStringLiteral for the production Material style name and proxy filter
  expression, retaining exactly the same strings and overloads.
- Keep two line-local include-check exceptions: QStringList's documented
  [public header](https://doc.qt.io/qt-6/qstringlist.html) is already included,
  and the chrono literal's public `<chrono>` header is already included. These
  provider-tracing warnings do not justify private-header dependencies. No
  include-check group or header directory was disabled.

Full Windows verification passes 157 UI, 19 flow, 6 keyboard and 63 model
records, zero failures/skips, in 277.60 seconds. This includes checked/bulk
deletion, undo, persistence and catalog-control paths. The final model-header
adjustment was rebuilt before the model CTest ran. Final comment-only annotation
changes were compile-checked in both kits after those runtime checks.

The actual Windows application also starts with the offscreen platform and a
unique QSHOPPER_DATA_DIR, creates its isolated database/default list, loads its
QML and stays alive through the five-second startup check. Its own test process
is then stopped. This does not certify visuals; the existing PopupList
contentWidth warning remains DEV-001, and the offscreen font notice is not a
new application finding. No user database or physical device was used.

The Android x86_64 application shared library builds. Both full Samuel scans
retain 505/100 checks and complete without parser errors. Windows emissions
fall from 231 to 190 and Android from 35 to 24. All remaining missing-include,
make_unique and property-type-mismatch diagnostics are gone. Both production
QString-allocation diagnostics are gone; the remaining 94 are in test fixtures.
The helpers still report the other findings (8 Windows and 4 Android runs need
review); this is not a clean-profile claim.

Reports are in `out/dev005/cleanup`: verify-windows.txt, model-include-build.txt,
final-windows-build.txt, final-android-build.txt, windows-analysis-final,
android-analysis-final, app-smoke.json and verification-summary.json. DEV-005
remains open for the remaining test-style, bounds/policy and Qt/JNI dispositions.

## Remaining valid warnings (DEV-005)

The next pass fixes the actionable findings left by the public-include cleanup,
including the test harness. These are quality improvements, rather than claims
that every warning represented a runtime bug:

- Replace 94 reviewed test-string conversions with QStringLiteral or Qt's `_s`
  literal, preserving the fixture text. Use const QFETCH declarations, explicit
  qsizetype casts, named/bounded fixture values and QVariant::toModelIndex().
- Give test QObject fixtures default-parent constructors and internal linkage.
  Make helpers/slots static where they use no fixture state, add nodiscard to
  value-returning invokables and use Q_SLOTS. Import only the string-literal
  operator, rather than its whole namespace.
- Reserve known list capacities, use const QList::at() for reads and a ranges
  algorithm for checked-item detection. Use replace() for the fixture update.
- Remove the bounded remove/removeEditor recursion. Removal now restores a
  pending edit directly and then removes the placeholder. Retain the read-only
  and index checks after restoration, because notification receivers can change
  model state. No signal sequence, stored item identity or undo policy changes.
- Replace the three Android JNI object calls with callMethod<QJniObject>, using
  the same Java method names/signatures. Perform system-bar bit operations in
  quint32, converting to jint at the JNI boundary. Name the API-30 cutoff and use
  concise preprocessor guards. The template API is present in the supported
  [Qt 6.10 public header](https://github.com/qt/qtbase/blob/v6.10.0/src/corelib/kernel/qjniobject.h).

The recursion refactor has a pre-change characterization:
`pending_editor_restore_respects_readonly`, with remove-editor and remove-row
data rows. A rowsInserted receiver makes the model read-only during restoration;
the test checks the retained placeholder, item identity, eventual cancellation
and persisted rows. It passes both before and after (four records each including
setup/cleanup). This preserves an existing safety check; it is not a newly found
bug with a fabricated failing-before claim. Normal model CTest includes both rows.

Four mutable QList accesses retain line-local bounds-check exceptions. setData
has an explicit index guard; the other three accesses refer to the existing
editor placeholder required by a pending edit. Qt's at() is const-only, so these
member writes keep operator[] with their guard/invariant documented. No unchecked
access check is disabled globally, and no const_cast or copying wrapper was added.
The private Q_SLOTS label has the same line-local macro access-label exception as
the public Q_SLOTS label. Earlier optional-access/include-provider exceptions stay
documented in their original sections.

Set `readability-function-cognitive-complexity.IgnoreMacros: true` to avoid
counting Qt assertion implementation as authored control flow. A local control
with 30 assertion-like macros and 30 explicit if statements warns on both with
the original option. With IgnoreMacros, only the authored function still warns
(complexity 30, unchanged threshold 25). This removes 13 inflated test metrics.
The documented [option](https://clang.llvm.org/extra/clang-tidy/checks/readability/function-cognitive-complexity.html)
also ignores macro arguments, so this metric cannot assess logic inside them;
recheck this limitation when upgrading LLVM. All 505/100 check names stay enabled.

Final scans contain zero displayed project diagnostics: 14 Windows analyzer runs
(seven translation units) and 10 Android runs (five application translation units),
all exit zero, no parser failures. This follows 190 Windows and 24 Android emissions
at the beginning of this pass. Config snapshots and source hashes remain in the
reports; this is a clean result within the documented scope and exceptions.

Windows verification passes all four CTest entries in 285.78 seconds: 157 UI,
19 flow, 6 real-keyboard and 65 model records, zero failures or skips. The final
literal-operator import was rebuilt before model CTest and the targeted callback
test ran again afterward. QML tests use offscreen rendering; they are not Windows
visual certification. The API-36 emulator suite passes all 47 native theme checks
across six profiles, including live System theme changes, resume, native IME,
status-bar icon contrast, safe surfaces and preserved fixture data.

Android native compilation succeeds. The usual APK output directory has an
explicit delete-deny ACL, causing Gradle mergeDebugNativeLibs to fail even outside
the sandbox. Packaging the same rebuilt native binary in a fresh temporary
directory succeeds, without changing ACLs. The signed APK is installed only on
emulator-5580. Android 9/10 fallback code is compiled, not runtime-certified;
the emulator runs API 36. No physical-device installation is performed.

Reports are in `out/dev005/remaining-valid`: `windows-confirmed/results.json`,
`android-final/results.json`, `callback-before.txt`, `callback-after.txt`,
`complexity-before.txt`, `complexity-after.txt`, `reviewed-string-conversions.json`,
`verify-windows-final.txt`, `model-final-build.txt`, `android-native-final.txt`,
`android-package-final.txt`, and `android-theme/results.json`.

DEV-005 was closed with user acceptance on 2026-11-01 after reviewing both model
and UI regression coverage. Earlier sections retain the intermediate findings and
their dispositions; the final clean scans and verification above are the closure
baseline. Desktop visual appearance, physical-phone coverage and Android 9/10
runtime behavior are not certified by this pass.
