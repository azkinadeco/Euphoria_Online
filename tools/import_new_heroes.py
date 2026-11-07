"""Import heroes from 'Karakter Euphoria Online/hero/NEW HERO NOVEMBER 2026'.
Removes the white background (border flood-fill + edge de-fringe), writes PNGs to
art/characters/heroes/<id>/{char,sprite}/ and registers them in data/character_database.json.
Run: python3 tools/import_new_heroes.py"""
import json, os, re, glob
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'Karakter Euphoria Online', 'hero', 'NEW HERO NOVEMBER 2026')
HEROES = {  # folder -> (id, display name, title, element, class, type, color)
    'Abadonia': ('abadonia', 'Abadonia', 'ABYSSAL LION QUEEN', 'DARK', 'KNIGHT', 'DEFENSE', '#7b4bd6'),
    'Aqua': ('aqua', 'Aqua', 'CHALICE OF THE TIDES', 'WATER', 'HEALER', 'SUPPORT', '#2ec4b6'),
    'Atalanta': ('atalanta', 'Atalanta', 'THUNDERSTEP HUNTRESS', 'LIGHTNING', 'ASSASSIN', 'BURST', '#5aa9ff'),
    'Kali': ('kali', 'Kali', 'HUNDRED BLADE SAINT', 'WIND', 'WARRIOR', 'AOE', '#d9d2c3'),
    'Rubby': ('rubby', 'Rubby', 'BOMB BELLE', 'FIRE', 'MAGE', 'AOE', '#ff7043'),
    'Schylua': ('schylua', 'Schylua', 'FROST REAPER', 'ICE', 'WARRIOR', 'FREEZE', '#7fd6ff'),
    'Siv ': ('siv', 'Siv', 'THUNDER HAMMER MAIDEN', 'LIGHTNING', 'TANK', 'STUN', '#ff8fc7'),
    'Vexira': ('vexira', 'Vexira', 'SUCCUBUS TEMPTRESS', 'DARK', 'WARLOCK', 'DEBUFF', '#e0457b'),
    'Zennyo Ryuo': ('zennyo', 'Zennyo Ryuo', "DRAGON KING'S DAUGHTER", 'FIRE', 'MAGE', 'AOE', '#c0392b'),
    'sven': ('sven', 'Sven', 'GREATSWORD WANDERER', 'EARTH', 'WARRIOR', 'AOE', '#8d6e63'),
}

def cutout(path, out, max_side=None):
    im = Image.open(path).convert('RGB')
    a = np.asarray(im).astype(np.int16)
    v = a.mean(2); sat = a.max(2) - a.min(2)
    light = (v > 236) & (sat < 18)
    lab, n = ndimage.label(light)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    # soft edge: pixels next to background that are still quite light become partly transparent
    near = ndimage.binary_dilation(bg, iterations=2) & ~bg
    alpha = np.where(bg, 0.0, 1.0)
    edge_a = np.clip((255.0 - v) / 60.0, 0.0, 1.0)
    alpha = np.where(near, np.maximum(edge_a, 0.0), alpha)
    alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))).astype(np.float32) / 255.0
    # remove isolated specks
    solid = alpha > 0.5
    flab, fn = ndimage.label(solid)
    if fn > 1:
        sizes = ndimage.sum(solid, flab, range(1, fn + 1))
        keep = np.zeros(fn + 1, bool); keep[1:] = sizes > solid.size * 0.0008
        alpha = np.where(keep[flab] | (~solid & (alpha > 0)), alpha, 0.0)
    # de-fringe: un-blend white from semi-transparent edge pixels
    af = alpha[..., None]
    rgb = a.astype(np.float32)
    col = np.where(af > 0.02, (rgb - (1.0 - af) * 255.0) / np.maximum(af, 0.02), rgb)
    col = np.clip(col, 0, 255)
    img = Image.fromarray(np.dstack([col.astype(np.uint8), (alpha * 255).astype(np.uint8)]), 'RGBA')
    bb = img.getchannel('A').point(lambda p: 255 if p > 20 else 0).getbbox()
    if bb:
        pad = 10
        img = img.crop((max(0, bb[0] - pad), max(0, bb[1] - pad), min(img.width, bb[2] + pad), min(img.height, bb[3] + pad)))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    # second pass: remove flat white background trapped inside the silhouette (e.g. between legs)
    import importlib.util
    spec = importlib.util.spec_from_file_location("cwh", os.path.join(os.path.dirname(os.path.abspath(__file__)), "clean_white_holes.py"))
    cwh = importlib.util.module_from_spec(spec); spec.loader.exec_module(cwh)
    cwh.holes(out, True)

def sort_key(f):
    b = os.path.basename(f).lower()
    m = re.search(r'(\d+)([a-e]?)', b.split('evo')[-1] if 'evo' in b else b.split('_')[-1])
    return (int(m.group(1)) if m else 0, m.group(2) if m else '', b)

# guarded so other tools can import cutout() without re-running the whole import
if __name__ == '__main__':
    db_path = os.path.join(ROOT, 'data', 'character_database.json')
    db = json.load(open(db_path))
    for folder, (hid, name, title, elem, cls, typ, color) in HEROES.items():
        files = [f for f in glob.glob(os.path.join(SRC, folder, '*.jpg'))]
        chars = [f for f in files if 'char' in os.path.basename(f).lower()]
        sprites = [f for f in files if 'sprite' in os.path.basename(f).lower()]
        base_c = sorted([f for f in chars if 'evo' not in os.path.basename(f).lower()], key=sort_key)
        evo_c = sorted([f for f in chars if 'evo' in os.path.basename(f).lower()], key=sort_key)
        base_s = sorted([f for f in sprites if 'evo' not in os.path.basename(f).lower()], key=sort_key)
        evo_s = sorted([f for f in sprites if 'evo' in os.path.basename(f).lower()], key=sort_key)
        out_dir = 'art/characters/heroes/%s' % hid
        states = {}
        for i, f in enumerate(base_c):
            p = '%s/char/%s_char_stage%d.png' % (out_dir, hid, i + 1)
            cutout(f, os.path.join(ROOT, p)); states['stage%d' % (i + 1)] = {'base': 'res://' + p, 'interactions': []}
        for i, f in enumerate(evo_c):
            p = '%s/char/%s_char_evo%d.png' % (out_dir, hid, i + 1)
            cutout(f, os.path.join(ROOT, p)); states['evo%d' % (i + 1)] = {'base': 'res://' + p, 'interactions': []}
        sp = []
        for i, f in enumerate(base_s):
            p = '%s/sprite/%s_sprite_stage%d.png' % (out_dir, hid, i + 1)
            cutout(f, os.path.join(ROOT, p)); sp.append('res://' + p)
        for i, f in enumerate(evo_s):
            p = '%s/sprite/%s_sprite_evo%d.png' % (out_dir, hid, i + 1)
            cutout(f, os.path.join(ROOT, p)); sp.append('res://' + p)
        portrait = states['stage1']['base']
        db['heroes'][hid] = {'id': hid, 'display_name': name, 'title': title, 'element': elem, 'class': cls, 'type': typ,
                             'theme_color': color, 'portrait': portrait, 'char_states': states, 'sprites': sp}
        print(hid, len(states), 'arts,', len(sp), 'sprites')
    # shopkeeper NPC
    for i, f in enumerate(['Store Character.jpg', 'Store Character 2.jpg']):
        cutout(os.path.join(SRC, f), os.path.join(ROOT, 'art/npc/shopkeeper_%d.png' % (i + 1)))
    print('shopkeepers ok')
    json.dump(db, open(db_path, 'w'), indent=1)
