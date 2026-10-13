"""
Slice the 16 diorama icons directly from the reference sheet in Downloads
("Bộ biểu tượng diorama pastel 3D") and write them as the main-screen
feature icons (icon_0.png .. icon_15.png).

The sheet is a 4x4 grid. We detect the grid gutters from the alpha
projection, crop each cell, trim to its opaque content, pad to a square
canvas, then resize to 96x122 (matching the existing feature-icon size)
and save to the app assets + build dirs.

This reproduces the reference style EXACTLY (no redrawing).
"""

import os
import numpy as np
from PIL import Image

SRC = r"C:\Users\PHD\Downloads\Bộ biểu tượng diorama pastel 3D аанацҳауеит.png"

ROOT = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend"
OUT_DIR = os.path.join(ROOT, r"assets\images\features\split_icons")
BUILD_DIRS = [
    os.path.join(ROOT, r"build\flutter_assets\assets\images\features\split_icons"),
    os.path.join(ROOT, r"build\web\assets\assets\images\features\split_icons"),
]
for d in [OUT_DIR, *BUILD_DIRS]:
    os.makedirs(d, exist_ok=True)

W, H = 96, 122
SS = 4                      # supersample target for crisp downscale
TW, TH = W * SS, H * SS

# ---------------------------------------------------------------- load
im = Image.open(SRC).convert("RGBA")
arr = np.array(im)
alpha = arr[:, :, 3]
opaque = alpha > 16

# ---------------------------------------------------------------- grid
def runs(proj, thresh):
    out, inrun, s = [], False, 0
    for i, v in enumerate(proj):
        if v > thresh and not inrun:
            inrun, s = True, i
        elif v <= thresh and inrun:
            inrun = False
            out.append((s, i - 1))
    if inrun:
        out.append((s, len(proj) - 1))
    return out

col = opaque.sum(axis=0)
row = opaque.sum(axis=1)
col_runs = runs(col, max(2, col.max() * 0.02))
row_runs = runs(row, max(2, row.max() * 0.02))
print("cols:", len(col_runs), "rows:", len(row_runs))
assert len(col_runs) == 4 and len(row_runs) == 4, "expected a 4x4 grid"

# ---------------------------------------------------------------- slice
def trim_to_content(cell):
    a = np.array(cell)
    m = a[:, :, 3] > 16
    ys, xs = np.where(m)
    if len(xs) == 0:
        return cell
    return cell.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def pad_square(cell, margin=0.06):
    """Pad the trimmed cell onto a transparent square canvas with a small
    margin so every icon has consistent visual weight."""
    cw, ch = cell.size
    side = int(max(cw, ch) * (1 + margin * 2))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(cell, ((side - cw) // 2, (side - ch) // 2))
    return canvas


idx = 0
for (ry0, ry1) in row_runs:
    for (cx0, cx1) in col_runs:
        cell = im.crop((cx0, ry0, cx1 + 1, ry1 + 1))
        cell = trim_to_content(cell)
        cell = pad_square(cell)
        # resize to supersampled target then downscale for smooth edges
        big = cell.resize((TW, TH), Image.Resampling.LANCZOS)
        out = big.resize((W, H), Image.Resampling.LANCZOS)
        name = f"icon_{idx}.png"
        out.save(os.path.join(OUT_DIR, name), "PNG", optimize=True)
        for bd in BUILD_DIRS:
            out.save(os.path.join(bd, name), "PNG", optimize=True)
        print(f"  saved {name}  (from cell {cell.size})")
        idx += 1

print(f"Done. {idx} icons written to {OUT_DIR}")
