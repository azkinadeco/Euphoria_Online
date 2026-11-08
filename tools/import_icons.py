"""Bring edited icons from 'Karakter Euphoria Online/icon asset' back into the game.
Only files that changed are copied. Each one is resized back to its original game size (keeping its
aspect ratio, centred on a transparent canvas) so layouts don't break; originals go to _recut_backup/icons_<time>/.
Run: python3 tools/import_icons.py            (dry run: lists what would change)
     python3 tools/import_icons.py --apply"""
import hashlib, json, os, shutil, sys, time
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'Karakter Euphoria Online', 'icon asset')
apply = '--apply' in sys.argv
man = json.load(open(os.path.join(SRC, 'icon_manifest.json')))
bak = os.path.join(ROOT, '_recut_backup', 'icons_%s' % time.strftime('%Y%m%d_%H%M%S'))

def h(p):
    return hashlib.md5(open(p, 'rb').read()).hexdigest()

# the same icon can sit in several folders: use the most recently edited copy that differs from the game
best = {}
for e in man:
    src, dst = os.path.join(SRC, e['file']), os.path.join(ROOT, e['game_path'])
    if not os.path.exists(src) or (os.path.exists(dst) and h(src) == h(dst)):
        continue
    if e['game_path'] not in best or os.path.getmtime(src) > os.path.getmtime(os.path.join(SRC, best[e['game_path']]['file'])):
        best[e['game_path']] = e
changed = 0
for e in best.values():
    src, dst = os.path.join(SRC, e['file']), os.path.join(ROOT, e['game_path'])
    changed += 1
    print(('UPDATE ' if apply else 'would update ') + e['game_path'] + '  (' + e['label'] + ')')
    if not apply:
        continue
    os.makedirs(bak, exist_ok=True)
    if os.path.exists(dst):
        shutil.copy2(dst, os.path.join(bak, os.path.basename(dst)))
    im = Image.open(src).convert('RGBA')
    w, ht = e['size']
    if im.size != (w, ht):
        im.thumbnail((w, ht), Image.LANCZOS)
        canvas = Image.new('RGBA', (w, ht), (0, 0, 0, 0))
        canvas.paste(im, ((w - im.width) // 2, (ht - im.height) // 2), im)
        im = canvas
    im.save(dst, optimize=True)
print('%d changed icon(s)%s' % (changed, '' if apply else ' — run with --apply to copy them into the game'))
if apply and changed:
    print('Backup of the old files:', bak)
    print('Reopen Godot (or run Godot --headless --import) so it re-imports the textures.')
