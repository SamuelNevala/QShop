# C++ static analysis

Optional; separate from normal builds/tests. Uses Qt Creator's clang-tidy
**22.1.8** and **Clazy 1.16** with the actual compilation database.

```powershell
./tools/analyze-cpp.ps1
./tools/analyze-cpp.ps1 -SkipBuild -ReportDirectory out/analysis-repeat
```

The first command builds Windows/generated headers, then checks every tracked C++
translation unit. `-SkipBuild` requires a current build and `compile_commands.json`.
For another built directory use `-BuildDirectory`; for an Android app-only build
add `-ApplicationOnly`. Configure that build with
`CMAKE_EXPORT_COMPILE_COMMANDS=ON` first. Use `-ClangTidy`/`-Clazy` for other tools.

## Configuration

`.clang-tidy` contains the accepted **505-check** project profile;
`tools/clazy-checks.txt` explicitly lists **100 Clazy checks**. It spans
correctness, CERT, core guidelines, modernization, performance, readability and
Qt/JNI checks. Check names stay explicit so upgrades do not silently broaden scope.
The imported IDE warning flag `-w` was not adopted. Compiler commands, definitions,
Qt headers and source selection come from CMake, not a generic substitute.

In Qt Creator enable **Prefer .clang-tidy file, if present** under its Clang Tools
settings. The CLI does not change IDE preferences. Reports record versions,
enabled checks, configuration snapshots and source coverage. Review again when
upgrading the toolchain; do not apply exported fixes automatically.

## Accepted dispositions

- `QSignalSpy` alone is excluded from const-correctness: its signal callbacks
  mutate records. Do not generalize that exception to arbitrary objects.
- Cognitive complexity ignores macro expansions. Authored control flow stays
  checked at threshold 25; the metric cannot assess logic inside macro arguments.
- Qt meta-object access-label macros and guarded mutable QList accesses have
  narrow named line-local exceptions. Keep bounds/read-only invariants and
  receiver re-entrancy checks; do not add global suppressions or const_cast.
- Optional-access and include-provider exceptions are local to confirmed cases.
  Public includes, value/ownership cleanup and typed JNI calls were corrected
  where warnings identified real quality issues.
- Removing bounded editor-restore recursion retained checks after callbacks.
  `pending_editor_restore_respects_readonly` characterizes receiver changes;
  it was not relabeled a newly reproduced bug.

## Closure evidence

DEV-005 was accepted/closed **2026-11-01**. Final scans reported zero displayed
project diagnostics across all seven Windows translation units and five Android
app units: no parser failures. Windows model/UI/flow/keyboard checks and 47
native theme checks passed. Temporary packaging was used when a generated output
ACL prevented replacement; no SDK or ACL patch was made.

Evidence: `out/dev005/remaining-valid`, especially Windows/Android results,
callback/complexity controls and `verification` logs. The
[ticket](../tickets/DEV-005.json) preserves initial findings and their
dispositions. Full historical narrative: `git show 73ada02:tests/STATIC_ANALYSIS.md`.

These results apply to their recorded source/tool versions. They do not prove
absence of defects, all platform branches or physical-phone appearance. Every
confirmed bug still needs its own failing-before/passing-after regression.

References: [clang-tidy](https://clang.llvm.org/extra/clang-tidy/),
[Clazy](https://github.com/KDE/clazy),
[Qt Creator configuration](https://doc.qt.io/qtcreator/creator-how-to-configure-clang-diagnostics.html).
