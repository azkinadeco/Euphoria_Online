#!/usr/bin/env python3
"""Helper script to post-process generated semi-3D icon images into transparent 512x512 PNGs.

Applies a smooth circular mask with antialiased borders matching the game's medallion style,
and copies them into semi_3d_icons_v2/ under their appropriate subfolders.
"""
import os
import glob
from PIL import Image, ImageDraw

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_ASSET_DIR = os.path.join(ROOT_DIR, "Karakter Euphoria Online", "icon asset")
OUT_BASE_DIR = os.path.join(ICON_ASSET_DIR, "semi_3d_icons_v2")

TARGET_SIZE = 512
MARGIN = 16  # padding in pixels on 512 canvas


def process_image(src_path, dst_path, is_circle=True):
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    with Image.open(src_path) as im:
        im = im.convert("RGBA")
        # Resize to working resolution
        im_resized = im.resize((TARGET_SIZE, TARGET_SIZE), Image.Resampling.LANCZOS)
        
        if is_circle:
            # Create high quality antialiased circle mask
            mask_hi = Image.new("L", (TARGET_SIZE * 4, TARGET_SIZE * 4), 0)
            draw = ImageDraw.Draw(mask_hi)
            m = MARGIN * 4
            draw.ellipse([m, m, mask_hi.width - m, mask_hi.height - m], fill=255)
            mask = mask_hi.resize((TARGET_SIZE, TARGET_SIZE), Image.Resampling.LANCZOS)
            im_resized.putalpha(mask)
            
        im_resized.save(dst_path, "PNG")
        print(f"Processed: {dst_path}")


if __name__ == "__main__":
    print(f"Post-processor ready. Target base directory: {OUT_BASE_DIR}")
