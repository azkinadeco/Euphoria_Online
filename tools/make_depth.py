"""Heuristic depth map for a 2.5D 'live' hero illustration.
near (white) = the girl (skin + bright low-saturation hair), mid = dark construct / armour,
far (black) = thin, semi-transparent smoke. Heavily blurred so the parallax warps smoothly.
Usage: python3 tools/make_depth.py <in.png> <out_depth.png>"""
import sys
import numpy as np
from PIL import Image, ImageFilter

src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGBA')
W, H = im.size
small = im.resize((W // 2, H // 2), Image.LANCZOS)
a = np.asarray(small).astype(np.float32) / 255.0
r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
mx = np.maximum(np.maximum(r, g), b)
mn = np.minimum(np.minimum(r, g), b)
lum = 0.3 * r + 0.59 * g + 0.11 * b
sat = (mx - mn) / (mx + 1e-4)
skin = (r > 0.55) & (r > g) & (g > b * 0.9) & (sat > 0.12) & (sat < 0.6)
hair = (lum > 0.62) & (sat < 0.14)
blue = (b > 0.55) & (b > r + 0.15) & (sat > 0.3)
depth = np.full(lum.shape, 0.5, np.float32)          # construct / armour
depth[lum < 0.18] = 0.45
depth[blue] = 0.55
depth[hair] = 0.85
depth[skin] = 1.0
depth = depth * np.clip(al * 1.3, 0, 1) + 0.15 * (1 - np.clip(al * 1.3, 0, 1))   # smoke → far
# the girl is one body: close small holes, then smooth everything
d = Image.fromarray((depth * 255).astype(np.uint8))
d = d.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(14))
d = d.filter(ImageFilter.GaussianBlur(10))
# ground plane: lower parts sit a little closer
grad = np.linspace(-0.06, 0.08, d.height, dtype=np.float32)[:, None]
dd = np.clip(np.asarray(d).astype(np.float32) / 255.0 + grad, 0, 1)
Image.fromarray((dd * 255).astype(np.uint8)).save(dst)
print('depth', dst, d.size)
