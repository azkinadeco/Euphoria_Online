"""Re-cut every character art from its source in 'Karakter Euphoria Online' with tools/recut.py.
Pairs source → art by name (char_3a → stage3_a / stage3_alt1, char_evo2 → evo2, sprite_evo → sprite_evo1,
*special* → *_special), verifies the pair by image similarity, keeps the old art's max size,
backs up the old file to _recut_backup/ and writes the new one.
python3 tools/recut_all.py --dry   (list pairs only)
python3 tools/recut_all.py [ids...]"""
import os, re, sys, glob, shutil, json, time
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
K = os.path.join(ROOT, 'Karakter Euphoria Online')
FOLDERS = {
    'cthollia': ['hero/Cthollia'], 'eropatra': ['hero/Eropatra'], 'eurnipha': ['hero/Eurnipha'], 'fidelia': ['hero/Fidelia'],
    'furu': ['hero/Furu'], 'gemora': ['hero/Gemora'], 'glytta': ['hero/Glytta'], 'hyeonxa': ['hero/Hyeonxa'],
    'lucidria': ['hero/Lucidria'], 'lumeira': ['hero/Lumeira'], 'micca': ['hero/Micca Pandora'], 'mora': ['hero/Mora'],
    'rumi': ['hero/Rumi'], 'scylla': ['hero/Scylla'], 'shina': ['hero/Shina'], 'valeria': ['hero/Valeria'], 'xylia': ['hero/Xylia'],
    'abadonia': ['hero/NEW HERO NOVEMBER 2026/Abadonia'], 'aqua': ['hero/NEW HERO NOVEMBER 2026/Aqua'],
    'atalanta': ['hero/NEW HERO NOVEMBER 2026/Atalanta'], 'kali': ['hero/NEW HERO NOVEMBER 2026/Kali'],
    'rubby': ['hero/NEW HERO NOVEMBER 2026/Rubby'], 'schylua': ['hero/NEW HERO NOVEMBER 2026/Schylua'],
    'siv': ['hero/NEW HERO NOVEMBER 2026/Siv '], 'vexira': ['hero/NEW HERO NOVEMBER 2026/Vexira'],
    'zennyo': ['hero/NEW HERO NOVEMBER 2026/Zennyo Ryuo'], 'sven': ['hero/NEW HERO NOVEMBER 2026/sven'],
    'angela': ['hero/New Hero 4 November/Angela'], 'kara': ['hero/New Hero 4 November/Kara'], 'mei': ['hero/New Hero 4 November/Mei'],
    'ninger': ['hero/New Hero 4 November/Ning Er'], 'spimei': ['hero/New Hero 4 November/Spimei'], 'luby': ['hero/New Hero 4 nov part 2/Luby'],
    'eroghost': ['enemy/Eroghost'], 'evy_blood_sage': ['enemy/Evy Blood Sage'], 'gumi_wolf': ['enemy/Gumi Wolf'],
    'slarkoi': ['enemy/Slarkoi'], 'slime': ['enemy/slime'], 'ex_nymph': ['enemy/ex-nymph'], 'ygg_naar': ['enemy/Ygg-Naar'],
    'svormentis': ['enemy/New Enemy 4 November/Svormentis'], 'ymir': ['enemy/New Enemy 4 November/Ymir'],
    'scomantis': ['enemy/New Enemy 4 november part2 /Scomantis'], 'skelinch': ['enemy/New Enemy 4 november part2 /Skelinch'],
    'serpentia': ['enemy/New Enemy 4 november part2 /Snake Dragon'], 'voodoo': ['enemy/New Enemy 4 november part2 /Voodo Puppet '],
    'lizamorph': ['enemy/New Enemy 4 november part2 /liza morph'],
}
IMG = ('.png', '.jpg', '.jpeg', '.webp')

def parse(name):
    """→ (kind, group, number, letter) e.g. ('char','evo',3,'b'); group ∈ stage/evo/special/lobby."""
    b = os.path.splitext(os.path.basename(name))[0].lower().replace(' ', '_')
    kind = 'sprite' if 'sprite' in b else 'char'
    if 'special' in b:
        return (kind, 'special', 1, '')
    if 'loby' in b or 'lobby' in b:
        return (kind, 'lobby', 1, '')
    tail = re.split(r'(?:char|sprite)_?', b)[-1]
    grp = 'evo' if 'evo' in tail else 'stage'
    tail = tail.replace('evo', '').replace('stage', '').strip('_')
    m = re.match(r'_?(\d*)_?(?:(alt)(\d)|([a-e]))?$', tail)
    if not m:
        return (kind, grp, -1, tail)
    num = int(m.group(1)) if m.group(1) else 1
    letter = chr(96 + int(m.group(3))) if m.group(2) else (m.group(4) or '')
    return (kind, grp, num, letter)

def sources(hid):
    out = []
    for f in FOLDERS.get(hid, []):
        for p in glob.glob(os.path.join(K, f, '**', '*'), recursive=True):
            if p.lower().endswith(IMG) and '/trash/' not in p.lower() and '_3d' not in p.lower() and 'depth' not in p.lower():
                out.append(p)
    return out

def arts(hid):
    base = 'heroes' if os.path.isdir(os.path.join(ROOT, 'art/characters/heroes', hid)) else 'enemies'
    return [p for p in glob.glob(os.path.join(ROOT, 'art/characters', base, hid, '*', '*.png')) if 'depth' not in p]

MANUAL = {
    'ygg_naar': {'ygg_naar_char_stage1.png': 'one eye lv1.jpeg', 'ygg_naar_char_stage2.png': 'one eye lv2.jpg',
                 'ygg_naar_char_evo1.png': 'one eye evo1.jpeg', 'ygg_naar_char_evo2.png': 'one eye evo2.jpeg'},
    'ex_nymph': {'ex_nymph_char_stage1.png': 'nymph1.jpeg'},
}

def importer_order(hid):
    """Exact numbering used by tools/import_new_heroes.py (sequential after sort)."""
    import importlib.util
    spec = importlib.util.spec_from_file_location('inh', os.path.join(ROOT, 'tools', 'import_new_heroes.py'))
    inh = importlib.util.module_from_spec(spec); spec.loader.exec_module(inh)
    folder = [f for f, v in inh.HEROES.items() if v[0] == hid]
    if not folder:
        return None
    files = glob.glob(os.path.join(inh.SRC, folder[0], '*.jpg'))
    chars = [f for f in files if 'char' in os.path.basename(f).lower()]
    sprites = [f for f in files if 'sprite' in os.path.basename(f).lower()]
    out = {}
    for kind, lst in (('char', chars), ('sprite', sprites)):
        base = sorted([f for f in lst if 'evo' not in os.path.basename(f).lower()], key=inh.sort_key)
        evo = sorted([f for f in lst if 'evo' in os.path.basename(f).lower()], key=inh.sort_key)
        for i, f in enumerate(base):
            out['%s_%s_stage%d.png' % (hid, kind, i + 1)] = f
        for i, f in enumerate(evo):
            out['%s_%s_evo%d.png' % (hid, kind, i + 1)] = f
    return out

def pairs(hid):
    if hid in MANUAL:
        d = os.path.join(K, FOLDERS[hid][0])
        res = [(os.path.join(d, s), a) for a in arts(hid) for n, s in MANUAL[hid].items() if os.path.basename(a) == n]
        return res, [a for a in arts(hid) if os.path.basename(a) not in MANUAL[hid]]
    order = importer_order(hid)
    if order is not None:
        res = [(order[os.path.basename(a)], a) for a in sorted(arts(hid)) if os.path.basename(a) in order]
        miss = []
        for a in arts(hid):
            if os.path.basename(a) in order:
                continue
            sp = [s for s in sources(hid) if 'special' in os.path.basename(s).lower()] if 'special' in a else []
            if sp:
                res.append((sp[0], a))
            else:
                miss.append(a)
        return res, miss
    srcs = sources(hid)
    by = {}
    for s in srcs:
        by.setdefault(parse(s), []).append(s)
    res, miss = [], []
    for a in sorted(arts(hid)):
        k = parse(a)
        s = by.get(k)
        if s is None and k[1] == 'stage' and k[2] == 1:
            s = by.get((k[0], 'stage', 1, k[3]))
        if s:
            res.append((s[0], a))
        else:
            miss.append(a)
    used = {r[0] for r in res}
    still = []
    for a in miss:
        s, sc = fallback(hid, a, used)
        if s:
            res.append((s, a)); used.add(s)
        else:
            still.append(a)
    return res, still

def quick_cut(src):
    """Cheap preview cut (colour key only) used to pair files by similarity."""
    from recut import bg_color
    im = Image.open(src)
    if im.mode == 'RGBA' and np.asarray(im)[..., 3].min() < 10:
        o = im
    else:
        rgb = im.convert('RGB'); a = np.asarray(rgb).astype(np.float32)
        bgc = bg_color(rgb)
        bgc = np.array([255.0, 255.0, 255.0]) if bgc is None else bgc
        al = (np.abs(a - bgc).max(2) > 30).astype(np.uint8) * 255
        o = Image.fromarray(np.dstack([a.astype(np.uint8), al]), 'RGBA')
    bb = o.getchannel('A').point(lambda v: 255 if v > 16 else 0).getbbox()
    return o.crop(bb) if bb else o

_qc = {}
def fallback(hid, art, used):
    old = Image.open(art)
    best, bs = None, 0.0
    for s in sources(hid):
        if parse(s)[0] != parse(art)[0]:
            continue
        if s not in _qc:
            _qc[s] = quick_cut(s)
        sc = similar(old, _qc[s]) - (0.05 if s in used else 0.0)
        if sc > bs:
            best, bs = s, sc
    return best if bs >= 0.6 else None, bs

def similar(old, new):
    """0..1 colour similarity where both are opaque (same source → high)."""
    o = old.convert('RGBA').resize((96, 128)); n = new.convert('RGBA').resize((96, 128))
    oa = np.asarray(o).astype(np.float32); na = np.asarray(n).astype(np.float32)
    both = (oa[..., 3] > 200) & (na[..., 3] > 200)
    if both.sum() < 200:
        return 0.0
    d = np.abs(oa[..., :3] - na[..., :3])[both].mean()
    return max(0.0, 1.0 - d / 60.0)

if __name__ == '__main__':
    dry = '--dry' in sys.argv
    ids = [a for a in sys.argv[1:] if not a.startswith('--')] or list(FOLDERS.keys())
    log = []
    if dry:
        for hid in ids:
            p, m = pairs(hid)
            print('%-15s %2d pairs, missing: %s' % (hid, len(p), [os.path.basename(x) for x in m]))
            for s, a in p:
                if parse(s)[1:] != parse(a)[1:]:
                    print('     ~', os.path.basename(a), '<-', os.path.basename(s))
        sys.exit()
    from recut import cutout_image, bg_color
    bdir = os.path.join(ROOT, '_recut_backup')
    t0 = time.time()
    for hid in ids:
        p, m = pairs(hid)
        for src, art in p:
            im = Image.open(src)
            if im.mode in ('RGBA', 'LA') and np.asarray(im.convert('RGBA'))[..., 3].min() < 10:
                log.append(('skip-transparent-source', hid, os.path.basename(art)))
                continue
            old = Image.open(art)
            new = cutout_image(im)
            cap = max(old.size)
            if max(new.size) > cap:
                sc = cap / max(new.size)
                new = new.resize((max(1, round(new.width * sc)), max(1, round(new.height * sc))), Image.LANCZOS)
            sim = similar(old, new)
            if sim < 0.55:
                log.append(('MISMATCH %.2f' % sim, hid, os.path.basename(art), os.path.basename(src)))
                print('MISMATCH', hid, os.path.basename(art), os.path.basename(src), round(sim, 2), flush=True)
                continue
            rel = os.path.relpath(art, ROOT)
            os.makedirs(os.path.dirname(os.path.join(bdir, rel)), exist_ok=True)
            if not os.path.exists(os.path.join(bdir, rel)):
                shutil.copy2(art, os.path.join(bdir, rel))
            new.save(art)
            log.append(('ok %.2f' % sim, hid, os.path.basename(art)))
            print('ok', hid, os.path.basename(art), round(sim, 2), '%.0fs' % (time.time() - t0), flush=True)
    json.dump(log, open(os.path.join(ROOT, '_recut_backup', 'log.json'), 'w'), indent=1)
    print('DONE', len(log))
