#!/usr/bin/env python3
"""Deferred art packs for the web build (smaller first download).

Evolution and later stage art (*_evo* / *_stage2..9* character art + sprites, their 2.5D depth maps and painted lids) is left out of the
main .pck (exclude filter in export_presets.cfg "Web") and shipped as small extra packs that the game
downloads in the background after it starts (game/core/art_pack.gd). Until a pack has arrived, DB.tex()
shows the character's Lv1 art instead.

Writes:
  data/deferred_art.json      manifest compiled into the main pck (which files are deferred, which pack has them)
  builds/art_packs_plan.json  input for tools/make_art_packs.gd (target path -> source file pairs)
  builds/art_remap/...        exported-style .import remap files (only the [remap] section)

Run by tools/publish_web.sh before the export.  Usage: python3 tools/make_art_packs.py
"""
import glob, hashlib, json, os, re

CHUNK = 6_000_000          # bytes per pack (small packs = low peak memory on phones, progress survives reloads)
EVO = re.compile(r"_evo\d|_stage[2-9]")   # deferred forms: evolutions + stage 2..9 (Lv1 = stage1 stays)

def remap_of(import_text):
    out = []
    for line in import_text.splitlines():
        if line.startswith("[") and line.strip() != "[remap]" and out:
            break
        out.append(line)
    return "\n".join(out).strip() + "\n"

def main():
    root = os.getcwd()
    entries = []   # (char_key, res_png, import_path, ctex_res, ctex_file, size)
    evo_char = {}  # art basename -> char key (for depth maps and lids)
    for imp in sorted(glob.glob("art/characters/**/*.png.import", recursive=True)):
        png = imp[:-len(".import")]
        if not EVO.search(os.path.basename(png)):
            continue
        parts = png.split("/")
        key = "/".join(parts[2:4])           # heroes/<id> or enemies/<id>
        evo_char[os.path.basename(png)[:-4]] = key
        entries.append((key, png, imp))
    for folder, suffix in (("art/depth", "_depth"), ("art/lids", "_lid")):
        for imp in sorted(glob.glob(f"{folder}/*.png.import")):
            png = imp[:-len(".import")]
            base = os.path.basename(png)[:-4]
            if not base.endswith(suffix):
                continue
            art = base[: -len(suffix)]
            if EVO.search(art) and art in evo_char:
                entries.append((evo_char[art], png, imp))
    # resolve the imported .ctex of every entry
    files = []
    for key, png, imp in entries:
        text = open(imp, encoding="utf-8").read()
        m = re.search(r'path="res://(\.godot/imported/[^"]+)"', text)
        if not m or not os.path.exists(m.group(1)):
            print(f"skip (not imported yet): {png}")
            continue
        files.append({"key": key, "png": png, "imp": imp, "remap": remap_of(text),
                      "ctex": m.group(1), "size": os.path.getsize(m.group(1))})
    # group by character, heroes first, then pack characters into ~CHUNK sized packs
    by_key = {}
    for f in files:
        by_key.setdefault(f["key"], []).append(f)
    keys = sorted(by_key, key=lambda k: (not k.startswith("heroes/"), k))
    chunks, cur, cur_size = [], [], 0
    for k in keys:
        sz = sum(f["size"] for f in by_key[k])
        if cur and cur_size + sz > CHUNK:
            chunks.append(cur); cur, cur_size = [], 0
        cur.append(k); cur_size += sz
    if cur:
        chunks.append(cur)
    digest = hashlib.md5("".join(sorted(f["ctex"] for f in files)).encode()).hexdigest()[:8]
    manifest = {"v": digest, "packs": []}
    plan = {"out_dir": "builds/art_packs", "packs": []}
    os.makedirs("builds/art_remap", exist_ok=True)
    for i, ks in enumerate(chunks):
        name = f"art_{digest}_{i:02d}.pck"
        pf = [f for k in ks for f in by_key[k]]
        pairs = []
        for f in pf:
            rp = os.path.join("builds/art_remap", f["png"] + ".import")
            os.makedirs(os.path.dirname(rp), exist_ok=True)
            open(rp, "w", encoding="utf-8").write(f["remap"])
            pairs.append(["res://" + f["png"] + ".import", os.path.join(root, rp)])
            pairs.append(["res://" + f["ctex"], os.path.join(root, f["ctex"])])
        size = sum(f["size"] for f in pf)
        manifest["packs"].append({"file": name, "bytes": size, "ids": [k.split("/")[1] for k in ks],
                                  "files": ["res://" + f["png"] for f in pf]})
        plan["packs"].append({"file": name, "pairs": pairs})
    json.dump(manifest, open("data/deferred_art.json", "w"), indent=1)
    json.dump(plan, open("builds/art_packs_plan.json", "w"))
    total = sum(p["bytes"] for p in manifest["packs"])
    print(f"deferred art: {len(files)} files, {total / 1e6:.1f} MB in {len(chunks)} packs (v {digest})")

if __name__ == "__main__":
    main()
