"""Automatic depth maps for every hero AND enemy illustration (generic 2.5D Live).
Depth = a soft 'pillow' from the silhouette: distance from the edge (centre of the body = near),
gently blurred. Small (max 320 px tall) greyscale PNGs in art/depth/.
Run: python3 tools/make_depth_auto.py   (skips arts that have a hand-made rig)"""
import glob, os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'art', 'depth')
os.makedirs(OUT, exist_ok=True)
CUSTOM = {'glytta_char_evo2.png', 'glytta_char_evo2_a.png'}
n = 0
for f in sorted(glob.glob(os.path.join(ROOT, 'art/characters/heroes/*/char/*.png')) + glob.glob(os.path.join(ROOT, 'art/characters/enemies/*/char/*.png'))):
    b = os.path.basename(f)
    if 'depth' in b or b in CUSTOM:
        continue
    im = Image.open(f).convert('RGBA')
    H = 320
    W = max(8, round(im.width * H / im.height))
    a = np.asarray(im.resize((W, H), Image.BILINEAR).getchannel('A')).astype(np.float32) / 255.0
    solid = a > 0.4
    d = ndimage.distance_transform_edt(solid)
    if d.max() > 0:
        d = d / d.max()
    pillow = np.sqrt(d)                                   # rounder body
    # the upper body (head / chest) sits a little forward of the legs
    grad = np.linspace(0.08, -0.06, H, dtype=np.float32)[:, None]
    depth = np.clip(0.18 + 0.72 * pillow + grad * solid, 0, 1) * np.clip(a * 1.4, 0, 1)
    img = Image.fromarray((depth * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))
    img.save(os.path.join(OUT, b.replace('.png', '_depth.png')))
    n += 1
print('depth maps', n)
