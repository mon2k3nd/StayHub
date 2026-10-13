import os
import math
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\categories'
BUILD_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\flutter_assets\assets\images\categories'
FEATURES_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\assets\images\features'
BUILD_FEAT_DIR = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\build\flutter_assets\assets\images\features'

for d in [OUTPUT_DIR, BUILD_DIR, FEATURES_DIR, BUILD_FEAT_DIR]:
    os.makedirs(d, exist_ok=True)

# -------------------------------------------------------------
# Base 3D Clay Isometric Engine
# -------------------------------------------------------------
class ClayCanvas:
    def __init__(self, size=768):
        self.size = size
        self.im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        self.cx = size * 0.5
        self.cy = size * 0.68
        self.scale = size / 5.2
        self.cos30 = math.cos(math.radians(30))
        self.sin30 = math.sin(math.radians(30))

    def proj(self, x, y, z):
        # Isometric 30 deg
        u = self.cx + (x - z) * self.cos30 * self.scale
        v = self.cy + (x + z) * self.sin30 * self.scale - y * self.scale
        return (int(round(u)), int(round(v)))

    def draw_platform(self):
        S = self.size
        # 1. Soft blue ambient shadow underneath
        sh = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        sh_draw = ImageDraw.Draw(sh)
        sh_draw.ellipse([int(S*0.14), int(S*0.62), int(S*0.86), int(S*0.88)], fill=(105, 177, 255, 95))
        sh_draw.ellipse([int(S*0.22), int(S*0.65), int(S*0.78), int(S*0.84)], fill=(37, 99, 235, 75))
        sh = sh.filter(ImageFilter.GaussianBlur(int(S*0.045)))
        self.im = Image.alpha_composite(self.im, sh)

        # 2. Beveled rounded square 3D platform
        # We trace an isometric rounded square in 3D:
        # Corners at (+1.8, 0, +1.8), (+1.8, 0, -1.8), (-1.8, 0, -1.8), (-1.8, 0, +1.8)
        # With thickness dy = 0.22
        plat_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        pdraw = ImageDraw.Draw(plat_layer)

        # Draw skirt / side bevels from bottom to top
        steps = 24
        thick = 0.22
        r = 1.68
        for i in range(steps, -1, -1):
            h_val = -thick * (i / steps)
            ratio = i / steps
            # Color transition: base shadow to top porcelain
            c_r = int(218 + (248 - 218) * (1.0 - ratio))
            c_g = int(228 + (252 - 228) * (1.0 - ratio))
            c_b = int(244 + (255 - 244) * (1.0 - ratio))

            pts = []
            corner_r = 0.38
            # Generate rounded corner polygon in 3D
            corners = [
                (r - corner_r, r - corner_r, 0),      # right
                (-r + corner_r, r - corner_r, 90),    # bottom
                (-r + corner_r, -r + corner_r, 180),  # left
                (r - corner_r, -r + corner_r, 270),   # top
            ]
            for cx, cz, start_deg in corners:
                for deg in range(start_deg, start_deg + 91, 15):
                    rad = math.radians(deg)
                    px = cx + corner_r * math.cos(rad)
                    pz = cz + corner_r * math.sin(rad)
                    pts.append(self.proj(px, h_val, pz))

            pdraw.polygon(pts, fill=(c_r, c_g, c_b, 255))

        # Top surface inner bevel / glow
        top_pts = []
        for cx, cz, start_deg in corners:
            for deg in range(start_deg, start_deg + 91, 15):
                rad = math.radians(deg)
                px = cx + corner_r * math.cos(rad)
                pz = cz + corner_r * math.sin(rad)
                top_pts.append(self.proj(px, 0, pz))
        pdraw.polygon(top_pts, fill=(248, 252, 255, 255))

        # Stepped inner tile podium
        inner_r = 1.45
        in_cr = 0.28
        in_corners = [
            (inner_r - in_cr, inner_r - in_cr, 0),
            (-inner_r + in_cr, inner_r - in_cr, 90),
            (-inner_r + in_cr, -inner_r + in_cr, 180),
            (inner_r - in_cr, -inner_r + in_cr, 270),
        ]
        in_pts = []
        for cx, cz, start_deg in in_corners:
            for deg in range(start_deg, start_deg + 91, 15):
                rad = math.radians(deg)
                px = cx + in_cr * math.cos(rad)
                pz = cz + in_cr * math.sin(rad)
                in_pts.append(self.proj(px, 0.04, pz))
        pdraw.polygon(in_pts, fill=(238, 246, 255, 255), outline=(255, 255, 255, 230))

        self.im = Image.alpha_composite(self.im, plat_layer)

    def draw_box(self, x0, y0, z0, dx, dy, dz, color_top, color_left, color_right, round_bevel=True):
        # 3D box defined by corner (x0, y0, z0) and spans (dx, dy, dz)
        layer = Image.new('RGBA', (self.size, self.size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)

        p000 = self.proj(x0, y0, z0)
        p100 = self.proj(x0 + dx, y0, z0)
        p110 = self.proj(x0 + dx, y0 + dy, z0)
        p010 = self.proj(x0, y0 + dy, z0)

        p001 = self.proj(x0, y0, z0 + dz)
        p101 = self.proj(x0 + dx, y0, z0 + dz)
        p111 = self.proj(x0 + dx, y0 + dy, z0 + dz)
        p011 = self.proj(x0, y0 + dy, z0 + dz)

        # Right face: (x+dx) face (p100, p101, p111, p110)
        draw.polygon([p100, p101, p111, p110], fill=color_right)
        # Left face: (z+dz) face (p001, p101, p111, p011)
        draw.polygon([p001, p101, p111, p011], fill=color_left)
        # Top face: (y+dy) face (p010, p110, p111, p011)
        draw.polygon([p010, p110, p111, p011], fill=color_top)

        if round_bevel:
            # Highlight top rim
            draw.line([p010, p110], fill=(255, 255, 255, 120), width=2)
            draw.line([p110, p111], fill=(255, 255, 255, 90), width=2)
            draw.line([p111, p011], fill=(255, 255, 255, 150), width=2)
            draw.line([p011, p010], fill=(255, 255, 255, 120), width=2)

        self.im = Image.alpha_composite(self.im, layer)

    def draw_sphere(self, x, y, z, radius, color_base, highlight_col=(255, 255, 255)):
        # 3D sphere with radial clay shading
        cx, cy = self.proj(x, y, z)
        r_px = int(radius * self.scale)
        layer = Image.new('RGBA', (self.size, self.size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)

        # Base circle
        draw.ellipse([cx - r_px, cy - r_px, cx + r_px, cy + r_px], fill=(*color_base, 255))
        # Gradient highlight at upper-left
        hl = Image.new('RGBA', (self.size, self.size), (0, 0, 0, 0))
        hdraw = ImageDraw.Draw(hl)
        hl_cx = cx - int(r_px * 0.35)
        hl_cy = cy - int(r_px * 0.35)
        hl_r = int(r_px * 0.55)
        hdraw.ellipse([hl_cx - hl_r, hl_cy - hl_r, hl_cx + hl_r, hl_cy + hl_r], fill=(*highlight_col, 160))
        hl = hl.filter(ImageFilter.GaussianBlur(int(r_px * 0.4)))

        # Mask highlight to sphere bounds
        mask = Image.new('L', (self.size, self.size), 0)
        mdraw = ImageDraw.Draw(mask)
        mdraw.ellipse([cx - r_px, cy - r_px, cx + r_px, cy + r_px], fill=255)

        layer.paste(hl, (0, 0), mask)
        self.im = Image.alpha_composite(self.im, layer)

    def export(self, filepath):
        # Resize from 768 down to 512 with LANCZOS for super crisp quality
        out = self.im.resize((512, 512), Image.Resampling.LANCZOS)
        out.save(filepath, 'PNG')

# -------------------------------------------------------------
# 1. MAT_BANG.PNG (Mặt bằng / Kiot / Shophouse Storefront)
# -------------------------------------------------------------
def build_mat_bang():
    c = ClayCanvas()
    c.draw_platform()

    # Shop Main Building
    # Soft cream/porcelain walls
    c.draw_box(-0.9, 0.04, -0.9, 1.8, 1.6, 1.4,
               color_top=(250, 252, 255, 255),
               color_left=(230, 238, 248, 255),
               color_right=(210, 222, 238, 255))

    # Glass display window (large sky blue glass)
    c.draw_box(-0.8, 0.3, 0.52, 0.8, 0.9, 0.05,
               color_top=(147, 197, 253, 255),
               color_left=(96, 165, 250, 255),
               color_right=(59, 130, 246, 255))

    # Glass Shop Door (with golden handle)
    c.draw_box(0.15, 0.04, 0.52, 0.65, 1.25, 0.05,
               color_top=(191, 219, 254, 255),
               color_left=(147, 197, 253, 255),
               color_right=(96, 165, 250, 255))
    # Golden handle
    c.draw_sphere(0.22, 0.62, 0.6, 0.06, (245, 158, 11))

    # Curved Striped Awning Canopy (Coral Red & White Stripes)
    # Projecting out over the front of the shop
    n_stripes = 6
    w_stripe = 1.9 / n_stripes
    for s in range(n_stripes):
        is_red = (s % 2 == 0)
        c_top = (255, 107, 107, 255) if is_red else (255, 255, 255, 255)
        c_left = (239, 68, 68, 255) if is_red else (241, 245, 249, 255)
        c_right = (220, 38, 38, 255) if is_red else (226, 232, 240, 255)
        c.draw_box(-0.95 + s * w_stripe, 1.35, 0.5, w_stripe, 0.28, 0.55,
                   color_top=c_top, color_left=c_left, color_right=c_right)

    # 3D "SHOP" Signboard above the awning
    c.draw_box(-0.5, 1.7, 0.0, 1.0, 0.35, 0.15,
               color_top=(254, 240, 138, 255),
               color_left=(250, 204, 21, 255),
               color_right=(234, 179, 8, 255))

    # Cute decorative potted shrub next to entrance
    c.draw_sphere(0.95, 0.32, 0.8, 0.22, (34, 197, 94))
    c.draw_box(0.85, 0.04, 0.7, 0.2, 0.2, 0.2,
               color_top=(255, 255, 255, 255),
               color_left=(241, 245, 249, 255),
               color_right=(226, 232, 240, 255))

    p1 = os.path.join(OUTPUT_DIR, 'mat_bang.png')
    p2 = os.path.join(BUILD_DIR, 'mat_bang.png')
    c.export(p1)
    c.export(p2)
    print('Generated mat_bang.png')

# -------------------------------------------------------------
# 2. VAN_PHONG.PNG (Văn phòng / Corporate Office Workspace)
# -------------------------------------------------------------
def build_van_phong():
    c = ClayCanvas()
    c.draw_platform()

    # Wooden Executive Desk
    # Legs
    c.draw_box(-0.9, 0.04, -0.6, 0.12, 0.75, 0.12, (180, 120, 70, 255), (150, 95, 55, 255), (130, 80, 45, 255))
    c.draw_box(0.8, 0.04, -0.6, 0.12, 0.75, 0.12, (180, 120, 70, 255), (150, 95, 55, 255), (130, 80, 45, 255))
    c.draw_box(-0.9, 0.04, 0.4, 0.12, 0.75, 0.12, (180, 120, 70, 255), (150, 95, 55, 255), (130, 80, 45, 255))
    c.draw_box(0.8, 0.04, 0.4, 0.12, 0.75, 0.12, (180, 120, 70, 255), (150, 95, 55, 255), (130, 80, 45, 255))
    # Desktop top surface (warm timber)
    c.draw_box(-1.05, 0.75, -0.7, 2.0, 0.12, 1.25,
               color_top=(235, 175, 120, 255),
               color_left=(210, 150, 95, 255),
               color_right=(185, 130, 80, 255))

    # Ultra-thin Curved Dual-Monitor
    c.draw_box(-0.55, 0.88, -0.3, 1.1, 0.65, 0.06,
               color_top=(219, 234, 254, 255),
               color_left=(96, 165, 250, 255),
               color_right=(37, 99, 235, 255))
    # Stand
    c.draw_box(-0.06, 0.87, -0.3, 0.12, 0.2, 0.15,
               color_top=(200, 210, 220, 255), color_left=(170, 180, 190, 255), color_right=(140, 150, 160, 255))

    # Ergonomic High-Back Office Chair in StayHub Sky Blue
    # Seat
    c.draw_box(-0.35, 0.42, 0.65, 0.7, 0.12, 0.6,
               color_top=(96, 165, 250, 255), color_left=(59, 130, 246, 255), color_right=(37, 99, 235, 255))
    # Backrest
    c.draw_box(-0.35, 0.54, 1.15, 0.7, 0.75, 0.1,
               color_top=(96, 165, 250, 255), color_left=(59, 130, 246, 255), color_right=(37, 99, 235, 255))

    # Warm Arched Desk Lamp with glowing bulb
    c.draw_sphere(-0.75, 1.35, -0.3, 0.15, (250, 204, 21))
    c.draw_box(-0.85, 0.87, -0.35, 0.15, 0.45, 0.08, (245, 158, 11, 255), (217, 119, 6, 255), (180, 83, 9, 255))

    # Colored document files on desk
    c.draw_box(0.55, 0.87, -0.3, 0.35, 0.08, 0.4, (52, 211, 153, 255), (16, 185, 129, 255), (5, 150, 105, 255))
    c.draw_box(0.58, 0.95, -0.28, 0.32, 0.08, 0.38, (248, 113, 113, 255), (239, 68, 68, 255), (220, 38, 38, 255))

    p1 = os.path.join(OUTPUT_DIR, 'van_phong.png')
    p2 = os.path.join(BUILD_DIR, 'van_phong.png')
    c.export(p1)
    c.export(p2)
    print('Generated van_phong.png')

# -------------------------------------------------------------
# 3. KHO_VAN.PNG (Kho xưởng / Industrial Warehouse & Logistics)
# -------------------------------------------------------------
def build_kho_van():
    c = ClayCanvas()
    c.draw_platform()

    # Industrial Warehouse Building
    # Steel walls
    c.draw_box(-0.95, 0.04, -0.9, 1.9, 1.45, 1.3,
               color_top=(241, 245, 249, 255),
               color_left=(203, 213, 225, 255),
               color_right=(148, 163, 184, 255))

    # Pitched Industrial Roof (Teal / Ocean Blue)
    c.draw_box(-1.05, 1.45, -1.0, 2.1, 0.22, 1.5,
               color_top=(56, 189, 248, 255),
               color_left=(14, 165, 233, 255),
               color_right=(2, 132, 199, 255))

    # Metal Roll-Up Shutter Door with horizontal slats
    c.draw_box(-0.55, 0.04, 0.42, 1.1, 1.05, 0.05,
               color_top=(226, 232, 240, 255),
               color_left=(148, 163, 184, 255),
               color_right=(100, 116, 139, 255))
    # Warning hazard bar above door
    c.draw_box(-0.6, 1.08, 0.43, 1.2, 0.12, 0.06,
               color_top=(250, 204, 21, 255),
               color_left=(234, 179, 8, 255),
               color_right=(202, 138, 4, 255))

    # Wooden Shipping Cargo Crates in foreground
    # Crate 1 (Large)
    c.draw_box(0.35, 0.04, 0.65, 0.65, 0.65, 0.65,
               color_top=(245, 180, 110, 255),
               color_left=(217, 135, 60, 255),
               color_right=(180, 100, 40, 255))
    # Crate 2 (Stacked on top)
    c.draw_box(0.42, 0.69, 0.72, 0.5, 0.5, 0.5,
               color_top=(250, 195, 130, 255),
               color_left=(225, 150, 75, 255),
               color_right=(190, 110, 50, 255))
    # Wooden logistics pallet next to it
    c.draw_box(-0.85, 0.04, 0.65, 0.6, 0.15, 0.6,
               color_top=(210, 160, 110, 255),
               color_left=(180, 130, 85, 255),
               color_right=(150, 105, 65, 255))

    p1 = os.path.join(OUTPUT_DIR, 'kho_van.png')
    p2 = os.path.join(BUILD_DIR, 'kho_van.png')
    c.export(p1)
    c.export(p2)
    print('Generated kho_van.png')

# -------------------------------------------------------------
# 4. KHONG_GIAN.PNG (Không gian cộng đồng / Co-working Lounge)
# -------------------------------------------------------------
def build_khong_gian():
    c = ClayCanvas()
    c.draw_platform()

    # Round Communal Discussion Table in center
    c.draw_box(-0.55, 0.45, -0.55, 1.1, 0.1, 1.1,
               color_top=(254, 243, 199, 255),
               color_left=(253, 230, 138, 255),
               color_right=(252, 211, 77, 255))
    # Table center pillar
    c.draw_box(-0.15, 0.04, -0.15, 0.3, 0.41, 0.3,
               color_top=(241, 245, 249, 255),
               color_left=(203, 213, 225, 255),
               color_right=(148, 163, 184, 255))

    # Ceramic coffee mugs on table
    c.draw_sphere(-0.2, 0.62, 0.1, 0.08, (59, 130, 246))
    c.draw_sphere(0.2, 0.62, -0.15, 0.08, (244, 63, 94))

    # 3 Scandinavian Modern Lounge Chairs (Mint, Sky Blue, Warm Orange)
    # Chair 1 (Sky Blue)
    c.draw_sphere(-0.85, 0.38, 0.0, 0.28, (96, 165, 250))
    # Chair 2 (Mint Green)
    c.draw_sphere(0.85, 0.38, 0.0, 0.28, (52, 211, 153))
    # Chair 3 (Warm Coral)
    c.draw_sphere(0.0, 0.38, 0.85, 0.28, (251, 146, 60))

    # Brainstorming Presentation Board on Easel in background
    c.draw_box(-0.6, 0.9, -1.0, 1.2, 0.8, 0.06,
               color_top=(255, 255, 255, 255),
               color_left=(241, 245, 249, 255),
               color_right=(226, 232, 240, 255))
    # Sticky notes on board
    c.draw_box(-0.45, 1.25, -0.96, 0.22, 0.22, 0.02, (254, 240, 138, 255), (250, 204, 21, 255), (234, 179, 8, 255))
    c.draw_box(-0.1, 1.28, -0.96, 0.22, 0.22, 0.02, (167, 243, 208, 255), (110, 231, 183, 255), (52, 211, 153, 255))
    c.draw_box(0.25, 1.22, -0.96, 0.22, 0.22, 0.02, (191, 219, 254, 255), (147, 197, 253, 255), (96, 165, 250, 255))

    p1 = os.path.join(OUTPUT_DIR, 'khong_gian.png')
    p2 = os.path.join(BUILD_DIR, 'khong_gian.png')
    c.export(p1)
    c.export(p2)
    print('Generated khong_gian.png')

# -------------------------------------------------------------
# 5. LUU_TRU.PNG (Lưu trú / Hotel / Homestay / Resort)
# -------------------------------------------------------------
def build_luu_tru():
    c = ClayCanvas()
    c.draw_platform()

    # Boutique Resort Bungalow / Hotel Entrance Canopy
    c.draw_box(-0.85, 0.04, -0.85, 1.7, 1.45, 1.2,
               color_top=(254, 242, 242, 255),
               color_left=(254, 205, 211, 255),
               color_right=(251, 113, 133, 255))
    # Elegant blue pitched roof
    c.draw_box(-0.95, 1.45, -0.95, 1.9, 0.2, 1.4,
               color_top=(147, 197, 253, 255),
               color_left=(96, 165, 250, 255),
               color_right=(37, 99, 235, 255))

    # 3D Leather Travel Suitcase in foreground
    # Teal/Ocean Blue Suitcase
    c.draw_box(0.15, 0.04, 0.55, 0.75, 0.65, 0.4,
               color_top=(45, 212, 191, 255),
               color_left=(20, 184, 166, 255),
               color_right=(13, 148, 136, 255))
    # Golden latches & handle
    c.draw_sphere(0.52, 0.75, 0.75, 0.1, (245, 158, 11))

    # Shiny Golden Concierge Reception Bell
    c.draw_sphere(-0.45, 0.25, 0.7, 0.18, (250, 204, 21))
    c.draw_box(-0.55, 0.04, 0.6, 0.25, 0.08, 0.25, (217, 119, 6, 255), (180, 83, 9, 255), (146, 64, 14, 255))

    # 5 Luxury Golden Stars arched overhead
    for st in range(5):
        star_x = -0.6 + st * 0.3
        star_y = 1.85 + math.sin(st * math.pi / 4.0) * 0.12
        c.draw_sphere(star_x, star_y, -0.2, 0.09, (250, 204, 21))

    p1 = os.path.join(OUTPUT_DIR, 'luu_tru.png')
    p2 = os.path.join(BUILD_DIR, 'luu_tru.png')
    c.export(p1)
    c.export(p2)
    print('Generated luu_tru.png')

# -------------------------------------------------------------
# 6. DAT_CHO_THUE.PNG (Đất trống / Land Lot for Rent)
# -------------------------------------------------------------
def build_dat_cho_thue():
    c = ClayCanvas()
    c.draw_platform()

    # Lush Green Lawn Layer (Isometric Grass Slab)
    c.draw_box(-1.45, 0.04, -1.45, 2.9, 0.15, 2.9,
               color_top=(52, 211, 153, 255),
               color_left=(16, 185, 129, 255),
               color_right=(5, 150, 105, 255))

    # Wooden Picket Perimeter Fence Posts
    for fx in [-1.3, -0.4, 0.5, 1.3]:
        c.draw_box(fx, 0.19, 1.35, 0.08, 0.35, 0.08, (245, 190, 140, 255), (217, 135, 70, 255), (180, 100, 45, 255))
        c.draw_box(1.35, 0.19, fx, 0.08, 0.35, 0.08, (245, 190, 140, 255), (217, 135, 70, 255), (180, 100, 45, 255))
    # Horizontal fence rails
    c.draw_box(-1.3, 0.32, 1.35, 2.65, 0.06, 0.06, (254, 215, 170, 255), (251, 146, 60, 255), (234, 88, 12, 255))
    c.draw_box(1.35, 0.32, -1.3, 0.06, 0.06, 2.65, (254, 215, 170, 255), (251, 146, 60, 255), (234, 88, 12, 255))

    # Tall Survey Flag (Red/Coral fluttering flag in center)
    # Pole
    c.draw_box(-0.04, 0.19, -0.04, 0.08, 1.5, 0.08, (226, 232, 240, 255), (148, 163, 184, 255), (100, 116, 139, 255))
    # Triangular red flag
    c.draw_box(0.04, 1.3, -0.04, 0.55, 0.35, 0.04, (248, 113, 113, 255), (239, 68, 68, 255), (220, 38, 38, 255))

    # Round Clay Apple Tree on the plot
    # Trunk
    c.draw_box(-0.85, 0.19, -0.85, 0.16, 0.45, 0.16, (180, 100, 50, 255), (140, 75, 35, 255), (110, 55, 25, 255))
    # Foliage
    c.draw_sphere(-0.77, 0.85, -0.77, 0.42, (34, 197, 94))
    # Tiny flower blossoms on grass
    c.draw_sphere(0.65, 0.22, 0.3, 0.06, (255, 255, 255))
    c.draw_sphere(0.3, 0.22, 0.8, 0.06, (254, 240, 138))

    p1 = os.path.join(OUTPUT_DIR, 'dat_cho_thue.png')
    p2 = os.path.join(BUILD_DIR, 'dat_cho_thue.png')
    c.export(p1)
    c.export(p2)
    print('Generated dat_cho_thue.png')

# -------------------------------------------------------------
# 7. O_GHEP.PNG (Ở ghép / KTX - Student Bunk Bed / Dormitory)
# -------------------------------------------------------------
def build_o_ghep():
    # Use authentic high-res student roommate render from user's sample
    src = r'c:\Users\PHD\Desktop\StayHub\StayHub_frontend\o_ghep_full.png'
    if os.path.exists(src):
        im = Image.open(src).convert('RGBA')
        # Apply clean transparent background cutout
        arr = np.array(im)
        # Background is pale blue/white (r>230, g>235, b>245)
        r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
        bg_mask = (r > 232) & (g > 238) & (b > 245)
        # Soft alpha falloff
        alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
        alpha = cv2.GaussianBlur(alpha, (5, 5), 0)
        arr[:,:,3] = alpha
        clean = Image.fromarray(arr).resize((512, 512), Image.Resampling.LANCZOS)
        p1 = os.path.join(OUTPUT_DIR, 'o_ghep.png')
        p2 = os.path.join(BUILD_DIR, 'o_ghep.png')
        clean.save(p1)
        clean.save(p2)
        print('Generated o_ghep.png from authentic 3D master')

# -------------------------------------------------------------
# 8. ICON_RESIDENT_PERKS.PNG (Ưu đãi cư dân StayHub - 3D VIP Gift Box)
# -------------------------------------------------------------
def build_resident_perks():
    c = ClayCanvas(size=512)
    # Gift Box Body in StayHub Sky Blue
    c.draw_box(-0.85, 0.1, -0.85, 1.7, 1.3, 1.7,
               color_top=(147, 197, 253, 255),
               color_left=(96, 165, 250, 255),
               color_right=(37, 99, 235, 255))
    # Box Lid
    c.draw_box(-0.95, 1.25, -0.95, 1.9, 0.28, 1.9,
               color_top=(191, 219, 254, 255),
               color_left=(147, 197, 253, 255),
               color_right=(96, 165, 250, 255))
    # Shimmering Gold Ribbon along X
    c.draw_box(-0.96, 0.1, -0.2, 1.92, 1.45, 0.4,
               color_top=(254, 240, 138, 255),
               color_left=(250, 204, 21, 255),
               color_right=(217, 119, 6, 255))
    # Shimmering Gold Ribbon along Z
    c.draw_box(-0.2, 0.1, -0.96, 0.4, 1.45, 1.92,
               color_top=(254, 240, 138, 255),
               color_left=(250, 204, 21, 255),
               color_right=(217, 119, 6, 255))
    # Golden Bow Knot on top
    c.draw_sphere(0.0, 1.65, 0.0, 0.25, (250, 204, 21))
    c.draw_sphere(-0.28, 1.72, 0.0, 0.2, (253, 224, 71))
    c.draw_sphere(0.28, 1.72, 0.0, 0.2, (253, 224, 71))
    # Sparkle stars
    c.draw_sphere(-0.8, 1.8, 0.5, 0.1, (254, 240, 138))
    c.draw_sphere(0.8, 1.7, -0.5, 0.1, (254, 240, 138))

    p1 = os.path.join(OUTPUT_DIR, 'icon_resident_perks.png')
    p2 = os.path.join(BUILD_DIR, 'icon_resident_perks.png')
    c.export(p1)
    c.export(p2)
    print('Generated icon_resident_perks.png')

# -------------------------------------------------------------
# 9. ICON_REFERRAL_REWARD.PNG (Giới thiệu bạn thuê phòng - 200K Bonus)
# -------------------------------------------------------------
def build_referral_reward():
    c = ClayCanvas(size=512)
    # Red/Coral Gift Envelope Wallet
    c.draw_box(-0.85, 0.1, -0.4, 1.7, 1.2, 0.8,
               color_top=(254, 205, 211, 255),
               color_left=(251, 113, 133, 255),
               color_right=(225, 29, 72, 255))
    # Crisp Green Cash Note (200K) emerging from envelope
    c.draw_box(-0.65, 0.8, -0.2, 1.3, 0.75, 0.08,
               color_top=(167, 243, 208, 255),
               color_left=(52, 211, 153, 255),
               color_right=(16, 185, 129, 255))
    # Shiny Stack of Gold Coins in front
    c.draw_box(0.3, 0.1, 0.5, 0.45, 0.15, 0.45, (254, 240, 138, 255), (250, 204, 21, 255), (217, 119, 6, 255))
    c.draw_box(0.3, 0.26, 0.5, 0.45, 0.15, 0.45, (254, 240, 138, 255), (250, 204, 21, 255), (217, 119, 6, 255))
    c.draw_box(0.3, 0.42, 0.5, 0.45, 0.15, 0.45, (254, 240, 138, 255), (250, 204, 21, 255), (217, 119, 6, 255))

    p1 = os.path.join(OUTPUT_DIR, 'icon_referral_reward.png')
    p2 = os.path.join(BUILD_DIR, 'icon_referral_reward.png')
    c.export(p1)
    c.export(p2)
    print('Generated icon_referral_reward.png')

# -------------------------------------------------------------
# 10. FEAT_LOCATION.PNG (Vị trí GPS / Location Map Pin)
# -------------------------------------------------------------
def build_location_pin():
    c = ClayCanvas(size=512)
    c.draw_platform()
    # Radar Pulse Rings on platform
    # 3D Teardrop Location Pin
    # Pin Head
    c.draw_sphere(0.0, 1.45, 0.0, 0.55, (37, 99, 235))
    # Inner White Eye
    c.draw_sphere(0.0, 1.45, 0.35, 0.22, (255, 255, 255))
    # Pin Tip Cone pointing down to platform
    c.draw_box(-0.15, 0.25, -0.15, 0.3, 0.9, 0.3,
               color_top=(96, 165, 250, 255),
               color_left=(37, 99, 235, 255),
               color_right=(29, 78, 216, 255))

    p1 = os.path.join(FEATURES_DIR, 'feat_location.png')
    p2 = os.path.join(BUILD_FEAT_DIR, 'feat_location.png')
    c.export(p1)
    c.export(p2)
    print('Generated feat_location.png')

if __name__ == '__main__':
    build_mat_bang()
    build_van_phong()
    build_kho_van()
    build_khong_gian()
    build_luu_tru()
    build_dat_cho_thue()
    build_o_ghep()
    build_resident_perks()
    build_referral_reward()
    build_location_pin()
    print('ALL ICONS SUCCESSFULLY CREATED & SYNCHRONIZED!')
