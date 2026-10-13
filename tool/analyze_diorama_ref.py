"""Analyze the pastel 3D diorama reference sheet in Downloads.

The sheet is a grid of diorama icons. We:
  * report overall size
  * find non-transparent bounding box
  * detect grid rows/cols by scanning alpha projections
  * crop each cell, report size + dominant palette
  * save each cell to tool/_ref_cells/ for inspection
"""
import os
from collections import Counter
import numpy as np
from PIL import Image

SRC = r"C:\Users\PHD\Downloads\Bộ biểu tượng diorama pastel 3D аанацҳауеит.png"
OUT = os.path.join(os.path.dirname(__file__), "_ref_cells")
os.makedirs(OUT, exist_ok=True)

im = Image.open(SRC).convert("RGBA")
W, H = im.size
print("sheet size:", W, H)

a = np.array(im)
alpha = a[:, :, 3]
opaque = alpha > 16

# bounding box of content
ys, xs = np.where(opaque)
if len(xs) == 0:
    print("no opaque content")
    raise SystemExit
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
print("content bbox:", (x0, y0, x1, y1), "w", x1 - x0 + 1, "h", y1 - y0 + 1)

# column / row projections to find gutters
col = opaque.sum(axis=0)
row = opaque.sum(axis=1)


def runs(proj, thresh):
    """Return list of (start,end) contiguous runs where proj>thresh."""
    out = []
    inrun = False
    s = 0
    for i, v in enumerate(proj):
        if v > thresh and not inrun:
            inrun = True
            s = i
        elif v <= thresh and inrun:
            inrun = False
            out.append((s, i - 1))
    if inrun:
        out.append((s, len(proj) - 1))
    return out


col_runs = runs(col, max(2, col.max() * 0.02))
row_runs = runs(row, max(2, row.max() * 0.02))
print("col runs:", len(col_runs), col_runs)
print("row runs:", len(row_runs), row_runs)


def dominant(img, k=8):
    arr = np.array(img)
    al = arr[:, :, 3]
    m = al > 200
    if m.sum() == 0:
        return []
    px = arr[m][:, :3]
    # quantize to 16 levels
    q = (px // 16 * 16)
    c = Counter(map(tuple, q))
    return c.most_common(k)


# crop cells from row_runs x col_runs
cells = []
for ri, (ry0, ry1) in enumerate(row_runs):
    for ci, (cx0, cx1) in enumerate(col_runs):
        cell = im.crop((cx0, ry0, cx1 + 1, ry1 + 1))
        cells.append((ri, ci, cell))

print("cells:", len(cells))
for ri, ci, cell in cells:
    name = f"r{ri}_c{ci}.png"
    cell.save(os.path.join(OUT, name))
    dom = dominant(cell, 6)
    print(f"  {name:10s} size={cell.size} dom={dom}")
