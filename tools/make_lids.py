#!/usr/bin/env python3
"""Painted lids for the blink (char_rig.gdshader `lid_tex`).
For every rig with measured eyes, the eye openings and the upper lashes are inpainted away (OpenCV Telea,
then softened) on a crop around the eyes. The closed lid then shows the face's own shading, blush and the
hair that crosses it, instead of one flat skin colour. Writes art/lids/<art>_lid.png and sets
rig["lid"] = [res path, x, y, w, h] (UV rect of the crop on the art).
Usage: python3 tools/make_lids.py <rigs.json> [more.json ...]   (files are updated in place)"""
import json, math, os, sys
import numpy as np, cv2
from PIL import Image

OUT = 'art/lids'


def arc_of(qx):
    return np.sqrt(np.clip(1.0 - np.minimum(np.abs(qx), 1.0) ** 2, 0, 1))


def eye_geom(e, W, H):
    """Shader geometry of one measured eye (game/ui/char_rig.gd _set_eyes): centre px, angle, half sizes px."""
    asp = W / H
    ax, ay = (e[2] - e[0]) * asp, e[3] - e[1]
    if ax < 0:
        ax, ay = -ax, -ay
    ang = math.atan2(ay, ax)
    hw = math.hypot(ax, ay) * 0.5 * 1.12 * H        # half width in px
    hh = (e[5] - e[4]) * 0.5 * 1.1 * H               # half height in px
    cx = (e[0] + e[2]) * 0.5 * W
    cy = (e[4] + e[5]) * 0.5 * H
    return cx, cy, ang, hw, hh


def make(path, rig):
    if rig.get('lid_keep') and rig.get('lid') and os.path.exists(rig['lid'][0].replace('res://', '')):
        return rig['lid'][0]      # hand-approved lid: not regenerated
    eyes = [e for e in rig.get('eyes', []) if len(e) == 6]
    if not eyes:
        rig.pop('lid', None)
        return None
    src = path.replace('res://', '')
    im = Image.open(src).convert('RGBA')
    W, H = im.size
    reach = float(rig.get('lid_reach', 1.0))
    geo = [eye_geom(e, W, H) for e in eyes]
    # crop: all eyes plus a margin of 2 eye heights / 0.6 eye widths
    xs, ys = [], []
    for cx, cy, ang, hw, hh in geo:
        r = max(hw * 1.6, hh * 4.0)
        xs += [cx - r, cx + r]
        ys += [cy - r, cy + r]
    x0, y0 = max(0, int(min(xs))), max(0, int(min(ys)))
    x1, y1 = min(W, int(math.ceil(max(xs)))), min(H, int(math.ceil(max(ys))))
    crop = np.asarray(im)[y0:y1, x0:x1].copy()
    rgb = crop[..., :3].copy()
    mask = np.zeros(rgb.shape[:2], np.uint8)
    yy, xx = np.mgrid[0:rgb.shape[0], 0:rgb.shape[1]].astype(np.float32)
    for cx, cy, ang, hw, hh in geo:
        dx, dy = xx + x0 - cx, yy + y0 - cy
        lx = math.cos(ang) * dx + math.sin(ang) * dy
        ly = -math.sin(ang) * dx + math.cos(ang) * dy
        qx, qy = lx / hw, ly / max(hh, 1.0)
        arc = np.sqrt(np.clip(1.0 - np.minimum(np.abs(qx), 1.0) ** 2, 0, 1))
        # the opening and the painted upper lash band above it (which the blink moves down)
        m = (np.abs(qx) < 1.18) & (qy > -arc - 0.55 - 0.55 * reach) & (qy < arc + 0.45)
        mask |= m.astype(np.uint8)
    # lashes, liner and lid creases reach past the measured opening: every dark or eye-coloured pixel close
    # to an eye joins the hole, so the fill comes from skin only (not from the lash line)
    lum = rgb.astype(np.float32) @ np.array([0.3, 0.55, 0.15], np.float32)
    sat = rgb.max(2).astype(np.float32) - rgb.min(2)
    for cx, cy, ang, hw, hh in geo:
        dx, dy = xx + x0 - cx, yy + y0 - cy
        lx = math.cos(ang) * dx + math.sin(ang) * dy
        ly = -math.sin(ang) * dx + math.cos(ang) * dy
        qx, qy = lx / hw, ly / max(hh, 1.0)
        ring = (np.abs(qx) < 1.0) & (qy > 1.6) & (qy < 3.2)          # cheek just below the eye
        skin_l = float(np.median(lum[ring])) if ring.any() else float(np.median(lum))
        near = (np.abs(qx) < 1.15) & (qy > -arc_of(qx) - 0.45 - 0.5 * reach) & (qy < arc_of(qx) + 0.7)   # lash band only: hair strands above stay
        mask |= (near & ((lum < skin_l * 0.78) | (sat > 140))).astype(np.uint8)
        # eye white / catch-lights just outside the measured opening would leak into the fill as a pale streak
        white = (lum > skin_l * 1.06) & (sat < 60) & (np.abs(qx) < 1.25) & (qy > -arc_of(qx) - 0.4) & (qy < arc_of(qx) + 0.5)
        mask |= white.astype(np.uint8)
    # hair is dark like a lash but continues far outside the eye: dark blobs that are mostly outside the
    # lash zone are hair, and stay (only the eye opening itself is always removed)
    opening = np.zeros(mask.shape, bool)
    zone = np.zeros(mask.shape, bool)
    for cx, cy, ang, hw, hh in geo:
        dx, dy = xx + x0 - cx, yy + y0 - cy
        lx = math.cos(ang) * dx + math.sin(ang) * dy
        ly = -math.sin(ang) * dx + math.cos(ang) * dy
        qx, qy = lx / hw, ly / max(hh, 1.0)
        opening |= (np.abs(qx) < 1.0) & (np.abs(qy) < arc_of(qx) + 0.15)
        zone |= (np.abs(qx) < 1.3) & (qy > -arc_of(qx) - 1.3) & (qy < arc_of(qx) + 1.0)
    dark = (lum < skin_l * 0.78).astype(np.uint8)
    nlab, lab = cv2.connectedComponents(dark, connectivity=8)
    for i in range(1, nlab):
        comp = lab == i
        n = comp.sum()
        if n > 30 and (comp & ~zone).sum() > 0.35 * n:
            mask[comp & ~opening] = 0
    mask = cv2.dilate(mask, np.ones((3, 3), np.uint8), iterations=2)
    # Fill = diffusion of the surrounding SKIN only (rigs with 'lid_paint' keep OpenCV Telea instead: bold
    # anime lids whose shading should follow the painted crease): every hole pixel takes a smooth, distance-weighted
    # average of nearby skin pixels (lashes, brows, hair and eye white are left out), at several scales so
    # wide holes still find skin. The result continues the face's own shading and has no hard outline.
    hh_min = min(g[4] for g in geo)
    cheek = np.zeros(rgb.shape[:2], bool)
    for cx, cy, ang, hw, hh in geo:
        dx, dy = xx + x0 - cx, yy + y0 - cy
        lx = math.cos(ang) * dx + math.sin(ang) * dy
        ly = -math.sin(ang) * dx + math.cos(ang) * dy
        qx, qy = lx / hw, ly / max(hh, 1.0)
        # skin sample: a ring all around the eye (upper lid, corners and cheek) just outside the hole
        rr = np.sqrt(qx ** 2 + (qy * 0.5) ** 2)
        cheek |= (rr > 1.25) & (rr < 2.0) & (mask == 0)
    src_px = rgb[cheek] if cheek.sum() > 20 else rgb[mask == 0]
    sl = src_px.astype(np.float32) @ np.array([0.3, 0.55, 0.15], np.float32)
    tone = np.median(src_px[(sl >= np.percentile(sl, 30)) & (sl <= np.percentile(sl, 90))].astype(np.float32), 0)
    f = rgb.astype(np.float32)
    dist = np.linalg.norm(f - tone, axis=2)
    alpha_px = crop[..., 3].astype(np.float32) / 255.0
    valid = ((mask == 0) & (dist < 62.0) & (alpha_px > 0.9)).astype(np.float32)
    fill = np.zeros_like(f)
    have = np.zeros(f.shape[:2], np.float32)
    for sig in (hh_min * 0.8, hh_min * 1.6, hh_min * 3.2, hh_min * 6.0):
        sig = max(1.5, sig)
        num = cv2.GaussianBlur(f * valid[..., None], (0, 0), sig)
        den = cv2.GaussianBlur(valid, (0, 0), sig)
        est = num / np.maximum(den, 1e-4)[..., None]
        take = (den > 0.04) & (have < 0.5)
        fill[take] = est[take]
        have[take] = 1.0
    fill[have < 0.5] = tone
    # match the fill's brightness to the skin right around the hole (diffusion favours the lighter cheek)
    ring_b = (cv2.dilate(mask, np.ones((3, 3), np.uint8), iterations=3) > 0) & (mask == 0) & (valid > 0)
    if ring_b.sum() > 10:
        lw_ = np.array([0.3, 0.55, 0.15], np.float32)
        ratio = float(np.median(f[ring_b] @ lw_)) / max(float(np.median(fill[mask > 0] @ lw_)), 1.0)
        fill = np.where((mask > 0)[..., None], fill * np.clip(ratio, 0.8, 1.0), fill)
    # whole hole = fill (dilated first so no original lash / eye-white pixel shows through inside it)
    if rig.get('lid_paint'):
        bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
        tel = cv2.cvtColor(cv2.inpaint(bgr, mask * 255, max(3, int(hh_min * 0.8)), cv2.INPAINT_TELEA), cv2.COLOR_BGR2RGB).astype(np.float32)
        tel = cv2.GaussianBlur(tel, (0, 0), max(1.2, hh_min * 0.35))
        fill = np.where((mask > 0)[..., None], tel, fill)
    fm = cv2.GaussianBlur(cv2.dilate(mask, np.ones((3, 3), np.uint8), iterations=2).astype(np.float32), (0, 0), max(1.0, hh_min * 0.15))[..., None]
    fm = np.clip(fm * 1.3, 0, 1)
    out = np.clip(fill * fm + f * (1 - fm), 0, 255).astype(np.uint8)
    os.makedirs(OUT, exist_ok=True)
    name = os.path.splitext(os.path.basename(src))[0] + '_lid.png'
    # alpha = where the eye was removed (soft): the shader only corrects colours there
    # soft, wide feather: the painted-out area melts into the untouched art (no patch outline)
    grow = cv2.dilate(mask, np.ones((3, 3), np.uint8), iterations=max(1, int(hh_min * 0.25)))
    alpha = np.clip(cv2.GaussianBlur(grow.astype(np.float32), (0, 0), max(1.5, hh_min * 0.45)) * 1.15 * 255, 0, 255).astype(np.uint8)
    Image.fromarray(np.dstack([out, alpha]), 'RGBA').save(os.path.join(OUT, name), optimize=True)
    rig['lid'] = ['res://%s/%s' % (OUT, name), round(x0 / W, 5), round(y0 / H, 5), round((x1 - x0) / W, 5), round((y1 - y0) / H, 5)]
    return name


def main():
    for f in sys.argv[1:]:
        rigs = json.load(open(f))
        n = 0
        for path, rig in rigs.items():
            if make(path, rig):
                n += 1
        json.dump(rigs, open(f, 'w'), indent=0)
        print('%s: %d painted lids' % (f, n))


if __name__ == '__main__':
    main()
