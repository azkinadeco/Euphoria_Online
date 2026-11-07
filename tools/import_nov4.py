"""Import the 4 November batch: 5 heroes, 3 enemies, special-event banners, lobby NPCs.
Sources are already transparent PNGs (one stray white background is cut out). Files ending in 'a'
(e.g. bunny_char_2a) are alternate expressions → stored as that state's "interactions".
'_loby' files → a "lobby" state used when the hero is the lobby secretary.
Run: python3 tools/import_nov4.py"""
import json, os, re, glob, importlib.util
import numpy as np
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online')
spec = importlib.util.spec_from_file_location("imp", os.path.join(ROOT, 'tools', 'import_new_heroes.py'))

HEROES = {  # folder -> (id, display name, title, element, class, type, colour, prefix)
    'Angela': ('angela', 'Angela', 'SERAPHIC VALKYRIE', 'LIGHT', 'PALADIN', 'DEFENSE', '#ffe08a', 'falkrie'),
    'Kara': ('kara', 'Kara', 'PHOENIX REAPER', 'FIRE', 'ASSASSIN', 'BURST', '#f2b33d', 'scythe'),
    'Mei': ('mei', 'Mei', 'CRIMSON BLADE BUNNY', 'FIRE', 'WARRIOR', 'AOE', '#d7263d', 'bunny'),
    'Ning Er': ('ninger', 'Ning Er', 'PRINCESS OF A THOUSAND COINS', 'EARTH', 'HEALER', 'SUPPORT', '#e8c25a', 'ninger'),
    'Spimei': ('spimei', 'Spimei', 'SCARLET SPIDER ENGINE', 'FIRE', 'RANGER', 'BURST', '#e0402f', 'spide'),
}
ENEMIES = {
    'Dark': ('hairly', 'Hairly', 'WITCH OF THE SHADOW TRESSES', 'DARK', 'MAGE', 'Hairly'),
    'Svormentis': ('svormentis', 'Svormentis', 'THE DEVOURING MAW', 'WATER', 'TANK', 'mouth'),
    'Ymir': ('ymir', 'Ymir', 'QUEEN OF THE BONE THRONE', 'EARTH', 'WARRIOR', 'skull'),
}

def load_clean(path):
    im = Image.open(path).convert('RGBA')
    if im.getpixel((2, 2))[3] > 200:   # opaque corner → white background left in; cut it out
        import tempfile
        imp = importlib.util.module_from_spec(spec); spec.loader.exec_module(imp)
        tmp = tempfile.mktemp(suffix='.png')
        imp.cutout(path, tmp)
        im = Image.open(tmp).convert('RGBA')
    bb = im.getchannel('A').point(lambda p: 255 if p > 16 else 0).getbbox()
    if bb:
        pad = 8
        im = im.crop((max(0, bb[0] - pad), max(0, bb[1] - pad), min(im.width, bb[2] + pad), min(im.height, bb[3] + pad)))
    return im

def save(im, rel, max_side):
    im = im.copy()
    im.thumbnail((max_side, max_side), Image.LANCZOS)
    out = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im.save(out, optimize=True)
    return 'res://' + rel

def key(f):
    b = os.path.splitext(os.path.basename(f))[0].lower()
    m = re.search(r'(evo)?(\d*)([a-z]?)$', b.split('_')[-1])
    return (1 if 'evo' in b else 0, int(m.group(2) or 1) if m else 0, m.group(3) if m else '')

def is_alt(f):
    tail = os.path.splitext(os.path.basename(f))[0].lower().split('_')[-1]
    return bool(re.match(r'^(evo)?\d+[a-e]$', tail)) and tail not in ('loby',)

def build(folder, hid, kind):
    files = glob.glob(os.path.join(folder, '**', '*.png'), recursive=True)
    chars = sorted([f for f in files if '_char_' in os.path.basename(f).lower() and 'loby' not in f.lower() and 'special' not in f.lower()], key=key)
    sprites = sorted([f for f in files if '_sprite_' in os.path.basename(f).lower() and 'loby' not in f.lower()], key=key)
    lobby = [f for f in files if 'loby' in os.path.basename(f).lower() and '_char_' in os.path.basename(f).lower()]
    base = 'art/characters/%s/%s' % (kind, hid)
    states = {}
    order = []
    n_stage = n_evo = 0
    for f in chars:
        if is_alt(f):
            if order:   # alternate expression of the previous state
                prev = order[-1]
                p = save(load_clean(f), '%s/char/%s_char_%s_alt%d.png' % (base, hid, prev, len(states[prev]['interactions']) + 1), 1200)
                states[prev]['interactions'].append(p)
            continue
        evo = 'evo' in os.path.basename(f).lower()
        if evo:
            n_evo += 1; name = 'evo%d' % n_evo
        else:
            n_stage += 1; name = 'stage%d' % n_stage
        p = save(load_clean(f), '%s/char/%s_char_%s.png' % (base, hid, name), 1200)
        states[name] = {'base': p, 'interactions': []}
        order.append(name)
    for f in lobby:
        states['lobby'] = {'base': save(load_clean(f), '%s/char/%s_char_lobby.png' % (base, hid), 1200), 'interactions': []}
    sp = []
    for i, f in enumerate([s for s in sprites if not is_alt(s)]):
        sp.append(save(load_clean(f), '%s/sprite/%s_sprite_%d.png' % (base, hid, i + 1), 512))
    return states, sp

db_path = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(db_path))
for folder, (hid, name, title, elem, cls, typ, color, _p) in HEROES.items():
    states, sp = build(os.path.join(K, 'hero', 'New Hero 4 November', folder), hid, 'heroes')
    db['heroes'][hid] = {'id': hid, 'display_name': name, 'title': title, 'element': elem, 'class': cls, 'type': typ,
                         'theme_color': color, 'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
    print('hero', hid, sorted(states.keys()), 'alts:', sum(len(s['interactions']) for s in states.values()), 'sprites:', len(sp))
for folder, (eid, name, title, elem, cls, _p) in ENEMIES.items():
    states, sp = build(os.path.join(K, 'enemy', 'New Enemy 4 November', folder), eid, 'enemies')
    db['enemies'][eid] = {'id': eid, 'display_name': name, 'title': title, 'element': elem, 'class': cls,
                          'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
    print('enemy', eid, sorted(states.keys()), 'sprites:', len(sp))
# lobby poses live in npc/new npc 4 nov (prefix → id)
LOBBY = {'falkrie': ('heroes', 'angela'), 'ninger': ('heroes', 'ninger'), 'spide': ('heroes', 'spimei'),
         'skull': ('enemies', 'ymir'), 'Hairly': ('enemies', 'hairly')}
for pre, (kind, cid) in LOBBY.items():
    f = os.path.join(K, 'npc', 'new npc 4 nov', '%s_char_loby.png' % pre)
    if os.path.exists(f):
        p = save(load_clean(f), 'art/characters/%s/%s/char/%s_char_lobby.png' % (kind, cid, cid), 1400)
        db[kind][cid]['char_states']['lobby'] = {'base': p, 'interactions': []}
        print('lobby pose', cid)
json.dump(db, open(db_path, 'w'), indent=1)
# special-event banners
for f in sorted(glob.glob(os.path.join(K, 'Special Event', '*.png'))):
    save(load_clean(f), 'art/banners_event/%s' % os.path.basename(f), 1100)
print('banners ok')
# lobby NPC (Hairly, with pivot sheet) — the others are the heroes' lobby poses imported above
save(load_clean(os.path.join(K, 'npc', 'new npc 4 nov', 'Hairly_char_loby.png')), 'art/npc/hairly_lobby.png', 1400)
print('npc ok')
