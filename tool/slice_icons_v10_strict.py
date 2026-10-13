import os
import shutil
import numpy as np
from PIL import Image

def slice_strict(src_path, out_dir, suffix="_v10"):
    src = Image.open(src_path).convert("RGBA")
    arr = np.asarray(src)
    alpha = arr[:, :, 3]

    rows = (alpha > 5).any(axis=1)
    ys = np.where(rows)[0]
    y0, y1 = ys.min(), ys.max()

    pad_y = 6
    y0 = max(0, y0 - pad_y)
    y1 = min(arr.shape[0]-1, y1 + pad_y)
    
    W = arr.shape[1]
    N_COLS = 10
    bounds = [round(i * W / N_COLS) for i in range(N_COLS + 1)]

    os.makedirs(out_dir, exist_ok=True)
    web_dir = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\web\assets\assets\images\categories"
    flutter_dir = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\flutter_assets\assets\images\categories"
    os.makedirs(web_dir, exist_ok=True)
    os.makedirs(flutter_dir, exist_ok=True)

    names = ["phong_tro", "can_ho", "nha_o", "o_ghep", "mat_bang",
             "van_phong", "kho_van", "khong_gian", "luu_tru", "dat_cho_thue"]

    for i, name in enumerate(names):
        x0, x1 = bounds[i], bounds[i+1]
        tile = src.crop((x0, y0, x1, y1 + 1))
        out_name = f"{name}{suffix}.png"
        out_path = os.path.join(out_dir, out_name)
        tile.save(out_path, "PNG", optimize=True)
        shutil.copy2(out_path, os.path.join(web_dir, out_name))
        shutil.copy2(out_path, os.path.join(flutter_dir, out_name))
        print(f"Saved {out_name} size={tile.size}")

if __name__ == "__main__":
    SRC = r"C:\Users\PHD\.gemini\antigravity-ide\brain\32dd7bf9-9f89-45a1-92d3-c1d7b5950639\.user_uploaded\media_1789927085303.png"
    OUT = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\categories"
    slice_strict(SRC, OUT, suffix="_v10")
