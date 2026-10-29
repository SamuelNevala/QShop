# QShopper design principles

QShopper is optimized for shopping in a store with one hand. The main design
choices support that situation: deliberate actions, quick correction, comfortable
touch targets, and a list that follows the shopper's route.

Use this document as a reference when changing the app's behavior or appearance.

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

The velocity trigger should work with a comfortable one-handed stroke. Higher
swipe sensitivity must make the same gesture easier to activate, while the
half-width fallback and deliberate pullback remain independent of that setting.

Phone-tested reference: on 2026-10-29, the user reported that **150% sensitivity**
felt good on the Pixel 10 Pro XL after the gravity adjustment to 1000 mm/s².
At the user's request, gravity is now **666.67 mm/s²**, making **100% sensitivity**
match that tested effort. Keep the existing sensitivity preference and half-width
fallback unchanged. The reference is not proof of the same feel on every device.

## Keep mistakes close enough to correct

Android Back closes one layer per gesture: the drawer first, then the keyboard
while editing, then edit mode. From shopping mode it backgrounds the app and
keeps the list and process available for returning. Hiding the keyboard preserves
the draft; leaving edit mode follows the existing policy of discarding unsubmitted
text and restoring the original item when cancelling an unfinished edit.

Accidental actions will still happen. The correction should require little
movement and no search through the list.

Checked items follow first-in, last-out order: the most recently checked item
stays nearest the unchecked items. This puts the most likely mistake within easy
reach. Preserve that ordering and the ability to reverse a check quickly.

Resetting checks should retain this selection-derived order for the next use,
without requiring the shopper to arrange the list again. For example, starting
with `1, 2, 3` and checking `3, 1, 2` should produce unchecked items ordered
`2, 1, 3` after reset. This order must persist when the list is reopened.

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

Shrinking the text and wrapping it across two lines are deliberate parts of the
design. Short names stay large; long entries gain room without enlarging the
reference row or requiring the user to shorten what they write. The intended
presentation accommodates both short and very long entries within the same
shopping list.

Preserve this balance when changing typography or row layout. A uniformly small
font would sacrifice glanceability, while a fixed large font with early
truncation would sacrifice the useful detail in longer entries.

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

## Applying these principles

When evaluating a change, consider whether it:

- Works comfortably with one hand in a store.
- Makes deliberate actions easy and accidental actions unlikely.
- Keeps the most recent mistake nearby and quick to correct.
- Preserves physical touch sizes across displays.
- Keeps short item names large and lets long entries shrink and wrap to two lines.
- Respects the user's list order and movable insertion point.
- Supports continuous keyboard and voice entry.
- Keeps the app's animation and visual character useful and responsive.

An implementation shortcut or a familiar UI pattern is not, by itself, a reason
to give up these choices. If a change needs a different tradeoff, make that
tradeoff explicit and discuss it with the user.
