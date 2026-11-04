"""Locate the rendered UI-023 Undo bar without waiting for accessibility idle."""

from io import BytesIO
from PIL import Image


def undo_bar_frame(raw, theme, limit=None):
    image = Image.open(BytesIO(raw)).convert("RGB")
    width, height = image.size
    limit = height if limit is None else limit
    tint = (0, 230, 118) if theme == 0 else (105, 240, 174)

    def matches(pixel, color):
        return max(abs(a - b) for a, b in zip(pixel, color)) <= 4

    spans = []
    start = None
    for y in range(max(120, limit // 2), limit):
        # The narrow leading padding stays filled and contains no text.
        # The unfilled surface is translucent, so it has no fixed RGB value.
        pixel = image.getpixel((round(width * .05), y))
        inside = matches(pixel, tint)
        if inside and start is None:
            start = y
        if not inside and start is not None:
            spans.append((start, y))
            start = None
    if start is not None:
        spans.append((start, limit))
    spans = [span for span in spans if span[1] - span[0] > 80]
    if not spans:
        return None
    top, bottom = max(spans, key=lambda span: span[1] - span[0])
    size = bottom - top
    margin = round(size * 2 / 9.27)
    left, right = margin, width - margin
    sample_y = round(top + size * .85)
    pixels = [image.getpixel((x, sample_y)) for x in range(left + 20, right - 20)]
    fraction = sum(matches(pixel, tint) for pixel in pixels) / len(pixels)
    return dict(top=top, bottom=bottom, size=size, fraction=fraction,
                action_x=round(right - size * (.5 + .5 / 9.27)), action_y=(top + bottom) // 2)
