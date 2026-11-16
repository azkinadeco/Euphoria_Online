#!/usr/bin/env python3
"""Finds asset references that fail silently: icons, sound effects and background keys that do not exist,
and big pictures imported lossless (they bloat the web build).

A missing icon is just a blank square and a missing sound is silence, so nothing ever reports them.
Run from the project root:  python3 tools/check_refs.py   (exit code 1 when something is missing)
"""
import glob
import json
import os
import re
import sys

src = {p: open(p, encoding='utf-8').read() for p in glob.glob('game/**/*.gd', recursive=True)}
icons = {os.path.basename(f)[:-4] for f in glob.glob('art/icons/*.png')}
audio = {os.path.relpath(f, 'audio')[:-4] for f in glob.glob('audio/**/*.wav', recursive=True)}
bad = []
for p, t in sorted(src.items()):
    for m in re.finditer(r'\bicon\("([^"%]+)"\)', t):
        if m.group(1) not in icons:
            bad.append('icon   %-24s %s' % (m.group(1), p))
    for m in re.finditer(r'"((?:icon|item|elem)_[a-z0-9_]+)"', t):
        # theme constant names such as "icon_max_width" are not files
        if m.group(1) not in icons and not m.group(1).startswith('icon_max'):
            bad.append('icon   %-24s %s' % (m.group(1), p))
    for m in re.finditer(r'\bsfx\("([^"%]+)"\)', t):
        if m.group(1) not in audio:
            bad.append('sfx    %-24s %s' % (m.group(1), p))
db = src['game/core/db.gd']
m = re.search(r'const BG := \{(.*?)\n\}', db, re.S)
bg = dict(re.findall(r'"([a-z0-9_]+)": "(res://[^"]+)"', m.group(1)))
for k, v in bg.items():
    if not os.path.exists(v[6:]):
        bad.append('bgfile %-24s %s' % (k, v))
for p, t in sorted(src.items()):
    for mm in re.finditer(r'(?:set_bg|DB\.bg)\("([a-z0-9_]+)"|"bg": "([a-z0-9_]+)"', t):
        k = mm.group(1) or mm.group(2)
        if k not in bg:
            bad.append('bg     %-24s %s' % (k, p))
for it in json.load(open('data/news.json', encoding='utf-8')):
    if it.get('bg', 'lobby') not in bg:
        bad.append('bg     %-24s data/news.json (%s)' % (it.get('bg'), it['id']))
# big pictures must be imported lossy (a lossless character art or backdrop adds megabytes to the web build)
for f in glob.glob('art/characters/**/*.import', recursive=True) + glob.glob('backround image/**/*.import', recursive=True) + glob.glob('art/banners_event/*.import'):
    if re.search(r'^compress/mode=0', open(f, encoding='utf-8').read(), re.M):
        bad.append('import %-22s %s (lossless: set compress/mode=1, lossy 0.85)' % ('', f))
bad = sorted(set(bad))
print('\n'.join(bad) if bad else 'check_refs: all %d icons, %d sounds and %d backgrounds referenced exist' % (len(icons), len(audio), len(bg)))
sys.exit(1 if bad else 0)
