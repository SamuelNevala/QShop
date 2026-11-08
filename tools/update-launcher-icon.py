"""Rebuild launcher SVG/Android vectors from the pinned Font Awesome artwork.

Run the Qt export in artwork/UX-006/README.md afterward to refresh PNGs.
No network access or third-party Python packages are required.
"""

from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "artwork/UX-006"
RES = ROOT / "android/res"


def main():
    source = ET.parse(ART / "file-pen.svg").getroot()
    path = source.find("{http://www.w3.org/2000/svg}path").attrib["d"]
    attribution = "Font Awesome Free 7.3.1 file-pen, CC BY 4.0; attribution: artwork/UX-006/README.md."
    (ART / "launcher.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72">\n'
        f'<!-- {attribution} -->\n'
        '<circle cx="36" cy="36" r="36" fill="#69F0AE"/>\n'
        '<g transform="translate(5.4 11.52) scale(0.09)">'
        f'<path fill="#121212" d="{path}"/></g>\n</svg>\n', encoding="utf-8")
    drawable = RES / "drawable"
    drawable.mkdir(exist_ok=True)
    for name, color in (("foreground", "#121212"), ("monochrome", "#FFFFFF")):
        (drawable / f"icon_{name}.xml").write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            f'<!-- {attribution} -->\n'
            '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n'
            '    <group android:scaleX="0.09" android:scaleY="0.09" android:translateX="23.4" android:translateY="29.52">\n'
            f'        <path android:fillColor="{color}" android:pathData="{path}" />\n'
            '    </group>\n</vector>\n', encoding="utf-8")
    print("Updated launcher SVG and Android foreground/monochrome vectors.")


if __name__ == "__main__":
    main()
