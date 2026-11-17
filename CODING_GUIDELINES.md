# Coding guide

Keep QShopper simple. Use [Google's C++ guide](https://google.github.io/styleguide/cppguide.html)
as a starting point, adjusted for Qt and this project. Existing accepted
formatters govern layout; broad reformatting belongs in its own change.
Review coverage and decisions: [DEV-006](reviews/DEV-006.md).

## C++

- Use C++20 and public Qt APIs. Keep ownership and failure handling explicit.
- Put braces around every `if` body. Do not introduce `continue`.
- Prefer small value types/rule of zero; add constructors, inheritance or
  abstraction only when the existing behavior benefits. A plain stored record
  does not need a wrapper just to reduce repeated syntax.
- Use QObject parents for QObject lifetime. Do not copy/move QObject models.
- Validate indices/parents/read-only state before mutation. A flat model has no
  child rows. Keep begin/end model notifications and property notifications paired
  with their actual state changes; account for re-entrant signal receivers.
- Read database results into temporary state. Replace loaded state only after a
  successful query; a failed read must not become destructive cleanup or save.
- Use stable item identity when restoring/reordering data. Preserve user order,
  pending edits, checked-stack semantics and recovery policy from DESIGN.md.
- Use categorized logging. Debug detail belongs in Debug; Release is quiet apart
  from actionable warnings/errors. Do not log shopping text or credentials.
- Keep local analyzer exceptions narrow and explain the invariant. A warning is
  a lead to investigate, not an instruction to apply an automated refactor.

## QML review

Review one component at a time: definition, base/content dependencies, derived
types, actual callers, dynamic loading and tests. Reading a caller does not count
as reviewing it. Record “no changes needed” when appropriate.

| Responsibility | Owner |
| --- | --- |
| Natural size | Component's implicitWidth/implicitHeight |
| Actual allocation/position | Parent, anchors or Layout |
| Layout hints | Instance that is a direct child of a Layout |
| Content size | Control/content relationship, without circular implicit sizing |

Avoid competing anchors and Layout geometry. Prefer RowLayout, ColumnLayout,
GridLayout or FlexboxLayout over positioners or Item wrappers used only to place
children; choose the simplest suitable layout. Do not add redundant fill hints.
Custom button content honors inherited display modes and declares its default.

Use `Theme.pixels(mm)` and `Theme.millimeters(px)`, based on the window's attached
Screen density. Do not apply devicePixelRatio again or pass Dimensions objects.
Preview scale is desktop Debug only. Do not reload the view for zoom.

Preserve intentional animations, opacity, swipe pullback, touch sizes and text
fitting. Prefer Qt's existing controls/behavior over a parallel framework.
Resolved Material.theme drives colors; stored System is a preference, not the
effective light/dark palette. Qualify ambiguous control imports when sorted.

## Formatting and analysis

```powershell
./tools/format-qml.ps1
./tools/format-cpp.ps1
./tools/format-qml.ps1 -Check
./tools/format-cpp.ps1 -Check
./tools/analyze-cpp.ps1
```

Use Qt 6.12 qmlformat and clang-format 22.1.8. New sources must be tracked first.
Keep import sorting, include order and the committed configurations. Separate
format-only changes from behavior fixes. [Analysis settings](tests/STATIC_ANALYSIS.md)
explain the deliberately broad checks and reviewed exceptions.

## Changes and tests

A bug fix needs an automated reproduction that fails before and passes after.
Test the observable failure/real trigger, not a copy of the replacement code.
Use model tests for data, Qt Quick Tests for interactions, and native rendering
or Android coverage for platform-specific behavior. Manual acceptance complements
automation. Keep isolated data and record any untested platform gap.

Use real production controls in interaction tests. Wait for the intended settled
state; test animation interruptions separately. Preserve useful failure messages
and receiver/order checks. Do not add XFAIL/skip to hide an unexplained failure,
global warning suppression, vacuous source-pattern assertions or new generic test
frameworks where a direct fixture will do.

Run [appropriate checks](tests/README.md); repeat broader suites when new edits
or failures justify it. Keep test-only cleanup and app behavior changes separate.
