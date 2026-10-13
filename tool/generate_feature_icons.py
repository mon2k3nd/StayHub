"""
StayHub — Pastel 3D DIORAMA feature icon generator.

Matches the reference sheet in Downloads
("Bộ biểu tượng diorama pastel 3D"): a 4x4 grid of soft pastel 3D dioramas.
Each icon is a small floating rounded platform (soft blue/white) with a
glossy pastel object sitting on top, a soft contact shadow, and gentle
top-light. Airy, cute, "clay-render" look.

Generates icon_0.png .. icon_15.png for the main-screen feature grid
(assets/images/features/split_icons/).

STYLE (extracted from the reference sheet):
  * square-ish diorama, transparent background
  * palette: porcelain white (240,244,250), soft blue (176,208,240),
             light blue (208,224,240), pale cyan (224,240,240),
             periwinkle (128,160,224), accent blue (64,144,240),
             warm (240,170,110), green (150,200,120), pink (240,170,190)
  * rounded floating platform base with a soft rim
  * soft contact shadow beneath
  * glossy top highlight on every volume

Feature map (must match guest_landing_screen.dart):
  0  Tìm phòng nhanh      -> magnifier + small house
  1  Ghép phòng tiết kiệm -> two room blocks + heart
  2  Sự kiện & Giải trí   -> gift box + confetti
  3  Hóa đơn điện nước    -> receipt sheet + bolt
  4  Báo sự cố bảo trì    -> wrench + gear
  5  Hợp đồng điện tử     -> document + seal
  6  Đầu tư sinh lời      -> coin stack + up arrow
  7  Cộng đồng cư dân     -> three people
  8  Tiện ích xung quanh  -> map pin
  9  Thu gọn              -> chevron-up circle
  10 An ninh toà nhà      -> shield + check
  11 Hệ thống chi nhánh   -> building cluster
  12 Ký hợp đồng điện tử  -> pen + document
  13 Phòng của tôi        -> house + heart
  14 Đánh giá chất lượng  -> star
  15 Hỗ trợ 24/7          -> headset
"""

import os
import math
from PIL import Image, ImageDraw, ImageFilter

# ---------------------------------------------------------------- paths
ROOT = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend"
OUT_DIR = os.path.join(ROOT, r"assets\images\features\split_icons")
BUILD_DIRS = [
    os.path.join(ROOT, r"build\flutter_assets\assets\images\features\split_icons"),
    os.path.join(ROOT, r"build\web\assets\assets\images\features\split_icons"),
]
for d in [OUT_DIR, *BUILD_DIRS]:
    os.makedirs(d, exist_ok=True)

# render at 4x then downscale for smooth anti-aliased edges
SS = 4
W, H = 96, 122
CW, CH = W * SS, H * SS

# ---------------------------------------------------------------- palette
PORC = (240, 244, 250)      # porcelain white
PORC_D = (214, 224, 238)    # porcelain shadow
SBLUE = (176, 208, 240)     # soft blue
SBLUE_D = (140, 178, 224)   # soft blue shadow
LBLUE = (208, 224, 240)     # light blue
LBLUE_D = (176, 200, 228)   # light blue shadow
CYAN = (224, 240, 240)      # pale cyan
CYAN_D = (188, 216, 220)    # pale cyan shadow
PERI = (128, 160, 224)      # periwinkle
PERI_D = (100, 132, 200)    # periwinkle shadow
BLUE = (64, 144, 240)       # accent blue
BLUE_D = (44, 116, 214)     # accent blue shadow
WARM = (240, 170, 110)      # warm accent
WARM_D = (222, 146, 84)     # warm shadow
GREEN = (150, 200, 120)     # green accent
GREEN_D = (120, 172, 92)    # green shadow
PINK = (240, 170, 190)      # pink accent
PINK_D = (220, 140, 164)    # pink shadow
AMBER = (246, 206, 120)     # amber
AMBER_D = (226, 178, 84)    # amber shadow
WHITE = (252, 253, 255)
INK = (110, 130, 160)
SHADOW = (150, 175, 210)


def _shade(c, f):
    if f >= 0:
        return tuple(int(v + (255 - v) * f) for v in c)
    return tuple(int(v * (1 + f)) for v in c)


def new_canvas():
    return Image.new("RGBA", (CW, CH), (0, 0, 0, 0))


def soft_shadow(canvas, cx, cy, rx, ry, alpha=60):
    sh = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=SHADOW + (alpha,))
    sh = sh.filter(ImageFilter.GaussianBlur(int(CW * 0.045)))
    return Image.alpha_composite(canvas, sh)


def platform(canvas, cx, cy, rx, ry, top=SBLUE, rim=SBLUE_D, depth=None):
    """Rounded floating diorama platform: an ellipse top with a soft rim
    and a slightly darker underside, giving a thick 'puck' look."""
    if depth is None:
        depth = ry * 0.55
    layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # underside / rim
    d.ellipse([cx - rx, cy - ry + depth, cx + rx, cy + ry + depth], fill=rim + (255,))
    d.rectangle([cx - rx, cy, cx + rx, cy + depth], fill=rim + (255,))
    # top face
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=top + (255,))
    layer = layer.filter(ImageFilter.GaussianBlur(int(CW * 0.004)))
    canvas = Image.alpha_composite(canvas, layer)
    # glossy top highlight
    hl = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([cx - rx * 0.72, cy - ry * 0.82, cx + rx * 0.72, cy - ry * 0.05],
               fill=_shade(top, 0.35) + (255,))
    hl = hl.filter(ImageFilter.GaussianBlur(int(CW * 0.02)))
    return Image.alpha_composite(canvas, hl)


def clay_round(canvas, box, radius, color, top_light=0.26, bottom_dark=0.14):
    x0, y0, x1, y1 = box
    layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(box, radius=radius, fill=color + (255,))
    sh = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.rounded_rectangle((x0, y0 + (y1 - y0) * 0.5, x1, y1), radius=radius,
                         fill=_shade(color, -bottom_dark) + (255,))
    sh = sh.filter(ImageFilter.GaussianBlur(int(CW * 0.012)))
    layer = Image.alpha_composite(layer, sh)
    hl = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.rounded_rectangle((x0 + 6, y0 + 5, x1 - 6, y0 + (y1 - y0) * 0.42),
                         radius=radius, fill=_shade(color, top_light) + (255,))
    hl = hl.filter(ImageFilter.GaussianBlur(int(CW * 0.014)))
    layer = Image.alpha_composite(layer, hl)
    return Image.alpha_composite(canvas, layer)


def clay_disc(canvas, center, r, color, top_light=0.28):
    cx, cy = center
    layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (255,))
    hl = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.ellipse([cx - r * 0.7, cy - r * 0.8, cx + r * 0.7, cy - r * 0.05],
               fill=_shade(color, top_light) + (255,))
    hl = hl.filter(ImageFilter.GaussianBlur(r * 0.25))
    layer = Image.alpha_composite(layer, hl)
    return Image.alpha_composite(canvas, layer)


def iso_box(canvas, cx, base_y, w, h, depth, top, left, right):
    """Isometric box: top face (rhombus) + left/right side faces."""
    layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    hw = w / 2.0
    top_pts = [
        (cx, base_y - h - depth * 0.5),
        (cx + hw, base_y - h),
        (cx, base_y - h + depth * 0.5),
        (cx - hw, base_y - h),
    ]
    left_pts = [
        (cx - hw, base_y - h),
        (cx, base_y - h + depth * 0.5),
        (cx, base_y + depth * 0.5),
        (cx - hw, base_y),
    ]
    right_pts = [
        (cx, base_y - h + depth * 0.5),
        (cx + hw, base_y - h),
        (cx + hw, base_y),
        (cx, base_y + depth * 0.5),
    ]
    d.polygon(left_pts, fill=left + (255,))
    d.polygon(right_pts, fill=right + (255,))
    d.polygon(top_pts, fill=top + (255,))
    return Image.alpha_composite(canvas, layer)


def save(canvas, idx):
    out = canvas.resize((W, H), Image.Resampling.LANCZOS)
    name = f"icon_{idx}.png"
    out.save(os.path.join(OUT_DIR, name), "PNG", optimize=True)
    for bd in BUILD_DIRS:
        out.save(os.path.join(bd, name), "PNG", optimize=True)
    print(f"  saved {name}")


# ---------------------------------------------------------------- icons
# Every icon: soft shadow -> floating platform -> object(s) on top.

def icon_0_search_house():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.34, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.74, CW * 0.40, CH * 0.11)
    # small house on the platform
    c = iso_box(c, CW * 0.42, CH * 0.72, CW * 0.30, CH * 0.20, CH * 0.08,
                PORC, LBLUE, LBLUE_D)
    roof = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    rd = ImageDraw.Draw(roof)
    bx, by = CW * 0.42, CH * 0.50
    rd.polygon([(bx - CW * 0.19, by), (bx, by - CH * 0.12), (bx + CW * 0.19, by)],
               fill=PERI + (255,))
    rd.polygon([(bx - CW * 0.19, by), (bx, by - CH * 0.12), (bx, by + CH * 0.015)],
               fill=PERI_D + (255,))
    c = Image.alpha_composite(c, roof)
    c = clay_round(c, (CW * 0.39, CH * 0.58, CW * 0.45, CH * 0.72), int(CW * 0.015), WARM)
    # magnifier
    ring = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    rg = ImageDraw.Draw(ring)
    rg.ellipse([CW * 0.54, CH * 0.30, CW * 0.82, CH * 0.58], outline=BLUE + (255,), width=int(CW * 0.04))
    rg.ellipse([CW * 0.57, CH * 0.33, CW * 0.79, CH * 0.55], outline=_shade(BLUE, 0.45) + (255,), width=int(CW * 0.012))
    rg.line([(CW * 0.78, CH * 0.54), (CW * 0.90, CH * 0.66)], fill=BLUE_D + (255,), width=int(CW * 0.045))
    c = Image.alpha_composite(c, ring)
    return c


def icon_1_roommate():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.36, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.76, CW * 0.42, CH * 0.11)
    c = iso_box(c, CW * 0.38, CH * 0.74, CW * 0.28, CH * 0.24, CH * 0.08,
                PORC, CYAN, CYAN_D)
    c = iso_box(c, CW * 0.62, CH * 0.76, CW * 0.28, CH * 0.30, CH * 0.08,
                PORC, LBLUE, LBLUE_D)
    for (x, y) in [(0.31, 0.56), (0.31, 0.64)]:
        c = clay_round(c, (CW * x, CH * y, CW * (x + 0.13), CH * (y + 0.045)),
                       int(CW * 0.01), WHITE)
    for (x, y) in [(0.55, 0.54), (0.55, 0.62)]:
        c = clay_round(c, (CW * x, CH * y, CW * (x + 0.13), CH * (y + 0.045)),
                       int(CW * 0.01), WHITE)
    c = clay_disc(c, (CW * 0.70, CH * 0.34), CW * 0.10, PINK)
    h = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    hd = ImageDraw.Draw(h)
    hx, hy, s = CW * 0.70, CH * 0.34, CW * 0.055
    hd.polygon([(hx, hy + s * 0.7), (hx - s, hy - s * 0.1), (hx - s, hy - s * 0.6),
                (hx - s * 0.4, hy - s * 0.9), (hx, hy - s * 0.3),
                (hx + s * 0.4, hy - s * 0.9), (hx + s, hy - s * 0.6),
                (hx + s, hy - s * 0.1)], fill=WHITE + (255,))
    c = Image.alpha_composite(c, h)
    return c


def icon_2_party():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.34, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.78, CW * 0.40, CH * 0.11)
    # gift box
    c = iso_box(c, CW * 0.5, CH * 0.76, CW * 0.40, CH * 0.22, CH * 0.10,
                PORC, LBLUE, LBLUE_D)
    c = clay_round(c, (CW * 0.47, CH * 0.50, CW * 0.53, CH * 0.76), int(CW * 0.008), WARM)
    c = iso_box(c, CW * 0.5, CH * 0.52, CW * 0.46, CH * 0.06, CH * 0.10,
                _shade(PORC, 0.02), CYAN, CYAN_D)
    c = clay_disc(c, (CW * 0.43, CH * 0.42), CW * 0.06, WARM)
    c = clay_disc(c, (CW * 0.57, CH * 0.42), CW * 0.06, WARM)
    c = clay_disc(c, (CW * 0.5, CH * 0.44), CW * 0.045, WARM_D)
    for (x, y, col) in [(0.24, 0.30, PINK), (0.78, 0.28, PERI), (0.30, 0.20, CYAN_D),
                        (0.72, 0.18, WARM), (0.86, 0.42, GREEN)]:
        c = clay_disc(c, (CW * x, CH * y), CW * 0.026, col)
    return c


def icon_3_bill():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.30, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.80, CW * 0.36, CH * 0.10)
    c = clay_round(c, (CW * 0.30, CH * 0.22, CW * 0.70, CH * 0.80), int(CW * 0.03), WHITE)
    c = clay_round(c, (CW * 0.30, CH * 0.22, CW * 0.70, CH * 0.32), int(CW * 0.03), LBLUE)
    for i, y in enumerate([0.40, 0.47, 0.54, 0.61]):
        w = 0.28 if i % 2 == 0 else 0.20
        c = clay_round(c, (CW * 0.37, CH * y, CW * (0.37 + w), CH * (y + 0.03)),
                       int(CW * 0.01), PORC_D)
    c = clay_round(c, (CW * 0.37, CH * 0.68, CW * 0.58, CH * 0.73), int(CW * 0.01), GREEN)
    c = clay_disc(c, (CW * 0.72, CH * 0.30), CW * 0.10, AMBER)
    b = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    bd = ImageDraw.Draw(b)
    bx, by = CW * 0.72, CH * 0.30
    bd.polygon([(bx + CW * 0.018, by - CH * 0.06), (bx - CW * 0.035, by + CH * 0.008),
                (bx, by + CH * 0.008), (bx - CW * 0.018, by + CH * 0.07),
                (bx + CW * 0.045, by - CH * 0.008), (bx + CW * 0.008, by - CH * 0.008)],
               fill=WHITE + (255,))
    c = Image.alpha_composite(c, b)
    return c


def icon_4_maintenance():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.32, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.80, CW * 0.38, CH * 0.10)
    gear = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gear)
    gx, gy, gr = CW * 0.60, CH * 0.50, CW * 0.18
    for k in range(8):
        a = math.radians(k * 45)
        x = gx + math.cos(a) * gr
        y = gy + math.sin(a) * gr
        gd.ellipse([x - CW * 0.045, y - CW * 0.045, x + CW * 0.045, y + CW * 0.045],
                   fill=LBLUE_D + (255,))
    gd.ellipse([gx - gr, gy - gr, gx + gr, gy + gr], fill=LBLUE + (255,))
    gd.ellipse([gx - CW * 0.07, gy - CW * 0.07, gx + CW * 0.07, gy + CW * 0.07],
               fill=PORC + (255,))
    c = Image.alpha_composite(c, gear)
    wr = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wr)
    wd.line([(CW * 0.30, CH * 0.74), (CW * 0.50, CH * 0.52)], fill=PERI + (255,), width=int(CW * 0.06))
    wd.ellipse([CW * 0.22, CH * 0.66, CW * 0.38, CH * 0.82], fill=PERI + (255,))
    wd.ellipse([CW * 0.26, CH * 0.70, CW * 0.34, CH * 0.78], fill=PORC + (255,))
    wd.ellipse([CW * 0.44, CH * 0.46, CW * 0.56, CH * 0.58], fill=PERI + (255,))
    wd.ellipse([CW * 0.47, CH * 0.49, CW * 0.53, CH * 0.55], fill=PORC + (255,))
    c = Image.alpha_composite(c, wr)
    return c


def icon_5_contract():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.30, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.80, CW * 0.36, CH * 0.10)
    c = clay_round(c, (CW * 0.28, CH * 0.20, CW * 0.72, CH * 0.80), int(CW * 0.03), WHITE)
    c = clay_round(c, (CW * 0.28, CH * 0.20, CW * 0.72, CH * 0.30), int(CW * 0.03), PERI)
    for i, y in enumerate([0.38, 0.45, 0.52, 0.59]):
        w = 0.32 if i % 2 == 0 else 0.22
        c = clay_round(c, (CW * 0.35, CH * y, CW * (0.35 + w), CH * (y + 0.03)),
                       int(CW * 0.01), PORC_D)
    sg = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sg)
    sd.line([(CW * 0.35, CH * 0.70), (CW * 0.43, CH * 0.66), (CW * 0.51, CH * 0.72),
             (CW * 0.59, CH * 0.66), (CW * 0.67, CH * 0.70)],
            fill=BLUE + (255,), width=int(CW * 0.016), joint="curve")
    c = Image.alpha_composite(c, sg)
    c = clay_disc(c, (CW * 0.70, CH * 0.68), CW * 0.085, AMBER)
    return c


def icon_6_invest():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.32, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.38, CH * 0.10)
    for y in [0.78, 0.70, 0.62]:
        c = clay_round(c, (CW * 0.28, CH * (y - 0.075), CW * 0.60, CH * y),
                       int(CW * 0.035), AMBER)
        c = clay_round(c, (CW * 0.28, CH * (y - 0.075), CW * 0.60, CH * (y - 0.042)),
                       int(CW * 0.035), _shade(AMBER, 0.3))
    ar = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    ad = ImageDraw.Draw(ar)
    ad.line([(CW * 0.44, CH * 0.58), (CW * 0.66, CH * 0.32)], fill=GREEN + (255,), width=int(CW * 0.045))
    ad.polygon([(CW * 0.66, CH * 0.22), (CW * 0.78, CH * 0.36), (CW * 0.58, CH * 0.38)],
               fill=GREEN + (255,))
    c = Image.alpha_composite(c, ar)
    return c


def icon_7_community():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.34, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.40, CH * 0.10)
    c = clay_disc(c, (CW * 0.32, CH * 0.42), CW * 0.09, CYAN_D)
    c = clay_round(c, (CW * 0.21, CH * 0.50, CW * 0.43, CH * 0.80), int(CW * 0.055), CYAN)
    c = clay_disc(c, (CW * 0.68, CH * 0.42), CW * 0.09, PERI_D)
    c = clay_round(c, (CW * 0.57, CH * 0.50, CW * 0.79, CH * 0.80), int(CW * 0.055), PERI)
    c = clay_disc(c, (CW * 0.5, CH * 0.38), CW * 0.11, LBLUE_D)
    c = clay_round(c, (CW * 0.35, CH * 0.48, CW * 0.65, CH * 0.84), int(CW * 0.065), LBLUE)
    return c


def icon_8_nearby():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.28, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.34, CH * 0.09)
    pin = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pin)
    pd.ellipse([CW * 0.30, CH * 0.22, CW * 0.70, CH * 0.62], fill=WARM + (255,))
    pd.polygon([(CW * 0.35, CH * 0.54), (CW * 0.65, CH * 0.54), (CW * 0.5, CH * 0.80)],
               fill=WARM + (255,))
    pd.ellipse([CW * 0.35, CH * 0.27, CW * 0.65, CH * 0.57], fill=WARM_D + (255,))
    c = Image.alpha_composite(c, pin)
    c = clay_disc(c, (CW * 0.5, CH * 0.42), CW * 0.09, WHITE)
    return c


def icon_9_collapse():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.28, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.34, CH * 0.09)
    c = clay_disc(c, (CW * 0.5, CH * 0.50), CW * 0.26, LBLUE)
    ch = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    cd = ImageDraw.Draw(ch)
    cd.line([(CW * 0.38, CH * 0.56), (CW * 0.5, CH * 0.44), (CW * 0.62, CH * 0.56)],
            fill=WHITE + (255,), width=int(CW * 0.045), joint="curve")
    c = Image.alpha_composite(c, ch)
    return c


def icon_10_security():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.28, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.34, CH * 0.09)
    sh = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.polygon([(CW * 0.5, CH * 0.18), (CW * 0.74, CH * 0.28), (CW * 0.74, CH * 0.52),
                (CW * 0.5, CH * 0.80), (CW * 0.26, CH * 0.52), (CW * 0.26, CH * 0.28)],
               fill=LBLUE_D + (255,))
    sd.polygon([(CW * 0.5, CH * 0.24), (CW * 0.68, CH * 0.32), (CW * 0.68, CH * 0.50),
                (CW * 0.5, CH * 0.72), (CW * 0.32, CH * 0.50), (CW * 0.32, CH * 0.32)],
               fill=LBLUE + (255,))
    c = Image.alpha_composite(c, sh)
    ck = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    kd = ImageDraw.Draw(ck)
    kd.line([(CW * 0.41, CH * 0.44), (CW * 0.47, CH * 0.52), (CW * 0.61, CH * 0.34)],
            fill=WHITE + (255,), width=int(CW * 0.04), joint="curve")
    c = Image.alpha_composite(c, ck)
    return c


def icon_11_branches():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.36, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.84, CW * 0.42, CH * 0.10)
    c = iso_box(c, CW * 0.30, CH * 0.82, CW * 0.26, CH * 0.22, CH * 0.08,
                PORC, CYAN, CYAN_D)
    c = iso_box(c, CW * 0.70, CH * 0.82, CW * 0.26, CH * 0.22, CH * 0.08,
                PORC, PERI, PERI_D)
    c = iso_box(c, CW * 0.5, CH * 0.86, CW * 0.28, CH * 0.36, CH * 0.08,
                PORC, LBLUE, LBLUE_D)
    for (x, y) in [(0.24, 0.60), (0.24, 0.68), (0.64, 0.60), (0.64, 0.68)]:
        c = clay_round(c, (CW * x, CH * y, CW * (x + 0.10), CH * (y + 0.04)),
                       int(CW * 0.008), WHITE)
    for (x, y) in [(0.42, 0.46), (0.42, 0.54), (0.42, 0.62)]:
        c = clay_round(c, (CW * x, CH * y, CW * (x + 0.14), CH * (y + 0.04)),
                       int(CW * 0.008), WHITE)
    return c


def icon_12_sign():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.30, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.36, CH * 0.10)
    c = clay_round(c, (CW * 0.26, CH * 0.26, CW * 0.66, CH * 0.80), int(CW * 0.03), WHITE)
    for i, y in enumerate([0.38, 0.45, 0.52]):
        w = 0.28 if i % 2 == 0 else 0.20
        c = clay_round(c, (CW * 0.33, CH * y, CW * (0.33 + w), CH * (y + 0.03)),
                       int(CW * 0.01), PORC_D)
    sg = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sg)
    sd.line([(CW * 0.33, CH * 0.66), (CW * 0.41, CH * 0.62), (CW * 0.49, CH * 0.68),
             (CW * 0.57, CH * 0.62)],
            fill=BLUE + (255,), width=int(CW * 0.016), joint="curve")
    c = Image.alpha_composite(c, sg)
    pen = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pen)
    pd.line([(CW * 0.60, CH * 0.20), (CW * 0.80, CH * 0.40)], fill=WARM + (255,), width=int(CW * 0.055))
    pd.line([(CW * 0.60, CH * 0.20), (CW * 0.66, CH * 0.26)], fill=WARM_D + (255,), width=int(CW * 0.055))
    pd.polygon([(CW * 0.78, CH * 0.38), (CW * 0.84, CH * 0.44), (CW * 0.76, CH * 0.46)],
               fill=INK + (255,))
    c = Image.alpha_composite(c, pen)
    return c


def icon_13_my_room():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.34, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.40, CH * 0.10)
    c = iso_box(c, CW * 0.5, CH * 0.80, CW * 0.40, CH * 0.26, CH * 0.10,
                PORC, PINK, PINK_D)
    roof = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    rd = ImageDraw.Draw(roof)
    bx, by = CW * 0.5, CH * 0.52
    rd.polygon([(bx - CW * 0.24, by), (bx, by - CH * 0.15), (bx + CW * 0.24, by)],
               fill=PINK + (255,))
    rd.polygon([(bx - CW * 0.24, by), (bx, by - CH * 0.15), (bx, by + CH * 0.02)],
               fill=PINK_D + (255,))
    c = Image.alpha_composite(c, roof)
    c = clay_round(c, (CW * 0.44, CH * 0.62, CW * 0.56, CH * 0.80), int(CW * 0.018), WARM)
    h = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    hd = ImageDraw.Draw(h)
    hx, hy, s = CW * 0.5, CH * 0.40, CW * 0.07
    hd.polygon([(hx, hy + s * 0.7), (hx - s, hy - s * 0.1), (hx - s, hy - s * 0.6),
                (hx - s * 0.4, hy - s * 0.9), (hx, hy - s * 0.3),
                (hx + s * 0.4, hy - s * 0.9), (hx + s, hy - s * 0.6),
                (hx + s, hy - s * 0.1)], fill=WHITE + (255,))
    c = Image.alpha_composite(c, h)
    return c


def icon_14_rating():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.30, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.36, CH * 0.10)
    c = clay_disc(c, (CW * 0.5, CH * 0.50), CW * 0.30, LBLUE)
    star = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(star)
    cx, cy, R, r = CW * 0.5, CH * 0.50, CW * 0.23, CW * 0.10
    pts = []
    for k in range(10):
        a = math.radians(-90 + k * 36)
        rad = R if k % 2 == 0 else r
        pts.append((cx + math.cos(a) * rad, cy + math.sin(a) * rad))
    sd.polygon([(p[0], p[1] + CH * 0.012) for p in pts], fill=AMBER_D + (255,))
    sd.polygon(pts, fill=AMBER + (255,))
    c = Image.alpha_composite(c, star)
    c = clay_disc(c, (CW * 0.5, CH * 0.48), CW * 0.045, _shade(AMBER, 0.4))
    return c


def icon_15_support():
    c = new_canvas()
    c = soft_shadow(c, CW * 0.5, CH * 0.90, CW * 0.30, CH * 0.06)
    c = platform(c, CW * 0.5, CH * 0.82, CW * 0.36, CH * 0.10)
    band = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band)
    bd.arc([CW * 0.24, CH * 0.24, CW * 0.76, CH * 0.76], start=180, end=360,
           fill=PERI + (255,), width=int(CW * 0.06))
    c = Image.alpha_composite(c, band)
    c = clay_round(c, (CW * 0.18, CH * 0.46, CW * 0.31, CH * 0.72), int(CW * 0.045), LBLUE)
    c = clay_round(c, (CW * 0.69, CH * 0.46, CW * 0.82, CH * 0.72), int(CW * 0.045), LBLUE)
    c = clay_round(c, (CW * 0.215, CH * 0.50, CW * 0.275, CH * 0.68), int(CW * 0.018), WHITE)
    c = clay_round(c, (CW * 0.725, CH * 0.50, CW * 0.785, CH * 0.68), int(CW * 0.018), WHITE)
    mic = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    md = ImageDraw.Draw(mic)
    md.arc([CW * 0.41, CH * 0.58, CW * 0.59, CH * 0.82], start=0, end=180,
           fill=PERI_D + (255,), width=int(CW * 0.03))
    md.line([(CW * 0.5, CH * 0.78), (CW * 0.5, CH * 0.86)], fill=PERI_D + (255,),
            width=int(CW * 0.03))
    c = Image.alpha_composite(c, mic)
    return c


BUILDERS = [
    icon_0_search_house,
    icon_1_roommate,
    icon_2_party,
    icon_3_bill,
    icon_4_maintenance,
    icon_5_contract,
    icon_6_invest,
    icon_7_community,
    icon_8_nearby,
    icon_9_collapse,
    icon_10_security,
    icon_11_branches,
    icon_12_sign,
    icon_13_my_room,
    icon_14_rating,
    icon_15_support,
]


def main():
    print(f"Generating {len(BUILDERS)} diorama icons at {W}x{H} (SS={SS}) ...")
    for idx, builder in enumerate(BUILDERS):
        save(builder(), idx)
    print("Done.")


if __name__ == "__main__":
    main()
