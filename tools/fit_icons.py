#!/usr/bin/env python3
"""Rescales icons whose picture uses only a small part of the canvas (lots of empty margin), so every icon
looks the same size in the UI. Originals are kept in _recut_backup/icons_small/.
Run from the project root:  python3 tools/fit_icons.py
"""
import glob
import os
import shutil

from PIL import Image

FILL = 0.94       # the picture's longer side after fitting, as a share of the canvas
LIMIT = 0.80      # icons already filling at least this much are left alone

for f in sorted(glob.glob('art/icons/*.png')):
    im = Image.open(f).convert('RGBA')
    box = im.getchannel('A').point(lambda v: 255 if v > 12 else 0).getbbox()
    if not box:
        continue
    w, h = im.size
    used = max((box[2] - box[0]) / w, (box[3] - box[1]) / h)
    if used >= LIMIT:
        continue
    back = os.path.join('_recut_backup/icons_small', os.path.basename(f))
    if not os.path.exists(back):
        shutil.copy(f, back)
    pic = im.crop(box)
    k = FILL * min(w / pic.width, h / pic.height)
    pic = pic.resize((max(1, round(pic.width * k)), max(1, round(pic.height * k))), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out.paste(pic, ((w - pic.width) // 2, (h - pic.height) // 2), pic)
    out.save(f)
    print('%-34s used %.0f%% -> %.0f%%' % (os.path.basename(f), used * 100, FILL * 100))
