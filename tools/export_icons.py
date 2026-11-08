"""Export every in-game icon / UI asset into 'Karakter Euphoria Online/icon asset' for manual editing
(e.g. with the Gemini CLI). Writes:
  <folder>/<file>.png        editable copies (same file name as in the game)
  SHEET_<n>_<folder>.png     catalog sheets: each icon with its file name + in-game name below
  ALL_ICONS.png              one overview sheet
  icon_manifest.json         file -> game path, size, label (used by tools/import_icons.py)
  README.md                  how to edit and bring the icons back
Run: python3 tools/export_icons.py"""
import glob, json, os, re, shutil
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'Karakter Euphoria Online', 'icon asset')

# in-game names for item icons (from DB.ITEMS) + readable names for the rest
src = open(os.path.join(ROOT, 'game', 'core', 'db.gd'), encoding='utf-8').read()
NAMES = {}
for name, icon in re.findall(r'"name": "([^"]+)"[^\n{}]*?"icon": "([a-z_0-9]+)"', src):
    NAMES.setdefault(icon, name)
EXTRA = {
    'icon_gold': 'Gold', 'icon_gem': 'Gems', 'icon_crystal': 'Hero EXP', 'icon_arena': 'Arena / Arena Coin', 'icon_guild': 'Guild / Guild Coin',
    'icon_shop': 'Shop', 'icon_awakening': 'Awakening', 'icon_equipment': 'Gear Chest / Equipment', 'icon_skills': 'Skill Book / Skills', 'icon_quest': 'Quests / Player EXP', 'icon_energy': 'Energy', 'icon_ticket': 'Summon Ticket',
    'icon_shards': 'Hero Shards / Runes', 'icon_heart': 'Bond / Friend Point', 'icon_zoom': 'Zoom / Full screen',
    'icon_combat_auto': 'Battle: AUTO', 'icon_combat_speed': 'Battle: Speed', 'icon_combat_target': 'Battle: Target',
    'icon_skill_basic': 'Skill: Basic', 'icon_skill_passive': 'Skill: Passive', 'icon_skill_tactical': 'Skill: Tactical',
    'icon_skill_ultimate': 'Skill: Ultimate', 'icon_live_ops': 'Event / Live Ops', 'icon_gacha': 'Summon menu',
    'icon_afk': 'AFK Rewards', 'icon_pass': 'Battle Pass', 'icon_codex': 'Codex', 'icon_boss': 'World Boss',
    'gear_relic': 'Gear: Accessory / Relic', 'btn': 'Button', 'btn_gold': 'Button: Gold',
    'panel': 'Panel', 'popup': 'Popup frame', 'tab': 'Tab', 'tab_on': 'Tab: selected',
    'rays': 'Light rays', 'crest': 'Title crest', 'ribbon': 'Popup ribbon', 'medallion': 'Medallion',
    'card_back': 'Summon card back', 'frame_r': 'Hero frame R', 'frame_sr': 'Hero frame SR', 'frame_ssr': 'Hero frame SSR',
    'logo_text': 'Logo text', 'logo_emblem': 'Logo emblem', 'logo_text_glow': 'Logo text (glow)', 'boot_splash': 'Boot splash',
    'app_icon': 'App icon',
}

def label_of(stem):
    if stem in EXTRA:
        return EXTRA[stem]
    if stem in NAMES:
        return NAMES[stem]
    s = re.sub(r'^(icon|item|elem|gear|vfx|btn|app)_', '', stem).replace('_', ' ').title()
    if stem.startswith('elem_'):
        return 'Element: ' + s
    if stem.startswith('gear_'):
        return 'Gear: ' + s
    if stem.startswith('btn_'):
        return 'Button: ' + s
    return s

# Folders (the first four were made by the artist). An icon may sit in more than one folder
# (e.g. Gems is both a bag item and a shop ware); tools/import_icons.py takes whichever copy was edited.
BAG, SHOP, SYMBOL, WEAPON = 'Icon all item in backpack', 'Icon shop ', 'Symbol in game', 'Weapon'
UIKIT, VFX, BRAND = 'UI frame & button', 'VFX', 'Logo & brand'
BAG_ICONS = {'icon_gold', 'icon_gem', 'icon_crystal', 'icon_energy', 'icon_ticket', 'icon_shards', 'icon_skills', 'icon_equipment', 'icon_live_ops'}
SHOP_ICONS = {'icon_shop', 'icon_gem', 'icon_gold', 'icon_ticket', 'icon_crystal', 'icon_energy', 'icon_skills', 'icon_equipment', 'icon_arena',
              'icon_guild', 'icon_heart', 'item_exp_potion', 'item_energy_potion', 'item_star_stone', 'item_celestial_gem', 'item_bouquet',
              'item_oath_ring', 'item_royal_chest', 'item_hunt_core', 'item_rune_chest', 'item_rune_pouch', 'item_sweet_cake', 'item_perfume',
              'item_skin_ticket', 'item_gold_bag', 'item_season_token', 'gear_weapon', 'gear_armor', 'gear_relic'}

def folders(path):
    stem = os.path.splitext(os.path.basename(path))[0]
    d = os.path.basename(os.path.dirname(path))
    if d == 'ui': return [UIKIT]
    if d == 'vfx': return [VFX]
    if d == 'brand': return [BRAND]
    out = []
    if stem.startswith('gear_'): out.append(WEAPON)
    elif stem.startswith('item_') or stem in BAG_ICONS: out.append(BAG)
    else: out.append(SYMBOL)
    if stem in SHOP_ICONS: out.append(SHOP)
    return out

files = sorted(glob.glob(os.path.join(ROOT, 'art', 'icons', '*.png')))
files += sorted(glob.glob(os.path.join(ROOT, 'art', 'ui', '*.png')))
files += sorted(glob.glob(os.path.join(ROOT, 'art', 'vfx', '*.png')))
files += sorted(f for f in glob.glob(os.path.join(ROOT, 'art', 'brand', '*.png')) if 'backup' not in f)

os.makedirs(OUT, exist_ok=True)
ALL_FOLDERS = [SYMBOL, BAG, SHOP, WEAPON, UIKIT, VFX, BRAND]

def font(sz):
    for f in ['/System/Library/Fonts/Supplemental/Arial Bold.ttf', '/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf']:
        if os.path.exists(f):
            return ImageFont.truetype(f, sz)
    return ImageFont.load_default()

F_NAME, F_FILE, F_TITLE = font(15), font(12), font(30)
manifest, groups = [], {}
for f in files:
    stem = os.path.splitext(os.path.basename(f))[0]
    im = Image.open(f)
    for cat in folders(f):
        os.makedirs(os.path.join(OUT, cat), exist_ok=True)
        shutil.copy2(f, os.path.join(OUT, cat, os.path.basename(f)))
        e = {'file': '%s/%s' % (cat, os.path.basename(f)), 'game_path': os.path.relpath(f, ROOT), 'size': list(im.size), 'label': label_of(stem),
             'nine_slice': cat == UIKIT and stem not in ('rays', 'crest', 'card_back', 'medallion')}
        manifest.append(e)
        groups.setdefault(cat, []).append((f, e))

CELL_W, CELL_H, ICON = 190, 222, 128
TITLES = {SYMBOL: 'SYMBOLS IN GAME (menus, elements, battle)', BAG: 'ALL ITEMS IN BACKPACK', SHOP: 'SHOP ICONS (wares & shop currencies)',
          WEAPON: 'WEAPON / GEAR', UIKIT: 'UI FRAMES & BUTTONS (9-slice: keep the border width!)', VFX: 'VFX', BRAND: 'LOGO & BRAND'}

def checker(w, h, s=12):
    bg = Image.new('RGB', (w, h), (44, 36, 60))
    d = ImageDraw.Draw(bg)
    for y in range(0, h, s):
        for x in range(0, w, s):
            if (x // s + y // s) % 2:
                d.rectangle((x, y, x + s - 1, y + s - 1), fill=(54, 45, 72))
    return bg

def sheet(items, title, cols=8):
    rows = (len(items) + cols - 1) // cols
    W, H = cols * CELL_W + 20, rows * CELL_H + 70
    img = Image.new('RGB', (W, H), (22, 16, 34))
    d = ImageDraw.Draw(img)
    d.text((14, 16), title + '   (%d)' % len(items), font=F_TITLE, fill=(255, 212, 121))
    for i, (f, e) in enumerate(items):
        x, y = 10 + (i % cols) * CELL_W, 60 + (i // cols) * CELL_H
        d.rounded_rectangle((x + 4, y + 4, x + CELL_W - 4, y + CELL_H - 4), 10, outline=(90, 70, 130), width=1)
        cb = checker(ICON + 16, ICON + 16)
        img.paste(cb, (x + (CELL_W - ICON - 16) // 2, y + 10))
        ic = Image.open(f).convert('RGBA')
        ic.thumbnail((ICON, ICON), Image.Resampling.LANCZOS)
        img.paste(ic, (x + (CELL_W - ic.width) // 2, y + 18 + (ICON - ic.height) // 2), ic)
        name = e['label'] if len(e['label']) <= 22 else e['label'][:21] + '…'
        tw = d.textlength(name, font=F_NAME)
        d.text((x + (CELL_W - tw) / 2, y + ICON + 32), name, font=F_NAME, fill=(255, 255, 255))
        fn = os.path.basename(f)
        tw = d.textlength(fn, font=F_FILE)
        d.text((x + (CELL_W - tw) / 2, y + ICON + 54), fn, font=F_FILE, fill=(180, 165, 215))
        sz = '%dx%d' % tuple(e['size'])
        tw = d.textlength(sz, font=F_FILE)
        d.text((x + (CELL_W - tw) / 2, y + ICON + 70), sz, font=F_FILE, fill=(120, 110, 150))
    return img

for f in glob.glob(os.path.join(OUT, 'SHEET_*.png')):
    os.remove(f)
for i, cat in enumerate(ALL_FOLDERS):
    if cat in groups:
        sheet(groups[cat], TITLES[cat]).save(os.path.join(OUT, 'SHEET_%d_%s.png' % (i + 1, cat.strip().replace(' ', '_').replace('&', 'and'))))
seen, allitems = set(), []
for cat in ALL_FOLDERS:
    for it in groups.get(cat, []):
        if it[1]['game_path'] not in seen:
            seen.add(it[1]['game_path']); allitems.append(it)
sheet(allitems, 'EUPHORIA ONLINE — ALL ICONS & UI ASSETS', cols=12).save(os.path.join(OUT, 'ALL_ICONS.png'))
json.dump(manifest, open(os.path.join(OUT, 'icon_manifest.json'), 'w'), indent=1, ensure_ascii=False)
print('exported', len(manifest), 'assets into', OUT)
