"""Structured depth map for glytta_char_evo2 (2.5D live rig).
Shapes are traced in preview space (685x800) from the pivot reference sheet, then scaled.
White = near, black = far. Run: python3 tools/make_depth_glytta.py"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
SRC = 'art/characters/heroes/glytta/char/glytta_char_evo2.png'
DST = 'art/characters/heroes/glytta/char/glytta_char_evo2_depth.png'
PW, PH = 685, 800
W, H = 960, 1120
k = W / PW

def layer(shapes, blur):
    m = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(m)
    for kind, pts, val in shapes:
        sp = [(x * k, y * k) for x, y in pts] if kind == 'poly' else [c * k for c in pts]
        if kind == 'poly':
            d.polygon(sp, fill=val)
        else:
            d.ellipse(sp, fill=val)
    return np.asarray(m.filter(ImageFilter.GaussianBlur(blur))).astype(np.float32) / 255.0

yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
# soft volume: the whole group bulges towards the viewer around the girl's chest
bulge = np.exp(-(((xx - 330 * k) / (300 * k)) ** 2 + ((yy - 400 * k) / (380 * k)) ** 2))
depth = 0.18 + 0.32 * bulge
# construct parts that reach forward
construct = layer([
    ('ell', (560, 400, 670, 510), 255),          # big eyeball
    ('poly', [(470, 130), (600, 160), (680, 300), (650, 420), (560, 400), (470, 300)], 170),   # right beast head
    ('poly', [(40, 150), (180, 140), (300, 330), (300, 470), (200, 450), (60, 330)], 200),     # left arm-maw (in front of her)
    ('poly', [(0, 450), (110, 430), (140, 650), (60, 690), (0, 640)], 140),                   # left small head
], 16)
depth = np.maximum(depth, 0.3 + 0.38 * construct)
# the girl: head, hair, torso, raised right leg, left leg
girl = layer([
    ('ell', (215, 175, 375, 335), 255),          # head
    ('poly', [(110, 140), (230, 110), (300, 160), (250, 300), (160, 420), (110, 330)], 200),   # flowing hair (behind head)
    ('poly', [(250, 300), (370, 290), (420, 380), (400, 470), (330, 520), (240, 500), (230, 380)], 255),  # torso
    ('poly', [(360, 470), (420, 380), (460, 350), (480, 380), (580, 520), (550, 540), (450, 430), (400, 500)], 255),  # raised leg
    ('poly', [(240, 480), (330, 520), (260, 620), (230, 760), (180, 760), (190, 600)], 235),  # left leg
], 12)
depth = np.maximum(depth, 0.55 + 0.45 * girl)
# the left maw passes IN FRONT of her waist → keep it on top there
maw = layer([('poly', [(150, 300), (300, 330), (330, 420), (290, 470), (180, 440)], 255)], 10)
depth = np.maximum(depth, 0.6 + 0.4 * maw)
al = np.asarray(Image.open(SRC).convert('RGBA').resize((W, H)).getchannel('A').filter(ImageFilter.GaussianBlur(6))).astype(np.float32) / 255.0
depth = depth * (0.35 + 0.65 * al)
Image.fromarray((np.clip(depth, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(4)).save(DST)
print('depth written', DST)
