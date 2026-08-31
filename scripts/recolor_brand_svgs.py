#!/usr/bin/env python3
"""Replace legacy orange/coral brand hex codes in SVGs with deeper purple #7F5FC4 (and gradient helpers).

Run from repo root:
  python3 Hare-Customer/scripts/recolor_brand_svgs.py

Run from Hare-Customer:
  python3 scripts/recolor_brand_svgs.py

Optional custom assets directory:
  python3 scripts/recolor_brand_svgs.py --assets-root /path/to/Hare-Customer/assets
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Files that must keep third-party / payment brand colors unchanged.
SKIP_FILES = frozenset({"vipps_button.svg", "mastercard.svg"})

# (source_hex_without_hash, dest_hex_without_hash) — applied case-insensitively after #.
# Order: longer / more specific first where relevant.
REPLACEMENTS: list[tuple[str, str]] = [
    # Legacy Hare orange / red-orange (solids → brand purple)
    ("ef4626", "7F5FC4"),
    ("ff401a", "7F5FC4"),
    ("ff6e51", "7F5FC4"),
    ("e92700", "7F5FC4"),
    ("f93432", "7F5FC4"),
    ("e86657", "7F5FC4"),  # coral logo paths (style="fill:#e86657")
    ("e54e01", "7F5FC4"),
    ("c63013", "6349A3"),  # legacy Android primaryDark
    # Peach / coral illustration accents (demo_dialog cheeks, etc.) → lavender
    ("ff8b7b", "E8DDF9"),
    ("ff5652", "D4C4F2"),
    ("a02724", "6349A3"),  # mouth / dark red accent → deeper purple
    # Flame / gradient oranges → purple ramp
    ("ffab00", "C9B5EF"),
    ("e15700", "6349A3"),
    ("ff9601", "B49AE8"),
    ("ff7503", "7F5FC4"),
    ("ff5f00", "9B7FD9"),
    ("ffaa01", "B8A3E8"),
    ("ffc823", "E5DCF9"),
    # Misc orange accents sometimes used in exports
    ("ff4500", "7F5FC4"),
    ("ff5722", "7F5FC4"),
    ("ff6d00", "8E6FD4"),
    ("fe5000", "7F5FC4"),
    # Yellow-gold illustration highlights (read as orange on screen, e.g. phone_verification)
    ("ffd252", "D4C4F2"),
    # Light peach / coral fills (icons, empty states) → soft lavender / bg tint
    ("ffece8", "F4F0FB"),
    ("feebe7", "E8DDF9"),
    # Warm paper/beige in illustrations → cool lavender-gray (no orange cast)
    ("ede2d3", "EDE9F7"),
]


def replace_hex_colors(content: str) -> str:
    out = content
    for src, dst in REPLACEMENTS:
        pat = re.compile(r"#" + re.escape(src), re.IGNORECASE)
        out = pat.sub("#" + dst, out)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description="Recolor brand SVG hex values to purple ramp.")
    parser.add_argument(
        "--assets-root",
        type=Path,
        default=None,
        help="Path to assets folder (default: Hare-Customer/assets next to this script)",
    )
    args = parser.parse_args()
    root = args.assets_root
    if root is None:
        root = Path(__file__).resolve().parents[1] / "assets"
    root = root.resolve()
    if not root.is_dir():
        print("assets directory not found:", root, file=sys.stderr)
        return 1

    changed_files: list[Path] = []
    for path in sorted(root.rglob("*.svg")):
        if path.name in SKIP_FILES:
            continue
        text = path.read_text(encoding="utf-8")
        new_text = replace_hex_colors(text)
        if new_text != text:
            path.write_text(new_text, encoding="utf-8")
            changed_files.append(path)

    print(f"Updated {len(changed_files)} SVG file(s) under {root}")
    for p in changed_files:
        print(" ", p.relative_to(root.parent))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
