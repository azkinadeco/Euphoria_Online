#!/usr/bin/env python3
"""Merges the per-enemy rig files of data/rigs_dev/ into data/char_rigs.json and sets the face crop of
every merged art from its rig's head circle (data/face_crops.json), so icons show the real head even on
poses where it is not at the top of the picture (riding, lying, upside down).
Run from the project root:  python3 tools/merge_dev_rigs.py
"""
import glob
import json
import os

from PIL import Image

RIGS = 'data/char_rigs.json'
CROPS = 'data/face_crops.json'


def check(path, rig):
    """Returns a list of problems of one rig (empty = fine)."""
    bad = []
    for k, n in (('head', 3), ('neck', 2), ('chest', 2), ('hips', 2)):
        v = rig.get(k)
        if not isinstance(v, list) or len(v) != n or not all(isinstance(x, (int, float)) and 0 <= x <= 1 for x in v):
            bad.append('%s missing or out of range' % k)
    for b in rig.get('bones', []):
        if len(b) not in (7, 8) or not all(isinstance(x, (int, float)) for x in b):
            bad.append('bone %s' % b)
    if len(rig.get('bones', [])) > 10:
        bad.append('more than 10 bones')
    for f in rig.get('floats', []):
        if len(f) != 4:
            bad.append('float %s' % f)
    for g in rig.get('glows', []):
        if len(g) != 3:
            bad.append('glow %s' % g)
    if len(rig.get('floats', [])) > 6 or len(rig.get('glows', [])) > 6 or len(rig.get('eyes', [])) > 8:
        bad.append('too many floats / glows / eyes')
    for e in rig.get('eyes', []):
        if len(e) not in (0, 6):
            bad.append('eye %s' % e)
    if not os.path.exists(path.replace('res://', '')):
        bad.append('art file not found')
    return bad


def main():
    rigs = json.load(open(RIGS))
    crops = json.load(open(CROPS))
    n = 0
    problems = 0
    for f in sorted(glob.glob('data/rigs_dev/*.json')):
        for path, rig in json.load(open(f)).items():
            bad = check(path, rig)
            if bad:
                problems += 1
                print('PROBLEM %s: %s' % (path.split('/')[-1], '; '.join(bad)))
                continue
            rigs[path] = rig
            w, h = Image.open(path.replace('res://', '')).size
            cx, cy, r = rig['head']
            fw = min(1.0, 2.5 * r * h / w)
            fh = min(1.0, 2.5 * r * 1.12)
            x = min(max(cx - fw / 2, 0.0), 1.0 - fw)
            y = min(max(cy - fh / 2 - r * 0.1, 0.0), 1.0 - fh)
            crops[path] = [round(x, 4), round(y, 4), round(fw, 4), round(fh, 4)]
            n += 1
    json.dump(rigs, open(RIGS, 'w'))
    json.dump(crops, open(CROPS, 'w'), indent=0)
    print('merged %d rigs (%d problems); char_rigs.json now has %d entries' % (n, problems, len(rigs)))


if __name__ == '__main__':
    main()
