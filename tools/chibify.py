## Turns a full-body art into a chibi battle sprite: the head is magnified with a smooth bulge warp
## and the legs are squashed. Usage:
##   python3 tools/chibify.py <in.png> <out.png> <head_cx> <head_cy> <head_r> <mag> <leg_y> <leg_k>
## head_* are UV (0..1) of the art, mag = head magnification (1.5-1.9), leg_y = UV row where squashing
## starts, leg_k = vertical scale below it (0.6-0.75). Used for Mora, Ex-Nymph and Ygg-Naar (batch 136).
import sys, numpy as np, cv2
from PIL import Image
# chibify.py in out cx cy R mag legy legk
src, out = sys.argv[1], sys.argv[2]
cx, cy, R, mag, legy, legk = map(float, sys.argv[3:9])
im = np.asarray(Image.open(src).convert('RGBA')).astype(np.float32)
H, W = im.shape[:2]
# 1) body squash: rows below legy (uv) compressed by legk (output taller->shorter)
ly = legy * H
oh = int(ly + (H - ly) * legk)
ys = np.arange(oh, dtype=np.float32)
srcy = np.where(ys < ly, ys, ly + (ys - ly) / legk)
mapx = np.tile(np.arange(W, dtype=np.float32), (oh, 1))
mapy = np.tile(srcy[:, None], (1, W))
im = cv2.remap(im, mapx, mapy, cv2.INTER_CUBIC, borderMode=cv2.BORDER_CONSTANT, borderValue=0)
H = oh
# 2) head bulge: pad canvas so the bigger head fits
pad = int(R * H / 1.0 * (mag - 1) * 1.2) + 4
im = cv2.copyMakeBorder(im, pad, 0, pad, pad, cv2.BORDER_CONSTANT, value=0)
Hh, Ww = im.shape[:2]
c = np.array([cx * W + pad, cy * (H * 1.0) + pad], np.float32)
Rp = R * H
yy, xx = np.mgrid[0:Hh, 0:Ww].astype(np.float32)
dx, dy = xx - c[0], yy - c[1]
d = np.sqrt(dx * dx + dy * dy)
R2 = Rp * 2.6
# output radius r_out maps to source radius r_src: inside Rp*mag -> /mag; smooth blend to identity at R2
t = np.clip((d - Rp * mag) / (R2 - Rp * mag), 0, 1)
t = t * t * (3 - 2 * t)
f = (1.0 / mag) * (1 - t) + 1.0 * t
# keep continuity: at d=Rp*mag, src=Rp; at R2, src=R2
mapx = c[0] + dx * f
mapy = c[1] + dy * f
im = cv2.remap(im, mapx, mapy, cv2.INTER_CUBIC, borderMode=cv2.BORDER_CONSTANT, borderValue=0)
im = np.clip(im, 0, 255).astype(np.uint8)
a = im[:, :, 3]
ys_, xs_ = np.where(a > 8)
im = im[ys_.min():ys_.max() + 1, xs_.min():xs_.max() + 1]
Image.fromarray(im).save(out)
print(out, im.shape)
