# Backlog

QShopper is near feature complete. Open work is below; resolved reports retain
their status, regressions and acceptance history in `tickets/`.

## Current work

| Ticket | Remaining work |
| --- | --- |
| [UI-037](tickets/UI-037.json) | API-36 emulator: catalog Undo hidden behind Gboard; user cannot reproduce on phone; investigate platform scope |
| [REL-001](tickets/REL-001.json) | Google Play release: publish exact sources; finish trader/payment/regional tasks, signing, migration and store testing |
| [QA-001](tickets/QA-001.json) | Remaining physical shopping/dictation validation; do not reopen already accepted subcases |
| [QA-002](tickets/QA-002.json) | Physical sizing, touch comfort and display measurements |
| [UX-007](tickets/UX-007.json) | Real-shopping trial at 110% sensitivity; defaults remain unchanged |
| [UX-008](tickets/UX-008.json) | Haptics for mode/check/delete actions; assess Undo, reorder pickup and mode-pull threshold feedback |

Finland, all eligible Play markets and adult household shoppers are confirmed.
[Release guide](RELEASE.md), [regional checklist](store/google-play/REGIONAL_CHECKLIST.md)
and [app terms](store/google-play/TERMS.md) describe the remaining decisions.
No production key, Console submission or public app release is claimed.

## Intake and closure

- Capture trigger, actual/expected behavior, severity, build and evidence.
- Distinguish observed bugs, review candidates and untested behavior.
- Reports stay in the backlog until selected; this does not authorize implementation.
- A bug closes only with a failing-before/passing-after automated regression at
  the relevant model/UI/platform level. Manual testing complements it.
- Keep IDs/status/history stable. Add new UI tickets from UI-038 onward.
- Update the ticket and index together; follow [DESIGN.md](DESIGN.md).

## Resolved history

Each linked report contains its diagnosis, fix, tests and acceptance.

### DEV

| Ticket | Completed work |
| --- | --- |
| [DEV-001](tickets/DEV-001.json) | Investigate the Qt PopupList contentWidth override diagnostic |
| [DEV-002](tickets/DEV-002.json) | Choose Qt-aligned qmlformat settings and format all project QML sources |
| [DEV-003](tickets/DEV-003.json) | Choose clang-format settings and format the project's C++ code |
| [DEV-004](tickets/DEV-004.json) | Review and simplify the CMake build files using KISS principles |
| [DEV-005](tickets/DEV-005.json) | Configure clang-tidy and Clazy, analyze the C++ code, and fix actionable findings |
| [DEV-006](tickets/DEV-006.json) | Review QML and C++ for simplicity and establish KISS-based coding guidelines |
| [DEV-007](tickets/DEV-007.json) | Replace the project proxy wrapper with Qt's QML SortFilterProxyModel |
| [DEV-008](tickets/DEV-008.json) | Overhaul Android dependency packaging and isolate production sources |
| [DEV-009](tickets/DEV-009.json) | Remove unused WheelIcon and disabled cart-wheel snippets |
| [DEV-010](tickets/DEV-010.json) | Use a layout for IconButton content and honor inherited display modes |
| [DEV-011](tickets/DEV-011.json) | Migrate Undo countdown drawing from Canvas to Qt Canvas2D |
| [DEV-012](tickets/DEV-012.json) | Update bundled Font Awesome Free to the current stable release |
| [DEV-013](tickets/DEV-013.json) | Use categorized logging and keep Release console output minimal |

### QA

| Ticket | Completed work |
| --- | --- |
| [QA-003](tickets/QA-003.json) | Expand UI tests to cover all implemented user interactions |

### UI

| Ticket | Completed work |
| --- | --- |
| [UI-001](tickets/UI-001.json) | Lists selector has a blank selection on a fresh installation |
| [UI-002](tickets/UI-002.json) | ComboBox logs a null-dimensions error during app startup |
| [UI-003](tickets/UI-003.json) | Bound shopping text using Qt built-in fitting |
| [UI-004](tickets/UI-004.json) | Critical regression: right swipes fail to select items and cannot delete in edit mode |
| [UI-005](tickets/UI-005.json) | Safe-area border and swipeable background should match and follow the theme |
| [UI-006](tickets/UI-006.json) | Android Back gesture should close the current UI layer before backgrounding the app |
| [UI-007](tickets/UI-007.json) | Android Back gesture leaks a long press and leaves an item stuck in move mode |
| [UI-008](tickets/UI-008.json) | Empty-area background rectangle appears inside the view when scrolling a long list |
| [UI-009](tickets/UI-009.json) | Reset checked items into chronological checking order |
| [UI-010](tickets/UI-010.json) | Long ComboBox option lists ignore the safe area and leave first and last options unreachable |
| [UI-011](tickets/UI-011.json) | Keep the Android application portrait-only |
| [UI-012](tickets/UI-012.json) | Add a drawer About component showing open-source licenses |
| [UI-013](tickets/UI-013.json) | Replace existing backgrounds with original shopping-themed images |
| [UI-014](tickets/UI-014.json) | Drawer Material component colors are wrong with System theme selected |
| [UI-015](tickets/UI-015.json) | Validate fast Undo while Clear-list delegates are retiring |
| [UI-016](tickets/UI-016.json) | Android Back from a selector popup also closes the drawer |
| [UI-017](tickets/UI-017.json) | Validate ArrowIcon reset/rearm and resized idle arrow position |
| [UI-018](tickets/UI-018.json) | WeekModel reports child rows despite being a flat list |
| [UI-019](tickets/UI-019.json) | WeekModel refresh skips a changed date with the same day of month |
| [UI-020](tickets/UI-020.json) | canUndo QML bindings stay stale when readOnly changes |
| [UI-021](tickets/UI-021.json) | Table cleanup drops active lists after an unsuccessful catalog read |
| [UI-022](tickets/UI-022.json) | Failed reload replaces loaded rows with incomplete data that a later edit saves |
| [UI-023](tickets/UI-023.json) | Undo is hidden with the movable editor and discarded by routine interactions |
| [UI-024](tickets/UI-024.json) | UndoBar text and icon use reversed theme colors instead of TextItem colors |
| [UI-025](tickets/UI-025.json) | Colored fills can make day numbers, selected icons and Undo text hard to read |
| [UI-026](tickets/UI-026.json) | Selected popup text has low contrast with bright accent colors |
| [UI-027](tickets/UI-027.json) | Translucent Undo background loses readability over inverse checked rows |
| [UI-028](tickets/UI-028.json) | Light-theme swipe cart icons have low contrast over translucent Green feedback |
| [UI-029](tickets/UI-029.json) | Custom colored text, pressed icons and focus borders can lose contrast |
| [UI-030](tickets/UI-030.json) | Vivid slider thumb lacks a readable boundary on the drawer surface |
| [UI-031](tickets/UI-031.json) | Cart arrow is misplaced after the Font Awesome update |
| [UI-032](tickets/UI-032.json) | Restart Undo countdown when restoring an action exposes an earlier deletion |
| [UI-033](tickets/UI-033.json) | Editor stays under the virtual keyboard after moving it to the end of a long list |
| [UI-034](tickets/UI-034.json) | Android safe-area background should follow drawer dimming |
| [UI-035](tickets/UI-035.json) | Scrolling a long list destroys the offscreen editor and closes the keyboard |
| [UI-036](tickets/UI-036.json) | Clear draft without losing editor focus or dismissing the virtual keyboard |

### UX

| Ticket | Completed work |
| --- | --- |
| [UX-001](tickets/UX-001.json) | Review primary and accent color design against Android color guidance |
| [UX-002](tickets/UX-002.json) | Evaluate red delete and green selection feedback and compare alternatives |
| [UX-003](tickets/UX-003.json) | Review primary and accent usage outside standard QML Material components |
| [UX-004](tickets/UX-004.json) | Decide between Font Awesome and bundled SVG icons, including Tabler Icons |
| [UX-005](tickets/UX-005.json) | Evaluate Undo granularity during post-reset removal of non-recurring items |
| [UX-006](tickets/UX-006.json) | Redesign the Android application icon |
