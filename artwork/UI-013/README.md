# UI-013 background candidates

Created 2026-11-05 using the built-in `image_gen` tool: ten initial new-generation calls, one per candidate, plus two calls replacing/refining candidate 08 at the user's request. No CLI/API fallback was used.

Open [gallery.html](gallery.html) for the numbered comparison. Click any image to open its full-size preview.

## Direction and provenance

The user's “20-” was interpreted as the 1920s. Each original shopping scene combines period clothing/interiors with one or two subtle modern details. The initial ten calls used no image inputs and requested original compositions without copied advertisements, specific likenesses or identifiable brands.

Candidate 08 was replaced with an over-the-shoulder scene showing QShopper on the phone. Its references were the original candidate 08 (style/setting), candidate 01 (new phone wallpaper), and an isolated Android test screenshot (app layout/typography only). A second call replaced the phone's decorative background with a softly painted plain shop texture to avoid retaining the screenshot's old artwork. The four legible entries are Milk, Bread, Apples and struck-through Coffee. This is a painted depiction of the app, not a pixel-exact screenshot. [Revision prompts and input roles](revisions/08-qshopper-visible.json) preserve the process and superseded output path.

[Exact prompt set](prompts.json) records every prompt and original tool output path. [Inventory](inventory.json) records native dimensions, byte sizes and SHA-256 hashes. The workspace copies were verified byte-for-byte against the generator outputs.

The user selected **all ten** on 2026-11-05. The PNGs remain unchanged at the generator's native size: candidates 01 and 08 are 916 × 1717; the other eight are 941 × 1672. Production JPEGs are 1080 × 1920, exported at quality 90 using a centered aspect-preserving crop and high-quality bicubic resampling. This is a modest upscale of the approved artwork, not newly generated detail. Candidate 08 uses the revised QShopper scene.

Run `./artwork/UI-013/export.ps1` from PowerShell on Windows to reproduce the deployment files in `app/backgrounds/`. It checks each approved PNG's SHA-256 before exporting. [Export inventory](exports.json) records source/output hashes, dimensions, encoder quality and byte sizes; repeated export was verified unchanged. The ten JPEGs total approximately 6 MB. Gallery links retain the original PNGs for provenance and comparison.

## Candidates

| Number | Scene | Modern detail |
| --- | --- | --- |
| 01 | [Phone and pantry](candidates/01-phone-and-pantry.png) | Smartphone and digital shelf label |
| 02 | [Fresh produce](candidates/02-produce.png) | Smartphone among apple and pear crates |
| 03 | [Bakery counter](candidates/03-bakery.png) | Discreet contactless payment terminal |
| 04 | [Dairy cabinet](candidates/04-dairy.png) | Modern refrigerated cabinet |
| 05 | [Bulk goods](candidates/05-bulk-goods.png) | Electronic weighing scale |
| 06 | [Market hall](candidates/06-market-hall.png) | Compact wire shopping trolley |
| 07 | [Contactless checkout](candidates/07-checkout.png) | Phone tapping a payment reader |
| 08 | [QShopper in hand](candidates/08-rainy-shopfront.png) | QShopper visible on the shopper's phone |
| 09 | [Grocer stocktaking](candidates/09-stocktaking.png) | Handheld barcode scanner |
| 10 | [Evening produce](candidates/10-evening-produce.png) | Phone and refrigerated produce case |

## Review and acceptance

All ten images were visually inspected for shopping subject matter, period/modern balance, composition and obvious rendering defects. They are intentionally cohesive painted illustrations; incidental jar/packet marks are not intended as readable labels.

`app/Background.qml` cycles all ten JPEGs in gallery order, retaining the seven-second interval, push/pop transitions and `PreserveAspectCrop`. `app/CMakeLists.txt` packages exactly those ten exports. The five old JPGs and the unused root WebP have been removed from the checkout; prior Git history is retained. PNG source artwork stays outside `app/` and is not packaged.

`tests/backgrounds/tst_backgrounds.qml` covers all ten resource URLs and decoded sizes, a complete forward/reverse slideshow cycle, resize bindings, and portrait rendering with short/long/checked production delegates in both themes. Separate offscreen and native Windows CTest entries run it. `tests/android/test_backgrounds.py` identifies each actual native slideshow frame against its exported artwork in both themes, checks order and preserves isolated shopping data. Validation results are recorded in UI-013. The user confirmed the appearance on the phone and requested ticket closure and commit on 2026-11-05; UI-013 is resolved.
