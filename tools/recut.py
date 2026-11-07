"""Hybrid background removal for white-background character art.
mask = AI silhouette (rembg isnet-anime) ∪ colour key (anything clearly not white, near the character),
then white de-fringe. Keeps white hair / pale skin / white clothes that flood-fill used to eat.
Usage (module): from recut import cutout_image ; cutout_image(PIL.Image) -> RGBA PIL.Image"""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

_session = None

def _ai_mask(im):
    global _session
    from rembg import remove, new_session
    if _session is None:
        _session = new_session('isnet-anime')
    m = remove(im, session=_session, only_mask=True, post_process_mask=False)
    return np.asarray(m.convert('L')).astype(np.float32) / 255.0

def bg_color(im):
    """Solid background colour estimated from the border, or None if the border is not uniform."""
    a = np.asarray(im.convert('RGB')).astype(np.float32)
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    med = np.median(border, 0)
    close = (np.abs(border - med).max(1) < 28).mean()
    return med if close > 0.6 else None

def checker_colors(im):
    """Two grey levels of a baked-in 'fake transparency' checkerboard, or None."""
    a = np.asarray(im.convert('RGB')).astype(np.float32)
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1], a[1], a[-2], a[:, 1], a[:, -2]])
    sat = border.max(1) - border.min(1)
    if (sat < 14).mean() < 0.85:
        return None
    lum = border.mean(1)
    if lum.std() < 8:
        return None
    thr = (lum.min() + lum.max()) / 2
    lo, hi = border[lum < thr], border[lum >= thr]
    if len(lo) < len(border) * 0.15 or len(hi) < len(border) * 0.15:
        return None
    return np.median(lo, 0), np.median(hi, 0)

def checker_grid_mask(a, chk):
    """Pixels that match the checkerboard pattern itself (square size + phase taken from the
    top-left corner) over a whole 7x7 neighbourhood → background, whatever the AI says."""
    lum = a.mean(2)
    thr = (chk[0].mean() + chk[1].mean()) / 2
    row = lum[1] >= thr
    runs, n = [], 1
    for i in range(1, len(row)):
        if row[i] == row[i - 1]:
            n += 1
        else:
            runs.append(n); n = 1
    runs = [r for r in runs[1:] if r > 3]
    if len(runs) < 3:
        return None
    s = int(np.median(runs))
    # phase from the first transition on the top row / left column
    def first_edge(line):
        for i in range(1, len(line)):
            if (line[i] >= thr) != (line[i - 1] >= thr):
                return i % s
        return 0
    ox, oy = first_edge(lum[1]), first_edge(lum[:, 1])
    H, W = lum.shape
    yy, xx = np.mgrid[0:H, 0:W]
    par = (((xx - ox) // s) + ((yy - oy) // s)) % 2
    c0_is_hi = lum[1, max(0, ox)] >= thr if ox < W else True
    hi_par = par == (0 if c0_is_hi else 1)
    exp = np.where(hi_par[..., None], chk[1], chk[0])
    err = np.abs(a - exp).max(2)
    from scipy import ndimage as nd
    err_m = nd.uniform_filter(err, 7)
    sat = a.max(2) - a.min(2)
    return (err_m < 14) & (sat < 18)

def is_white_bg(im):
    c = bg_color(im)
    return c is not None and c.min() > 225

def cutout_image(im, pad=10):
    im = im.convert('RGB')
    a = np.asarray(im).astype(np.float32)
    H, W = a.shape[:2]
    ai = _ai_mask(im)
    chk = checker_colors(im)
    bgc = None if chk is not None else bg_color(im)
    if chk is not None:
        # checkerboard: distance to the nearer of its two greys; un-blend against that grey
        d1 = np.abs(a - chk[0]).max(2); d2 = np.abs(a - chk[1]).max(2)
        dist = np.minimum(d1, d2)
        bgc = np.where((d1 < d2)[..., None], chk[0], chk[1])
    else:
        if bgc is None:
            bgc = np.array([255.0, 255.0, 255.0])
        # colour key: distance from the background colour (soft)
        dist = np.abs(a - bgc).max(2)
    key = np.clip((dist - 10.0) / 45.0, 0.0, 1.0)
    if chk is not None:
        # on a checkerboard, colourless grey outside the AI silhouette is always background
        sat = a.max(2) - a.min(2)
        key = np.where((sat < 18) & (ai < 0.35), 0.0, key)
    # only keep key-regions that touch / sit near the character or are big (effects like jellyfish)
    solid = ai > 0.5
    near = ndimage.binary_dilation(solid, iterations=max(8, W // 40))
    kl, kn = ndimage.label(key > 0.25)
    keep = np.zeros(kn + 1, bool)
    if kn:
        sizes = ndimage.sum(np.ones_like(key), kl, range(1, kn + 1))
        touch = ndimage.maximum(near.astype(np.uint8), kl, range(1, kn + 1))
        keep[1:] = (touch > 0) | (sizes > H * W * 0.002)
    key = np.where(keep[kl] | (key <= 0.25) & ndimage.binary_dilation(keep[kl], iterations=3), key, 0.0)
    # AI interior is trusted fully; its soft edge blends with the key
    ai_in = np.asarray(Image.fromarray((np.clip(ai, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(5))).astype(np.float32) / 255.0
    alpha = np.maximum(ai_in, np.maximum(key, ai * key))
    alpha = np.maximum(alpha, np.where(ai > 0.85, ai, 0.0))
    if chk is not None:
        # checker squares the AI half-included: exact checker greys are background unless deep inside her
        alpha = np.where((dist < 22) & (ai < 0.92) & (sat < 18), 0.0, alpha)
    alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))).astype(np.float32) / 255.0
    # de-fringe: remove the white that was blended into semi-transparent pixels
    af = alpha[..., None]
    col = np.where(af > 0.03, (a - (1.0 - af) * bgc) / np.maximum(af, 0.03), a)
    col = np.clip(col, 0, 255)
    out = Image.fromarray(np.dstack([col.astype(np.uint8), (alpha * 255).astype(np.uint8)]), 'RGBA')
    bb = out.getchannel('A').point(lambda p: 255 if p > 16 else 0).getbbox()
    if bb:
        out = out.crop((max(0, bb[0] - pad), max(0, bb[1] - pad), min(W, bb[2] + pad), min(H, bb[3] + pad)))
    return out
