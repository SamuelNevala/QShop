# Google Play listing draft

Local draft for the English and Finnish store listings.

## Copy for Console

| Field | English (en-US) | Finnish (fi-FI) | Limit |
| --- | --- | --- | ---: |
| Name | [English title](en-US/title.txt) | [Finnish title](fi-FI/title.txt) | 30 |
| Short description | [English short description](en-US/short-description.txt) | [Finnish short description](fi-FI/short-description.txt) | 80 |
| Full description | [English full description](en-US/full-description.txt) | [Finnish full description](fi-FI/full-description.txt) | 4,000 |
| Test notes | [English test notes](en-US/release-notes.txt) | [Finnish test notes](fi-FI/release-notes.txt) | Track-specific |

Paste contents as plain text. Proposed title: **QShopper: Shopping List**;
QShopper alone remains an option. Use en-US as the default listing and add fi-FI.
Keep factual metadata without ranking/price slogans or keyword repetition.
[Setup/limits](https://support.google.com/googleplay/android-developer/answer/9859152),
[metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842).

## Settings

| Field | Prepared position |
| --- | --- |
| Type/category | App / Shopping (confirm category) |
| Payment | One-time paid build; public GPL source. Price undecided, EUR 2.99 proposed |
| Package | shopper.nevala.com; confirm availability before first upload |
| Website | [Public project](https://github.com/SamuelNevala/QShop) |
| Support | samuel.nevala@gmail.com |
| Privacy | [Published policy](https://samuelnevala.github.io/QShop/privacy-policy.html), exact anonymous HTTP 200 verified 12 November; Console field pending |
| Terms | [Published terms](https://samuelnevala.github.io/QShop/terms.html), version 18 November; anonymous HTTP 200/exact HTML verified, Console field pending |
| Publisher/markets | Finland / all eligible paid-app markets; final roster/regional checks pending |
| Audience | Adults 18+ household shoppers; separate IARC questionnaire, no rating assigned |

Account identity is verified; app creation/declarations remain open. Follow the
[regional checklist](REGIONAL_CHECKLIST.md), [Data safety](data-safety.md),
[terms review](../../reviews/REL-001-terms.md) and [release steps](../../RELEASE.md).
Core offline lists do not imply that Android backup/keyboard services never transfer data.

## Visual assets

Use the green page-and-pen identity and accepted illustrated backgrounds;
retain [artwork attribution](../../artwork/UX-006/README.md).

| Asset | Requirement / state |
| --- | --- |
| Store icon | 512 × 512 RGBA: [PNG](assets/icon.png), [editable SVG](assets/icon.svg), prepared |
| Feature graphic | 1024 × 500 RGB PNG/JPEG; brief only |
| Phone screenshots | Four 1080 × 2160 RGB JPEGs per language, captured in the Android app |

Store icon is a full square without baked mask/shadow; Play supplies its treatment.
SVG keeps launcher paths/placement and replaces its circular backdrop. Regenerate
at 512 px through Qt SVG/grabToImage, as in the [launcher exporter](../../artwork/UX-006/export.qml).
[Icon specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications),
[asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151).

For the feature graphic, use the existing market illustration and check the crop
at phone size. If it includes text, localize it for each listing.

### Screenshot sequence

Use the clean files below for the matching language in Play Console. The
[English guide](../../docs/guide.html) and [Finnish guide](../../docs/guide-fi.html)
use these same screenshots and display gesture marks on the page.

| Order | English capture and caption | Finnish capture and caption |
| --- | --- | --- |
| 1 | [Shopping](../../docs/images/guide/en/shopping.jpg) · Check items with a swipe | [Ostokset](../../docs/images/guide/fi/shopping.jpg) · Merkitse ostokset pyyhkäisemällä |
| 2 | [Editor](../../docs/images/guide/en/editor.jpg) · Add items where they belong | [Muokkaus](../../docs/images/guide/fi/editor.jpg) · Lisää tuote oikeaan kohtaan |
| 3 | [Undo](../../docs/images/guide/en/undo.jpg) · Undo a mistaken deletion | [Kumoaminen](../../docs/images/guide/fi/undo.jpg) · Kumoa vahingossa tehty poisto |
| 4 | [Drawer](../../docs/images/guide/en/drawer.jpg) · Choose your theme and colors | [Valikko](../../docs/images/guide/fi/drawer.jpg) · Valitse teema ja värit |

[Localized graphic assets](https://support.google.com/googleplay/android-developer/answer/9844778).

Undo is temporary and does not survive reload/list switch. Voice typing belongs
to the keyboard. Do not claim sharing, automatic aisles, barcode/price tracking.
