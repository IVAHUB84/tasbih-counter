"""
create_icons.py  —  generates placeholder PNG icons for Tasbih Counter
Run once before building:  python create_icons.py

Produces:
  resources/drawables/ic_launcher.png  (40x40, white bead symbol)
  resources/drawables/ic_reset.png     (20x20, circular arrow symbol)
  resources/drawables/ic_settings.png  (20x20, gear / dot symbol)

All icons use a transparent background (RGBA).
"""

import struct
import zlib
import os
import math


# ---------------------------------------------------------------------------
# Minimal PNG writer (no external dependencies)
# ---------------------------------------------------------------------------

def _make_png(width: int, height: int, pixels) -> bytes:
    """
    Create a PNG file in memory.

    pixels : list of (r, g, b, a) tuples, row-major, top-to-bottom.
    Returns the raw bytes of a valid PNG file.
    """
    def u32be(n):
        return struct.pack(">I", n & 0xFFFFFFFF)

    def chunk(name: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(name + data) & 0xFFFFFFFF
        return u32be(len(data)) + name + data + u32be(crc)

    # IHDR  — 8-bit RGBA
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))

    # IDAT  — raw pixel data with filter byte 0 per scanline
    raw = b""
    for y in range(height):
        raw += b"\x00"                       # filter: None
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw += bytes([r, g, b, a])

    idat = chunk(b"IDAT", zlib.compress(raw, 9))
    iend = chunk(b"IEND", b"")

    return b"\x89PNG\r\n\x1a\n" + ihdr + idat + iend


def _save(path: str, width: int, height: int, pixels) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(_make_png(width, height, pixels))
    print(f"  Created: {path}  ({width}x{height})")


# ---------------------------------------------------------------------------
# Helper drawing primitives
# ---------------------------------------------------------------------------

WHITE = (255, 255, 255, 255)
BLACK = (0,   0,   0,   255)
TRANSP = (0,  0,   0,   0)

def _blank(w, h):
    return [TRANSP] * (w * h)

def _set(pixels, w, x, y, color):
    if 0 <= x < w and 0 <= y < len(pixels) // w:
        pixels[y * w + x] = color

def _circle(pixels, w, cx, cy, radius, color, filled=False):
    for y in range(cy - radius - 1, cy + radius + 2):
        for x in range(cx - radius - 1, cx + radius + 2):
            dx, dy = x - cx, y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if filled:
                if dist <= radius:
                    _set(pixels, w, x, y, color)
            else:
                if abs(dist - radius) < 0.85:
                    _set(pixels, w, x, y, color)

def _line(pixels, w, x0, y0, x1, y1, color):
    """Bresenham line."""
    dx = abs(x1 - x0); dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    while True:
        _set(pixels, w, x0, y0, color)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy; x0 += sx
        if e2 <  dx:
            err += dx; y0 += sy

def _arc(pixels, w, cx, cy, radius, a_start, a_end, color, steps=60):
    """Arc from a_start to a_end degrees (inclusive)."""
    for i in range(steps + 1):
        t = a_start + (a_end - a_start) * i / steps
        x = int(round(cx + radius * math.cos(math.radians(t))))
        y = int(round(cy + radius * math.sin(math.radians(t))))
        _set(pixels, w, x, y, color)


# ---------------------------------------------------------------------------
# Icon designs
# ---------------------------------------------------------------------------

def make_launcher(w=40, h=40):
    """
    40x40 launcher icon:
      Black filled circle background
      White bead-string (vertical arc + dots)
    """
    p = _blank(w, h)
    cx, cy = w // 2, h // 2

    # Background circle
    _circle(p, w, cx, cy, cx - 2, BLACK, filled=True)
    _circle(p, w, cx, cy, cx - 2, WHITE, filled=False)

    # String (vertical line through centre)
    _line(p, w, cx, 6, cx, h - 6, WHITE)

    # Beads — 5 filled circles along the string
    bead_r   = 3
    bead_ys  = [8, 13, 20, 27, 32]
    for by in bead_ys:
        _circle(p, w, cx, by, bead_r, WHITE, filled=True)

    return p


def make_reset(w=20, h=20):
    """
    20x20 reset icon:
      Circular arrow (arc 30° – 330°) + arrow head
    """
    p = _blank(w, h)
    cx, cy = w // 2, h // 2
    r = 7

    # Arc (leaving a gap at the top for the arrowhead)
    _arc(p, w, cx, cy, r, 40, 320, WHITE, steps=80)

    # Arrowhead at 40° (start of arc)
    tip_x = int(round(cx + r * math.cos(math.radians(40))))
    tip_y = int(round(cy + r * math.sin(math.radians(40))))
    # Two short lines forming the arrow
    _line(p, w, tip_x, tip_y, tip_x - 3, tip_y - 2, WHITE)
    _line(p, w, tip_x, tip_y, tip_x + 1, tip_y - 4, WHITE)

    return p


def make_settings(w=20, h=20):
    """
    20x20 settings (gear) icon:
      Inner circle + 6 outer teeth
    """
    p = _blank(w, h)
    cx, cy = w // 2, h // 2

    # Inner hub
    _circle(p, w, cx, cy, 3, WHITE, filled=True)
    # Outer ring
    _circle(p, w, cx, cy, 7, WHITE, filled=False)

    # 6 radial teeth
    for deg in range(0, 360, 60):
        rad = math.radians(deg)
        x1 = int(round(cx + 5 * math.cos(rad)))
        y1 = int(round(cy + 5 * math.sin(rad)))
        x2 = int(round(cx + 9 * math.cos(rad)))
        y2 = int(round(cy + 9 * math.sin(rad)))
        _line(p, w, x1, y1, x2, y2, WHITE)

    return p


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    base = os.path.join(os.path.dirname(__file__), "resources", "drawables")

    print("Generating Tasbih Counter icons …")
    _save(os.path.join(base, "ic_launcher.png"), 40, 40, make_launcher())
    _save(os.path.join(base, "ic_reset.png"),    20, 20, make_reset())
    _save(os.path.join(base, "ic_settings.png"), 20, 20, make_settings())
    print("Done.")
