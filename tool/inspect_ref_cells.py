"""Render a labeled contact sheet of the 16 reference cells so we can map
each diorama to a feature slot. Also print per-cell color signature.
"""
import os
import numpy as np
from PIL import Image, ImageDraw

CELLS = os.path.join(os.path.dirname(__file__), "_ref_cells")
files = sorted(os.listdir(CELLS))
files = [f for f in files if f.endswith(".png")]

# build a 4x4 contact sheet with labels
cell = 260
pad = 30
sheet = Image.new("RGBA", (cell * 4 + pad * 5, cell * 4 + pad * 5), (255, 255, 255, 255))
d = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    r, c = divmod(i, 4)
    im = Image.open(os.path.join(CELLS, f)).convert("RGBA")
    im.thumbnail((cell, cell))
    x = pad + c * (cell + pad) + (cell - im.width) // 2
    y = pad + r * (cell + pad) + (cell - im.height) // 2
    sheet.alpha_composite(im, (x, y))
    d.text((pad + c * (cell + pad), pad + r * (cell + pad) - 18), f, fill=(0, 0, 0, 255))
out = os.path.join(os.path.dirname(__file__), "_ref_contact.png")
sheet.convert("RGB").save(out)
print("contact sheet:", out, sheet.size)

# per-cell signature: mean color of opaque pixels + accent colors
for f in files:
    a = np.array(Image.open(os.path.join(CELLS, f)).convert("RGBA"))
    m = a[:, :, 3] > 200
    if m.sum() == 0:
        print(f, "empty")
        continue
    px = a[m][:, :3].astype(int)
    mean = px.mean(axis=0).round().astype(int)
    # find saturated accent (max-min channel spread)
    spread = px.max(axis=1) - px.min(axis=1)
    acc = px[spread > 60]
    acc_mean = acc.mean(axis=0).round().astype(int) if len(acc) else [0, 0, 0]
    print(f"{f:10s} mean={tuple(mean)} accent={tuple(acc_mean)} n_acc={len(acc)}")
