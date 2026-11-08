"""Import Hyeonxa's Christmas special skin ('Special Event/Hyeonxa Skin Christmash').
Backgrounds are already removed. Writes the special outfit (+ alt expression), its battle sprite and the event banner.
Run: python3 tools/import_xmas.py"""
import json, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
src = open(os.path.join(ROOT, 'tools', 'import_nov4.py')).read()
ns = {'__file__': os.path.join(ROOT, 'tools', 'import_nov4.py')}
exec(src[:src.index("db_path = os.path.join(ROOT, 'data', 'character_database.json')")], ns)
save, load_clean = ns['save'], ns['load_clean']
D = os.path.join(ROOT, 'Karakter Euphoria Online', 'Special Event', 'Hyeonxa Skin Christmash')
B = 'art/characters/heroes/hyeonxa'
base = save(load_clean(os.path.join(D, 'hyeonxa_char_skin_christmash.png')), B + '/char/hyeonxa_char_special.png', 1200)
alt = save(load_clean(os.path.join(D, 'hyeonxa_char_skin_christmash2.png')), B + '/char/hyeonxa_char_special_alt1.png', 1200)
spr = save(load_clean(os.path.join(D, 'hyeonxa_sprite_skin_christmash.png')), B + '/sprite/hyeonxa_sprite_special.png', 1000)
ban = save(load_clean(os.path.join(D, 'hyeonxa_banner_skin_christmash.png')), 'art/banners_event/banner_hyeonxa_xmas_1.png', 1100)
p = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(p))
h = db['heroes']['hyeonxa']
h['char_states']['special'] = {'base': base, 'interactions': [alt]}
h['special_sprite'] = spr
json.dump(db, open(p, 'w'), indent=1, ensure_ascii=False)
print('hyeonxa special:', base, alt, spr, ban)
