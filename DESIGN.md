# QShopper design principles

QShopper is optimized for shopping in a store with one hand. The main design
choices support that situation: deliberate actions, quick correction, comfortable
touch targets, and a list that follows the shopper's route.

Use this document as a reference when changing the app's behavior or appearance.

The Android phone app is portrait-only. Keep shopping, editing, keyboard entry
and drawer interactions in portrait when the phone rotates. Android platform
overrides on large displays are documented in ANDROID.md; portrait-only use is
the product intent, rather than a request to redesign the landscape interface.

When the drawer opens, its resolved Material dimming must extend across the
exposed system-bar safe areas. Preserve their normal 80%-opacity row surface
underneath, and restore it on close. Side insets beneath the drawer retain the
native panel/shadow treatment. System-bar icons follow the effective dimmed
palette; the user's stored Light/Dark/System selection remains unchanged.

## One-handed use and deliberate gestures

Small buttons and checkboxes are easy to hit by mistake when using a phone with
one hand while shopping. Checking an item should be easy to do deliberately and
hard to do accidentally.

Horizontal swipes with a pullback motion are the primary interaction for checking
items. The movement and return of the row provide feedback about the action.
Preserve this interaction when changing the list; a tap on a small checkbox is
not an equivalent replacement.

A deliberate swipe can trigger the item action in either of two ways: enough
velocity, or travel beyond half the delegate's width. The distance trigger must
work even for a slow drag. Right swipes select items in shopping mode and delete
them in edit mode; preserve the distinct actions and the working left-swipe path.

Keep red deletion and green checking/unchecking feedback separate from the user's
primary/accent choices. Cart/bin silhouettes and directional arrows communicate
the action without relying on color alone. UI-028 uses black cart/bin bodies and
white arrows with black outlines in both themes, preserving their contrast over
the translucent action strips without changing the existing swipe animations.

The velocity trigger should work with a comfortable one-handed stroke. Higher
swipe sensitivity must make the same gesture easier to activate, while the
half-width fallback and deliberate pullback remain independent of that setting.

Phone-tested reference: on 2026-10-29, the user reported that **150% sensitivity**
felt good on the Pixel 10 Pro XL after the gravity adjustment to 1000 mm/s².
At the user's request, gravity is now **666.67 mm/s²**, making **100% sensitivity**
match that tested effort. Keep the existing sensitivity preference and half-width
fallback unchanged. The reference is not proof of the same feel on every device.

The Monday 2026-11-09 shopping trial was successful overall. On 2026-11-11 the
user requested a further real-shopping trial at **110% sensitivity** before any
default adjustment. Keep gravity and the existing default unchanged pending
that result; [UX-007](tickets/UX-007.json) records the follow-up.

## Keep mistakes close enough to correct

Android Back closes one layer per gesture: an open About/licenses view or
drawer selector popup first (leaving the drawer open), then the drawer, then the keyboard
while editing, then edit mode. From shopping mode it backgrounds the app and
keeps the list and process available for returning. Hiding the keyboard preserves
the draft; leaving edit mode follows the existing policy of discarding unsubmitted
text and restoring the original item when cancelling an unfinished edit.

Accidental actions will still happen. The correction should require little
movement and no search through the list.

Accepted Undo visual design, 2026-11-03 (UI-023): use a
floating bar above the keyboard or bottom safe area, independent of the movable
editor. An opaque accent-color fill recedes across the whole background to show
time remaining; do not blend the fill with a translucent tint. The user's
2026-11-06 refinement (UI-027) replaces the earlier 20%-opacity surface: the
background is fully opaque and uses the normal unchecked row's resolved
Material.backgroundColor. Checked rows beneath Undo must not obscure its text
or icon. Use the ProgressBar itself as Popup.background, without the default
popup surface/elevation shadow. The accent countdown remains visible above the
solid neutral surface.
Keep the message, Font Awesome Undo arrow, outer shape and full touch area fixed.
UI-025 preserves normal TextItem foreground colors on Undo and uses a compatible,
fully opaque tone from the chosen accent color when the vivid fill would obscure
that text. The global accent shade is unchanged.
Filled current-day circles and selected buttons instead use a contrasting dark
or light foreground; captions outside the button circle keep normal theme text.
The whole bar is tappable to Undo; the Font Awesome arrow is its visual cue.
A short message identifies the removed item/count.
Use a brief slide/settle animation and keep recovery reachable while scrolling.
UX-005, selected for implementation on 2026-11-07, replaces UI-023's original
restore-all batch policy with one Undo step per deletion action. A swipe removes
one item; each explicit Remove checked or Clear list action is one bulk step.
One tap reverses only the latest action. Further taps reverse earlier pending
actions in reverse order; the message always identifies the next action to undo.
This lets a shopper correct one mistaken removal after intentionally deleting
non-recurring items following Reset checks.

Keep one shared 15-second window, restarted by each new deletion and whenever
Undo exposes an earlier pending action. The user selected this refinement on
2026-11-08 (UI-032), so an earlier mistake still gets time for correction after a
near-expiry Undo. Expiry discards every remaining recovery step. Undoing the last step
hides the bar and stops its clock. A new deletion after Undo replaces the undone
future steps while preserving earlier pending actions. There is no separate
Undo-all action, history screen or per-item timer.

Scrolling, typing, submission, checking and editor movement preserve recovery.
The clock pauses while the drawer blocks the action or the app is inactive.
Recovery belongs to the current loaded list and app process; successful reload/
list switching ends recovery, while a failed load preserves it. Preserve newer
edits and the surviving rows' order when restoring removed items by identity and
their neighboring items. Physical one-handed shopping acceptance remains a
separate complement to automated touch tests.

Checked items follow first-in, last-out order: the most recently checked item
stays nearest the unchecked items. This puts the most likely mistake within easy
reach. Preserve that ordering and the ability to reverse a check quickly.

Resetting checks should restore the chronological checking order for the next use,
without requiring the shopper to arrange the list again. For example, starting
with `1, 2, 3` and checking `3, 1, 2` produces a checked stack `2, 1, 3`;
Reset reverses that stack to unchecked `3, 1, 2`. Within that group, the first
item checked becomes the first after Reset. Persist this order when reopened.

Leave unchecked entries first. For unchecked `A, B` followed by checked `C, D`,
Reset produces `A, B, D, C`. Reverse only checked positions, leaving a free
editor insertion point in place. An item being edited participates through its
original checked state: its editor follows that item's reordered position,
retaining unfinished text and identity. Reset clears every checked flag, and a
second Reset does not reverse the already-reset items again.

## Design in millimeters

Android has too many screen sizes and densities to design a separate layout for
each display. Touch targets should retain a consistent physical size across
devices.

The reference list row height is **9.27 mm**. Use physical dimensions to guide
touch targets, spacing, and control geometry. A larger screen can show more
content; a smaller screen should not make the main interactions too small to use
comfortably.

In QML, use `Theme.pixels(millimeter)` for geometry and
`Theme.millimeters(pixels)` when interpreting gesture distances. The goal is
consistent physical usability, rather than matching pixel counts or fitting the
same number of rows on every screen.

## Large text that adapts to the entry

Item names in the shopping view start with a large, bold font so short entries
are easy to read at a glance while shopping. `TextItem` uses a reference font
size of **7 mm**.

Shrinking the text and normally wrapping it across two lines are deliberate parts
of the design. A third line is allowed for exceptionally long entries. Short
names stay large; long entries gain room without enlarging the
reference row or requiring the user to shorten what they write. The intended
presentation accommodates both short and very long entries within the same
shopping list.

Preserve this balance when changing typography or row layout. A uniformly small
font would sacrifice glanceability, while a fixed large font with early
truncation would sacrifice the useful detail in longer entries.

Use Qt's `Text.Fit` with the large reference size and `maximumLineCount: 3`.
Rely on Qt's built-in fitting and existing right-ellipsis fallback; do not add a
separate font scaler. The saved name remains intact when display text is elided.

## Write in recall order, insert in shopping order

People remember items in an arbitrary order. That should not force the shopping
list into the same order or require a separate rearranging step after every
entry.

The editor is movable. Put it where an item belongs, enter the item, then move it
to the next insertion point as needed. Keep this workflow quick and keep the
editor reachable while the keyboard is open.

The shopper controls the list order. After a few visits, they know the store's
layout and can arrange the list along their route. Shop mapping, categories, or
automatic sorting should not be required to achieve that order, and should not
override the user's arrangement.

## Keep entry fast and continuous

Use the virtual keyboard's dictation to enter items quickly. The app should work
with the keyboard's text composition and voice input.

Submitting an item keeps the keyboard open, clears the editor for the next item,
and leaves the insertion point accessible. Repeatedly reopening the keyboard
interrupts entry. The user should still be able to dismiss it deliberately.

## Keep the visual character

A flashy look, animation, and opacity are intentional parts of QShopper's design.
Movement makes checking, reordering, and pulling a row back understandable.
Opacity helps show state and interaction feedback.

Short and long lists should have a unified appearance. The background fill below
the delegates is intentional: it covers otherwise empty viewport space, but must
not appear as an intrusive block or boundary while scrolling a long list.

Preserve that character while keeping item names legible, touch targets usable,
and actions responsive. Visual changes should support the shopping interaction
without making entry or correction slower.

The vivid primary/accent treatment is intentional. On 2026-11-05 the user
explained that Qt's standard Material colors look bleak and that the shade shift
in Theme.qml was introduced to give the app stronger colors. Evaluate that shift
and its foreground/background pairings while preserving the intended vivid look;
matching muted defaults is not itself a design goal. The analysis and separate
contrast follow-ups are recorded in [UX-001](reviews/UX-001.md).

Keep System, Light and Dark independent of the selected primary/accent families.
Foreground/background colors are derived automatically; do not add independent
foreground/background pickers or a separate Custom theme mode. Keep all 19 color
families. Coordinated primary/accent presets are only a possible future convenience.
UI-026 uses readable normal popup captions with a bold current entry, preserving
the vivid swatches rather than using potentially unreadable accent-colored text.

UX-003 keeps vivid primary/accent fills separate from colored ink. When a small
label or meaningful icon needs more contrast, tint its selected color toward
black on a light neutral surface or white on a dark one. Use the owning surface,
including its opacity over photographs, rather than changing the global palette.
The current-day circle, swatches, slider fill and tab underline keep their vivid
colors. The slider thumb has a small neutral outline, thicker with keyboard
focus. A custom drawer surface must also propagate through Material.background
so descendant controls use the surface that is actually painted.

## Applying these principles

When evaluating a change, consider whether it:

- Works comfortably with one hand in a store.
- Makes deliberate actions easy and accidental actions unlikely.
- Keeps the most recent mistake nearby and quick to correct.
- Preserves physical touch sizes across displays.
- Keeps short names large and lets long entries shrink and wrap, with a three-line cap.
- Respects the user's list order and movable insertion point.
- Supports continuous keyboard and voice entry.
- Keeps the app's animation and visual character useful and responsive.

An implementation shortcut or a familiar UI pattern is not, by itself, a reason
to give up these choices. If a change needs a different tradeoff, make that
tradeoff explicit and discuss it with the user.
