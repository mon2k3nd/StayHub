import os
import shutil
import numpy as np
from PIL import Image

def slice_centered(src_path, out_dir, suffix="_v11"):
    src = Image.open(src_path).convert("RGBA")
    arr = np.asarray(src)
    alpha = arr[:, :, 3]

    # Global Y bounds (using low threshold to keep all shadow)
    rows = (alpha > 5).any(axis=1)
    ys = np.where(rows)[0]
    y0, y1 = ys.min(), ys.max()

    pad_y = 6
    y0 = max(0, y0 - pad_y)
    y1 = min(arr.shape[0]-1, y1 + pad_y)
    
    # Find centers using high threshold to isolate the solid buildings
    cols = (alpha > 100).any(axis=0)
    segments = []
    in_seg = False
    start = 0
    for x in range(len(cols)):
        if cols[x] and not in_seg:
            in_seg = True
            start = x
        elif not cols[x] and in_seg:
            in_seg = False
            if x - start > 10:
                segments.append((start, x))
    if in_seg:
        if len(cols) - start > 10:
            segments.append((start, len(cols)))
            
    centers = [(s+e)//2 for s, e in segments]
    print("Found centers:", centers)
    
    if len(centers) != 10:
        print(f"ERROR: Expected 10 centers, found {len(centers)}")
        return

    # Uniform crop width
    # 92 is safe enough to not include adjacent hard pixels, but wide enough for the icon
    W = 96

    os.makedirs(out_dir, exist_ok=True)
    web_dir = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\web\assets\assets\images\categories"
    flutter_dir = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\flutter_assets\assets\images\categories"
    os.makedirs(web_dir, exist_ok=True)
    os.makedirs(flutter_dir, exist_ok=True)

    names = ["phong_tro", "can_ho", "nha_o", "o_ghep", "mat_bang",
             "van_phong", "kho_van", "khong_gian", "luu_tru", "dat_cho_thue"]

    for i, name in enumerate(names):
        cx = centers[i]
        x0 = cx - W // 2
        x1 = x0 + W
        
        # We need to make sure we don't go out of bounds of the original image
        src_x0 = max(0, x0)
        src_x1 = min(arr.shape[1], x1)
        
        tile = Image.new("RGBA", (W, y1 - y0 + 1), (0, 0, 0, 0))
        dst_x0 = src_x0 - x0
        
        cropped = src.crop((src_x0, y0, src_x1, y1 + 1))
        
        # Mask out any pixels that belong to adjacent icons
        # Find the midpoint between this center and adjacent centers
        left_mid = (centers[i-1] + cx) // 2 if i > 0 else 0
        right_mid = (cx + centers[i+1]) // 2 if i < 9 else arr.shape[1]
        
        # Convert cropped to numpy to mask
        crop_arr = np.array(cropped)
        # crop_arr maps to X coordinates: src_x0 to src_x1
        for px in range(crop_arr.shape[1]):
            global_x = src_x0 + px
            if global_x < left_mid or global_x > right_mid:
                crop_arr[:, px, 3] = 0 # Transparent
                
        cropped = Image.fromarray(crop_arr)
        
        tile.paste(cropped, (dst_x0, 0))

        out_name = f"{name}{suffix}.png"
        out_path = os.path.join(out_dir, out_name)
        tile.save(out_path, "PNG", optimize=True)
        shutil.copy2(out_path, os.path.join(web_dir, out_name))
        shutil.copy2(out_path, os.path.join(flutter_dir, out_name))
        print(f"Saved {out_name} size={tile.size} center={cx}")

if __name__ == "__main__":
    SRC = r"C:\Users\PHD\.gemini\antigravity-ide\brain\32dd7bf9-9f89-45a1-92d3-c1d7b5950639\.user_uploaded\media_1789927085303.png"
    OUT = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\categories"
    slice_centered(SRC, OUT, suffix="_v11")
