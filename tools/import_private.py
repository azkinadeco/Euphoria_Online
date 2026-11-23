#!/usr/bin/env python3
"""Private-room outfits: '<anything>_private.png' in a hero's folder under 'Karakter Euphoria Online/hero'.
Saved as art/characters/heroes/<id>/char/<id>_char_private.png (1200 px, white background cut out) and
written to the character database as heroes[<id>]['private_art']. REST TOGETHER in the Private Room lets the
hero wear it for one hour (Game.private_active).
Run: python3 tools/import_private.py   then Godot --headless --path . --import (and tools/make_depth_auto.py)"""
import glob, json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online', 'hero')
src = open(os.path.join(ROOT, 'tools', 'import_nov4.py')).read()
ns = {'__file__': os.path.join(ROOT, 'tools', 'import_nov4.py')}
exec(src[:src.index("def key(f):")], ns)
save, load_clean = ns['save'], ns['load_clean']

db_path = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(db_path))
heroes = db['heroes']
by_name = {}
for hid, h in heroes.items():
    by_name[h.get('display_name', hid).lower().replace(' ', '')] = hid
    by_name[hid.lower()] = hid
done = []
for f in sorted(glob.glob(os.path.join(K, '**', '*_private.png'), recursive=True)):
    folder = os.path.basename(os.path.dirname(f)).strip().lower().replace(' ', '')
    hid = by_name.get(folder)
    if not hid:
        print('no hero for folder', folder, f); continue
    rel = 'art/characters/heroes/%s/char/%s_char_private.png' % (hid, hid)
    heroes[hid]['private_art'] = save(load_clean(f), rel, 1200)
    done.append(hid)
json.dump(db, open(db_path, 'w'), indent=1, ensure_ascii=False)
print('private outfits:', done)
