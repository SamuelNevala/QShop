# QShopper backlog

Started: 2026-10-28. QShopper is near feature complete. Backlog gathering and
prioritization are recorded below. UI-004 is resolved. The user selected UI-006
for implementation; remaining tickets stay deferred until selected.

Use [DESIGN.md](DESIGN.md) when deciding what counts as correct behavior. Keep
intentional gestures, text fitting, animation, and list ordering intact.

## How to use this backlog

- Capture reports first. Do not implement fixes during backlog gathering.
- Feature and code-quality requests are also backlog intake during this phase,
  unless the user explicitly asks to implement them now.
- Keep stable IDs. Add new UI reports from UI-011 onward; UI-002 is already resolved.
- Distinguish user reports, previously observed bugs, source-review candidates,
  missing features, code-quality work, and validation tasks. Missing test coverage
  is not evidence of a bug.
- Record the trigger, actual and expected behavior, device/build, and evidence
  when available. Unknown details can remain pending.
- Severity describes impact. The suggested order below is a recommendation;
  implementation begins when the user selects work, and reproduction may change priorities.
- Update the backlog and any linked ticket together. Close a bug with evidence
  from the affected behavior, not just a passing unrelated test suite.
- Every bug fix must add or strengthen an automated regression test: reproduce
  the bug, verify the test fails before the fix, then passes afterward. This rule
  applies to all current and future bug tickets, including analyzer findings.
- Test the actual trigger at the appropriate model, QML, platform, or rendering
  level. Manual checks supplement the test rather than replacing it. A desktop
  model test alone cannot establish that an Android gesture or visual bug is fixed.
- Record the regression test and its before/after results when closing a ticket.
  If reproduction or automation is blocked, leave the ticket open with that gap.

## Suggested execution order

Proposed on 2026-10-28. Restore reliable shopping interactions first, then finish
coverage and visual decisions, simplify the implementation, and prepare release.
Keep each bug fix paired with its own failing-before/passing-after regression
test. This recommendation does not itself authorize starting implementation.

| Order | Tickets | Reason and approach |
| --- | --- | --- |
| 1 | [UI-004](tickets/UI-004.json) — right-swipe selection/deletion | Resolved: regression tests pass; user confirmed half-width behavior and comfortable phone feel at 150% sensitivity |
| 2 | [UI-007](tickets/UI-007.json) — Back/long-press leak | Held-row cleanup reproduced and fixed while implementing UI-006; original physical-phone edge timing remains open |
| 3 | [UI-006](tickets/UI-006.json) — Back navigation | Implemented and covered by Windows and native Android tests; pending phone confirmation. User chose existing discard/restore behavior for unfinished edits |
| 4 | [UI-010](tickets/UI-010.json) — unreachable ComboBox options | Restore access to all choices; test actual safe-area bounds and endpoint selection |
| 5 | [UI-009](tickets/UI-009.json) — reset ordering | Protect list reuse and persisted order. Reproduce the exact example first because a simple source trace already appears to meet it; avoid a speculative rewrite |
| 6 | [UI-008](tickets/UI-008.json), then [UI-001](tickets/UI-001.json) | Fix long-list rendering, then recheck/fix the fresh-install list selection. Retain their distinct visual and state regression tests |
| 7 | [QA-003](tickets/QA-003.json), UI-003, and QA-001 | Complete remaining interaction coverage and assess the unconfirmed text-fitting discrepancy. Use a physical-phone shopping pass to expose integration problems |
| 8 | [UX-001](tickets/UX-001.json) → [UX-002](tickets/UX-002.json) → [UX-003](tickets/UX-003.json), then [UI-005](tickets/UI-005.json) and QA-002 | Agree coherent color roles before final theme/border fixes. Verify typography, contrast, physical sizing, and the intended visual continuity on devices |
| 9 | [DEV-006](tickets/DEV-006.json) → [DEV-002](tickets/DEV-002.json) / [DEV-003](tickets/DEV-003.json) → [DEV-004](tickets/DEV-004.json) → [DEV-005](tickets/DEV-005.json), with DEV-001 | Establish practical KISS guidance, apply formatting in separate mechanical changes, simplify CMake, then run configured analyzers against a clear build. Investigate the remaining QML warning alongside quality work |
| 10 | [REL-001](tickets/REL-001.json), with final QA-001/QA-002 checks | Prepare production signing/builds and store submission from the stabilized app. Repeat affected interaction/device checks after the quality changes before declaring release readiness |

QA-003 is incremental: begin its interaction inventory and harness improvements
with the early bug fixes, then fill the remaining gaps at step 7. Completing the
entire suite is not a prerequisite for fixing UI-004. Reuse a small, reliable
harness rather than building a large test framework first.

Release-planning research can be pulled forward to identify account or store
lead times; publication readiness still depends on resolved blockers and tests.
Keep broad formatting and refactoring out of the initial behavior-fix commits so
regressions remain easy to trace.

### Recommended first ticket: UI-004

1. Reproduce right-swipe failure on isolated data. Record whether movement,
   direction recognition, animation completion, or action delivery fails.
2. Add regression cases for a slow drag beyond half the delegate width and a
   fast swipe below that distance, in shopping and edit modes. Include working
   left-swipe controls and short/slow non-action cases.
3. Verify that the relevant cases fail before the fix. The signed-distance
   fallback is a lead, not a complete explanation of the reported velocity failure.
4. Make the smallest justified fix, run the regression cases and normal Windows
   verification, and verify the corresponding Android touch behavior using
   isolated data and the appropriate platform harness.
5. Record before/after results before closing UI-004. Keep any separate Back
   cancellation defect linked to UI-007 rather than silently expanding the fix.

## Bugs and candidates

| ID | Finding | Evidence/status | Severity |
| --- | --- | --- | --- |
| [UI-010](tickets/UI-010.json) | Long ComboBox option lists, such as colors, ignore the safe area and make the first and last options unreachable | User-observed; independent reproduction pending; distinct from UI-005's color mismatch | Major, per user |
| [UI-009](tickets/UI-009.json) | Reset checks should retain the selection-derived order for reuse: initial 1,2,3; check 3,1,2; reset to 2,1,3 | User-reported; exact failure/order and persistence need reproduction; simple source trace appears to meet the example | Major, per user |
| [UI-008](tickets/UI-008.json) | Empty-area background rectangle appears inappropriately while scrolling lists of roughly 35+ items | User-observed; independent reproduction pending; preserve the intentional short/long-list background continuity | Major, per user |
| [UI-007](tickets/UI-007.json) | Android Back gesture leaks a long press in edit mode, leaving an item stuck in move mode until manually dropped | Related held-row Back cleanup reproduced and fixed with regression coverage; original physical-phone timing remains open | Major, per user |
| [UI-005](tickets/UI-005.json) | Safe-area border and swipeable background do not match or consistently follow the theme | User-reported on current phone build; reproduction pending | Minor, per user |
| [UI-001](tickets/UI-001.json) | Lists selector is blank on a fresh installation | Observed on Windows on 2026-10-03; deferred; current build needs recheck | Unassigned |
| UI-003 | Shopping text permits eight lines despite the intended two-line presentation | Source/design discrepancy; visible failure not established | Unassigned |

### UI-003 — Check long-entry text fitting against the two-line design

- **Expected:** short names stay large and legible. Long entries shrink and wrap
  across two lines within the 9.27 mm reference row.
- **Evidence:** `TextItem.qml` has a 7 mm reference font, `Text.Fit`, wrapping, and
  `maximumLineCount: 8`. The user explicitly described two-line fitting as intentional.
- **Unknown:** whether the current row geometry actually renders more than two
  lines or creates a visible readability problem. The property value alone does
  not establish the rendered result.
- **Reproduction to collect:** inspect short names, long multiword entries, and
  long unbroken names on the phone. Record line count, clipping, and readability.
- **Acceptance:** preserve large short names and readable long entries in the
  intended two-line presentation. Do not reduce the line limit without checking
  how it affects font fitting and content visibility.

### UI-004 — Critical right-swipe regression

The earlier source-review candidate is now the
[critical user-reported right-swipe regression](tickets/UI-004.json), rather than
a separate issue. Both independent triggers must work: sufficient velocity, or
travel beyond half the delegate width. In shopping mode, a right swipe selects
the item; in edit mode, it deletes the item. Left swipes reportedly appear to work.

Resolved on 2026-10-29. The distance comparison now uses absolute travel, and
simulated gravity was reduced from 9810 to 1000 mm/s² after comfortable short
strokes reproduced excessive resistance. Windows and Android regressions passed;
the user confirmed the half-width fix and that 150% sensitivity feels good on the
phone. At the user's request, gravity was then calibrated to the literal value
666.67 mm/s² so 100% sensitivity matches that effort. System Back cancellation
remains UI-007. See the ticket for evidence.

## Missing features

### [UI-006 — Android Back gesture priority](tickets/UI-006.json)

Requested on 2026-10-28 and implemented on 2026-10-29; awaiting phone confirmation.
On each completed Android Back swipe, apply the first matching rule:

| Order | Current state | Action |
| --- | --- | --- |
| 1 | Drawer open | Close the drawer |
| 2 | Drawer closed, edit mode, virtual keyboard open | Close the keyboard and stay in edit mode |
| 3 | Drawer closed, edit mode, virtual keyboard closed | Switch to shopping mode |
| 4 | Drawer closed, shopping mode | Send the app to the background |

One gesture performs one action; it must not fall through to the next rule.
Backgrounding must not clear the list or explicitly quit the app. Validate with
the real Android Back gesture and keyboard. The user chose the existing mode-exit
policy: hide preserves the draft, leaving edit discards it and restores an original
item if an unfinished edit is cancelled.

Related major bug: [UI-007](tickets/UI-007.json). Back can leak a long press into
the list and leave an item stuck in move mode. Handling Back navigation alone
does not establish that pointer cancellation and drag cleanup are correct.

## Release preparation

| ID | Request | Status |
| --- | --- | --- |
| [REL-001](tickets/REL-001.json) | Prepare and define the steps for app-store publication: readiness, Release builds/signing, testing, store materials, submission, and rollout | Requested; preparation/planning deferred; target store to confirm, likely Google Play |

REL-001 should produce a concise publication checklist based on the selected
store's current official requirements, with dependencies and user decisions
clearly identified. The current debug APK is not evidence of store readiness.
Account actions, uploads, submissions, and publication require separate user
authorization; none is requested as part of backlog intake.

## Design reviews

| ID | Request | Status |
| --- | --- | --- |
| [UX-001](tickets/UX-001.json) | Analyze primary and accent color selection, derivation, and use against Android/Material color guidance | Requested; review deferred; explicitly limited to coloring, not an overall app redesign |
| [UX-002](tickets/UX-002.json) | Evaluate red delete and green selection feedback, comparing alternatives for clarity, accessibility, and theme compatibility | Requested; review and color changes deferred |
| [UX-003](tickets/UX-003.json) | Review whether primary/accent usage in custom and non-Material components is sensible, readable, and consistent | Requested; review and implementation deferred |

UX-001 covers primary/accent roles, palette choices, readability, state feedback,
and behavior across Light, Dark, and System themes. Compare the actual Qt Material
implementation with official Android guidance, respect the visual intent in
DESIGN.md, and record recommendations separately before any implementation.

UX-002 focuses on action semantics: red for deletion and green for selection.
Compare the existing scheme with alternatives, including non-color cues and
readability over translucent backgrounds. Coordinate with UX-001 and recommend
keeping the current colors if they remain the best fit; a change is not assumed.

UX-003 examines actual custom-component color bindings, theme propagation,
semantic roles, and rendered combinations outside standard Material controls.
Reuse UX-001/UX-002 findings where relevant; a custom Material color reference is
not automatically wrong, and a component rewrite is not assumed.

## Code-quality work

| ID | Request | Status |
| --- | --- | --- |
| [DEV-002](tickets/DEV-002.json) | Choose a qmlformat configuration close to Qt's own QML conventions and apply it to all project QML sources, including tests and templates | Requested; configuration and formatting deferred |
| [DEV-003](tickets/DEV-003.json) | Choose a clang-format configuration and apply it to all project-owned C++ sources and headers, including tests | Requested; configuration and formatting deferred |
| [DEV-004](tickets/DEV-004.json) | Review and simplify the CMake files using KISS principles, removing unnecessary complexity while preserving supported builds | Requested; review and cleanup deferred |
| [DEV-005](tickets/DEV-005.json) | Set up clang-tidy and Clazy with suitable checks, analyze the project, triage findings, and fix actionable issues | Requested; setup, analysis, and fixes deferred |
| [DEV-006](tickets/DEV-006.json) | Analyze QML and C++ for simplicity and write practical KISS-based coding guidelines grounded in the current code | Requested; review and full guide deferred; KISS recorded as a standing principle |

DEV-002 should establish a checked-in `.qmlformat.ini`, Qt-style attribute order,
and a repeatable formatter invocation usable with Qt Creator. Preserve behavior
and import resolution, exclude generated/external files, and verify that a second
pass is unchanged. Keep it separate from functional fixes.

DEV-003 should establish a checked-in `.clang-format`, document the tool version
and repeatable invocation, and preserve Qt macros and include semantics. Exclude
generated/external files, check that a second pass is unchanged, and run Windows
verification after the eventual formatting pass.

DEV-004 covers root/test CMake structure and its relationship to presets and build
scripts. Favor direct, readable configuration over unnecessary helper layers.
Preserve necessary platform gates, QML resources, keyboard deployment, tests, and
optional coverage; verify the build paths affected by the eventual cleanup.

DEV-005 should select compatible analyzer versions and useful checks, analyze
against the real build configuration, and document repeatable commands. Record
findings before fixing them, review automatic suggestions, and account for any
remaining diagnostics. Coordinate CMake changes with DEV-004 and keep functional
fixes distinguishable from formatting.

DEV-006 should produce `CODING_GUIDELINES.md` from a review of both languages.
KISS means clear, direct implementations and justified abstractions, rather than
the shortest possible code or removal of necessary correctness safeguards.
Coordinate with DEV-002 through DEV-005 and record proposed refactors separately.

## Test coverage and validation tasks — no failure claimed

| ID | Area | Checks still needed |
| --- | --- | --- |
| [QA-003](tickets/QA-003.json) | Expand automated UI coverage to all implemented user interactions | Inventory and map controls, gestures, modes, cancellation/recovery, settings, persistence, and Android-specific flows to repeatable tests; implementation deferred |
| QA-001 | Full shopping flow on the updated physical phone | One-handed check/correction, checked-item stack order, movable editor, long-press reordering, drawer and list switching, restart persistence, dictation, repeated Return, the end of a long list with the keyboard open, and UI-006 Back behavior once implemented |
| QA-002 | Physical sizing and text on different displays | Check real touch dimensions, short/long-entry readability, and layout on different phone sizes/densities; desktop zoom alone does not establish physical Android usability |
| DEV-001 | Repeated QML diagnostic | Investigate the `PopupList` `contentWidth` override warning in existing Windows UI/keyboard reports. Determine whether it is an app or Qt issue and whether it affects behavior; no user-visible failure is established |

QA-003 should exercise actual user paths, not count direct model calls or emitted
signals as coverage of UI controls. Reuse existing tests, add missing platform
coverage, and keep known-bug regressions linked to their fixes. Record the
interaction-to-test matrix and remaining gaps rather than claiming complete
coverage from a passing partial suite.

Existing evidence: Windows model, offscreen QML, and keyboard suites passed on
2026-10-27. Android emulator checks covered keyboard submission, hide/reopen,
long-list scrolling, and repeated keyboard resizing. These checks do not certify
the full shopping flow on the current physical phone. See
[tests/README.md](tests/README.md) and [ANDROID.md](ANDROID.md).

Do not turn old notes saying Android was untested into duplicate bugs: later
emulator evidence exists. Physical-phone behavior remains a separate check.

## Resolved history

| Reference | Finding | Resolution/evidence |
| --- | --- | --- |
| [UI-004](tickets/UI-004.json) | Right-swipe selection/deletion and excessive swipe resistance | Absolute-distance fix and gravity tuning; before/after regressions pass. User confirmed half-width behavior and phone feel at 150% sensitivity on 2026-10-29 |
| [UI-002](tickets/UI-002.json) | Null-dimensions error during component startup | Theme migration removed the delayed Dimensions dependency; regression coverage exists |
| [Keyboard resize](ANDROID.md#keyboard-resize-verification) | Keyboard covered the end of a long list | Explicit Android `adjustResize`; emulator scrolling and ten hide/show cycles passed, with no near-black frames in the recorded test. Physical-phone verification belongs to QA-001 |
| APK signing, 2026-10-28 | Phone refused the update because the signing certificate differed | Original shared debug key matched the installed certificate; rebuilt APK verified, and user confirmed the update installed. `build-android.ps1 -DebugKeystore ../debug.keystore` preserves that signing choice |

## Intake

More user-reported bugs are expected. Add them as they are described; do not
invent symptoms for the unspecified reports. A rough description is enough to
start a ticket, with reproduction details added later.

The suggested order above remains the execution plan. UI-004 and UI-006 were
selected separately after prioritization. UI-007 remains the next ticket, as the
user explicitly requested after its cancellation probe reproduced a failure.
