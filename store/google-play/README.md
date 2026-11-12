# QShopper Google Play listing draft

English draft for the first Play test listing, prepared on 8 November 2026.
The message is one-handed shopping, deliberate swipes and the shopper's own
item order. Public copy describes the current app. Samuel confirmed Play
Console account verification on 12 November 2026. Nothing in this directory has
been uploaded to Play Console.

## Text to paste into Console

| Field | File | Limit |
| --- | --- | ---: |
| App name | [title.txt](en-US/title.txt) | 30 characters |
| Short description | [short-description.txt](en-US/short-description.txt) | 80 characters |
| Full description | [full-description.txt](en-US/full-description.txt) | 4,000 characters |
| Test release notes | [release-notes.txt](en-US/release-notes.txt) | Check the selected track's field |

Paste each file's contents, without its filename. The text is plain text;
headings in the full description do not require Markdown. The proposed title
is **QShopper: Shopping List**. The shorter **QShopper** remains an option if
you prefer the brand name alone. English (United States) is the starting locale;
translations should follow the accepted English copy.

Character limits and contact requirements follow Google's
[app setup guidance](https://support.google.com/googleplay/android-developer/answer/9859152).
Keep claims factual and avoid ranking, pricing slogans or repeated keywords;
see the [metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842).

## Suggested listing settings

| Setting | Draft |
| --- | --- |
| Type | App |
| Payment model | Paid app: one-time purchase of the official build; public source remains available |
| Price | Amount not selected; EUR 2.99 proposed as a starting price, awaiting owner decision |
| Category | Shopping; confirm in Console |
| Package ID | `shopper.nevala.com` |
| Website | Existing public source project: https://github.com/SamuelNevala/QShop |
| Tags | Choose available tags that describe shopping lists; no keyword padding |
| Public support email | Owner to supply |
| Privacy-policy URL | Prepare and publish after the release data/backup audit |
| Countries and target audience | Owner decisions still required |

Do not copy the Git author email into the public support field without the
owner choosing it. Content rating, Data safety and regional declarations are
separate Console tasks. The offline-list claim is about core list operations;
it is not a claim that Android backup or keyboard dictation never transfers
data. See [release preparation](../../RELEASE.md#8-complete-the-store-and-distribution-material).

## Visual assets

Use the existing green page-and-pen identity and the app's illustrated shop
backgrounds. Preserve their provenance and
[Font Awesome attribution](../../artwork/UX-006/README.md). Follow Google's
[preview-asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151).

| Asset | Draft direction | Status |
| --- | --- | --- |
| Store icon | 512 x 512 RGBA PNG, green square with the existing dark page-and-pen art | [icon.png](assets/icon.png); [editable SVG](assets/icon.svg) |
| Feature graphic | 1024 x 500 RGB PNG/JPEG; existing market illustration with a clear central focal area and the line below | Brief only |
| Phone screenshots | Four actual 1080 x 1920 portrait captures, RGB PNG/JPEG | Capture after copy review |

The store icon uses a full square with no baked corner mask or outer shadow;
Play applies its own treatment. This is a separate export, preserving the round
Android launcher icon. See [Play icon design](https://developer.android.com/distribute/google-play/resources/icon-design-specifications).

`icon.svg` retains the launcher artwork's path and placement, replacing only
the circular green backdrop with a full square. Export it through Qt's SVG
renderer at 512 x 512 to regenerate the RGBA PNG. The initial export used the
same `Image`/`grabToImage` approach as
[the launcher exporter](../../artwork/UX-006/export.qml); its temporary harness
and validation report are under `out/rel001/store-export` and
`out/rel001/store-content-check.json`.

Feature graphic copy: **Your list. Your shopping order.** Keep the name and
message readable when cropped. Use the existing illustration as artwork;
screenshots should show the real app rather than a simulated interface.

## Screenshot sequence

Use the same disposable list and palette so the sequence reads as one trip:
Bananas, Tomatoes, Wholegrain bread, Oat milk, Eggs, Coffee and Pasta.
Exclude personal list data and notifications. Text overlays are optional;
the captions below are proposed headlines and the last column supplies alt text.

| Order | Caption | Capture | Alt text |
| --- | --- | --- | --- |
| 1 | Swipe through your shopping | Shopping mode with several large names and two checked items | Shopping list with large item names and checked items below the remaining groceries. |
| 2 | Add it where it belongs | Movable editor between existing items, native keyboard open | Editor between grocery items, with the Android keyboard open for the next entry. |
| 3 | Correct a mistaken removal | Edit mode with one removed item and a clearly visible Undo countdown | Undo bar offering to restore a removed grocery item. |
| 4 | Choose your colors | Same list in Dark theme; show the drawer's Light, Dark and System choices | Dark shopping list with theme, primary color and accent color choices in the drawer. |

Capture a real frame of a swipe for image 1 if it stays legible; keep the item
names the focus. Do not fabricate a hand, gesture overlay or unsupported feature.
For image 2, place the editor deliberately rather than showing an empty list.

The existing [Light](../../docs/images/shopping-light.png) and
[Dark](../../docs/images/shopping-dark.png) captures are references, not upload
assets: they are 1440 x 3120 RGBA, exceeding Play's 2:1 screenshot ratio and using
an alpha channel. Recapture at the intended geometry; do not stretch them.
The four 1080 x 1920 captures also follow Google's recommended portrait format.

## Content checks before upload

- Review the proposed title, descriptions, screenshot captions and test notes.
- Supply the public support email and complete the privacy-policy audit/URL.
- Finish the feature graphic and capture the real phone screenshots.
- Review all visuals at phone size and verify text/image dimensions and formats.
- Recheck copy against the exact accepted build and selected test track.

Undo is limited to pending actions and does not survive a reload/list switch;
the draft does not promise permanent recovery. Voice typing belongs to the
Android keyboard. Do not add cloud sharing, automatic aisle sorting, barcode
scanning or price tracking to the description without implementing them.
