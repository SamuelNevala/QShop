# QShopper coding guidelines

DEV-006 review completed 2026-11-03, covering application QML/templates, C++
sources/headers and their QML/C++ tests. Coverage, evidence, retained decisions
and separate follow-ups are in [the review record](reviews/DEV-006.md).

## Basis and precedence

Use the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
as the C++ starting point. Evaluate its rationale rather than importing every
rule: QShopper is a small Qt application, with C++20 and established Qt interfaces.
Keep the user's instructions, [DESIGN.md](DESIGN.md), correctness and KISS central
to each decision. A rule should make this code easier to read or safer to change.

Retain the accepted `.clang-format`, `.qmlformat.ini` and formatter helpers.
Google's formatting, naming and include-order rules do not authorize a second
formatting pass or renaming existing Qt-facing APIs. Record any proposed departure
and its benefit before changing an established project convention.

The practical C++ guidance will grow from the C++ source review. Its starting
principles are direct public dependencies, readable control flow, explicit
ownership and appropriate resource management. Evaluate Google-specific library
choices, exception/RTTI policies and large-codebase restrictions against Qt and
the actual build before adopting them. Do not introduce Abseil or replace Qt
containers simply to match examples in the source guide.

Existing project rules still apply: braces for every `if`, no `continue` in new
or edited C++, and reviewed analyzer findings rather than automatic fix batches.
Use Qt's ownership and model contracts; for example, transfer a QUndoCommand to
QUndoStack at its existing ownership boundary instead of creating two owners.
Let a local unique_ptr clean up on scope exit; do not reset it immediately before
return unless earlier destruction has a concrete purpose. Keep release() where
ownership is actually transferred to QUndoStack.
Record proposed application changes before implementing them during a review.
Keep the proxy's existing parser-status hooks and QML initialization phase, as
requested by the user; do not move that setup into the constructor as a cleanup.

## C++ value types

Use a simple struct for passive public data without custom lifetime work or
cross-field invariants. Day contains two QString fields; let those members
provide normal copy/move/destruction instead of declaring boilerplate special
members and a forwarding constructor. Named aggregate initializers make its two
string values clear and follow the selected analyzer profile. Keep the separate
Qt type metadata used by its container.

Google's [copy/move guidance](https://google.github.io/styleguide/cppguide.html#Copyable_Movable_Types)
allows this public-data exception to its usual explicit-declaration rule.
Use explicit ownership/copy policy when the type's semantics require it; do not
turn this example into a blanket rule for QObject classes or resource managers.

Item also uses implicit copy/move/destruction, but keeps its real constructors.
Those distinguish null-UUID editor placeholders, new named items and loaded
records with an existing UUID. Removing lifecycle boilerplate is not a reason
to change construction policy or force an aggregate.

Keep comparison operators only where there is an actual consumer. The unused
file-local Item equality function was removed; do not invent replacement equality
semantics or compare only selected fields for hypothetical future use.

Keep values that form one logical unit in one record. UndoRemove stores each
removed Item with its restore index in a private named struct, held in one QList.
This avoids maintaining matching positions in two containers. A small record
with meaningful field names is enough; no generic wrapper is needed.

For a complete model replacement, use one reset sequence and put the data
mutation inside it. WeekModel clears and rebuilds its seven days between
beginResetModel and endResetModel; removing every row first adds an unnecessary
notification phase. Check the actual consumer before changing notifications;
incremental edits still need the appropriate row/data signals.

Prefer a framework signal that directly expresses the event being handled.
main.cpp uses objectCreationFailed for root-QML load failure, rather than
inferring failure from objectCreated. Keep the queued exit: a synchronous load
failure can happen before the application event loop starts.

For computed Qt properties, notify changes caused by every dependency. Model's
canUndo depends on both the Undo stack and readOnly; changing either can change
the effective value. Test a real QML binding as well as the getter, and avoid
notifying when the value is unchanged. See UI-020's model-property regression.

Recheck a guard only when intervening work can change the state it protects.
Model::move needs one read-only entry check; remove must recheck after restoring
a pending edit because its notifications can make the model read-only.

Let the operation that combines related changes own their final save. setChecked
changes a flag and may move a row, so it uses the existing Save::NO move policy
and saves once afterward. Keep that final save even when no row move is needed.

Use a container's direct operation when it expresses the intended change.
Model::move uses QList::move for storage relocation, while keeping the separate
Qt model notifications, bounds checks, editor tracking and persistence policy.

Store only the values an operation needs. Table cleanup keeps active UUIDs in a
QList and uses contains() for membership, rather than constructing full Item
records and searching them with a predicate. Keep the complete-read error guard
and existing cleanup policy when simplifying that representation.

Handle a local failure where it occurs when no later cleanup step is required.
The save loop logs a failed insert, rolls back and returns there, instead of
carrying an error flag through a break to a second check. Keep the rollback and
diagnostics; a shorter path must not weaken transaction safety.

A failed query is not an empty result. Before deleting tables based on catalog
membership, require the entire catalog read to succeed, including iteration.
Abort cleanup on an error before deciding which lists are orphaned. UI-021 covers
initial and partial reads, preserved contents and healthy/empty/read-only controls.

Before replacing loaded rows, collect and validate the complete read. On failure,
keep the rows, pending edit, Undo and active-list identity together. A failed list
switch must not allow the retained rows to be saved to the requested target.
UI-022 covers recovery followed by ordinary edits, failed switches and successful
refresh controls.

## Review one QML component at a time

For each file, establish its responsibility and trace its real use:

1. Read the root/base type, properties, aliases, signals, functions and internal
   content. Identify inherited behavior that the file relies on or overrides.
2. Find direct and derived instantiations, inline components, delegates, Loaders,
   component properties and string/URL-based creation. Include tests and build
   registration; distinguish unused-looking code from proven unused code.
3. Map the sizing and positioning contract at the definition and every use site.
4. Check bindings, state changes, ownership, input, theme and product intent.
   Preserve necessary behavior even where it adds implementation detail.
5. Record what should stay, any justified change, evidence and coverage limits.
   "No changes needed" is a complete review result. Reading a related file for
   context does not mark that file independently reviewed.

## QML geometry responsibilities

A reusable component normally supplies a useful natural size through
`implicitWidth` and `implicitHeight`. Its caller or parent decides its actual
size and placement. This is a starting principle, not a blanket ban on explicit
dimensions inside component definitions: internal content and deliberately fixed
controls can need them. Record the actual contract rather than changing syntax
by rule.

Prefer the appropriate `RowLayout`, `ColumnLayout`, `GridLayout` or
`FlexboxLayout` for new or revised composition, rather than Row/Column positioners
or an Item that exists only to place children manually. Do not replace unrelated
working components as a side effect. Bind size hints and margins on layout-managed
children; leave their actual position and dimensions to the layout.
Layered drawings and transform/clipping scopes can still use Item when that is
their actual role.
For example, Weekdays keeps a full-cell background Item with a smaller anchored
today marker behind its content. The layout owns the cell; the background owns
the marker's decorative position. An extra layout is not needed for that layer.

At an instance, choose sizing appropriate to its immediate parent:

- In a Qt Quick Layout, express constraints with `Layout.minimum*`,
  `Layout.preferred*`, `Layout.maximum*`, `Layout.fill*` and alignment as needed.
  Do not also drive geometry that the layout owns with anchors or explicit
  width/height bindings. A layout that has no parent layout can itself be anchored.
- Outside a layout, use anchors or direct dimensions when appropriate. Avoid
  competing authorities on the same axis; centering plus an explicit size can
  be legitimate. ListView, Loader, Control content and other containers have
  their own geometry behavior, so inspect the immediate parent rather than
  assuming every use is managed by a layout.
- Check both axes and the entire dependency chain. Content-derived implicit size
  must not feed back through the size assigned by its parent. Consider padding,
  insets, visibility, font changes, long text, resizing and preview scale.
- Use `Theme.pixels()` for physical reference dimensions. Preserve the deliberate
  touch sizes and Qt text fitting described in DESIGN.md.

These distinctions follow Qt's [Item implicit sizing](https://doc.qt.io/qt-6/qml-qtquick-item.html#implicitWidth-prop)
and [layout geometry ownership](https://doc.qt.io/qt-6/qtquicklayouts-overview.html).
The first example is [Icon.qml](Icon.qml): its natural height belongs in the
definition, while the editor instances own their square allocation through
anchors or height/width bindings. No geometry rewrite is justified for those uses.

[TextIcon.qml](TextIcon.qml) illustrates a different contract: it is a glyph
renderer whose active callers allocate the display rectangle. Its inherited Text
metrics are not a reason to add a fixed millimeter implicit size to this helper.
Where font size depends on actual height, verify that a parent allocation or an
explicit caller font breaks any implicit-height feedback. Review whole-font
assignments as well as individual font properties: Icon and Pulley intentionally
provide their content's font, while other users retain the height-based default.

## Changes and verification

When reviewing animation state, distinguish an intent latch (such as "already
animated during this gesture") from the animation's `running` state. Replacing
one with the other can change repeated-trigger behavior. Check reset, completion,
rapid re-entry and resizing, as well as the initial animation. An imperative
assignment replaces a QML property binding; decide whether a reset should assign
a value or preserve a relationship. ArrowIcon's reset observations are tracked
for validation in [UI-017](tickets/UI-017.json), without assuming a visible bug.
For initialization-sensitive behavior, include creation with an already-active
input using the actual parent/Loader path. A standalone fixture can have a
different enable-signal sequence; establish a real consumer failure before
adding startup workarounds. UndoIcon's current editor path starts its countdown
even when Undo was available before editor creation.

Object aliases can be justified extension points in a small component family.
ArrowIcon's three derived variants use its arrow and animation aliases directly
for glyph padding and movement configuration. Retain that simple arrangement
unless a narrower interface demonstrably improves understanding; do not add a
collection of forwarding properties solely to hide an already understood object.

Replacing a control's contentItem also means preserving its relevant public
contract. IconButton uses a FlexboxLayout for its glyph and caption and honors
the inherited `display` modes. Its explicit TextUnderIcon default preserves the
drawer design; IconOnly/TextOnly suppress the unused child, and TextBesideIcon
changes the arrangement. Preserve existing appearance with geometry/rendering
checks, including final-line behavior after pixel rounding. See
[DEV-010](tickets/DEV-010.json) and the permanent button-layout tests.

Keep the review separate from a broad rewrite. Record worthwhile refactors as
bounded follow-up work, with reasons and affected use sites. A suspected bug needs
reproduction before being called a confirmed bug. Every bug fix requires an
observable failing-before/passing-after regression at the relevant test level.
Retain verified no-change decisions and existing successful checks; do not
manufacture changes or tests just to fill a review checklist.

When two uses in one file repeat the same presentation rules, a local inline
component can keep those rules together. ColorComboBox shares its swatch/label
layout and passes only text, font and colors; selection and palette decisions
remain with each control. Prefer this bounded reuse over a general control API.
TextDelegate's two DragBorder instances need no extra inputs: their common
feedback follows the enclosing row state, and only their vertical anchors differ.
Keep View's three theme buttons explicit, as requested by the user. Some repeated
configuration for a small fixed set is acceptable; do not replace these with a
Repeater solely to remove duplication.

Before retaining or removing an apparently unused QML component, check its
instantiations, dynamic loading, module registration and relevant history. Build
registration alone is not a live instance; an infinite animation in an unused
definition does not establish a runtime performance bug. WheelIcon's disabled
cart-wheel uses led to its selected removal in [DEV-009](tickets/DEV-009.json),
rather than adding machinery for hypothetical future reuse.

## Tests

Keep fixtures isolated and assertions close to the action they verify. Short
local helpers for finding a row, submitting text or checking order make a test
readable; a shared test framework is not needed just to remove similar setup.
Direct model calls can arrange data, but a UI interaction test must drive the
actual control or gesture for the action under test.

Use otherwise-valid inputs to test a guard. Moving a row to itself cannot prove
that read-only protection works; test valid forward/backward moves and preserved
identity, storage and Undo. A small isolated mutation can confirm that a test
detects the intended regression without changing application code.

Wait for observable readiness, such as a drawer's opened state, rather than a
fixed startup delay. Keep deliberate gesture timing, negative-observation periods
and animation/render settling where those are part of the test. Verify colors
change between themes as well as matching across surfaces. Keep native platform,
font and rendering limits explicit; passing offscreen tests do not certify them.

Implement bounded test-only review findings directly, as requested by the user.
Preserve earlier regression coverage and separate application fixes from test
quality work. Bug fixes still require the failing-before/passing-after coverage
defined in AGENTS.md.
