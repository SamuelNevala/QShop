# Android launcher icon

Selected direction: round icon, the default Green accent and Font Awesome's
page-and-pen artwork. The first-launch Dark theme resolves Green to `#69F0AE`;
the foreground is `#121212`. The launcher icon stays recognizable regardless of
the user's in-app palette.

`file-pen.svg` is the original Font Awesome Free Solid **7.3.1** artwork,
Copyright 2026 Fonticons, Inc., licensed under **CC BY 4.0**. Its URL and hash
are recorded in `sources.json`. The path is unchanged; derived assets recolor,
scale and center it. The full license/attribution is bundled in
`app/licenses/FontAwesome.txt` and available offline in About.

The original path extends below its upstream 512-high viewBox. The derived
geometry retains the whole pen descender. Adaptive vectors use a 108 dp canvas;
the painted foreground stays inside Android's central 66 dp safe circle. Legacy
PNGs use a round, transparent-corner background at all six Android densities.
API 26+ gets separate vector foreground/background layers. API 33+ also gets a
monochrome layer for themed icons. Launchers own the final adaptive mask, so
devices may display a circle or another system-selected shape.

References: [Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive),
[upstream artwork](https://github.com/FortAwesome/Font-Awesome/blob/7.3.1/svgs/solid/file-pen.svg).

## Regeneration

From the repository root, with the normal Windows test build available:

```powershell
python tools/update-launcher-icon.py
$env:PATH = 'C:/Qt/6.12.0/msvc2022_64/bin;' + $env:PATH
$env:QT_QUICK_BACKEND = 'rhi'
$env:QSG_RHI_BACKEND = 'd3d11'
$env:QSG_RHI_PREFER_SOFTWARE_RENDERER = '1'
./out/windows-agent/qshopper_ui_tests.exe -input artwork/UX-006/export.qml -import out/windows-agent -platform windows
python tests/test_launcher_icon.py
```

The export uses Qt's SVG renderer and `Item.grabToImage` to preserve alpha.
`preview.png` is a 512 px review image; the APK uses the Android resources.
