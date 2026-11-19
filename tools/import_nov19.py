"""Import 'New Hero 19 Nov 2026' (9 heroes) and the 4 hero costumes in 'Costume/Hero'.
Sources are transparent PNGs (two stray white backgrounds are cut out by load_clean).
Heroes: '<n>' = stage form, 'evo<n>' = evolution, a trailing letter (2a, evo1b) = alternate expression of
that form ('3a' without a '3' becomes the base). 'evo' with no number counts as evo1. 'banner' is skipped.
Costumes become the hero's Wardrobe special skin ('special' state): the first art is the base, every other
pose of the set is an alternate (shown in the art viewer), sprites -> special_sprite / special_sprite_evo.
Run: python3 tools/import_nov19.py"""
import json, os, re, glob
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online')
src = open(os.path.join(ROOT, 'tools', 'import_nov4.py')).read()
ns = {'__file__': os.path.join(ROOT, 'tools', 'import_nov4.py')}
exec(src[:src.index("def key(f):")], ns)
save, load_clean = ns['save'], ns['load_clean']

SRC = os.path.join(K, 'hero', 'New Hero 19 Nov 2026')
HEROES = {  # folder -> (id, name, title, element, class, type, colour)
    'Aura': ('aura', 'Aura', 'ARCANE RING ARCHER', 'ICE', 'RANGER', 'BURST', '#9d8cff'),
    'Fuji': ('fuji', 'Fuji', 'SCARLET SYRINGE NURSE', 'LIGHT', 'HEALER', 'SUPPORT', '#d1343e'),
    'Kyra': ('kyra', 'Kyra', 'JADEFLAME ONI', 'DARK', 'WARLOCK', 'DEBUFF', '#2fd67a'),
    'Sharas': ('sharas', 'Sharas', 'CHAINSAW DRAGONESS', 'FIRE', 'WARRIOR', 'AOE', '#e3a23a'),
    'Toka': ('toka', 'Toka', 'BLAZING FIST BOXER', 'FIRE', 'WARRIOR', 'BURST', '#ff3b3b'),
    'Tora': ('tora', 'Tora', 'JADE DRAGON SWORD DANCER', 'WIND', 'ASSASSIN', 'BURST', '#8fe37a'),
    'Tsundae': ('tsundae', 'Tsundae', 'AZURE FLAME HEIRESS', 'FIRE', 'MAGE', 'AOE', '#7fb2ff'),
    'Vila': ('vila', 'Vila', 'CRIMSON WING IDOL', 'DARK', 'ASSASSIN', 'BURST', '#c4202f'),
    'Yumi': ('yumi', 'Yumi', 'BUNNY HAMMER WARDEN', 'EARTH', 'TANK', 'DEFENSE', '#f0e1b5'),
}
SKINS = {  # folder -> hero id
    'Angela Flaminggo Skin': 'angela', 'Mei Surfing Skin': 'mei',
    'Eropatra Halloween Skin': 'eropatra', 'Rubby Summer Skin': 'rubby',
}

def tail(f):
    return os.path.splitext(os.path.basename(f))[0].lower().split('_')[-1]

def k2(f):
    t = tail(f)
    m = re.match(r'^(evo)?(\d*)([a-z]*)$', t)
    return (1 if m.group(1) else 0, int(m.group(2) or 1), m.group(3), t)

def is_sprite(f):
    return os.path.basename(os.path.dirname(f)).lower() == 'sprite' or '_sprite_' in os.path.basename(f).lower()

def hero(folder, hid):
    files = glob.glob(os.path.join(folder, '**', '*.png'), recursive=True)
    chars = sorted([f for f in files if not is_sprite(f) and '_char_' in os.path.basename(f).lower() and tail(f) != 'banner'], key=k2)
    base = 'art/characters/heroes/%s' % hid
    states, seen, n_stage, n_evo = {}, {}, 0, 0
    for f in chars:
        evo, num, letters, _ = k2(f)
        grp = (evo, num)
        if grp in seen:
            prev = seen[grp]
            p = save(load_clean(f), '%s/char/%s_char_%s_alt%d.png' % (base, hid, prev, len(states[prev]['interactions']) + 1), 1200)
            states[prev]['interactions'].append(p)
            continue
        if evo:
            n_evo += 1; name = 'evo%d' % n_evo
        else:
            n_stage += 1; name = 'stage%d' % n_stage
        states[name] = {'base': save(load_clean(f), '%s/char/%s_char_%s.png' % (base, hid, name), 1200), 'interactions': []}
        seen[grp] = name
    # sprites: one per form number, alternate-expression sprites (1a) are left out
    sprites = sorted([f for f in files if is_sprite(f) and not k2(f)[2]], key=k2)
    sp, ns_, ne = [], 0, 0
    for f in sprites:
        if k2(f)[0]:
            ne += 1; p = '%s/sprite/%s_sprite_evo%d.png' % (base, hid, ne)
        else:
            ns_ += 1; p = '%s/sprite/%s_sprite_stage%d.png' % (base, hid, ns_)
        sp.append(save(load_clean(f), p, 512))
    return states, sp

def skin(folder, hid):
    files = glob.glob(os.path.join(folder, '**', '*.png'), recursive=True)
    chars = sorted([f for f in files if not is_sprite(f) and '_char_' in os.path.basename(f).lower()], key=k2)
    # the banner pose is kept as one more alternate
    base = 'art/characters/heroes/%s' % hid
    arts = [save(load_clean(f), '%s/char/%s_char_special%s.png' % (base, hid, '' if i == 0 else '_alt%d' % i), 1200)
            for i, f in enumerate(chars)]
    sprites = sorted([f for f in files if is_sprite(f)], key=lambda f: (1 if 'evo' in tail(f) or '_char_' in os.path.basename(f) else 0, f))
    sp = [save(load_clean(f), '%s/sprite/%s_sprite_special%s.png' % (base, hid, '' if i == 0 else '_%d' % (i + 1)), 512)
          for i, f in enumerate(sprites)]
    return arts, sp

db_path = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(db_path))
for folder, (hid, name, title, elem, cls, typ, color) in HEROES.items():
    states, sp = hero(os.path.join(SRC, folder), hid)
    db['heroes'][hid] = {'id': hid, 'display_name': name, 'title': title, 'element': elem, 'class': cls, 'type': typ,
                         'theme_color': color, 'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
    print('hero', hid, {k: len(v['interactions']) for k, v in states.items()}, 'sprites', [s.split('/')[-1] for s in sp])
for folder, hid in SKINS.items():
    arts, sp = skin(os.path.join(K, 'Costume', 'Hero', folder), hid)
    h = db['heroes'][hid]
    h['char_states']['special'] = {'base': arts[0], 'interactions': arts[1:]}
    h['special_sprite'] = sp[0]
    if len(sp) > 1:
        h['special_sprite_evo'] = sp[-1]
    else:
        h.pop('special_sprite_evo', None)
    print('skin', hid, len(arts), 'arts', [s.split('/')[-1] for s in sp])
json.dump(db, open(db_path, 'w'), indent=1, ensure_ascii=False)
