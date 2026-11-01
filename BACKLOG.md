# QShopper backlog

Started: 2026-10-28. QShopper is near feature complete. Backlog gathering and
prioritization are recorded below. UI-001, UI-003, UI-004, UI-005, UI-007, UI-008,
UI-009, UI-010, UI-011, UI-014 and UI-016 are resolved. UI-006 is implemented pending phone
confirmation. QA-003 is closed by user acceptance; other unselected tickets stay deferred.

Use [DESIGN.md](DESIGN.md) when deciding what counts as correct behavior. Keep
intentional gestures, text fitting, animation, and list ordering intact.

## How to use this backlog

- Capture reports first. Do not implement fixes during backlog gathering.
- Feature and code-quality requests are also backlog intake during this phase,
  unless the user explicitly asks to implement them now.
- Keep stable IDs. Add new UI reports from UI-017 onward; UI-002 is already resolved.
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
| 2 | [UI-007](tickets/UI-007.json) — Back/long-press leak | Resolved: QML and native Android regressions pass; user confirmed the fix works on the affected phone |
| 3 | [UI-006](tickets/UI-006.json) — Back navigation | Implemented and covered by Windows and native Android tests; pending phone confirmation. User chose existing discard/restore behavior for unfinished edits |
| 4 | [UI-010](tickets/UI-010.json) — unreachable ComboBox options | Resolved: endpoint bounds/selection regressions and 54 native Android checks pass; user confirmed the fix on the phone |
| 5 | [UI-011](tickets/UI-011.json) — portrait-only Android | Resolved: native sensor and popup regressions pass; user waived physical-phone testing. Android's large-screen overrides are documented |
| 6 | [UI-009](tickets/UI-009.json) — reset ordering | Closed with user confirmation: checked 2,1,3 resets to 3,1,2; unchecked entries stay first. Model/QML/native regressions cover pending edits, repeated Reset and restart persistence |
| 7 | [UI-008](tickets/UI-008.json), then [UI-001](tickets/UI-001.json) | Both resolved: UI-008 has phone confirmation; UI-001 has before/after drawer-selection regressions, real Windows rendering and native Android cold-restart coverage |
| 8 | [QA-003](tickets/QA-003.json), [UI-003](tickets/UI-003.json), and QA-001 | UI-003 and QA-003 are closed by user acceptance. Continue physical-phone/dictation validation under QA-001/QA-002; UI-015/UI-016 remain separate follow-ups |
| 9 | [UX-001](tickets/UX-001.json) → [UX-002](tickets/UX-002.json) → [UX-003](tickets/UX-003.json), then [UI-005](tickets/UI-005.json) and QA-002 | UI-005 selected directly and resolved with phone confirmation; broader color-role reviews remain deferred. Verify typography, contrast, physical sizing and visual continuity on devices |
| 10 | [DEV-006](tickets/DEV-006.json) → [DEV-002](tickets/DEV-002.json) / [DEV-003](tickets/DEV-003.json) → [DEV-004](tickets/DEV-004.json) → [DEV-005](tickets/DEV-005.json), with DEV-001 | Establish practical KISS guidance, apply formatting in separate mechanical changes, simplify CMake, then run configured analyzers against a clear build. Investigate the remaining QML warning alongside quality work |
| 11 | [REL-001](tickets/REL-001.json), with final QA-001/QA-002 checks | Prepare production signing/builds and store submission from the stabilized app. Repeat affected interaction/device checks after the quality changes before declaring release readiness |

QA-003 is incremental: begin its interaction inventory and harness improvements
with the early bug fixes, then fill the remaining gaps at step 8. Completing the
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
| [UI-015](tickets/UI-015.json) | Validate fast Undo during the Clear-list animation | Input-readiness investigation: settled mouse/touch Undo passes after correcting the test driver; transition-time hit-target reproduction remains open | Unassigned |

### [UI-008 — Long-list background continuity](tickets/UI-008.json)

Selected, implemented and resolved on 2026-10-31; user confirmed the phone fix.
Virtualization changes the instantiated delegates' bounds, so `childrenRect.height`
cannot locate the end of the full list. The filler now follows `originY` plus
`contentHeight`, converted to viewport coordinates, with nonnegative height.
Its color, opacity and short-list purpose are preserved.

Five focused regression records fail with the original geometry. All ten final
records pass offscreen and with real Windows rendering, including rendered pixels,
34/35/80-item lists, touch scrolling, resizing, checks, editor movement and removal.
The full Windows workflow passes 102 UI, 6 keyboard and 61 model records. Native
Android scrolling and keyboard checks pass all 15 cases. The user confirmed the
supplied test APK fixes the issue on the affected phone and requested a commit.

### [UI-001 — Fresh-install list selection](tickets/UI-001.json)

Reproduced and resolved on 2026-10-31. Persist the default list's resolved UUID,
then bind the selector to the active UUID instead of manually matching the initial
name alias. Before/after drawer tests verify default display, switching contents,
reopening, settings restoration in a fresh engine, a new window, catalog selection
and model refresh. All Windows suites and ten native Android checks pass, including
actual cold restarts. The user accepted the fix and waived fresh-install phone
testing to preserve existing phone data.

### [UI-005 — Theme-following safe-area surface](tickets/UI-005.json)

Selected directly by the user on 2026-10-31, ahead of the planned QA/color reviews.
Resolved with user phone confirmation on 2026-10-31. Safe-area strips use the
normal row's Material background and 0.8 resting opacity. Checked rows retain the
inverse surface; System mode now derives that inverse from its resolved theme.
Android system-bar icons follow the actual window surface on theme changes,
resume and IME changes so that light/dark overrides remain readable.

Rendered regressions fail before the fix and pass afterward. All Windows suites
and 47 native Android checks pass, including real OS System-mode changes and
keyboard use. The Android 9/10 fallback is compiled but lacks runtime coverage.
The user verified the supplied APK on the affected phone and requested closure
and a commit. No physical-device installation or data reset was performed by the agent.

### [UI-014 — Drawer Material colors in System theme](tickets/UI-014.json)

Selected on 2026-10-31; user clarified this is an Android-only failure. Reproduced
and resolved with user Android emulator confirmation. The drawer
compared the raw System selection to Dark and chose a light background despite
Dark Material controls. It now uses the drawer's resolved `Material.theme`.

The native regression selects themes through the real drawer and compares its
background and seven Material controls with the corresponding explicit palette.
Before the fix, 24 of 137 checks fail in live, initial and reopened System/Dark.
Afterward all 137 pass, including 47 existing UI-005 controls. The Windows suites
also pass as regression checks; they do not establish Android reproduction.
Existing shade choices and other palette settings are preserved. The user accepted
Android emulator verification and requested closure and a commit on 2026-10-31;
physical-phone confirmation is not claimed.

### [UI-003 — Bound shopping text using Qt's built-in fitting](tickets/UI-003.json)

Selected on 2026-10-31. The original eight-line allowance produces up to four
lines in native Windows preview cases and three on the tested Android emulator.
The user relaxed the original strict two-line limit; the recommended cap is now
three, preserving useful space for exceptionally long names.

Resolved on 2026-10-31 with user desktop confirmation and acceptance of closure.
Physical-phone confirmation is not claimed. The user requested the simple Qt-native
approach: keep the 7 mm reference font, Text.Fit and 9.27 mm row, and set
maximumLineCount to three. Qt handles shrinking, wrapping and the existing ellipsis
fallback. The additional C++ font scaler has been removed as unnecessary complexity.

The repeatable QML suite checks short, long, unbroken and oversized text at three
widths and two preview scales, checked styling, row reuse and live resizing.
Native screenshots check both themes and stored source text with isolated data.
Regression results and commands are recorded in the ticket and tests/README.md.
The user tested the desktop appearance, reported it looks good and requested a commit.

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

Related major bug: [UI-007](tickets/UI-007.json). Its separate cancellation fix
prevents a stale long-press timer and unintended swipe actions after system
takeover. Tests also verify that the first subsequent reorder and swipe work.
The user confirmed UI-007 works on the affected phone. UI-006's full four-step
priority still awaits explicit phone confirmation.

### [UI-011 — Portrait-only Android orientation](tickets/UI-011.json)

Requested, selected and resolved on 2026-10-29. The user waived physical-phone
testing and accepted the automated verification.
The activity now requests `portrait` in the manifest. The native regression
first proves that the emulator sensors can rotate a Settings control, then checks
QShopper's actual geometry on launch and rotation with shopping/edit modes,
keyboard, drawer and unfinished text. Saved list order and checks are preserved.
Android can override orientation restrictions on larger displays; see ANDROID.md.

### [UI-012 — Drawer About and open-source licenses](tickets/UI-012.json)

Requested on 2026-10-30; implementation deferred. Add an About component in the
drawer where users can identify shipped open-source components and read their
license texts and attribution notices offline. Inventory the actual libraries,
fonts, icons and other third-party assets when implementing.

Keep long license texts readable and scrollable within the safe area. Cover
opening, scrolling, closing and Android Back with UI tests, preserving shopping
data and unfinished edits. Coordinate the inventory with REL-001's licensing
review. Priority and severity remain unassigned.

### [UI-013 — Original shopping-themed background images](tickets/UI-013.json)

Requested on 2026-10-30; image generation and replacement deferred. Create new,
original shopping-related backgrounds with the user's requested 1920-pixel target.
Confirm the exact dimensions/aspect ratio and number of variants when selected.
The existing image may inform the broad visual direction; do not copy its artwork.

The user identifies `_one.png` as the original and raises a copyright concern.
That filename was not found in the current checkout; `background_one.jpg` and
other background variants are present and packaged. Verify the original and any
derivatives, then replace affected assets and remove obsolete packaged references.
Record the new artwork's provenance and coordinate with REL-001/UI-012. Preserve
text readability, themes, transparency and portrait cropping. Priority is unassigned.

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
| [UX-004](tickets/UX-004.json) | Consider replacing Font Awesome with [Tabler Icons](https://tabler.io/icons): icon coverage, readability, Qt/QML integration, licensing and maintenance | Requested; comparison and migration deferred |

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

UX-004 should inventory current glyphs and map suitable replacements, compare
visual clarity and theme behavior at the existing physical sizes, and recommend
a KISS asset approach. Coordinate notices with UI-012 and REL-001. Switching is
an option to evaluate, not an agreed migration; priority remains unassigned.

## Code-quality work

| ID | Request | Status |
| --- | --- | --- |
| [DEV-002](tickets/DEV-002.json) | Choose a qmlformat configuration close to Qt's own QML conventions and apply it to all project QML sources, including tests and templates | Resolved 2026-11-01 with user acceptance: Qt 6.12 settings/helper applied to 54 sources; SortImports=true with preserved control selection, repeat pass stable, all four Windows suites and 19 native Windows flow records pass |
| [DEV-003](tickets/DEV-003.json) | Choose a clang-format configuration and apply it to all project-owned C++ sources and headers, including tests | Resolved 2026-11-01 with user acceptance: Qt-aligned clang-format 22.1.8 settings/helper applied to all 11 sources; repeat pass and include/token audits pass, all four Windows suites and nine native Windows cancellation records pass |
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

QA-003 closed by user acceptance on 2026-10-31: the interaction map and expanded
control-driven coverage are accepted with validation limits recorded. All four
Windows suites pass; Android passes 65/68 checks, with three selector Back
failures tracked as UI-016. Dictation/physical-device checks continue under
QA-001/QA-002; UI-015 remains a separate transition-time input candidate.

| Reference | Finding | Resolution/evidence |
| --- | --- | --- |
| [DEV-003](tickets/DEV-003.json) | Consistent C++ formatting | Root clang-format configuration and helper cover all 11 C++/header/test sources. Repeat pass, include/token audits, four Windows suites and nine native cancellation records pass. User accepted closure and commit on 2026-11-01 |
| [DEV-002](tickets/DEV-002.json) | Consistent QML formatting | Qt 6.12 qmlformat, root configuration and repeatable helper cover all 54 QML/test/template sources. Sorted imports preserve existing control selection; repeat pass and Windows checks pass. User accepted closure and commit on 2026-11-01 |
| [UI-016](tickets/UI-016.json) | Android Back also closes the drawer behind a selector | Modal selector popups dismiss on outside release; six touch regressions fail before and all 17 focused records pass after. All four Windows suites and 26 native left/right checks pass. User confirmed on an Android emulator and requested closure on 2026-11-01 |
| [UI-003](tickets/UI-003.json) | Bound long-entry text fitting | Keep Qt Text.Fit and 7 mm font, cap at three lines. Four native Windows cases fail before; all 33 pass afterward. Full Windows suites and 20 Android controls pass. User confirmed desktop appearance and accepted closure on 2026-10-31 |
| [UI-004](tickets/UI-004.json) | Right-swipe selection/deletion and excessive swipe resistance | Absolute-distance fix and gravity tuning; before/after regressions pass. User confirmed half-width behavior and phone feel at 150% sensitivity on 2026-10-29 |
| [UI-007](tickets/UI-007.json) | Back cancellation leaks a long press and breaks the next item interaction | Reset the stale cancelled tap recognizer and reject cancelled swipe actions. Before/after QML and native Android tests pass; user confirmed the fix works on the phone on 2026-10-29 |
| [UI-010](tickets/UI-010.json) | Long selector popup endpoints overlap unsafe screen areas | Use window safe-area margins for popup bounds; before/after regressions and 54 native Android checks pass. User confirmed the phone fix on 2026-10-29 |
| [UI-011](tickets/UI-011.json) | Keep the Android phone app portrait-only | Manifest portrait request; 11 sensor/state checks, 18 popup checks and all Windows suites pass. User waived physical-phone testing on 2026-10-29; platform overrides are documented |
| [UI-014](tickets/UI-014.json) | System theme gives Android drawer controls the wrong background | Use the resolved drawer Material theme. Before: 24/137 native checks fail; after: all 137 pass. Windows regressions pass. User confirmed on an Android emulator and requested closure on 2026-10-31 |
| [UI-005](tickets/UI-005.json) | Safe-area background does not match rows or follow the theme | Match the normal Material surface and opacity, resolve System checked contrast and native bar icons. Before/after regressions, all Windows suites and 47 native checks pass; user confirmed the phone fix on 2026-10-31 |
| [UI-001](tickets/UI-001.json) | Blank list selector on a fresh installation | Persist the resolved default UUID and bind the selector to the active value. Two failing-before cases now pass; six focused Windows records, full Windows suites and ten native Android checks including cold restart pass on 2026-10-31. User accepted the fix and waived phone testing |
| [UI-008](tickets/UI-008.json) | Empty-area filler overlaps virtualized long-list rows | Full ListView extent and origin determine filler position; before/after pixel regressions, all Windows suites and 15 native Android checks pass. User confirmed the phone fix on 2026-10-31 |
| [UI-009](tickets/UI-009.json) | Reset must recover chronological checking order | Reverse checked slots, keep unchecked entries fixed, retain drafts and IDs, and save once. Updated model/QML/native regressions pass; user confirmed the test APK works and requested closure on 2026-10-30 |
| [UI-002](tickets/UI-002.json) | Null-dimensions error during component startup | Theme migration removed the delayed Dimensions dependency; regression coverage exists |
| [Keyboard resize](ANDROID.md#keyboard-resize-verification) | Keyboard covered the end of a long list | Explicit Android `adjustResize`; emulator scrolling and ten hide/show cycles passed, with no near-black frames in the recorded test. Physical-phone verification belongs to QA-001 |
| APK signing, 2026-10-28 | Phone refused the update because the signing certificate differed | Original shared debug key matched the installed certificate; rebuilt APK verified, and user confirmed the update installed. `build-android.ps1 -DebugKeystore ../debug.keystore` preserves that signing choice |

## Intake

More user-reported bugs are expected. Add them as they are described; do not
invent symptoms for the unspecified reports. A rough description is enough to
start a ticket, with reproduction details added later.

The suggested order above remains the execution plan. UI-004, UI-006 and UI-007
were selected separately after prioritization. UI-007 is resolved with
regression coverage and phone confirmation. The user then selected UI-010;
it is resolved with automated coverage and phone confirmation.
The user then selected UI-011; it is resolved with sensor-driven regression
coverage and physical-phone testing waived by the user. The user then selected
UI-009 and corrected the required order: reverse the checked stack into checking
order, leaving unchecked entries first. It is closed with updated model,
drawer and native Android verification and user confirmation of the test APK.
The user then selected UI-008; it is resolved with rendered-pixel and native
Android regressions plus user confirmation of the phone fix. The user then selected
UI-001; it is resolved with before/after selection tests, real Windows rendering
and native Android cold-restart verification. Next is the planned QA-003 interaction
coverage inventory and UI-003 text-fitting assessment in the original plan. The
user instead selected UI-005; its theme/safe-area fix is resolved with
regressions and user phone confirmation. QA-003 and the broader color-role
reviews remain deferred.

The user then selected UI-014 ("104") and clarified Android-only reproduction.
Its one-binding drawer fix is resolved with native before/after rendering tests
and user Android emulator confirmation. Broader color reviews remain deferred.

The user then selected UI-003 and asked to keep fitting simple and allow more than
two lines. The final change caps Qt's built-in Text.Fit at three lines; no separate
font scaler remains. Windows/Android tests cover the resulting behavior.
The user confirmed the desktop appearance and accepted closure on 2026-10-31.
QA-003 was then selected. The interaction inventory is in tests/INTERACTIONS.md;
coverage additions use real controls and isolated data. Initial Clear/Undo failures
were narrowed to test input before outgoing delegates retired. Settled mouse/touch
Undo passes with no app changes; UI-015 retains the transition-time validation
candidate. The user accepted closure of QA-003 on 2026-10-31 with its documented
platform/dictation limits retained under QA-001/QA-002. The user clarified
selector-popup Back priority: dismiss only the popup first. All three selectors
fail that native regression; UI-016 tracks the app fix separately.

UI-016 selected on 2026-10-31. Outside press dismissed the selector before
Android delivered Back, which then closed the drawer too. Modal popups now wait
for outside release; Back routing is unchanged. Six QML cases fail before the
fix and all 17 focused cases pass afterward, including native Windows rendering.
Full Windows verification passes all four entries (157 UI/19 flow/6 keyboard/61
model records); all 26 native left/right checks pass. Shared-key ARM64 APK is
ready. The user confirmed the fix on an Android emulator on 2026-11-01 and
requested closure and commit; UI-016 is resolved. No physical-phone confirmation
is claimed.
