#!/usr/bin/env python3
"""Generate the Cetli app icon: a dark green "C" with three list lines on a lemon background.

Run from the repository root:  python3 tool/generate_icons.py   (requires Pillow)
Output:
  assets/branding/cetli-icon-1024.png                            – source image / preview
  android/app/src/main/res/mipmap-*/ic_launcher.png              – legacy (round) icon
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png   – adaptive icon foreground
  android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png   – Android 13+ themed icon
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/values/ic_launcher_background.xml
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND = (247, 210, 72)    # #F7D248 lemon
INK = (23, 70, 58)             # #17463A dark green
WHITE = (255, 255, 255)
SS = 4                         # supersampling for anti-aliasing

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}


def stroke(draw, pts, width, fill):
    draw.line(pts, fill=fill, width=int(width))
    r = width / 2
    for x, y in pts:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def symbol(size, ratio, background=None, ink=INK):
    """The "C" with three lines on a size×size canvas; the C's outer diameter is 92 units,
    one unit = size × ratio / 100."""
    s = size * SS
    img = Image.new("RGBA", (s, s), background + (255,) if background else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = s * ratio / 100
    c = s / 2
    r, w = 46 * u, 12 * u
    gap = (42, 318)  # the C is open to the right
    d.arc((c - r, c - r, c + r, c + r), start=gap[0], end=gap[1], fill=ink, width=int(w))
    for angle in gap:  # round ends
        a = math.radians(angle)
        x, y = c + (r - w / 2) * math.cos(a), c + (r - w / 2) * math.sin(a)
        d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=ink)
    for y, x1 in ((-14, 14), (0, 14), (14, 2)):  # the list lines
        stroke(d, [(c - 14 * u, c + y * u), (c + x1 * u, c + y * u)], 6 * u, ink)
    return img.resize((size, size), Image.LANCZOS)


def circle_mask(img):
    s = img.size[0]
    m = Image.new("L", (s * SS, s * SS), 0)
    ImageDraw.Draw(m).ellipse((0, 0, s * SS - 1, s * SS - 1), fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), m.resize(img.size, Image.LANCZOS))
    return out


def main():
    (ROOT / "assets/branding").mkdir(parents=True, exist_ok=True)
    symbol(1024, 0.80, BACKGROUND).save(ROOT / "assets/branding/cetli-icon-1024.png")

    for name, k in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        # legacy icon: 48 dp, round
        circle_mask(symbol(round(48 * k), 0.80, BACKGROUND)).save(folder / "ic_launcher.png")
        # adaptive foreground: 108 dp canvas, the symbol stays inside the 66 dp safe zone
        symbol(round(108 * k), 0.64).save(folder / "ic_launcher_foreground.png")
        # themed (single colour) icon
        symbol(round(108 * k), 0.64, ink=WHITE).save(folder / "ic_launcher_monochrome.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n', encoding="utf-8")
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#F7D248</color>\n'
        '</resources>\n', encoding="utf-8")
    print("Icons generated.")


if __name__ == "__main__":
    main()
