"""
slice_icons_v8.py
=================
Slice the transparent 3D icon strip (`icons_transparent.png`) into 10 equal
columns and export them as `*_v8.png` category assets.

CRITICAL RULES (learned from a previous failure)
------------------------------------------------
* DO NOT compute a per-icon bounding box and tight-crop each icon. That
  destroys the relative scale and the shared ground baseline of the 3D set.
* DO compute ONE global bounding box on the Y axis only (trim the empty
  space above and below the whole strip).
* DO split the width into 10 EQUAL columns ("chia đều tăm tắp"). Every icon
  therefore keeps its original scale and all icons sit on the same plane.

Output: StayHub_frontend/assets/images/categories/<name>_v8.png
"""

from __future__ import annotations

import os
import shutil

import numpy as np
from PIL import Image

# --------------------------------------------------------------------------- #
# Paths
# --------------------------------------------------------------------------- #
ROOT = r"c:\Users\PHD\Desktop\StayHub"
SRC = os.path.join(ROOT, "icons_transparent.png")

ASSET_DIR = os.path.join(ROOT, "StayHub_frontend", "assets", "images", "categories")
BUILD_WEB_DIR = os.path.join(
    ROOT, "StayHub_frontend", "build", "web", "assets", "assets", "images", "categories"
)
BUILD_FLUTTER_DIR = os.path.join(
    ROOT, "StayHub_frontend", "build", "flutter_assets", "assets", "images", "categories"
)

# Left-to-right order mapped to the required file names.
NAMES = [
    "phong_tro",      # 1  Nhà mái xanh
    "can_ho",         # 2  Chung cư cao tầng xanh
    "nha_o",          # 3  Nhà mái ngói cam
    "o_ghep",         # 4  Giường tầng
    "mat_bang",       # 5  Cửa hàng mặt tiền
    "van_phong",      # 6  Tòa nhà văn phòng
    "kho_van",        # 7  Kho xưởng mái vòm
    "khong_gian",     # 8  Phòng làm việc chung
    "luu_tru",        # 9  Khách sạn Hotel
    "dat_cho_thue",   # 10 Đất trống có pin map
]

N_COLS = 10
ALPHA_THRESHOLD = 8      # alpha above this counts as "content"
PAD_TOP = 6              # small breathing room kept above content
PAD_BOTTOM = 6           # small breathing room kept below content


def global_y_bounds(alpha: np.ndarray) -> tuple[int, int]:
    """
    Scan the WHOLE image and return the global (y_min, y_max) of any pixel
    that has meaningful alpha. This trims only the empty top/bottom margins
    of the entire strip — never per icon.
    """
    rows = (alpha > ALPHA_THRESHOLD).any(axis=1)
    ys = np.where(rows)[0]
    if len(ys) == 0:
        raise RuntimeError("no content found in source image")
    return int(ys.min()), int(ys.max())


def main() -> int:
    if not os.path.isfile(SRC):
        raise SystemExit(f"source not found: {SRC}")

    src = Image.open(SRC).convert("RGBA")
    W, H = src.size
    print(f"[1/4] loaded {SRC}  size={W}x{H}")

    arr = np.asarray(src)
    alpha = arr[:, :, 3]

    # --- Global Y bounding box (whole strip) --------------------------------
    y0, y1 = global_y_bounds(alpha)
    y0 = max(0, y0 - PAD_TOP)
    y1 = min(H - 1, y1 + PAD_BOTTOM)
    crop_h = y1 - y0 + 1
    print(f"[2/4] global Y bounds: {y0}..{y1}  (height {crop_h} of {H})")

    # --- 10 equal-width columns --------------------------------------------
    # Use exact integer boundaries so the columns tile the full width with no
    # gap and no overlap. Widths differ by at most 1 px (2167 / 10 = 216.7).
    bounds = [round(i * W / N_COLS) for i in range(N_COLS + 1)]
    widths = [bounds[i + 1] - bounds[i] for i in range(N_COLS)]
    print(f"[3/4] equal columns: widths={widths}  (sum={sum(widths)})")

    os.makedirs(ASSET_DIR, exist_ok=True)

    written = []
    for i, name in enumerate(NAMES):
        x0, x1 = bounds[i], bounds[i + 1]
        # Crop: full column width, global Y band only. NO per-icon tight crop.
        tile = src.crop((x0, y0, x1, y1 + 1))
        out_path = os.path.join(ASSET_DIR, f"{name}_v8.png")
        tile.save(out_path, "PNG", optimize=True)
        written.append((name, tile.size, out_path))
        print(f"      [{i + 1:2d}] {name}_v8.png  x={x0}-{x1 - 1}  size={tile.size}")

    # --- Sync build caches --------------------------------------------------
    print("[4/4] syncing build caches ...")
    for d in (BUILD_WEB_DIR, BUILD_FLUTTER_DIR):
        if os.path.isdir(os.path.dirname(d)):
            os.makedirs(d, exist_ok=True)
            for name, _, src_path in written:
                shutil.copy2(src_path, os.path.join(d, f"{name}_v8.png"))
            print(f"      copied 10 files -> {d}")
        else:
            print(f"      [skip] not present: {d}")

    print(f"\n[OK] wrote {len(written)} icons to {ASSET_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
