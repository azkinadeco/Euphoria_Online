#!/usr/bin/env python3
"""Draw the item icons that used to share art with other items.

Same look as art/icons/*: dark disc, coloured ring, flat symbol. Drawn at 4x and
scaled down to 128 px. Run from the project root:  python3 tools/gen_item_icons.py
"""
import math
from PIL import Image, ImageDraw, ImageFilter

S = 4
N = 128 * S
C = N / 2


def P(x, y):
    return (x * S, y * S)


def base(ring):
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    glow = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([C - 61 * S, C - 61 * S, C + 61 * S, C + 61 * S], outline=ring + (150,), width=5 * S)
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(3 * S)))
    d = ImageDraw.Draw(im)
    d.ellipse([C - 58 * S, C - 58 * S, C + 58 * S, C + 58 * S], fill=(14, 11, 22, 255), outline=ring + (255,), width=3 * S)
    d.ellipse([C - 53 * S, C - 53 * S, C + 53 * S, C + 53 * S], outline=ring + (90,), width=1 * S)
    return im, d


def poly(d, pts, fill, outline=None, width=0):
    d.polygon([P(x, y) for x, y in pts], fill=fill, outline=outline, width=width * S if width else 0)


def ell(d, x0, y0, x1, y1, **kw):
    if "width" in kw:
        kw["width"] *= S
    d.ellipse([x0 * S, y0 * S, x1 * S, y1 * S], **kw)


def rect(d, x0, y0, x1, y1, r=0, **kw):
    if "width" in kw:
        kw["width"] *= S
    d.rounded_rectangle([x0 * S, y0 * S, x1 * S, y1 * S], radius=r * S, **kw)


def line(d, pts, fill, w):
    d.line([P(x, y) for x, y in pts], fill=fill, width=w * S, joint="curve")


def flask(d, liquid, hi):
    # round-bottom flask with a cork
    rect(d, 55, 26, 73, 34, 3, fill=(176, 120, 72, 255))
    rect(d, 57, 33, 71, 50, 2, fill=(210, 225, 240, 70), outline=(225, 235, 250, 255), width=3)
    ell(d, 36, 46, 92, 102, fill=(210, 225, 240, 60), outline=(225, 235, 250, 255), width=3)
    d.chord([40 * S, 49 * S, 88 * S, 99 * S], -15, 195, fill=liquid)
    ell(d, 46, 72, 54, 80, fill=hi)


def sweet_cake():
    im, d = base((255, 168, 96))
    poly(d, [(30, 70), (98, 52), (98, 92), (30, 98)], fill=(250, 226, 190, 255))
    poly(d, [(30, 70), (98, 52), (98, 62), (30, 80)], fill=(255, 120, 160, 255))
    poly(d, [(30, 82), (98, 70), (98, 74), (30, 86)], fill=(255, 150, 180, 255))
    poly(d, [(30, 70), (64, 38), (98, 52)], fill=(255, 245, 235, 255))
    ell(d, 58, 28, 74, 44, fill=(230, 40, 70, 255))
    line(d, [(66, 30), (70, 22)], (90, 170, 80, 255), 3)
    return im


def perfume():
    im, d = base((190, 140, 255))
    rect(d, 56, 22, 72, 36, 3, fill=(255, 210, 110, 255))
    rect(d, 60, 34, 68, 42, 1, fill=(230, 220, 255, 255))
    poly(d, [(42, 46), (86, 46), (96, 76), (80, 104), (48, 104), (32, 76)], fill=(150, 90, 240, 220), outline=(225, 205, 255, 255), width=3)
    poly(d, [(46, 54), (60, 54), (52, 74)], fill=(235, 220, 255, 170))
    # crescent moon on the glass
    ell(d, 58, 64, 82, 88, fill=(255, 235, 160, 255))
    ell(d, 64, 60, 88, 84, fill=(150, 90, 240, 255))
    return im


def skin_ticket():
    im, d = base((255, 110, 200))
    # coat hanger
    line(d, [(64, 38), (64, 30)], (255, 220, 120, 255), 4)
    d.arc([58 * S, 20 * S, 72 * S, 34 * S], 180, 360, fill=(255, 220, 120, 255), width=4 * S)
    line(d, [(64, 38), (30, 58), (98, 58), (64, 38)], (255, 220, 120, 255), 4)
    # dress
    poly(d, [(52, 58), (76, 58), (80, 72), (96, 104), (32, 104), (48, 72)], fill=(255, 90, 180, 255))
    poly(d, [(48, 72), (80, 72), (82, 77), (46, 77)], fill=(255, 220, 120, 255))
    # sparkle
    poly(d, [(92, 26), (95, 34), (103, 37), (95, 40), (92, 48), (89, 40), (81, 37), (89, 34)], fill=(255, 255, 255, 255))
    return im


def exp_potion():
    im, d = base((120, 230, 120))
    flask(d, (90, 220, 110, 255), (200, 255, 200, 255))
    # up arrow
    poly(d, [(64, 70), (76, 84), (69, 84), (69, 94), (59, 94), (59, 84), (52, 84)], fill=(255, 255, 255, 235))
    return im


def energy_potion():
    im, d = base((255, 170, 60))
    flask(d, (255, 150, 40, 255), (255, 225, 160, 255))
    poly(d, [(68, 66), (56, 84), (64, 84), (60, 98), (74, 78), (66, 78)], fill=(255, 255, 255, 240))
    return im


def forge_ember():
    im, d = base((255, 90, 60))
    poly(d, [(64, 22), (82, 48), (90, 72), (80, 98), (64, 106), (48, 98), (38, 72), (46, 52), (54, 62)], fill=(240, 70, 40, 255))
    poly(d, [(64, 48), (76, 70), (76, 90), (64, 100), (52, 90), (52, 74), (58, 80)], fill=(255, 170, 60, 255))
    poly(d, [(64, 72), (70, 84), (64, 96), (58, 86)], fill=(255, 240, 170, 255))
    return im


def hunt_core():
    im, d = base((240, 80, 90))
    for k in range(8):
        a = k * math.pi / 4
        a1, a2 = a - 0.18, a + 0.18
        poly(d, [(64 + 22 * math.cos(a1), 64 + 22 * math.sin(a1)), (64 + 44 * math.cos(a), 64 + 44 * math.sin(a)), (64 + 22 * math.cos(a2), 64 + 22 * math.sin(a2))], fill=(150, 30, 50, 255))
    ell(d, 38, 38, 90, 90, fill=(200, 40, 60, 255), outline=(255, 140, 140, 255), width=3)
    ell(d, 50, 50, 78, 78, fill=(255, 90, 90, 255))
    ell(d, 57, 57, 71, 71, fill=(255, 230, 200, 255))
    return im


def rune_pouch():
    im, d = base((90, 220, 210))
    ell(d, 30, 50, 98, 106, fill=(120, 80, 50, 255))
    poly(d, [(46, 54), (82, 54), (90, 34), (78, 42), (64, 30), (50, 42), (38, 34)], fill=(150, 100, 60, 255))
    rect(d, 42, 50, 86, 58, 3, fill=(90, 220, 210, 255))
    # rune glyph
    line(d, [(64, 66), (64, 96)], (120, 255, 240, 255), 4)
    line(d, [(64, 72), (76, 82), (64, 92)], (120, 255, 240, 255), 4)
    return im


def star_stone():
    im, d = base((255, 210, 90))
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 42 if k % 2 == 0 else 18
        pts.append((64 + r * math.cos(a), 66 + r * math.sin(a)))
    poly(d, pts, fill=(255, 205, 70, 255), outline=(255, 245, 200, 255), width=2)
    inner = [(64 + (x - 64) * 0.5, 66 + (y - 66) * 0.5) for x, y in pts]
    poly(d, inner, fill=(255, 240, 170, 255))
    return im


def gold_bag():
    im, d = base((255, 200, 70))
    ell(d, 28, 46, 100, 108, fill=(170, 110, 50, 255))
    poly(d, [(46, 50), (82, 50), (92, 28), (64, 38), (36, 28)], fill=(200, 135, 60, 255))
    rect(d, 42, 46, 86, 54, 3, fill=(255, 210, 90, 255))
    ell(d, 48, 62, 80, 94, fill=(255, 205, 70, 255), outline=(255, 240, 180, 255), width=3)
    line(d, [(64, 70), (64, 86)], (170, 110, 50, 255), 4)
    line(d, [(56, 78), (72, 78)], (170, 110, 50, 255), 4)
    return im


def chest(ring, wood, trim, gem):
    im, d = base(ring)
    rect(d, 28, 60, 100, 100, 4, fill=wood)
    d.chord([28 * S, 34 * S, 100 * S, 86 * S], 180, 360, fill=wood)
    rect(d, 28, 56, 100, 64, 0, fill=trim)
    rect(d, 40, 36, 48, 100, 0, fill=trim)
    rect(d, 80, 36, 88, 100, 0, fill=trim)
    rect(d, 56, 54, 72, 74, 3, fill=trim)
    ell(d, 59, 58, 69, 68, fill=gem)
    return im


def rune_chest():
    return chest((90, 220, 210), (40, 70, 90, 255), (120, 255, 240, 255), (255, 255, 255, 255))


def royal_chest():
    return chest((255, 200, 70), (150, 40, 60, 255), (255, 205, 70, 255), (120, 220, 255, 255))


def messenger():
    im, d = base((255, 143, 184))
    # back bubble
    rect(d, 46, 30, 104, 72, 14, fill=(150, 90, 240, 255))
    poly(d, [(88, 70), (100, 84), (80, 70)], fill=(150, 90, 240, 255))
    # front bubble with a heart
    rect(d, 24, 48, 86, 94, 16, fill=(255, 143, 184, 255), outline=(255, 225, 235, 255), width=3)
    poly(d, [(36, 92), (30, 108), (52, 92)], fill=(255, 143, 184, 255))
    ell(d, 40, 60, 56, 76, fill=(255, 255, 255, 255))
    ell(d, 54, 60, 70, 76, fill=(255, 255, 255, 255))
    poly(d, [(41, 71), (69, 71), (55, 86)], fill=(255, 255, 255, 255))
    return im


def plate(d, rim=(235, 230, 245, 255)):
    ell(d, 22, 70, 106, 104, fill=(200, 195, 215, 255))
    ell(d, 24, 66, 104, 98, fill=rim)
    ell(d, 36, 72, 92, 92, fill=(250, 248, 255, 255))


def ing_flour():
    im, d = base((240, 220, 160))
    poly(d, [(38, 46), (90, 46), (98, 104), (30, 104)], fill=(236, 222, 188, 255), outline=(255, 245, 220, 255), width=2)
    poly(d, [(42, 46), (86, 46), (78, 30), (50, 30)], fill=(214, 196, 156, 255))
    rect(d, 44, 42, 84, 50, 3, fill=(180, 120, 72, 255))
    # moon on the sack
    ell(d, 52, 64, 78, 90, fill=(255, 215, 110, 255))
    ell(d, 58, 60, 84, 86, fill=(236, 222, 188, 255))
    return im


def ing_berry():
    im, d = base((255, 110, 150))
    for cx, cy in [(50, 74), (78, 74), (64, 54)]:
        ell(d, cx - 18, cy - 18, cx + 18, cy + 18, fill=(230, 50, 90, 255), outline=(255, 150, 180, 255), width=2)
        ell(d, cx - 10, cy - 12, cx - 3, cy - 5, fill=(255, 210, 225, 255))
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 12 if k % 2 == 0 else 5
        pts.append((64 + r * math.cos(a), 34 + r * math.sin(a)))
    poly(d, pts, fill=(255, 235, 140, 255))
    return im


def ing_herb():
    im, d = base((110, 230, 140))
    line(d, [(64, 104), (64, 40)], (70, 150, 80, 255), 4)
    for sx, y in [(-1, 50), (1, 62), (-1, 76), (1, 88)]:
        poly(d, [(64, y), (64 + sx * 34, y - 14), (64 + sx * 26, y + 6)], fill=(90, 210, 120, 255), outline=(170, 255, 190, 255), width=1)
    ell(d, 58, 28, 70, 40, fill=(120, 230, 150, 255))
    ell(d, 80, 40, 88, 48, fill=(190, 240, 255, 255))
    return im


def ing_meat():
    im, d = base((240, 120, 90))
    ell(d, 30, 40, 86, 96, fill=(200, 70, 60, 255), outline=(255, 160, 140, 255), width=3)
    ell(d, 44, 54, 68, 78, fill=(255, 200, 180, 255))
    line(d, [(76, 80), (98, 102)], (245, 240, 230, 255), 9)
    ell(d, 92, 94, 106, 108, fill=(245, 240, 230, 255))
    ell(d, 98, 88, 110, 100, fill=(245, 240, 230, 255))
    return im


def dish_pancake():
    im, d = base((255, 190, 110))
    plate(d)
    for i, y in enumerate([74, 64, 54]):
        ell(d, 36, y - 10, 92, y + 10, fill=(220, 150, 70, 255), outline=(250, 200, 120, 255), width=2)
    poly(d, [(46, 48), (82, 48), (78, 60), (50, 60)], fill=(150, 80, 30, 200))
    ell(d, 54, 32, 66, 44, fill=(230, 50, 90, 255))
    ell(d, 64, 30, 76, 42, fill=(230, 50, 90, 255))
    return im


def dish_tart():
    im, d = base((255, 120, 170))
    plate(d)
    ell(d, 32, 50, 96, 88, fill=(225, 165, 90, 255))
    ell(d, 38, 54, 90, 82, fill=(240, 80, 120, 255))
    for cx, cy in [(52, 64), (64, 60), (76, 64), (58, 74), (72, 74)]:
        ell(d, cx - 6, cy - 6, cx + 6, cy + 6, fill=(200, 30, 70, 255), outline=(255, 160, 190, 255), width=1)
    poly(d, [(64, 30), (67, 38), (75, 40), (67, 43), (64, 50), (61, 43), (53, 40), (61, 38)], fill=(255, 255, 255, 255))
    return im


def bowl(d, soup, rim):
    d.chord([26 * S, 40 * S, 102 * S, 106 * S], 0, 180, fill=rim)
    ell(d, 26, 58, 102, 82, fill=rim)
    ell(d, 32, 61, 96, 79, fill=soup)


def dish_stew():
    im, d = base((240, 120, 70))
    bowl(d, (190, 90, 40, 255), (120, 80, 60, 255))
    ell(d, 44, 64, 56, 72, fill=(240, 140, 60, 255))
    ell(d, 66, 63, 80, 73, fill=(160, 60, 50, 255))
    ell(d, 56, 70, 66, 76, fill=(110, 200, 110, 255))
    for x in (48, 64, 80):
        d.arc([(x - 6) * S, 30 * S, (x + 6) * S, 46 * S], 200, 340, fill=(255, 255, 255, 200), width=3 * S)
        d.arc([(x - 6) * S, 40 * S, (x + 6) * S, 56 * S], 20, 160, fill=(255, 255, 255, 200), width=3 * S)
    return im


def dish_salad():
    im, d = base((120, 230, 140))
    bowl(d, (90, 200, 110, 255), (235, 230, 245, 255))
    for cx, cy, c in [(46, 60, (70, 180, 90)), (60, 54, (120, 230, 140)), (76, 58, (70, 180, 90)), (86, 64, (120, 230, 140)), (40, 68, (120, 230, 140))]:
        ell(d, cx - 12, cy - 8, cx + 12, cy + 8, fill=c + (255,))
    ell(d, 54, 62, 64, 72, fill=(230, 50, 90, 255))
    ell(d, 70, 64, 80, 74, fill=(230, 50, 90, 255))
    return im


def dish_pie():
    im, d = base((255, 200, 70))
    plate(d)
    d.chord([30 * S, 36 * S, 98 * S, 100 * S], 180, 360, fill=(215, 145, 70, 255))
    rect(d, 30, 66, 98, 82, 4, fill=(190, 120, 55, 255))
    for x in (44, 58, 72, 86):
        line(d, [(x - 6, 50), (x + 2, 62)], (150, 90, 40, 255), 3)
    poly(d, [(64, 26), (72, 36), (64, 46), (56, 36)], fill=(255, 220, 90, 255), outline=(255, 250, 210, 255), width=1)
    return im


def kitchen():
    im, d = base((255, 190, 110))
    # cooking pot with steam and a ladle
    rect(d, 30, 60, 98, 100, 10, fill=(200, 110, 80, 255), outline=(255, 190, 150, 255), width=3)
    rect(d, 24, 54, 104, 64, 4, fill=(230, 140, 100, 255))
    rect(d, 18, 64, 30, 72, 3, fill=(230, 140, 100, 255))
    rect(d, 98, 64, 110, 72, 3, fill=(230, 140, 100, 255))
    ell(d, 54, 74, 74, 90, fill=(255, 225, 235, 255))
    poly(d, [(56, 84), (72, 84), (64, 94)], fill=(255, 225, 235, 255))
    for x in (46, 64, 82):
        d.arc([(x - 6) * S, 24 * S, (x + 6) * S, 40 * S], 200, 340, fill=(255, 255, 255, 220), width=3 * S)
        d.arc([(x - 6) * S, 34 * S, (x + 6) * S, 50 * S], 20, 160, fill=(255, 255, 255, 220), width=3 * S)
    return im


ICONS = {
    "item_sweet_cake": sweet_cake,
    "item_perfume": perfume,
    "item_skin_ticket": skin_ticket,
    "item_exp_potion": exp_potion,
    "item_energy_potion": energy_potion,
    "item_forge_ember": forge_ember,
    "item_hunt_core": hunt_core,
    "item_rune_pouch": rune_pouch,
    "item_star_stone": star_stone,
    "item_gold_bag": gold_bag,
    "item_rune_chest": rune_chest,
    "item_royal_chest": royal_chest,
    "icon_messenger": messenger,
    "item_ing_flour": ing_flour,
    "item_ing_berry": ing_berry,
    "item_ing_herb": ing_herb,
    "item_ing_meat": ing_meat,
    "item_dish_pancake": dish_pancake,
    "item_dish_tart": dish_tart,
    "item_dish_stew": dish_stew,
    "item_dish_salad": dish_salad,
    "item_dish_pie": dish_pie,
    "icon_kitchen": kitchen,
}

if __name__ == "__main__":
    import sys
    only = set(sys.argv[1:])
    for name, fn in ICONS.items():
        if only and name not in only:
            continue
        fn().resize((128, 128), Image.Resampling.LANCZOS).save("art/icons/%s.png" % name)
        print("wrote", name)
