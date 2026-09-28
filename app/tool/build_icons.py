"""Generates the launcher icons (Android legacy + adaptive, iOS) from code.

Mark: a red-and-white fishing float riding the water on deep water, with
two ripples around it, tilted at the italic angle of the wordmark. The same
float is the symbol in the app (core/widgets/brand.dart).
Run from app/: `pip install pillow && python tool/build_icons.py`.
"""

import json
import math
import pathlib

from PIL import Image, ImageChops, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEEP_WATER = (11, 42, 51)
FOAM = (241, 246, 245)
RED_HEAD = (228, 38, 44)
SS = 4  # supersampling for smooth edges
TILT = math.radians(-8)


def _cubic(p0, p1, p2, p3, steps=24):
    out = []
    for i in range(steps + 1):
        t = i / steps
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * p3[1]
        out.append((x, y))
    return out


def _egg(left, top, width, height):
    """Float profile: narrow shoulders, round belly (as in FloatPainter)."""
    cx = left + width / 2
    right = left + width
    bottom = top + height
    belly = top + height * 0.62
    pts = []
    pts += _cubic((cx, top), (cx + width * 0.34, top), (right, belly - height * 0.3), (right, belly))
    pts += _cubic((right, belly), (right, bottom - height * 0.1), (cx + width * 0.3, bottom), (cx, bottom))
    pts += _cubic((cx, bottom), (cx - width * 0.3, bottom), (left, bottom - height * 0.1), (left, belly))
    pts += _cubic((left, belly), (left, belly - height * 0.3), (cx - width * 0.34, top), (cx, top))
    return pts


def _rotate(points, center, angle):
    cx, cy = center
    c, s = math.cos(angle), math.sin(angle)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in points]


def draw_mark(size: int, scale: float, mono: bool = False) -> Image.Image:
    """Transparent image with the float and ripples centered; `scale` is the
    share of the canvas the mark may use. `mono` draws a one-color
    silhouette (Android themed icons)."""
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    block = big * scale
    cx = big / 2
    water_y = big / 2 + block * 0.12
    ink = FOAM + (255,)

    # Ripples on the surface, behind the float.
    for w, h, alpha, width in ((1.0, 0.2, 90, 0.022), (0.7, 0.13, 150, 0.026)):
        rw, rh = block * w / 2, block * h / 2
        a = 255 if mono else alpha
        d.ellipse(
            (cx - rw, water_y - rh, cx + rw, water_y + rh),
            outline=FOAM + (a,),
            width=max(1, int(block * width)),
        )

    body_w = block * 0.34
    body_h = block * 0.5
    body_top = water_y - body_h * 0.5
    left = cx - body_w / 2
    egg = _rotate(_egg(left, body_top, body_w, body_h), (cx, water_y), TILT)
    stroke = max(2, int(body_w * 0.09))

    # Antenna: a stick above the body.
    ant_h = block * 0.2
    stick = [
        (cx - stroke * 0.7, body_top - ant_h),
        (cx + stroke * 0.7, body_top - ant_h),
        (cx + stroke * 0.7, body_top + stroke),
        (cx - stroke * 0.7, body_top + stroke),
    ]
    d.polygon(_rotate(stick, (cx, water_y), TILT), fill=ink)

    if mono:
        d.polygon(egg, fill=ink)
    else:
        # Red above the waterline, white below: draw white, then clip red.
        d.polygon(egg, fill=FOAM + (255,))
        red = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        rd = ImageDraw.Draw(red)
        rd.polygon(egg, fill=RED_HEAD + (255,))
        mask = Image.new("L", (big, big), 0)
        md = ImageDraw.Draw(mask)
        # Upper half-plane of the tilted waterline.
        far = big * 2
        c, s = math.cos(TILT), math.sin(TILT)
        half = [(-far, -far), (far, -far), (far, 0), (-far, 0)]
        half = [(cx + x * c - y * s, water_y + x * s + y * c) for x, y in half]
        md.polygon(half, fill=255)
        top_half = ImageChops.multiply(red.split()[3], mask)
        img.paste(RED_HEAD + (255,), (0, 0, big, big), top_half)
        # Outline and waist band in deep water, so the float reads as an object.
        d.line(egg + [egg[0]], fill=DEEP_WATER + (255,), width=stroke, joint="curve")
        band = [(-body_w / 2, 0), (body_w / 2, 0)]
        band = [(cx + x * c - y * s, water_y + x * s + y * c) for x, y in band]
        d.line(band, fill=DEEP_WATER + (255,), width=max(2, int(stroke * 0.9)))

    # Front half of the ripples passes in front of the float: it sits in the
    # water, not on top of it.
    for w, h, alpha, width in ((1.0, 0.2, 90, 0.022), (0.7, 0.13, 150, 0.026)):
        rw, rh = block * w / 2, block * h / 2
        a = 255 if mono else alpha
        d.arc(
            (cx - rw, water_y - rh, cx + rw, water_y + rh),
            start=8,
            end=172,
            fill=FOAM + (a,),
            width=max(1, int(block * width)),
        )

    return img.resize((size, size), Image.LANCZOS)


def full_icon(size: int, scale: float = 0.78) -> Image.Image:
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
        # Adaptive layers: 108 dp canvas, mark inside the 66 dp safe zone.
        px = round(108 * factor)
        draw_mark(px, 0.62).save(folder / "ic_launcher_foreground.png")
        draw_mark(px, 0.62, mono=True).save(folder / "ic_launcher_monochrome.png")
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
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
    (ROOT / "build").mkdir(exist_ok=True)
    full_icon(1024).convert("RGB").save(ROOT / "build/icon_preview.png")


if __name__ == "__main__":
    main()
