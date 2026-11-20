#!/usr/bin/env python3
"""Audit, format, and generate Godot .import files for enemy backgrounds.

Target directory: backround image/new backround enemy/enemy_backgrounds
Standard dimensions: 1376x768 (16:9) JPEG, lossy compression (quality 0.85)
"""
import hashlib
import os
import sys

from enemy_background_catalog import ENEMY_BACKGROUND_CATALOG, ENEMY_BACKGROUND_DIR


GODOT_IMPORT_TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
path="res://.godot/imported/{file}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://backround image/new backround enemy/enemy_backgrounds/{file}"
dest_files=["res://.godot/imported/{file}-{md5}.ctex"]

[params]

compress/mode=1
compress/high_quality=false
compress/lossy_quality=0.85
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""


def compute_ctex_hash(file_path):
    """Computes standard MD5 hash for Godot imported cache naming."""
    h = hashlib.md5()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def audit_and_import(dry_run=False):
    os.makedirs(ENEMY_BACKGROUND_DIR, exist_ok=True)
    total = len(ENEMY_BACKGROUND_CATALOG)
    found = 0
    missing = []

    print(f"=== Enemy Backgrounds Audit ({total} characters) ===")
    print(f"{'Enemy ID':<18} {'Element':<10} {'Status':<12} {'Filename'}")
    print("-" * 65)

    for enemy_id, data in ENEMY_BACKGROUND_CATALOG.items():
        fname = data["file"]
        fpath = os.path.join(ENEMY_BACKGROUND_DIR, fname)
        if os.path.exists(fpath):
            found += 1
            print(f"{enemy_id:<18} {data['element']:<10} {'READY':<12} {fname}")
            # Generate .import file if missing
            import_path = f"{fpath}.import"
            if not os.path.exists(import_path) and not dry_run:
                file_hash = compute_ctex_hash(fpath)
                import_content = GODOT_IMPORT_TEMPLATE.format(file=fname, md5=file_hash)
                with open(import_path, "w", encoding="utf-8") as imp_f:
                    imp_f.write(import_content)
                print(f"  -> Created Godot .import: {import_path}")
        else:
            missing.append((enemy_id, data))
            print(f"{enemy_id:<18} {data['element']:<10} {'MISSING':<12} {fname}")

    print("-" * 65)
    print(f"Summary: {found}/{total} completed ({found*100//total}%), {len(missing)} pending.")
    return found, missing


if __name__ == "__main__":
    dry_run = "--dry-run" in sys.argv
    audit_and_import(dry_run=dry_run)
