"""Import '*_char_evo_special.png' skins as the 'special' outfit state (Wardrobe-exclusive).
White backgrounds are cut out automatically. Run: python3 tools/import_special_skins.py"""
import json, os, glob, importlib.util, tempfile
import numpy as np
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online', 'hero')
spec = importlib.util.spec_from_file_location("imp", os.path.join(ROOT, 'tools', 'import_new_heroes.py'))
SKINS = {  # source → hero id
    # Lucidria, Hyeonxa, Kali, Abadonia: withdrawn, their source files are damaged.
    'New Hero 4 November/Ning Er/ninger_char_evo_special.png': 'ninger', 'New Hero 4 November/Spimei/spide_char_evo_special.png': 'spimei',
}
def has_white_bg(im):
    a = np.asarray(im.convert('RGBA')).astype(np.int16)
    edge = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    white = (edge[:, 3] > 200) & (edge[:, :3].min(1) > 235)
    return white.mean() > 0.2
db_path = os.path.join(ROOT, 'data', 'character_database.json')
db = json.load(open(db_path))
for rel, hid in SKINS.items():
    src = os.path.join(K, rel)
    im = Image.open(src).convert('RGBA')
    if has_white_bg(im):
        imp = importlib.util.module_from_spec(spec); spec.loader.exec_module(imp)
        # flatten onto white first: transparent margins would otherwise read as black
        flat = Image.new('RGBA', im.size, (255, 255, 255, 255)); flat.alpha_composite(im)
        fsrc = tempfile.mktemp(suffix='.png'); flat.convert('RGB').save(fsrc)
        tmp = tempfile.mktemp(suffix='.png'); imp.cutout(fsrc, tmp); im = Image.open(tmp).convert('RGBA')
        note = 'white bg removed'
    else:
        note = 'transparent'
    bb = im.getchannel('A').point(lambda p: 255 if p > 16 else 0).getbbox()
    im = im.crop((max(0, bb[0] - 8), max(0, bb[1] - 8), min(im.width, bb[2] + 8), min(im.height, bb[3] + 8)))
    im.thumbnail((1200, 1200), Image.LANCZOS)
    out = 'art/characters/heroes/%s/char/%s_char_special.png' % (hid, hid)
    os.makedirs(os.path.join(ROOT, os.path.dirname(out)), exist_ok=True)
    im.save(os.path.join(ROOT, out), optimize=True)
    db['heroes'][hid]['char_states']['special'] = {'base': 'res://' + out, 'interactions': []}
    print(hid, note, im.size)
json.dump(db, open(db_path, 'w'), indent=1)
