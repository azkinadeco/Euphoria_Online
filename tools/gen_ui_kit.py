"""Procedural UI kit (9-slice frames, buttons, card frames) for Euphoria Online.
Drawn at 4x and downsampled for clean anti-aliasing. Run: python3 tools/gen_ui_kit.py -> art/ui/*.png
Replace any PNG with artist-made art of the same size/margins later."""
from PIL import Image, ImageDraw, ImageFilter
import os, math
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'art', 'ui')
SS = 4

def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))

def vgrad(w, h, stops):
    """stops: [(t, rgba)]"""
    im = Image.new('RGBA', (w, h))
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                lt = (t - stops[i][0]) / max(1e-6, stops[i + 1][0] - stops[i][0])
                c = lerp(stops[i][1], stops[i + 1][1], lt)
                break
        for x in range(w):
            px[x, y] = c
    return im

def rr_mask(w, h, r, inset=0):
    m = Image.new('L', (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((inset, inset, w - 1 - inset, h - 1 - inset), r, fill=255)
    return m

def save(im, name, size):
    im = im.resize(size, Image.LANCZOS)
    im.save(os.path.join(OUT, name))

def corner_ornament(d, cx, cy, s, col, flip_x=1, flip_y=1):
    # diamond gem + two curls pointing along the edges
    gem = [(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)]
    d.polygon(gem, fill=col)
    d.polygon([(cx, cy - s * 0.5), (cx + s * 0.5, cy), (cx, cy + s * 0.5), (cx - s * 0.5, cy)], fill=(255, 245, 210, 255))
    w = max(2, int(s * 0.28))
    d.arc((cx + flip_x * s * 0.8 - s * 1.4, cy - s * 0.7, cx + flip_x * s * 0.8 + s * 1.4, cy + s * 2.1), 200 if flip_x > 0 else 280, 300 if flip_x > 0 else 340, fill=col, width=w)
    d.line((cx + flip_x * s * 1.1, cy, cx + flip_x * s * 3.2, cy), fill=col, width=w)
    d.line((cx, cy + flip_y * s * 1.1, cx, cy + flip_y * s * 3.2), fill=col, width=w)

def frame(name, size, radius, fill_stops, outer, inner, orn_col, orn=True, glow_top=True, bw=2.0):
    W, H = size[0] * SS, size[1] * SS
    base = vgrad(W, H, fill_stops)
    m = rr_mask(W, H, radius * SS)
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    im.paste(base, (0, 0), m)
    d = ImageDraw.Draw(im)
    if glow_top:
        g = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(g)
        gd.rounded_rectangle((6 * SS, 3 * SS, W - 6 * SS, int(H * 0.35)), radius * SS, fill=(255, 255, 255, 18))
        g = g.filter(ImageFilter.GaussianBlur(4 * SS))
        im = Image.alpha_composite(im, Image.composite(g, Image.new('RGBA', (W, H)), m))
        d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, W - 1, H - 1), radius * SS, outline=outer, width=int(bw * SS))
    if inner:
        o = int(4 * SS)
        d.rounded_rectangle((o, o, W - 1 - o, H - 1 - o), max(2, radius - 3) * SS, outline=inner, width=int(1 * SS))
    if orn:
        s = 4 * SS
        off = 7 * SS
        corner_ornament(d, off, off, s, orn_col, 1, 1)
        corner_ornament(d, W - off, off, s, orn_col, -1, 1)
        corner_ornament(d, off, H - off, s, orn_col, 1, -1)
        corner_ornament(d, W - off, H - off, s, orn_col, -1, -1)
    save(im, name, size)

def button(name, size, radius, stops, outline, sheen=60, inner=None):
    W, H = size[0] * SS, size[1] * SS
    base = vgrad(W, H, stops)
    m = rr_mask(W, H, radius * SS)
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    im.paste(base, (0, 0), m)
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((3 * SS, 2 * SS, W - 3 * SS, int(H * 0.46)), (radius - 2) * SS, fill=(255, 255, 255, sheen))
    sh = sh.filter(ImageFilter.GaussianBlur(1.5 * SS))
    im = Image.alpha_composite(im, Image.composite(sh, Image.new('RGBA', (W, H)), m))
    d = ImageDraw.Draw(im)
    if inner:
        d.rounded_rectangle((2 * SS, 2 * SS, W - 1 - 2 * SS, H - 1 - 2 * SS), (radius - 2) * SS, outline=inner, width=SS)
    d.rounded_rectangle((0, 0, W - 1, H - 1), radius * SS, outline=outline, width=int(1.5 * SS))
    save(im, name, size)

os.makedirs(OUT, exist_ok=True)
GOLD = (232, 190, 98, 255); GOLD_D = (150, 104, 38, 255); VIO = (110, 86, 170, 200)
# panels
frame('panel.png', (96, 96), 12, [(0, (30, 20, 52, 236)), (0.5, (18, 12, 34, 236)), (1, (12, 8, 24, 240))], GOLD_D, VIO, GOLD)
frame('card.png', (64, 64), 10, [(0, (40, 30, 70, 236)), (1, (24, 18, 44, 240))], (104, 84, 160, 255), None, (200, 160, 90, 255), orn=True, bw=1.5)
frame('popup.png', (128, 128), 16, [(0, (34, 22, 60, 250)), (0.45, (20, 13, 38, 250)), (1, (12, 8, 24, 252))], GOLD, (200, 160, 90, 160), GOLD, bw=3.0)
# title ribbon (horizontal 9-slice)
W, H = 160 * SS, 44 * SS
rb = vgrad(W, H, [(0, (120, 60, 150, 255)), (0.5, (70, 32, 100, 255)), (1, (44, 18, 68, 255))])
m = Image.new('L', (W, H), 0)
ImageDraw.Draw(m).polygon([(0, H // 2), (14 * SS, 0), (W - 14 * SS, 0), (W, H // 2), (W - 14 * SS, H), (14 * SS, H)], fill=255)
rib = Image.new('RGBA', (W, H), (0, 0, 0, 0)); rib.paste(rb, (0, 0), m)
dr = ImageDraw.Draw(rib)
dr.polygon([(0, H // 2), (14 * SS, 0), (W - 14 * SS, 0), (W, H // 2), (W - 14 * SS, H), (14 * SS, H)], outline=GOLD, width=2 * SS)
dr.line((16 * SS, 5 * SS, W - 16 * SS, 5 * SS), fill=(255, 230, 170, 120), width=SS)
save(rib, 'ribbon.png', (160, 44))
# header bar
W, H = 64 * SS, 72 * SS
hb = vgrad(W, H, [(0, (10, 6, 20, 235)), (0.75, (18, 10, 34, 200)), (1, (18, 10, 34, 0))])
d = ImageDraw.Draw(hb)
gl = Image.new('RGBA', (W, H), (0, 0, 0, 0)); ImageDraw.Draw(gl).line((0, 62 * SS, W, 62 * SS), fill=(255, 200, 110, 170), width=3 * SS)
gl = gl.filter(ImageFilter.GaussianBlur(2 * SS)); hb = Image.alpha_composite(hb, gl)
ImageDraw.Draw(hb).line((0, 62 * SS, W, 62 * SS), fill=GOLD, width=SS)
save(hb, 'header.png', (64, 72))
# buttons
button('btn_gold.png', (48, 40), 10, [(0, (255, 236, 170, 255)), (0.45, (232, 178, 72, 255)), (1, (168, 108, 28, 255))], (92, 52, 12, 255), 90, (255, 245, 210, 140))
button('btn_gold_hover.png', (48, 40), 10, [(0, (255, 244, 196, 255)), (0.45, (246, 196, 92, 255)), (1, (186, 124, 36, 255))], (110, 64, 16, 255), 110, (255, 250, 225, 170))
button('btn_gold_pressed.png', (48, 40), 10, [(0, (196, 136, 46, 255)), (1, (232, 178, 72, 255))], (92, 52, 12, 255), 20)
button('btn_gold_disabled.png', (48, 40), 10, [(0, (96, 80, 58, 255)), (1, (60, 48, 34, 255))], (40, 30, 20, 255), 15)
button('btn.png', (48, 40), 10, [(0, (58, 44, 98, 245)), (0.5, (34, 24, 62, 245)), (1, (24, 16, 44, 245))], (110, 86, 170, 255), 34, (160, 130, 230, 70))
button('btn_hover.png', (48, 40), 10, [(0, (78, 60, 132, 250)), (0.5, (46, 34, 84, 250)), (1, (32, 22, 58, 250))], (170, 140, 255, 255), 44, (200, 175, 255, 90))
button('btn_pressed.png', (48, 40), 10, [(0, (30, 22, 54, 250)), (1, (60, 44, 104, 250))], (214, 194, 255, 255), 10)
button('btn_disabled.png', (48, 40), 10, [(0, (26, 20, 38, 230)), (1, (18, 14, 28, 230))], (52, 44, 70, 255), 6)
button('tab.png', (48, 40), 8, [(0, (30, 22, 52, 220)), (1, (18, 13, 32, 220))], (66, 52, 100, 255), 20)
button('tab_on.png', (48, 40), 8, [(0, (110, 76, 180, 250)), (0.6, (70, 46, 124, 250)), (1, (50, 32, 92, 250))], (255, 212, 121, 255), 60, (255, 230, 170, 120))
# hero card frames (overlays: transparent centre)
def card_frame(name, col, light, ssr):
    W, H = 64 * SS, 80 * SS
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, W - 1, H - 1), 10 * SS, outline=col, width=3 * SS)
    d.rounded_rectangle((3 * SS, 3 * SS, W - 1 - 3 * SS, H - 1 - 3 * SS), 8 * SS, outline=light, width=SS)
    s = (5 if ssr else 3.5) * SS
    for (x, y, fx, fy) in [(6 * SS, 6 * SS, 1, 1), (W - 6 * SS, 6 * SS, -1, 1), (6 * SS, H - 6 * SS, 1, -1), (W - 6 * SS, H - 6 * SS, -1, -1)]:
        corner_ornament(d, x, y, s, col, fx, fy)
    if ssr:
        d.polygon([(W // 2 - 7 * SS, 0), (W // 2, 6 * SS), (W // 2 + 7 * SS, 0)], fill=col)
        d.ellipse((W // 2 - 3 * SS, 0, W // 2 + 3 * SS, 5 * SS), fill=(255, 250, 220, 255))
    save(im, name, (64, 80))
card_frame('frame_ssr.png', (238, 190, 90, 255), (255, 240, 190, 200), True)
card_frame('frame_sr.png', (190, 120, 255, 255), (230, 200, 255, 170), False)
card_frame('frame_r.png', (110, 170, 230, 255), (200, 225, 255, 150), False)
print("ui kit written to", OUT)
# bottom navigation bar: gold glowing top edge, dark gradient body
W, H = 64 * SS, 96 * SS
nb = vgrad(W, H, [(0, (26, 16, 46, 0)), (0.12, (26, 16, 46, 235)), (1, (8, 5, 16, 248))])
gl = Image.new('RGBA', (W, H), (0, 0, 0, 0)); ImageDraw.Draw(gl).line((0, 12 * SS, W, 12 * SS), fill=(255, 200, 110, 190), width=4 * SS)
gl = gl.filter(ImageFilter.GaussianBlur(3 * SS)); nb = Image.alpha_composite(nb, gl)
ImageDraw.Draw(nb).line((0, 12 * SS, W, 12 * SS), fill=GOLD, width=SS)
save(nb, 'navbar.png', (64, 96))
# round medallion behind the main nav action
W = H = 128 * SS
md = Image.new('RGBA', (W, H), (0, 0, 0, 0))
g2 = Image.new('RGBA', (W, H), (0, 0, 0, 0)); ImageDraw.Draw(g2).ellipse((8 * SS, 8 * SS, W - 8 * SS, H - 8 * SS), fill=(255, 190, 90, 120))
g2 = g2.filter(ImageFilter.GaussianBlur(7 * SS)); md = Image.alpha_composite(md, g2)
disc = vgrad(W, H, [(0, (120, 80, 190, 255)), (1, (40, 22, 76, 255))])
mk = Image.new('L', (W, H), 0); ImageDraw.Draw(mk).ellipse((18 * SS, 18 * SS, W - 18 * SS, H - 18 * SS), fill=255)
md.paste(disc, (0, 0), mk)
d = ImageDraw.Draw(md)
d.ellipse((18 * SS, 18 * SS, W - 18 * SS, H - 18 * SS), outline=GOLD, width=3 * SS)
d.ellipse((24 * SS, 24 * SS, W - 24 * SS, H - 24 * SS), outline=(255, 235, 180, 150), width=SS)
save(md, 'medallion.png', (128, 128))
print("nav assets written")
# light rays (victory backdrop) and winged title crest
W = H = 512 * 2
rays = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(rays)
cx = cy = W // 2
for i in range(18):
    a0 = i * (2 * math.pi / 18)
    a1 = a0 + 0.12
    d.polygon([(cx, cy), (cx + math.cos(a0) * W, cy + math.sin(a0) * W), (cx + math.cos(a1) * W, cy + math.sin(a1) * W)], fill=(255, 220, 140, 70))
mask = Image.new('L', (W, H), 0)
for r in range(W // 2, 0, -8):
    ImageDraw.Draw(mask).ellipse((cx - r, cy - r, cx + r, cy + r), fill=int(255 * (1 - r / (W / 2)) ** 0.6))
rays.putalpha(Image.composite(rays.getchannel('A'), Image.new('L', (W, H), 0), mask))
rays = rays.filter(ImageFilter.GaussianBlur(4))
rays.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, 'rays.png'))
# winged crest under the VICTORY title
W, H = 520 * SS, 120 * SS
cr = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(cr)
cx = W // 2
for side in (-1, 1):
    for k in range(6):
        y = 30 * SS + k * 11 * SS
        x0 = cx + side * (60 + k * 6) * SS
        x1 = cx + side * (240 - k * 30) * SS
        d.polygon([(x0, y), (x1, y + 6 * SS), (x0, y + 14 * SS)], fill=(232, 190, 98, 230 - k * 25))
d.ellipse((cx - 26 * SS, 32 * SS, cx + 26 * SS, 84 * SS), fill=(110, 60, 160, 255), outline=(232, 190, 98, 255), width=4 * SS)
d.polygon([(cx, 40 * SS), (cx + 14 * SS, 58 * SS), (cx, 76 * SS), (cx - 14 * SS, 58 * SS)], fill=(255, 240, 200, 255))
save(cr, 'crest.png', (520, 120))
print("victory assets written")
# home icon (house) for the header HOME button
W = H = 128 * SS
hm = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(hm)
gold = (255, 214, 121, 255)
d.polygon([(W * 0.5, H * 0.14), (W * 0.9, H * 0.5), (W * 0.78, H * 0.5), (W * 0.5, H * 0.26), (W * 0.22, H * 0.5), (W * 0.1, H * 0.5)], fill=gold)
d.rounded_rectangle((W * 0.24, H * 0.46, W * 0.76, H * 0.86), 6 * SS, fill=gold)
d.rounded_rectangle((W * 0.42, H * 0.6, W * 0.58, H * 0.86), 4 * SS, fill=(40, 24, 64, 255))
save(hm, '../icons/icon_home.png', (64, 64))
print("home icon written")
# distinct menu icons: date (two hearts), room (bed), garden (flower), event (star banner), festival (lantern exists)
def _icon(name, draw):
    W = H = 128 * SS
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((6 * SS, 6 * SS, W - 6 * SS, H - 6 * SS), fill=(26, 16, 44, 255), outline=(232, 190, 98, 255), width=5 * SS)
    draw(d, W, H)
    save(im, '../icons/%s.png' % name, (64, 64))
def heart(d, cx, cy, s, col):
    d.ellipse((cx - s, cy - s * 0.8, cx, cy + s * 0.2), fill=col)
    d.ellipse((cx, cy - s * 0.8, cx + s, cy + s * 0.2), fill=col)
    d.polygon([(cx - s, cy - s * 0.2), (cx + s, cy - s * 0.2), (cx, cy + s * 1.1)], fill=col)
_icon('icon_date', lambda d, W, H: (heart(d, W * 0.42, H * 0.5, 22 * SS, (255, 120, 170, 255)), heart(d, W * 0.6, H * 0.46, 18 * SS, (255, 200, 220, 255))))
def bed(d, W, H):
    d.rounded_rectangle((W * 0.22, H * 0.48, W * 0.78, H * 0.66), 4 * SS, fill=(160, 120, 230, 255))
    d.rounded_rectangle((W * 0.24, H * 0.4, W * 0.42, H * 0.5), 4 * SS, fill=(255, 230, 245, 255))
    d.rectangle((W * 0.2, H * 0.34, W * 0.24, H * 0.74), fill=(232, 190, 98, 255))
    d.rectangle((W * 0.76, H * 0.5, W * 0.8, H * 0.74), fill=(232, 190, 98, 255))
_icon('icon_room', bed)
def flower(d, W, H):
    cx, cy, r = W * 0.5, H * 0.46, 13 * SS
    for k in range(6):
        a = k * math.pi / 3
        d.ellipse((cx + math.cos(a) * r * 1.3 - r, cy + math.sin(a) * r * 1.3 - r, cx + math.cos(a) * r * 1.3 + r, cy + math.sin(a) * r * 1.3 + r), fill=(255, 150, 190, 255))
    d.ellipse((cx - r * 0.8, cy - r * 0.8, cx + r * 0.8, cy + r * 0.8), fill=(255, 220, 110, 255))
    d.line((cx, cy + r * 2, cx, H * 0.8), fill=(110, 200, 120, 255), width=4 * SS)
_icon('icon_garden', flower)
print("menu icons written")
# ornate summon card back (rarity glow is added in-game)
W, H = 300 * SS, 390 * SS
cb = vgrad(W, H, [(0, (54, 30, 92, 255)), (0.5, (28, 14, 52, 255)), (1, (16, 8, 30, 255))])
m = rr_mask(W, H, 18 * SS)
card = Image.new('RGBA', (W, H), (0, 0, 0, 0)); card.paste(cb, (0, 0), m)
d = ImageDraw.Draw(card)
d.rounded_rectangle((0, 0, W - 1, H - 1), 18 * SS, outline=GOLD, width=5 * SS)
d.rounded_rectangle((12 * SS, 12 * SS, W - 13 * SS, H - 13 * SS), 12 * SS, outline=(200, 160, 90, 170), width=2 * SS)
# diamond lattice
for k in range(-8, 9):
    d.line((W / 2 + k * 30 * SS - H, 0, W / 2 + k * 30 * SS + H, H), fill=(120, 90, 180, 40), width=SS)
    d.line((W / 2 + k * 30 * SS + H, 0, W / 2 + k * 30 * SS - H, H), fill=(120, 90, 180, 40), width=SS)
cx, cy = W / 2, H / 2
for r, a in [(92, 120), (72, 200)]:
    d.ellipse((cx - r * SS, cy - r * SS, cx + r * SS, cy + r * SS), outline=(232, 190, 98, a), width=3 * SS)
star = []
for k in range(16):
    ang = k * math.pi / 8 - math.pi / 2
    rr = (60 if k % 2 == 0 else 24) * SS
    star.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr))
d.polygon(star, fill=(232, 190, 98, 255))
d.ellipse((cx - 14 * SS, cy - 14 * SS, cx + 14 * SS, cy + 14 * SS), fill=(255, 245, 210, 255))
card.alpha_composite(Image.composite(card, card, m)) if False else None
save(card, 'card_back.png', (300, 390))
print("card back written")
