#!/usr/bin/env python3
"""Shift orange/red-orange pixels in raster illustrations toward brand purple (HSV heuristic).

Requires: pip install pillow

Default targets are common in-app illustrations that are still PNG (not SVG).

Run from Hare-Customer:
  pip install pillow
  python3 scripts/recolor_brand_pngs.py
"""

from __future__ import annotations

import argparse
import colorsys
from pathlib import Path

try:
    from PIL import Image
except ImportError as e:
    raise SystemExit("Install Pillow first: pip install pillow") from e


def shift_orange_to_purple(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
    """Map red-orange / orange pixels (cart, helmet) toward brand purple ~hue 0.76."""
    if a == 0:
        return r, g, b, a
    rn, gn, bn = r / 255.0, g / 255.0, b / 255.0
    h, s, v = colorsys.rgb_to_hsv(rn, gn, bn)
    # Wider hue window: red-orange through orange (skip yellow h>~0.14).
    # Lower saturation floor catches anti-aliased edges on PNG exports.
    if 0.0 <= h <= 0.14 and s >= 0.07 and v >= 0.12:
        h = 0.76 + (h - 0.07) * 0.18
        s = min(1.0, s * 1.06)
        rn, gn, bn = colorsys.hsv_to_rgb(h, s, v)
        return int(rn * 255), int(gn * 255), int(bn * 255), a
    return r, g, b, a


def process_png(path: Path) -> bool:
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            px[x, y] = shift_orange_to_purple(*px[x, y])
    im.save(path)
    return True


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Recolor orange PNG pixels toward purple.")
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[
            root / "assets/images/blank_cart.png",
            root / "assets/images/delivered.png",
            root / "assets/images/explore.png",
            root / "assets/images/tracking.png",
            root / "assets/images/no_delivery_fee.png",
        ],
        help="PNG files to process (default: common illustration PNGs)",
    )
    args = parser.parse_args()
    done = 0
    for p in args.paths:
        p = p.resolve()
        if not p.is_file():
            print("skip (missing):", p)
            continue
        process_png(p)
        print("updated:", p.relative_to(root))
        done += 1
    print(f"Done: {done} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
