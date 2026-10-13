"""Analyze the reference category icons (v11) to extract style: palette, alpha, structure."""
import os
import numpy as np
from PIL import Image

D = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\categories"
NAMES = ["phong_tro_v11.png", "can_ho_v11.png", "nha_o_v11.png", "o_ghep_v11.png",
         "mat_bang_v11.png", "van_phong_v11.png", "kho_van_v11.png", "khong_gian_v11.png",
         "luu_tru_v11.png", "dat_cho_thue_v11.png"]

for n in NAMES:
    im = Image.open(os.path.join(D, n)).convert("RGBA")
    a = np.asarray(im)
    alpha = a[:, :, 3]
    ys, xs = np.where(alpha > 10)
    if len(xs) == 0:
        print(n, "EMPTY")
        continue
    bbox = (xs.min(), ys.min(), xs.max(), ys.max())
    # opaque pixels only
    op = a[alpha > 200]
    mean = op[:, :3].mean(axis=0).astype(int)
    # dominant colors via coarse quantization
    q = (op[:, :3] // 32 * 32)
    uniq, counts = np.unique(q.reshape(-1, 3), axis=0, return_counts=True)
    order = np.argsort(-counts)[:6]
    doms = [(tuple(int(v) for v in uniq[i]), int(counts[i])) for i in order]
    print(f"{n}: size={im.size} bbox={bbox} opaque={len(op)} mean={tuple(mean)}")
    print(f"    dominant={doms}")
