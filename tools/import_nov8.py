"""Import 'Update 8 Nov': heroes Gala, Morana (+special), Seraph, Tamo (+special) and enemy Octra (+banner).
Backgrounds are already removed by hand. Reuses tools/import_nov4.py helpers.
Run: python3 tools/import_nov8.py"""
import json, os, re, glob
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online')
src = open(os.path.join(ROOT, 'tools', 'import_nov4.py')).read()
ns = {'__file__': os.path.join(ROOT, 'tools', 'import_nov4.py')}
exec(src[:src.index("db_path = os.path.join(ROOT, 'data', 'character_database.json')")], ns)
save, load_clean, key = ns['save'], ns['load_clean'], ns['key']

def tail(f):
    return os.path.splitext(os.path.basename(f))[0].lower().split('_')[-1]

def build(folder, hid, kind):
    """Like import_nov4.build, but: a lettered file whose base is missing (Tamo's evo1a) becomes the base,
    'evo3aa' style double letters count as alternates, and 'banner'/'special' files are skipped."""
    files = glob.glob(os.path.join(folder, '**', '*.png'), recursive=True)
    chars = [f for f in files if '_char_' in os.path.basename(f).lower() and tail(f) not in ('banner', 'special')]
    def k2(f):
        m = re.match(r'^(evo)?(\d+)([a-z]*)$', tail(f))
        return (1 if m.group(1) else 0, int(m.group(2)), m.group(3))
    chars.sort(key=k2)
    base = 'art/characters/%s/%s' % (kind, hid)
    states, seen, n_stage, n_evo = {}, {}, 0, 0
    for f in chars:
        evo, num, letters = k2(f)
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
    for f in glob.glob(os.path.join(folder, '*special*.png')):
        states['special'] = {'base': save(load_clean(f), '%s/char/%s_char_special.png' % (base, hid), 1200), 'interactions': []}
    sprites = sorted([f for f in files if '_sprite_' in os.path.basename(f).lower()], key=key)
    sp = [save(load_clean(f), '%s/sprite/%s_sprite_%d.png' % (base, hid, i + 1), 512) for i, f in enumerate(sprites)]
    return states, sp

HEROES = {  # folder -> (id, name, title, element, class, type, colour)
    'Gala': ('gala', 'Gala', 'NEBULA FLAME TEMPTRESS', 'FIRE', 'MAGE', 'AOE', '#ff7a2f'),
    'Morana': ('morana', 'Morana', 'THE BLACK PRIESTESS', 'DARK', 'HEALER', 'SUPPORT', '#9b7bd6'),
    'Seraph': ('seraph', 'Seraph', 'ARCHANGEL OF A THOUSAND EYES', 'LIGHT', 'MAGE', 'BURST', '#ffe7a3'),
    'Tamo': ('tamo', 'Tamo', 'NINE-TAILED SWORD QUEEN', 'EARTH', 'WARRIOR', 'DEFENSE', '#f5c542'),
}
ENEMIES = {'Octra': ('octra', 'Octra', 'MISTRESS OF THE ABYSS BEAST', 'DARK', 'MAGE')}
db_path = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(db_path))
for folder, (hid, name, title, elem, cls, typ, color) in HEROES.items():
    states, sp = build(os.path.join(K, 'hero', 'New Hero Update 8 Nov', folder), hid, 'heroes')
    db['heroes'][hid] = {'id': hid, 'display_name': name, 'title': title, 'element': elem, 'class': cls, 'type': typ,
                         'theme_color': color, 'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
    print('hero', hid, {k: len(v['interactions']) for k, v in states.items()}, 'sprites', len(sp))
for folder, (eid, name, title, elem, cls) in ENEMIES.items():
    d = os.path.join(K, 'enemy', 'New Enemuy Update 8 Nov', folder)
    states, sp = build(d, eid, 'enemies')
    db['enemies'][eid] = {'id': eid, 'display_name': name, 'title': title, 'element': elem, 'class': cls,
                          'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
    print('enemy', eid, {k: len(v['interactions']) for k, v in states.items()}, 'sprites', len(sp))
    for f in glob.glob(os.path.join(d, '*banner*.png')):
        print('banner', save(load_clean(f), 'art/banners_event/banner_%s_1.png' % eid, 1100))
json.dump(db, open(db_path, 'w'), indent=1)
