"""Check launcher provenance, shared paths, density exports and safe-zone geometry.

Requires Pillow; native Android drawing is checked separately by IconProbe.
"""

import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"


def main():
    art = ROOT / "artwork/UX-006"
    provenance = json.loads((art / "sources.json").read_text())
    assert hashlib.sha256((art / "file-pen.svg").read_bytes()).hexdigest() == provenance["source_sha256"]
    path = ET.parse(art / "file-pen.svg").find("{http://www.w3.org/2000/svg}path").attrib["d"]
    for kind in ("foreground", "monochrome"):
        vector = ET.parse(ROOT / f"android/res/drawable/icon_{kind}.xml")
        assert vector.find("group/path").attrib[ANDROID + "pathData"] == path
    for density, size in (("ldpi", 36), ("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                          ("xxhdpi", 144), ("xxxhdpi", 192)):
        image = Image.open(ROOT / f"android/res/drawable-{density}/icon.png").convert("RGBA")
        assert image.size == (size, size)
        assert image.getpixel((0, 0))[3] == 0, "Round icon needs transparent corners"
        assert image.getpixel((size // 2, size // 10)) == (105, 240, 174, 255)
        dark = [(x, y) for y in range(size) for x in range(size)
                if image.getpixel((x, y)) == (18, 18, 18, 255)]
        assert len(dark) > size * size * .1, "Page/pen must be legible"
        assert max(((x + .5 - size / 2) ** 2 + (y + .5 - size / 2) ** 2) ** .5
                   for x, y in dark) < size * 33 / 72, "Artwork exceeds adaptive safe circle"
    manifest = ET.parse(ROOT / "android/AndroidManifest.xml").find("application")
    assert manifest.get(ANDROID + "icon") == manifest.get(ANDROID + "roundIcon") == "@drawable/icon"
    for api in (26, 33):
        adaptive = ET.parse(ROOT / f"android/res/drawable-anydpi-v{api}/icon.xml")
        assert adaptive.find("background").get(ANDROID + "drawable") == "@drawable/icon_background"
        assert adaptive.find("foreground").get(ANDROID + "drawable") == "@drawable/icon_foreground"
        if api == 33:
            assert adaptive.find("monochrome").get(ANDROID + "drawable") == "@drawable/icon_monochrome"
    print("PASS launcher paths/provenance, six round PNG exports, adaptive safe circle and themed resources")


if __name__ == "__main__":
    main()
