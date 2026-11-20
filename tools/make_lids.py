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
        near = (np.abs(qx) < 1.3) & (qy > -arc_of(qx) - 0.45 - 0.5 * reach) & (qy < arc_of(qx) + 0.7)   # lash band only: hair strands above stay
        mask |= (near & ((lum < skin_l * 0.78) | (sat > 140))).astype(np.uint8)
    mask = cv2.dilate(mask, np.ones((3, 3), np.uint8), iterations=2)
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    rad = max(3, int(min(g[4] for g in geo) * 0.8))
    out = cv2.inpaint(bgr, mask * 255, rad, cv2.INPAINT_TELEA)
    # Telea leaves streaks across a wide hole: soften the filled part, keep the untouched pixels exact
    soft = cv2.GaussianBlur(out, (0, 0), max(1.2, min(g[4] for g in geo) * 0.35))
    fm = cv2.GaussianBlur(mask.astype(np.float32), (0, 0), 1.5)[..., None]
    out = (soft * fm + out * (1 - fm)).astype(np.uint8)
    out = cv2.cvtColor(out, cv2.COLOR_BGR2RGB)
    # the fill borrows from the lash line around the hole and turns muddy / dark: inside the hole, colours
    # darker than the cheek go back to the cheek tone (a little shading kept), so the lid reads as skin
    cheek = np.zeros(rgb.shape[:2], bool)
    for cx, cy, ang, hw, hh in geo:
        dx, dy = xx + x0 - cx, yy + y0 - cy
        lx = math.cos(ang) * dx + math.sin(ang) * dy
        ly = -math.sin(ang) * dx + math.cos(ang) * dy
        qx, qy = lx / hw, ly / max(hh, 1.0)
        cheek |= (np.abs(qx) < 0.9) & (qy > 1.5) & (qy < 3.0) & (mask == 0)
    if rig.get('lid_tone') and cheek.sum() > 20:   # opt-in per rig: painterly faces whose fill turns muddy
        ck = rgb[cheek].astype(np.float32)
        cl = ck @ np.array([0.3, 0.55, 0.15], np.float32)
        ck = ck[cl >= np.percentile(cl, 40)]          # skip shadows / hair in the cheek sample
        tone = np.median(ck, 0)
        tl = float(tone @ np.array([0.3, 0.55, 0.15]))
        o = out.astype(np.float32)
        ol = o @ np.array([0.3, 0.55, 0.15], np.float32)
        shade = np.clip(ol / max(tl, 1.0), 0.86, 1.04)[..., None]
        dist = np.linalg.norm(o - tone, axis=2)
        k = np.clip((dist - 18.0) / 50.0, 0, 1) * (ol < tl * 1.02)
        k = (cv2.GaussianBlur((k * (mask > 0)).astype(np.float32), (0, 0), 1.5) * fm[..., 0])[..., None]
        out = np.clip(o * (1 - k) + tone * shade * k, 0, 255).astype(np.uint8)
    os.makedirs(OUT, exist_ok=True)
    name = os.path.splitext(os.path.basename(src))[0] + '_lid.png'
    # alpha = where the eye was removed (soft): the shader only corrects colours there
    alpha = np.clip(cv2.GaussianBlur(mask.astype(np.float32), (0, 0), 1.2) * 255, 0, 255).astype(np.uint8)
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
