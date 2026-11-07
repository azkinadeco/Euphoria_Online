"""Removes flat pure-white background trapped inside a cut-out silhouette (shaded white clothing is kept).
Usage: python3 tools/clean_white_holes.py apply <png files...>   (or scan)"""
import sys, glob, numpy as np
from PIL import Image
from scipy import ndimage
def holes(path, apply=False):
    im = Image.open(path).convert('RGBA'); a = np.asarray(im).astype(np.float32)
    rgb = a[..., :3]; al = a[..., 3]
    white = (rgb.min(2) > 244) & (al > 200)
    lab, n = ndimage.label(white)
    if n == 0: return []
    areas = ndimage.sum(white, lab, range(1, n + 1))
    found = []
    mask = np.zeros(white.shape, bool)
    for i in range(1, n + 1):
        if areas[i-1] < 300: continue
        m = lab == i
        v = rgb[m].mean(1)
        if v.mean() > 250 and v.std() < 2.0:
            found.append(int(areas[i-1])); mask |= m
    if apply and found:
        mask = ndimage.binary_dilation(mask, iterations=1)
        new_a = np.where(mask, 0, al)
        out = np.dstack([rgb, new_a]).astype(np.uint8)
        Image.fromarray(out, 'RGBA').save(path)
    return found
if __name__ == '__main__':
    apply = sys.argv[1] == 'apply'
    for f in sys.argv[2:]:
        r = holes(f, apply)
        if r: print(f.split('/')[-1], r)
