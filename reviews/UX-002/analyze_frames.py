"""Offline color-vision review of actual QShopper component frames.

Requires NumPy and Pillow. This is an analysis artifact, not Android's display
correction/simulator or an application regression test. Matrix data: Machado,
Oliveira & Fernandes (2009), severity 100, as published in colorspacious/cvd.py:
https://raw.githubusercontent.com/njsmith/colorspacious/master/colorspacious/cvd.py
Original paper: https://doi.org/10.1109/TVCG.2009.113
"""

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


MATRICES = {
    "Protanopia": [[.152286, 1.052583, -.204868], [.114503, .786281, .099216], [-.003882, -.048116, 1.051998]],
    "Deuteranopia": [[.367322, .860646, -.227968], [.280085, .672501, .047413], [-.011820, .042940, .968881]],
    "Tritanopia": [[1.255528, -.076749, -.178779], [-.078411, .930809, .147602], [.004733, .691367, .303900]],
}


def simulate(rgb, mode):
    rgb = np.asarray(rgb, dtype=float) / 255
    linear = np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4)
    if mode == "Grayscale":
        gray = linear @ np.array([.2126, .7152, .0722])
        changed = np.repeat(gray[..., np.newaxis], 3, axis=-1)
    elif mode == "Original":
        changed = linear
    else:
        changed = linear @ np.array(MATRICES[mode]).T
    changed = np.clip(changed, 0, 1)
    encoded = np.where(changed <= .0031308, 12.92 * changed, 1.055 * changed ** (1 / 2.4) - .055)
    return np.rint(np.clip(encoded, 0, 1) * 255).astype(np.uint8)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("out/ux002"))
    parser.add_argument("--log", default="native-software.txt")
    parser.add_argument("--output", type=Path, default=Path("out/ux002/analysis"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    rows = [json.loads(line.split("UX002_DATA ", 1)[1])
            for line in (args.input / args.log).read_text(encoding="utf-8").splitlines()
            if "UX002_DATA " in line]
    assert len(rows) == 4, "Require all four validated theme/background cases"
    (args.output / "measurements.json").write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
    modes = ["Original", "Grayscale", *MATRICES]
    nominal = {mode: {name: "#" + "".join(f"{value:02x}" for value in simulate(rgb, mode))
                      for name, rgb in {"Red500": [244, 67, 54], "Green500": [76, 175, 80]}.items()}
               for mode in modes}
    (args.output / "simulation-colors.json").write_text(json.dumps(nominal, indent=2) + "\n", encoding="utf-8")
    width, height = 336, 330
    sheet = Image.new("RGB", (width * len(modes), (height + 46) * 2 + 40), "#eeeeee")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
    small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
    for index, tag in enumerate(["Light-03-bakery", "Dark-10-evening-produce"]):
        frame = Image.open(args.input / f"ux002-{tag}-settled.png").convert("RGB")
        for column, mode in enumerate(modes):
            changed = Image.fromarray(simulate(np.asarray(frame), mode))
            changed.save(args.output / f"{tag}-{mode.lower()}.png")
            draw.text((column * width + 8, index * (height + 46) + 5), mode, fill="black", font=font)
            draw.text((column * width + 8, index * (height + 46) + 27), tag.split("-", 1)[0], fill="black", font=small)
            sheet.paste(changed.resize((width, height), Image.Resampling.LANCZOS), (column * width, index * (height + 46) + 46))
    draw.text((8, sheet.height - 32), "Offline full-severity model previews; not Android correction or simulator output. Inspect full frames for icon detail.", fill="black", font=small)
    sheet.save(args.output / "comparison.png")
    for theme in ("Light", "Dark"):
        for action in ("check", "uncheck", "delete"):
            matching = [row for case in rows if case["tag"].startswith(theme)
                        for row in case["records"] if row["action"] == action]
            print(theme, action, "min", round(min(row["minContrast"] for row in matching), 3),
                  "median range", [round(min(row["medianContrast"] for row in matching), 3),
                                   round(max(row["medianContrast"] for row in matching), 3)])
    print(json.dumps(nominal, indent=2))


if __name__ == "__main__":
    main()
