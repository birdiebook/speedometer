"""Draws the app icon: the dial from docs/FORM.md, reduced to what reads at 60 px (BESLUT B12).

    python3 tools/ikon.py

Writes App/Assets.xcassets/AppIcon.appiconset/icon-1024.png (1024 x 1024, no alpha, as App Store requires).
Drawn at 4x and scaled down for smooth edges. Needs Pillow.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

S = 4  # supersampling
N = 1024 * S
CX, CY = N / 2, 548 * S
WHITE, GREY, AMBER, BLACK = (255, 255, 255), (99, 99, 102), (255, 179, 64), (0, 0, 0)


def point(r, deg):
    t = math.radians(deg)
    return CX + r * S * math.sin(t), CY - r * S * math.cos(t)


def stroke(draw, a, b, width, colour):
    draw.line([a, b], fill=colour, width=width * S)
    for p in (a, b):  # round caps
        r = width * S / 2
        draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=colour)


def main():
    img = Image.new("RGB", (N, N), BLACK)
    d = ImageDraw.Draw(img)
    # The scale: 240 degrees, a major tick every 10 units of 60, a minor one between (METOD M6, fewer ticks).
    for v in range(0, 61, 5):
        deg = -120 + v * 4
        major = v % 10 == 0
        stroke(d, point(392, deg), point(392 - (88 if major else 44), deg), 30 if major else 16,
               WHITE if major else GREY)
    # The top-speed marker: a triangle pointing inwards, just past the needle.
    m = 66
    d.polygon([point(404, m), point(468, m - 5.5), point(468, m + 5.5)], fill=AMBER)
    # The needle at 37.5 on the scale, clear of the ticks, and the hub.
    n = 30
    stroke(d, point(-56, n), point(288, n), 30, WHITE)
    r = 50 * S
    d.ellipse([CX - r, CY - r, CX + r, CY + r], fill=WHITE)
    r = 19 * S
    d.ellipse([CX - r, CY - r, CX + r, CY + r], fill=BLACK)
    out = Path(__file__).resolve().parent.parent / "App/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
    img.resize((1024, 1024), Image.LANCZOS).save(out)
    print(out.relative_to(out.parents[3]))


if __name__ == "__main__":
    main()
