"""Deep-analyze each diorama cell: silhouette shape, vertical mass profile,
and color-region layout so we can reproduce the composition procedurally.
"""
import os
import numpy as np
from PIL import Image

CELLS = os.path.join(os.path.dirname(__file__), "_ref_cells")


def describe(path):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    al = a[:, :, 3]
    m = al > 40
    h, w = al.shape
    ys, xs = np.where(m)
    if len(xs) == 0:
        return
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    bw, bh = x1 - x0 + 1, y1 - y0 + 1
    # vertical mass profile (10 bands)
    prof = []
    for i in range(10):
        yy0 = y0 + bh * i // 10
        yy1 = y0 + bh * (i + 1) // 10
        band = m[yy0:yy1, x0:x1 + 1]
        prof.append(round(band.mean(), 2))
    # horizontal mass profile (10 bands)
    hprof = []
    for i in range(10):
        xx0 = x0 + bw * i // 10
        xx1 = x0 + bw * (i + 1) // 10
        band = m[y0:y1 + 1, xx0:xx1]
        hprof.append(round(band.mean(), 2))
    # aspect
    ar = round(bw / bh, 2)
    print(f"{os.path.basename(path):10s} bbox={bw}x{bh} ar={ar}")
    print(f"    vprof={prof}")
    print(f"    hprof={hprof}")


for f in sorted(os.listdir(CELLS)):
    if f.endswith(".png"):
        describe(os.path.join(CELLS, f))
