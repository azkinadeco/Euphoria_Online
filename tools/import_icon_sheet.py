"""Cut the icons out of a Gemini-edited catalog sheet (same 12-column layout as ALL_ICONS.png) and put them in the game.
  1. every accepted cell is cut out (dark background removed) into semi_3d_icons_v2/<folder>/<file>.png
  2. those cut-outs, plus any single PNG the artist dropped into semi_3d_icons_v2/<folder>/ by hand, are resized
     to the icon's game size and copied into art/ (originals backed up to _recut_backup/icons_semi3d_<time>/).
Cells whose picture does not match the icon (Gemini drew something else) are listed in SKIP and keep the old icon.
Run: python3 tools/import_icon_sheet.py            (dry run)
     python3 tools/import_icon_sheet.py --apply"""
import json, os, shutil, sys, time
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
ASSET = os.path.join(ROOT, 'Karakter Euphoria Online', 'icon asset')
V2 = os.path.join(ASSET, 'semi_3d_icons_v2')
SHEET = os.path.join(V2, 'ALL_ICONS_BETA.png')
apply = '--apply' in sys.argv

# sheet grid (measured on ALL_ICONS_BETA.png: gold cell outlines)
X0, Y0, PX, PY, CW, CH = 15, 77, 189.2, 221.3, 180, 140
# cells Gemini redrew as a different object -> keep the current icon
SKIP = {10: 'Bag drawn as a crest', 16: 'Date drawn as a portal', 20: 'Friends drawn as a winged emblem',
        43: 'Gear Chest drawn as silver coins', 44: 'Gems drawn as gold coins', 45: 'Gold (hand-made file used instead)',
        46: 'Event drawn as a crystal', 47: 'Hero Shards drawn as a gem', 55: "Hunter's Stew drawn as a fruit",
        56: 'Starberry Tart drawn as a potion', 58: 'Hero EXP Potion drawn as coal', 59: 'Forge Ember drawn as a coin',
        62: 'Starberry drawn as a crystal', 63: 'Moonwheat Flour drawn as a crystal', 64: 'Dewleaf Herb drawn as a book',
        65: 'Wild Game drawn as ore', 66: 'Oath Ring (hand-made file used instead)', 68: 'Royal Gear Chest drawn as a crest',
        69: 'Grand Rune Chest drawn as a crest'}
LAST_ICON = 80  # cells after this are 9-slice UI frames / brand art: never taken from the sheet

ORDER = ['Symbol in game', 'Icon all item in backpack', 'Icon shop ', 'Weapon', 'UI frame & button', 'VFX', 'Logo & brand']
man = json.load(open(os.path.join(ASSET, 'icon_manifest.json')))
order, seen = [], set()
for cat in ORDER:
    for e in man:
        if e['file'].split('/')[0] == cat and e['game_path'] not in seen:
            seen.add(e['game_path']); order.append(e)

def cut(sheet, i):
    c, r = i % 12, i // 12
    x, y = round(X0 + c * PX), round(Y0 + r * PY)
    im = sheet.crop((x + 6, y + 4, x + CW - 6, y + CH))
    a = np.asarray(im.convert('RGB')).astype(int)
    dark = a.max(2) < 34
    lab, _ = ndimage.label(dark)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(edge))
    bg = ndimage.binary_opening(bg, iterations=1)
    # drop stray specks (bits of the cell outline / label): keep blobs at least 5% of the main one
    fl, n = ndimage.label(~bg)
    if n > 1:
        sizes = ndimage.sum(np.ones_like(fl), fl, range(1, n + 1))
        keep = [k + 1 for k, sz in enumerate(sizes) if sz >= 0.05 * sizes.max()]
        bg = ~np.isin(fl, keep)
    alpha = Image.fromarray(np.where(bg, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    im = im.convert('RGBA'); im.putalpha(alpha)
    bb = im.getbbox()
    im = im.crop(bb)
    s = max(im.size) + 4
    sq = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    sq.paste(im, ((s - im.width) // 2, (s - im.height) // 2), im)
    return sq

sheet = Image.open(SHEET).convert('RGBA')
todo = {}  # game_path -> (src png, label)
for i, e in enumerate(order[:LAST_ICON + 1]):
    if i in SKIP:
        continue
    out = os.path.join(V2, e['file'].split('/')[0], os.path.basename(e['game_path']))
    if apply or not os.path.exists(out):
        os.makedirs(os.path.dirname(out), exist_ok=True)
        cut(sheet, i).save(out)
    todo[e['game_path']] = (out, e)
# hand-made single files win over sheet cells
for e in order:
    for cat in ORDER:
        p = os.path.join(V2, cat, os.path.basename(e['game_path']))
        if os.path.exists(p) and os.path.getmtime(p) < os.path.getmtime(SHEET) - 1:
            todo[e['game_path']] = (p, e)

bak = os.path.join(ROOT, '_recut_backup', 'icons_semi3d_%s' % time.strftime('%Y%m%d_%H%M%S'))
for gp, (src, e) in sorted(todo.items()):
    print(('UPDATE ' if apply else 'would update ') + gp + '  <- ' + os.path.relpath(src, V2))
    if not apply:
        continue
    os.makedirs(bak, exist_ok=True)
    dst = os.path.join(ROOT, gp)
    shutil.copy2(dst, os.path.join(bak, os.path.basename(dst)))
    im = Image.open(src).convert('RGBA')
    w, h = e['size']
    im.thumbnail((w, h), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    canvas.paste(im, ((w - im.width) // 2, (h - im.height) // 2), im)
    canvas.save(dst, optimize=True)
print('%d icon(s); skipped %d cells: %s' % (len(todo), len(SKIP), ', '.join('%d %s' % (k, v) for k, v in SKIP.items())))
