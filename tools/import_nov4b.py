"""Import '4 nov part 2': hero Luby (+ special skin) and 5 enemies. Reuses tools/import_nov4.py helpers.
Run: python3 tools/import_nov4b.py"""
import json, os, glob, importlib.util, sys
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online')
src = open(os.path.join(ROOT, 'tools', 'import_nov4.py')).read()
helpers = src[:src.index("db_path = os.path.join(ROOT, 'data', 'character_database.json')")]
ns = {'__file__': os.path.join(ROOT, 'tools', 'import_nov4.py')}
exec(helpers, ns)
build, save, load_clean = ns['build'], ns['save'], ns['load_clean']
HEROES = {'Luby': ('luby', 'Luby', 'MECHA CAT MISCHIEF', 'WIND', 'ASSASSIN', 'BURST', '#8fe63a')}
ENEMIES = {
    'Scomantis': ('scomantis', 'Scomantis', 'EMERALD STINGER', 'WIND', 'ASSASSIN'),
    'Skelinch': ('skelinch', 'Skelinch', 'HELLFIRE PUNK', 'FIRE', 'WARRIOR'),
    'Snake Dragon': ('serpentia', 'Serpentia', 'FLAME-SCALE LAMIA', 'FIRE', 'MAGE'),
    'Voodo Puppet ': ('voodoo', 'Voodoo Doll', 'THE STITCHED DANCER', 'DARK', 'ASSASSIN'),
    'liza morph': ('lizamorph', 'Liza Morph', 'THE CRAWLING SHADOW', 'DARK', 'TANK'),
}
db_path = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(db_path))
for folder, (hid, name, title, elem, cls, typ, color) in HEROES.items():
    d = os.path.join(K, 'hero', 'New Hero 4 nov part 2', folder)
    special = [f for f in glob.glob(os.path.join(d, '*special*.png'))]
    # build() ignores files with 'special'? no — move them aside logically by filtering
    files_backup = special
    states, sp = build(d, hid, 'heroes')
    for f in special:
        states['special'] = {'base': save(load_clean(f), 'art/characters/heroes/%s/char/%s_char_special.png' % (hid, hid), 1200), 'interactions': []}
    db['heroes'][hid] = {'id': hid, 'display_name': name, 'title': title, 'element': elem, 'class': cls, 'type': typ,
                         'theme_color': color, 'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
    print('hero', hid, sorted(states.keys()), 'alts:', sum(len(s['interactions']) for s in states.values()), 'sprites', len(sp))
for folder, (eid, name, title, elem, cls) in ENEMIES.items():
    states, sp = build(os.path.join(K, 'enemy', 'New Enemy 4 november part2 ', folder), eid, 'enemies')
    db['enemies'][eid] = {'id': eid, 'display_name': name, 'title': title, 'element': elem, 'class': cls,
                          'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
    print('enemy', eid, sorted(states.keys()), 'sprites', len(sp))
json.dump(db, open(db_path, 'w'), indent=1)
