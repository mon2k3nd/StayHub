"""
remove_icons_background.py
==========================
High-fidelity background removal for the horizontal 3D icon strip
(`temp_mau.png` -> `icons_transparent.png`).

STRICT REQUIREMENTS SATISFIED
-----------------------------
1. NO CROP / NO RESIZE : the output keeps the EXACT original resolution and
   horizontal layout. A single RGBA PNG is produced.
2. PERFECT ALPHA MATTING : the flat blue gradient background is removed and
   replaced with a true transparent (alpha = 0) background.
3. SOFT SHADOW / AO PRESERVATION : soft contact shadows and ambient-occlusion
   gradients under the 3D buildings are kept as *semi-transparent* pixels
   (partial alpha) instead of being hard-clipped, so edges stay smooth with no
   halo, no jaggies and no "eaten" rim.
4. OUTPUT : `icons_transparent.png` with a standard RGBA channel.

ALGORITHM
---------
The source background is a near-uniform light-blue gradient
(~RGB 235,245,253, std < 2). This is exploited for a physically accurate
matte instead of a coarse segmentation:

  A. Estimate the background colour field (per-column, robust border sampling)
     so the subtle horizontal/vertical gradient is modelled, not assumed flat.
  B. Compute a per-pixel "background likeness" distance in a perceptual space
     (weighted RGB + local contrast) -> raw foreground probability.
  C. Build a trimap (definite BG / unknown / definite FG) via hysteresis
     thresholding + morphological cleanup.
  D. Solve a closed-form-ish alpha matte inside the unknown band using a
     guided-filter style edge-aware refinement (keeps soft shadow gradients).
  E. Recover true foreground colour by un-premultiplying the background
     (F = (C - (1-a)B) / a) to kill the blue fringe on anti-aliased edges.
  F. Preserve soft shadows: low-contrast dark/desaturated regions that are
     spatially attached to the icons are retained with partial alpha.

Dependencies: numpy, Pillow, scipy (optional, falls back to pure numpy).
"""

from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageFilter

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
SRC = r"c:\Users\PHD\Desktop\StayHub\temp_mau.png"
DST = r"c:\Users\PHD\Desktop\StayHub\icons_transparent.png"

# Hysteresis thresholds on the 0..1 background-likeness score.
#   score >= FG_T  -> definite foreground
#   score <= BG_T  -> definite background
#   in between     -> unknown band (solved by matting)
FG_T = 0.62
BG_T = 0.30

# Shadow preservation: how much of a *dark but low-saturation* region attached
# to the icons is kept. 0 = off, 1 = keep everything.
SHADOW_KEEP = 0.85

# Edge refinement radius (px) for the guided-filter style matte.
REFINE_RADIUS = 6
REFINE_EPS = 1e-3

# Anti-fringe strength when un-premultiplying the background colour.
DEFRINGE = 1.0


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def _box_blur(img: np.ndarray, radius: int) -> np.ndarray:
    """Fast separable box blur (mean filter) on a float array (H,W) or (H,W,C)."""
    if radius <= 0:
        return img
    k = 2 * radius + 1
    pad = radius
    if img.ndim == 2:
        img = img[:, :, None]
        squeeze = True
    else:
        squeeze = False

    padded = np.pad(img, ((pad, pad), (pad, pad), (0, 0)), mode="edge")
    # cumulative sum along axis 0 then axis 1
    c = np.cumsum(padded, axis=0)
    c = np.concatenate([np.zeros((1,) + c.shape[1:], c.dtype), c], axis=0)
    out = (c[k:, :, :] - c[:-k, :, :]) / k

    c = np.cumsum(out, axis=1)
    c = np.concatenate([np.zeros((c.shape[0], 1) + c.shape[2:], c.dtype), c], axis=1)
    out = (c[:, k:, :] - c[:, :-k, :]) / k

    if squeeze:
        out = out[:, :, 0]
    return out


def _gaussian(img: np.ndarray, sigma: float) -> np.ndarray:
    """Gaussian blur via PIL (handles float by scaling)."""
    if sigma <= 0:
        return img
    is2d = img.ndim == 2
    if is2d:
        img = img[:, :, None]
    h, w, c = img.shape
    out = np.empty_like(img)
    for i in range(c):
        ch = img[:, :, i]
        lo, hi = float(ch.min()), float(ch.max())
        rng = hi - lo if hi > lo else 1.0
        norm = ((ch - lo) / rng * 255.0).astype(np.uint8)
        pil = Image.fromarray(norm, mode="L").filter(ImageFilter.GaussianBlur(sigma))
        out[:, :, i] = np.asarray(pil, dtype=np.float32) / 255.0 * rng + lo
    return out[:, :, 0] if is2d else out


def _guided_filter(guide: np.ndarray, src: np.ndarray, radius: int, eps: float) -> np.ndarray:
    """
    Edge-aware guided filter (He et al.). `guide` and `src` are float (H,W).
    Preserves soft gradients (shadows) while snapping to real edges.
    """
    mean_g = _box_blur(guide, radius)
    mean_s = _box_blur(src, radius)
    corr_gg = _box_blur(guide * guide, radius)
    corr_gs = _box_blur(guide * src, radius)

    var_g = corr_gg - mean_g * mean_g
    cov_gs = corr_gs - mean_g * mean_s

    a = cov_gs / (var_g + eps)
    b = mean_s - a * mean_g

    mean_a = _box_blur(a, radius)
    mean_b = _box_blur(b, radius)
    return mean_a * guide + mean_b


def _morph(mask: np.ndarray, radius: int, mode: str) -> np.ndarray:
    """Binary morphology via box blur thresholding (numpy only)."""
    if radius <= 0:
        return mask
    dens = _box_blur(mask.astype(np.float32), radius)
    if mode == "dilate":
        return (dens > 0.0).astype(np.float32)
    if mode == "erode":
        return (dens >= 0.999).astype(np.float32)
    raise ValueError(mode)


# --------------------------------------------------------------------------- #
# Core pipeline
# --------------------------------------------------------------------------- #
def estimate_background(rgb: np.ndarray) -> np.ndarray:
    """
    Model the background colour field. The source has a very gentle gradient,
    so we sample the border ring and fit a smooth low-order field per channel
    using a heavily blurred border-constrained image.
    """
    h, w, _ = rgb.shape
    border = 8

    # Robust global background colour from the border ring.
    ring = np.concatenate([
        rgb[:border].reshape(-1, 3),
        rgb[-border:].reshape(-1, 3),
        rgb[:, :border].reshape(-1, 3),
        rgb[:, -border:].reshape(-1, 3),
    ])
    bg_global = np.median(ring, axis=0)

    # Per-column background (captures horizontal gradient) from top+bottom rows.
    top = np.median(rgb[:border], axis=0)          # (w,3)
    bot = np.median(rgb[-border:], axis=0)         # (w,3)
    col_bg = 0.5 * (top + bot)                     # (w,3)

    # Per-row background (captures vertical gradient) from left+right cols.
    left = np.median(rgb[:, :border], axis=1)      # (h,3)
    right = np.median(rgb[:, -border:], axis=1)    # (h,3)
    row_bg = 0.5 * (left + right)                  # (h,3)

    # Separable smooth field: blend column & row models, then smooth.
    field = 0.5 * col_bg[None, :, :] + 0.5 * row_bg[:, None, :]
    # Blend toward the global colour to avoid over-fitting to icon pixels that
    # may touch the border.
    field = 0.7 * field + 0.3 * bg_global[None, None, :]
    field = _gaussian(field, sigma=max(h, w) * 0.02)
    return field


def background_likeness(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """
    Per-pixel score in [0,1]: 1 = looks exactly like background,
    0 = clearly foreground. Uses a perceptual weighted distance plus a
    local-contrast term so flat background scores high even with gradient.
    """
    diff = rgb - bg
    # Perceptual weights (human vision is most sensitive to green).
    w = np.array([0.30, 0.59, 0.11], dtype=np.float32)
    dist = np.sqrt(np.sum((diff * diff) * w[None, None, :], axis=2))

    # Normalise distance to a 0..1 score with a soft knee.
    # Background noise is ~2-3 units; real content is >25 units.
    score = np.clip(1.0 - dist / 42.0, 0.0, 1.0)

    # Local contrast: background is flat, icons have texture.
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    local_mean = _box_blur(lum, 4)
    contrast = np.abs(lum - local_mean)
    score = score * np.clip(1.0 - contrast / 18.0, 0.0, 1.0)

    return score.astype(np.float32)


def build_trimap(score: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Hysteresis trimap: returns (fg, bg, unknown) float masks.

    NOTE on semantics: `score` is BACKGROUND-likeness (1 = background,
    0 = foreground). Therefore a HIGH score means background and a LOW score
    means foreground.
    """
    fg = (score <= BG_T).astype(np.float32)
    bg = (score >= FG_T).astype(np.float32)

    # Clean speckle: remove tiny isolated fg blobs, fill tiny bg holes.
    fg = _morph(fg, 2, "dilate")
    fg = _morph(fg, 2, "erode")
    bg = _morph(bg, 2, "dilate")
    bg = _morph(bg, 2, "erode")

    unknown = np.clip(1.0 - fg - bg, 0.0, 1.0)
    return fg, bg, unknown


def solve_matte(rgb: np.ndarray, bg: np.ndarray, score: np.ndarray,
                fg: np.ndarray, bgm: np.ndarray, unknown: np.ndarray) -> np.ndarray:
    """
    Produce a continuous alpha matte in [0,1].
    Definite regions are pinned; the unknown band is solved with a guided
    filter that respects the image edges (keeps soft shadow gradients).
    """
    # Initial alpha: 1 in fg, 0 in bg, score-derived in unknown.
    alpha0 = np.where(fg > 0.5, 1.0, np.where(bgm > 0.5, 0.0, 1.0 - score))

    # Guide = luminance of the source (edges align with real object borders).
    lum = (rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)) / 255.0

    # Edge-aware refinement of the unknown band only.
    refined = _guided_filter(lum, alpha0, REFINE_RADIUS, REFINE_EPS)

    alpha = np.where(unknown > 0.5, refined, alpha0)
    alpha = np.where(fg > 0.5, 1.0, alpha)
    alpha = np.where(bgm > 0.5, 0.0, alpha)
    return np.clip(alpha, 0.0, 1.0).astype(np.float32)


def preserve_shadows(rgb: np.ndarray, bg: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    """
    Keep soft contact shadows / ambient occlusion.

    Shadow pixels are: darker than the background, low saturation, and
    spatially attached to the icon silhouette. They receive a partial alpha
    proportional to their darkness so the gradient stays smooth.

    The source shadows are subtle (only ~15-45 luminance units darker than the
    light-blue background), so the darkness response is tuned to that range and
    the "attached" mask is generous enough to cover the full shadow footprint.
    """
    diff = rgb - bg
    lum_diff = diff @ np.array([0.299, 0.587, 0.114], dtype=np.float32)

    # Darkness relative to background (positive = darker than bg).
    # Tuned for subtle shadows: full weight at ~35 units darker.
    darkness = np.clip(-lum_diff / 35.0, 0.0, 1.0)
    # Soft knee so faint shadow tails fade out smoothly instead of clipping.
    darkness = darkness ** 0.85

    # Saturation of the pixel (shadows are desaturated, icons are colourful).
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1.0), 0.0)
    # Shadows keep a slight blue tint, so allow a little saturation.
    desat = np.clip(1.0 - sat / 0.45, 0.0, 1.0)

    shadow_score = darkness * desat

    # Only keep shadows that are near existing foreground (attached).
    # A wide radius captures the full soft-shadow footprint beneath icons.
    near_fg = _box_blur((alpha > 0.5).astype(np.float32), 26)
    attached = np.clip(near_fg * 2.2, 0.0, 1.0)

    shadow_alpha = shadow_score * attached * SHADOW_KEEP

    # Combine: never reduce existing alpha, only add shadow coverage.
    out = np.maximum(alpha, shadow_alpha)
    return np.clip(out, 0.0, 1.0).astype(np.float32)


def defringe(rgb: np.ndarray, bg: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    """
    Un-premultiply the background from anti-aliased edge pixels so no blue
    halo remains:  F = (C - (1-a) * B) / a.

    Applied fully (not blended back toward the original) on every pixel with
    meaningful alpha, then a mild saturation boost removes any residual blue
    cast left on the soft edges.
    """
    a = alpha[:, :, None]
    safe = np.maximum(a, 1e-3)
    fg = (rgb - (1.0 - a) * bg) / safe
    fg = np.clip(fg, 0.0, 255.0)

    # Residual blue-cast removal: on semi-transparent pixels, if the recovered
    # colour is still bluer than it is bright, pull the blue channel down
    # toward the red/green average (kills the light-blue fringe).
    semi = (alpha > 0.02) & (alpha < 0.98)
    if semi.any():
        r, g, b = fg[:, :, 0], fg[:, :, 1], fg[:, :, 2]
        rg = 0.5 * (r + g)
        excess = np.clip(b - rg, 0.0, None)
        b_new = b - excess * DEFRINGE
        fg[:, :, 2] = np.where(semi, b_new, b)

    # Fully transparent pixels: keep the original colour (invisible anyway).
    out = np.where(a > 0.0, fg, rgb)
    return np.clip(out, 0.0, 255.0).astype(np.float32)


def smooth_alpha(alpha: np.ndarray) -> np.ndarray:
    """Final light smoothing to remove any residual stair-stepping."""
    a = _gaussian(alpha, 0.6)
    return np.clip(a, 0.0, 1.0)


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
def main() -> int:
    if not os.path.isfile(SRC):
        print(f"[ERROR] source not found: {SRC}", file=sys.stderr)
        return 1

    src = Image.open(SRC).convert("RGB")
    W, H = src.size
    print(f"[1/7] loaded {SRC}  size={W}x{H}")

    rgb = np.asarray(src, dtype=np.float32)

    print("[2/7] estimating background field ...")
    bg = estimate_background(rgb)

    print("[3/7] computing background-likeness ...")
    score = background_likeness(rgb, bg)

    print("[4/7] building trimap ...")
    fg, bgm, unknown = build_trimap(score)
    print(f"      fg={fg.mean():.3f}  bg={bgm.mean():.3f}  unknown={unknown.mean():.3f}")

    print("[5/7] solving alpha matte (edge-aware) ...")
    alpha = solve_matte(rgb, bg, score, fg, bgm, unknown)

    print("[6/7] preserving soft shadows / AO ...")
    alpha = preserve_shadows(rgb, bg, alpha)
    alpha = smooth_alpha(alpha)

    print("[7/7] de-fringing + writing RGBA ...")
    fg_rgb = defringe(rgb, bg, alpha)

    out = np.dstack([fg_rgb, alpha * 255.0]).astype(np.uint8)
    result = Image.fromarray(out, mode="RGBA")

    # Hard guarantee: identical resolution, no crop.
    assert result.size == (W, H), "resolution changed!"
    result.save(DST, "PNG", optimize=True)

    print(f"[OK] wrote {DST}  size={result.size}  mode={result.mode}")
    print(f"     transparent px: {(alpha < 0.02).mean() * 100:.1f}%")
    print(f"     opaque px     : {(alpha > 0.98).mean() * 100:.1f}%")
    print(f"     soft/partial  : {((alpha >= 0.02) & (alpha <= 0.98)).mean() * 100:.1f}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
