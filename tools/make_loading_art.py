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
    ('abadonia', 'evo1', 'new backround maps/abadon city maps1.jpg'),
    ('mei', 'evo1', 'maps forest.jpg'),
    ('zennyo', 'evo1', 'maps big tree world.jpg'),
    ('morana', 'evo1', 'new backround maps/necro maps.jpg'),
    ('ninger', 'lobby', 'backround black market.jpg'),
    ('atalanta', 'evo1', 'maps galaxy.jpg'),
]
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
        im = Image.open(os.path.join(BG_DIR, bg)).convert('RGB')
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
    total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
    print('const SLIDES = ' + json.dumps(rows, ensure_ascii=False, indent='\t') + ';')
    print('// %d files, %.0f KB' % (len(os.listdir(OUT)), total / 1024))


if __name__ == '__main__':
    main()
