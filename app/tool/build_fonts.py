"""Generates the static Archivo instances bundled in assets/fonts, and
fetches Shrikhand (the wordmark, already static).

The app ships static instances (not the variable masters) so rendering is
identical on every platform and in golden tests. Run from app/:

    pip install fonttools
    python tool/build_fonts.py

Sources (SIL OFL 1.1): https://github.com/google/fonts/tree/main/ofl/archivo
and https://github.com/google/fonts/tree/main/ofl/shrikhand.
"""

import pathlib
import tempfile
import urllib.request

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

BASE = "https://raw.githubusercontent.com/google/fonts/main/ofl/archivo/"
MASTERS = {
    False: "Archivo%5Bwdth,wght%5D.ttf",
    True: "Archivo-Italic%5Bwdth,wght%5D.ttf",
}

# (family file prefix, width axis value, weight, italic)
INSTANCES = [
    ("Archivo", 100, 400, False),
    ("Archivo", 100, 500, False),
    ("Archivo", 100, 600, False),
    ("Archivo", 100, 700, False),
    ("Archivo", 100, 400, True),
    ("Archivo", 100, 600, True),
    ("ArchivoExpanded", 125, 600, False),
    ("ArchivoExpanded", 125, 800, False),
    ("ArchivoExpanded", 125, 800, True),
    ("ArchivoExpanded", 125, 900, True),
    ("ArchivoCondensed", 62, 700, False),
    ("ArchivoCondensed", 62, 800, False),
]

SHRIKHAND = "https://raw.githubusercontent.com/google/fonts/main/ofl/shrikhand/"

WEIGHT_NAMES = {400: "Regular", 500: "Medium", 600: "SemiBold", 700: "Bold",
                800: "ExtraBold", 900: "Black"}


def main() -> None:
    out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "fonts"
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        masters = {}
        for italic, name in MASTERS.items():
            path = pathlib.Path(tmp) / f"master_{int(italic)}.ttf"
            urllib.request.urlretrieve(BASE + name, path)
            masters[italic] = path
        urllib.request.urlretrieve(BASE + "OFL.txt", out / "OFL.txt")
        for family, width, weight, italic in INSTANCES:
            font = TTFont(masters[italic])
            static = instancer.instantiateVariableFont(
                font, {"wdth": width, "wght": weight}, updateFontNames=False)
            suffix = WEIGHT_NAMES[weight] + ("Italic" if italic else "")
            static.save(out / f"{family}-{suffix}.ttf")
            print(f"{family}-{suffix}.ttf")
    urllib.request.urlretrieve(SHRIKHAND + "Shrikhand-Regular.ttf",
                               out / "Shrikhand-Regular.ttf")
    urllib.request.urlretrieve(SHRIKHAND + "OFL.txt", out / "OFL-Shrikhand.txt")
    print("Shrikhand-Regular.ttf")


if __name__ == "__main__":
    main()
