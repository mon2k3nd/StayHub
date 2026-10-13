import os
import shutil
import numpy as np
from PIL import Image

def slice_transparent_strip(src_path, out_dir, suffix="_v10"):
    if not os.path.isfile(src_path):
        print(f"Source not found: {src_path}")
        return

    src = Image.open(src_path).convert("RGBA")
    arr = np.asarray(src)
    alpha = arr[:, :, 3]

    rows = (alpha > 5).any(axis=1)
    ys = np.where(rows)[0]
    if len(ys) == 0:
        print("No content found.")
        return
    y0, y1 = ys.min(), ys.max()

    pad_y = 10
    y0 = max(0, y0 - pad_y)
    y1 = min(arr.shape[0], y1 + pad_y)

    cols = (alpha > 5).any(axis=0)
    segments = []
    in_seg = False
    start = 0
    for x in range(len(cols)):
        if cols[x] and not in_seg:
            in_seg = True
            start = x
        elif not cols[x] and in_seg:
            in_seg = False
            segments.append((start, x))
    if in_seg:
        segments.append((start, len(cols)))

    n_icons = len(segments)
    print(f"Found {n_icons} icons in {src_path}")

    segments = [(s, e) for s, e in segments if e - s > 20]
    n_icons = len(segments)
    print(f"Filtered to {n_icons} icons")

    max_w = max([e - s for s, e in segments])
    uniform_w = max_w + 10

    os.makedirs(out_dir, exist_ok=True)
    
    web_dir = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\web\assets\assets\images\categories"
    flutter_dir = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\flutter_assets\assets\images\categories"
    os.makedirs(web_dir, exist_ok=True)
    os.makedirs(flutter_dir, exist_ok=True)

    names = ["phong_tro", "can_ho", "nha_o", "o_ghep", "mat_bang",
             "van_phong", "kho_van", "khong_gian", "luu_tru", "dat_cho_thue"]

    for i, (s, e) in enumerate(segments):
        if i >= 10: break
        cx = (s + e) // 2
        x0 = cx - uniform_w // 2
        x1 = x0 + uniform_w

        tile = Image.new("RGBA", (uniform_w, y1 - y0), (0, 0, 0, 0))
        src_x0 = max(0, x0)
        src_x1 = min(arr.shape[1], x1)
        dst_x0 = src_x0 - x0
        
        cropped = src.crop((src_x0, y0, src_x1, y1))
        tile.paste(cropped, (dst_x0, 0))

        name = names[i]
        out_name = f"{name}{suffix}.png"
        
        out_path = os.path.join(out_dir, out_name)
        tile.save(out_path, "PNG", optimize=True)
        
        shutil.copy2(out_path, os.path.join(web_dir, out_name))
        shutil.copy2(out_path, os.path.join(flutter_dir, out_name))

if __name__ == "__main__":
    SRC = r"C:\Users\PHD\.gemini\antigravity-ide\brain\32dd7bf9-9f89-45a1-92d3-c1d7b5950639\.user_uploaded\media_1789927085303.png"
    OUT = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\categories"
    slice_transparent_strip(SRC, OUT, suffix="_v10")
