#!/usr/bin/env python3
"""Costume (special skin) forms from the owner's costume sets in 'Karakter Euphoria Online/Costume/Hero'.

tools/import_nov19.py saved every pose of a set as art/.../<id>_char_special[_alt<i>].png in this order
(sorted by k2). File tails: '1', '2', '3' = costume stages, 'evo1'..'evo5' = costume evolutions, a trailing
letter ('1a', 'evo2b') = alternate expression of that form, 'loby' / 'banner' = extra poses of form 1.
Writes db['heroes'][id]['special_forms'] = [{"base", "interactions", "kind": "stage"|"evo", "n"}, ...].
The unlock rank of each form is decided in game (Game.costume_form_req): stage 2 / 3 at 4 / 5 stars,
evo 1 at 6 gold stars, evo 2..5 at Azure / Crimson / Violet / Abyss.
Run: python3 tools/costume_forms.py   (no new art files are written)
"""
import glob, json, os, re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online')
SKINS = {'Angela Flaminggo Skin': 'angela', 'Mei Surfing Skin': 'mei',
         'Eropatra Halloween Skin': 'eropatra', 'Rubby Summer Skin': 'rubby'}

def tail(f):
    return os.path.splitext(os.path.basename(f))[0].lower().split('_')[-1]

def k2(f):  # same order as tools/import_nov19.py
    t = tail(f)
    m = re.match(r'^(evo)?(\d*)([a-z]*)$', t)
    return (1 if m.group(1) else 0, int(m.group(2) or 1), m.group(3), t)

def is_sprite(f):
    return os.path.basename(os.path.dirname(f)).lower() == 'sprite' or '_sprite_' in os.path.basename(f).lower()

db_path = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(db_path))
for folder, hid in SKINS.items():
    files = glob.glob(os.path.join(K, 'Costume', 'Hero', folder, '**', '*.png'), recursive=True)
    chars = sorted([f for f in files if not is_sprite(f) and '_char_' in os.path.basename(f).lower()], key=k2)
    base = 'res://art/characters/heroes/%s/char/%s_char_special' % (hid, hid)
    forms, by = [], {}
    for i, f in enumerate(chars):
        path = base + ('' if i == 0 else '_alt%d' % i) + '.png'
        if not os.path.exists(os.path.join(ROOT, path[6:])):
            print('missing', path); continue
        evo, num, letters, t = k2(f)
        if t in ('loby', 'oby', 'banner') or not re.match(r'^(evo)?\d*[a-z]*$', t) or letters in ('loby', 'oby', 'banner'):
            key = (0, 1)        # lobby / banner poses: extra expressions of the first form
        else:
            key = (evo, num)
        if key not in by:
            by[key] = {'base': path, 'interactions': [], 'kind': 'evo' if key[0] else 'stage', 'n': key[1]}
            forms.append(by[key])
        else:
            by[key]['interactions'].append(path)
    forms.sort(key=lambda fm: (fm['kind'] == 'evo', fm['n']))
    db['heroes'][hid]['special_forms'] = forms
    print(hid, [(fm['kind'], fm['n'], len(fm['interactions'])) for fm in forms])
json.dump(db, open(db_path, 'w'), indent=1, ensure_ascii=False)
