# Interaction coverage

This is a map to repeatable coverage, not a claim that every device/permutation
has passed. See [running tests](README.md) and each linked ticket for the actual
before/after results and owner acceptance. QA-003 is resolved; remaining physical
work is QA-001/QA-002 and UX-007.

| Interaction | Desktop coverage | Native Android coverage |
| --- | --- | --- |
| Enter/leave shopping or edit mode | `UserFlows`, preview/keyboard cases | `test_entry.py`, `test_back.py` |
| Insert at editor; replace by double tap; clear/empty Return | Actual control-driven flow and persistence | `test_entry.py` |
| Continuous keyboard composition/Return/hide/reopen | Real Qt keyboard suite; isolated settings | `test_entry.py`; `test_recovery_entry.py` |
| Haptics at pull threshold, swipe start/opposite-side crossing, row pickup/index/drop and editor arrival | Real held-touch flows observe `Haptics.requested`; same-side pullback is silent; ticks follow only the dragged row's index | Native Back/reorder, editor/IME checks and vibrator history; accepted on phone UX-008 |
| Clear committed/preedit text; retain focus/IME and continue entry | Real keyboard suite with mouse/touch and repeated Clear | `test_entry.py --clear-only` |
| Catalog Undo above continuously open IME | Native layout gap UI-037; currently failing | `test_entry.py --catalog-ime-only` |
| Long-press reorder; checked row rejects reorder | Flow/cancellation cases, exact order/identity | `test_back.py --matrix`; entry controls |
| Slow half-width and velocity swipe thresholds | Swipe matrix in shopping/edit and both directions | `test_swipes.py` |
| Back cancels edge press without stuck/misclassified row | TouchCancel, next-interaction/parenting checks | `test_back.py --matrix` |
| Popup/About/privacy/drawer/IME/edit Back priority | Window shortcuts and actual popup controls | `test_back.py --selector-back`; `test_about.py` |
| Individual/bulk delete, sequential Undo, expiry | Model, flow, Undo and native-rendering suites | `test_reset.py`, `test_undorecovery.py`, `test_release.py` |
| Immediate Undo during Clear-list retirement | Fast-Undo suites, real target/receiver checks | `test_fastundo.py` with a press deadline |
| Reset checked stack; pending edits; second Reset | Model and QML identity/order/storage cases | `test_reset.py` |
| List switching, fresh selection, failed load/reload | Model faults; selected UUID and fresh settings engine | Popup restart and native entry/reset cases |
| Move editor to end; open IME; scroll editor out of view | View/real-keyboard cases, 40/200-row retention | `test_recovery_entry.py --case keyboard/scroll` |
| Lists/primary/accent popup endpoints and live geometry | Popup-scroll/resize/zoom; binding loops fail | `test_popups.py --matrix` |
| Light/Dark/System and primary/accent persistence | Theme/custom-color/contrast suites | `test_safeborder.py`, `test_customcolors.py` |
| Safe borders and drawer/system-bar dimming | Rendered pixels, inverse rows and resize | Safe-border/System drawer matrix |
| Continuous empty/short/34/35/80-row background | Native/offscreen rendered row sampling | `test_listbackground.py` |
| Large text fitting/wrapping, checked styling, reuse | Production TextDelegate at widths/scales; native fonts | `test_textfitting.py` |
| Arrow replay/idle resize and cart centering | Arrow-feedback suites | `test_arrowfeedback.py` |
| Caption/display modes and disabled clicks | IconButton production content under all display modes | Android actual drawer interactions |
| Offline licenses/privacy and full scroll endpoints | Cached text roundtrip, actual drawer, antialiased logos | `test_about.py`, `--privacy`, `--application` |
| Portrait request and Back background/resume | Build gates; ordinary lifecycle cases | `test_portrait.py`, `test_back.py` |
| Zoom, fresh-engine scale and window position | Preview/persistence suites | Android/Release preview gate remains off |
| Launcher artwork | SVG/export pixel checks | `test_icon.py` |

## Limits and remaining acceptance

- Offscreen passes do not certify native font appearance or system gestures.
  Native Windows uses D3D11 WARP; Android results apply to the tested emulator.
- Dictation controls use synthetic speech and never a physical microphone.
  Actual shopper/keyboard behavior remains in [QA-001](../reviews/QA-001.md).
- Display simulations complement physical millimeter measurements and one-hand
  comfort checks in [QA-002](../reviews/QA-002.md).
- The accepted fast-Undo tests target their real animation window; ordinary
  settled-path tests must not accidentally claim that coverage.
- Known Android large-screen orientation overrides remain a platform constraint;
  a phone-emulator portrait pass does not certify tablets/foldables.
- UI-035 is owner-confirmed fixed. The later 110% sensitivity shopping trial is
  still [UX-007](../tickets/UX-007.json); preserve current defaults.

For failure reports, include the command, commit, platform, result file and exact
trigger. Keep normal data separate from fixtures. Prior test counts are dated
evidence in tickets, not minimum totals to preserve as implementations evolve.
