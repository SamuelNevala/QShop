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
- Keep stable IDs. Add new UI reports from UI-029 onward; UI-002 is already resolved.
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
| 9 | [UX-001](tickets/UX-001.json) → [UX-002](tickets/UX-002.json) → [UX-003](tickets/UX-003.json), then [UI-005](tickets/UI-005.json) and QA-002 | UI-005 selected directly and resolved with phone confirmation; UX-001 is resolved; UX-002 and its UI-028 follow-up are resolved by user acceptance; UX-003 remains deferred. Verify typography, contrast, physical sizing and visual continuity on devices |
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
| [UI-025](tickets/UI-025.json) | Colored fills can obscure current-day numbers, selected icons and Undo text | Resolved 2026-11-06 with user confirmation: readable day/button foregrounds and compatible Undo fill preserve the vivid palette. Regressions fail before/pass after; subsequent solid-surface refinement is UI-027 | Unassigned |
| [UI-026](tickets/UI-026.json) | Selected popup captions lose contrast with bright accents | Resolved 2026-11-06 with phone confirmation: normal popup text and a bold current entry preserve vivid swatches. 116 offscreen/134 native Windows popup records and 42 Android checks pass | Unassigned |
| [UI-027](tickets/UI-027.json) | Translucent Undo becomes unreadable over checked rows | Resolved 2026-11-06 with phone confirmation: opaque normal-row background beneath the accent countdown. Original regressions fail; 14 native Windows Undo records and 16 Android checked-row checks pass | Unassigned |
| [UI-028](tickets/UI-028.json) | Light swipe cart icons are faint on translucent Green feedback | Resolved 2026-11-07: user accepted dark cart/bin bodies and white outlined arrows. All 15 Windows suites (1063 records) and 100 native Android checks pass | Unassigned |
| [UI-015](tickets/UI-015.json) | Validate fast Undo during the Clear-list animation | Input-readiness investigation: settled mouse/touch Undo passes after correcting the test driver; transition-time hit-target reproduction remains open | Unassigned |
| [UI-017](tickets/UI-017.json) | Validate ArrowIcon reset/rearm and resized idle position | DEV-006 component probe observes a continuing animation after reset and a stale idle y after resize. No rendered user-path failure established; follow-up deferred, no app change | Unassigned |
| [UI-018](tickets/UI-018.json) | WeekModel incorrectly reports child rows in a flat list | Resolved 2026-11-02: permanent QTest fails before/passes after; 269 Windows records, final model rerun, format and changed-unit analyzers pass. Committed 2260f0f1; no visible shopping-screen failure claimed | Unassigned |
| [UI-019](tickets/UI-019.json) | WeekModel skips refresh for different full dates sharing a day number | Resolved 2026-11-02: controlled-date model regression fails in three cases before/passes after; all 278 Windows records, format and changed-unit analyzers pass. Committed ccc341ea; Android suspension not simulated | Unassigned |
| [UI-020](tickets/UI-020.json) | canUndo bindings stay stale when readOnly changes | Resolved 2026-11-02: permanent QML binding regression fails before/passes after; all 284 Windows records, analyzers and formatting pass. Committed 790790d1; no normal phone-flow failure claimed | Unassigned |
| [UI-021](tickets/UI-021.json) | Cleanup drops active list tables after catalog-read failure | Resolved 2026-11-02: permanent initial/partial-read regressions fail before/pass after; all 289 Windows records, analyzers and format pass. Committed e64e008e; no phone incident established | Major |
| [UI-022](tickets/UI-022.json) | Failed reload exposes incomplete rows that a later edit saves over original data | Resolved 2026-11-03: permanent initial/partial read, editor/Undo and failed-switch regressions fail before/pass after; all 302 Windows records, analyzers and format pass. Committed 88e31d0b; no phone incident established | Major |

### [UI-023 — Reachable Undo that survives routine interaction](tickets/UI-023.json)

Resolved 2026-11-04; user accepted the finished implementation and requested
closure, APK and commit. View-owned `UndoBar.qml` uses Popup/ProgressBar and a
whole-bar TapHandler. Consecutive deletions form one recoverable batch and each
restarts 15 seconds; routine interaction preserves recovery, drafts and newer
edits. The user's separate 20%-opacity background leaves fill/text/icon solid.
The clock pauses behind the drawer or while inactive, with idle-pausing and
language-server warnings fixed. Regression-first cases reproduce the original
failures. Final verification passes all five Windows suites (331 records),
22 isolated Android checks, formatters, QML lint, translation extraction and
the unchanged analyzed C++ baseline. Signed ARM64 APK is ready in `dist/`.

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

Resolved 2026-11-05 with user phone confirmation and a request to commit.
Selected after UX-004 retained Font Awesome.
The user clarified that this feature supplies the Qt and Font Awesome license
notices. Drawer → About → Licenses opens a themed reader with both documents
bundled offline. Qt notices follow the retained runtime inventory and installed
SBOM; Android excludes desktop keyboard notices. Source URLs, hashes and the
optional regeneration tool are documented in app/licenses/README.md.
Following user review, the existing ListModel/DelegateChooser supplies a GroupBox
titled "About", containing an information IconButton captioned "Licenses".

The reader refinement replaces full-document layout with cached, virtualized
non-selectable paragraphs. Native Windows opening drops from 3,338 ms to about
300 ms, with tab rendering in 21–40 ms. The sole header is Open-source licenses; an accessible Font Awesome close
IconButton is centred in the footer. Standalone ListView body swipes work with touch
and mouse. VectorImage.CurveRenderer antialiases the Qt/Font Awesome logos. Full notice/OFL/CC BY
texts and source hashes are bundled. QTest checks exact resource round trips;
UI tests cover latency, no selection, logos, scrolling, safe areas and Back.
Native Android checks cover document headers/final paragraphs, both themes,
system Back and retained draft/data. Logo rendering intentionally adds the Qt
SVG/VectorImage runtime closure; both ABI contracts contain 53 native libraries.
Shared-key test APK:
`dist/QShopper-arm64-debug.apk`. User confirmed the final feature works on the
phone and requested closure on 2026-11-05.
Publication/source arrangements remain REL-001; background provenance remains
UI-013. Priority and severity remain unassigned.

### [UI-013 — Original shopping-themed background images](tickets/UI-013.json)

Resolved on 2026-11-05: the user confirmed the appearance on the phone and
requested closure and commit. The user chose all ten original shopping-themed images in
[the numbered gallery](artwork/UI-013/gallery.html); all ten now replace the old
packaged backgrounds in the slideshow.
The scenes interpret the requested period as the 1920s, with subtle modern phones
and shop utilities. Candidate 08 was replaced at the user's request with a scene
showing QShopper on the shopper's phone. [Prompts and provenance](artwork/UI-013/README.md) are recorded.
The approved native PNGs are retained as source artwork; reproducible JPEG exports
are 1080 × 1920. The five old JPGs and unused WebP are removed. Resource/slideshow
and portrait-rendering coverage passes on Windows; Android identifies all ten
images in both themes with saved list data unchanged. All nine Windows suites
have passing results (403 records, including an isolated general UI rerun after
an initial timeout under concurrent build load). User phone verification completes
the accepted scope.

The original request raised an unverified copyright concern about `_one.png`,
which was not found in the checkout. All existing background variants have been
replaced or removed; new artwork provenance is recorded. Release/publication
arrangements remain REL-001. Priority and severity were unassigned.

### [UI-024 — UndoBar text and icon use reversed theme colors](tickets/UI-024.json)

Resolved on 2026-11-04; user confirmed the change works and requested commit. The popup's
inverse palette made its message and icon white in Light and black in Dark.
Both now use normal TextItem foreground colors, preserving the accepted surface,
transparency and Undo behavior. Two native Windows regression cases fail before
the fix; all ten rendering records pass afterward, including live theme changes,
current System resolution and glyph pixels over full/empty progress backgrounds.

The signed ARM64 review APK is `dist/QShopper-arm64-UI-024-debug.apk`. Automated
Android rendering and separate OS-Light/OS-Dark System checks were not run;
the user did not specify a device/theme matrix for their confirmation.
This is separate from resolved UI-023; severity and priority remain unassigned.

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
| [UX-001](tickets/UX-001.json) | Analyze primary and accent color selection, derivation, and use against Android/Material color guidance | Resolved 2026-11-06: accepted [review](reviews/UX-001.md) retains vivid shades, all 19 families, automatic foreground/background and System/Light/Dark. Separate UI-025/UI-026 fixes accepted; UX-002 is resolved and UX-003 remains deferred |
| [UX-002](tickets/UX-002.json) | Evaluate red delete and green selection feedback, including color blindness and Android guidance | Resolved 2026-11-07: accepted [report](reviews/UX-002.md) retains red/green plus non-color cues. Separate UI-028 contrast fix also accepted |
| [UX-003](tickets/UX-003.json) | Review whether primary/accent usage in custom and non-Material components is sensible, readable, and consistent | Requested; review and implementation deferred |
| [UX-004](tickets/UX-004.json) | Decide between Font Awesome and bundled SVG icons, including [Tabler Icons](https://tabler.io/icons): coverage, readability, Qt/QML integration, licensing and maintenance | Resolved 2026-11-04; user accepted keeping Font Awesome and requested commit. Production experiment restored; UI-012 prerequisite satisfied. Native comparison and dependency-cost evidence in reviews/UX-004.md |
| [UX-005](tickets/UX-005.json) | Test Undo during post-reset cleanup of non-recurring items; evaluate a per-action stack instead of restoring the whole deletion batch | User reports that correcting one mistake also restores intended removals. Proposed: reverse the latest deletion action, with explicit bulk actions kept coherent. Real-phone workflow and timer/stack policy review deferred; no behavior change authorized |

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

UX-005 revisits recovery granularity using real one-handed list reuse, not only
isolated deletion tests. It links QA-001's physical shopping flow and the accepted
UI-023 batch policy; retain that implementation until a replacement is selected.
Test intentional removals followed by a mistake, repeated Undo and explicit bulk
actions while preserving the post-reset order and saved item identities.

## Code-quality work

| ID | Request | Status |
| --- | --- | --- |
| [DEV-002](tickets/DEV-002.json) | Choose a qmlformat configuration close to Qt's own QML conventions and apply it to all project QML sources, including tests and templates | Resolved 2026-11-01 with user acceptance: Qt 6.12 settings/helper applied to 54 sources; SortImports=true with preserved control selection, repeat pass stable, all four Windows suites and 19 native Windows flow records pass |
| [DEV-003](tickets/DEV-003.json) | Choose a clang-format configuration and apply it to all project-owned C++ sources and headers, including tests | Resolved 2026-11-01 with user acceptance: Qt-aligned clang-format 22.1.8 settings/helper applied to all 11 sources; repeat pass and include/token audits pass, all four Windows suites and nine native Windows cancellation records pass |
| [DEV-004](tickets/DEV-004.json) | Simplify root/test CMake using KISS and adopt the user-selected C++20 baseline | Resolved 2026-11-01; user accepted. Windows suites, selected build configurations and 13 Android emulator checks pass |
| [DEV-005](tickets/DEV-005.json) | Set up clang-tidy and Clazy with suitable checks, analyze the project, triage findings, and fix actionable issues | Resolved 2026-11-01; user accepted. All 505/100 checks retained: zero findings in 14 Windows and 10 Android analyzer runs, with narrow exceptions documented. Four Windows suites (247 records) and 47 native Android theme checks pass |
| [DEV-006](tickets/DEV-006.json) | Analyze QML and C++ for simplicity and write practical KISS-based coding guidelines grounded in the current code | Resolved 2026-11-03; user accepted closure. All 11 C++ and 56 QML/template targets reviewed, guide complete. Changes split into ten focused commits, including five independent bug fixes with regressions. Combined 302 Windows records, ten native Windows records, analyzers and formatting pass; intermediate model states also build/pass. UI-017 and other deferred tickets remain separate |
| [DEV-007](tickets/DEV-007.json) | Replace the project C++ proxy wrapper with QtQml.Models SortFilterProxyModel | Resolved 2026-11-03; user confirmed the change works and requested commit. Baseline/replacement characterization, all 308 Windows records, 12 native Windows records and 38 native Android checks pass. Wrapper removed; Qt 6.10 API alias retained and Qt 6.12 kits validated |
| [DEV-008](tickets/DEV-008.json) | Overhaul Android dependency packaging and isolate production sources | Resolved 2026-11-04; user accepted closure and requested commit. ARM64 APK 95.6 to 63.1 MB; native libraries 103 to 45. App-only scans, explicit styles/plugin selection, default-off QML tooling (always off in Release), safe staging regeneration. Both ABIs and Debug/Release/opt-in contracts pass; 331 Windows records, native Android checks and analyzers pass |
| [DEV-009](tickets/DEV-009.json) | Remove unused WheelIcon, its module registration and disabled cart-wheel snippets | Resolved 2026-11-01 at user request. File, CMake entry and inactive snippets removed; 247 Windows records, Android native build/module checks and formatting of 53 remaining QML/templates pass. Committed 2044afc5 |
| [DEV-010](tickets/DEV-010.json) | Use a layout for IconButton content and honor inherited display modes | Resolved 2026-11-03 with DEV-006 acceptance; committed cff0e6a4. Four modes, caption limits, caller sizing and clicks verified; final combined suites pass |
| [DEV-011](tickets/DEV-011.json) | Migrate Canvas drawing to QtCanvas2D.Canvas2D, starting with UndoIcon's countdown arc | Resolved 2026-11-03; user requested closure and commit. Qt 6.12 minimum and transparent Canvas2D arc. All 316 Windows records (including 8 native rendering records), original Canvas characterization and 12 native Android checks pass. Undo redesign remains UI-023 |

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
The user selected Google's C++ Style Guide as a starting point, subject to Qt and
KISS judgment rather than wholesale adoption. Review each QML file together with
its instantiation points, especially implicit sizing versus caller geometry,
anchors and Layout ownership. No-change outcomes are valid. Track progress in
[reviews/DEV-006.md](reviews/DEV-006.md); the guide is a working draft until the
source review is complete.

DEV-007 now uses QtQml.Models.SortFilterProxyModel for the drawer catalog, with
ValueFilter on checked=false and RoleSorter on name. The legacy C++ wrapper and
build registration are removed. Characterization preserves case-sensitive lexical
ordering, duplicate UUID order, the synthetic catalog entry, live changes and
active UUID selection; native Android checks include restart and catalog Undo.
The model property retains the Qt 6.10/6.11 documented API and remains an alias in
the validated Qt 6.12 kit. This type is still technology preview: recheck its API
when upgrading Qt. Qt 6.10/6.11 runtime and ARM64 were not retested. The user accepted the migration on 2026-11-03; it does not change the user's
shopping order.

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
| [UI-012](tickets/UI-012.json) | Drawer About and offline Qt/Font Awesome licenses | Resolved 2026-11-05 with user phone confirmation. Cached paragraph reader, swipe scrolling, smooth logos, consistent Close IconButton and clipped drawer; before/after regressions, 357 latest Windows records, 26 Android checks, both ABI contracts and formatting pass. Release arrangements remain REL-001 |
| [DEV-009](tickets/DEV-009.json) | Dormant cart-wheel component and commented usages | Removed file, QML registration and both disabled snippets at user request. All 247 Windows records pass; Android native build and generated resource/module audit pass; no runtime bug claimed |
| [DEV-005](tickets/DEV-005.json) | Repeatable C++ static analysis and actionable warning cleanup | Samuel baseline retained (505 clang-tidy / 100 Clazy checks); Windows/Android scans clean with documented exceptions. Property-contract regression fails before and passes after; cancellation characterization, 247 Windows records and 47 native Android checks pass. User accepted closure and commit on 2026-11-01 |
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
