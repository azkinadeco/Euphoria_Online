#!/usr/bin/env python3
"""Draws art/ui/card_back.png (300x390): the back of a summon card.
Purple field with a diamond lattice, triple gold frame, corner diamonds and a moon-and-star medallion.
Run from the project root:  python3 tools/gen_card_back.py   (needs Pillow)
"""
import math

from PIL import Image, ImageDraw, ImageFilter

W, H, S = 300, 390, 3   # S = supersampling
GOLD, GOLD2, DIM = (232, 190, 98, 255), (255, 226, 150, 255), (150, 112, 58, 255)


def main():
    w, h = W * S, H * S
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    base = Image.new('RGBA', (w, h))
    px = base.load()
    for y in range(h):
        t = y / h
        r, g, b = 34 - 12 * t, 18 - 8 * t, 66 - 26 * t
        for x in range(w):
            dx, dy = (x - w / 2) / (w / 2), (y - h / 2) / (h / 2)
            k = max(0.0, 1.0 - (dx * dx + dy * dy)) * 0.55
            px[x, y] = (min(255, int(r + 60 * k)), min(255, int(g + 26 * k)), min(255, int(b + 88 * k)), 255)
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=22 * S, fill=255)
    img.paste(base, (0, 0), mask)
    lat = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lat)
    for i in range(-h, w + h, 26 * S):
        ld.line((i, 0, i + h, h), fill=(200, 160, 255, 26), width=S)
        ld.line((i, h, i + h, 0), fill=(200, 160, 255, 26), width=S)
    fm = Image.new('L', (w, h), 0)
    ImageDraw.Draw(fm).rounded_rectangle((20 * S, 20 * S, w - 20 * S, h - 20 * S), radius=12 * S, fill=255)
    img.paste(lat, (0, 0), Image.composite(lat.split()[3], Image.new('L', (w, h), 0), fm))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((5 * S, 5 * S, w - 5 * S, h - 5 * S), radius=19 * S, outline=GOLD, width=3 * S)
    d.rounded_rectangle((13 * S, 13 * S, w - 13 * S, h - 13 * S), radius=13 * S, outline=DIM, width=S)
    d.rounded_rectangle((18 * S, 18 * S, w - 18 * S, h - 18 * S), radius=10 * S, outline=GOLD, width=S)
    for cx, cy in [(30, 30), (W - 30, 30), (30, H - 30), (W - 30, H - 30)]:
        cx, cy, r, r2 = cx * S, cy * S, 9 * S, 4 * S
        d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=GOLD2, outline=DIM)
        d.polygon([(cx, cy - r2), (cx + r2, cy), (cx, cy + r2), (cx - r2, cy)], fill=(60, 30, 100, 255))
    cx, cy = w // 2, h // 2
    glow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((cx - 96 * S, cy - 96 * S, cx + 96 * S, cy + 96 * S), fill=(190, 130, 255, 70))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(22 * S)))
    d = ImageDraw.Draw(img)
    for rr, wd, col in [(84, 3, GOLD), (76, 1, DIM), (58, 2, GOLD)]:
        d.ellipse((cx - rr * S, cy - rr * S, cx + rr * S, cy + rr * S), outline=col, width=wd * S)
    for k in range(24):
        a = k * math.tau / 24
        r1, r2 = (62 * S, 72 * S) if k % 2 == 0 else (65 * S, 70 * S)
        d.line((cx + math.cos(a) * r1, cy + math.sin(a) * r1, cx + math.cos(a) * r2, cy + math.sin(a) * r2),
               fill=GOLD if k % 2 == 0 else DIM, width=2 * S)
    moon = Image.new('L', (w, h), 0)
    md = ImageDraw.Draw(moon)
    md.ellipse((cx - 44 * S, cy - 44 * S, cx + 44 * S, cy + 44 * S), fill=255)
    md.ellipse((cx - 28 * S, cy - 54 * S, cx + 60 * S, cy + 34 * S), fill=0)
    img.paste(Image.new('RGBA', (w, h), GOLD2), (0, 0), moon)
    d = ImageDraw.Draw(img)

    def star(sx, sy, big, small, col):
        pts = []
        for k in range(8):
            a = -math.pi / 2 + k * math.pi / 4
            q = big if k % 2 == 0 else small
            pts.append((sx + math.cos(a) * q, sy + math.sin(a) * q))
        d.polygon(pts, fill=col)

    star(cx + 14 * S, cy - 8 * S, 24 * S, 6 * S, (255, 245, 210, 255))
    star(cx + 36 * S, cy + 22 * S, 9 * S, 2.5 * S, GOLD2)
    star(cx - 4 * S, cy + 30 * S, 6 * S, 2 * S, GOLD2)
    for sy in (58, H - 58):
        y, r = sy * S, 6 * S
        d.line((cx - 46 * S, y, cx - 12 * S, y), fill=GOLD, width=2 * S)
        d.line((cx + 12 * S, y, cx + 46 * S, y), fill=GOLD, width=2 * S)
        d.polygon([(cx, y - r), (cx + r, y), (cx, y + r), (cx - r, y)], fill=GOLD2)
    img.resize((W, H), Image.Resampling.LANCZOS).save('art/ui/card_back.png')
    print('art/ui/card_back.png written')


if __name__ == '__main__':
    main()
