# QShopper design

Optimize for **one-handed shopping in the shop**: deliberate actions, nearby
correction, readable text and the shopper's own route. The phone app is portrait;
Android's large-screen overrides are a platform limit, not a landscape redesign.

## Deliberate gestures

Horizontal swipes with pullback replace small checkboxes. A right swipe checks
in shopping mode and deletes in edit mode; preserve the working left correction
path. Trigger through sufficient velocity **or more than half the row width**, so
slow deliberate drags work too. Higher sensitivity makes activation easier.

Gravity is **666.67 mm/s²** at the current 100% default, matching the accepted
150%-effort trial of the previous setting. Keep these defaults until the separate
[110% real-shopping trial](tickets/UX-007.json) is accepted.

Green check/uncheck and red delete feedback stay independent of primary/accent.
Cart/bin shapes, direction and pullback carry meaning without relying on color
alone. Black bodies and outlined white arrows preserve contrast. Animations and
translucent feedback are intentional, not decoration to remove during cleanup.

Android haptics mark every below-to-above mode-pull threshold crossing and the start
of a recognized horizontal swipe. During one held touch, cue again only when the
row crosses its resting centre into the opposite action; same-side pullback stays
silent. Shopping check/uncheck and edit-mode delete use
Confirm; edit-mode check/uncheck use ToggleOn/ToggleOff. A
pullback can still have its initial cue. Add pickup/drop cues for moving rows, a
tick for each dragged-row index change, and editor arrival at a tapped destination.
Displaced neighbours stay silent. Avoid duplicate
completion cues and startup/reload feedback. Respect system touch-feedback settings;
keep visual feedback sufficient when vibration is unavailable or disabled.
Undo uses Confirm; an actual recovery expiry uses one Reject warning cue.
Pausing or cancelling the clock must not emit the expiry cue.

## Ordering and correction

Checked items form a first-in/last-out stack: the newest stays nearest unchecked
items. Reset reverses only the checked group into collection order, leaving
unchecked entries first. For unchecked A,B and checked C,D, Reset gives A,B,D,C.
Reset twice must not reverse again. Pending edits retain their item identity/text;
a free editor insertion point stays in place. Persist the resulting order.

Undo reverses **one deletion action** at a time: one swipe, Remove checked or
Clear list. Each new deletion and each Undo that exposes an earlier action
restarts one shared **15-second** window. Expiry clears remaining recovery;
undoing the last step hides/stops it. A new deletion replaces undone future steps
while preserving earlier pending steps. There is no Undo-all/history screen.

Typing, submission, scrolling, checks and editor movement preserve recovery.
Pause the clock while the drawer blocks input or the app is inactive. Successful
list reload/switch ends recovery; failed loads preserve it. Restore by identities
and neighbors without overwriting later edits or surviving order.

The floating Undo bar stays reachable above the IME/bottom safe area, independent
of the editor. Its entire area is tappable. Keep its text/icon/outer geometry
fixed while the opaque accent countdown recedes over a fully opaque, normal
unchecked-row background. Preserve normal text color and readable fill contrast;
do not let checked rows show through. Use the ProgressBar as Popup.background.

## Sizing and text

Reference row/touch height: **9.27 mm**. Use `Theme.pixels(mm)` for geometry and
`Theme.millimeters(px)` for gesture distances. The window's Screen.pixelDensity
is authoritative; do not multiply/divide by devicePixelRatio. Android/Release use
scale 1. Desktop Debug preview scale is adjustable and persisted separately.

Item names start large/bold at **7 mm** for glanceability. Qt `Text.Fit` shrinks
and normally wraps to two lines, with a **three-line cap** and existing ellipsis
fallback. Stored names stay intact. Do not add a separate font scaler, uniformly
shrink short names or enlarge the fixed row for long entries.

## Entry and navigation

The shopper remembers items in any order and moves the editor to insert them in
route order. Do not impose categories or shop-layout sorting. Catalog sorting is
separate from shopping order. Keep the editor accessible above the keyboard and
retained when scrolled away: the list caches about 40 reference rows per side.

Return submits, clears the input and keeps the native keyboard open for continued
typing/dictation. Support composition from the selected keyboard; the app does
not activate the microphone itself.
The editor's clear button empties the draft without taking text focus or closing
an already-open keyboard.
Entering edit mode leaves the editor unfocused; tap it to start text entry.

Back closes one layer: foremost About/privacy/selector popup, drawer, keyboard,
then edit mode; in shopping mode it backgrounds the app. Hiding the keyboard
keeps the draft and releases editor text focus. Any keyboard dismissal releases
that focus; tapping the editor restores it and reopens entry. Leaving edit mode
discards unsubmitted text and restores an original item if its replacement was unfinished.

## Theme and visual continuity

Keep vivid primary/accent choices and all 19 color families. Light/Dark/System
remain independent; foreground/background are derived, without separate pickers
or a Custom theme. Use the owning control's resolved Material.theme, not raw
System, for palette decisions. Proposed coordinated presets remain optional.

Maintain readable colored text/meaningful icons against their actual surface,
including translucent photographs. Adjust local ink/fill pairs rather than
flattening the global palette. Day circles, swatches, sliders and tab underlines
retain vivid fills; selected popup captions use normal readable ink and bold.

Safe borders match normal/inverse row surfaces and theme. An open drawer dims
the exposed top/bottom safe areas with its resolved Material treatment, while
side insets retain native panel/shadow behavior. System-bar icons follow the
effective surface. Closing restores the normal 80%-opacity row surface.

Short and long lists must look continuous. Empty-area fill below delegates must
not appear between rows while scrolling. Preserve legibility, responsiveness,
animation and the original shopping-themed background series.

Decisions/evidence: [backlog](BACKLOG.md), [theme review](reviews/UX-001.md),
[color feedback](reviews/UX-002.md), [custom colors](reviews/UX-003.md),
[Undo](reviews/UX-005.md) and [interaction tests](tests/INTERACTIONS.md).
