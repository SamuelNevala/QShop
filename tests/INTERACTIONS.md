# QShopper interaction coverage

QA-003 inventory, 2026-10-31. Map the implemented UI, including cancellation and
recovery. A passing model test is supporting evidence, not proof that a control
or gesture works. Direct model calls in UI fixtures only arrange test data.

`qml/` is the existing offscreen suite; `flows/` uses the real application window
and actual controls in a separate repeatable CTest entry. Native Windows runs
check the same flows with real rendering. `keyboard/` loads the real desktop VKB.
Android scripts drive only the isolated emulator and use disposable data/settings.
UI-023's `rendering/tst_undopopup.qml` is the native Windows/WARP CTest entry
for the full-background countdown, fixed touch area, pause/restart and draft focus.
Older ticket evidence is mapped here without claiming every native matrix was
rerun during QA-003. See the run record below for what actually ran.

## Shopping and mode changes

| Interaction / state | Automated path and observable result | Android coverage |
| --- | --- | --- |
| Slow left/right swipe past half width; quick shorter swipe | `qml/tst_swipe.qml::test_swipe_action` exercises mouse/touch, shopping/edit modes, and verifies the actual check/delete result | `android/test_swipes.py`: eight direction/mode/distance/velocity cases |
| Short slow stroke and deliberate pullback do nothing | `tst_swipe.qml::test_rejected_swipe` checks no action delivery, unchanged rows/checks and returned position | `test_swipes.py --rejections --gesture-jar ...`: eight cases; one continuous pointer for pullback |
| Readable cart/bin and arrow during real held swipes | `swipecontrast/tst_swipecontrast.qml`: actual touch, both directions/modes/check states/themes, four backgrounds, live palette changes and action/Undo outcomes; offscreen and native Windows D3D11 WARP CTest entries | `test_swipecontrast.py`: 20 explicit/System profiles, actual held feedback pixels, cancel preserving exact data, then committed check/delete |
| Check stack and nearby correction with either direction | `flows/tst_userflows.qml::test_correction`: real swipes, exact visible order and checked flags | `test_back.py --matrix`: checking/correction after interrupted Back; `test_reset.py`: exact stack order |
| Shopping single/double tap is not a check or mode change | `UserFlows::test_shopping_taps_are_not_checks` | Native dedicated tap-only control not yet added |
| Pull down to enter/leave edit mode; insufficient pull rejected | `UserFlows::test_mode_pull_threshold`: actual touch movement crosses the resisted pulley's geometry, then observes mode/data | Existing native swipe/Back/reset scripts enter edit mode through a real pull; both directions of mode change are not a dedicated Android matrix |
| Long list, both scroll directions, empty/short list, editor/removal/resize | `tst_listbackground.qml`, `tst_safeborder.qml`: real flicks plus geometry/pixel assertions | `test_listbackground.py`, with `--keyboard` for actual Gboard/insets |
| Ten background images, slideshow forward/reverse, portrait crop and themes | `backgrounds/tst_backgrounds.qml`: packaged resources, decoded dimensions, cycle, resize and production row previews; native Windows CTest renders actual fonts | `test_backgrounds.py`: all ten actual slideshow frames in both themes, matched against exports; exact list data retained |
| Readable day number, selected icons/captions and Undo text on colored fills | `contrast/tst_filledcontrast.qml`: all 19 families, Light/Dark, four button display modes, actual glyphs and Undo fill/underlay samples; offscreen and native Windows CTest | `test_filledcontrast.py`: real held day-header pull, selected theme button and deletion/Undo in six explicit/System/palette profiles; exact list data restored |
| Custom colored labels/icons, selector focus and slider boundary | `customcolors/tst_customcolors.qml`: all 19 families, both themes, actual drawer inheritance, native System, live bindings and actual glyph/border pixels | `test_customcolors.py`: real held header/pulley, pressed editor icon, thumb and both license tabs with isolated data |
| Custom colored labels/icons, selector focus and slider boundary | `customcolors/tst_customcolors.qml`: all 19 families, both themes, actual drawer inheritance, native System, live bindings and actual glyph/border pixels | `test_customcolors.py`: real held header/pulley, pressed editor icon, thumb and both license tabs with isolated data |
| Readable selected Lists/Accent/Primary popup captions | `popupcontrast/tst_popupcontrast.qml`: all 19 accents in Light/Dark, representative System modes, keyboard highlight, current-index and live palette changes, real glyphs, retained font and swatches; normal/native CTest | `test_popupcontrast.py`: six palette/explicit/System profiles, actual caption pixels, popup-only Back and exact saved data |
| Solid Undo surface above inverse checked rows | `rendering/tst_undopopup.qml::test_opaque_surface_over_checked_row`: white/black/colored underlays, empty/half progress, both themes/scales | `test_filledcontrast.py --checked-underlay`: actual 27-item mixed list, uncovered surface pixels after eight seconds, normal text/icon and exact Undo restoration |
| Large short names and bounded long/unbroken names | `tst_textfitting.qml`, including native Windows actual-font run; Qt `Text.Fit` with three-line cap | `test_textfitting.py`: actual foreground bands, font-size controls and unchanged saved names |

## About and licenses (UI-012)

`about/tst_about.qml` runs in the normal `qshopper_about_tests` CTest entry.
Actual drawer activation, both complete documents, scroll endpoints, both themes,
safe-margin/viewport resizing and Back/Close retain the drawer, draft and exact
item IDs/order/checks. Eleven records also cover open/switch latency, logo readiness, body touch/mouse
swipes, header/footer geometry, display modes, non-selection and keyboard activation. Native Windows checks
actual caption fitting; offscreen's dummy font cannot certify it. QTest compares
complete reconstructed notices with their bundled resources. Android checks cover
offline headers and accessible final paragraphs, native scrollbar endpoints, safe
bounds, theme pixels, IME state and both Back edges (26 checks). The normal
qshopper_about_rendering_tests entry compares actual antialiased logo pixels with
the default geometry renderer. It uses disposable emulator data
and restores network state; commands are in README.md and ANDROID.md.
User confirmed the final feature works on the phone on 2026-11-05.

## Editing, deletion and list management

| Interaction / state | Automated path and observable result | Android coverage |
| --- | --- | --- |
| Tap a row to position the editor, then insert there | `UserFlows::test_insert_edit_and_clear_through_controls`: actual tap, typing/Return, exact order | `test_entry.py`: actual tap/insertion and exact saved order |
| Double tap, replace an existing name and submit | Same flow, actual double touch and Ctrl+A/typing/Return; order survives a new window | `test_entry.py`: actual double tap/replacement and preserved ID; `test_reset.py --case pending` also opens checked-row edits |
| Clear draft using editor's X; empty Return | Same flow; source rows remain unchanged | `test_entry.py`: actual editor X and Gboard Return |
| Long-press reorder and drop | `UserFlows::test_reorder_drop_persists`: actual hold/drag/drop, exact order and new-window persistence | `test_back.py --matrix`: actual order after deliberate reorder/restore controls |
| Checked row ignores single tap and long-press reorder | `UserFlows::test_checked_row_does_not_reorder` | `test_entry.py`: checked-row tap/hold leaves order and editor intact |
| Cancel before/during hold, reorder or horizontal swipe; recover immediately | `tst_cancel.qml::test_cancel` sends TouchCancel and checks parenting/state/no action plus next gesture; `tst_back.qml` has key-routing controls | `test_back.py --matrix` covers both system edges, keyboard states, initial holds and recovery; crossing several rows before cancellation remains an additional permutation |
| Right swipe in edit mode deletes; Undo restores | `UserFlows::test_delete_and_undo_icon`: actual swipe and editor icon, exact visible order | `test_entry.py`: native single-delete and actual Undo, including exact restored records |
| Remove checked from drawer; Undo restores checked stack | `UserFlows::test_drawer_removal:checked`: actual drawer button and icon, order/checks | `test_reset.py --case remove`: SQLite names/order/checks/IDs |
| Clear list from drawer; Undo restores | `UserFlows::test_drawer_removal:all`: actual mouse/touch Undo after all departing delegates settle; full restoration assertions | `test_reset.py --case clear`: passing native touch control |
| Remove checked with no checks is a no-op | `UserFlows::test_remove_checked_without_checks_is_noop` | Generic native no-check action not yet added |
| Post-reset cleanup: Undo only the latest action; repeat for earlier actions | `ModelTest::post_reset_cleanup_undoes_one_action`, mutation/bulk/redo-branch cases; `UndoRecovery::test_post_reset_cleanup_undoes_one_swipe_at_a_time` uses actual swipes/taps and a shared non-extended clock | `test_reset.py --case cleanup`: exact names/IDs/order/checks after every Undo and restart |
| Post-reset cleanup: Undo only the latest action; repeat for earlier actions | `ModelTest::post_reset_cleanup_undoes_one_action`, mutation/bulk/redo-branch cases; `UndoRecovery::test_post_reset_cleanup_undoes_one_swipe_at_a_time` uses actual swipes/taps and a shared non-extended clock | `test_reset.py --case cleanup`: exact names/IDs/order/checks after every Undo and restart |
| Undo expires at its actual timeout | `UserFlows::test_undo_expires`: real 15-second timer and retained deletion; `rendering/tst_undopopup.qml`: full-background countdown, geometry, themes and pause/restart | `test_undorecovery.py`: actual expiry, rendered bar, keyboard and background/resume |
| Scroll, tap, move editor and submit while Undo is available | `qml/tst_undorecovery.qml`: actual offscreen-editor deletion, scroll, movement, submission and recovery; `UserFlows::test_other_interaction_preserves_undo` | `test_undorecovery.py`: scrolling, two separate deletion/Undo steps, new entry, exact IDs/order/flags and retained native keyboard |
| Reset checks, including mixed/pending edits and repeated Reset | `tst_reset.qml::test_drawer_reset`: real checks, drawer Reset, exact resulting order, retained draft and new window | `test_reset.py` default four cases: exact/mixed/pending and per-action cleanup, with force-stop/relaunch persistence |
| Open list catalog through selector; create, rename, delete and Undo a list | `UserFlows::test_catalog_create_rename_delete_undo`: actual selection/entry/edit/delete/Undo, unchanged list ID and preserved contents | `test_entry.py`: native create/rename/delete/Undo/select, unchanged UUID and independent list contents |
| Switch lists, reopen selector, restore saved selection | `tst_listselection.qml`: actual popup clicks, distinct contents, saved UUID and fresh engine/new window | `test_popups.py --selector lists --restart`: actual cold restart |

## Keyboard and navigation

| Interaction / state | Automated path and observable result | Android coverage |
| --- | --- | --- |
| Repeated text entry with Return and empty Return retains keyboard | `keyboard/tst_keyboard.qml::test_enter_keeps_keyboard_open_with_composed_input`: real VKB keys, explicit preedit/commit control and empty VKB Return | `test_entry.py`: actual English QWERTY Gboard letter/Return keys, empty Return, SQLite rows and native IME visibility |
| Hide keyboard, reopen through editor | `DevelopmentKeyboard::test_hide_button_and_reopen_preserve_window_and_input` | `test_back.py` and `test_entry.py`: native keyboard state and retained draft |
| Open drawer from editor dismisses keyboard; return keeps draft | `UserFlows::test_drawer_and_popup_dismissal_preserve_draft`; real keyboard dismissal also mapped in `tst_keyboard.qml` (that older case opens drawer by signal) | `test_entry.py` actual editor menu icon; `test_portrait.py` draft survives drawer close/rotation |
| Drawer outside click and Escape; popup Escape without changing selection | `UserFlows::test_drawer_and_popup_dismissal_preserve_draft` | Outside click covered by native entry/portrait scripts. `test_back.py --selector-back --edge left/right` asserts popup-only dismissal, then drawer-only Back; all 26 UI-016 checks pass with drafts/settings/data preserved |
| Back: drawer, keyboard, edit mode, background; unfinished replacement | `tst_back.qml`, real-key routing with only desktop platform gate overridden; real desktop VKB Back case | `test_back.py`: actual system edge gestures, live process/background return and saved rows. `test_entry.py` also verifies pending replacement cancellation through native Back, preserving original text/ID |
| Cancelled Android edge gesture must not leak a hold or break next swipe | `tst_cancel.qml` desktop control; domain tests alone are insufficient | `test_back.py --matrix` + `BackGesture.java`, UI-007 evidence: 69 native checks |
| Voice/dictation | App-side commit/continuous-entry behavior is covered by VKB and native Gboard entry | **Open validation gap:** no controlled speech/audio fixture; recognizer/network/permission behavior and voice punctuation/correction require manual or purpose-built native validation. Microphone is not activated by tests |

## Drawer settings, layout and desktop controls

| Interaction / state | Automated path and observable result | Android coverage |
| --- | --- | --- |
| Click Light/Dark/System; foreground/background follow effective theme | `UserFlows::test_settings_through_controls` clicks every choice and checks saved values. `tst_safeborder.qml` samples surfaces but changes theme programmatically | `test_safeborder.py --drawer`: real app selections and OS scheme changes, matching explicit palettes, system-bar contrast, resume and IME |
| Choose Accent/Primary; endpoints, scrolling and safe bounds | `tst_popupsafearea.qml` clicks real options; `UserFlows::test_settings_through_controls` checks stored values | `test_popups.py`: actual swipes/taps; `--restart` now verifies color as well as list restoration |
| Change sensitivity using slider; gesture effort and saved value | `tst_swipesensitivity.qml` drags real handle and retries same gesture; `UserFlows` writes through control | `test_entry.py` taps actual slider, checks native range value and cold-restored value |
| Cold restore selected theme | Desktop checks verify stored selection; new window in one engine is not proof of a fresh singleton | `test_entry.py`: explicit Light survives real process restart and renders light surface; cold System choice is not a separate case |
| Popup resize/zoom/open/close warning safety | `tst_combobox.qml` directly opens popups for geometry stress; endpoint test adds actual activation | `test_popups.py --matrix` adds real IME resize and rotated-device request |
| Portrait while launching/rotating, keyboard/drawer and draft | Desktop manifest review cannot certify Android | `test_portrait.py`: sensor-driven Android Settings rotation control, live app geometry, data/draft/process invariants |
| Preview Page Up/Down, Ctrl+0 and geometry; scale/position restoration | `tst_preview.qml`, `tst_persistence.qml`, `tst_theme.qml` | Android/release gate checked by sizing/build tests; preview shortcuts are desktop-only |
| Desktop VKB build gate, hide/reopen, resize and zoom | `tst_keyboard.qml` with real plugin; ordinary suite checks disabled layout gate | Android uses system IME; no InputPanel scaling is applied there |

## Remaining work and interpretation

QA-003 was **closed by user acceptance on 2026-10-31**. Core interactions have substantially more
control-driven coverage, but the explicitly listed native permutations and real
dictation are gaps, not passing claims. Selector-popup Back policy is clarified;
UI-016 subsequently fixes the native regression (26 left/right checks pass). Additional native
expiry/invalidation permutations remain identified; real dictation needs a
controlled speech fixture or manual validation. Physical
one-handed shopping, dictation quality and multi-device readability remain
QA-001/QA-002 validation work. User acceptance closes this coverage pass with
those limits recorded; it does not certify the unverified interactions.

UI-015 is a transition-time input validation candidate, not a confirmed bug in
the settled path. Early tests pressed before outgoing delegates retired. The
final flow waits for actual whole-list readiness and retains all restoration
assertions without XFAIL/skip markers. No application changes are bundled here.

## Repeatable runs

```powershell
./tools/verify-windows.ps1
```

This configures/builds and runs UI, user-flow, real desktop keyboard and model
CTest entries. The new flow entry has its own 120-second timeout; existing suite
timeouts remain unchanged. Reports are under `out/windows-agent/tests`.

For actual Windows rendering, with the Qt kit on PATH:

```powershell
Remove-Item Env:QT_QUICK_BACKEND -ErrorAction SilentlyContinue
./out/windows-agent/qshopper_ui_tests.exe -input tests/flows -import out/windows-agent -o out/qa003/flows-native.txt,txt
```

New/strengthened native commands (run serially; they share one emulator):

```powershell
python tests/android/test_swipes.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/qa003-swipes
python tests/android/test_swipes.py --adb C:/android/sdk/platform-tools/adb.exe --rejections --gesture-jar out/android-emulator/back-gesture/gesture.jar --output out/android-emulator/qa003-rejections
python tests/android/test_back.py --adb C:/android/sdk/platform-tools/adb.exe --selector-back --output out/android-emulator/qa003-popup-back-policy
python tests/android/test_entry.py --adb C:/android/sdk/platform-tools/adb.exe --output out/android-emulator/qa003-entry
python tests/android/test_reset.py --adb C:/android/sdk/platform-tools/adb.exe --case clear --output out/android-emulator/qa003-clear
python tests/android/test_reset.py --adb C:/android/sdk/platform-tools/adb.exe --case remove --output out/android-emulator/qa003-remove
python tests/android/test_popups.py --adb C:/android/sdk/platform-tools/adb.exe --selector accent --endpoint first --restart --output out/android-emulator/qa003-accent
python tests/android/test_popups.py --adb C:/android/sdk/platform-tools/adb.exe --selector primary --endpoint last --restart --output out/android-emulator/qa003-primary
```

Build the existing continuous-pointer helper using
`./tools/build-android-gesture-test.ps1 -SdkRoot C:/android/sdk` when needed.
The native entry test requires Pillow and the configured portrait English QWERTY
Gboard layout on QShopper_API_36. It records native insets, screenshots and key
coordinates; it rejects other IMEs. Letter/Return taps test real IME delivery,
but do not claim speech recognition or every language's composition behavior.
The same helper now injects deterministic double taps for native editing/catalog
checks, avoiding separate ADB process startup between taps. Gboard may capitalize
submitted words; preload/rename assertions compare the exact saved source text.

QA-003 run results are recorded in `tickets/QA-003.json`; reports/screenshots in
`out/qa003` and the named Android output directories are local evidence.

## QA-003 verification record

Final Windows workflow: 148 UI, 19 flow, 6 keyboard and 61 model records pass;
no failures, skips or expected-failure markers. All 19 native Windows flow records
also pass. Final Android runs pass 65 of 68 checks: 58 checks outside the native
Back script, plus 7 passing Back controls. Three selector-popup Back cases fail
(UI-016). The eight rejection checks passed a repeat run with the final helper.
These are the original QA-003 results. The subsequent UI-016 fix passes all
13 checks from each edge (26 total); its focused QML Back/touch file passes all
17 records, with six failing-before outside-touch cases. The user confirmed the
fix on an Android emulator on 2026-11-01 and accepted closure of UI-016.
Reports: `out/qa003/verify-final.txt`, `out/qa003/flows-native-final.txt`, and each
native command's `results.json`. No application code changed.

The user selected popup-only dismissal, leaving the drawer open until the next
Back. The strict final regression fails for Lists, Accent and Primary: all close
the drawer too. An earlier observational run left Accent open; it did not assert
the chosen policy and is superseded as acceptance evidence. Editor and saved
items remain intact. The later UI-016 fix changes selector popup dismissal to
outside release with modal delivery; native left/right runs now pass, including
the following drawer-only Back and unchanged draft/settings/list controls.

For a manual dictation check, create a disposable list, dictate two entries
(including quantities/punctuation and the user's normal language), submit each
with Return, and check that the keyboard remains open without duplicated/lost
text. Exercise correction/composition cancellation, keyboard hide/reopen and
drawer dismissal, then restart and inspect saved text. Record device, IME,
recognizer configuration and results. This is a manual validation procedure,
not an automated speech-recognition result.
