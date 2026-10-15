#!/usr/bin/env python3
"""Generate the Cetli app icon: a paper slip with lines and a check mark on a green background.

Run from the repository root:  python3 tool/generate_icons.py   (requires Pillow)
Output:
  assets/branding/cetli-icon-1024.png                            – source image / preview
  android/app/src/main/res/mipmap-*/ic_launcher.png              – legacy (round) icon
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png   – adaptive icon foreground
  android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png   – Android 13+ themed icon
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/values/ic_launcher_background.xml
"""
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND = (23, 70, 58)      # #17463A
PAPER = (255, 248, 231)        # #FFF8E7
INK = (43, 58, 53)             # #2B3A35
CHECK = (46, 158, 107)         # #2E9E6B
SS = 4                         # supersampling for anti-aliasing

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}


def stroke(draw, pts, width, fill):
    draw.line(pts, fill=fill, width=int(width), joint="curve")
    r = width / 2
    for x, y in pts:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def symbol(size, ratio, background=None, mono=False):
    """The slip symbol on a size×size canvas; one unit = size × ratio / 100 (the slip is 72×92 units)."""
    s = size * SS
    img = Image.new("RGBA", (s, s), background + (255,) if background else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = s * ratio / 100
    cx, cy = s / 2, s / 2

    def p(x, y):
        return (cx + x * u, cy + y * u)

    paper = (255, 255, 255, 255) if mono else PAPER
    cut = (0, 0, 0, 0)
    ink = cut if mono else INK
    check = cut if mono else CHECK

    d.rounded_rectangle((*p(-36, -46), *p(36, 46)), radius=9 * u, fill=paper)
    for y, x1 in ((-26, 22), (-8, 22), (10, 4)):
        stroke(d, [p(-22, y), p(x1, y)], 6 * u, ink)
    if not mono:
        # a paper-coloured halo keeps the check readable where it leaves the slip
        stroke(d, [p(4, 25), p(15, 36), p(38, 8)], 19 * u, PAPER)
    stroke(d, [p(4, 25), p(15, 36), p(38, 8)], 10 * u, check)
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
    symbol(1024, 0.68, BACKGROUND).save(ROOT / "assets/branding/cetli-icon-1024.png")

    for name, k in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        # legacy icon: 48 dp, round
        circle_mask(symbol(round(48 * k), 0.68, BACKGROUND)).save(folder / "ic_launcher.png")
        # adaptive foreground: 108 dp canvas, the symbol stays inside the 66 dp safe zone
        symbol(round(108 * k), 0.50).save(folder / "ic_launcher_foreground.png")
        # themed (single colour) icon: white slip, lines and check cut out
        symbol(round(108 * k), 0.50, mono=True).save(folder / "ic_launcher_monochrome.png")

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
        '    <color name="ic_launcher_background">#17463A</color>\n'
        '</resources>\n', encoding="utf-8")
    print("Icons generated.")


if __name__ == "__main__":
    main()
