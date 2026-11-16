"""Import 'New Enemy Update 15 nov': 17 enemies (art already cut out by hand).
Reuses the save / load_clean helpers of tools/import_nov4.py.
Run: python3 tools/import_nov15.py"""
import glob
import json
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'Karakter Euphoria Online', 'enemy', 'New Enemy Update 15 nov ')
src = open(os.path.join(ROOT, 'tools', 'import_nov4.py')).read()
ns = {'__file__': os.path.join(ROOT, 'tools', 'import_nov4.py')}
exec(src[:src.index("db_path = os.path.join(ROOT, 'data', 'character_database.json')")], ns)
save, load_clean = ns['save'], ns['load_clean']

# folder -> (id, name, title, element, class)
ENEMIES = {
    'Amatera': ('amatera', 'Amatera', 'CHAINED HAND OF THE PIT', 'DARK', 'MAGE'),
    'Anthis': ('anthis', 'Anthis', 'PALE MOTH WANDERER', 'WIND', 'ASSASSIN'),
    'Cleara': ('cleara', 'Cleara', 'PHARAOH OF THE GILDED TOMB', 'EARTH', 'MAGE'),
    'Code Zero': ('code_zero', 'Code Zero', 'PILOT OF THE SKULL WORM', 'LIGHTNING', 'TANK'),
    'Cow Girl': ('cow_girl', 'Cow Girl', 'MEADOW BRUISER', 'EARTH', 'WARRIOR'),
    'Graeae': ('graeae', 'Graeae', 'THE BANDAGED MAW', 'DARK', 'TANK'),
    'Kurenai': ('kurenai', 'Kurenai', 'EMERALD MANTIS BLADE', 'WIND', 'ASSASSIN'),
    'Lamia': ('lamia', 'Lamia', 'VIOLET REAVER', 'DARK', 'WARRIOR'),
    'Lolth': ('lolth', 'Lolth', 'BROODMOTHER OF WHISPERS', 'DARK', 'MAGE'),
    'Nagini': ('nagini', 'Nagini', 'GORGON OF THE STILL LAKE', 'WATER', 'MAGE'),
    'Nox': ('nox', 'Nox', 'MIDNIGHT GEL', 'CHAOS', 'TANK'),
    'Octavia-Vex': ('octavia', 'Octavia-Vex', 'DEEP CURRENT WARDEN', 'WATER', 'TANK'),
    'Rin': ('rin', 'Rin', 'AZURE STINGER', 'ICE', 'RANGER'),
    'Roza Sha': ('roza', 'Roza Sha', 'GILDED GUNSLINGER', 'LIGHT', 'RANGER'),
    'Selene': ('selene', 'Selene', 'NIGHTWING SUCCUBUS', 'DARK', 'MAGE'),
    'Veyr-Nok': ('veyr_nok', 'Veyr-Nok', 'KEEPER OF THE WATCHING BALLOONS', 'CHAOS', 'MAGE'),
    "Xa'niyus": ('xaniyus', "Xa'niyus", 'HORNED TIDE HERALD', 'WIND', 'WARRIOR'),
}


def tail(f):
    return os.path.splitext(os.path.basename(f))[0].lower().split('_')[-1]


def order(f):
    """(is_evo, number, letters). 'evo' = evo 1, 'loby' = an extra stage after the numbered ones."""
    t = tail(f)
    if t in ('loby', 'lobby'):
        return (0, 99, '')
    m = re.match(r'^(evo)?(\d*)([a-z]*)$', t)
    return (1 if m.group(1) else 0, int(m.group(2) or 1), m.group(3))


def build(folder, eid):
    files = glob.glob(os.path.join(folder, '**', '*.png'), recursive=True)
    chars = sorted([f for f in files if '_char_' in os.path.basename(f).lower()], key=order)
    base = 'art/characters/enemies/%s' % eid
    states, seen, n_stage, n_evo = {}, {}, 0, 0
    for f in chars:
        evo, num, letters = order(f)
        grp = (evo, num)
        if grp in seen:   # lettered file = another expression of the same pose
            prev = seen[grp]
            p = save(load_clean(f), '%s/char/%s_char_%s_alt%d.png' % (base, eid, prev, len(states[prev]['interactions']) + 1), 1200)
            states[prev]['interactions'].append(p)
            continue
        if evo:
            n_evo += 1
            name = 'evo%d' % n_evo
        else:
            n_stage += 1
            name = 'stage%d' % n_stage
        states[name] = {'base': save(load_clean(f), '%s/char/%s_char_%s.png' % (base, eid, name), 1200), 'interactions': []}
        seen[grp] = name
    sprites = sorted([f for f in files if '_sprite_' in os.path.basename(f).lower()], key=order)
    sp = [save(load_clean(f), '%s/sprite/%s_sprite_%d.png' % (base, eid, i + 1), 512) for i, f in enumerate(sprites)]
    return states, sp


def main():
    db_path = os.path.join(ROOT, 'data', 'character_database.json')
    db = json.load(open(db_path))
    for folder, (eid, name, title, elem, cls) in ENEMIES.items():
        states, sp = build(os.path.join(SRC, folder), eid)
        db['enemies'][eid] = {'id': eid, 'display_name': name, 'title': title, 'element': elem, 'class': cls,
                              'portrait': states['stage1']['base'], 'char_states': states, 'sprites': sp}
        print('%-10s %s sprites %d' % (eid, {k: len(v['interactions']) for k, v in states.items()}, len(sp)))
    json.dump(db, open(db_path, 'w'), indent=1)


if __name__ == '__main__':
    main()
