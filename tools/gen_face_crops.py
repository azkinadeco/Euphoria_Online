#!/usr/bin/env python3
"""Precompute head crops for DB.face() -> data/face_crops.json.

Full-body art (tall images, or listed in FULL_BODY) gets an alpha-based crop centred on the head;
chest-up portraits keep the default crop in DB.face(). Run after adding hero/enemy art:
    python3 tools/gen_face_crops.py
"""
import json, os
import numpy as np
from PIL import Image

FULL_BODY = {"angela", "svormentis", "evy_blood_sage"}
# hand-placed crops [x, y, w, h] (fractions of the image) where the alpha heuristic misses the head
MANUAL = {"ygg_naar": [0.22, 0.04, 0.36, 0.40]}
db = json.load(open("data/character_database.json"))

def head_rect(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 128)
    if len(ys) == 0 or (a > 128).mean() > 0.95:
        return None
    top, bot = ys.min(), ys.max()
    fh = bot - top
    side = max(fh * 0.24, w * 0.25)
    band = a[top:int(top + fh * 0.30)] > 128
    cols = band.sum(0).astype(float)
    cx = (cols * np.arange(w)).sum() / max(1.0, cols.sum())
    rw = (a[top:int(top + fh * 0.4)] > 128).sum(1)
    k = int(np.argmax(rw > side * 0.35)) if (rw > side * 0.35).any() else 0
    y0 = max(0.0, top + k - side * 0.18)
    x0 = min(max(0.0, cx - side / 2), w - side)
    hh = min(side * 1.15, h - y0)
    return [round(x0 / w, 4), round(y0 / h, 4), round(side / w, 4), round(hh / h, 4)]

out = {}
for group in ("heroes", "enemies"):
    for e in db[group].values():
        paths = []
        if e.get("portrait"):
            paths.append(e["portrait"])
        for k, st in (e.get("char_states") or {}).items():
            if k != "lobby" and st.get("base"):
                paths.append(st["base"])
        for rp in paths:
            p = rp.replace("res://", "")
            if not os.path.exists(p):
                continue
            if e["id"] in MANUAL:
                out[rp] = MANUAL[e["id"]]
                continue
            w, h = Image.open(p).size
            if h / w < 1.25 and e["id"] not in FULL_BODY:
                continue
            r = head_rect(p)
            if r:
                out[rp] = r
json.dump(out, open("data/face_crops.json", "w"), indent=0, sort_keys=True)
print("face crops:", len(out))
