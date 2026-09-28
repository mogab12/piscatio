"""Generates the launcher icons (Android legacy + adaptive, iOS) from code.

Mark: an expanded black italic "P" (Archivo, the app's number face) on deep
water, with the red notch of the trip time ruler above it (in the app, each
catch is a notch). Run from app/: `pip install pillow && python tool/build_icons.py`.
"""

import json
import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "assets/fonts/ArchivoExpanded-BlackItalic.ttf"
DEEP_WATER = (11, 42, 51)
FOAM = (241, 246, 245)
RED_HEAD = (228, 38, 44)


def draw_mark(size: int, scale: float) -> Image.Image:
    """Transparent image with the mark centered; `scale` is the share of
    the canvas the glyph block may use."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    block = size * scale
    font = ImageFont.truetype(str(FONT), int(block * 0.95))
    bbox = d.textbbox((0, 0), "P", font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    notch_h = block * 0.2
    gap = block * 0.07
    total_h = notch_h + gap + h
    top = (size - total_h) / 2
    x = (size - w) / 2 - bbox[0]
    y = top + notch_h + gap - bbox[1]
    d.text((x, y), "P", font=font, fill=FOAM)
    # Notch: downward triangle centered over the glyph's stem side.
    cx = size / 2 - w * 0.06
    half = notch_h * 0.62
    d.polygon(
        [(cx - half, top), (cx + half, top), (cx, top + notch_h)],
        fill=RED_HEAD,
    )
    return img


def full_icon(size: int, scale: float = 0.62) -> Image.Image:
    base = Image.new("RGBA", (size, size), DEEP_WATER + (255,))
    base.alpha_composite(draw_mark(size, scale))
    return base


def main() -> None:
    res = ROOT / "android/app/src/main/res"
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, factor in densities.items():
        folder = res / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        full_icon(round(48 * factor)).convert("RGB").save(folder / "ic_launcher.png")
        # Adaptive foreground: 108 dp canvas, mark inside the 66 dp safe zone.
        draw_mark(round(108 * factor), 0.48).save(folder / "ic_launcher_foreground.png")
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />\n'
        "</adaptive-icon>\n"
    )
    (res / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        '    <color name="ic_launcher_background">#0B2A33</color>\n</resources>\n'
    )

    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios / "Contents.json").read_text())
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        px = round(points * scale)
        # iOS icons must be opaque.
        full_icon(px).convert("RGB").save(ios / image["filename"])
    full_icon(1024).convert("RGB").save(ROOT / "build/icon_preview.png")


if __name__ == "__main__":
    main()
