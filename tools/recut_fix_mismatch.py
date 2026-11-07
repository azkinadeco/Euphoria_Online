"""Second pass for pairs recut_all.py rejected: confirm 'same artwork' with multi-scale
template matching of the old art (on white) inside the source, then re-cut them.
python3 tools/recut_fix_mismatch.py [--dry]"""
import os, re, sys, json, shutil
import numpy as np, cv2
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import recut_all as R

def gray_on_white(im):
    im = im.convert('RGBA')
    bg = Image.new('RGBA', im.size, (255, 255, 255, 255)); bg.alpha_composite(im)
    return np.asarray(bg.convert('L')).astype(np.float32)

def same_art(old, src_im):
    s = gray_on_white(src_im); o = gray_on_white(old)
    sw = 260.0
    s = cv2.resize(s, (int(sw), int(s.shape[0] * sw / s.shape[1])))
    best = -1.0
    for f in np.linspace(0.45, 1.0, 23):
        w = int(sw * f); h = int(o.shape[0] * w / o.shape[1])
        if h > s.shape[0] or w < 20 or h < 20:
            continue
        t = cv2.resize(o, (w, h))
        r = cv2.matchTemplate(s, t, cv2.TM_CCOEFF_NORMED)
        best = max(best, float(r.max()))
    return best

if __name__ == '__main__':
    dry = '--dry' in sys.argv
    lines = open(os.path.join(R.ROOT, '_recut_backup', 'run.log')).read().splitlines()
    todo = [l.split() for l in lines if l.startswith('MISMATCH')]
    from recut import cutout_image
    for _, hid, art_name, src_name, _sim in todo:
        art = [a for a in R.arts(hid) if os.path.basename(a) == art_name][0]
        src = [s for s in R.sources(hid) if os.path.basename(s) == src_name]
        if not src:
            print('nosrc', hid, art_name); continue
        sc = same_art(Image.open(art), Image.open(src[0]))
        verdict = sc >= 0.55
        print('%s %-12s %-28s %-28s %.2f' % ('OK ' if verdict else 'BAD', hid, art_name, src_name, sc), flush=True)
        if dry or not verdict:
            continue
        old = Image.open(art)
        new = cutout_image(Image.open(src[0]))
        cap = max(old.size)
        if max(new.size) > cap:
            k = cap / max(new.size)
            new = new.resize((round(new.width * k), round(new.height * k)), Image.LANCZOS)
        rel = os.path.relpath(art, R.ROOT)
        b = os.path.join(R.ROOT, '_recut_backup', rel)
        os.makedirs(os.path.dirname(b), exist_ok=True)
        if not os.path.exists(b):
            shutil.copy2(art, b)
        new.save(art)
        print('   recut', art_name, flush=True)
