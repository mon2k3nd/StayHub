import os
import math
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

CATEGORIES_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\categories'
BUILD_CAT_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\flutter_assets\assets\images\categories'
FEATURES_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\features'
BUILD_FEAT_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\flutter_assets\assets\images\features'

for d in [CATEGORIES_DIR, BUILD_CAT_DIR, FEATURES_DIR, BUILD_FEAT_DIR]:
    os.makedirs(d, exist_ok=True)

def create_base_floating_platform(w=512, h=512):
    """Creates an ultra-clean 3D porcelain floating platform with soft blue ambient shadow."""
    canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))

    # 1. Soft blue ambient shadow underneath
    shadow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    # Isometric soft shadow
    sdraw.ellipse([int(w*0.16), int(h*0.70), int(w*0.84), int(h*0.92)], fill=(105, 177, 255, 95))
    sdraw.ellipse([int(w*0.25), int(h*0.73), int(w*0.75), int(h*0.88)], fill=(37, 99, 235, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(w*0.042)))
    canvas = Image.alpha_composite(canvas, shadow)

    # 2. Isometric rounded bevel platform
    plat = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(plat)

    # Beveled skirt
    cx, cy = w * 0.5, h * 0.77
    rx, ry = w * 0.35, h * 0.17
    thick = int(h * 0.055)
    for dy in range(thick, -1, -1):
        ratio = dy / thick
        c_r = int(220 + 32 * (1 - ratio))
        c_g = int(230 + 24 * (1 - ratio))
        c_b = int(246 + 9 * (1 - ratio))
        pdraw.ellipse([int(cx - rx), int(cy - ry + dy), int(cx + rx), int(cy + ry + dy)], fill=(c_r, c_g, c_b, 255))

    # Top surface
    pdraw.ellipse([int(cx - rx), int(cy - ry), int(cx + rx), int(cy + ry)], fill=(252, 254, 255, 255))
    # Stepped inner tile
    pdraw.ellipse([int(cx - rx * 0.88), int(cy - ry * 0.88 - 3), int(cx + rx * 0.88), int(cy + ry * 0.88 - 3)],
                  fill=(243, 248, 255, 255), outline=(255, 255, 255, 200))

    canvas = Image.alpha_composite(canvas, plat)
    return canvas

# -------------------------------------------------------------
# 1. VAN_PHONG.PNG (Office: Wooden Desk + Lamp + Books + Chair)
# -------------------------------------------------------------
def build_van_phong():
    base = create_base_floating_platform()
    # Load authentic 3D desk crop from phong_tro_3d
    src_path = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\desk_crop.png'
    desk = Image.open(src_path).convert('RGBA')

    # Mask out the background blue wall and right bed with soft vignette
    dw, dh = desk.size
    mask = Image.new('L', (dw, dh), 0)
    mdraw = ImageDraw.Draw(mask)
    # Oval around desk, lamp, books, chair
    mdraw.ellipse([int(dw*0.12), int(dh*0.08), int(dw*0.92), int(dh*0.94)], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(12))

    desk.putalpha(mask)
    desk_scaled = desk.resize((340, 340), Image.Resampling.LANCZOS)

    # Place on platform
    base.paste(desk_scaled, (86, 95), desk_scaled)

    # Save to both paths
    p1 = os.path.join(CATEGORIES_DIR, 'van_phong.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'van_phong.png')
    base.save(p1, 'PNG')
    base.save(p2, 'PNG')
    print('Generated authentic 3D van_phong.png')

# -------------------------------------------------------------
# 2. KHONG_GIAN.PNG (Co-working / Shared Lounge: Blue Couch + Plant)
# -------------------------------------------------------------
def build_khong_gian():
    base = create_base_floating_platform()
    # Load authentic 3D blue couch crop from header_isometric
    src_path = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\couch_crop.png'
    couch = Image.open(src_path).convert('RGBA')

    cw, ch = couch.size
    mask = Image.new('L', (cw, ch), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([int(cw*0.08), int(ch*0.08), int(cw*0.92), int(ch*0.92)], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(10))
    couch.putalpha(mask)

    couch_scaled = couch.resize((330, 275), Image.Resampling.LANCZOS)
    base.paste(couch_scaled, (91, 150), couch_scaled)

    p1 = os.path.join(CATEGORIES_DIR, 'khong_gian.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'khong_gian.png')
    base.save(p1, 'PNG')
    base.save(p2, 'PNG')
    print('Generated authentic 3D khong_gian.png')

# -------------------------------------------------------------
# 3. DAT_CHO_THUE.PNG (Land Plot: Round Clay Tree + Flowers + Lawn)
# -------------------------------------------------------------
def build_dat_cho_thue():
    base = create_base_floating_platform()

    # Draw emerald green grass layer on the platform
    grass = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(grass)
    cx, cy = 256, 394
    rx, ry = 160, 78
    gdraw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(52, 211, 153, 255), outline=(110, 231, 183, 255), width=2)
    base = Image.alpha_composite(base, grass)

    # Load authentic 3D round clay tree crop from nha_o_3d
    src_path = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\tree_crop.png'
    tree = Image.open(src_path).convert('RGBA')

    tw, th = tree.size
    mask = Image.new('L', (tw, th), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([int(tw*0.08), int(th*0.08), int(tw*0.92), int(th*0.96)], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(8))
    tree.putalpha(mask)

    tree_scaled = tree.resize((260, 280), Image.Resampling.LANCZOS)
    base.paste(tree_scaled, (126, 120), tree_scaled)

    # Add cute survey flag next to tree
    flag = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(flag)
    # Pole
    fdraw.rectangle([340, 260, 344, 380], fill=(203, 213, 225, 255))
    # Red triangular flag
    fdraw.polygon([(344, 260), (385, 275), (344, 290)], fill=(239, 68, 68, 255))
    base = Image.alpha_composite(base, flag)

    p1 = os.path.join(CATEGORIES_DIR, 'dat_cho_thue.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'dat_cho_thue.png')
    base.save(p1, 'PNG')
    base.save(p2, 'PNG')
    print('Generated authentic 3D dat_cho_thue.png')

# -------------------------------------------------------------
# 4. MAT_BANG.PNG (Shophouse Storefront with Awning Canopy)
# -------------------------------------------------------------
def build_mat_bang():
    base = create_base_floating_platform()

    # Load mini house from header_isometric as shop building
    src_path = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\mini_house_crop.png'
    house = Image.open(src_path).convert('RGBA')
    hw, hh = house.size
    mask = Image.new('L', (hw, hh), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([int(hw*0.06), int(hh*0.06), int(hw*0.94), int(hh*0.94)], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(8))
    house.putalpha(mask)
    house_scaled = house.resize((260, 285), Image.Resampling.LANCZOS)
    base.paste(house_scaled, (126, 130), house_scaled)

    # Add 3D Red/White Striped Awning Canopy
    awning = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(awning)
    # Draw striped awning
    stripes = 5
    for i in range(stripes):
        is_red = (i % 2 == 0)
        col = (239, 68, 68, 255) if is_red else (255, 255, 255, 255)
        x_st = 175 + i * 28
        adraw.polygon([
            (x_st, 240),
            (x_st + 28, 240),
            (x_st + 20, 275),
            (x_st - 8, 275)
        ], fill=col)
    awning = awning.filter(ImageFilter.GaussianBlur(0.8))
    base = Image.alpha_composite(base, awning)

    # Add "SHOP" golden sign
    sign = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sign)
    sdraw.rounded_rectangle([216, 185, 296, 215], radius=6, fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    sdraw.text((234, 192), "SHOP", fill=(255, 255, 255, 255))
    base = Image.alpha_composite(base, sign)

    p1 = os.path.join(CATEGORIES_DIR, 'mat_bang.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'mat_bang.png')
    base.save(p1, 'PNG')
    base.save(p2, 'PNG')
    print('Generated authentic 3D mat_bang.png')

# -------------------------------------------------------------
# 5. KHO_VAN.PNG (Warehouse with Shutter Door & Cargo Crates)
# -------------------------------------------------------------
def build_kho_van():
    base = create_base_floating_platform()

    # Load mini house as warehouse structure
    src_path = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\mini_house_crop.png'
    house = Image.open(src_path).convert('RGBA')
    hw, hh = house.size
    mask = Image.new('L', (hw, hh), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([int(hw*0.06), int(hh*0.06), int(hw*0.94), int(hh*0.94)], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(8))
    house.putalpha(mask)
    house_scaled = house.resize((260, 285), Image.Resampling.LANCZOS)
    base.paste(house_scaled, (100, 130), house_scaled)

    # Add Industrial Roll-Up Shutter Door on the front
    shutter = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shutter)
    sdraw.rectangle([180, 280, 230, 360], fill=(148, 163, 184, 255), outline=(71, 85, 105, 255), width=2)
    for ly in range(286, 360, 8):
        sdraw.line([(180, ly), (230, ly)], fill=(203, 213, 225, 255), width=1)

    # 3D Wooden Shipping Cargo Crates
    # Crate 1
    sdraw.rounded_rectangle([290, 305, 360, 375], radius=6, fill=(217, 135, 70, 255), outline=(254, 215, 170, 255), width=2)
    sdraw.line([(290, 305), (360, 375)], fill=(180, 100, 45, 255), width=2)
    sdraw.line([(290, 375), (360, 305)], fill=(180, 100, 45, 255), width=2)
    # Crate 2 on top
    sdraw.rounded_rectangle([300, 250, 350, 300], radius=5, fill=(245, 180, 110, 255), outline=(254, 240, 138, 255), width=2)
    sdraw.line([(300, 250), (350, 300)], fill=(217, 135, 70, 255), width=2)

    base = Image.alpha_composite(base, shutter)

    p1 = os.path.join(CATEGORIES_DIR, 'kho_van.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'kho_van.png')
    base.save(p1, 'PNG')
    base.save(p2, 'PNG')
    print('Generated authentic 3D kho_van.png')

# -------------------------------------------------------------
# 6. LUU_TRU.PNG (Hotel / Homestay: Travel Suitcase + Gold Bell + Stars)
# -------------------------------------------------------------
def build_luu_tru():
    base = create_base_floating_platform()

    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    # 3D Teal/Ocean Blue Travel Suitcase
    draw.rounded_rectangle([190, 250, 330, 370], radius=16, fill=(20, 184, 166, 255), outline=(94, 234, 212, 255), width=3)
    # Suitcase leather straps
    draw.line([(225, 250), (225, 370)], fill=(13, 148, 136, 255), width=6)
    draw.line([(295, 250), (295, 370)], fill=(13, 148, 136, 255), width=6)
    # Handle on top
    draw.rounded_rectangle([235, 220, 285, 250], radius=6, fill=(15, 118, 110, 255), outline=(94, 234, 212, 255), width=2)

    # Shiny Golden Concierge Bell next to suitcase
    draw.ellipse([325, 315, 385, 375], fill=(245, 158, 11, 255))
    draw.ellipse([335, 305, 375, 345], fill=(251, 191, 36, 255))
    draw.ellipse([348, 295, 362, 310], fill=(254, 240, 138, 255))

    # 5 Golden Hotel Stars arched overhead
    for i in range(5):
        sx = 176 + i * 40
        sy = 175 + int(math.sin(i * math.pi / 4.0) * -15)
        draw.ellipse([sx - 12, sy - 12, sx + 12, sy + 12], fill=(250, 204, 21, 255), outline=(254, 240, 138, 255), width=2)

    layer = layer.filter(ImageFilter.GaussianBlur(0.6))
    base = Image.alpha_composite(base, layer)

    p1 = os.path.join(CATEGORIES_DIR, 'luu_tru.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'luu_tru.png')
    base.save(p1, 'PNG')
    base.save(p2, 'PNG')
    print('Generated authentic 3D luu_tru.png')

# -------------------------------------------------------------
# 7. O_GHEP.PNG (Ở ghép / KTX: Authentic Student Roommate from Master)
# -------------------------------------------------------------
def build_o_ghep():
    src = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\o_ghep_full.png'
    if os.path.exists(src):
        im = Image.open(src).convert('RGBA')
        arr = np.array(im)
        r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
        bg_mask = (r > 232) & (g > 238) & (b > 245)
        alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
        alpha = cv2.GaussianBlur(alpha, (5, 5), 0)
        arr[:,:,3] = alpha
        clean = Image.fromarray(arr).resize((512, 512), Image.Resampling.LANCZOS)
        p1 = os.path.join(CATEGORIES_DIR, 'o_ghep.png')
        p2 = os.path.join(BUILD_CAT_DIR, 'o_ghep.png')
        clean.save(p1, 'PNG')
        clean.save(p2, 'PNG')
        print('Generated authentic 3D o_ghep.png')

# -------------------------------------------------------------
# 8. ICON_RESIDENT_PERKS.PNG (Ưu đãi cư dân - 3D VIP Gift Box)
# -------------------------------------------------------------
def build_resident_perks():
    im = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    # Ambient shadow
    sh = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sh)
    sdraw.ellipse([130, 360, 382, 440], fill=(105, 177, 255, 100))
    sdraw.ellipse([170, 375, 342, 425], fill=(37, 99, 235, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(16))
    im = Image.alpha_composite(im, sh)

    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    # Sky Blue Gift Box Body
    draw.rounded_rectangle([150, 210, 362, 380], radius=24, fill=(59, 130, 246, 255), outline=(147, 197, 253, 255), width=4)
    # Box Lid
    draw.rounded_rectangle([138, 175, 374, 225], radius=16, fill=(96, 165, 250, 255), outline=(191, 219, 254, 255), width=4)
    # Gold Ribbon Horizontal
    draw.rectangle([138, 275, 374, 315], fill=(245, 158, 11, 255))
    # Gold Ribbon Vertical
    draw.rectangle([236, 175, 276, 380], fill=(251, 191, 36, 255))
    # Gold Ribbon Bow on top
    draw.ellipse([200, 130, 260, 185], fill=(254, 240, 138, 255), outline=(217, 119, 6, 255), width=3)
    draw.ellipse([252, 130, 312, 185], fill=(254, 240, 138, 255), outline=(217, 119, 6, 255), width=3)
    draw.ellipse([236, 145, 276, 185], fill=(245, 158, 11, 255))

    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    im = Image.alpha_composite(im, layer)

    p1 = os.path.join(CATEGORIES_DIR, 'icon_resident_perks.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'icon_resident_perks.png')
    im.save(p1, 'PNG')
    im.save(p2, 'PNG')
    print('Generated authentic 3D icon_resident_perks.png')

# -------------------------------------------------------------
# 9. ICON_REFERRAL_REWARD.PNG (Giới thiệu bạn thuê phòng - 200K Bonus)
# -------------------------------------------------------------
def build_referral_reward():
    im = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    # Ambient shadow
    sh = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sh)
    sdraw.ellipse([130, 360, 382, 440], fill=(251, 146, 60, 90))
    sh = sh.filter(ImageFilter.GaussianBlur(16))
    im = Image.alpha_composite(im, sh)

    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    # Coral Red Envelope
    draw.rounded_rectangle([150, 220, 362, 380], radius=20, fill=(239, 68, 68, 255), outline=(254, 205, 211, 255), width=4)
    # Green 200K Cash Note sticking out
    draw.rounded_rectangle([170, 140, 342, 230], radius=12, fill=(16, 185, 129, 255), outline=(167, 243, 208, 255), width=3)
    draw.text((216, 170), "200K", fill=(255, 255, 255, 255))
    # Gold coins in front
    draw.ellipse([270, 310, 340, 380], fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=3)
    draw.ellipse([310, 325, 370, 385], fill=(251, 191, 36, 255), outline=(254, 240, 138, 255), width=3)

    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    im = Image.alpha_composite(im, layer)

    p1 = os.path.join(CATEGORIES_DIR, 'icon_referral_reward.png')
    p2 = os.path.join(BUILD_CAT_DIR, 'icon_referral_reward.png')
    im.save(p1, 'PNG')
    im.save(p2, 'PNG')
    print('Generated authentic 3D icon_referral_reward.png')

# -------------------------------------------------------------
# 10. FEAT_LOCATION.PNG (Vị trí GPS / Location Map Pin)
# -------------------------------------------------------------
def build_location_pin():
    base = create_base_floating_platform()
    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    # 3D Teardrop Location Map Pin in Brand Blue
    # Pin head
    draw.ellipse([200, 140, 312, 252], fill=(37, 99, 235, 255), outline=(96, 165, 250, 255), width=5)
    # Pin tip
    draw.polygon([(216, 225), (300, 225), (256, 320)], fill=(29, 78, 216, 255))
    # Inner white dot
    draw.ellipse([236, 176, 276, 216], fill=(255, 255, 255, 255))

    # Radar pulse ring on platform
    draw.ellipse([186, 350, 326, 410], outline=(59, 130, 246, 160), width=4)

    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    base = Image.alpha_composite(base, layer)

    p1 = os.path.join(FEATURES_DIR, 'feat_location.png')
    p2 = os.path.join(BUILD_FEAT_DIR, 'feat_location.png')
    base.save(p1, 'PNG')
    base.save(p2, 'PNG')
    print('Generated authentic 3D feat_location.png')

if __name__ == '__main__':
    build_van_phong()
    build_khong_gian()
    build_dat_cho_thue()
    build_mat_bang()
    build_kho_van()
    build_luu_tru()
    build_o_ghep()
    build_resident_perks()
    build_referral_reward()
    build_location_pin()
    print('ALL COMPOSITED 3D ICONS BUILT SUCCESSFULLY!')
