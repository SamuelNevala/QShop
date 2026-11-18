# Google Play listing draft

Prepared 8 November 2026; still **not uploaded**. Copy describes current
one-handed shopping, deliberate swipes and the shopper's own order.

## Copy for Console

| Field | File | Limit |
| --- | --- | ---: |
| Name | [title.txt](en-US/title.txt) | 30 |
| Short description | [short-description.txt](en-US/short-description.txt) | 80 |
| Full description | [full-description.txt](en-US/full-description.txt) | 4,000 |
| Test notes | [release-notes.txt](en-US/release-notes.txt) | Track-specific |

Paste contents as plain text. Proposed title: **QShopper: Shopping List**;
QShopper alone remains an option. Starting locale: en-US; translate accepted copy.
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
| Phone screenshots | Four actual 1080 × 1920 portrait RGB PNG/JPEG captures; pending |

Store icon is a full square without baked mask/shadow; Play supplies its treatment.
SVG keeps launcher paths/placement and replaces its circular backdrop. Regenerate
at 512 px through Qt SVG/grabToImage, as in the [launcher exporter](../../artwork/UX-006/export.qml).
[Icon specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications),
[asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151).

Feature graphic: existing market illustration, clear focal area, **Your list.
Your shopping order.** Check crop/readability at phone size.

### Screenshot sequence

Use the same disposable groceries/palette; exclude real lists and notifications.

| Order | Caption | Real capture / alt text |
| --- | --- | --- |
| 1 | Swipe through your shopping | Large item names, two checked items below remaining groceries |
| 2 | Add it where it belongs | Movable editor between groceries, Android keyboard open |
| 3 | Correct a mistaken removal | Edit mode with removed item and visible Undo countdown |
| 4 | Choose your colors | Same list in Dark theme, drawer theme/primary/accent choices |

Existing [Light](../../docs/images/shopping-light.png)/[Dark](../../docs/images/shopping-dark.png)
captures are references, not upload-ready: 1440 × 3120 RGBA exceeds the 2:1 ratio
and uses alpha. Recapture rather than stretching. Screenshots must show actual
features, not simulated interfaces. Review copy/assets against the accepted build.

Undo is temporary and does not survive reload/list switch. Voice typing belongs
to the keyboard. Do not claim sharing, automatic aisles, barcode/price tracking.
