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

def create_base_platform(w=512, h=512):
    canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))

    # Soft ambient blue shadow
    shadow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.ellipse([int(w*0.14), int(h*0.72), int(w*0.86), int(h*0.93)], fill=(105, 177, 255, 95))
    sdraw.ellipse([int(w*0.24), int(h*0.75), int(w*0.76), int(h*0.89)], fill=(37, 99, 235, 75))
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(w*0.045)))
    canvas = Image.alpha_composite(canvas, shadow)

    # 3D Porcelain Beveled Platform
    plat = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(plat)

    cx, cy = w * 0.5, h * 0.78
    rx, ry = w * 0.36, h * 0.17
    thick = int(h * 0.055)

    for dy in range(thick, -1, -1):
        ratio = dy / thick
        c_r = int(222 + 30 * (1 - ratio))
        c_g = int(232 + 22 * (1 - ratio))
        c_b = int(246 + 9 * (1 - ratio))
        pdraw.ellipse([int(cx - rx), int(cy - ry + dy), int(cx + rx), int(cy + ry + dy)], fill=(c_r, c_g, c_b, 255))

    pdraw.ellipse([int(cx - rx), int(cy - ry), int(cx + rx), int(cy + ry)], fill=(252, 254, 255, 255))
    pdraw.ellipse([int(cx - rx * 0.9), int(cy - ry * 0.9 - 2), int(cx + rx * 0.9), int(cy + ry * 0.9 - 2)],
                  fill=(244, 248, 255, 255), outline=(255, 255, 255, 210))

    return Image.alpha_composite(canvas, plat)

def save_both(im, filename, is_feat=False):
    d1 = FEATURES_DIR if is_feat else CATEGORIES_DIR
    d2 = BUILD_FEAT_DIR if is_feat else BUILD_CAT_DIR
    p1 = os.path.join(d1, filename)
    p2 = os.path.join(d2, filename)
    im.save(p1, 'PNG')
    im.save(p2, 'PNG')
    print(f'Successfully saved {filename} to {d1} and {d2}')

# 1. VAN_PHONG.PNG (Desk + Lamp + Books + Chair)
def render_van_phong():
    base = create_base_platform()
    desk = Image.open('StayHub_frontend/desk_grabcut.png').convert('RGBA')
    chair = Image.open('StayHub_frontend/chair_grabcut.png').convert('RGBA')

    # Desk
    dw, dh = desk.size
    desk_scaled = desk.resize((310, int(310 * dh / dw)), Image.Resampling.LANCZOS)
    base.paste(desk_scaled, (100, 150), desk_scaled)

    # Chair in front
    cw, ch = chair.size
    chair_scaled = chair.resize((150, int(150 * ch / cw)), Image.Resampling.LANCZOS)
    base.paste(chair_scaled, (215, 275), chair_scaled)

    save_both(base, 'van_phong.png')

# 2. KHONG_GIAN.PNG (Co-working Shared Lounge: Blue Couch + Coffee Table)
def render_khong_gian():
    base = create_base_platform()
    couch = Image.open('StayHub_frontend/couch_grabcut.png').convert('RGBA')
    # Clean top wall fragment from couch
    c_arr = np.array(couch)
    c_arr[:45, :130, 3] = 0
    couch = Image.fromarray(c_arr)

    cw, ch = couch.size
    couch_scaled = couch.resize((310, int(310 * ch / cw)), Image.Resampling.LANCZOS)
    base.paste(couch_scaled, (105, 175), couch_scaled)

    # Add modern round coffee table in front of couch
    tbl = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(tbl)
    # Table top
    tdraw.ellipse([270, 340, 370, 390], fill=(254, 243, 199, 255), outline=(252, 211, 77, 255), width=2)
    # Coffee mug
    tdraw.ellipse([310, 350, 332, 368], fill=(239, 68, 68, 255))
    tbl = tbl.filter(ImageFilter.GaussianBlur(0.6))
    base = Image.alpha_composite(base, tbl)

    save_both(base, 'khong_gian.png')

# 3. DAT_CHO_THUE.PNG (Land: Lawn + Round Clay Tree + Survey Flag)
def render_dat_cho_thue():
    base = create_base_platform()

    # Green lawn slab
    grass = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(grass)
    cx, cy = 256, 395
    rx, ry = 160, 78
    gdraw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(52, 211, 153, 255), outline=(110, 231, 183, 255), width=2)
    base = Image.alpha_composite(base, grass)

    # Tree
    tree = Image.open('StayHub_frontend/tree_grabcut.png').convert('RGBA')
    tw, th = tree.size
    tree_scaled = tree.resize((260, int(260 * th / tw)), Image.Resampling.LANCZOS)
    base.paste(tree_scaled, (100, 140), tree_scaled)

    # Survey locator flag
    flag = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(flag)
    fdraw.rectangle([340, 240, 345, 385], fill=(203, 213, 225, 255))
    fdraw.polygon([(345, 240), (395, 260), (345, 280)], fill=(239, 68, 68, 255))
    # Boundary survey pegs
    for px, py in [(130, 375), (200, 420), (360, 420), (390, 375)]:
        fdraw.rectangle([px-3, py-10, px+3, py+4], fill=(245, 158, 11, 255))
    base = Image.alpha_composite(base, flag)

    save_both(base, 'dat_cho_thue.png')

# 4. MAT_BANG.PNG (Shophouse Retail Front + Striped Awning)
def render_mat_bang():
    base = create_base_platform()
    house = Image.open('StayHub_frontend/mini_house_grabcut.png').convert('RGBA')
    hw, hh = house.size
    house_scaled = house.resize((260, int(260 * hh / hw)), Image.Resampling.LANCZOS)
    base.paste(house_scaled, (126, 145), house_scaled)

    # Red/White striped awning canopy over shop front
    awning = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(awning)
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

    # "SHOP" golden sign
    adraw.rounded_rectangle([216, 185, 296, 215], radius=6, fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=2)
    adraw.text((234, 192), "SHOP", fill=(255, 255, 255, 255))

    # Glass display door
    adraw.rectangle([185, 275, 225, 335], fill=(147, 197, 253, 220), outline=(59, 130, 246, 255), width=2)
    adraw.ellipse([218, 305, 224, 311], fill=(245, 158, 11, 255))

    awning = awning.filter(ImageFilter.GaussianBlur(0.6))
    base = Image.alpha_composite(base, awning)

    save_both(base, 'mat_bang.png')

# 5. KHO_VAN.PNG (Warehouse + Roll-up Shutter Door + Cargo Crates)
def render_kho_van():
    base = create_base_platform()
    house = Image.open('StayHub_frontend/mini_house_grabcut.png').convert('RGBA')
    hw, hh = house.size
    house_scaled = house.resize((260, int(260 * hh / hw)), Image.Resampling.LANCZOS)
    base.paste(house_scaled, (100, 145), house_scaled)

    # Industrial roll-up metal shutter door
    decor = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    ddraw = ImageDraw.Draw(decor)
    ddraw.rectangle([155, 275, 205, 345], fill=(148, 163, 184, 255), outline=(71, 85, 105, 255), width=2)
    for ly in range(282, 345, 8):
        ddraw.line([(155, ly), (205, ly)], fill=(203, 213, 225, 255), width=1)
    # Hazard bar above shutter
    ddraw.rectangle([150, 268, 210, 275], fill=(245, 158, 11, 255))

    # 3D Wooden Shipping Cargo Crates
    ddraw.rounded_rectangle([275, 305, 355, 375], radius=6, fill=(217, 135, 70, 255), outline=(254, 215, 170, 255), width=2)
    ddraw.line([(275, 305), (355, 375)], fill=(180, 100, 45, 255), width=2)
    ddraw.line([(275, 375), (355, 305)], fill=(180, 100, 45, 255), width=2)

    ddraw.rounded_rectangle([290, 245, 345, 300], radius=5, fill=(245, 180, 110, 255), outline=(254, 240, 138, 255), width=2)
    ddraw.line([(290, 245), (345, 300)], fill=(217, 135, 70, 255), width=2)

    decor = decor.filter(ImageFilter.GaussianBlur(0.6))
    base = Image.alpha_composite(base, decor)

    save_both(base, 'kho_van.png')

# 6. LUU_TRU.PNG (Hotel: Suitcase + Reception Bell + 5 Stars)
def render_luu_tru():
    base = create_base_platform()
    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    # 3D Teal/Ocean Blue Travel Suitcase
    draw.rounded_rectangle([190, 250, 330, 370], radius=16, fill=(20, 184, 166, 255), outline=(94, 234, 212, 255), width=3)
    draw.line([(225, 250), (225, 370)], fill=(13, 148, 136, 255), width=6)
    draw.line([(295, 250), (295, 370)], fill=(13, 148, 136, 255), width=6)
    draw.rounded_rectangle([235, 220, 285, 250], radius=6, fill=(15, 118, 110, 255), outline=(94, 234, 212, 255), width=2)

    # Golden Concierge Reception Bell
    draw.ellipse([325, 315, 385, 375], fill=(245, 158, 11, 255))
    draw.ellipse([335, 305, 375, 345], fill=(251, 191, 36, 255))
    draw.ellipse([348, 295, 362, 310], fill=(254, 240, 138, 255))

    # 5 Golden Stars arched overhead
    for i in range(5):
        sx = 176 + i * 40
        sy = 175 + int(math.sin(i * math.pi / 4.0) * -15)
        draw.ellipse([sx - 12, sy - 12, sx + 12, sy + 12], fill=(250, 204, 21, 255), outline=(254, 240, 138, 255), width=2)

    layer = layer.filter(ImageFilter.GaussianBlur(0.6))
    base = Image.alpha_composite(base, layer)

    save_both(base, 'luu_tru.png')

# 7. O_GHEP.PNG (Student Roommate with Radar from Master)
def render_o_ghep():
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
        save_both(clean, 'o_ghep.png')

# 8. ICON_RESIDENT_PERKS.PNG (VIP Golden Gift Box)
def render_resident_perks():
    im = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sh = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sh)
    sdraw.ellipse([130, 360, 382, 440], fill=(105, 177, 255, 100))
    sdraw.ellipse([170, 375, 342, 425], fill=(37, 99, 235, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(16))
    im = Image.alpha_composite(im, sh)

    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle([150, 210, 362, 380], radius=24, fill=(59, 130, 246, 255), outline=(147, 197, 253, 255), width=4)
    draw.rounded_rectangle([138, 175, 374, 225], radius=16, fill=(96, 165, 250, 255), outline=(191, 219, 254, 255), width=4)
    draw.rectangle([138, 275, 374, 315], fill=(245, 158, 11, 255))
    draw.rectangle([236, 175, 276, 380], fill=(251, 191, 36, 255))
    draw.ellipse([200, 130, 260, 185], fill=(254, 240, 138, 255), outline=(217, 119, 6, 255), width=3)
    draw.ellipse([252, 130, 312, 185], fill=(254, 240, 138, 255), outline=(217, 119, 6, 255), width=3)
    draw.ellipse([236, 145, 276, 185], fill=(245, 158, 11, 255))
    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    im = Image.alpha_composite(im, layer)

    save_both(im, 'icon_resident_perks.png')

# 9. ICON_REFERRAL_REWARD.PNG (Referral 200K Cash & Coins)
def render_referral_reward():
    im = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sh = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sh)
    sdraw.ellipse([130, 360, 382, 440], fill=(251, 146, 60, 90))
    sh = sh.filter(ImageFilter.GaussianBlur(16))
    im = Image.alpha_composite(im, sh)

    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle([150, 220, 362, 380], radius=20, fill=(239, 68, 68, 255), outline=(254, 205, 211, 255), width=4)
    draw.rounded_rectangle([170, 140, 342, 230], radius=12, fill=(16, 185, 129, 255), outline=(167, 243, 208, 255), width=3)
    draw.text((216, 170), "200K", fill=(255, 255, 255, 255))
    draw.ellipse([270, 310, 340, 380], fill=(245, 158, 11, 255), outline=(254, 240, 138, 255), width=3)
    draw.ellipse([310, 325, 370, 385], fill=(251, 191, 36, 255), outline=(254, 240, 138, 255), width=3)
    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    im = Image.alpha_composite(im, layer)

    save_both(im, 'icon_referral_reward.png')

# 10. FEAT_LOCATION.PNG (3D Map Pin)
def render_location_pin():
    base = create_base_platform()
    layer = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse([200, 140, 312, 252], fill=(37, 99, 235, 255), outline=(96, 165, 250, 255), width=5)
    draw.polygon([(216, 225), (300, 225), (256, 320)], fill=(29, 78, 216, 255))
    draw.ellipse([236, 176, 276, 216], fill=(255, 255, 255, 255))
    draw.ellipse([186, 350, 326, 410], outline=(59, 130, 246, 160), width=4)
    layer = layer.filter(ImageFilter.GaussianBlur(0.8))
    base = Image.alpha_composite(base, layer)

    save_both(base, 'feat_location.png', is_feat=True)

if __name__ == '__main__':
    render_van_phong()
    render_khong_gian()
    render_dat_cho_thue()
    render_mat_bang()
    render_kho_van()
    render_luu_tru()
    render_o_ghep()
    render_resident_perks()
    render_referral_reward()
    render_location_pin()
    print('ALL DONE!')
