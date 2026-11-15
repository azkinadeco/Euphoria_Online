#!/usr/bin/env python3
"""Builds the small images of the web loading screen (web_shell/loading/).

The loading page shows a slideshow while the game downloads: an in-game map with a hero in front of it.
Run from the project root:  python3 tools/make_loading_art.py   (needs Pillow)
It prints the SLIDES list to paste into web_shell/euphoria_shell.html when the line-up changes.
"""
import json
import os
import re

from PIL import Image

OUT = 'web_shell/loading'
BG_DIR = 'backround image'
# hero id, character art state, background file
SLIDES = [
    ('shina', 'evo1', 'new backround maps/dragon fire maps.jpg'),
    ('angela', 'lobby', 'maps assgard.jpg'),
    ('valeria', 'evo1', 'maps es.jpg'),
    ('xylia', 'evo1', 'maps galaxy.jpg'),
    ('lumeira', 'evo1', 'maps big tree world.jpg'),
    ('morana', 'evo1', 'new backround maps/necro maps.jpg'),
    ('kali', 'evo1', 'maps forest.jpg'),
    ('atalanta', 'evo1', 'maps galaxy.jpg'),
]
# a hero's own backdrop wins over the map listed above
HERO_BG = 'backround image/new backround hero/hero_backgrounds/bg_%s.jpg'
BG_W = 1280
HERO_H = 1000


def quotes():
    src = open('game/core/db.gd', encoding='utf-8').read()
    out = {}
    for hid, _, _ in SLIDES:
        m = re.search(r'^\t"%s": "([^"]+)",$' % hid, src, re.M)
        out[hid] = m.group(1) if m else ''
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    db = json.load(open('data/character_database.json', encoding='utf-8'))['heroes']
    q = quotes()
    rows = []
    for i, (hid, state, bg) in enumerate(SLIDES):
        own = HERO_BG % hid
        im = Image.open(own if os.path.exists(own) else os.path.join(BG_DIR, bg)).convert('RGB')
        im = im.resize((BG_W, round(im.height * BG_W / im.width)), Image.Resampling.LANCZOS)
        bg_name = 'bg_%s.jpg' % hid
        im.save(os.path.join(OUT, bg_name), quality=72, optimize=True, progressive=True)
        ch = Image.open('art/characters/heroes/%s/char/%s_char_%s.png' % (hid, hid, state)).convert('RGBA')
        box = ch.getbbox()
        if box:
            ch = ch.crop(box)
        ch = ch.resize((round(ch.width * HERO_H / ch.height), HERO_H), Image.Resampling.LANCZOS)
        hero_name = 'hero_%s.webp' % hid
        ch.save(os.path.join(OUT, hero_name), quality=82, method=6)
        e = db[hid]
        rows.append({'id': hid, 'name': e.get('display_name', hid.capitalize()), 'title': e.get('title', ''),
                     'elem': e.get('element', 'LIGHT'), 'quote': q[hid]})
    logo = Image.open('art/brand/logo_text_glow.png').convert('RGBA')
    logo = logo.crop(logo.getbbox())
    logo = logo.resize((720, round(logo.height * 720 / logo.width)), Image.Resampling.LANCZOS)
    logo.save(os.path.join(OUT, 'logo.webp'), quality=88, method=6)
    share_card(logo)
    total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
    print('const SLIDES = ' + json.dumps(rows, ensure_ascii=False, indent='\t') + ';')
    print('// %d files, %.0f KB' % (len(os.listdir(OUT)), total / 1024))


def share_card(logo):
    """1200x630 preview picture for chat apps and social networks (og:image)."""
    W, H = 1200, 630
    bg = Image.open(os.path.join(BG_DIR, 'maps assgard.jpg')).convert('RGB')
    sc = max(W / bg.width, H / bg.height)
    bg = bg.resize((round(bg.width * sc), round(bg.height * sc)), Image.Resampling.LANCZOS)
    bg = bg.crop(((bg.width - W) // 2, (bg.height - H) // 2, (bg.width - W) // 2 + W, (bg.height - H) // 2 + H)).convert('RGBA')
    # dark fade on the left for the logo
    shade = Image.new('RGBA', (W, H), (7, 4, 14, 0))
    px = shade.load()
    for x in range(W):
        a = int(235 * max(0.0, 1.0 - x / (W * 0.72)) ** 1.2)
        for y in range(H):
            px[x, y] = (7, 4, 14, a)
    bg = Image.alpha_composite(bg, shade)
    for hid, state, dx, hh in (('abadonia', 'evo1', 470, 600), ('angela', 'lobby', 760, 640)):
        ch = Image.open('art/characters/heroes/%s/char/%s_char_%s.png' % (hid, hid, state)).convert('RGBA')
        ch = ch.crop(ch.getbbox())
        ch = ch.resize((round(ch.width * hh / ch.height), hh), Image.Resampling.LANCZOS)
        bg.alpha_composite(ch, (dx, H - hh + 20 if hh < H else 0), (0, 0, min(ch.width, W - dx), min(ch.height, H - max(0, H - hh + 20))))
    lg = logo.resize((440, round(logo.height * 440 / logo.width)), Image.Resampling.LANCZOS)
    bg.alpha_composite(lg, (50, (H - lg.height) // 2 - 10))
    bg.convert('RGB').save(os.path.join(OUT, 'share.jpg'), quality=84, optimize=True, progressive=True)


if __name__ == '__main__':
    main()
