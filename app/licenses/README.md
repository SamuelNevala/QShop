# Offline license notices

UI-012 provides the Qt and Font Awesome notices requested by the user. Full
license texts and copyright notices are bundled; the app never downloads them.
UX-004 retained Font Awesome after the Tabler comparison. DEV-012 upgrades the
bundled Free Solid font and matching brand logo to 7.3.1.

`FontAwesome.txt` identifies the included Font Awesome 7 Free Solid 7.3.1 OTF font,
its copyright, the matching upstream distribution notice and the complete
SIL Open Font License 1.1. The upstream notice also distinguishes the SVG/code
formats. QShopper uses the font and the Font Awesome brand SVG in the About tab;
the latter has its fill changed to blue and is attributed with full CC BY 4.0 text.
UX-006 also uses the Free Solid `file-pen` SVG for the Android launcher icon.
Its recoloring/scaling and upstream source are attributed in the same notice;
the original path, hash and editable sources are in `artwork/UX-006`.
Qt's official logo identifies its tab; asset URLs, hashes and changes are recorded
in `../logos/sources.json`. Qt and logo trademarks retain their upstream ownership.

The Qt files contain Qt's copyright and full LGPL v3/GPL v3 texts, bundled
third-party copyright/attribution notices and complete standard license texts.
Qt's installed SPDX bill of materials supplies the versions, dependency graph,
copyrights and source locations. Selection starts with the Qt binaries in the
actual Android APK report and follows their runtime dependencies. Build-only
platform CMake helpers are excluded. Attribution entries shared by two Qt
targets are deduplicated by their upstream ID.

CMake packages one Qt variant under the common resource URL
`qrc:/qt/qml/QShopper/licenses/Qt.txt`:

| Build | Source text |
| --- | --- |
| Android | `Qt-Android.txt` |
| Windows without the desktop keyboard | `Qt-Windows.txt` |
| Windows with the desktop development keyboard | `Qt-Windows-Keyboard.txt` |

Android never gets the desktop keyboard notices. The Windows keyboard variant
includes Qt Virtual Keyboard's GPL v3 notice and its bundled attributions.
The Windows inventory uses the shared runtime targets plus the Windows platform
plugin; a future desktop distribution must check its actual deployed plugin set.

`manifest.json` records the Qt version, Android runtime targets, selected
attribution IDs, upstream URLs/raw-content hashes, generated-file hashes and the
font hash. Upstream legal wording and padding are retained; line endings are
normalized to LF. Git's whitespace check is disabled only for these imported
legal text files.

## Updating

The optional developer tool uses Python's standard library and downloads the
sources referenced by the installed kit. It is not part of the ordinary build.
First obtain an actual package report with `tests/test_android_package.py`
(`--report out/package-arm64.json`), then run:

```powershell
python tools/update-license-notices.py --package-report out/package-arm64.json --qt-root C:/Qt/6.12.0 --qt-version 6.12.0
```

Downloads are cached under ignored `out/ui012/license-source-cache`. Source
commits come from the Qt SBOM; a release tag is used where the kit has no commit.
SPDX's standard license-text revision is recorded in the source URLs. Review the
generated notices, IDs and hashes when changing the Qt kit, font or deployment
set. Rebuild and verify the reader on Windows and Android afterward.

LicenseNotices reads each resource once per engine and splits on double newlines.
The QML reader virtualizes non-selectable Text paragraphs in a standalone ListView with an attached scrollbar; body dragging scrolls it. It does
not repeatedly parse/layout the full Qt notice. A QTest round trip checks that
joining paragraphs recovers the exact original resource. Standard VectorImage
renders the two local SVG logos, with Qt Svg/VectorImage runtime dependencies
included in the package inventory and notices.
These notices implement the in-app notice/text requirement; source distribution,
relinking/installation arrangements and publication preparation remain REL-001.
Background provenance/replacement remains UI-013.
