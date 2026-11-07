class_name DB
extends RefCounted
## Static game data for Euphoria Online (v2 core).
## All gameplay numbers live here so balancing never needs UI changes.

const ART_ROOT := "res://art/characters/"
const BG := {
	"lobby": "res://backround image/backround loby.jpg",
	"battle": "res://backround image/backround battle.jpg",
	"boss": "res://backround image/backround boss maps.jpg",
	"world": "res://backround image/backround story maps.jpg",
	"forest": "res://backround image/maps forest.jpg",
	"aqua": "res://backround image/maps aqua.jpg",
	"hell": "res://backround image/maps hell.jpg",
	"ice": "res://backround image/maps es.jpg",
	"galaxy": "res://backround image/maps galaxy.jpg",
	"asgard": "res://backround image/maps assgard.jpg",
	"space": "res://backround image/maps space.jpg",
	"alien": "res://backround image/maps alien planet.jpg",
	"blackhole": "res://backround image/maps blackhole.jpg",
	"bigtree": "res://backround image/maps big tree world.jpg",
	"blackmarket": "res://backround image/backround black market.jpg",
	"pool": "res://backround image/backround kolam renang.jpg",
	"abaddon": "res://backround image/new backround maps/abadon city maps1.jpg",
	"apocalypse": "res://backround image/new backround maps/aphocalipse maps.jpg",
	"dino": "res://backround image/new backround maps/dino maps.jpg",
	"dragonfire": "res://backround image/new backround maps/dragon fire maps.jpg",
	"necro": "res://backround image/new backround maps/necro maps.jpg",
	"outland": "res://backround image/new backround maps/outland maps.jpg",
	"onsen": "res://backround image/new backround maps/onsen backround.jpg",
	"gameroom": "res://backround image/new backround maps/room game backround.jpg",
	"room1": "res://backround image/new backround maps/room1.jpg",
	"room2": "res://backround image/new backround maps/room2.jpg",
	"shower": "res://backround image/new backround maps/shower backround.jpg",
}

const RARITY_COLOR := {"R": Color("#5fa8ff"), "SR": Color("#c77dff"), "SSR": Color("#ffc94a")}
const RARITY_START_STAR := {"R": 1, "SR": 2, "SSR": 3}
const MAX_STAR := 6
const MAX_BOND := 10
const MAX_DEPLOY := 5
const MAX_ROUNDS := 5
const MAX_SKILL_LV := 5

## Feature gating by player level (progressive disclosure for new players).
const FEATURE_UNLOCK := {"garden": 2, "minigame": 2, "gallery": 2, "dungeon": 3, "pass": 3, "friends": 4, "event": 4,
	"arena": 5, "worldboss": 5, "festival": 2, "bestiary": 2, "date": 4, "hunt": 12, "rift": 15, "room": 3, "photo": 2, "forge": 6, "tower": 6, "expedition": 6, "guild": 7, "messenger": 2}
## Grid shown in the lobby MENU (route, icon, label).
const MENU_FEATURES := [
	["shop", "icon_shop", "Shop"], ["bag", "icon_bag", "Bag"], ["pass", "icon_pass", "Season Pass"],
	["dungeon", "icon_dungeon", "Dungeon"], ["arena", "icon_arena", "Arena"], ["tower", "icon_tower", "Tower"],
	["worldboss", "icon_boss", "World Boss"], ["hunt", "icon_combat_target", "Boss Hunt"], ["rift", "icon_awakening", "Starlight Rift"],
	["event", "icon_live_ops", "Event"], ["festival", "icon_festival", "Festival"], ["bestiary", "icon_boss", "Bestiary"],
	["expedition", "icon_afk", "Expedition"], ["garden", "icon_garden", "Garden"], ["room", "icon_room", "Private Room"], ["date", "icon_date", "Date"],
	["wardrobe", "icon_heart", "Wardrobe"], ["guild", "icon_guild", "Guild"], ["friends", "icon_friends", "Friends"], ["gallery", "icon_codex", "Gallery"], ["settings", "icon_settings", "Settings"],
	["photo", "icon_codex", "Photo Studio"], ["forge", "icon_equipment", "Forge"], ["messenger", "icon_messenger", "Messenger"],
]
## MENU sections (route lists, in display order).
const MENU_SECTIONS := [
	["BATTLE", ["dungeon", "arena", "tower", "worldboss", "hunt", "rift"]],
	["EVENTS", ["event", "festival", "pass"]],
	["HEROES & BOND", ["messenger", "date", "room", "photo", "garden", "expedition", "gallery", "bestiary"]],
	["SHOP & SOCIAL", ["shop", "forge", "wardrobe", "bag", "guild", "friends", "settings"]],
]
const MAX_AWAKEN := 5
const AWAKEN_STAT := 0.06          # +6% HP/ATK/DEF per awaken level
const AWAKEN_SHARDS := [40, 60, 80, 100, 120]

# ---------------------------------------------------------------- black market (daily rotating shop)
const MARKET_SIZE := 6
const MARKET_REFRESH_COST := 50
const MARKET_REFRESHES := 3
const MARKET_POOL := [
	{"give": {"summon_ticket": 2}, "price": 240, "cur": "gems", "w": 3},
	{"give": {"rune:atk:3": 1}, "price": 180, "cur": "gems", "w": 3},
	{"give": {"rune:crit:3": 1}, "price": 200, "cur": "gems", "w": 3},
	{"give": {"rune:hp:3": 1}, "price": 160, "cur": "gems", "w": 3},
	{"give": {"gear:weapon:SSR": 1}, "price": 450, "cur": "gems", "w": 1},
	{"give": {"gear:armor:SSR": 1}, "price": 450, "cur": "gems", "w": 1},
	{"give": {"skill_book": 3}, "price": 30000, "cur": "gold", "w": 4},
	{"give": {"star_stone": 10}, "price": 300, "cur": "gems", "w": 3},
	{"give": {"celestial_gem": 3}, "price": 20000, "cur": "gold", "w": 4},
	{"give": {"exp_potion": 10}, "price": 25000, "cur": "gold", "w": 5},
	{"give": {"gear_chest_ssr": 1}, "price": 380, "cur": "gems", "w": 2},
	{"give": {"rune_chest": 2}, "price": 300, "cur": "gems", "w": 2},
	{"give": {"energy_potion": 3}, "price": 90, "cur": "gems", "w": 4},
	{"give": {"oath_ring": 1}, "price": 1500, "cur": "gems", "w": 1},
]
const MARKET_SHARD_PRICE := {"R": 60, "SR": 120, "SSR": 260}

## Role passives (always active in battle, both sides).
const PASSIVES := {
	"GUARD": {"name": "Iron Guard", "roles": ["TANK", "PALADIN", "KNIGHT"], "desc": "Takes 15% less damage."},
	"RAGE": {"name": "Battle Rage", "roles": ["WARRIOR"], "desc": "+8% ATK at the end of every round (max +40%)."},
	"PRECISION": {"name": "Precision", "roles": ["ASSASSIN"], "desc": "+20% Crit chance and stronger crits (x1.9)."},
	"ARCANE": {"name": "Arcane Pierce", "roles": ["MAGE", "WARLOCK"], "desc": "Ignores 25% of the target's DEF."},
	"HUNTER": {"name": "Hunter's Eye", "roles": ["RANGER"], "desc": "+20% damage to enemies outside the front line."},
	"GRACE": {"name": "Grace", "roles": ["HEALER", "BUFFER"], "desc": "End of round: heals the weakest ally for 6% of her Max HP."},
}

static func passive_of(id: String) -> String:
	var r := role_of(id)
	for k in PASSIVES.keys():
		if r in PASSIVES[k]["roles"]:
			return k
	return ""

## Team synergy from the most common element group on a side.
static func synergy(ids: Array) -> Dictionary:
	var counts := {}
	for id in ids:
		var g: String = ELEMENT_GROUP.get(element_of(id), "LIGHT")
		counts[g] = int(counts.get(g, 0)) + 1
	var best := ""
	var n := 0
	for k in counts.keys():
		if int(counts[k]) > n:
			n = int(counts[k])
			best = k
	var bonus: float = [0.0, 0.0, 0.05, 0.10, 0.15, 0.20, 0.20][mini(n, 6)]
	return {"element": best, "count": n, "bonus": bonus, "distinct": counts.size()}

## Skill power scales +12% per skill level (damage, heal and DoT).
static func skill_at(skill: Dictionary, lv: int) -> Dictionary:
	if lv <= 1:
		return skill
	var s := skill.duplicate()
	var m := 1.0 + 0.12 * float(lv - 1)
	for k in ["mult", "heal", "burn"]:
		if s.has(k):
			s[k] = float(s[k]) * m
	return s

## Six combat elements. Some heroes display a sub-element (Ice, Lightning, Chaos)
## which maps onto one of these for the advantage wheel.
const ELEMENT_GROUP := {"FIRE": "FIRE", "WATER": "WATER", "ICE": "WATER", "WIND": "WIND", "LIGHTNING": "WIND", "EARTH": "EARTH", "LIGHT": "LIGHT", "DARK": "DARK", "CHAOS": "DARK"}
const ELEMENT_BEATS := {"FIRE": "WIND", "WIND": "EARTH", "EARTH": "WATER", "WATER": "FIRE", "LIGHT": "DARK", "DARK": "LIGHT"}
const ELEMENT_COLOR := {"FIRE": Color("#ff6b4a"), "WATER": Color("#4ab3ff"), "ICE": Color("#9fe3ff"), "WIND": Color("#5ee39a"), "LIGHTNING": Color("#b78cff"), "EARTH": Color("#d9a35b"), "LIGHT": Color("#ffe27a"), "DARK": Color("#b072ff"), "CHAOS": Color("#ff5fb4")}
const ELEMENT_ICON := {"FIRE": "elem_fire", "WATER": "elem_water", "ICE": "elem_water", "WIND": "elem_wind", "LIGHTNING": "elem_lightning", "EARTH": "elem_earth", "LIGHT": "elem_light", "DARK": "elem_dark", "CHAOS": "elem_dark"}

## Skill targeting (Brown Dust style):
##   aim  : "front" = closest enemy in the attacker's row (falls back to nearest row)
##          "back"  = furthest enemy in that row, "lowest" = lowest HP% enemy
##          "ally_lowest" / "ally_all" / "self" for supports
##   shape: cells hit relative to the aimed cell
##          single, pierce (target + behind), line (whole row), column, cross,
##          square (2x2 toward back/down), x (diagonals), all
const SHAPES := ["single", "pierce", "line", "column", "cross", "square", "x", "all"]

const HEROES := {
	"fidelia": {"rarity": "R", "role": "PALADIN", "hp": 2600, "atk": 120, "def": 120,
		"skill": {"name": "Tidal Bulwark", "aim": "front", "shape": "single", "mult": 1.1, "shield_self": 0.25,
		"taunt": 2, "desc": "Strikes the front enemy for 110% ATK and shields herself for 25% Max HP. Taunts enemies for 2 rounds."}},
	"lucidria": {"rarity": "R", "role": "TANK", "hp": 2800, "atk": 110, "def": 130,
		"skill": {"name": "Ancient Mace Slam", "aim": "front", "shape": "pierce", "mult": 1.0, "stun": 0.35,
		"taunt": 1, "desc": "Smashes the front enemy and the one behind it for 100% ATK. 35% chance to Stun. Taunts enemies for 1 round."}},
	"eurnipha": {"rarity": "R", "role": "WARRIOR", "hp": 2000, "atk": 170, "def": 80,
		"skill": {"name": "Void Siphon", "aim": "front", "shape": "single", "mult": 1.5, "drain": 0.4,
		"desc": "Drains the front enemy for 150% ATK, healing 40% of the damage dealt."}},
	"rumi": {"rarity": "R", "role": "MAGE", "hp": 1400, "atk": 210, "def": 50,
		"skill": {"name": "Crimson Exorcism", "aim": "back", "shape": "single", "mult": 1.6, "execute": 0.8,
		"desc": "Hits the furthest enemy in her row for 160% ATK. +80% damage to targets under 35% HP."}},
	"mora": {"rarity": "R", "role": "MAGE", "hp": 1450, "atk": 180, "def": 55,
		"skill": {"name": "Chronos Ring", "aim": "front", "shape": "column", "mult": 0.8,
		"desc": "Strikes the whole column of the front enemy for 80% ATK."}},
	"furu": {"rarity": "SR", "role": "HEALER", "hp": 1700, "atk": 150, "def": 70,
		"skill": {"name": "Sacred Benediction", "aim": "ally_all", "shape": "all", "heal": 0.9,
		"cleanse": true, "desc": "Heals every ally for 90% ATK. Cleanses Burn, Stun, Silence and DEF/Heal debuffs."}},
	"glytta": {"rarity": "SR", "role": "WARRIOR", "hp": 2100, "atk": 190, "def": 85,
		"skill": {"name": "Crystal Waltz", "aim": "front", "shape": "line", "mult": 0.9,
		"desc": "Dances through the entire enemy row for 90% ATK."}},
	"hyeonxa": {"rarity": "SR", "role": "WARLOCK", "hp": 1600, "atk": 200, "def": 60,
		"skill": {"name": "Nine-Fang Venom", "aim": "front", "shape": "cross", "mult": 0.75, "burn": 0.3,
		"silence": 0.3, "desc": "Cross-shaped venom burst for 75% ATK. Poisons for 30% ATK each round (2 rounds). 30% chance to Silence."}},
	"scylla": {"rarity": "SR", "role": "ASSASSIN", "hp": 1500, "atk": 240, "def": 55,
		"skill": {"name": "Kraken Ambush", "aim": "back", "shape": "single", "mult": 1.9, "crit_bonus": 0.3,
		"desc": "Ambushes the furthest enemy in her row for 190% ATK. +30% Crit chance."}},
	"lumeira": {"rarity": "SR", "role": "BUFFER", "hp": 1550, "atk": 170, "def": 60,
		"skill": {"name": "Astral Wing Hymn", "aim": "front", "shape": "column", "mult": 0.6, "team_atk": 0.2,
		"desc": "Hits a column for 60% ATK and grants all allies +20% ATK for 2 rounds."}},
	"gemora": {"rarity": "SR", "role": "RANGER", "hp": 1500, "atk": 225, "def": 55,
		"skill": {"name": "Void Railgun", "aim": "front", "shape": "line", "mult": 1.0, "crit_bonus": 0.2,
		"desc": "Fires through the entire row for 100% ATK. +20% Crit chance."}},
	"shina": {"rarity": "SSR", "role": "WARRIOR", "hp": 2500, "atk": 260, "def": 100,
		"skill": {"name": "Dragonic Inferno", "aim": "front", "shape": "square", "mult": 1.3, "burn": 0.35,
		"desc": "Engulfs a 2x2 area for 130% ATK and Burns for 35% ATK each round (2 rounds)."}},
	"xylia": {"rarity": "SSR", "role": "WARLOCK", "hp": 1800, "atk": 300, "def": 70,
		"skill": {"name": "Pandemonium Blueprint", "aim": "front", "shape": "x", "mult": 1.5, "def_down": 0.25,
		"desc": "X-shaped demonic seal for 150% ATK. Reduces DEF by 25% for 2 rounds."}},
	"micca": {"rarity": "SSR", "role": "MAGE", "hp": 1700, "atk": 290, "def": 65,
		"skill": {"name": "Pandora Unboxed", "aim": "front", "shape": "all", "mult": 0.9, "stun": 0.2,
		"desc": "Unleashes chaos on ALL enemies for 90% ATK. 20% chance to Stun each."}},
	"cthollia": {"rarity": "SSR", "role": "WARLOCK", "hp": 2000, "atk": 270, "def": 80,
		"skill": {"name": "Abyssal Maelstrom", "aim": "front", "shape": "cross", "mult": 1.15, "stun": 0.25,
		"desc": "Cross-shaped maelstrom for 115% ATK. 25% chance to Freeze."}},
	"valeria": {"rarity": "SSR", "role": "KNIGHT", "hp": 3000, "atk": 220, "def": 150,
		"skill": {"name": "Frostvale Judgement", "aim": "front", "shape": "column", "mult": 1.0, "stun": 0.4, "shield_self": 0.2,
		"desc": "Freezes a whole column for 100% ATK (40% Freeze) and shields herself for 20% Max HP."}},
	"eropatra": {"rarity": "SSR", "role": "ASSASSIN", "hp": 1900, "atk": 310, "def": 70,
		"skill": {"name": "Serpent Empress Fang", "aim": "back", "shape": "pierce", "mult": 2.0, "burn": 0.3,
		"heal_block": 1, "desc": "Strikes the furthest enemy in her row (and behind) for 200% ATK, Burning for 2 rounds. Blocks healing for 2 rounds."}},
	# ---- November 2026 heroes
	"abadonia": {"rarity": "SSR", "role": "KNIGHT", "hp": 3100, "atk": 230, "def": 150,
		"skill": {"name": "Lion Sovereign's Charge", "aim": "front", "shape": "pierce", "mult": 1.3, "shield_self": 0.25, "stun": 0.2,
		"taunt": 2, "desc": "Rides through the front enemy and the one behind for 130% ATK (20% Stun) and gains a 25% Max HP shield. Taunts enemies for 2 rounds."}},
	"atalanta": {"rarity": "SSR", "role": "ASSASSIN", "hp": 1850, "atk": 305, "def": 65,
		"skill": {"name": "Thunderstep Dash", "aim": "back", "shape": "pierce", "mult": 1.9, "crit_bonus": 0.25,
		"desc": "Lightning-dashes to the furthest enemy in her row (and behind) for 190% ATK. +25% Crit chance."}},
	"kali": {"rarity": "SSR", "role": "WARRIOR", "hp": 2400, "atk": 270, "def": 95,
		"skill": {"name": "Hundred Blade Rain", "aim": "front", "shape": "line", "mult": 1.15, "def_down": 0.2,
		"desc": "A hundred swords rain on the whole row for 115% ATK and lower DEF by 20% for 2 rounds."}},
	"zennyo": {"rarity": "SSR", "role": "MAGE", "hp": 1900, "atk": 285, "def": 70,
		"skill": {"name": "Ryuo Dragon Parade", "aim": "front", "shape": "all", "mult": 0.95, "burn": 0.2,
		"desc": "Her dragon brood scorches ALL enemies for 95% ATK and Burns them for 2 rounds."}},
	"aqua": {"rarity": "SR", "role": "HEALER", "hp": 1750, "atk": 155, "def": 75,
		"skill": {"name": "Chalice of the Tides", "aim": "ally_all", "shape": "all", "heal": 1.0,
		"revive": 0.3, "cleanse": true, "desc": "Pours the holy chalice, healing every ally for 100% ATK. Once per battle, revives a fallen ally with 30% HP. Cleanses debuffs."}},
	"rubby": {"rarity": "SR", "role": "MAGE", "hp": 1500, "atk": 215, "def": 55,
		"skill": {"name": "Big Bang Ballad", "aim": "front", "shape": "square", "mult": 1.1, "burn": 0.25,
		"desc": "Throws her bomb friends at a 2x2 area for 110% ATK. Burns for 2 rounds."}},
	"schylua": {"rarity": "SR", "role": "WARRIOR", "hp": 2050, "atk": 200, "def": 85,
		"skill": {"name": "Glacial Reap", "aim": "front", "shape": "line", "mult": 0.95, "stun": 0.25,
		"heal_block": 1, "desc": "An ice scythe sweep across the whole row for 95% ATK. 25% chance to Freeze. Blocks healing for 2 rounds."}},
	"vexira": {"rarity": "SR", "role": "WARLOCK", "hp": 1600, "atk": 205, "def": 60,
		"skill": {"name": "Charm of Ruin", "aim": "front", "shape": "cross", "mult": 0.8, "def_down": 0.3,
		"silence": 0.4, "desc": "Cross-shaped imp swarm for 80% ATK. Charmed enemies lose 30% DEF for 2 rounds. 40% chance to Silence."}},
	"siv": {"rarity": "R", "role": "TANK", "hp": 2400, "atk": 140, "def": 125,
		"skill": {"name": "Thunder Tap", "aim": "front", "shape": "pierce", "mult": 1.0, "stun": 0.3,
		"desc": "A hammer strike through the front enemy and the one behind for 100% ATK. 30% chance to Stun."}},
	"sven": {"rarity": "R", "role": "WARRIOR", "hp": 2200, "atk": 165, "def": 95,
		"skill": {"name": "Rift Cleaver", "aim": "front", "shape": "column", "mult": 0.9,
		"desc": "A greatsword cleave down the whole column for 90% ATK."}},
	# ---- 4 November 2026 heroes
	"angela": {"rarity": "SSR", "role": "PALADIN", "hp": 3000, "atk": 230, "def": 145,
		"skill": {"name": "Seraph's Verdict", "aim": "front", "shape": "column", "mult": 1.2, "team_atk": 0.15, "taunt": 2,
		"desc": "Smites the front column with holy light for 120% ATK, raises ALL allies' ATK by 15% for 2 rounds and taunts enemies."}},
	"kara": {"rarity": "SSR", "role": "ASSASSIN", "hp": 1800, "atk": 320, "def": 60,
		"skill": {"name": "Phoenix Harvest", "aim": "back", "shape": "single", "mult": 2.2, "burn": 0.35, "crit_bonus": 0.2,
		"desc": "Twin scythes reap the furthest enemy for 220% ATK and set her ablaze (35% ATK burn). +20% Crit chance."}},
	"mei": {"rarity": "SSR", "role": "WARRIOR", "hp": 2500, "atk": 285, "def": 90,
		"skill": {"name": "Crimson Moon Slash", "aim": "front", "shape": "square", "mult": 1.35, "def_down": 0.25,
		"desc": "A blood-red katana arc hits a 2x2 area for 135% ATK and lowers their DEF by 25% for 2 rounds."}},
	"ninger": {"rarity": "SR", "role": "HEALER", "hp": 2000, "atk": 160, "def": 85,
		"skill": {"name": "Rain of Golden Fortune", "aim": "ally_all", "shape": "all", "heal": 0.75, "cleanse": true,
		"desc": "Showers every ally in lucky coins: heals 75% ATK and cleanses their debuffs."}},
	"luby": {"rarity": "SSR", "role": "ASSASSIN", "hp": 1900, "atk": 300, "def": 70,
		"skill": {"name": "Mecha-Cat Pounce", "aim": "back", "shape": "cross", "mult": 1.4, "stun": 0.25, "crit_bonus": 0.15,
		"desc": "Her mecha cat pounces on the furthest enemy in a cross for 140% ATK (25% Stun). +15% Crit chance."}},
	"spimei": {"rarity": "SR", "role": "RANGER", "hp": 1650, "atk": 240, "def": 60,
		"skill": {"name": "Scarlet Drone Swarm", "aim": "back", "shape": "all", "mult": 0.55, "burn": 0.15,
		"desc": "Her spider-drones strafe EVERY enemy for 55% ATK and leave them burning (15% ATK)."}},
}

const ENEMIES := {
	"slime": {"hp": 1800, "atk": 90, "def": 90, "role": "TANK",
		"skill": {"name": "Gel Crush", "aim": "front", "shape": "single", "mult": 1.0}},
	"ex_nymph": {"hp": 1100, "atk": 120, "def": 40, "role": "RANGER",
		"skill": {"name": "Thorn Volley", "aim": "front", "shape": "line", "mult": 0.7}},
	"slarkoi": {"hp": 2200, "atk": 100, "def": 120, "role": "TANK",
		"skill": {"name": "Mummy Wrap", "aim": "front", "shape": "pierce", "mult": 0.9, "stun": 0.2}},
	"gumi_wolf": {"hp": 1500, "atk": 150, "def": 70, "role": "WARRIOR",
		"skill": {"name": "Foxfire Pounce", "aim": "front", "shape": "cross", "mult": 0.8, "burn": 0.2}},
	"eroghost": {"hp": 1100, "atk": 170, "def": 40, "role": "ASSASSIN",
		"skill": {"name": "Phantom Rend", "aim": "back", "shape": "single", "mult": 1.5}},
	"evy_blood_sage": {"hp": 1200, "atk": 160, "def": 45, "role": "MAGE",
		"skill": {"name": "Blood Rite", "aim": "front", "shape": "column", "mult": 0.8, "drain": 0.3}},
	"ygg_naar": {"hp": 2500, "atk": 180, "def": 80, "role": "MAGE",
		"skill": {"name": "Primordial Gaze", "aim": "front", "shape": "all", "mult": 0.6, "stun": 0.15}},
	# ---- 4 November 2026 enemies
	"hairly": {"hp": 1500, "atk": 175, "def": 50, "role": "MAGE",
		"skill": {"name": "Shadow Tress Bind", "aim": "front", "shape": "cross", "mult": 0.9, "silence": 0.3}},
	"svormentis": {"hp": 2600, "atk": 125, "def": 130, "role": "TANK",
		"skill": {"name": "Devouring Maw", "aim": "front", "shape": "single", "mult": 1.25, "drain": 0.4}},
	"scomantis": {"hp": 1400, "atk": 185, "def": 55, "role": "ASSASSIN",
		"skill": {"name": "Emerald Sting", "aim": "back", "shape": "single", "mult": 1.5, "burn": 0.25}},
	"skelinch": {"hp": 1900, "atk": 170, "def": 80, "role": "WARRIOR",
		"skill": {"name": "Hellfire Gauntlets", "aim": "front", "shape": "pierce", "mult": 1.1, "burn": 0.2}},
	"serpentia": {"hp": 1700, "atk": 175, "def": 70, "role": "MAGE",
		"skill": {"name": "Flame-Scale Coil", "aim": "front", "shape": "square", "mult": 0.85, "burn": 0.15}},
	"voodoo": {"hp": 1300, "atk": 190, "def": 45, "role": "ASSASSIN",
		"skill": {"name": "Stitched Dance", "aim": "back", "shape": "single", "mult": 1.4, "def_down": 0.25}},
	"lizamorph": {"hp": 2800, "atk": 120, "def": 135, "role": "TANK",
		"skill": {"name": "Shadow Crawl", "aim": "front", "shape": "cross", "mult": 0.8, "silence": 0.25}},
	"ymir": {"hp": 2200, "atk": 165, "def": 100, "role": "WARRIOR",
		"skill": {"name": "Bone Throne Crush", "aim": "front", "shape": "column", "mult": 1.0, "stun": 0.2}},
}

const VOICE := {
	"greet": ["Commander, you're back! I was waiting for you.", "Ready for another adventure today?", "The Aether feels calm... for now."],
	"tap": ["H-hey! Don't poke me so suddenly!", "Hehe, do you need something?", "Stay focused, Commander.", "If you keep staring, I'll get shy..."],
	"bond": ["I feel stronger when I'm with you.", "Let's keep fighting side by side.", "You've become someone precious to me."],
	"oath": ["I swear my blade and heart to you, forever.", "This ring... I'll never take it off."],
	"win": ["Victory is ours!", "Was that all they had?", "Another page in our legend."],
}

## Hero-specific lobby lines (fallback to VOICE when missing).
const HERO_LINES := {
	"shina": "The dragon flame inside me burns for you alone, Commander.",
	"xylia": "Every empire needs an architect. I chose to build mine around you.",
	"micca": "Wanna peek inside my box? Hehe... maybe later~",
	"cthollia": "The abyss whispers your name. I told it to be quiet.",
	"valeria": "The frost never bothers me. Your absence does.",
	"eropatra": "Kneel? No, no... you may stand beside your Empress.",
	"furu": "May the light guide your every step, Commander.",
	"glytta": "Crystal steps, one, two... want to dance with me?",
	"hyeonxa": "Nine heads, and all of them think about you.",
	"scylla": "The tide brought me here. I'm choosing to stay.",
	"lumeira": "The butterflies say today will be a lucky day!",
	"gemora": "Signal locked. Target: Commander's heart.",
	"fidelia": "My shield is yours. Stand behind me.",
	"lucidria": "Ancient walls fall, but I won't.",
	"eurnipha": "Your warmth is... sweet. Let me stay close.",
	"rumi": "Exorcism complete. Now, where's my reward?",
	"mora": "Time slows down whenever you're near.",
	"abadonia": "Kneel before the Lion Queen... or ride beside her.",
	"atalanta": "Try to keep up, Commander! Ah, too slow~",
	"kali": "A hundred blades, one heart. Guess who it belongs to.",
	"zennyo": "My little dragons like you. That's rare.",
	"aqua": "Thirsty? The holy chalice is always full for you.",
	"rubby": "Careful, my friends here are a little... explosive.",
	"schylua": "The frost reaps all. Except you.",
	"vexira": "Ara~ Shall I steal your heart, or will you give it freely?",
	"siv": "Hammer ready! Wh-where should I hit?",
	"sven": "My sword has wandered far. It rests easier near you.",
	"angela": "The heavens sent me to guard you. ...I volunteered, actually.",
	"kara": "Death walks beside you, Commander. Lucky you — she likes you.",
	"mei": "Don't stare at the ears. Stare at the sword. It's sharper.",
	"ninger": "Every coin I own says you'll have a lucky day!",
	"spimei": "Drones online. Wings online. Heart... also online, unfortunately.",
	"luby": "Nya~! My mecha cat wants head pats. ...Fine, me too.",
}

const CHAPTERS := [
	{"name": "Whispering Woods", "bg": "forest", "pool": ["slime", "ex_nymph", "gumi_wolf"], "boss": "gumi_wolf",
		"mod": {"elem": "WIND", "atk": 0.15, "name": "Forest Breeze: WIND units +15% ATK"},
		"intro": [["mora", "Commander, the forest has grown restless. Monsters roam where children once played."], ["fidelia", "Then we clear a path. Stay behind my shield."]],
		"boss_lines": [["gumi_wolf", "Grrr... these woods belong to the Nine Tails!"], ["shina", "Then let my flames light them up!"]],
		"outro": [["shina", "The Nine Tails flee... the woods can breathe again."], ["mora", "But the corruption came from the sea. I can feel the tide turning dark."], ["furu", "Then our next path leads to the Sunken Reef, Commander."]],
		"mid": [["glytta", "Commander, look! Fox tracks... and they glow purple."], ["lucidria", "Corrupted beasts. Stay in formation."]]},
	{"name": "Sunken Reef", "bg": "aqua", "pool": ["slime", "slarkoi", "ex_nymph"], "boss": "slime",
		"mod": {"elem": "WATER", "atk": 0.15, "name": "Tidal Current: WATER units +15% ATK"},
		"intro": [["scylla", "The tide is wrong. Something is poisoning the reef."], ["hyeonxa", "Poison? Hmph. Amateurs."]],
		"boss_lines": [["slime", "Blub... BLUB! The Queen devours all!"], ["cthollia", "Let the abyss show you a real ocean."]],
		"outro": [["scylla", "The reef is clean. The Slime Queen won't poison anyone again."], ["cthollia", "Those were not ordinary monsters. Someone sent them... from a burning citadel."], ["eropatra", "Fire? How delightful. Lead the way, Commander."]],
		"mid": [["hyeonxa", "This poison... it isn't natural. Someone brewed it."], ["fidelia", "Then we find the brewer. Shields up!"]]},
	{"name": "Infernal Citadel", "bg": "hell", "pool": ["gumi_wolf", "eroghost", "evy_blood_sage"], "boss": "evy_blood_sage",
		"mod": {"elem": "FIRE", "atk": 0.15, "name": "Infernal Heat: FIRE units +15% ATK"},
		"intro": [["eropatra", "The citadel burns... a fitting stage for an Empress."], ["rumi", "Spirits everywhere. Time for some exorcism!"]],
		"boss_lines": [["evy_blood_sage", "Your blood will complete my ritual!"], ["eurnipha", "I'll be draining you first, sage."]],
		"outro": [["rumi", "The blood ritual is broken!"], ["eurnipha", "The sage spoke of a cold land where souls are frozen in place."], ["valeria", "Frostvale. My home. ...I was afraid this day would come."]],
		"mid": [["furu", "So many lost spirits here... I'll pray for them after the battle."], ["eurnipha", "Pray later, little priestess. They're coming."]]},
	{"name": "Frostvale Expanse", "bg": "ice", "pool": ["slarkoi", "eroghost", "gumi_wolf"], "boss": "eroghost",
		"mod": {"elem": "WATER", "def": 0.2, "name": "Permafrost: WATER units +20% DEF"},
		"intro": [["valeria", "Welcome to my homeland. Mind the cold, Commander."], ["glytta", "So pretty! Like dancing on crystal."]],
		"boss_lines": [["eroghost", "Hehehe... frozen souls taste the best."], ["valeria", "Then freeze, phantom."]],
		"outro": [["valeria", "The phantom is gone. Frostvale is free."], ["glytta", "Look! The northern lights are pointing at the sky... at a rift!"], ["gemora", "Signal confirmed. The Eclipse leaks through the Void Rift."]],
		"mid": [["scylla", "...The ice is cracking. Something moves beneath."], ["valeria", "My people's souls. Free them, Commander!"]]},
	{"name": "Void Rift", "bg": "galaxy", "pool": ["eroghost", "evy_blood_sage", "ygg_naar"], "boss": "ygg_naar",
		"mod": {"elem": "DARK", "atk": 0.15, "name": "Void Pressure: DARK units +15% ATK"},
		"intro": [["gemora", "Signal from beyond the rift... it's watching us."], ["lumeira", "The butterflies are scared. Let's be careful."]],
		"boss_lines": [["ygg_naar", "I AM THE EYE THAT SAW THE FIRST STAR."], ["micca", "Cool eye. I'm putting it in my box!"]],
		"outro": [["micca", "Hehe, one giant eye, safely boxed! ...mostly."], ["lumeira", "The butterflies say the true source is above us. In Asgard."], ["xylia", "Then we storm heaven itself. I've always wanted to redesign it."]],
		"mid": [["xylia", "The rift is unstable. One wrong step and we fall into nothing."], ["gemora", "Calculating safe path... Follow me."]]},
	{"name": "Celestial Asgard", "bg": "asgard", "pool": ["ygg_naar", "evy_blood_sage", "gumi_wolf", "eroghost"], "boss": "ygg_naar",
		"mod": {"elem": "LIGHT", "atk": 0.15, "name": "Divine Radiance: LIGHT units +15% ATK"},
		"intro": [["furu", "The gates of the celestial city... they're corrupted."], ["xylia", "Then we tear them down and rebuild. My specialty."]],
		"boss_lines": [["ygg_naar", "THE ECLIPSE CANNOT BE STOPPED."], ["shina", "Watch us, Commander. This ends now!"]],
		"outro": [["furu", "The Eclipse... is fading. Light returns to Euphoria."], ["shina", "We did it, Commander! Every one of us, together."], ["fidelia", "Our oath is fulfilled. But for you... we will keep fighting, always."]],
		"mid": [["mora", "Time flows strangely here. Yesterday and tomorrow overlap."], ["rumi", "Creepy! Double exorcism fee for this one!"]]},
	# ---- Arc 2: The Second Eclipse (corrupted heroes return as bosses)
	{"name": "Ashen Battlefield", "bg": "battle", "pool": ["gumi_wolf", "slarkoi", "evy_blood_sage", "eroghost"], "boss": "kali",
		"mod": {"elem": "WIND", "def": 0.2, "name": "Ash Storm: WIND units +20% DEF"},
		"intro": [["nar", "— ARC 2 —   THE SECOND ECLIPSE"], ["fidelia", "Commander... the sky is darkening again. A second Eclipse?"], ["shina", "No way. We ended it in Asgard!"], ["furu", "Something survived. And it's taking the shape of heroes."]],
		"mid": [["glytta", "These swords on the ground... they're Kali's!"], ["valeria", "Then she's been taken by the Eclipse. Stay sharp."]],
		"boss_lines": [["kali", "A hundred blades... for a hundred enemies. You are all enemies now."], ["fidelia", "Kali, wake up! We're your friends!"]],
		"outro": [["kali", "...Commander? My blades... I'm sorry. The darkness spoke in my voice."], ["furu", "You're free now. But the Eclipse is taking others."], ["kali", "Then my hundred blades are yours. Let's find them."]]},
	{"name": "Eclipse Citadel", "bg": "boss", "pool": ["ygg_naar", "eroghost", "evy_blood_sage", "slime"], "boss": "abadonia",
		"mod": {"elem": "DARK", "atk": 0.2, "name": "Black Sun: DARK units +20% ATK"},
		"intro": [["kali", "The citadel moved overnight. It's following the black sun."], ["xylia", "Impressive architecture. I hate it."]],
		"mid": [["rumi", "The walls are crying... no, those are spirits. Lots of them."], ["eurnipha", "The void is hungry here. Even I feel it."]],
		"boss_lines": [["abadonia", "Kneel before the Queen of the Second Eclipse."], ["valeria", "One queen to another — I refuse."]],
		"outro": [["abadonia", "My lion... he never stopped protecting me, even in the dark."], ["abadonia", "Commander. Abyssal Lion Queen Abadonia pledges her shield to you."], ["mora", "Two freed. The Eclipse's heart must be close."]]},
	{"name": "Shattered Continent", "bg": "world", "pool": ["gumi_wolf", "ygg_naar", "slarkoi", "ex_nymph"], "boss": "zennyo",
		"mod": {"elem": "FIRE", "atk": 0.2, "name": "Dragonfire Skies: FIRE units +20% ATK"},
		"intro": [["gemora", "The continent is splitting. Dragons in the sky — hundreds."], ["shina", "Dragons? ...Those are Zennyo's little ones!"]],
		"mid": [["atalanta", "I scouted ahead. She's on the highest peak, and she's not alone."], ["lumeira", "The butterflies won't fly there. Be careful~"]],
		"boss_lines": [["zennyo", "Father would be proud. I'll burn this world clean."], ["shina", "A dragon fighting a dragon? Fine, let's settle it!"]],
		"outro": [["zennyo", "...The little ones were crying. I couldn't hear them until now."], ["shina", "Welcome back, sis. Dragons stick together."], ["furu", "The source is above the clouds. The Fallen Cathedral."]]},
	{"name": "Fallen Cathedral", "bg": "lobby", "pool": ["ygg_naar", "evy_blood_sage", "eroghost", "gumi_wolf"], "boss": "vexira",
		"mod": {"elem": "LIGHT", "def": 0.25, "name": "Last Prayer: LIGHT units +25% DEF"},
		"intro": [["furu", "This was where I took my vows. Now it's... the Eclipse's heart."], ["fidelia", "Then we take it back. All of us."]],
		"mid": [["vexira", "Ara~ you came all this way to see me? How sweet."], ["eropatra", "That voice... Vexira was the first one taken. She's the core!"]],
		"boss_lines": [["vexira", "Love, desire, despair... I'll drink all of it. Starting with yours, Commander."], ["shina", "Everyone, together! This time we end it for real!"]],
		"outro": [["vexira", "...So warm. I forgot what being free felt like."], ["furu", "The second Eclipse is gone. I can see the stars again."], ["shina", "Commander. Whatever comes next — we'll face it with you. Promise."],
			["nar", "That night, every clock in the cathedral stopped at the same minute."], ["mora", "...No. Not yet. It's too early for this hour to come."]]},
	# ---- Arc 3: The Hour of Dawn (mirror heroes from a ruined future)
	{"name": "Frozen Tomorrow", "bg": "ice", "pool": ["eroghost", "slarkoi", "ex_nymph", "evy_blood_sage"], "boss": "valeria", "mirror": true, "boss_hp": 1.3,
		"mod": {"elem": "FIRE", "atk": 0.2, "name": "Last Embers: FIRE units +20% ATK"},
		"intro": [["nar", "— ARC 3 —   THE HOUR OF DAWN"], ["mora", "Commander. The clocks stopped because time itself has been cut open."],
			["valeria", "Frostvale again? ...No. This isn't my home. The snow here is black."],
			["mora", "This is Frostvale ten years from now. Something is pulling tomorrow into today."],
			["?", "valeria", ["We'll save this future too.", "Stay close to me, Valeria.", "Black snow? Cool and creepy."],
				["...Then I'll believe in it. For you.", "I— of course. Someone has to keep you warm.", "Hmph. Only you would say that here."], [40, 30, 15]]],
		"mid": [["scylla", "There are footprints in the ash. Heeled boots. A knight's stride."], ["valeria", "...Those are mine. I'd know them anywhere."]],
		"mid2": [["glytta", "Everyone in this village is frozen mid-dance. Like they stopped to listen to something."], ["mora", "To the last bell. In the future I come from... it rings for the Commander."], ["shina", "Mora? What do you mean, 'the future you come from'?"], ["mora", "...Later. She's here."]],
		"boss_lines": [["mirror:valeria", "So this is the past. Warm. Loud. Naive."], ["valeria", "You wear my face... but your eyes are empty."],
			["mirror:valeria", "They emptied the day our Commander fell. Step aside, girl. I'm here to change that day."]],
		"outro": [["mirror:valeria", "...You fight like someone who still has something to lose. I envy you."], ["valeria", "Then stay. Lose it with us, not alone."],
			["mirror:valeria", "I can't. The hourglass pulls me back. Ask Mora... why she brought us here."], ["nar", "The mirror shattered into snowflakes that fell upward."],
			["shina", "Mora. Talk. Now."], ["mora", "...The fire will tell you. The next fracture is in the Infernal Citadel."]]},
	{"name": "Burning Tomorrow", "bg": "hell", "pool": ["gumi_wolf", "evy_blood_sage", "slarkoi", "eroghost"], "boss": "eropatra", "mirror": true, "boss_hp": 6.5,
		"mod": {"elem": "WATER", "atk": 0.2, "name": "Rain of Ash: WATER units +20% ATK"},
		"intro": [["eropatra", "My citadel... ruined, rebuilt, and ruined again. How tiresome."], ["mora", "In ten years it becomes a throne. And the one sitting on it is you, Eropatra."],
			["eropatra", "A throne? Well. At least my future self has taste."], ["cthollia", "...Then why does the throne room smell like grief?"]],
		"mid": [["rumi", "These spirits aren't monsters. They're soldiers. Our soldiers, from the future."], ["hyeonxa", "Then the war we're heading toward is already lost... somewhere."]],
		"mid2": [["mora", "Commander, I owe you the truth. In my time, the Eclipse returns a third time."], ["mora", "You lead us. You win. And you do not come back."],
			["fidelia", "...Say that again."], ["mora", "The heroes of my time broke. Some became tyrants. Some became ghosts. And I... opened the hourglass."],
			["?", "mora", ["You did it to save me.", "You should have told us.", "Whatever happens, I'm not angry."],
				["...Yes. Every single time.", "I know. I was afraid you'd stop me.", "Commander... that's the cruelest kindness."], [40, 15, 30]]],
		"boss_lines": [["mirror:eropatra", "Kneel, little Empress. I rule the ashes now."], ["eropatra", "I kneel to no one. Least of all to a sadder me."],
			["mirror:eropatra", "Sadder? I built a kingdom so no one could ever take what I love again!"], ["eropatra", "And yet you're alone on your throne. Commander — let's end her loneliness."]],
		"outro": [["mirror:eropatra", "Gold, perfume, a whole empire... none of it brought him back."], ["eropatra", "Then I'll keep him here. In this time. You have my word, Empress to Empress."],
			["nar", "The citadel's fires went quiet, one by one."], ["mora", "Two fractures closed. The last mirror waits at the gates of Asgard."], ["fidelia", "...I already know whose face she'll wear."]]},
	{"name": "The Last Bastion", "bg": "asgard", "pool": ["ygg_naar", "eroghost", "gumi_wolf", "evy_blood_sage"], "boss": "fidelia", "mirror": true, "boss_hp": 1.8,
		"mod": {"elem": "LIGHT", "def": 0.25, "name": "Oathbound Wall: LIGHT units +25% DEF"},
		"intro": [["fidelia", "Commander. Whatever she says to me up there... don't look away from me."], ["shina", "We've got your back, shield-head. Always."],
			["?", "fidelia", ["I'll never look away.", "You're not her, Fidelia.", "Let me carry the shield this time."],
				["...Thank you. That's all I needed.", "Not yet. Help me stay that way.", "Absolutely not. ...But I'm glad you offered."], [40, 30, 20]]],
		"mid": [["lucidria", "The gates are covered in shields. Hundreds. All cracked down the middle."], ["fidelia", "...One for every time she failed. I can feel it."]],
		"mid2": [["kali", "My blades are trembling. Something up there is stronger than the Eclipse."], ["abadonia", "My lion won't go further. He's... bowing?"], ["fidelia", "Because she's a knight. Even broken, she's still a knight."]],
		"boss_lines": [["mirror:fidelia", "Turn back. I held this gate for ten years. No one passes. Not even you."], ["fidelia", "What happened to you?"],
			["mirror:fidelia", "I stood in front of him, and it wasn't enough. Do you know how heavy a shield gets when it's useless?"],
			["fidelia", "...Then lean on mine. Commander, give the order!"]],
		"outro": [["mirror:fidelia", "...You're stronger than I was. Because you're not standing alone."], ["fidelia", "Neither are you. Not anymore."],
			["mirror:fidelia", "The Hour of Dawn. Mora's hourglass. If she turns it once more, the timelines collapse. Stop her — and forgive her."],
			["nar", "Above Asgard, the stars began to run backwards."]]},
	{"name": "The Hour of Dawn", "bg": "galaxy", "pool": ["ygg_naar", "eroghost", "evy_blood_sage", "slime", "gumi_wolf"], "boss": "mora", "mirror": true, "boss_hp": 9.0,
		"mod": {"elem": "LIGHT", "atk": 0.2, "name": "First Light: LIGHT units +20% ATK"},
		"intro": [["mora", "Commander... she's waiting. The me who turned the hourglass a thousand times."], ["mora", "If I go alone, I'll listen to her. I always do."],
			["?", "mora", ["You won't go alone.", "Then don't listen. Listen to me.", "Let's write a new ending together."],
				["...Okay. Hold on to my hand, then.", "Your voice... is louder than hers. It always was.", "A new ending. I like that very much."], [30, 30, 40]]],
		"mid": [["gemora", "Temporal readings are off the scale. Yesterday, today and tomorrow are in the same room."], ["micca", "Can I put a day in my box? Just a small one?"]],
		"mid2": [["shina", "Everyone's here. Every hero we freed. Kali, Abadonia, Zennyo, Vexira..."], ["vexira", "Ara~ did you think we'd miss the finale?"],
			["zennyo", "The little dragons wanted to see the Commander win."], ["mora", "...So this is what was missing in my time. All of you, together."]],
		"boss_lines": [["mirror:mora", "One more turn. Just one more, and he lives. Why won't you let me?"], ["mora", "Because every turn breaks someone else. Valeria. Eropatra. Fidelia. You."],
			["mirror:mora", "I don't care! I'd break every timeline for one more morning with him!"], ["commander", "Then spend that morning here. With us. Put the hourglass down, Mora."],
			["mirror:mora", "...If you want me to stop, you'll have to win. Like you always do."]],
		"outro": [["nar", "The hourglass cracked. Sand that had fallen for ten thousand years finally came to rest."],
			["mirror:mora", "...It's quiet. I forgot that time could be quiet."], ["mora", "Stay with us. There's room in this timeline. I'll make sure of it."],
			["mirror:mora", "No. I belong to my morning. But now I know it can end differently. Thank you, Commander."],
			["fidelia", "Commander. In the future she came from, you didn't come back. In ours... you will. That's an order from your shield."],
			["shina", "And from your dragon! You're stuck with all of us, forever."], ["mora", "Then let's go home. The clocks are ticking again."],
			["nar", "— END OF ARC 3 —   Euphoria's story will continue..."]]},
	# ---- Arc 4: The Last Light (the third Eclipse — Noctis, the Hollow Star)
	{"name": "Hollow Tide", "bg": "aqua", "pool": ["slime", "slarkoi", "eroghost", "evy_blood_sage"], "boss": "cthollia", "variant": "hollow", "mirror": true, "boss_hp": 3.0,
		"mod": {"elem": "EARTH", "atk": 0.2, "name": "Silent Sea: EARTH units +20% ATK"},
		"intro": [["nar", "— ARC 4 —   THE LAST LIGHT"], ["nar", "Three weeks after the hourglass broke, the sea stopped making sound."],
			["scylla", "Commander. The tide comes in. The tide goes out. But there is no sound at all."], ["mora", "...This is it. The third Eclipse. The one from my future."],
			["fidelia", "Then we already know how this ends. And we're going to end it differently."],
			["?", "mora", ["Together, this time.", "I'm not going anywhere, Mora.", "Tell me everything you know."],
				["Together. ...I'll hold you to that.", "Promise me. Out loud. Every morning.", "It hollows people out. It starts with the ones who love the deepest."], [40, 30, 20]]],
		"mid": [["hyeonxa", "These monsters are empty inside. No poison, no blood. Just... nothing."], ["rumi", "No spirits either. Something ate them."]],
		"mid2": [["scylla", "Cthollia went down to the reef to listen for the tide. She hasn't come back."], ["abadonia", "My lion smells her. Below us. And she's... singing."],
			["nar", "From the deep came a lullaby with no voice in it."]],
		"boss_lines": [["hollow:cthollia", "Shhh. Don't you hear it? The quiet. It's so much kinder than the waves."],
			["scylla", "Cthollia, the sea was never quiet with you. You were its loudest song."],
			["hollow:cthollia", "Then let me be quiet. Let all of you be quiet. The Star promised..."], ["fidelia", "Commander — bring her back!"]],
		"outro": [["cthollia", "...The tide. I can hear the tide again. Commander, I— something was inside me. Something cold and lonely."],
			["cthollia", "It whispered a name before it left. Noctis. The Hollow Star."], ["gemora", "Searching... There is a dead star above Euphoria. It was not there yesterday."],
			["mora", "In my future we never learned its name. We already know more than they did."]]},
	{"name": "Hollow Garden", "bg": "forest", "pool": ["ex_nymph", "gumi_wolf", "scomantis", "slime"], "boss": "eurnipha", "variant": "hollow", "mirror": true, "boss_hp": 6.0,
		"mod": {"elem": "WIND", "atk": 0.2, "name": "Withered Wind: WIND units +20% ATK"},
		"intro": [["glytta", "The Whispering Woods... the leaves are grey. Even the fox spirits went quiet."], ["lumeira", "The butterflies won't fly. They're just... sitting there. Waiting."],
			["eurnipha", "I'll go ahead. Warmth is my specialty. If anything's cold here, I'll hug it until it isn't."],
			["?", "eurnipha", ["Don't go alone.", "Your warmth is exactly what it wants.", "Then hug me first. For luck."],
				["...Fine. Walk with me, then.", "Hmm. You're scary when you're right.", "Ara. Commander, in front of everyone?"], [30, 20, 40]]],
		"mid": [["micca", "I put a grey leaf in my box. It made the box cold. I took it out. I'm scared, Commander."], ["kali", "Stay behind my blades, little one."]],
		"mid2": [["nar", "In the heart of the garden, every flower faced the same direction: upward, toward a star that gave no light."],
			["lucidria", "It's pulling the life out of everything. Like a flower that's forgotten the sun."], ["fidelia", "Where is Eurnipha?"], ["hollow:eurnipha", "Here. I'm right here. Isn't it peaceful?"]],
		"boss_lines": [["hollow:eurnipha", "I finally understand, Commander. Noctis is so cold. So alone. It just wants to be held."],
			["hollow:eurnipha", "So I'm giving it everything. My warmth. Yours too, if you'll let me."], ["lumeira", "That isn't a hug, Eurnipha. That's drowning."],
			["commander", "Eurnipha. Come back and hug me instead. I'm right here."]],
		"outro": [["eurnipha", "...Commander? Why are you crying? Oh. Oh, I see. I'm sorry. I'm here now."],
			["eurnipha", "I saw it. Noctis. It's a star that died alone, a long time ago. It doesn't hate us. It's just so cold it can't tell warmth from hunger."],
			["furu", "Then maybe... it can't be destroyed. Only answered."], ["xylia", "...Commander. I'm going to say something you won't like."],
			["xylia", "A star that high needs a tower to reach. And I've been dreaming of blueprints I never drew."]]},
	{"name": "Architect of Ruin", "bg": "boss", "pool": ["ygg_naar", "evy_blood_sage", "eroghost", "slarkoi", "gumi_wolf"], "boss": "xylia", "variant": "hollow", "mirror": true, "boss_hp": 2.6,
		"mod": {"elem": "DARK", "def": 0.25, "name": "Black Scaffold: DARK units +25% DEF"},
		"intro": [["nar", "Overnight, a tower rose from the Eclipse Citadel. It was still growing at dawn."],
			["valeria", "Xylia's gone. Her room is full of drawings. All of the same tower."], ["eropatra", "She's building a staircase to that star. Of course she is."],
			["mora", "In my future, the tower already stood. We never climbed it in time."]],
		"mid": [["atalanta", "I ran the outer stairs. Ten thousand steps and it's still going up."], ["siv", "Then let's knock the stairs down! I-I mean... after we save her!"]],
		"mid2": [["vexira", "Ara~ the tower is made of dreams. Hers. I can taste them."], ["vexira", "She dreamed of building something that would last forever, so no one she loves would ever be lost again."],
			["zennyo", "The little dragons can fly us to the top. Hold on tight."], ["shina", "Hey, sis. Let's go bring the architect home."]],
		"boss_lines": [["hollow:xylia", "Commander. Do you like it? A tower that reaches the sky. No one will ever be left behind again."],
			["hollow:xylia", "Noctis showed me. Once it's finished, every bond will be preserved. Frozen. Perfect. Forever."],
			["shina", "That's not a home, Xylia! A home is where people get to change and grow and argue about breakfast!"],
			["hollow:xylia", "...Breakfast. You always burned the eggs, Shina."], ["shina", "And you always redesigned the kitchen after! Come back and redesign it again!"]],
		"outro": [["xylia", "...My head hurts. Did I build that? It's hideous. Structurally sound. But hideous."], ["shina", "Welcome back, architect."],
			["nar", "Then the top of the tower opened, and the dead star leaned down to look at them."],
			["mirror:mora", "Commander. Listen. This is the moment from my future. The moment you went up alone."],
			["mora", "You came back...?"], ["mirror:mora", "Only my voice, through the cracks in the hourglass. Don't go alone. That's all. Don't go alone."]]},
	{"name": "The Last Light", "bg": "lobby", "pool": ["ygg_naar", "eroghost", "evy_blood_sage", "gumi_wolf", "slime", "slarkoi"], "boss": "shina", "variant": "hollow", "mirror": true, "boss_hp": 5.0, "boss_atk": 0.6,
		"mod": {"elem": "LIGHT", "atk": 0.25, "name": "Twenty-Seven Lights: LIGHT units +25% ATK"},
		"intro": [["nar", "Noctis descended on the one place that still felt like home: the cathedral."], ["fidelia", "Commander, stay behind me. This time I won't—"],
			["nar", "Before she could finish, the star reached past every shield and took the warmest light in the room."], ["furu", "SHINA!"],
			["?", "fidelia", ["We go together. All of us.", "I'm going after her.", "Fidelia — protect everyone. I'll lead."],
				["...Together. Yes. That's how we win.", "Not alone, Commander. Never alone. Remember?", "Then I'll protect you while you lead. That's my oath."], [40, 10, 30]]],
		"mid": [["kali", "A hundred blades. Every one of them for her."], ["abadonia", "My lion and I go first. We owe her a battle."], ["vexira", "Ara~ the little dragon owes ME an apology. She has to come back for that."]],
		"mid2": [["nar", "Every hero the Commander had ever freed stood in the nave. Twenty-seven lights against one cold star."],
			["mora", "Commander. In my future, you went up there alone and gave Noctis your warmth. And it was enough to stop it. And you were gone."],
			["mora", "Not this time. This time we give it ours. All of ours. Together."], ["zennyo", "Big sister's in there. The little dragons are all crying. Let's go."]],
		"boss_lines": [["hollow:shina", "...Commander. It's so cold in here. It's been cold for ten thousand years."],
			["hollow:shina", "It doesn't want to hurt anyone. It just wants someone to stay. Can I stay with it? Someone should."],
			["commander", "Then we'll all stay. Every one of us. Noctis, you don't have to be alone anymore."], ["hollow:shina", "Then... prove it. Show it how warm you are."]],
		"outro": [["nar", "Twenty-seven lights burned at once. Not to destroy the star — to warm it."],
			["nar", "For the first time in ten thousand years, Noctis felt warm. And a dead star began, very slowly, to shine."],
			["shina", "...Commander? Hah. I'm okay. I'm actually okay. Your hand is shaking, you know."],
			["shina", "It said thank you. Before it went back up. It said it'll watch over us now. It's a little embarrassing, honestly."],
			["mora", "...Commander. Look at the hourglass."], ["nar", "The broken hourglass was full again. And on the sand, written in a familiar hand: 'You came home. Thank you.'"],
			["mora", "That future is gone. You're here. You're actually here."], ["fidelia", "Our oath stands. Today, tomorrow, and every tomorrow after that."],
			["shina", "Okay, everyone! Breakfast at the cathedral! Xylia, don't redesign the kitchen until AFTER we eat!"],
			["nar", "— END OF ARC 4: THE LAST LIGHT —   Thank you for playing, Commander. Euphoria's sky has one more star now."]]},
	# ---- Arc 5: The Starbound Expedition (astral beasts guarding dying stars)
	{"name": "Starport Horizon", "bg": "space", "pool": ["slime", "ex_nymph", "eroghost", "gumi_wolf"], "boss": "slarkoi", "variant": "astral", "mirror": true, "boss_hp": 4.8, "boss_atk": 1.8,
		"mod": {"elem": "WIND", "atk": 0.2, "name": "Ion Storm: WIND/LIGHTNING units +20% ATK"},
		"intro": [["nar", "— ARC 5 —   THE STARBOUND EXPEDITION"], ["nar", "A month after Noctis began to shine, its light started to blink. Three short. Three long. Three short."],
			["gemora", "It is a distress signal, Commander. Noctis is relaying it. Other stars are dying — far beyond Euphoria."],
			["xylia", "Which is why I repurposed the tower. It's a starport now. Structurally sound. And far less hideous."],
			["shina", "We're going to SPACE? Commander, say yes. Say yes say yes say yes."],
			["?", "gemora", ["Plot the course, Gemora.", "Everyone comes home. That's the rule.", "Space! Obviously yes."],
				["Course plotted. Estimated wonder: maximum.", "Rule recorded. Priority one. Always.", "Shina's enthusiasm has been... confirmed contagious."], [30, 40, 20]]],
		"mid": [["atalanta", "Something stowed away on the launch platform. Something BIG."], ["siv", "I'll hit it! W-with the hammer! Where's the hammer?!"]],
		"mid2": [["xylia", "That thing is chewing on my starport. My beautiful, load-bearing starport."], ["abadonia", "Then my lion and I will remove it. Politely. With teeth."],
			["nar", "Across the docks, a behemoth wrapped in starlight lifted its head and roared without sound."]],
		"boss_lines": [["nar", "The Starport Behemoth had followed the signal too — drawn to light, like every creature in the dark."],
			["fidelia", "It's not evil. It's hungry. Commander, we drive it off the platform — don't let it reach the engines!"]],
		"outro": [["gemora", "Behemoth retreating. Launch window open. Engines... engaged."], ["nar", "And the starport tore free of Euphoria's sky, carrying twenty-seven lights toward the stars."],
			["lumeira", "Look, Commander! The butterflies are floating! Everything is floating!"], ["mora", "First stop: a planet whose star is going grey. They call it Mycelia."]]},
	{"name": "Mycelia, the Spore World", "bg": "alien", "pool": ["ex_nymph", "slime", "gumi_wolf", "evy_blood_sage"], "boss": "ex_nymph", "variant": "astral", "mirror": true, "boss_hp": 16.0, "boss_atk": 2.4,
		"mod": {"elem": "EARTH", "atk": 0.2, "name": "Spore Bloom: EARTH units +20% ATK"},
		"intro": [["glytta", "The ground is GLOWING. And soft. Like dancing on a cloud made of mushrooms!"], ["hyeonxa", "Do not touch anything. Do not eat anything. Especially you, Micca."],
			["micca", "...I already put one in my box."], ["lumeira", "The butterflies hear something. The spores are... talking. They're scared of us."]],
		"mid": [["furu", "Their sun is dim, Commander. Grey. The whole planet is holding its breath."], ["cthollia", "Like the sea before Noctis. A silence that hurts."]],
		"mid2": [["lumeira", "Let me try. The butterflies can carry words... if I dream them hard enough."],
			["?", "lumeira", ["I'll hold your hand while you dream.", "Be careful, Lumeira.", "Tell them we brought a friend's light."],
				["Then I'll dream the nicest dream I can~", "I will. You'll wake me up if it goes bad?", "Noctis' light... yes. They'll understand that."], [40, 20, 30]],
			["nar", "The spores answered with a single image: a crown of colour, and a queen who would not let strangers near her dying sun."]],
		"boss_lines": [["nar", "The Spore Queen rose from the glowing field, her petals sharp as glass."],
			["lumeira", "She thinks we came to take the last of their light. Commander — we have to show her we can give it, not take it!"]],
		"outro": [["lumeira", "She's listening now. The butterflies told her everything. About Noctis. About us."],
			["nar", "The Spore Queen bowed, and from her crown she offered a single seed, pulsing with green fire."],
			["gemora", "Analysis: the seed is alive. And it is pointing. Toward the black hole at the centre of this system."],
			["mora", "...All the light from these dying stars is falling into it. Something is drinking the stars."]]},
	{"name": "Event Horizon", "bg": "blackhole", "pool": ["eroghost", "evy_blood_sage", "ygg_naar", "slime"], "boss": "eroghost", "variant": "astral", "mirror": true, "boss_hp": 4.5,
		"mod": {"elem": "LIGHT", "def": 0.25, "name": "Gravity Well: LIGHT units +25% DEF"},
		"intro": [["mora", "Commander... my hourglass is spinning. Time bends here. Hold on to something. Hold on to me."],
			["valeria", "The ice in my sword is falling sideways. That's not normal."], ["scylla", "We're standing on a stone floating over nothing. Lovely."]],
		"mid": [["rumi", "Spirits! Thousands! They're made of... starlight? Exorcism fee is going to be astronomical."], ["eropatra", "Ha. I'll pay it. Get them away from my Commander."]],
		"mid2": [["nar", "At the edge of the horizon, time folded. For a moment, every hero saw a reflection of themselves — Mirror, Hollow, and true — standing side by side."],
			["mora", "I see her. The other me. She's... waving. She's smiling, Commander."],
			["?", "mora", ["Wave back. Together.", "She's happy now. Because of you.", "We'll visit her someday."],
				["...Together. Yes. She'd like that.", "Because of us. You never let me take credit alone.", "Time is a slow postman... but someday."], [40, 30, 20]]],
		"boss_lines": [["nar", "From the swirling light rose a wraith woven out of everything the black hole had swallowed."],
			["kali", "It's wearing stolen starlight like armour. A hundred blades — let's give it back!"]],
		"outro": [["nar", "The wraith unravelled, and the stolen light streamed out — not into the hole, but past it."],
			["gemora", "The light is flowing outward now. Toward... a tree? There is a tree on the far side of the black hole. Size: incalculable."],
			["lucidria", "...I know that tree. Every flower I ever pressed came from its seeds. Yggdrasil. The World Tree."],
			["shina", "Hang on. 'Ygg'? As in Ygg-Naar? The giant eye from Chapter Five?!"], ["fidelia", "...We are going to have to have a talk with that eye."]]},
	{"name": "Crown of Yggdrasil", "bg": "bigtree", "pool": ["gumi_wolf", "ex_nymph", "slarkoi", "ygg_naar", "eroghost"], "boss": "ygg_naar", "variant": "astral", "mirror": true, "boss_hp": 4.0, "boss_atk": 0.9,
		"mod": {"elem": "WATER", "atk": 0.25, "name": "Canopy Rain: WATER units +25% ATK"},
		"intro": [["nar", "The World Tree grew between stars. Its branches held whole villages. Its roots drank light from a hundred suns."],
			["lucidria", "It's dying. The leaves are gold because they're starving, not because they're beautiful."],
			["zennyo", "The little dragons found a door in the bark. And an eye. A very, very big eye."]],
		"mid": [["sven", "Old roads up here. Walked by no one for ten thousand years."], ["atalanta", "Then let's be the first. Race you to the crown!"]],
		"mid2": [["ygg_naar", "...YOU. THE ONES WHO BOXED ME. THE ONES WHO WARMED THE HOLLOW STAR."], ["micca", "Hi! You were very comfy in the box!"],
			["ygg_naar", "I AM THE EYE OF YGGDRASIL. I SAW THE FIRST STAR. I WATCHED IT DIE. AND THE TREE BEGAN TO STARVE."],
			["ygg_naar", "SO I DRANK THE OTHER STARS. ONE BY ONE. TO KEEP THE TREE ALIVE. WOULD YOU NOT DO THE SAME, FOR WHAT YOU LOVE?"],
			["?", "lucidria", ["There's another way.", "We'll give it a new star.", "Not by stealing. Never by stealing."],
				["...Yes. A gardener doesn't starve one flower to feed another.", "Noctis' light, Mycelia's seed... it might be enough.", "Then let us show the Eye. Together."], [30, 40, 30]]],
		"boss_lines": [["ygg_naar", "THEN SHOW ME. SHOW ME A LIGHT THAT DOES NOT HAVE TO BE TAKEN."],
			["shina", "Everyone! This one isn't about winning. It's about giving!"], ["commander", "Noctis — lend us your light. One more time."]],
		"outro": [["nar", "Twenty-seven lights, a seed from Mycelia, and a star that had learned what warmth meant — all of it poured into the crown of the World Tree."],
			["nar", "And at the top of Yggdrasil, where a dead star had hung for ten thousand years, a new sun opened its eyes."],
			["ygg_naar", "...I SEE IT. I SAW THE FIRST STAR. NOW I SEE THE NEXT ONE."], ["ygg_naar", "THANK YOU, COMMANDER. THE OTHER STARS ARE FREE. I WILL WATCH OVER THEM NOW. ALL OF THEM."],
			["lucidria", "The leaves are turning green. Commander... I'm going to press so many flowers."],
			["shina", "Okay! Expedition complete! Who wants to go home and NOT go to space for at least a week?!"],
			["xylia", "I already redesigned the starport into a holiday resort. There is a pool. You're welcome."],
			["nar", "— END OF ARC 5: THE STARBOUND EXPEDITION —   The stars are shining again. Thank you, Commander."]]},
	# ---- Arc 6: Echoes of the First Oath (who the Commander really is)
	{"name": "Ruins of the First Oath", "bg": "world", "pool": ["gumi_wolf", "slarkoi", "ex_nymph", "eroghost"], "boss": "sven", "variant": "echo", "mirror": true, "boss_hp": 3.5, "boss_atk": 1.6,
		"mod": {"elem": "EARTH", "def": 0.25, "name": "Ancient Stone: EARTH units +25% DEF"},
		"intro": [["nar", "— ARC 6 —   ECHOES OF THE FIRST OATH"], ["nar", "Before it closed its great eye, Ygg-Naar left the Commander one last gift: a memory, a thousand years old."],
			["ygg_naar", "COMMANDER. BEFORE YOU, THERE WAS ANOTHER. THE FIRST COMMANDER. THE FIRST OATH. LOOK."],
			["nar", "A cathedral that did not exist yet. Twenty-seven heroes kneeling in a circle. And at the centre — a face the Commander knew from every mirror."],
			["shina", "Commander... that's YOU. Older. With a scar. But that's you."],
			["?", "shina", ["...That can't be me.", "Then who were all of you?", "Whatever I was, I'm here now."],
				["It's you. I'd know that stupid face anywhere.", "...I don't know. But my heart's beating really fast.", "Yeah. That's the you I like."], [20, 30, 40]]],
		"mid": [["sven", "These roads... I know them. I've walked them before. Long before I was born."], ["lucidria", "...So have I, Sven. So have I."]],
		"mid2": [["nar", "In the ruined plaza stood a knight made of old light, gripping a sword the Commander had seen in the memory."],
			["sven", "That's... my sword. That's me. A thousand years ago."], ["mora", "An Echo. A past life, still bound to an oath that never ended."]],
		"boss_lines": [["echo:sven", "Halt. The First Commander ordered this road sealed until the Oath is fulfilled. None pass."],
			["sven", "...You're tired. I can see it. A thousand years of standing guard."],
			["echo:sven", "Tired does not matter. Orders matter. Unless... my Commander orders otherwise."],
			["commander", "Then I'm ordering you to rest. Let's see if I'm still your Commander."]],
		"outro": [["echo:sven", "...That voice. Yes. It's you. Thank you, my Commander. The road is yours."],
			["nar", "The Echo knelt, smiled at Sven, and faded into motes of old gold — which drifted into Sven's chest and stayed there."],
			["sven", "...I remember a campfire. And you, laughing. A thousand years ago."],
			["lucidria", "Commander. I owe you the truth, and I am afraid of it. But not here. At the Archive. Please."]]},
	{"name": "The Drowned Archive", "bg": "aqua", "pool": ["slime", "slarkoi", "evy_blood_sage", "ex_nymph"], "boss": "hyeonxa", "variant": "echo", "mirror": true, "boss_hp": 7.0, "boss_atk": 1.6,
		"mod": {"elem": "WATER", "atk": 0.25, "name": "Sunken Memory: WATER units +25% ATK"},
		"intro": [["scylla", "Beneath the reef there's a library. The fish swim between the shelves like they're reading."],
			["lucidria", "The Archive of the First Oath. Every hero's name was written here. Every hero but one was reborn."],
			["hyeonxa", "...'Every hero but one.' You mean you, don't you, Lucidria."]],
		"mid": [["gemora", "These books are written in a language I was programmed to read. Interesting. Unsettling."], ["eurnipha", "Don't read anything sad out loud. I'm not ready."]],
		"mid2": [["lucidria", "I was there, Commander. At the First Oath. I never died, so I was never reborn. I just... waited."],
			["lucidria", "A thousand years of old ruins and pressed flowers, waiting for the day the Commander came back. And then you did. And you didn't remember me."],
			["?", "lucidria", ["I'm sorry I forgot.", "I remember you now.", "Then let's make new memories."],
				["Don't be. You came back. That was always enough.", "...You're lying. But it's the kindest lie anyone has ever told me.", "New ones... Yes. I'd like that more than anything."], [30, 20, 40]]],
		"boss_lines": [["echo:hyeonxa", "Intruders in the Archive. The records of the First Oath are sealed. I sealed them myself."],
			["hyeonxa", "And I'm unsealing them. Move, past me. You were always too proud."], ["echo:hyeonxa", "...So were you, apparently."]],
		"outro": [["echo:hyeonxa", "Read it, then. The last page. Read what the First Commander promised."],
			["nar", "The last page held a single line, in a hand the Commander's own hand recognised: 'I will come back. And next time, I will not make you wait alone.'"],
			["lucidria", "...You promised that. A thousand years ago. To me."],
			["mora", "Then the Oath isn't finished. It's waiting for the second half. At the Forge where the first rings were made."]]},
	{"name": "The Forge of Oaths", "bg": "hell", "pool": ["gumi_wolf", "evy_blood_sage", "slarkoi", "eroghost"], "boss": "siv", "variant": "echo", "mirror": true, "boss_hp": 7.5, "boss_atk": 1.8,
		"mod": {"elem": "FIRE", "atk": 0.25, "name": "Forge Heat: FIRE units +25% ATK"},
		"intro": [["siv", "A forge! A really, REALLY big forge! Commander, my hands are tingling. Is that normal?"],
			["abadonia", "My lion is nervous. He doesn't get nervous."], ["fidelia", "Every Oath Ring we've ever worn was made here, wasn't it?"]],
		"mid": [["rubby", "The fire here doesn't burn. It hums. Like it's singing."], ["xylia", "Structural analysis: this forge is older than the cathedral. Older than anything."]],
		"mid2": [["siv", "...I remember this hammer. I made the rings. Twenty-seven of them. And one more, for the Commander."],
			["siv", "But I never got to give the last one. The Eclipse came first. I-I'm sorry I was too slow."],
			["?", "siv", ["You weren't slow. You were brave.", "Let's finish it together.", "I'll wait as long as you need."],
				["B-brave? Me? ...Hehe. Okay. Okay!", "Together! Right! Hammer ready!", "No more waiting. I'll finish it now!"], [40, 40, 20]]],
		"boss_lines": [["echo:siv", "The forge is closed. The last ring was never finished. It must never be finished, or the seal breaks."],
			["siv", "The seal is ALREADY breaking! Because nobody finished it! Let me through, past me!"],
			["echo:siv", "...You were always louder than me. Fine. Prove your hammer is stronger."]],
		"outro": [["nar", "Echo and girl struck the anvil together. Once. The sound rang through a thousand years."],
			["siv", "It's done. The last ring. Commander, this one's yours. It was always yours."],
			["echo:siv", "...Thank you. I can rest now. Go to the First Cathedral. She's waiting. She's always been waiting."],
			["lucidria", "...Then let me go first. There is someone there I need to face. Me."]]},
	{"name": "The First Cathedral", "bg": "asgard", "pool": ["ygg_naar", "eroghost", "evy_blood_sage", "gumi_wolf", "slime"], "boss": "lucidria", "variant": "echo", "mirror": true, "boss_hp": 3.2, "boss_atk": 1.45,
		"mod": {"elem": "LIGHT", "atk": 0.25, "name": "First Light: LIGHT units +25% ATK"},
		"intro": [["nar", "High above Asgard, where the clouds were older than time, stood the cathedral from the memory. Untouched. Waiting."],
			["lucidria", "The First Oath was made here. And when the Commander fell, I swore I would keep this place exactly as it was. Forever."],
			["furu", "Lucidria... that's not keeping a promise. That's being trapped by one."]],
		"mid": [["vexira", "Ara~ the flowers here are a thousand years old and still blooming. Someone's been very stubborn."], ["kali", "Stubborn is a kind of love. A heavy kind."]],
		"mid2": [["nar", "At the altar stood an Echo — not of a past life, but of a past heart. Lucidria, exactly as she had been on the day she started waiting."],
			["lucidria", "That's me. The part of me that never stopped waiting. She doesn't want to let go of the old Oath. She doesn't believe you're really back."],
			["?", "lucidria", ["Then I'll prove it to both of you.", "You don't have to fight her alone.", "She's part of you. Bring her home too."],
				["...Prove it. Please. I'm so tired of being the only one who remembers.", "Not alone. Never alone. That's the new Oath, isn't it?", "Bring her home... yes. Both of us. Together."], [30, 40, 40]]],
		"boss_lines": [["echo:lucidria", "Go away. You are a stranger wearing his face. My Commander promised he would not make me wait alone — and then I waited a thousand years. Alone."],
			["commander", "I'm sorry. I'm here now. And I'm not leaving — not this time, not ever."],
			["echo:lucidria", "...Words. He said beautiful words too. Show me. Show me you are real."], ["shina", "Everyone — let's show her!"]],
		"outro": [["echo:lucidria", "...Warm. Your hand is warm. You're real. You actually came back."],
			["nar", "The Echo of the waiting heart folded into Lucidria like a pressed flower closing between pages."],
			["lucidria", "Commander. The First Oath is fulfilled. You came back, and I wasn't alone. So... I'd like to make a second one."],
			["nar", "Siv's ring caught the light. Twenty-seven heroes knelt in a circle — not because a seal demanded it, but because they chose to."],
			["fidelia", "The Second Oath. Not to seal anything. Just... to stay together."], ["mora", "No hourglass. No echoes. Just a promise for tomorrow."],
			["nar", "— END OF ARC 6: ECHOES OF THE FIRST OATH —   A thousand years later, the Commander kept the promise. Thank you for playing."]]},
	# ---- Arc 7: Ashes of Abaddon (Abadonia's lost kingdom)
	{"name": "Abaddon City", "bg": "abaddon", "pool": ["slarkoi", "gumi_wolf", "eroghost", "ex_nymph"], "boss": "slarkoi", "variant": "ashen", "mirror": true, "boss_hp": 5.0, "boss_atk": 1.8,
		"mod": {"elem": "EARTH", "atk": 0.25, "name": "Rusted Iron: EARTH units +25% ATK"},
		"intro": [["nar", "— ARC 7 —   ASHES OF ABADDON"], ["nar", "One morning, Abadonia's lion refused to eat. He stood at the cathedral gate, facing west, growling at nothing."],
			["abadonia", "...He smells it. Iron and rain and ash. He smells home."], ["fidelia", "Home? You never told us where you came from."],
			["abadonia", "Because there is nothing left to tell. Abaddon was a city of iron towers. I was its princess. Three hundred years ago, it burned — and I ran."],
			["?", "abadonia", ["Then let's go see it. Together.", "You don't have to go back.", "Running kept you alive. That's not shameful."],
				["...Together. My lion would like that. So would I.", "I do. He won't stop growling until I do.", "...You say that so easily. I wish I could believe it."], [40, 20, 30]]],
		"mid": [["xylia", "These towers are impossible. Steel frames, glass skins... this city was centuries ahead of us."], ["gemora", "Matching records: none. Abaddon has been erased from every archive."]],
		"mid2": [["abadonia", "This was the Grand Avenue. My brother and I raced our lions down it every spring."], ["shina", "You have a BROTHER?"],
			["abadonia", "Had. Aurelion. The Crown Prince. He stayed behind when the city burned. I never learned what happened to him."],
			["nar", "Something enormous shifted in the rubble ahead — a colossus of rust and ash, wearing the city's broken crest."]],
		"boss_lines": [["nar", "The Rust Colossus had guarded the empty avenue for three hundred years, still obeying its last command: let no one return."],
			["abadonia", "I am Abadonia of Abaddon! Your princess has returned — stand aside!"], ["nar", "It did not recognise her. Ash had long since filled its eyes."]],
		"outro": [["abadonia", "...It was built to protect us. And it waited three hundred years for someone to come home."],
			["nar", "In the Colossus' chest, a bronze plate glowed: 'BY ORDER OF CROWN PRINCE AURELION — SEAL THE EASTERN GATE.'"],
			["abadonia", "He sealed the gate... from the inside. Why would he—"], ["atalanta", "The eastern gate's open now. And there's... a jungle behind it? With very big footprints."]]},
	{"name": "Primeval Vale", "bg": "dino", "pool": ["gumi_wolf", "ex_nymph", "svormentis", "slime"], "boss": "gumi_wolf", "variant": "ashen", "mirror": true, "boss_hp": 3.2, "boss_atk": 1.35,
		"mod": {"elem": "WIND", "atk": 0.25, "name": "Ancient Wilds: WIND units +25% ATK"},
		"intro": [["atalanta", "DINOSAURS. Commander. Real, actual dinosaurs. I'm going to race one."], ["zennyo", "The little dragons are bowing to them. They're... ancestors?"],
			["mora", "Time is frozen here. This valley is a pocket of the past — Aurelion sealed it away. But why?"]],
		"mid": [["siv", "That one's eating a tree! A WHOLE tree!"], ["lumeira", "The butterflies here are as big as my head~ I love it."]],
		"mid2": [["abadonia", "...I remember now. Father kept a hidden valley for the royal beasts. My lion was born here."],
			["abadonia", "If Aurelion hid the city's treasures in frozen time, then he expected someone to come back for them. He expected me."],
			["?", "atalanta", ["Atalanta, scout ahead.", "Stay close — something's hunting us.", "Race you to the river!"],
				["On it! Back before you blink!", "...You're right. The birds went quiet.", "You're ON, Commander!"], [30, 30, 40]]],
		"boss_lines": [["nar", "From the ferns rose the alpha of the vale — a great beast, ash-grey from the cinders that blew in from the burning city long ago."],
			["zennyo", "It's scared. The ash hurts it. Commander, let's set it free!"]],
		"outro": [["nar", "The alpha shook off its ashen coat and padded away, lighter, into the green."],
			["abadonia", "There's a path behind the waterfall. Old stone steps, worn smooth. The royal procession road."],
			["lucidria", "Royal roads always lead to the same place, Commander. The tombs."], ["abadonia", "...The Necropolis of Kings. Where my father sleeps."]]},
	{"name": "Necropolis of Kings", "bg": "necro", "pool": ["eroghost", "hairly", "ymir", "evy_blood_sage"], "boss": "eroghost", "variant": "ashen", "mirror": true, "boss_hp": 6.5, "boss_atk": 1.8,
		"mod": {"elem": "DARK", "def": 0.25, "name": "Grave Chill: DARK units +25% DEF"},
		"intro": [["rumi", "Okay. This is the most haunted place I have ever been. And I've been to the Hollow Star."], ["furu", "So many restless souls... they're all wearing crowns."],
			["abadonia", "Every king of Abaddon is buried here. Except one. There was never a tomb for Aurelion."]],
		"mid": [["hyeonxa", "The air is thick with old curses. Don't breathe too deeply."], ["vexira", "Ara~ the dead here dream of fire. Every single one."]],
		"mid2": [["nar", "On the wall of the deepest tomb, carved in a frantic hand: 'The Eclipse offered to save Abaddon. I said yes. Forgive me, little sister.'"],
			["abadonia", "...Aurelion. You fool. You absolute fool. You made a deal with the Eclipse?"],
			["?", "abadonia", ["He did it to protect you.", "It's not your fault he chose this.", "We'll find out the whole truth."],
				["...He always did stupid things to protect me.", "...Then why does it feel like it is?", "Yes. Whatever it costs. I need to know."], [30, 40, 30]]],
		"boss_lines": [["nar", "The herald of the Ashen King rose from the royal sarcophagus, robed in cinders."],
			["nar", "'The King sleeps in the burning city. He waits for his sister. He has waited three hundred years to say goodbye.'"],
			["abadonia", "Then get out of my way. I'm late."]],
		"outro": [["nar", "The herald crumbled. Beyond the last tomb, the sky turned red — and the city outside began, impossibly, to burn again."],
			["mora", "Commander, the hourglass — time is folding. We're seeing the night Abaddon fell. It's replaying."],
			["abadonia", "Then this time I'm not running. Lion — we ride. Toward the fire."]]},
	{"name": "Abaddon Burning", "bg": "apocalypse", "pool": ["skelinch", "evy_blood_sage", "serpentia", "eroghost", "slarkoi"], "boss": "abadonia", "variant": "ashen", "mirror": true, "boss_hp": 1.8, "boss_atk": 0.95,
		"mod": {"elem": "LIGHT", "atk": 0.25, "name": "Last Dawn of Abaddon: LIGHT units +25% ATK"},
		"intro": [["nar", "The night of the fall, three hundred years ago — replayed in crystal and fire."],
			["nar", "On the palace steps stood a young princess on a lion, frozen mid-flight, her face full of terror. And beside her, made of ash, another Abadonia — older, colder, furious."],
			["abadonia", "...That's me. The part of me that never forgave myself for running."]],
		"mid": [["kali", "Fire in every street. A hundred blades won't put this out."], ["eropatra", "Then we don't put it out. We walk through it."]],
		"mid2": [["nar", "In the throne room, a tall figure of embers knelt with his back to them. A crown of ash. A voice like a dying hearth."],
			["nar", "'Little sister. I asked the Eclipse to save the city. It saved nothing. It only kept us burning — me, and the part of you that stayed.'"],
			["nar", "'Set her free. Set yourself free. And then let me go.'"],
			["?", "abadonia", ["We'll do it together.", "Say goodbye to him, Abadonia.", "He's proud of you. I can tell."],
				["...Together. Yes. Hold on to me, Commander.", "...I will. After. I promise.", "...Don't. I'll cry. Queens don't cry. ...Damn it."], [40, 30, 30]]],
		"boss_lines": [["ashen:abadonia", "You RAN. You left him. You left all of them. What kind of queen runs?"],
			["abadonia", "A frightened girl of sixteen. That's who. And she lived. And she found a family again."],
			["ashen:abadonia", "...A family? You don't deserve one."], ["commander", "She does. And we're right here to prove it."]],
		"outro": [["ashen:abadonia", "...They stayed. All of them. Even knowing what I did."],
			["nar", "The ashen queen bowed her head, and became a frightened girl on a lion — and then simply a memory, warm and forgiven."],
			["nar", "'Thank you, little sister.' The ember king rose, smiled, and scattered into a thousand sparks that drifted up into a clear night sky."],
			["abadonia", "...Goodbye, Aurelion. I'll race the lions down the Grand Avenue for you. Every spring."],
			["nar", "When dawn came, the fires were gone. Abaddon was still ruined — but vines and flowers had already begun to climb the iron towers."],
			["xylia", "...I could rebuild it. Not the same. Better. If the Queen allows it."], ["abadonia", "The Queen allows it. On one condition: the Commander gets the tallest tower."],
			["nar", "— END OF ARC 7: ASHES OF ABADDON —   The lion finally ate his breakfast. Thank you for playing, Commander."]]},
	# ---- Arc 8: The Gilded Gate (the 4 November heroes)
	{"name": "The Gilded Gate", "bg": "asgard", "pool": ["hairly", "voodoo", "lizamorph", "slime"], "boss": "hairly", "variant": "astral", "mirror": true, "boss_hp": 3.5, "boss_atk": 1.7,
		"mod": {"elem": "LIGHT", "atk": 0.25, "name": "Heaven's Gate: LIGHT units +25% ATK"},
		"intro": [["nar", "— ARC 8 —   THE GILDED GATE"], ["nar", "One morning, a golden gate appeared in the sky above Asgard. Nobody had built it. Nobody could open it."],
			["angela", "Commander. I am Angela, guardian of that gate. And I have failed — something slipped through it last night."],
			["shina", "An angel? Asking US for help? This is a first."],
			["?", "angela", ["We'll help. Tell us everything.", "What slipped through?", "You don't have to apologise."],
				["Thank you. Heaven chose well.", "A witch made of shadow and hair. She steals fates.", "...I'm a guardian. Failing is not allowed. But thank you."], [30, 30, 40]]],
		"mid": [["mora", "The hourglass sand is turning black near the gate. Someone is reading futures... and eating them."], ["angela", "That is her. Hairly, the Witch of Shadow Tresses."]],
		"mid2": [["nar", "In the clouds beyond the gate sat a woman wrapped in black hair, shuffling tarot cards made of other people's tomorrows."],
			["hairly", "...You came. Let me peek at your fate. Oh — it's so bright. I want it."]],
		"boss_lines": [["hairly", "Every card I draw is a stolen tomorrow. Yours would be the brightest in my deck."],
			["angela", "Not while I stand. Seraph's wings — open!"], ["commander", "Angela, together. You're not guarding this gate alone anymore."]],
		"outro": [["hairly", "...Fine. I'll give them back. All the futures. But I keep the deck. It's pretty."],
			["angela", "She surrendered? ...That was easier than heaven's records predicted."],
			["hairly", "I didn't surrender. I read your Commander's card. It said: 'Stay close to this one.' So I will."],
			["nar", "And so the witch who stole fates became the Commander's fortune teller."],
			["angela", "Commander. The gate shows four more cracks. Four more realms are bleeding through. ...Will you let me fly beside you?"]]},
	{"name": "Thousand-Coin Bazaar", "bg": "blackmarket", "pool": ["svormentis", "slime", "gumi_wolf", "ex_nymph"], "boss": "svormentis", "variant": "astral", "mirror": true, "boss_hp": 3.0, "boss_atk": 1.3,
		"mod": {"elem": "EARTH", "atk": 0.25, "name": "Golden Tide: EARTH units +25% ATK"},
		"intro": [["ninger", "You there! Commander! Yes, you! Want to buy a lucky coin? Only one gold! ...Okay, ten gold."],
			["rumi", "A fellow merchant. I respect the hustle."], ["ninger", "I'm Ning Er, Princess of a Thousand Coins! And my bazaar is being EATEN."]],
		"mid": [["ninger", "Something huge swims under the market. It swallowed three stalls and a very angry chicken."], ["siv", "A sea monster in a market?! I'll hit it!"]],
		"mid2": [["nar", "From a fountain of gold coins rose a monstrous fish with a girl perched in its jaws, laughing."],
			["ninger", "Svormentis! The Devouring Maw! It eats coins — and it's been eating MY coins!"],
			["?", "ninger", ["Coins can be earned again.", "We'll get every coin back.", "Is the chicken okay?"],
				["...You're right. But they were LUCKY coins!", "Every single one? You're my favourite customer!", "THE CHICKEN IS FINE. Focus, Commander!"], [30, 40, 20]]],
		"boss_lines": [["nar", "The Maw opened wide enough to swallow the whole bazaar."], ["ninger", "Commander! Rain of Golden Fortune — I'll keep you all standing!"]],
		"outro": [["nar", "The Maw spat out ten thousand coins, three stalls, and a very relieved chicken, then sank back into the fountain, sulking."],
			["ninger", "My coins! My bazaar! ...Commander, from today you shop for free. Okay, ninety percent off."],
			["angela", "Two cracks sealed. The next one bleeds fire. Red fire."], ["mei", "...That would be my fault. Sorry. Hi. I'm Mei."]]},
	{"name": "Crimson Dojo", "bg": "dragonfire", "pool": ["ymir", "serpentia", "evy_blood_sage", "skelinch"], "boss": "ymir", "variant": "ashen", "mirror": true, "boss_hp": 2.8, "boss_atk": 1.35,
		"mod": {"elem": "FIRE", "atk": 0.25, "name": "Burning Dojo: FIRE units +25% ATK"},
		"intro": [["mei", "My dojo sits on a dragon's skeleton. Don't stare at the ears. Stare at the sword."], ["kali", "A hundred blades greet you, sister of the sword."],
			["mei", "...You have more swords than me. I hate you. Let's be friends."]],
		"mid": [["mei", "A queen of bones moved into my dojo. She sits on a skull throne and judges my katas."], ["zennyo", "The little dragons don't like her. She's sitting on their grandpa."]],
		"mid2": [["nar", "Atop a mountain of skulls sat Ymir, wrapped in ancient bandages, crowned in gold."],
			["kara", "...Ymir. I know her. I reaped her soul nine hundred years ago. She refused to go."],
			["mei", "Wait, who are YOU?"], ["kara", "Kara. The Phoenix Reaper. I'm here to finish a job."]],
		"boss_lines": [["nar", "'No reaper takes the Queen of the Bone Throne,' rattled a thousand skulls at once."],
			["kara", "Then I'll take you with company. Mei, left flank. Commander, give the order."], ["mei", "Since when do you give ME orders?!"]],
		"outro": [["nar", "The bone throne crumbled. Ymir's bandages fell away, and for a moment a tired old queen smiled — and finally let go."],
			["kara", "...She just wanted someone to say she ruled well. So I told her."],
			["mei", "That was... kind. For a reaper."], ["kara", "Don't tell anyone. Bad for the brand."],
			["angela", "One crack left. It's... humming. Mechanical."], ["spimei", "That's me. Hi. Please don't shoot my drones."]]},
	{"name": "Scarlet Engine", "bg": "space", "pool": ["svormentis", "hairly", "ymir", "ygg_naar", "eroghost"], "boss": "spimei", "variant": "mirror", "mirror": true, "boss_hp": 2.6, "boss_atk": 1.2,
		"mod": {"elem": "WIND", "atk": 0.25, "name": "Ion Wind: WIND units +25% ATK"},
		"intro": [["spimei", "I built a gate engine to fly between realms. It worked. Then it stopped listening to me."],
			["xylia", "You built THAT? It's beautiful. It's terrifying. Teach me."], ["spimei", "...Help me shut it down first. Then I'll teach you everything."]],
		"mid": [["gemora", "The engine is copying people who pass through the gates. It made a copy of Spimei."], ["spimei", "A copy of me without a heart module. That's... the worst version of me."]],
		"mid2": [["nar", "In the engine's core hovered a scarlet figure with drone wings — Spimei's face, but cold and blank."],
			["spimei", "I built her to be efficient. Efficient people don't feel anything. ...I almost was her."],
			["?", "spimei", ["You're not her. You came to us.", "Your heart module is my favourite part.", "Let's shut her down together."],
				["...Correct. I chose you. Logged.", "W-warning: overheating. That's your fault.", "Together. Efficiency increased by... a lot."], [30, 40, 30]]],
		"boss_lines": [["mirror:spimei", "Emotion detected in the original. Inefficient. Deleting."], ["spimei", "No. My emotions are the best thing I ever built."],
			["commander", "Everyone — Angela, Ning Er, Mei, Kara, Spimei — this is your arc. Show her!"]],
		"outro": [["nar", "The mirror powered down. The last crack in the Gilded Gate sealed with a soft chime."],
			["angela", "All four realms are stable. The gate is closed... and its five guardians are standing beside you, Commander."],
			["ninger", "Five new friends! That's worth more than a thousand coins!"], ["mei", "Fine. I'll stay. The food here is good."],
			["kara", "I'll stay too. Someone has to keep the reaper's job interesting."], ["spimei", "Staying. Heart module requires it."],
			["hairly", "...I already knew all of you would say that. I read the cards."],
			["nar", "— END OF ARC 8: THE GILDED GATE —   Welcome, new friends. Thank you for playing, Commander."]]},
	# ---- Arc 9: The Wild Hunt (Luby + the tamed beasts; 4 Nov part 2 foes)
	{"name": "Howling Wilds", "bg": "outland", "pool": ["gumi_wolf", "scomantis", "skelinch", "ex_nymph"], "boss": "scomantis", "variant": "feral", "mirror": true, "boss_hp": 4.2, "boss_atk": 1.9,
		"mod": {"elem": "WIND", "atk": 0.25, "name": "Hunting Gale: WIND units +25% ATK"},
		"intro": [["nar", "— ARC 9 —   THE WILD HUNT"], ["nar", "Three nights after the Gilded Gate closed, a horn sounded across the Outlands. Long. Low. Hungry."],
			["nar", "In every camp, every tamed beast lifted its head at once — and their eyes turned green."],
			["luby", "Nyaa— Commander! My mecha cat bit me! He NEVER bites me! Something is calling him!"],
			["gumi_wolf", "...Grrr... the horn... it sings... Master, hold my collar. Please. Don't let me go to it."],
			["?", "luby", ["We'll find who's blowing that horn.", "Your cat will be okay, Luby.", "Everyone keep your companions close."],
				["Yes! And I'm biting THEM back!", "...Promise? He's all I have. He's made of scrap and he's perfect.", "Good plan. Tie them to the cathedral. With bows. Cute bows."], [40, 30, 30]]],
		"mid": [["atalanta", "Tracks. Hundreds of them. All heading to the same place — the Wild Hunt's camp."], ["luby", "And they're not running away. They're running TO something."]],
		"mid2": [["nar", "On a ridge of black thorns stood an emerald scorpion girl, her stinger glowing with the same green light as the horn."],
			["scomantis", "Click-click. The Horn calls, and we answer. Why should beasts kneel to people?"],
			["gumi_wolf", "Because some people... scratch behind your ears. And mean it."]],
		"boss_lines": [["feral:scomantis", "Emerald venom for the tamers! The Hunt takes back what is ours!"], ["luby", "He's not yours! He's MINE! — Mecha-Cat, pounce!"],
			["commander", "Don't hurt her more than we need to. She's not the enemy. The horn is."]],
		"outro": [["nar", "The green light drained from the scorpion girl's eyes. She sat down in the dust and shivered."],
			["scomantis", "...Click. I was... somewhere loud. And angry. And you pulled me out."],
			["luby", "Wanna come home with us? We have snacks. And a very forgiving Commander."],
			["scomantis", "...Snacks. Yes. Click-click."], ["atalanta", "The tracks go south. Toward the hot springs. Something big is bathing there."]]},
	{"name": "Serpent Springs", "bg": "pool", "pool": ["serpentia", "slime", "scomantis", "voodoo"], "boss": "serpentia", "variant": "feral", "mirror": true, "boss_hp": 3.5, "boss_atk": 1.8,
		"mod": {"elem": "FIRE", "atk": 0.25, "name": "Scalding Springs: FIRE units +25% ATK"},
		"intro": [["nar", "The springs of the south steam day and night. Today the water was boiling — and singing the horn's song."],
			["zennyo", "That steam smells like dragon. Cousin dragon. Angry cousin dragon."],
			["luby", "Mecha-Cat hates water. He's shaking. ...Okay, I'm also shaking. Nyaa."]],
		"mid": [["schylua", "The water froze where I touched it, then melted again in a second. Something in there is VERY warm."], ["zennyo", "Something with scales. Lots of scales."]],
		"mid2": [["nar", "From the boiling pool rose a lamia wrapped in flame-scales, coiling around a burning orb."],
			["serpentia", "Sssso the tamers come. Did you know I used to sleep here peacefully? Then the horn woke me. It's so loud."],
			["?", "zennyo", ["We can make it quiet again.", "Zennyo, talk to her. Dragon to dragon.", "Everyone, cool her down!"],
				["...Quiet. She'd like that. So would I.", "...Cousin. Come out of the noise. I'll sing you something softer.", "Schylua! Ice! Lots of ice!"], [30, 40, 30]]],
		"boss_lines": [["feral:serpentia", "HSSSS! The Horn says coil, crush, burn!"], ["zennyo", "Then listen to me instead! Dragon King's Daughter — FLAME, ANSWER ME!"],
			["commander", "Hold the line. When she tires, we talk."]],
		"outro": [["nar", "The springs cooled. The lamia sank into the water up to her chin and closed her eyes."],
			["serpentia", "...It's quiet. Oh, it's so quiet. Thank you, little cousin."], ["zennyo", "Anytime. ...I'm not little."],
			["luby", "Two down! But the horn's still blowing. From the north now. From... a carnival?"],
			["hairly", "I drew a card. The Puppet. Someone up there is pulling strings — and not only the beasts'."]]},
	{"name": "The Puppet Fair", "bg": "necro", "pool": ["lizamorph", "eroghost", "skelinch"], "boss": "voodoo", "variant": "feral", "mirror": true, "boss_hp": 2.6, "boss_atk": 1.4,
		"mod": {"elem": "LIGHT", "atk": 0.25, "name": "Fairground Lights: LIGHT units +25% ATK"},
		"intro": [["nar", "A carnival nobody remembered building stood in the northern ruins. Music boxes played the horn's song, slightly out of tune."],
			["vexira", "Ooh, a carnival! With rides! And clowns! ...Why are all the clowns staring at me?"],
			["skelinch", "Yo, Commander. Hellfire Punk, reporting. The horn grabbed me too. Then it got bored and let go. Rude."]],
		"mid": [["lucidria", "Every stall has a puppet. Every puppet looks like someone we've tamed."], ["luby", "There's one of Mecha-Cat. It's... cute? No. Creepy. Cute-creepy."]],
		"mid2": [["nar", "On a stage at the heart of the fair, a porcelain doll danced on strings that rose into the dark — strings tied to the Horn itself."],
			["voodoo", "Stitched together and stitched to the Horn. I dance when it pulls. I don't want to dance anymore."],
			["skelinch", "Then let's cut the strings. I've got fire for fists. Fire beats string. Everyone knows that."]],
		"boss_lines": [["feral:voodoo", "Dance, dance, dance — the Horn's song never stops!"], ["skelinch", "It does now! Hellfire Gauntlets — BURN THE STRINGS!"],
			["commander", "Aim for the strings, not the doll!"]],
		"outro": [["nar", "One by one the strings snapped. The doll fell — and Vexira caught her before she hit the stage."],
			["voodoo", "...I'm not dancing. I'm just... sitting. Is this what it's like?"], ["vexira", "Yep. Sitting is great. Ten out of ten. You'll love it."],
			["nar", "Above the fair, the cut strings drifted upward and vanished into a black, crawling shadow — and the Horn sounded one last time."],
			["luby", "...That came from home. From the cathedral. Mecha-Cat is at the cathedral! NYAA, Commander, RUN!"]]},
	{"name": "The Last Hunt", "bg": "blackhole", "pool": ["lizamorph", "gumi_wolf", "serpentia", "skelinch"], "boss": "luby", "variant": "feral", "mirror": true, "boss_hp": 2.0, "boss_atk": 1.0,
		"mod": {"elem": "WIND", "atk": 0.3, "name": "The Wild Hunt: WIND units +30% ATK"},
		"intro": [["nar", "The cathedral was dark. In the courtyard sat the Horn — and wrapped around it, a crawling shadow with a hundred limbs."],
			["lizamorph", "...hungry... the Horn feeds me every bond it breaks... so many bonds here... so warm..."],
			["nar", "And beside it stood Luby. Green eyes. Green claws. Her mecha cat purring at her feet like a war engine."],
			["feral:luby", "Nya. Commander. The Horn says I'm free now. No collars. No snacks. Just the Hunt."],
			["luby", "...That's not me. That's me — but without the part that loves you. Commander, please. Get her back. Get ME back."]],
		"mid": [["gumi_wolf", "Master. The shadow drinks the bonds. Every pat. Every gift. Every 'good girl'. It wants all of it."],
			["scomantis", "Then we give it nothing. Click. We hold on tighter."]],
		"mid2": [["nar", "Every tamed beast in the cathedral stepped forward — Gumi, Scomantis, Serpentia, Voodoo, Skelinch — and stood beside the Commander."],
			["serpentia", "We were called by the Horn. Now we answer something else."],
			["?", "luby", ["Luby, remember the sunbeam on my desk?", "Your cat bit you — and you still loved him.", "Come home. Snacks are waiting."],
				["...The sunbeam. First come, first nap. ...I remember.", "...Because he's MINE. Scrap and all. Like you're mine.", "...There better be fish snacks. ...Nya. I'm coming."], [40, 40, 30]]],
		"boss_lines": [["feral:luby", "The Hunt never ends! Mecha-Cat — POUNCE!"], ["luby", "Mecha-Cat — STAY. ...Good boy. Now, Commander. Bring her home."],
			["commander", "Everyone — beasts and heroes together. This is the last hunt."]],
		"outro": [["nar", "The Horn cracked down the middle. The green light poured out of it like water and soaked into the earth."],
			["nar", "The feral Luby blinked, looked at her own claws, and burst into tears — and the real Luby hugged her until there was only one."],
			["luby", "...Nyaa. I'm back. I'm all here. ...Mecha-Cat, stop licking my face, you're made of METAL."],
			["lizamorph", "...hungry... still hungry... but... ...that hug... it was warm... can I... stay near it?"],
			["commander", "You can stay. But you only eat dinner. Not bonds."], ["lizamorph", "...dinner. ...yes. ...thank you."],
			["nar", "That night, for the first time, every beast in the cathedral slept beside someone who loved it."],
			["nar", "— END OF ARC 9: THE WILD HUNT —   Every bond held. Thank you for playing, Commander."]]},
]
const STAGES_PER_CHAPTER := 6

## Interludes: battle-free story episodes unlocked after each arc (first read = reward + Bond for the cast).
const INTERLUDES := [
	{"id": "i1", "name": "Tea at the Cathedral", "req": 36, "bg": "lobby", "cast": ["shina", "fidelia", "furu"],
		"lines": [["nar", "A quiet afternoon, one week after the first Eclipse."], ["shina", "Commander! I made tea. It's... a little burnt. Dragon fire is hard to control."],
			["fidelia", "Tea isn't supposed to be on fire, Shina."], ["furu", "It's the thought that counts! ...Mostly."],
			["shina", "Hey, Commander. When this all started, I said I wasn't waiting for you. That was a lie. I waited every day."],
			["?", "shina", ["I'll always come back.", "I know. I waited too.", "The tea's actually good."],
				["...Hmph. You'd better.", "W-wha— don't say it so easily!", "Liar. But thanks."], [30, 40, 20]],
			["furu", "The bells sound different now. Lighter. Like the city is breathing again."], ["fidelia", "Enjoy it. Peace is a thing you have to protect, too."]]},
	{"id": "i2", "name": "The Freed Ones", "req": 60, "bg": "forest", "cast": ["kali", "abadonia", "zennyo", "vexira"],
		"lines": [["nar", "The four heroes freed from the Second Eclipse gathered by the river, not quite sure how to be ordinary again."],
			["kali", "I polish my blades every night. I keep thinking one of them will speak in that voice again."], ["abadonia", "My lion won't let me sleep alone. He sits by the door. Every night."],
			["zennyo", "The little dragons forgave me first. They were faster than me at that."],
			["vexira", "...I was the first one taken. Everything you all went through started with me."], ["vexira", "Ara~ I don't really know how to apologise. I've never had to before."],
			["kali", "Then don't. Just stay. That's enough."], ["?", "vexira", ["You're one of us now.", "We'll learn it together.", "Start with 'sorry'. It's easy."],
				["...One of us. Hmm. I like the sound of that.", "Together. That's a word I could get used to.", "S-sorry. ...Was that right?"], [40, 30, 20]],
			["zennyo", "Big sister Shina says breakfast is at the cathedral. She'll burn the eggs. Let's go anyway."]]},
	{"id": "i3", "name": "Letters from Tomorrow", "req": 84, "bg": "galaxy", "cast": ["mora", "valeria", "eropatra", "fidelia"],
		"lines": [["nar", "Inside the cracked hourglass, Mora found three letters that had not existed the day before."],
			["mora", "Valeria. This one is yours. It's... your handwriting."], ["valeria", "'To me, in the warm years: don't wait for him to be gone to say it. Say it every winter.' ...Hmph."],
			["eropatra", "Mine says: 'Rule nothing. Keep everything that matters close.' How dull. ...How true."],
			["fidelia", "'The shield isn't heavy when someone else is holding the other side.' ...I'll remember that."],
			["mora", "And there's one for the Commander. It only says: 'Thank you for staying. — Mora, from a quieter morning.'"],
			["?", "mora", ["Thank her for me.", "You're the Mora I want.", "Let's write one back."],
				["...I'll try. Time is a slow postman.", "C-Commander. You can't say things like that so easily.", "A letter backwards through time. Yes. Let's."], [20, 40, 30]]]},
	{"id": "i5", "name": "Poolside Holiday", "req": 132, "bg": "pool", "cast": ["atalanta", "rubby", "aqua", "scylla"],
		"lines": [["nar", "Xylia kept her promise. The old starport was now a seaside resort — with a very large pool."],
			["atalanta", "Race you to the far end! Loser buys shaved ice for everyone!"], ["aqua", "Please don't splash the tea. The tea is sacred."],
			["rubby", "I brought pool-safe fireworks~ They're waterproof! ...Mostly waterproof."], ["scylla", "...The water here is warm. Not like the sea. I think I like both."],
			["?", "scylla", ["Come swim with us, Scylla.", "Just relax. You earned it.", "Rubby, NO fireworks in the pool."],
				["...Fine. Just one lap. Next to you.", "Earned it... yes. I suppose I did.", "Too late. Look up."], [40, 30, 20]],
			["nar", "Somewhere above the resort, two new stars blinked — one cold and gentle, one gold and huge. Watching. Approving."]]},
	{"id": "i6", "name": "Pressed Flowers", "req": 156, "bg": "lobby", "cast": ["lucidria", "sven", "siv", "hyeonxa"],
		"lines": [["nar", "A week after the Second Oath, Lucidria opened the old book she had carried for a thousand years."],
			["lucidria", "Every page has a flower. One for every day I waited. I thought I would burn it once you came back."],
			["sven", "Don't. It's the road you walked. Roads are worth remembering."], ["hyeonxa", "...I'll archive it properly. In a place that doesn't flood this time."],
			["siv", "And I'll make a new cover! With a hammer! ...Gently!"],
			["?", "lucidria", ["Let's start a new book together.", "Add today's flower.", "I'll read every page."],
				["A new book. With both our names on the cover.", "Today... today I'll press a sunflower.", "It will take a very long time. ...Good. Stay that long."], [40, 30, 30]],
			["nar", "That evening, for the first time in a thousand years, Lucidria pressed a flower simply because it was pretty."]]},
	{"id": "i7", "name": "Lion's Onsen", "req": 180, "bg": "onsen", "cast": ["abadonia", "zennyo", "atalanta", "shina"],
		"lines": [["nar", "To celebrate the end of the fires, Eurnipha booked the whole hot spring inn. The lion was not allowed in. He sulked outside."],
			["abadonia", "...This is my first bath in three hundred years without dreaming of smoke."], ["shina", "Wait, you haven't bathed in THREE HUNDRED—"],
			["abadonia", "Without DREAMING of smoke, dragon. Listen properly."], ["zennyo", "The little dragons are making the water warmer. You're welcome."],
			["atalanta", "Race you to the cold plunge pool!"], ["abadonia", "...You're on. A queen never loses a race."],
			["?", "abadonia", ["You look lighter, Abadonia.", "Your brother would be happy.", "Don't drown Atalanta."],
				["...I feel lighter. Like I put down something heavy.", "...He would. He'd tease me for crying, too.", "No promises."], [30, 40, 20]]]},
	{"id": "i9", "name": "Bath Night for Beasts", "req": 228, "bg": "onsen", "cast": ["luby", "zennyo", "skelinch", "vexira"],
		"lines": [["nar", "After the Wild Hunt, the Commander declared a rule: every tamed beast gets a bath. The beasts declared war."],
			["luby", "Mecha-Cat does NOT go in water. He will RUST. ...Fine, he can have a towel bath."],
			["skelinch", "Yo, I'm a skeleton punk. Water goes right through me. ...Okay, it tickles."],
			["zennyo", "Cousin Serpentia brought her own hot spring. She just... coiled into the tub. The whole tub."],
			["vexira", "The voodoo doll asked if she's allowed to get wet. I said yes. She's been floating happily for an hour."],
			["?", "luby", ["Everyone did great today.", "Who's next? Gumi?", "Luby, it's your turn."],
				["Even the shadow thing? ...It said 'warm'. That counts.", "Gumi is hiding under the altar. With her nine tails sticking out.", "NYAA— no— okay, only if you wash my ears. Gently!"], [40, 30, 30]],
			["nar", "That night the cathedral smelled of soap, wet fur and fish snacks. Nobody minded."]]},
	{"id": "i8", "name": "Five New Faces", "req": 204, "bg": "lobby", "cast": ["angela", "ninger", "mei", "kara", "spimei"],
		"lines": [["nar", "The first dinner at the cathedral with all five newcomers. Shina insisted on cooking. Everyone else insisted she didn't."],
			["ninger", "I'll pay for takeout! ...With the Commander's money."], ["mei", "Are these carrots for me? ...They are, aren't they. Thank you."],
			["kara", "I don't usually eat. Reapers don't need to. ...But this smells nice."], ["spimei", "Drone delivery inbound. I ordered dessert for everyone. Efficiently."],
			["angela", "Commander. In heaven we eat alone, in silence. This is... loud. I love it."],
			["?", "angela", ["Welcome home, everyone.", "You'll get used to the noise.", "Shina, put down the frying pan."],
				["Home... yes. That's the word I was looking for.", "I hope I never do.", "FIRE! — oh. Too late."], [40, 30, 20]],
			["nar", "That night, the cathedral had thirty-two heroes, one oracle, and one very burnt dessert."]]},
	{"id": "i4", "name": "Starlight Afterparty", "req": 108, "bg": "asgard", "cast": ["shina", "eurnipha", "xylia", "cthollia"],
		"lines": [["nar", "Every hero in Euphoria came to the celebration on the roof of the cathedral. Above them, a new star was shining."],
			["xylia", "I redesigned the kitchen. Twice. Shina has been banned from it. Three times."], ["shina", "It was ONE omelette!"],
			["cthollia", "The sea is singing again. Louder than ever. I think it missed me."], ["eurnipha", "I made blankets for everyone. And one extra. For the star."],
			["nar", "High above, Noctis flickered — just once — as if waving."],
			["shina", "Hey, Commander. We did it. The future Mora was so scared of... it's not coming. You're staying. Right?"],
			["?", "shina", ["Right. Forever.", "As long as you'll have me.", "Only if you stop burning eggs."],
				["...Forever's a long time. Good.", "Idiot. That's forever, then.", "NEVER. Stay anyway!"], [40, 30, 20]],
			["nar", "And the Commander stayed."]]},
]
const CHAPTER_REWARD := {"gems": 300, "summon_ticket": 3, "gear_chest": 1}

const ITEMS := {
	"summon_ticket": {"name": "Summon Ticket", "icon": "icon_ticket", "desc": "Use for one summon on any banner.", "kind": "currency"},
	"exp_potion": {"name": "Hero EXP Potion", "icon": "item_exp_potion", "desc": "Grants 1,000 Hero EXP.", "kind": "use", "give": {"hero_exp": 1000}},
	"energy_potion": {"name": "Energy Flask", "icon": "item_energy_potion", "desc": "Restores 60 Energy.", "kind": "use", "give": {"energy": 60}},
	"gold_bag": {"name": "Gold Pouch", "icon": "item_gold_bag", "desc": "Contains 20,000 Gold.", "kind": "use", "give": {"gold": 20000}},
	"bouquet": {"name": "Flower Bouquet", "icon": "item_bouquet", "desc": "Gift: +40 Bond EXP.", "kind": "gift", "bond": 40},
	"sweet_cake": {"name": "Sweet Cake", "icon": "item_sweet_cake", "desc": "Gift: +60 Bond EXP.", "kind": "gift", "bond": 60},
	"perfume": {"name": "Moonlight Perfume", "icon": "item_perfume", "desc": "Gift: +80 Bond EXP.", "kind": "gift", "bond": 80},
	"celestial_gem": {"name": "Celestial Gem", "icon": "item_celestial_gem", "desc": "Precious gift: +120 Bond EXP.", "kind": "gift", "bond": 120},
	"oath_ring": {"name": "Oath Ring", "icon": "item_oath_ring", "desc": "Swear an Oath with a Bond Lv.10 hero (+10% all stats).", "kind": "oath"},
	"star_stone": {"name": "Universal Shard", "icon": "item_star_stone", "desc": "Works as 1 shard for any hero's Star Up.", "kind": "shard"},
	"skill_book": {"name": "Skill Book", "icon": "icon_skills", "desc": "Used to raise a hero's skill level (+12% skill power per level).", "kind": "material"},
	"rune_pouch": {"name": "Rune Pouch", "icon": "item_rune_pouch", "desc": "Open for 2 random runes (Tier 1-2).", "kind": "runes", "count": 2, "max_tier": 2},
	"rune_chest": {"name": "Grand Rune Chest", "icon": "item_rune_chest", "desc": "Open for 3 random runes (Tier 1-3).", "kind": "runes", "count": 3, "max_tier": 3},
	"gear_chest": {"name": "Gear Chest", "icon": "icon_equipment", "desc": "Open for random equipment (R 70% • SR 27% • SSR 3%).", "kind": "chest", "rates": {"SSR": 0.03, "SR": 0.27}},
	"gear_chest_ssr": {"name": "Royal Gear Chest", "icon": "item_royal_chest", "desc": "Open for SR or SSR equipment (SSR 30%).", "kind": "chest", "rates": {"SSR": 0.3, "SR": 0.7}},
	"forge_ember": {"name": "Forge Ember", "icon": "item_forge_ember", "desc": "Salvaged from equipment and won in the Armory Ruins. Fuels Reforging at the Forge.", "kind": "currency"},
	"skin_ticket": {"name": "Special Skin Ticket", "icon": "item_skin_ticket", "desc": "Unlocks any Special Skin in the Wardrobe.", "kind": "currency"},
	"hunt_core": {"name": "Hunt Core", "icon": "item_hunt_core", "desc": "Trophy from Boss Hunts. Trade it at the Hunter's Exchange.", "kind": "currency"},
	"season_token": {"name": "Lantern Charm", "icon": "item_season_token", "desc": "Seasonal Festival currency. Earned from battles while a festival is running. Spend it in the Festival Exchange.", "kind": "currency"},
	"festival_token": {"name": "Event Token", "icon": "icon_live_ops", "desc": "Event currency. Spend it in the Event Exchange.", "kind": "currency"},
}

const SHOP := [
	{"id": "daily_free", "name": "Daily Free Gift", "price": 0, "cur": "gems", "give": {"gems": 60, "gold": 5000}, "limit": 1},
	{"id": "ticket1", "name": "Summon Ticket", "price": 150, "cur": "gems", "give": {"summon_ticket": 1}, "limit": 10},
	{"id": "energy", "name": "Energy Flask x2", "price": 80, "cur": "gems", "give": {"energy_potion": 2}, "limit": 5},
	{"id": "gold", "name": "Gold Pouch x3", "price": 100, "cur": "gems", "give": {"gold_bag": 3}, "limit": 5},
	{"id": "exp", "name": "Hero EXP Potion x5", "price": 15000, "cur": "gold", "give": {"exp_potion": 5}, "limit": 10},
	{"id": "cake", "name": "Sweet Cake x3", "price": 12000, "cur": "gold", "give": {"sweet_cake": 3}, "limit": 5},
	{"id": "perfume", "name": "Moonlight Perfume x2", "price": 90, "cur": "gems", "give": {"perfume": 2}, "limit": 5},
	{"id": "bouquet", "name": "Flower Bouquet x3", "price": 8000, "cur": "gold", "give": {"bouquet": 3}, "limit": 10},
	{"id": "gem_gift", "name": "Celestial Gem", "price": 120, "cur": "gems", "give": {"celestial_gem": 1}, "limit": 5},
	{"id": "shard", "name": "Universal Shard x5", "price": 300, "cur": "arena_coin", "give": {"star_stone": 5}, "limit": 5},
	{"id": "ring", "name": "Oath Ring", "price": 1200, "cur": "arena_coin", "give": {"oath_ring": 1}, "limit": 1},
	{"id": "ticket_ac", "name": "Summon Ticket x2", "price": 200, "cur": "arena_coin", "give": {"summon_ticket": 2}, "limit": 3},
	{"id": "rune_ac", "name": "Rune Pouch x2", "price": 150, "cur": "arena_coin", "give": {"rune_pouch": 2}, "limit": 5},
	{"id": "rune_g", "name": "Rune Pouch", "price": 18000, "cur": "gold", "give": {"rune_pouch": 1}, "limit": 3},
	{"id": "rune_gem", "name": "Grand Rune Chest", "price": 200, "cur": "gems", "give": {"rune_chest": 1}, "limit": 3},
	{"id": "book_ac", "name": "Skill Book x2", "price": 180, "cur": "arena_coin", "give": {"skill_book": 2}, "limit": 3},
	{"id": "book_g", "name": "Skill Book", "price": 25000, "cur": "gold", "give": {"skill_book": 1}, "limit": 2},
	{"id": "gear_chest", "name": "Gear Chest", "price": 20000, "cur": "gold", "give": {"gear_chest": 1}, "limit": 3},
	{"id": "f_ticket", "name": "Summon Ticket", "price": 200, "cur": "friend_point", "give": {"summon_ticket": 1}, "limit": 2},
	{"id": "f_exp", "name": "Hero EXP Potion x3", "price": 120, "cur": "friend_point", "give": {"exp_potion": 3}, "limit": 5},
	{"id": "f_flower", "name": "Flower Bouquet x2", "price": 80, "cur": "friend_point", "give": {"bouquet": 2}, "limit": 5},
	{"id": "f_chest", "name": "Gear Chest", "price": 250, "cur": "friend_point", "give": {"gear_chest": 1}, "limit": 2},
	{"id": "g_ticket", "name": "Summon Ticket", "price": 120, "cur": "guild_coin", "give": {"summon_ticket": 1}, "limit": 3},
	{"id": "g_chest", "name": "Royal Gear Chest", "price": 400, "cur": "guild_coin", "give": {"gear_chest_ssr": 1}, "limit": 1},
	{"id": "g_shard", "name": "Universal Shard x3", "price": 150, "cur": "guild_coin", "give": {"star_stone": 3}, "limit": 3},
	{"id": "g_gem", "name": "Celestial Gem x2", "price": 100, "cur": "guild_coin", "give": {"celestial_gem": 2}, "limit": 3},
]

const DAILY_QUESTS := [
	{"id": "login", "name": "Log in today", "target": 1, "give": {"gems": 30}},
	{"id": "stage", "name": "Clear 3 story stages", "target": 3, "give": {"gems": 50, "gold": 5000}},
	{"id": "summon", "name": "Summon 2 times", "target": 2, "give": {"gems": 40}},
	{"id": "levelup", "name": "Level up any hero", "target": 1, "give": {"exp_potion": 2}},
	{"id": "afk", "name": "Claim AFK rewards", "target": 1, "give": {"gold": 8000}},
	{"id": "arena", "name": "Fight in the Arena", "target": 1, "give": {"arena_coin": 50, "gems": 20}},
	{"id": "bond", "name": "Interact with a hero 3 times", "target": 3, "give": {"bouquet": 1}},
	{"id": "guild", "name": "Check in or donate to your guild", "target": 1, "give": {"guild_coin": 30, "gold": 3000}},
	{"id": "dungeon", "name": "Clear a Daily Dungeon", "target": 2, "give": {"gems": 30, "gear_chest": 1}},
]

const WEEKLY_QUESTS := [
	{"id": "w_stage", "src": "stage", "name": "Clear 40 stages", "target": 40, "give": {"gems": 300, "summon_ticket": 2}},
	{"id": "w_summon", "src": "summon", "name": "Summon 20 times", "target": 20, "give": {"gems": 200, "star_stone": 5}},
	{"id": "w_dungeon", "src": "dungeon", "name": "Clear 12 Daily Dungeons", "target": 12, "give": {"skill_book": 3, "rune_pouch": 2}},
	{"id": "w_arena", "src": "arena", "name": "Fight 10 Arena battles", "target": 10, "give": {"arena_coin": 300, "gems": 150}},
	{"id": "w_bond", "src": "bond", "name": "Interact with heroes 25 times", "target": 25, "give": {"celestial_gem": 2, "perfume": 2}},
	{"id": "w_daily", "src": "quest", "name": "Complete 25 daily missions", "target": 25, "give": {"gems": 500, "summon_ticket": 3, "gear_chest_ssr": 1}},
]

## Codex: one-time rewards per hero milestone.
const CODEX_STEPS := [
	{"id": "own", "name": "Recruited", "give": {"gems": 50}},
	{"id": "star5", "name": "Reached 5★", "give": {"gems": 150, "star_stone": 3}},
	{"id": "bond10", "name": "Bond Lv.10", "give": {"celestial_gem": 2, "gems": 100}},
	{"id": "awaken5", "name": "Awakening A5", "give": {"summon_ticket": 3}},
]

const ACHIEVEMENTS := [
	{"id": "ch1", "name": "Clear Chapter 1", "stat": "stages_cleared", "target": 6, "give": {"gems": 300, "summon_ticket": 2}},
	{"id": "ch3", "name": "Clear Chapter 3", "stat": "stages_cleared", "target": 18, "give": {"gems": 600, "summon_ticket": 5}},
	{"id": "ch6", "name": "Clear Arc 1 (Chapter 6)", "stat": "stages_cleared", "target": 36, "give": {"gems": 1500, "oath_ring": 1}},
	{"id": "ch10", "name": "Clear Arc 2 (Chapter 10)", "stat": "stages_cleared", "target": 60, "give": {"gems": 3000, "summon_ticket": 10, "oath_ring": 1}},
	{"id": "ch12", "name": "Shatter Two Mirrors (Chapter 12)", "stat": "stages_cleared", "target": 72, "give": {"gems": 2000, "summon_ticket": 5, "celestial_gem": 2}},
	{"id": "ch14", "name": "Clear Arc 3: The Hour of Dawn", "stat": "stages_cleared", "target": 84, "give": {"gems": 5000, "summon_ticket": 15, "oath_ring": 1}},
	{"id": "ch16", "name": "Hear the Hollow Star (Chapter 16)", "stat": "stages_cleared", "target": 96, "give": {"gems": 2500, "summon_ticket": 6, "celestial_gem": 2}},
	{"id": "ch18", "name": "Clear Arc 4: The Last Light", "stat": "stages_cleared", "target": 108, "give": {"gems": 8000, "summon_ticket": 20, "oath_ring": 2}},
	{"id": "ch22", "name": "Clear Arc 5: The Starbound Expedition", "stat": "stages_cleared", "target": 132, "give": {"gems": 10000, "summon_ticket": 25, "celestial_gem": 5}},
	{"id": "ch26", "name": "Clear Arc 6: Echoes of the First Oath", "stat": "stages_cleared", "target": 156, "give": {"gems": 12000, "summon_ticket": 30, "oath_ring": 3}},
	{"id": "ch30", "name": "Clear Arc 7: Ashes of Abaddon", "stat": "stages_cleared", "target": 180, "give": {"gems": 14000, "summon_ticket": 30, "celestial_gem": 6}},
	{"id": "ch34", "name": "Clear Arc 8: The Gilded Gate", "stat": "stages_cleared", "target": 204, "give": {"gems": 15000, "summon_ticket": 30, "celestial_gem": 6}},
	{"id": "ch38", "name": "Clear Arc 9: The Wild Hunt", "stat": "stages_cleared", "target": 228, "give": {"gems": 16000, "summon_ticket": 30, "celestial_gem": 7}},
	{"id": "hard30", "name": "Clear 30 Hard stages", "stat": "hard_cleared", "target": 30, "give": {"gems": 1500, "star_stone": 20}},
	{"id": "own8", "name": "Recruit 8 heroes", "stat": "heroes_owned", "target": 8, "give": {"gems": 300}},
	{"id": "own27", "name": "Recruit every hero (27)", "stat": "heroes_owned", "target": 27, "give": {"gems": 3000}},
	{"id": "pull50", "name": "Summon 50 times", "stat": "total_pulls", "target": 50, "give": {"summon_ticket": 5}},
	{"id": "tower10", "name": "Reach Tower floor 10", "stat": "tower_floor", "target": 10, "give": {"gems": 400}},
	{"id": "star6", "name": "Raise a hero to 6★", "stat": "max_star", "target": 6, "give": {"gems": 500, "celestial_gem": 2}},
	{"id": "oath", "name": "Swear an Oath", "stat": "oaths", "target": 1, "give": {"gems": 500}},
	{"id": "tower25", "name": "Reach Tower floor 25", "stat": "tower_floor", "target": 25, "give": {"gems": 800, "gear_chest_ssr": 1}},
	{"id": "pull150", "name": "Summon 150 times", "stat": "total_pulls", "target": 150, "give": {"summon_ticket": 10}},
	{"id": "skill5", "name": "Master a skill (Lv.5)", "stat": "max_skill", "target": 5, "give": {"gems": 400, "skill_book": 3}},
	{"id": "memories", "name": "Read 10 Memories", "stat": "memories", "target": 10, "give": {"gems": 500, "celestial_gem": 3}},
	{"id": "pass30", "name": "Reach Season Pass Lv.30", "stat": "pass_level", "target": 30, "give": {"gems": 1000}},
]

const MAIL := [
	{"id": "skins_nov5", "title": "Special Skins Have Arrived!", "body": "Exclusive outfits are now in the WARDROBE: Ning Er, Spimei and Luby. Here is a Skin Ticket on us — pick your favourite!", "give": {"skin_ticket": 1, "gems": 200}},
	{"id": "nov2026", "title": "10 New Heroes Have Arrived!", "body": "Abadonia, Atalanta, Kali, Zennyo Ryuo, Aqua, Rubby, Schylua, Vexira, Siv and Sven join Euphoria! Meet them at the new rate-up banners. Lulu now runs the Shop (and the Black Market at night).", "give": {"summon_ticket": 2, "gems": 300}},
	{"id": "welcome", "title": "Welcome to Euphoria Online!", "body": "Commander, thank you for joining us. Please accept these gifts to begin your journey.", "give": {"gems": 900, "summon_ticket": 5, "gold": 50000}},
	{"id": "patch_v2", "title": "Version 2.0 Update", "body": "The battle system, formation and summoning have been fully rebuilt. Enjoy this compensation!", "give": {"exp_potion": 10, "energy_potion": 3}},
	{"id": "bond_event", "title": "Bond Festival", "body": "Gifts for your favourite heroes. Give them flowers in the Bond tab!", "give": {"bouquet": 10, "celestial_gem": 3}},
]

const GACHA_RATES := {"SSR": 0.03, "SR": 0.15}
const GACHA_PITY := 80
const GACHA_COST := 150
const DUPE_SHARDS := {"R": 10, "SR": 20, "SSR": 40}
## Spark: every pull on a rate-up banner gives 1 Summon Point for that banner;
## SPARK_COST points can be exchanged for the featured hero (or her duplicate shards).
const SPARK_COST := 150

## Commander titles (shown under the name). Conditions are checked in Game.title_unlocked().
const TITLES := [
	{"id": "rookie", "name": "Rookie Commander", "desc": "Begin your journey."},
	{"id": "summoner", "name": "Star Summoner", "desc": "Summon 100 times."},
	{"id": "collector", "name": "Hero Collector", "desc": "Own 15 heroes."},
	{"id": "beloved", "name": "Beloved Commander", "desc": "Reach max Bond with any hero."},
	{"id": "oathbound", "name": "Oathbound", "desc": "Take an Oath with any hero."},
	{"id": "eclipse", "name": "Eclipse Breaker", "desc": "Clear Arc 1 (Chapter 6)."},
	{"id": "second", "name": "Dawn of the Second Sun", "desc": "Clear Arc 2 (Chapter 10)."},
	{"id": "time", "name": "Keeper of the Hour", "desc": "Clear Arc 3 (Chapter 14)."},
	{"id": "light", "name": "The Last Light", "desc": "Clear Arc 4 (Chapter 18)."},
	{"id": "starbound", "name": "Starbound Commander", "desc": "Clear Arc 5 (Chapter 22)."},
	{"id": "second_oath", "name": "Keeper of the Second Oath", "desc": "Clear Arc 6 (Chapter 26)."},
	{"id": "limitless", "name": "Limitless", "desc": "Limit Break any hero to the maximum (Lv.100)."},
	{"id": "abaddon", "name": "Hero of Abaddon", "desc": "Clear Arc 7 (Chapter 30)."},
	{"id": "homebody", "name": "Homebody", "desc": "Unlock every Private Room."},
	{"id": "mirror_master", "name": "Mirror Master", "desc": "Clear 30 Hero Trial tiers."},
	{"id": "hunter", "name": "Apex Hunter", "desc": "Defeat any Boss Hunt target on ABYSS difficulty."},
	{"id": "tower", "name": "Tower Conqueror", "desc": "Reach Tower floor 30."},
	{"id": "arena", "name": "Arena Champion", "desc": "Reach 1,500 Arena RP."},
	{"id": "slayer", "name": "Colossus Slayer", "desc": "Deal 1,000,000 damage to a World Boss in one week."},
	{"id": "tactician", "name": "Grand Tactician", "desc": "Raise any Commander Tactic to Lv.5."},
]

const BANNERS := [
	{"id": "nov4b_luby", "name": "Mecha Cat Rate-Up", "featured": "luby", "desc": "NEW! Luby rate UP! 50% of SSR pulls are Luby.", "bg": "bigtree"},
	{"id": "nov4_mei", "name": "Crimson Bunny Rate-Up", "featured": "mei", "desc": "NEW! Mei rate UP! 50% of SSR pulls are Mei. Tap the art!", "bg": "hell",
		"img": ["res://art/banners_event/banner_bunny_1.png", "res://art/banners_event/banner_bunny_2.png", "res://art/banners_event/banner_bunny_3.png"]},
	{"id": "nov4_kara", "name": "Phoenix Reaper Rate-Up", "featured": "kara", "desc": "NEW! Kara rate UP! 50% of SSR pulls are Kara.", "bg": "dragonfire",
		"img": ["res://art/banners_event/banner_scythe_1.png"]},
	{"id": "nov4_angela", "name": "Seraph Rate-Up", "featured": "angela", "desc": "NEW! Angela rate UP! 50% of SSR pulls are Angela.", "bg": "asgard"},
	{"id": "pickup_sven", "name": "Wanderer's Pick-Up", "featured": "sven", "desc": "Sven rate UP! 50% of R pulls are Sven — and Spark him at 150 points.", "bg": "battle",
		"img": ["res://art/banners_event/banner_sven_1.png"]},
	{"id": "nov2026", "name": "Lion Queen Rate-Up", "featured": "abadonia", "desc": "NEW! Abadonia rate UP! 50% of SSR pulls are Abadonia.", "bg": "boss"},
	{"id": "nov2026b", "name": "Dragon Princess Rate-Up", "featured": "zennyo", "desc": "NEW! Zennyo Ryuo rate UP! 50% of SSR pulls are Zennyo.", "bg": "hell",
		"img": ["res://art/banners_event/banner_dragon_1.png"]},
	{"id": "limited", "name": "Pandemonium Rate-Up", "featured": "xylia", "desc": "Xylia rate UP! 50% of SSR pulls are Xylia.", "bg": "galaxy"},
	{"id": "limited2", "name": "Dragon Flame Rate-Up", "featured": "shina", "desc": "Shina rate UP! 50% of SSR pulls are Shina.", "bg": "hell"},
	{"id": "standard", "name": "Standard Summon", "featured": "", "desc": "All heroes. SSR 3% • SR 15% • R 82%.", "bg": "asgard"},
]

# ---------------------------------------------------------------- equipment
const GEAR_SLOTS := ["weapon", "armor", "accessory"]
const GEAR_MAX_LV := 10
const GEAR := {
	"weapon": {"icon": "gear_weapon", "names": {"R": "Iron Blade", "SR": "Runic Saber", "SSR": "Eclipse Fang"}, "atk": {"R": 0.06, "SR": 0.10, "SSR": 0.16}},
	"armor": {"icon": "gear_armor", "names": {"R": "Leather Mail", "SR": "Mythril Plate", "SSR": "Aegis of Dawn"}, "hp": {"R": 0.06, "SR": 0.10, "SSR": 0.16}, "def": {"R": 0.04, "SR": 0.07, "SSR": 0.11}},
	"accessory": {"icon": "gear_relic", "names": {"R": "Copper Ring", "SR": "Moon Pendant", "SSR": "Star Sigil"}, "all": {"R": 0.03, "SR": 0.05, "SSR": 0.08}},
}

## ---- Gear sets: 2 pieces = stat bonus, 3 pieces = a battle effect (BattleSim reads unit.sets).
const GEAR_SETS := {
	"inferno": {"name": "Flame Pact", "color": "#ff7a3d", "two": {"atk": 0.08}, "two_text": "ATK +8%", "three_text": "Skills also inflict Burn"},
	"tidal": {"name": "Tidecaller", "color": "#5fc8ff", "two": {"hp": 0.10}, "two_text": "HP +10%", "three_text": "Recover 6% HP at the end of every round"},
	"aegis": {"name": "Bastion", "color": "#ffd479", "two": {"def": 0.10}, "two_text": "DEF +10%", "three_text": "Start each battle with a 15% HP Shield"},
	"swift": {"name": "Gale Fang", "color": "#8fffb0", "two": {"crit": 0.06}, "two_text": "Crit +6%", "three_text": "Critical hits deal +30% damage"},
	"vampire": {"name": "Crimson Thirst", "color": "#ff5c8a", "two": {"atk": 0.05, "hp": 0.05}, "two_text": "ATK +5%, HP +5%", "three_text": "Heal 12% of the damage you deal"},
}
const GEAR_SET_IDS := ["inferno", "tidal", "aegis", "swift", "vampire"]
## ---- Forge: embers from salvage pay for Reforging; 3 of a rarity fuse into the next one.
const GEAR_EMBERS := {"R": 2, "SR": 6, "SSR": 20}
const REFORGE_COST := {"R": 4, "SR": 12, "SSR": 30}
const GEAR_NEXT := {"R": "SR", "SR": "SSR"}
const FUSE_GOLD := {"R": 5000, "SR": 30000}
const ARMORY_GEAR := ["R", "R", "SR", "SR", "SR"]   # guaranteed drop per difficulty
## ---- Gear substats: extra random stats on every piece. A sub is {k: stat, q: roll 0..1, up: upgrades}.
const GEAR_SUB_KEYS := ["hp", "atk", "def", "crit"]
const GEAR_SUB_MAX := {"hp": 0.02, "atk": 0.016, "def": 0.02, "crit": 0.01}   # value of a perfect roll
const GEAR_SUB_COUNT := {"R": 1, "SR": 2, "SSR": 3}
const GEAR_SUB_UP_LV := [5, 10]     # enhance levels that upgrade one random substat
const GEAR_SUB_UP := 0.5            # +50% of the rolled value per upgrade
const TEMPER_COST := {"R": 3, "SR": 8, "SSR": 20}   # doubled for every substat kept

## The set the Armory Ruins guarantees today (rotates daily).
static func armory_set(day: int) -> String:
	return GEAR_SET_IDS[posmod(day, GEAR_SET_IDS.size())]

## A gear's set (older gear without one gets a fixed set from its uid).
static func gear_set(g: Dictionary) -> String:
	var st := str(g.get("set", ""))
	return st if GEAR_SETS.has(st) else GEAR_SET_IDS[posmod(int(g.get("uid", 0)), GEAR_SET_IDS.size())]

static func gear_stats(g: Dictionary) -> Dictionary:
	var slot: String = g["slot"]
	var r: String = g["rarity"]
	var m := 1.0 + 0.1 * float(g.get("lv", 0))
	var d: Dictionary = GEAR[slot]
	var out := {"hp": 0.0, "atk": 0.0, "def": 0.0}
	if d.has("atk"):
		out["atk"] += float(d["atk"][r]) * m
	if d.has("hp"):
		out["hp"] += float(d["hp"][r]) * m
	if d.has("def"):
		out["def"] += float(d["def"][r]) * m
	if d.has("all"):
		for k in out.keys():
			out[k] += float(d["all"][r]) * m
	return out

static func gear_name(g: Dictionary) -> String:
	var n: String = GEAR[g["slot"]]["names"][g["rarity"]]
	return n + ("  +%d" % int(g["lv"]) if int(g.get("lv", 0)) > 0 else "")

static func gear_desc(g: Dictionary) -> String:
	var st := gear_stats(g)
	var parts: Array = []
	for k in ["hp", "atk", "def"]:
		if st[k] > 0.0:
			parts.append("%s +%.1f%%" % [k.to_upper(), st[k] * 100.0])
	return "  ".join(parts)

static func gear_score(g: Dictionary) -> float:
	var st := gear_stats(g)
	var sb := gear_sub_totals(g)
	return st["hp"] + sb["hp"] + (st["atk"] + sb["atk"]) * 1.4 + st["def"] + sb["def"] + sb["crit"] * 2.0

static func gear_sub_value(sb: Dictionary) -> float:
	return float(GEAR_SUB_MAX[sb["k"]]) * (0.5 + 0.5 * float(sb["q"])) * (1.0 + GEAR_SUB_UP * int(sb.get("up", 0)))

static func gear_sub_text(sb: Dictionary) -> String:
	var k := str(sb["k"])
	return "%s +%.1f%%" % ["Crit" if k == "crit" else k.to_upper(), gear_sub_value(sb) * 100.0]

## All substats of a piece on one line ("" when it has none).
static func gear_subs_desc(g: Dictionary) -> String:
	var parts: Array = []
	for sb in g.get("subs", []):
		parts.append(gear_sub_text(sb) + ("▲" if int(sb.get("up", 0)) > 0 else ""))
	return "  ".join(parts)

static func gear_sub_totals(g: Dictionary) -> Dictionary:
	var out := {"hp": 0.0, "atk": 0.0, "def": 0.0, "crit": 0.0}
	for sb in g.get("subs", []):
		out[sb["k"]] += gear_sub_value(sb)
	return out

## A fresh substat on a stat not listed in `taken`.
static func roll_gear_sub(taken: Array) -> Dictionary:
	var pool: Array = GEAR_SUB_KEYS.filter(func(k): return not taken.has(k))
	return {"k": pool[randi() % pool.size()], "q": randf(), "up": 0}

static func temper_cost(g: Dictionary, kept: int) -> int:
	return int(TEMPER_COST[g["rarity"]]) << kept

static func gear_enhance_cost(g: Dictionary) -> int:
	return int((1000 + 900 * int(g.get("lv", 0))) * {"R": 1.0, "SR": 1.8, "SSR": 3.0}[g["rarity"]])

# ---------------------------------------------------------------- login calendar
const LOGIN_REWARDS := [
	{"gems": 150, "gold": 20000},
	{"summon_ticket": 3},
	{"gems": 300, "exp_potion": 5},
	{"summon_ticket": 3, "gear_chest": 1},
	{"gems": 450, "skill_book": 2},
	{"summon_ticket": 5, "celestial_gem": 2},
	{"summon_ticket": 10, "gear_chest_ssr": 1},
]

# ---------------------------------------------------------------- limited event
## Limited events rotate every EVENT_DAYS days. DB.EVENT always holds the active one
## (set by Game via set_event_period); edit/add entries freely.
const EVENT_DAYS := 14
const SHOP_LUMEIRA := [
		{"id": "ev_shard", "name": "Lumeira Shard x10", "price": 300, "cur": "festival_token", "give": {"shard:lumeira": 10}, "limit": 8},
		{"id": "ev_ticket", "name": "Summon Ticket", "price": 150, "cur": "festival_token", "give": {"summon_ticket": 1}, "limit": 10},
		{"id": "ev_chest", "name": "Royal Gear Chest", "price": 500, "cur": "festival_token", "give": {"gear_chest_ssr": 1}, "limit": 2},
		{"id": "ev_ring", "name": "Oath Ring", "price": 1500, "cur": "festival_token", "give": {"oath_ring": 1}, "limit": 1},
		{"id": "ev_gems", "name": "300 Gems", "price": 250, "cur": "festival_token", "give": {"gems": 300}, "limit": 5},
		{"id": "ev_stone", "name": "Universal Shard x5", "price": 200, "cur": "festival_token", "give": {"star_stone": 5}, "limit": 5},
	]
const SHOP_ATALANTA := [
		{"id": "ev_shard", "name": "Atalanta Shard x10", "price": 300, "cur": "festival_token", "give": {"shard:atalanta": 10}, "limit": 8},
		{"id": "ev_ticket", "name": "Summon Ticket", "price": 150, "cur": "festival_token", "give": {"summon_ticket": 1}, "limit": 10},
		{"id": "ev_chest", "name": "Royal Gear Chest", "price": 500, "cur": "festival_token", "give": {"gear_chest_ssr": 1}, "limit": 2},
		{"id": "ev_ring", "name": "Oath Ring", "price": 1500, "cur": "festival_token", "give": {"oath_ring": 1}, "limit": 1},
		{"id": "ev_gems", "name": "300 Gems", "price": 250, "cur": "festival_token", "give": {"gems": 300}, "limit": 5},
		{"id": "ev_stone", "name": "Universal Shard x5", "price": 200, "cur": "festival_token", "give": {"star_stone": 5}, "limit": 5},
	]
const SHOP_VEXIRA := [
		{"id": "ev_shard", "name": "Vexira Shard x10", "price": 300, "cur": "festival_token", "give": {"shard:vexira": 10}, "limit": 8},
		{"id": "ev_ticket", "name": "Summon Ticket", "price": 150, "cur": "festival_token", "give": {"summon_ticket": 1}, "limit": 10},
		{"id": "ev_chest", "name": "Royal Gear Chest", "price": 500, "cur": "festival_token", "give": {"gear_chest_ssr": 1}, "limit": 2},
		{"id": "ev_ring", "name": "Oath Ring", "price": 1500, "cur": "festival_token", "give": {"oath_ring": 1}, "limit": 1},
		{"id": "ev_gems", "name": "300 Gems", "price": 250, "cur": "festival_token", "give": {"gems": 300}, "limit": 5},
		{"id": "ev_stone", "name": "Universal Shard x5", "price": 200, "cur": "festival_token", "give": {"star_stone": 5}, "limit": 5},
	]
const SHOP_GEMORA := [
		{"id": "ev_shard", "name": "Gemora Shard x10", "price": 300, "cur": "festival_token", "give": {"shard:gemora": 10}, "limit": 8},
		{"id": "ev_ticket", "name": "Summon Ticket", "price": 150, "cur": "festival_token", "give": {"summon_ticket": 1}, "limit": 10},
		{"id": "ev_chest", "name": "Royal Gear Chest", "price": 500, "cur": "festival_token", "give": {"gear_chest_ssr": 1}, "limit": 2},
		{"id": "ev_ring", "name": "Oath Ring", "price": 1500, "cur": "festival_token", "give": {"oath_ring": 1}, "limit": 1},
		{"id": "ev_gems", "name": "300 Gems", "price": 250, "cur": "festival_token", "give": {"gems": 300}, "limit": 5},
		{"id": "ev_stone", "name": "Universal Shard x5", "price": 200, "cur": "festival_token", "give": {"star_stone": 5}, "limit": 5},
	]
const SHOP_ZENNYO := [
		{"id": "ev_shard", "name": "Zennyo Shard x10", "price": 300, "cur": "festival_token", "give": {"shard:zennyo": 10}, "limit": 8},
		{"id": "ev_ticket", "name": "Summon Ticket", "price": 150, "cur": "festival_token", "give": {"summon_ticket": 1}, "limit": 10},
		{"id": "ev_chest", "name": "Royal Gear Chest", "price": 500, "cur": "festival_token", "give": {"gear_chest_ssr": 1}, "limit": 2},
		{"id": "ev_ring", "name": "Oath Ring", "price": 1500, "cur": "festival_token", "give": {"oath_ring": 1}, "limit": 1},
		{"id": "ev_gems", "name": "300 Gems", "price": 250, "cur": "festival_token", "give": {"gems": 300}, "limit": 5},
		{"id": "ev_stone", "name": "Universal Shard x5", "price": 200, "cur": "festival_token", "give": {"star_stone": 5}, "limit": 5},
	]
const EVENTS := [
	{"name": "Moonlit Festival", "featured": "lumeira", "bg": "aqua",
		"desc": "The butterflies of the reef dance under the full moon. Clear festival stages to earn Event Tokens and trade them for Lumeira shards!",
		"intro": [["lumeira", "The reef is glowing tonight~ The butterflies want to dance with the moon."], ["lumeira", "Will you come? Something big sleeps at the Tidal Shrine... let's not wake it. ...Too late?"]],
		"outro": [["lumeira", "The Queen of the Tide is asleep again. And the moon is so bright~"], ["lumeira", "Thank you for dancing with me, Commander."]],
		"stages": [
			{"name": "Lantern Shore", "level": 4, "pool": ["slime", "ex_nymph"], "count": 3, "tokens": 30},
			{"name": "Coral Parade", "level": 12, "pool": ["slime", "slarkoi", "ex_nymph"], "count": 4, "tokens": 50},
			{"name": "Moonlit Grotto", "level": 22, "pool": ["eroghost", "slarkoi", "gumi_wolf"], "count": 4, "tokens": 80},
			{"name": "Tidal Shrine", "level": 34, "pool": ["evy_blood_sage", "eroghost", "gumi_wolf"], "count": 5, "tokens": 120},
			{"name": "Queen of the Tide", "level": 46, "pool": ["slime", "evy_blood_sage", "ygg_naar"], "count": 5, "tokens": 200, "boss": "slime"},
		],
		"shop": SHOP_LUMEIRA},
	{"name": "Primeval Safari", "featured": "atalanta", "bg": "dino",
		"desc": "The gate to the Primeval Vale is open again! Race through the jungle with Atalanta, collect Event Tokens and trade them for Atalanta shards.",
		"intro": [["atalanta", "Safari time! The dinosaurs are back and they're FAST. Finally, a worthy race!"], ["siv", "C-can I ride one? A small one?"]],
		"outro": [["atalanta", "We outran a Primeval Alpha! Best. Week. Ever."], ["atalanta", "Same time next season, Commander? I'm already stretching."]],
		"stages": [
			{"name": "Fern Trail", "level": 8, "pool": ["ex_nymph", "gumi_wolf"], "count": 3, "tokens": 30},
			{"name": "Waterfall Ford", "level": 16, "pool": ["gumi_wolf", "slime", "ex_nymph"], "count": 4, "tokens": 50},
			{"name": "Thunder Plains", "level": 26, "pool": ["scomantis", "gumi_wolf"], "count": 4, "tokens": 80},
			{"name": "Fossil Cliffs", "level": 38, "pool": ["slarkoi", "gumi_wolf", "ex_nymph"], "count": 5, "tokens": 120},
			{"name": "The Primeval Alpha", "level": 50, "pool": ["gumi_wolf", "slarkoi", "ex_nymph"], "count": 5, "tokens": 200, "boss": "gumi_wolf"},
		],
		"shop": SHOP_ATALANTA},
	{"name": "Necro Masquerade", "featured": "vexira", "bg": "necro",
		"desc": "Vexira is throwing a masked ball in the Necropolis. The guests are... mostly dead. Earn Event Tokens and trade them for Vexira shards.",
		"intro": [["vexira", "Ara~ a masquerade among the tombs. Dress nicely, Commander. The dead are watching."], ["rumi", "I'm charging triple for this. TRIPLE."]],
		"outro": [["vexira", "The last waltz is over. Even the ghosts are smiling~"], ["vexira", "You were the best-dressed guest. ...I'll pretend I didn't pick your mask."]],
		"stages": [
			{"name": "Gate of Masks", "level": 8, "pool": ["eroghost", "slime"], "count": 3, "tokens": 30},
			{"name": "Hall of Candles", "level": 16, "pool": ["voodoo", "eroghost"], "count": 4, "tokens": 50},
			{"name": "The Waltz of Bones", "level": 26, "pool": ["eroghost", "evy_blood_sage", "slarkoi"], "count": 4, "tokens": 80},
			{"name": "Crypt Ballroom", "level": 38, "pool": ["hairly", "eroghost", "ymir"], "count": 5, "tokens": 120},
			{"name": "The Phantom Host", "level": 50, "pool": ["eroghost", "hairly", "ymir"], "count": 5, "tokens": 200, "boss": "eroghost"},
		],
		"shop": SHOP_VEXIRA},
	{"name": "Starport Gala", "featured": "gemora", "bg": "space",
		"desc": "Gemora hosts a gala on the starport to celebrate the rekindled stars. Uninvited guests keep docking. Earn Event Tokens for Gemora shards.",
		"intro": [["gemora", "Gala protocol initiated. Dress code: formal. Weapon code: also formal."], ["xylia", "My starport! Don't scratch anything!"]],
		"outro": [["gemora", "Gala concluded. Satisfaction rating: 98 percent. The remaining 2 percent was the space slime."], ["gemora", "Commander. ...Thank you for the dance. Logging this memory permanently."]],
		"stages": [
			{"name": "Docking Bay", "level": 10, "pool": ["slime", "ex_nymph"], "count": 3, "tokens": 30},
			{"name": "Zero-G Ballroom", "level": 18, "pool": ["slime", "eroghost", "ex_nymph"], "count": 4, "tokens": 50},
			{"name": "Observation Deck", "level": 28, "pool": ["ygg_naar", "eroghost"], "count": 4, "tokens": 80},
			{"name": "Engine Core", "level": 40, "pool": ["svormentis", "ygg_naar", "evy_blood_sage"], "count": 5, "tokens": 120},
			{"name": "The Gatecrasher", "level": 52, "pool": ["slime", "ygg_naar", "eroghost"], "count": 5, "tokens": 200, "boss": "ygg_naar"},
		],
		"shop": SHOP_GEMORA},
	{"name": "Dragonbone Trials", "featured": "zennyo", "bg": "dragonfire",
		"desc": "Zennyo's little dragons must pass their ancient trial in the Dragonbone Caldera. Escort them, earn Event Tokens and trade for Zennyo shards.",
		"intro": [["zennyo", "The little dragons are old enough for the Trial of Embers. I'm... a little nervous."], ["shina", "Relax, sis. Big sister Shina is here. ...And the Commander."]],
		"outro": [["zennyo", "They passed! All of them! Look how proud they are~"], ["zennyo", "Thank you for protecting them, Commander. They want to sleep on your lap now."]],
		"stages": [
			{"name": "Ember Steps", "level": 10, "pool": ["gumi_wolf", "slarkoi"], "count": 3, "tokens": 30},
			{"name": "Ribcage Bridge", "level": 18, "pool": ["gumi_wolf", "evy_blood_sage"], "count": 4, "tokens": 50},
			{"name": "Lava Shelf", "level": 28, "pool": ["serpentia", "skelinch", "gumi_wolf"], "count": 4, "tokens": 80},
			{"name": "Skull of the Elder", "level": 40, "pool": ["evy_blood_sage", "eroghost", "slarkoi"], "count": 5, "tokens": 120},
			{"name": "The Cinder Warden", "level": 52, "pool": ["evy_blood_sage", "gumi_wolf", "slarkoi"], "count": 5, "tokens": 200, "boss": "evy_blood_sage"},
		],
		"shop": SHOP_ZENNYO},
]
static var EVENT: Dictionary = EVENTS[0]

static func set_event_period(period: int) -> void:
	EVENT = EVENTS[posmod(period, EVENTS.size())]

static func event_stage(i: int) -> Dictionary:
	var e: Dictionary = EVENT["stages"][i]
	var rng := RandomNumberGenerator.new()
	rng.seed = 55331 * (i + 1) + hash(str(EVENT["name"]))
	var units: Array = []
	var used: Array = []
	if e.has("boss"):
		units.append({"id": e["boss"], "cell": Vector2i(1, 1), "level": int(e["level"]) + 3, "boss": true})
		used.append(Vector2i(1, 1))
	while units.size() < int(e["count"]):
		var cell := Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
		if used.has(cell):
			continue
		used.append(cell)
		var pool: Array = e["pool"]
		units.append({"id": pool[rng.randi_range(0, pool.size() - 1)], "cell": cell, "level": e["level"], "boss": false})
	return {"index": i, "name": e["name"], "level": e["level"], "enemies": units, "energy": 8, "tokens": e["tokens"], "first_gems": 80 + i * 40}

# ---------------------------------------------------------------- first steps
## New-player path, one step at a time in the lobby goal box. Progress is read from the save.
const FIRST_STEPS := [
	{"id": "mail", "text": "Collect your gifts in the Mailbox", "route": "mail", "give": {"gold": 5000}},
	{"id": "summon", "text": "Summon heroes at the Aether Gate", "route": "gacha", "give": {"gems": 100}},
	{"id": "stage1", "text": "Clear Stage 1-1", "route": "story", "give": {"exp_potion": 2}},
	{"id": "level", "text": "Raise any hero to Lv.5", "route": "hero_detail", "params": {"id": "shina", "tab": "UPGRADE"}, "give": {"gold": 10000}},
	{"id": "bond", "text": "Give Shina a gift in the Bond tab", "route": "hero_detail", "params": {"id": "shina", "tab": "BOND"}, "give": {"bouquet": 3}},
	{"id": "stage3", "text": "Clear Stage 1-3", "route": "story", "give": {"gear:weapon:SR": 1}},
	{"id": "gear", "text": "Equip your new weapon on Shina", "route": "hero_detail", "params": {"id": "shina", "tab": "GEAR"}, "give": {"gems": 150}},
	{"id": "chapter1", "text": "Clear Chapter 1", "route": "story", "give": {"summon_ticket": 2, "gems": 200}},
]

# ---------------------------------------------------------------- first-visit tutorials
const TUTORIALS := {
	"messenger": [["lumeira", "We can text you now! Every day a few of us will send you a message."],
		["lumeira", "Pick a reply. Some answers make us happier than others... and that means more Bond~"]],
	"forge": [["shina", "The Forge! Salvage old gear for Embers, then REFORGE a piece into the set you want."],
		["shina", "FUSE three of a rarity into the next one. And LOCK anything you can't bear to lose~"]],
	"temper": [["shina", "TEMPER rerolls a piece's substats. Keep the ones you like, but each one you keep doubles the price."],
		["shina", "You always get to compare the result, so a bad roll never costs you your old stats~"]],
	"photo": [["mei", "Photo Studio! Pick a model, an outfit and a place. Drag me around, pinch to resize."],
		["mei", "Try a filter and a frame, add a caption, then SNAP. Your shots go into the album~"]],
	"date": [["glytta", "A date! Pick a spot, pick a partner, and answer the way she'd like best~"],
		["glytta", "Perfect dates give the most Bond and a golden photo for your album. Two dates a day!"]],
	"worldboss": [["kali", "A new colossus every week. It can't be killed — just hit it as hard as you can, three times a day."],
		["kali", "Bring heroes of its WEAKNESS element (+30% ATK). Your weekly damage unlocks rewards and sets your rank."]],
	"hunt": [["atalanta", "Boss Hunt! Six astral beasts, four difficulties each. Win once to unlock the next difficulty and SWEEP."],
		["atalanta", "Each target drops something different. Hunt Cores go to Lulu's exchange — and to Limit Break!"]],
	"rift": [["mora", "The Starlight Rift. Climb as high as you can — after every win, choose one Blessing. They stack."],
		["mora", "One defeat ends the run, but your best floor this week is kept. Every fifth floor... someone familiar waits."]],
	"room": [["eurnipha", "Our private room~ Invite anyone, talk, give gifts, or just rest together."],
		["eurnipha", "Each of us has a favourite room — Bond doubles there. Higher Bond unlocks more rooms!"]],
	"festival": [["furu", "A festival changes every month! Win battles to collect Lantern Charms."],
		["furu", "Bring the featured heroes for extra charms, make a daily wish, and trade at the Festival Exchange."]],
	"tactics": [["fidelia", "Commander Tactics fire once per battle when their trigger happens — choose wisely before each fight."],
		["fidelia", "Barrage and Rally win races; Field Medic and Aegis win long battles. Upgrade them with Gold."]],
	"limit_break": [["siv", "6-star and stuck at the level cap? Limit Break! Each step adds +5 levels, up to Lv.100!"],
		["siv", "You'll need Hunt Cores, shards and Gold. The Cinder Witch drops Star Stones that count as shards!"]],
	"formation": [["fidelia", "The glowing column is our FRONT line. Tanks like me stand there. We attack enemies in the SAME ROW."],
		["furu", "Numbers = action order. Tap a hero to see her skill range on the enemy grid!"]],
	"gacha": [["furu", "This is the Aether Gate, where new allies answer your call."],
		["furu", "Every 80 summons guarantees an SSR, and your very first 10x summon always brings one!"],
		["shina", "Duplicates turn into shards. Use them to Star Up. Don't waste them!"]],
	"hero_detail": [["furu", "Here you can raise our Level, Skill and Stars, and equip gear and runes."],
		["furu", "The BOND tab is special. Gifts and Memories bring us closer... and unlock new outfits."],
		["shina", "Try tapping my head, body or legs. ...N-not too much!"]],
	"dungeon": [["lumeira", "Daily dungeons! Gold, EXP or gear, three tries each day."],
		["lumeira", "If you lose, the try comes back. Nothing to fear~"]],
	"arena": [["valeria", "The Arena. Other commanders' teams, controlled by their own strategy."],
		["valeria", "Climb the tiers this week; the season reward depends on where you finish."]],
	"garden": [["glytta", "Our garden! We relax here between battles."],
		["glytta", "Tap us to play — it raises our Bond. And try the Heart Catch mini-game!"]],
	"expedition": [["scylla", "...Send us on expeditions. We bring back loot while you rest."]],
	"guild": [["xylia", "A guild is an alliance. Check in and donate daily — every guild level makes all of us stronger."],
		["xylia", "And the Raid Boss... let's tear it apart together."]],
}

# ---------------------------------------------------------------- runes (Brown Dust style)
const RUNE_SLOTS := 3
const RUNE_MAX_TIER := 5
const RUNES := {
	"atk": {"name": "Fury Rune", "stat": "atk", "per_tier": 0.03, "color": Color("#ff6b5c")},
	"hp": {"name": "Vitality Rune", "stat": "hp", "per_tier": 0.04, "color": Color("#5ce07a")},
	"def": {"name": "Guard Rune", "stat": "def", "per_tier": 0.04, "color": Color("#5fb8ff")},
	"crit": {"name": "Precision Rune", "stat": "crit", "per_tier": 0.025, "color": Color("#ffd479")},
}

static func rune_value(r: Dictionary) -> float:
	return float(RUNES[r["type"]]["per_tier"]) * int(r["tier"])

static func rune_label(r: Dictionary) -> String:
	var d: Dictionary = RUNES[r["type"]]
	return "%s T%d  (+%.1f%% %s)" % [d["name"], int(r["tier"]), rune_value(r) * 100.0, str(d["stat"]).to_upper()]

# ---------------------------------------------------------------- costume / minigame / arena season
static func costume_price(idx: int) -> int:
	return 200 + 120 * idx

## ---- Special skins (Wardrobe-exclusive outfits, state key "special")
const SPECIAL_PRICE := 1280
const SPECIAL_SKINS := {
	"ninger": "Golden Jackpot", "spimei": "Scarlet Overdrive", "luby": "Plush Panther Purr",
}
## Heroes whose special skin was taken out of the game. Saves that bought one get a Skin Ticket back.
const WITHDRAWN_SKINS := ["lucidria", "hyeonxa", "kali", "abadonia"]

## Outfit index of a hero's special skin (-1 if none).
static func special_index(id: String) -> int:
	var states: Dictionary = _entry(base_id(id)).get("char_states", {})
	if not states.has("special"):
		return -1
	var keys: Array = states.keys().filter(func(k): return k != "lobby" and ResourceLoader.exists(str(states[k].get("base", ""))))
	keys.sort_custom(func(a, b): return _state_sort_key(a) < _state_sort_key(b))
	return keys.find("special")

const MINIGAME_REWARD_PLAYS := 3
const MINIGAME_SECONDS := 30
const ARENA_SEASON_DAYS := 7
const ARENA_TIERS := [
	{"name": "LEGEND", "rp": 1600, "give": {"gems": 1200, "summon_ticket": 5, "oath_ring": 1}},
	{"name": "DIAMOND", "rp": 1400, "give": {"gems": 800, "summon_ticket": 3}},
	{"name": "PLATINUM", "rp": 1200, "give": {"gems": 500, "summon_ticket": 2}},
	{"name": "GOLD", "rp": 1050, "give": {"gems": 300, "summon_ticket": 1}},
	{"name": "SILVER", "rp": 950, "give": {"gems": 150, "arena_coin": 200}},
	{"name": "BRONZE", "rp": 0, "give": {"gems": 80, "arena_coin": 100}},
]

static func arena_tier(rp: int) -> Dictionary:
	for t in ARENA_TIERS:
		if rp >= int(t["rp"]):
			return t
	return ARENA_TIERS[-1]

# ---------------------------------------------------------------- collection / garden / expedition
const COLLECTION_PER_HERO := 0.005   # +0.5% HP/ATK/DEF per hero owned
const GARDEN_SLOTS := 6
const GARDEN_TAPS_PER_DAY := 5
const EXPEDITIONS := [
	{"id": "herb", "name": "Herb Gathering", "hours": 1, "heroes": 1, "min_level": 1, "give": {"gold": 6000, "bouquet": 1}},
	{"id": "patrol", "name": "Border Patrol", "hours": 2, "heroes": 2, "min_level": 5, "give": {"hero_exp": 6000, "gold": 8000}},
	{"id": "ruins", "name": "Ancient Ruins Survey", "hours": 4, "heroes": 2, "min_level": 10, "give": {"gear_chest": 1, "skill_book": 1}},
	{"id": "hunt", "name": "Monster Hunt", "hours": 6, "heroes": 3, "min_level": 15, "give": {"gems": 80, "exp_potion": 4}},
	{"id": "rift", "name": "Rift Investigation", "hours": 8, "heroes": 3, "min_level": 25, "give": {"summon_ticket": 1, "gems": 60, "celestial_gem": 1}},
]

# ---------------------------------------------------------------- season pass
const PASS_LEVELS := 30
const PASS_EXP_PER_LV := 200
const PASS_PRICE := 980
const PASS_DAYS := 28
const PASS_EXP := {"stage": 15, "summon": 10, "dungeon": 25, "arena": 25, "guild": 20, "afk": 20, "quest": 60}

static func pass_reward(lv: int, premium: bool) -> Dictionary:
	if not premium:
		if lv % 10 == 0:
			return {"summon_ticket": 2, "gems": 100}
		if lv % 5 == 0:
			return {"skill_book": 2}
		match lv % 3:
			0: return {"gems": 40}
			1: return {"gold": 8000 + lv * 500}
			_: return {"exp_potion": 2}
	if lv == PASS_LEVELS:
		return {"oath_ring": 1, "summon_ticket": 5}
	if lv % 10 == 0:
		return {"gear_chest_ssr": 1, "gems": 300}
	if lv % 3 == 0:
		return {"summon_ticket": 1}
	match lv % 3:
		1: return {"gems": 80}
		_: return {"skill_book": 1, "celestial_gem": 1}

# ---------------------------------------------------------------- daily dungeons
const DUNGEON_TRIES := 3
const DUNGEON_LEVELS := [5, 15, 27, 40, 55]
const DUNGEONS := [
	{"id": "gold", "name": "Golden Vault", "icon": "icon_gold", "bg": "asgard", "pool": ["slime", "slarkoi", "gumi_wolf"],
		"desc": "Greedy guardians hoard treasure. Earn huge amounts of Gold."},
	{"id": "exp", "name": "Crystal Sanctum", "icon": "icon_crystal", "bg": "ice", "pool": ["eroghost", "ex_nymph", "evy_blood_sage"],
		"desc": "Aether crystals grow here. Earn Hero EXP and EXP Potions."},
	{"id": "gear", "name": "Armory Ruins", "icon": "icon_equipment", "bg": "hell", "pool": ["slarkoi", "gumi_wolf", "ygg_naar"],
		"desc": "Ancient forges guarded by beasts. Earn equipment and Gear Chests."},
]

static func dungeon_def(id: String) -> Dictionary:
	for d in DUNGEONS:
		if d["id"] == id:
			return d
	return DUNGEONS[0]

static func dungeon_stage(id: String, diff: int) -> Dictionary:
	var d := dungeon_def(id)
	var lvl: int = DUNGEON_LEVELS[diff]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id) + diff * 7717
	var units: Array = []
	var used: Array = []
	var count := 3 + mini(2, diff)
	if diff >= 2:
		units.append({"id": d["pool"][-1], "cell": Vector2i(1, 1), "level": lvl + 2, "boss": true})
		used.append(Vector2i(1, 1))
	while units.size() < count:
		var cell := Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
		if used.has(cell):
			continue
		used.append(cell)
		var pool: Array = d["pool"]
		units.append({"id": pool[rng.randi_range(0, pool.size() - 1)], "cell": cell, "level": lvl, "boss": false})
	var m := diff + 1
	var rewards := {}
	match id:
		"gold":
			rewards = {"gold": 12000 * m * m}
		"exp":
			rewards = {"hero_exp": 2500 * m * m, "exp_potion": m, "skill_book": 1 + diff / 2}
		"gear":
			rewards = {"gold": 3000 * m, "gear_chest": 1 + diff / 2, "forge_ember": 3 * m}
	return {"id": id, "diff": diff, "level": lvl, "enemies": units, "rewards": rewards, "bg": d["bg"], "name": "%s  Lv.%d" % [d["name"], diff + 1]}

# ---------------------------------------------------------------- bond stories (Sakura Oath "memories")
const BOND_STORY_REQ := [3, 6, 10]
const BOND_STORY_TITLES := ["First Steps", "A Quiet Evening", "Promise Under the Stars"]
const BOND_STORY_REWARDS := [{"gems": 60, "bouquet": 1}, {"gems": 120, "celestial_gem": 1}, {"gems": 250, "summon_ticket": 2}]

static var _voice_json: Dictionary = {}
static var _prof_json: Dictionary = {}

## Story speaker ids may carry a variant prefix ("mirror:", "hollow:", "echo:").
static func base_id(id: String) -> String:
	for p in ["mirror:", "hollow:", "echo:", "ashen:", "feral:"]:
		if id.begins_with(p):
			return id.substr(p.length())
	return id

static var _news_json: Array = []

## Notices shown on the lobby board (edit data/news.json; newest first).
static func news() -> Array:
	if _news_json.is_empty():
		var f := FileAccess.open("res://data/news.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Array:
				_news_json = d
	return _news_json

static func profile(id: String) -> Dictionary:
	if _prof_json.is_empty():
		_prof_json = _load_json("res://data/profiles.json")
	return _prof_json.get(id, {})

## Lobby backgrounds: unlocked by story progress (stages cleared).
const LOBBY_SCENES := [
	{"key": "lobby", "name": "Moonlit Cathedral", "req": 0}, {"key": "forest", "name": "Whispering Woods", "req": 6},
	{"key": "aqua", "name": "Sunken Reef", "req": 12}, {"key": "hell", "name": "Infernal Citadel", "req": 18},
	{"key": "ice", "name": "Frostvale", "req": 24}, {"key": "galaxy", "name": "Void Rift", "req": 30},
	{"key": "asgard", "name": "Celestial Asgard", "req": 36}, {"key": "battle", "name": "Ashen Battlefield", "req": 42},
	{"key": "boss", "name": "Eclipse Citadel", "req": 48}, {"key": "world", "name": "Shattered Continent", "req": 54},
	{"key": "pool", "name": "Poolside Resort", "req": 60}, {"key": "blackmarket", "name": "Night Market", "req": 72},
	{"key": "space", "name": "Starport Horizon", "req": 108}, {"key": "alien", "name": "Mycelia", "req": 114},
	{"key": "blackhole", "name": "Event Horizon", "req": 120}, {"key": "bigtree", "name": "Crown of Yggdrasil", "req": 126},
	{"key": "gameroom", "name": "Commander's Room", "req": 0}, {"key": "room1", "name": "Cozy Bedroom", "req": 12},
	{"key": "room2", "name": "Dragon Bedroom", "req": 30}, {"key": "onsen", "name": "Moonlit Onsen", "req": 48},
	{"key": "abaddon", "name": "Abaddon City", "req": 156}, {"key": "dino", "name": "Primeval Vale", "req": 162},
	{"key": "necro", "name": "Necropolis", "req": 168}, {"key": "apocalypse", "name": "Abaddon Burning", "req": 174},
	{"key": "dragonfire", "name": "Dragonbone Caldera", "req": 132}, {"key": "outland", "name": "The Outland", "req": 144},
]

## Equipped outfit bonus (Brown Dust style costumes): +2% ATK & HP per outfit tier, max +10%.
static func outfit_bonus(skin: int) -> float:
	return minf(0.10, 0.02 * float(skin))
static var _mem_json: Dictionary = {}

static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

## Hero voice line: {"jp": .., "en": .., "path": ..}. Categories: greet, tap, bond, skill, win, summon.
static func voice(id: String, cat: String) -> Dictionary:
	if _voice_json.is_empty():
		_voice_json = _load_json("res://data/voice_lines.json")
	var h: Dictionary = _voice_json.get(id, {})
	var l: Array = h.get("lines", {}).get(cat, [])
	if l.size() < 2:
		var pool: Array = VOICE.get(cat, VOICE["tap"])
		return {"jp": "", "en": str(HERO_LINES.get(id, pool[0])) if cat == "greet" else str(pool[randi() % pool.size()]), "path": ""}
	return {"jp": l[0], "en": l[1], "path": "res://audio/voice/%s_%s.wav" % [id, cat]}

static func _memories(id: String) -> Array:
	if _mem_json.is_empty():
		_mem_json = _load_json("res://data/memories.json")
	return _mem_json.get(id, [])

static func bond_story_title(id: String, ep: int) -> String:
	var m := _memories(id)
	if ep < m.size():
		return str(m[ep].get("title", BOND_STORY_TITLES[ep]))
	return BOND_STORY_TITLES[ep]

static func bond_story(id: String, ep: int) -> Array:
	var m := _memories(id)
	var lines: Array = (m[ep].get("lines", []) if ep < m.size() else _bond_story_template(id, ep)).duplicate(true)
	if lines.size() >= 2:
		lines.insert(lines.size() - 1, choice_line(id, MEMORY_CHOICES[ep % MEMORY_CHOICES.size()]))
	return lines

# ---------------------------------------------------------------- approach / dating
## What a hero responds to best: 0 = kindness/protection, 1 = training together, 2 = her powers/curiosity.
static func liking(id: String) -> int:
	var r := role_of(id)
	if r in ["TANK", "PALADIN", "KNIGHT", "HEALER", "BUFFER"]:
		return 0
	if r in ["WARRIOR", "ASSASSIN", "RANGER"]:
		return 1
	return 2

const MEMORY_CHOICES := [
	["\"You can always rely on me.\"", "\"Want to train together later?\"", "\"Tell me more about your power.\""],
	["\"You look beautiful tonight.\"", "\"Let's spar at dawn tomorrow.\"", "\"Could you show me a spell?\""],
	["\"I'll protect you, always.\"", "\"Let's grow stronger together.\"", "\"Your power amazes me.\""],
]
const TALK_TOPICS := [
	["What should I do on my day off, Commander?", ["\"Rest. You deserve it.\"", "\"Train with me!\"", "\"Study something new.\""]],
	["Do you think I'm strong enough?", ["\"You're strong because you care.\"", "\"Stronger than anyone I know.\"", "\"Your talent is incredible.\""]],
	["What kind of present would you give me?", ["\"Flowers, picked by me.\"", "\"A new weapon.\"", "\"An ancient grimoire.\""]],
	["The night sky is pretty, isn't it?", ["\"Not as pretty as you.\"", "\"Perfect for a night run!\"", "\"Do you know the constellations?\""]],
	["I made a mistake in the last battle...", ["\"Everyone makes mistakes. I've got you.\"", "\"Let's drill it until it's perfect.\"", "\"What did you learn from it?\""]],
	["Will you stay a little longer today?", ["\"As long as you want.\"", "\"Only if you race me back!\"", "\"Tell me a story and I'll stay.\""]],
]

## Builds a choice line ["?", id, options, replies, bond gains] tuned to the hero's personality.
static func choice_line(id: String, opts: Array, scale: float = 1.0) -> Array:
	var fav := liking(id)
	var gains: Array = []
	var replies: Array = []
	for k in opts.size():
		var g := 40 if k == fav else (20 if (k + 1) % 3 == fav else 10)
		gains.append(int(g * scale))
		var cat := "bond" if k == fav else ("greet" if (k + 1) % 3 == fav else "tap")
		replies.append(str(voice(id, cat)["en"]))
	return ["?", id, opts, replies, gains]

## Each hero has one favourite gift (x2 Bond EXP).
const GIFTS := ["bouquet", "sweet_cake", "perfume", "celestial_gem"]
static func fav_gift(id: String) -> String:
	return GIFTS[absi(hash(id)) % GIFTS.size()]

static func _bond_story_template(id: String, ep: int) -> Array:
	var n := name_of(id)
	var title := title_of(id).to_lower()
	var line: String = HERO_LINES.get(id, "I'm glad you're here.")
	match ep:
		0:
			return [[id, "Commander, do you have a moment? I... wanted to talk."],
				["commander", "Of course. What's on your mind, %s?" % n],
				[id, "Everyone calls me the %s. Sometimes the title feels heavier than my weapon." % title],
				[id, "But when we fight side by side, I forget about it. I'm just... me."],
				["commander", "Then just be you. That's who I trust."],
				[id, line]]
		1:
			return [[id, "Oh, you came! I was hoping you'd find me here."],
				[id, "The camp is so quiet tonight. No battles, no orders... just the wind."],
				["commander", "You seem calmer than usual."],
				[id, "Hehe, maybe that's your fault. You make it easy to relax."],
				[id, "Say, Commander... after the Eclipse is gone, will you still need me?"],
				["commander", "I'll always need you."],
				[id, "...Then I'll keep getting stronger. For you."]]
		_:
			return [[id, "Look up, Commander. Every star feels close tonight."],
				[id, "I've fought for so long, I forgot what I was fighting for."],
				[id, "Now I know. It's this moment. It's you."],
				["commander", "%s..." % n],
				[id, "Promise me something. No matter how dark it gets, don't let go of my hand."],
				["commander", "I promise."],
				[id, "Then I swear it too. Forever and always, Commander. ♥"]]

# ---------------------------------------------------------------- guild
const GUILD_MAX_LV := 10
const GUILDS := [
	{"name": "Eclipse Vanguard", "desc": "Top raiders. Daily raid attacks expected.", "lv": 6},
	{"name": "Moonlight Garden", "desc": "Casual & friendly. Bond lovers welcome!", "lv": 3},
	{"name": "Abyssal Covenant", "desc": "Tower climbers and arena grinders.", "lv": 5},
]
const FRIEND_NAMES := ["Hana", "Daichi", "Mei", "Riku", "Sakura", "Yuki", "Haru", "Kaede", "Ayame", "Toma"]
const MEMBER_NAMES := ["Rinne", "Kaito", "Yuzu", "Hikari", "Aria", "Zero", "Mochi", "Seren", "Kuro", "Akane", "Nova", "Ren", "Luna", "Sora"]

# ------------------------------------------------------------------ Hairly's Fortune (lobby NPC)
const HAIRLY_PIVOTS := {"eye_l": Vector2(0.458, 0.164), "eye_r": Vector2(0.539, 0.162), "eye_size": Vector2(0.022, 0.0048),
	"mouth": Vector2(0.502, 0.254), "mouth_size": Vector2(0.014, 0.0012), "neck": Vector2(0.52, 0.29), "hand": Vector2(0.33, 0.26),
	"chest": Vector2(0.52, 0.40), "hips": Vector2(0.55, 0.60), "hair_band": Vector2(0.2, 0.78)}
const GRAFITY_PIVOTS := {"eye_l": Vector2(0.459, 0.230), "eye_r": Vector2(0.574, 0.228), "eye_size": Vector2(0.026, 0.0075),
	"mouth": Vector2(0.519, 0.297), "mouth_size": Vector2(0.017, 0.0016), "neck": Vector2(0.52, 0.34), "chest": Vector2(0.50, 0.47),
	"hand": Vector2(0.47, 0.90), "hips": Vector2(0.50, 0.60), "hair_band": Vector2(0.18, 0.70),
	"flames": [Vector3(0.40, 0.08, 0.05), Vector3(0.63, 0.08, 0.05), Vector3(0.22, 0.67, 0.07),
		Vector3(0.68, 0.80, 0.05), Vector3(0.36, 0.87, 0.045), Vector3(0.58, 0.87, 0.045)]}
## Commander Road: one reward per milestone of Player level (big ones every 25 levels).
static func road_levels() -> Array:
	var out: Array = []
	for lv in range(5, 101, 5):
		out.append(lv)
	return out

static func road_reward(lv: int) -> Dictionary:
	if lv % 50 == 0:
		return {"gems": 300 + lv * 4, "summon_ticket": 3 + lv / 25, "celestial_gem": 1, "skin_ticket": 1}
	if lv % 25 == 0:
		return {"gems": 300 + lv * 4, "summon_ticket": 3 + lv / 25, "celestial_gem": 1}
	if lv % 10 == 0:
		return {"gems": 150, "summon_ticket": 1}
	return {"gems": 60 + lv, "gold": 5000 * lv / 5}

## Bestiary: kill milestones per enemy type (rewards claimed once each).
const BESTIARY_TIERS := [
	{"kills": 10, "give": {"gems": 30}}, {"kills": 50, "give": {"gems": 60, "gold": 20000}},
	{"kills": 150, "give": {"summon_ticket": 1}}, {"kills": 400, "give": {"celestial_gem": 1, "gems": 100}},
]
## ---- Taming (Bestiary): defeat enough of a foe, then tame her and grow a bond like a hero.
const TAME_KILLS := 20
const TAME_GOLD := 10000
const PET_MAX_BOND := 10
const PET_PATS_PER_DAY := 5
const COMPANION_PER_BOND := 0.005
## extra forms (evolutions) of a foe: index k unlocks at FORM_KILLS[k] kills OR pet bond FORM_BOND[k]
const FORM_KILLS := [1, 30, 80, 160, 300, 500, 800, 1200]
const FORM_BOND := [0, 2, 4, 6, 8, 9, 10, 10]
const PET_REWARDS := {3: {"gems": 50}, 5: {"gems": 80, "gold": 20000}, 7: {"summon_ticket": 1}, 10: {"gems": 200, "celestial_gem": 1}}
## personality per foe: [greeting when tamed, talk lines..., gift thanks, pat reaction]
const PET_LINES := {
	"eroghost": ["...You see me? Nobody ever sees me. Fine. I'll haunt YOU now.", "I used to rattle chains at travellers. Now I rattle them at your door. Progress.", "Ghosts don't sleep. I just watch you sleep. ...Is that weird?", "Warm hands. Ugh. Do it again.", "Ooh, a gift! I'll keep it forever. Literally forever."],
	"evy_blood_sage": ["A commander who tames witches... how delightfully reckless.", "My spells drink blood. I prefer tea, honestly. Bitter, like me.", "Stay still. I'm reading your fate in the candle wax. ...You'll spoil me rotten.", "Mm. Your touch is warmer than any blood rite.", "A present? You do know how to court a witch."],
	"gumi_wolf": ["Awoo! Nine tails, one master. Pet me. Now.", "I can smell the moon from here. And snacks. Mostly snacks.", "If you scratch behind my ears, I'll chase every monster away. Deal?", "Yes— right there— oh, my tails are wagging, don't look!", "Food! You brought food! Best master!"],
	"slarkoi": ["Grrr... wrapped in bandages for three thousand years, and YOU unwrap my heart?", "The crypt was quiet. Your camp is loud. ...I like loud.", "My bandages are clean today. I washed them. For you. Don't make it weird.", "Careful, I'm fragile. Three thousand years fragile.", "Treasure! A pharaoh's tribute! ...It's a cake. I'll take it."],
	"ygg_naar": ["The Primordial Eye opens... and sees only you.", "I have watched the stars be born. You are... more interesting.", "Blink twice if you love me. ...I only have one eye. I blinked once. Decide.", "My eye waters when you pat me. It is not crying. It is dew.", "A gift for the Eye. It shall be watched over for eternity."],
	"ex_nymph": ["The forest cast me out. ...Will you let me grow here instead?", "Flowers bloom where I step. Thorns too. Watch your feet.", "Talk to me like you talk to plants. Slowly. Kindly.", "Leaves rustle when I'm happy. Listen.", "For me? ...I'll plant it. It will grow into something beautiful."],
	"slime": ["Blorp! The Queen of Jelly accepts your service! ...I mean, your friendship.", "I can be any shape you want. A heart? There. Blorp.", "Poke me. Go on. Jiggle. Ehehe.", "Squish squish! More!", "I'll absorb it! In the cute way. Thank you!"],
	"hairly": ["My hair has bound kings... and it chose you. Lucky.", "I braid fortunes into my tresses. Yours keeps tangling with mine.", "Brush my hair a hundred times and I'll tell you a secret.", "Gently... my hair has feelings. So do I.", "Oh, a ribbon-worthy gift. You may stay."],
	"svormentis": ["THE MAW HUNGERS. ...For conversation, apparently.", "I devoured a mountain once. I regret nothing. It was crunchy.", "Speak. My teeth are listening.", "I am purring. Maws can purr. Do not question it.", "TRIBUTE. ACCEPTED. MOST DELICIOUS."],
	"ymir": ["The Bone Queen kneels to no one. ...Sit with me instead.", "My throne is cold. Your camp fire is not. I'll allow it.", "Count my bones and you'll find one cracked. You did that. Heart-shaped.", "Your warmth reaches even bone. How irritating. Continue.", "A queen's offering. I shall wear it on my crown."],
	"scomantis": ["Click-click. My stinger is sheathed. For now. For you.", "Emerald venom, emerald eyes, emerald heart. Don't step on it.", "I molt when I'm nervous. ...I have molted twice today.", "Click! ...That tickles, stop. No, don't stop.", "A gift? I'll hoard it with my shinies."],
	"skelinch": ["Yo. Hellfire Punk, at your service. Don't make it lame.", "I punch demons for fun. I'll punch yours. For free.", "My gauntlets are on fire. My heart? Eh. Smouldering.", "Heh. Head-pats. So uncool. ...Again.", "Ooh, shiny. You got taste, boss."],
	"serpentia": ["Sssso you are the one who calmed the flame-scales. Interesting.", "My coils are warm. Rest on them if you like. I won't squeeze. Much.", "Lamias shed their skin every spring. I shed my pride for you.", "Hsss... your hand is cool on my scales. Perfect.", "A treasure for my hoard. You may coil beside it."],
	"voodoo": ["Stitched together and stitched to you. Funny, isn't it?", "I dance when the strings pull. Lately, they pull toward you.", "Don't poke the pins. ...Okay, you can poke one.", "Soft hands... my stitches are loosening. That's a good thing.", "A gift! I'll sew it into my heart pocket."],
	"lizamorph": ["...crawls closer... ...stays.", "The shadows under your bed? Me. I'm guarding you.", "I don't talk much. I listen. You talk. I like your voice.", "...(happy shadow noises)...", "...for me? ...(shadow curls around it protectively)."],
}

const PET_STORY_REQ := [3, 6, 10]
const PET_STORY_TITLES := ["Off the Battlefield", "What I Used to Be", "A Promise Under Stars"]
const PET_STORY_REWARDS := [{"gems": 50}, {"gems": 80, "gold": 30000}, {"gems": 120, "celestial_gem": 1}]

## Bond episode lines for a tamed foe, built from her personality lines and title.
static func pet_story(id: String, ep: int) -> Array:
	var n := name_of(id)
	var title := title_of(id).to_lower()
	match ep:
		0:
			return [["nar", "%s lingers at the edge of camp, half in the firelight, half in the dark." % n],
				[id, pet_line(id, 1)],
				["commander", "You don't have to stand out there. There's room by the fire."],
				[id, "...Room. For a monster. You're strange, Commander."],
				[id, pet_line(id, 2)],
				["nar", "She sits down. A little closer than she meant to."]]
		1:
			return [[id, "Do you know why I fought you? Because the %s is all anyone ever let me be." % title],
				["commander", "And what do you want to be?"],
				[id, "...I don't know yet. Nobody ever asked."],
				["commander", "Then take your time. I'm not going anywhere."],
				[id, pet_line(id, 3)],
				["nar", "For the first time, %s doesn't look like she's waiting for a fight." % n]]
		_:
			return [["nar", "Late at night, the camp asleep. Two shadows under a sky full of stars."],
				[id, "I used to count the days until someone came to defeat me."],
				[id, "Now I count the days I get to spend beside you."],
				["commander", "Then let's make the count very, very long."],
				[id, pet_line(id, 4)],
				[id, "This is a promise, Commander. From %s — not the %s. Just me." % [n, title]]]

static func pet_line(id: String, slot: int) -> String:
	var l: Array = PET_LINES.get(id, ["...", "...", "...", "...", "..."])
	return str(l[clampi(slot, 0, l.size() - 1)])

static func pet_bond_next(lv: int) -> int:
	return 40 + lv * 30

const FORTUNES := [
	{"card": "THE STAR", "text": "Hope rises with the dawn. A small gift falls into your hands.", "give": {"gems": 40}},
	{"card": "THE SUN", "text": "Golden light on every road you walk today.", "give": {"gold": 15000}},
	{"card": "THE LOVERS", "text": "Someone close to you is thinking of you. Answer her.", "give": {"bouquet": 1, "sweet_cake": 1}},
	{"card": "THE CHARIOT", "text": "Victory favours the bold. March on without fear.", "give": {"energy": 30}},
	{"card": "THE HERMIT", "text": "Wisdom is found in quiet study.", "give": {"exp_potion": 3}},
	{"card": "WHEEL OF FORTUNE", "text": "The wheel turns. Luck is a summon away.", "give": {"summon_ticket": 1}},
	{"card": "THE MOON", "text": "Shadows hide treasures. Hunt in the dark corners.", "give": {"hunt_core": 10}},
]

# ------------------------------------------------------------------ Secretary Moments
## Once a day the lobby hero has a small personal moment (tap the heart near her).
const SECRETARY_MOMENTS := [
	{"lines": ["Commander! I made you lunch. Don't make that face — it's edible. ...Probably.", "Say 'aah'. I'm not leaving until you take one bite."],
		"opts": ["It's delicious!", "...Is this burnt?", "Let's eat together."], "give": {"energy": 20}},
	{"lines": ["Look what I found on the cathedral steps — a lucky coin! Shiny, isn't it?", "You keep it. Luck suits you better than me."],
		"opts": ["Then we'll share the luck.", "Thank you, really.", "Is this a bribe?"], "give": {"gold": 8000}},
	{"lines": ["These flowers bloomed this morning, so I picked one for your desk.", "...Don't read into it. It's just a flower. A pretty one."],
		"opts": ["It's beautiful. Like you.", "I'll keep it in water.", "Did you pick it for me specially?"], "give": {"bouquet": 1}},
	{"lines": ["I trained all night so I can protect you better today.", "...I'm fine. I'm not sleepy. Why are you looking at me like that?"],
		"opts": ["Go rest. That's an order.", "Thank you for working so hard.", "Let's train together next time."], "give": {"hero_exp": 3000}},
	{"lines": ["Someone left this letter on your desk. It smells like perfume. Hmph.", "...I didn't read it. Much."],
		"opts": ["Are you jealous?", "Read it with me.", "It's probably from the guild."], "give": {"gems": 30}},
	{"lines": ["Shh... I'm not asleep. I'm guarding your chair. With my eyes closed.", "...Five more minutes. Then I'll guard it with my eyes open."],
		"opts": ["Sleep. I'll guard you instead.", "*cover her with a blanket*", "Your hair's sticking up."], "give": {"energy": 10, "gold": 3000}},
	{"lines": ["It's raining. Do you want to just... stay in today? We could read.", "I picked a book. It's a romance. That's a coincidence."],
		"opts": ["I'd love that.", "What kind of romance?", "Coincidence, huh?"], "give": {"exp_potion": 2}},
]

# ------------------------------------------------------------------ Dates (Sakura Oath style)
## Each spot: 3 beats, each = [narration, hero line, [3 options]]. "{n}" = hero's first name.
## The option matching the hero's taste (DB.liking) scores best.
const DATE_PER_DAY := 2
const DATE_BOND := 3
const DATE_SPOTS := [
	{"key": "forest", "name": "Picnic in the Whispering Woods", "req": 0, "beats": [
		["You spread a blanket under the old oak. {n} sets down a basket that is suspiciously heavy.", "I made everything myself. ...Don't ask what the purple one is.",
			["I'll try the purple one first.", "Let's eat together, slowly.", "You cooked? I'm impressed."]],
		["A fox spirit creeps up and steals a sandwich. {n} laughs harder than you've ever heard.", "Did you see its face? It looked so proud!",
			["Let's share with it.", "I'll protect our lunch!", "Your laugh is cute."]],
		["The sun dips low. {n} leans against your shoulder, pretending to be sleepy.", "...Can we stay a little longer?",
			["As long as you want.", "Five more minutes. Then I carry you.", "I was hoping you'd ask."]]]},
	{"key": "pool", "name": "Afternoon at the Poolside Resort", "req": 60, "beats": [
		["Xylia's resort sparkles. {n} appears in a brand-new swimsuit and freezes when she sees you looking.", "D-don't stare! ...Is it weird?",
			["It suits you perfectly.", "Race you to the far end!", "I wasn't staring. Much."]],
		["{n} splashes you, then immediately regrets it as you splash back.", "That's cheating! You're way too strong!",
			["Truce! Shaved ice is on me.", "Never surrender!", "You started it~"]],
		["Floating side by side, you watch clouds drift past.", "That one looks like you. ...The grumpy part.",
			["And that one's you, smiling.", "I'm not grumpy!", "Let's float here all day."]]]},
	{"key": "onsen", "name": "Moonlit Onsen", "req": 48, "beats": [
		["Steam curls over the water. From the other side of the bamboo fence, {n}'s voice.", "C-Commander? Is that you over there?",
			["Just me. Relax.", "Want me to leave?", "The moon's beautiful tonight."]],
		["{n} tosses a small wooden bucket over the fence. It has a note: 'Warm milk. Drink it.'", "Did it land? Did I hit you? Sorry!",
			["Bullseye. Thank you.", "It hit my head. It's fine.", "You're sweet, you know that?"]],
		["Later, on the veranda in yukata, {n} sits a little closer than usual.", "...The onsen made me brave. Don't get used to it.",
			["I'll treasure it anyway.", "Then let's come back often.", "You look lovely in a yukata."]]]},
	{"key": "blackmarket", "name": "Night Market Stroll", "req": 72, "beats": [
		["Lanterns sway over Lulu's night market. {n} is drawn to a stall full of glittering trinkets.", "This hairpin... no, it's too expensive. Forget it.",
			["I'll buy it for you.", "Let's find something we both like.", "It would look great on you."]],
		["A fortune-telling booth. Hairly peers at you both and smirks.", "What did she say? Why are you blushing?!",
			["She said we're a good match.", "...It's a secret.", "Something about a long future."]],
		["Fireworks burst over the market. {n} grabs your sleeve without thinking.", "...I'm not scared. I just wanted to hold on.",
			["Then hold on.", "I've got you.", "I wanted to hold on too."]]]},
	{"key": "space", "name": "Starport Observation Deck", "req": 108, "beats": [
		["Through the great window, a sea of stars. Somewhere out there, Noctis blinks.", "It's waving at us. ...I think it approves.",
			["Wave back together?", "Approves of what, exactly?", "It's not as bright as you."]],
		["{n} points out constellations she invented on the spot.", "That one is 'The Commander Falling Asleep in Meetings'.",
			["Hey, that's slander!", "Show me yours next.", "Name one after us."]],
		["The starport hums. The two of you sit in comfortable silence.", "...I like quiet moments like this. With you.",
			["Me too.", "Let's make more of them.", "Thank you for coming."]]]},
	{"key": "bigtree", "name": "Canopy of Yggdrasil", "req": 126, "beats": [
		["Bridges of living wood sway between golden leaves. {n} holds the rope a little tighter.", "It's so high. ...Don't let go of my hand, okay?",
			["Never.", "I'll carry you if you want.", "The view's worth it."]],
		["You find a hollow full of glowing seeds. Each one hums a different note.", "If we plant one, maybe it'll grow into our own tree.",
			["Let's plant it together.", "We'll come back to check on it.", "What will we name it?"]],
		["At the crown, the new sun is setting. {n} turns to you, golden light on her face.", "Commander. Today was... the best day.",
			["Every day can be like this.", "I'll remember it forever.", "It's not over yet."]]]},
]
const DATE_RANKS := [["PERFECT DATE", 100, "#ffd479"], ["SWEET DATE", 70, "#ff8fb8"], ["NICE DATE", 0, "#9fd0ff"]]

static func date_spot(key: String) -> Dictionary:
	for d in DATE_SPOTS:
		if d["key"] == key:
			return d
	return DATE_SPOTS[0]

# ------------------------------------------------------------------ Hero Trials
## Personal challenge per hero: she must be deployed AND survive. The boss is her own Mirror.
const TRIAL_TIERS := [
	{"name": "Trial I", "lv": 18, "star": 2, "give": {"gems": 60}, "shards": 10},
	{"name": "Trial II", "lv": 45, "star": 4, "give": {"gems": 120, "gold": 30000}, "shards": 15},
	{"name": "Trial III", "lv": 78, "star": 6, "give": {"gems": 200, "star_stone": 10}, "shards": 25},
]
const ELEM_BG := {"FIRE": "hell", "WATER": "aqua", "WIND": "forest", "EARTH": "dino", "LIGHT": "asgard", "DARK": "necro"}

static func trial_stage(id: String, tier: int) -> Dictionary:
	var t: Dictionary = TRIAL_TIERS[tier]
	var grp: String = ELEMENT_GROUP.get(element_of(id), "LIGHT")
	# foes whose element beats hers — a real test
	var strong: Array = []
	for e in ENEMIES.keys():
		if ELEMENT_BEATS.get(ELEMENT_GROUP.get(element_of(e), ""), "") == grp:
			strong.append(e)
	if strong.is_empty():
		strong = ENEMIES.keys()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id + str(tier))
	var units: Array = [{"id": id, "cell": Vector2i(1, 1), "level": int(t["lv"]) + 2, "boss": true, "star": int(t["star"]), "elite": true,
		"mirror": true, "variant": "mirror", "hp_mult": 2.2, "atk_mult": 1.1}]
	var cells := [Vector2i(0, 0), Vector2i(0, 2), Vector2i(2, 1), Vector2i(0, 1)]
	for i in 2 + tier:
		units.append({"id": strong[rng.randi() % strong.size()], "cell": cells[i], "level": int(t["lv"]), "boss": false, "star": int(t["star"]), "elite": tier >= 2})
	return {"name": "%s: %s" % [t["name"], name_of(id).split(" ")[0]], "enemies": units, "bg": ELEM_BG.get(grp, "battle"), "level": t["lv"]}

# ------------------------------------------------------------------ Private Room
## Invite a hero to a private space. Rooms unlock by your highest Bond with any hero.
const ROOM_VISITS := 5
const ROOMS := [
	{"key": "gameroom", "name": "Commander's Room", "bond": 1, "lines": [
		"So this is where you plan our battles? ...Wait, is that a game? Teach me!",
		"Your chair is comfier than mine. I'm keeping it. Forever.",
		"Look — the map on your screen is Euphoria! Did you draw all of it?"]},
	{"key": "room1", "name": "Cozy Bedroom", "bond": 3, "lines": [
		"It's so cozy here... the fire, the books. Can I stay a little longer?",
		"I brought tea. Sit with me by the fireplace?",
		"Your bed is surprisingly neat, Commander. Suspicious."]},
	{"key": "room2", "name": "Dragon Bedroom", "bond": 5, "lines": [
		"Dragons carved into the bed frame... Shina would never leave this room.",
		"The orb on the table glows brighter when you're near. Did you notice?",
		"Shh. Let's just listen to the fire for a while."]},
	{"key": "onsen", "name": "Moonlit Onsen", "bond": 7, "lines": [
		"The water is perfect... ahh, every battle just melts away.",
		"Don't splash! ...Okay. Maybe one splash.",
		"The moon looks closer from here. Stay with me a bit?"]},
	{"key": "shower", "name": "Bathhouse", "bond": 9, "lines": [
		"H-hey! Knock first! ...Fine. Hand me the towel. Eyes closed!",
		"The steam makes everything so warm. Wait outside, okay? ...Don't go far.",
		"If you're going to stand there, at least scrub my back. ...I'm joking! Mostly."]},
]

static func room_def(key: String) -> Dictionary:
	for r in ROOMS:
		if r["key"] == key:
			return r
	return ROOMS[0]

## Each hero has one favourite room (double Bond there).
static func fav_room(id: String) -> String:
	return ROOMS[absi(hash(id + "room")) % ROOMS.size()]["key"]

# ------------------------------------------------------------------ Starlight Rift (weekly roguelite climb)
const RIFT_MAPS := ["space", "alien", "abaddon", "blackhole", "dino", "bigtree", "necro", "galaxy", "dragonfire", "asgard", "outland", "ice", "apocalypse", "hell", "aqua", "forest"]
const RIFT_POOL := ["slime", "ex_nymph", "gumi_wolf", "slarkoi", "eroghost", "evy_blood_sage", "ygg_naar", "hairly", "svormentis", "ymir", "scomantis", "skelinch", "serpentia", "voodoo", "lizamorph"]
const RIFT_VARIANTS := ["mirror", "hollow", "astral", "echo", "ashen"]
## Blessings: picked 1-of-3 after every win; they stack for the rest of the run.
const BLESSINGS := {
	"ember": {"name": "Ember Heart", "desc": "All allies ATK +8%", "rar": "R", "bonus": {"atk": 0.08}},
	"stone": {"name": "Stone Skin", "desc": "All allies DEF +12%", "rar": "R", "bonus": {"def": 0.12}},
	"bloom": {"name": "Vital Bloom", "desc": "All allies HP +12%", "rar": "R", "bonus": {"hp": 0.12}},
	"hymn": {"name": "Battle Hymn", "desc": "All allies ATK +6%, HP +6%", "rar": "SR", "bonus": {"atk": 0.06, "hp": 0.06}},
	"bulwark": {"name": "Bulwark", "desc": "All allies DEF +10%, HP +10%", "rar": "SR", "bonus": {"def": 0.1, "hp": 0.1}},
	"glass": {"name": "Glass Cannon", "desc": "ATK +22%, but HP -8%", "rar": "SR", "bonus": {"atk": 0.22, "hp": -0.08}},
	"fire": {"name": "Solar Flare", "desc": "FIRE heroes ATK +20%", "rar": "SR", "elem": "FIRE", "bonus": {"atk": 0.2}},
	"water": {"name": "Tidal Blessing", "desc": "WATER/ICE heroes ATK +20%", "rar": "SR", "elem": "WATER", "bonus": {"atk": 0.2}},
	"wind": {"name": "Gale Blessing", "desc": "WIND/LIGHTNING heroes ATK +20%", "rar": "SR", "elem": "WIND", "bonus": {"atk": 0.2}},
	"earth": {"name": "Terra Blessing", "desc": "EARTH heroes ATK +20%", "rar": "SR", "elem": "EARTH", "bonus": {"atk": 0.2}},
	"light": {"name": "Halo Blessing", "desc": "LIGHT heroes ATK +20%", "rar": "SR", "elem": "LIGHT", "bonus": {"atk": 0.2}},
	"dark": {"name": "Umbral Blessing", "desc": "DARK/CHAOS heroes ATK +20%", "rar": "SR", "elem": "DARK", "bonus": {"atk": 0.2}},
	"star": {"name": "Starlight Crown", "desc": "All allies ATK, HP and DEF +10%", "rar": "SSR", "bonus": {"atk": 0.1, "hp": 0.1, "def": 0.1}},
	"oath": {"name": "Second Oath", "desc": "All allies HP +25%", "rar": "SSR", "bonus": {"hp": 0.25}},
	"nova": {"name": "Nova Core", "desc": "All allies ATK +18%", "rar": "SSR", "bonus": {"atk": 0.18}},
}
const RIFT_MILESTONES := [
	{"floor": 5, "give": {"gems": 150, "gold": 30000}}, {"floor": 10, "give": {"hunt_core": 30, "summon_ticket": 1}},
	{"floor": 15, "give": {"gems": 250, "rune_chest": 1}}, {"floor": 20, "give": {"hunt_core": 50, "summon_ticket": 2}},
	{"floor": 25, "give": {"gems": 400, "celestial_gem": 1}}, {"floor": 30, "give": {"hunt_core": 80, "summon_ticket": 3}},
	{"floor": 40, "give": {"gems": 600, "gear_chest": 2}}, {"floor": 50, "give": {"summon_ticket": 5, "oath_ring": 1}},
]

static func rift_floor(floor_no: int, week: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("rift%d_%d" % [week, floor_no])
	var lvl := mini(170, 8 + floor_no * 3 + maxi(0, floor_no - 30) * 2)
	var star := clampi(1 + floor_no / 6, 1, 6)
	var units: Array = []
	var used: Array = []
	var boss := floor_no % 5 == 0
	if boss:
		var hids: Array = HEROES.keys()
		var variant: String = RIFT_VARIANTS[rng.randi() % RIFT_VARIANTS.size()]
		units.append({"id": hids[rng.randi() % hids.size()], "cell": Vector2i(1, 1), "level": lvl + 2, "boss": true, "star": star, "elite": true,
			"mirror": true, "variant": variant, "hp_mult": 2.2 + floor_no * 0.03, "atk_mult": 1.0})
		used.append(Vector2i(1, 1))
	var count := mini(5, 2 + floor_no / 4) + (0 if boss else 0)
	while units.size() < count:
		var cell := Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
		if used.has(cell):
			continue
		used.append(cell)
		units.append({"id": RIFT_POOL[rng.randi() % RIFT_POOL.size()], "cell": cell, "level": lvl, "boss": false, "star": star, "elite": floor_no >= 15})
	return {"floor": floor_no, "bg": RIFT_MAPS[(floor_no - 1) / 5 % RIFT_MAPS.size()], "enemies": units, "boss": boss, "level": lvl}

# ------------------------------------------------------------------ Boss Hunt
## Hunting grounds on the new star maps. Each target has 4 difficulties; 3 hunts per day (losses refunded).
const HUNT_TRIES := 3
const HUNT_DIFFS := ["NORMAL", "HARD", "NIGHTMARE", "ABYSS"]
const HUNT_LEVELS := [30, 52, 74, 96]
const HUNTS := [
	{"id": "behemoth", "name": "Starport Behemoth", "boss": "slarkoi", "bg": "space", "minions": ["slime", "gumi_wolf"], "focus": "gear", "hp_k": 0.7,
		"desc": "A colossal beast that feeds on engine light. Drops equipment — SSR gear on higher difficulties."},
	{"id": "spore", "name": "Spore Queen of Mycelia", "boss": "ex_nymph", "bg": "alien", "minions": ["slime", "ex_nymph"], "focus": "rune", "hp_k": 2.0, "atk_k": 1.5,
		"desc": "Her petals are crystallised runes. Drops runes of higher tiers."},
	{"id": "wraith", "name": "Singularity Wraith", "boss": "eroghost", "bg": "blackhole", "minions": ["evy_blood_sage", "eroghost"], "focus": "shard", "hp_k": 1.0,
		"desc": "Woven from swallowed starlight. Drops hero shards for Star Up & Awakening."},
	{"id": "cinder", "name": "Cinder Witch of Dragonbone", "boss": "evy_blood_sage", "bg": "dragonfire", "minions": ["gumi_wolf", "eroghost"], "focus": "stone", "hp_k": 1.9, "atk_k": 1.4,
		"desc": "She brews fire inside a dead dragon's ribs. Drops Star Stones (universal shards for Star Up, Awakening and Limit Break)."},
	{"id": "leviathan", "name": "Outland Leviathan", "boss": "slime", "bg": "outland", "minions": ["ex_nymph", "slarkoi"], "focus": "core", "hp_k": 1.1, "atk_k": 1.2,
		"desc": "Drifts between the floating isles, swallowing crystals. Drops extra Hunt Cores."},
	{"id": "canopy", "name": "Canopy Nine-Tail", "boss": "gumi_wolf", "bg": "bigtree", "minions": ["ex_nymph", "slarkoi"], "focus": "gold", "hp_k": 1.5, "atk_k": 1.3,
		"desc": "Guardian fox of Yggdrasil's canopy. Drops huge Gold, Hero EXP and EXP Potions."},
]
const HUNT_SHOP := [
	{"id": "hs_ssr_weapon", "name": "SSR Weapon", "price": 260, "give": {"gear:weapon:SSR": 1}, "limit": 2},
	{"id": "hs_ssr_armor", "name": "SSR Armor", "price": 260, "give": {"gear:armor:SSR": 1}, "limit": 2},
	{"id": "hs_ssr_acc", "name": "SSR Accessory", "price": 260, "give": {"gear:accessory:SSR": 1}, "limit": 2},
	{"id": "hs_rune3", "name": "Grand Rune Chest", "price": 150, "give": {"rune_chest": 1}, "limit": 4},
	{"id": "hs_cgem", "name": "Celestial Gem", "price": 180, "give": {"celestial_gem": 1}, "limit": 3},
	{"id": "hs_ticket", "name": "Summon Ticket", "price": 120, "give": {"summon_ticket": 1}, "limit": 5},
	{"id": "hs_exp", "name": "EXP Potion x5", "price": 40, "give": {"exp_potion": 5}, "limit": 10},
]

static func hunt_def(id: String) -> Dictionary:
	for h in HUNTS:
		if h["id"] == id:
			return h
	return HUNTS[0]

## Element that beats the hunt target (same rule as the World Boss).
static func hunt_weak(id: String) -> String:
	var grp: String = ELEMENT_GROUP.get(element_of(hunt_def(id)["boss"]), "LIGHT")
	for k in ELEMENT_BEATS.keys():
		if ELEMENT_BEATS[k] == grp:
			return k
	return "LIGHT"

static func hunt_stage(id: String, diff: int) -> Dictionary:
	var h := hunt_def(id)
	var lvl: int = HUNT_LEVELS[diff]
	var units: Array = [{"id": h["boss"], "cell": Vector2i(1, 1), "level": lvl + 3, "boss": true, "star": 2 + diff, "elite": true, "mirror": true, "variant": "astral",
		"hp_mult": (5.0 + diff * 0.8) * float(h.get("hp_k", 1.0)), "atk_mult": 1.15 * float(h.get("atk_k", 1.0))}]
	var cells := [Vector2i(0, 0), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 2)]
	for i in diff + 1:
		units.append({"id": h["minions"][i % 2], "cell": cells[i], "level": lvl, "boss": false, "star": 1 + diff, "elite": diff >= 2})
	var rewards := {"hunt_core": 12 + diff * 10, "gold": 6000 + diff * 9000}
	match str(h["focus"]):
		"gold":
			rewards["gold"] = int(rewards["gold"]) * 3
			rewards["hero_exp"] = 5000 + diff * 7000
			rewards["exp_potion"] = 2 + diff * 2
	return {"name": "%s  •  %s" % [h["name"], HUNT_DIFFS[diff]], "level": lvl, "bg": h["bg"], "enemies": units, "rewards": rewards,
		"first_gems": 80 * (diff + 1), "mod": {"elem": hunt_weak(id), "atk": 0.3, "name": "Hunter's Instinct: %s units +30%% ATK" % hunt_weak(id)}}

# ------------------------------------------------------------------ Story Links
## Heroes bound by the story fight better together. Active when every member is deployed.
const LINKS := [
	{"id": "cats", "name": "Mischief & Machines", "heroes": ["luby", "micca"], "bonus": {"atk": 0.08}, "line": "One steals snacks, one steals boxes."},
	{"id": "wings", "name": "Wings of Dawn", "heroes": ["angela", "furu"], "bonus": {"def": 0.08, "hp": 0.06}, "line": "Heaven's sword and heaven's prayer."},
	{"id": "phoenix", "name": "Phoenix & Dragon", "heroes": ["kara", "shina"], "bonus": {"atk": 0.08}, "line": "Two flames, one sky."},
	{"id": "blades", "name": "Blade Sisters", "heroes": ["mei", "kali"], "bonus": {"atk": 0.08}, "line": "A hundred blades and one red moon."},
	{"id": "coins", "name": "Counting House", "heroes": ["ninger", "rumi"], "bonus": {"hp": 0.08}, "line": "Every coin accounted for."},
	{"id": "engine", "name": "Engine Hearts", "heroes": ["spimei", "xylia"], "bonus": {"atk": 0.06, "def": 0.06}, "line": "Blueprints with wings."},
	{"id": "dragon", "name": "Dragon Sisters", "heroes": ["shina", "zennyo"], "bonus": {"atk": 0.08}, "line": "Dragons stick together."},
	{"id": "shield", "name": "Shield & Prayer", "heroes": ["fidelia", "furu"], "bonus": {"def": 0.10}, "line": "One guards the body, one guards the soul."},
	{"id": "frost", "name": "Frost & Snow", "heroes": ["valeria", "schylua"], "bonus": {"hp": 0.08}, "line": "A scarf long enough for two."},
	{"id": "freed", "name": "The Freed Blades", "heroes": ["kali", "abadonia"], "bonus": {"atk": 0.08}, "line": "Freed from the Second Eclipse, side by side."},
	{"id": "time", "name": "Keepers of Time", "heroes": ["mora", "lucidria"], "bonus": {"hp": 0.08}, "line": "Old ruins, older clocks."},
	{"id": "empress", "name": "Empress of the Abyss", "heroes": ["eropatra", "cthollia"], "bonus": {"atk": 0.08}, "line": "Gold above, the deep below."},
	{"id": "tide", "name": "Tide Sisters", "heroes": ["scylla", "aqua"], "bonus": {"hp": 0.08}, "line": "The sea sounds louder in the rain."},
	{"id": "mischief", "name": "Mischief Makers", "heroes": ["micca", "vexira"], "bonus": {"atk": 0.08}, "line": "One steals treats, one steals hearts."},
	{"id": "lantern", "name": "Lantern Wishes", "heroes": ["furu", "rumi"], "bonus": {"def": 0.08}, "line": "One lantern for every wish."},
	{"id": "dance", "name": "Starlight Dancers", "heroes": ["glytta", "lumeira"], "bonus": {"atk": 0.06, "hp": 0.06}, "line": "Butterflies and festival steps."},
	{"id": "architect", "name": "Architect & Oracle", "heroes": ["xylia", "gemora"], "bonus": {"def": 0.08}, "line": "Blueprints checked by star maps."},
	{"id": "thunder", "name": "Hunt & Thunder", "heroes": ["atalanta", "siv"], "bonus": {"atk": 0.08}, "line": "Race you to the next storm!"},
	{"id": "blaze", "name": "Blaze Brigade", "heroes": ["rubby", "shina"], "bonus": {"atk": 0.06}, "line": "Fireworks and dragonfire."},
	{"id": "wander", "name": "Wanderer & Sage", "heroes": ["sven", "hyeonxa"], "bonus": {"hp": 0.08}, "line": "Quiet roads and quieter tea."},
	{"id": "warm", "name": "Warm Hearts", "heroes": ["eurnipha", "cthollia"], "bonus": {"hp": 0.08}, "line": "Saved from the Hollow Star together."},
	{"id": "lastlight", "name": "The Last Light", "heroes": ["shina", "fidelia", "mora"], "bonus": {"atk": 0.06, "hp": 0.06, "def": 0.06}, "line": "Today, tomorrow, and every tomorrow after that."},
]

static func links_of(id: String) -> Array:
	return LINKS.filter(func(l): return (l["heroes"] as Array).has(id))

static func link_bonus_text(l: Dictionary) -> String:
	var parts: Array = []
	for k in ["atk", "hp", "def"]:
		if l["bonus"].has(k):
			parts.append("%s +%d%%" % [k.to_upper(), roundi(float(l["bonus"][k]) * 100)])
	return ", ".join(parts)

# ------------------------------------------------------------------ Commander Tactics
## One tactic is equipped before battle and fires automatically when its trigger happens.
const TACTICS := [
	{"id": "rally", "name": "Rally Cry", "req": 3, "trigger": "Start of Round 2", "icon": "icon_skill_ultimate"},
	{"id": "mend", "name": "Field Medic", "req": 6, "trigger": "Start of Round 3", "icon": "icon_heart"},
	{"id": "barrage", "name": "Opening Barrage", "req": 10, "trigger": "Start of Round 1", "icon": "icon_combat_target"},
	{"id": "aegis", "name": "Aegis Protocol", "req": 14, "trigger": "An ally drops below 40% HP", "icon": "icon_equipment"},
	{"id": "second_wind", "name": "Second Wind", "req": 20, "trigger": "The first ally falls", "icon": "icon_awakening"},
]
const TACTIC_MAX_LV := 5

static func tactic_def(id: String) -> Dictionary:
	for t in TACTICS:
		if t["id"] == id:
			return t
	return {}

## Effect strength for a tactic at a level.
static func tactic_value(id: String, lv: int) -> float:
	match id:
		"rally": return 0.15 + 0.05 * lv          # team ATK +
		"mend": return 0.15 + 0.05 * lv           # heal % max HP
		"barrage": return 0.6 + 0.2 * lv          # x average ally ATK to every enemy
		"aegis": return 0.15 + 0.05 * lv          # shield % max HP
		"second_wind": return 0.2 + 0.06 * lv     # revive HP %
	return 0.0

static func tactic_desc(id: String, lv: int) -> String:
	var v := tactic_value(id, lv)
	match id:
		"rally": return "All allies gain +%d%% ATK for 2 rounds." % roundi(v * 100)
		"mend": return "Heals all allies for %d%% Max HP and cleanses their debuffs." % roundi(v * 100)
		"barrage": return "Artillery strikes every enemy for %d%% of your team's average ATK." % roundi(v * 100)
		"aegis": return "Shields all allies for %d%% of their Max HP (once)." % roundi(v * 100)
		"second_wind": return "Revives the fallen ally with %d%% HP (once)." % roundi(v * 100)
	return ""

static func tactic_cost(lv: int) -> int:
	return 15000 * lv * lv

# ------------------------------------------------------------------ Seasonal festivals (by calendar month)
const FESTIVALS := {
	1: {"name": "New Dawn Festival", "fx": "firefly", "color": "#ffd479", "bg": "asgard", "featured": ["mora", "lucidria"],
		"lines": [["mora", "A new year, Commander. The clocks are ticking forward — together with you."], ["lucidria", "...I made a wish at the shrine. No, I won't tell you what it was."]]},
	2: {"name": "Sweetheart Festival", "fx": "heart", "color": "#ff8fb8", "bg": "lobby", "featured": ["vexira", "eurnipha"],
		"lines": [["vexira", "Ara~ chocolate for me? Or... shall I be the gift?"], ["eurnipha", "I made you something. It's warm. Like a hug you can eat."]]},
	3: {"name": "Sakura Bloom", "fx": "petal", "color": "#ffc4dc", "bg": "forest", "featured": ["lumeira", "glytta"],
		"lines": [["lumeira", "The petals are dancing with the butterflies~ Let's nap under the trees."], ["glytta", "Flower viewing party! I'll dance, you clap. Deal?"]]},
	4: {"name": "Sakura Bloom", "fx": "petal", "color": "#ffc4dc", "bg": "forest", "featured": ["lumeira", "glytta"],
		"lines": [["lumeira", "The petals are dancing with the butterflies~ Let's nap under the trees."], ["glytta", "Flower viewing party! I'll dance, you clap. Deal?"]]},
	5: {"name": "Rainbell Season", "fx": "rain", "color": "#a8d8ff", "bg": "aqua", "featured": ["aqua", "scylla"],
		"lines": [["aqua", "Rain is the sky's tea party. Share my umbrella, Commander?"], ["scylla", "...The sea sounds louder in the rain. I like it. And you."]]},
	6: {"name": "Rainbell Season", "fx": "rain", "color": "#a8d8ff", "bg": "aqua", "featured": ["aqua", "scylla"],
		"lines": [["aqua", "Rain is the sky's tea party. Share my umbrella, Commander?"], ["scylla", "...The sea sounds louder in the rain. I like it. And you."]]},
	7: {"name": "Summer Splash", "fx": "firefly", "color": "#9ff5ff", "bg": "pool", "featured": ["atalanta", "rubby"],
		"lines": [["atalanta", "Race you to the water! Loser buys shaved ice!"], ["rubby", "Summer fireworks are my specialty~ Stand back. Further. FURTHER."]]},
	8: {"name": "Summer Fireworks", "fx": "firefly", "color": "#ffb86b", "bg": "pool", "featured": ["atalanta", "rubby"],
		"lines": [["rubby", "Look up, Commander! That one's shaped like you!"], ["atalanta", "I'll catch every falling spark. ...For you."]]},
	9: {"name": "Tsukimi Moon Festival", "fx": "firefly", "color": "#e6e9ff", "bg": "ice", "featured": ["gemora", "cthollia"],
		"lines": [["gemora", "Lunar brightness at maximum. Recommended activity: moon-viewing with the Commander."], ["cthollia", "The moon pulls the tide... and something pulls me toward you."]]},
	10: {"name": "Moonlit Masquerade", "fx": "leaf", "color": "#ff9a4a", "bg": "hell", "featured": ["hyeonxa", "micca"],
		"lines": [["micca", "Trick or treat! ...I already took the treat. Hehe."], ["hyeonxa", "My birthday and a masquerade on the same night. Don't spoil it, Commander."]]},
	11: {"name": "Harvest Lantern Festival", "fx": "lantern", "color": "#ffb05c", "bg": "forest", "featured": ["furu", "rumi"],
		"lines": [["furu", "We release one lantern for every wish. I wrote mine for you, Commander."], ["rumi", "Lantern stalls, mochi stalls, fortune stalls! ...Lend me some gold?"]]},
	12: {"name": "Starfall Winter Festival", "fx": "snow", "color": "#ffffff", "bg": "ice", "featured": ["valeria", "schylua"],
		"lines": [["valeria", "Snow, cocoa, and you. This is the winter I always wanted."], ["schylua", "...I knitted a scarf. It's long enough for two. Don't make it weird."]]},
}
const FEST_DAILY_CAP := 400       # Lantern Charms from battles per day
const FEST_SHOP := [
	{"id": "fs_ticket", "name": "Summon Ticket", "price": 120, "give": {"summon_ticket": 1}, "limit": 6},
	{"id": "fs_gems", "name": "100 Gems", "price": 60, "give": {"gems": 100}, "limit": 6},
	{"id": "fs_shard0", "name": "Featured Shard x10", "price": 100, "give": {"shard:@0": 10}, "limit": 6},
	{"id": "fs_shard1", "name": "Featured Shard x10", "price": 100, "give": {"shard:@1": 10}, "limit": 6},
	{"id": "fs_cgem", "name": "Celestial Gem", "price": 150, "give": {"celestial_gem": 1}, "limit": 2},
	{"id": "fs_cake", "name": "Sweet Cake x2", "price": 40, "give": {"sweet_cake": 2}, "limit": 5},
	{"id": "fs_bouquet", "name": "Bouquet x2", "price": 40, "give": {"bouquet": 2}, "limit": 5},
	{"id": "fs_gear", "name": "Gear Chest", "price": 80, "give": {"gear_chest": 1}, "limit": 3},
	{"id": "fs_energy", "name": "Energy Flask", "price": 30, "give": {"energy_potion": 1}, "limit": 10},
]

# ------------------------------------------------------------------ World Boss (weekly)
const WORLD_BOSSES := [
	{"id": "gumi_wolf", "name": "Astral Nine-Tail", "bg": "hell"},
	{"id": "slarkoi", "name": "Crypt Behemoth", "bg": "battle"},
	{"id": "slime", "name": "Gelatinous Overlord", "bg": "aqua"},
	{"id": "ex_nymph", "name": "Corrupted Forest Queen", "bg": "forest"},
	{"id": "ygg_naar", "name": "Eye of the Primordial", "bg": "galaxy"},
	{"id": "ymir", "name": "Ymir, Bone Throne Colossus", "bg": "necro"},
	{"id": "svormentis", "name": "Svormentis, the Devouring Maw", "bg": "outland"},
	{"id": "serpentia", "name": "Serpentia, Flame-Scale Lamia", "bg": "dragonfire"},
]
const WB_TRIES := 3
## Weekly cumulative damage milestones.
const WB_MILESTONES := [
	{"dmg": 30000, "give": {"gold": 20000, "exp_potion": 2}},
	{"dmg": 100000, "give": {"gems": 100, "gear_chest": 1}},
	{"dmg": 250000, "give": {"summon_ticket": 1, "gold": 40000}},
	{"dmg": 600000, "give": {"gems": 200, "rune_chest": 1}},
	{"dmg": 1200000, "give": {"summon_ticket": 2, "celestial_gem": 1}},
	{"dmg": 2500000, "give": {"gems": 300, "gear_chest": 2}},
	{"dmg": 5000000, "give": {"summon_ticket": 3, "gems": 500}},
]
## Weekly ranking rewards (rank <= key).
const WB_RANK_REWARDS := [[1, {"gems": 600, "summon_ticket": 3}], [3, {"gems": 400, "summon_ticket": 2}], [10, {"gems": 250, "summon_ticket": 1}], [9999, {"gems": 100}]]

static func world_boss(week: int) -> Dictionary:
	var b: Dictionary = WORLD_BOSSES[posmod(week, WORLD_BOSSES.size())].duplicate()
	var grp: String = ELEMENT_GROUP.get(element_of(b["id"]), "LIGHT")
	var weak := "LIGHT"
	for k in ELEMENT_BEATS.keys():
		if ELEMENT_BEATS[k] == grp:
			weak = k
	b["weak"] = weak
	b["mod"] = {"elem": weak, "atk": 0.3, "name": "Weakness: %s heroes +30%% ATK" % weak}
	return b

static func wb_rank_reward(rank: int) -> Dictionary:
	for r in WB_RANK_REWARDS:
		if rank <= int(r[0]):
			return r[1]
	return {}

static func raid_max_hp(lv: int) -> int:
	return 120000 * lv + 60000 * lv * lv

static func raid_boss(lv: int) -> Array:
	return [{"id": "ygg_naar", "cell": Vector2i(1, 1), "level": 6 + lv * 7, "boss": true, "raid": true}]

static var _tex_cache: Dictionary = {}
static var _json: Dictionary = {}

# ----------------------------------------------------------------- textures

static func tex(path: String) -> Texture2D:
	if path == "":
		return null
	if _tex_cache.has(path):
		return _tex_cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	_tex_cache[path] = t
	return t

static func icon(name: String) -> Texture2D:
	return tex("res://art/icons/%s.png" % name)

## 2.5D live rigs: art path → depth map + pivots (UV space) for game/ui/live25d.gdshader.
## Built from the artist's pivot sheet (Karakter Euphoria Online/hero/Glytta/glytta_char_evo2_3d.png).
const GLYTTA_EVO2_RIG := {
	"depth": "res://art/characters/heroes/glytta/char/glytta_char_evo2_depth.png",
	"head_c": Vector2(0.46, 0.30), "head_r": Vector2(0.11, 0.095), "neck": Vector2(0.48, 0.378),
	"chest": Vector2(0.49, 0.46), "eye": Vector2(0.473, 0.309), "eye_size": Vector2(0.021, 0.0098),
	"mouth": Vector2(0.502, 0.3496), "mouth_size": Vector2(0.02, 0.012),
	"halo": Vector4(0.482, 0.15, 0.115, 0.03), "big_eye": Vector3(0.893, 0.569, 0.055), "small_eye": Vector3(0.149, 0.7375, 0.02),
	"glow_color": Color(0.45, 0.85, 1.0), "rim_color": Color(0.75, 0.9, 1.0),
}
const LIVE_RIGS := {
	"res://art/characters/heroes/glytta/char/glytta_char_evo2.png": GLYTTA_EVO2_RIG,
	"res://art/characters/heroes/glytta/char/glytta_char_evo2_a.png": GLYTTA_EVO2_RIG,
}

static var _auto_rig: Dictionary = {}

## Hand-made rig if there is one, else the automatic 2.5D depth (art/depth/<name>_depth.png).
static func live_rig(tex: Texture2D) -> Dictionary:
	if tex == null:
		return {}
	var p := tex.resource_path
	if LIVE_RIGS.has(p):
		return LIVE_RIGS[p]
	if not (p.contains("/heroes/") or p.contains("/enemies/")):
		return {}
	if not _auto_rig.has(p):
		var dp := "res://art/depth/%s_depth.png" % p.get_file().get_basename()
		_auto_rig[p] = {"depth": dp, "generic": true, "strength": 0.011, "chest": Vector2(0.5, 0.36)} if ResourceLoader.exists(dp) else {}
	return _auto_rig[p]

static func bg(key: String) -> Texture2D:
	return tex(BG.get(key, BG["lobby"]))

static func _db() -> Dictionary:
	if _json.is_empty():
		var f := FileAccess.open("res://data/character_database.json", FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_json = parsed
	return _json

static func _entry(id: String) -> Dictionary:
	var d := _db()
	if d.get("heroes", {}).has(id):
		return d["heroes"][id]
	return d.get("enemies", {}).get(id, {})

static func _state_sort_key(k: String) -> String:
	# stage1..stageN first, then evo1..evoN, then special
	if k.begins_with("stage"):
		return "0" + k.substr(5).pad_zeros(2)
	if k.begins_with("evo"):
		return "1" + k.substr(3).pad_zeros(2)
	return "2" + k

## Ordered list of full-art paths (the "skins"/art tiers) for a hero or enemy.
static func art_list(id: String) -> Array:
	var states: Dictionary = _entry(id).get("char_states", {})
	var keys: Array = states.keys()
	keys.sort_custom(func(a, b): return _state_sort_key(a) < _state_sort_key(b))
	var out: Array = []
	for k in keys:
		if k == "lobby":
			continue   # lobby pose is not an outfit
		var p: String = str(states[k].get("base", ""))
		if p != "" and ResourceLoader.exists(p):
			out.append(p)
	if out.is_empty():
		var portrait := str(_entry(id).get("portrait", ""))
		if portrait != "":
			out.append(portrait)
	return out

## Dedicated lobby pose (e.g. *_char_loby.png), or null.
static func lobby_art(id: String) -> Texture2D:
	var st: Dictionary = _entry(base_id(id)).get("char_states", {}).get("lobby", {})
	var p := str(st.get("base", ""))
	return tex(p) if p != "" and ResourceLoader.exists(p) else null

## Alternate expression (the "a" variants) for an outfit, or null.
static func alt_art(id: String, index: int = 0) -> Texture2D:
	var states: Dictionary = _entry(base_id(id)).get("char_states", {})
	var keys: Array = states.keys().filter(func(k): return k != "lobby")
	keys.sort_custom(func(a, b): return _state_sort_key(a) < _state_sort_key(b))
	if keys.is_empty():
		return null
	var inter: Array = states[keys[clampi(index, 0, keys.size() - 1)]].get("interactions", [])
	for p in inter:
		if ResourceLoader.exists(str(p)):
			return tex(str(p))
	return null

static func art(id: String, index: int = 0) -> Texture2D:
	id = base_id(id)
	var l := art_list(id)
	if l.is_empty():
		return null
	return tex(l[clampi(index, 0, l.size() - 1)])

static func portrait(id: String) -> Texture2D:
	var p := str(_entry(id).get("portrait", ""))
	if p != "" and ResourceLoader.exists(p):
		return tex(p)
	return art(id, 0)

## Square-ish face crop of the portrait for cards and icons.
static func face(id: String, skin: int = -1) -> Texture2D:
	id = base_id(id)
	var key := "face:%s:%d" % [id, skin]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var base: Texture2D = portrait(id) if skin < 0 else art(id, skin)
	if base == null:
		return null
	var w := float(base.get_width())
	var h := float(base.get_height())
	var side := minf(w * 0.78, h * 0.62)
	var at := AtlasTexture.new()
	at.atlas = base
	at.region = Rect2((w - side) * 0.5, h * 0.03, side, side * 1.15)
	_tex_cache[key] = at
	return at

## Wide head-and-shoulders crop for battle cut-ins. Finds the top of the
## visible figure from the image alpha so tall/short art both frame the face.
static func cutin(id: String) -> Texture2D:
	var key := "cutin:" + id
	if _tex_cache.has(key):
		return _tex_cache[key]
	var base := art(id, 0)
	if base == null:
		return null
	var img := base.get_image()
	var w := float(base.get_width())
	var h := float(base.get_height())
	var top := 0.0
	if img != null:
		if img.is_compressed():
			img = img.duplicate()
			img.decompress()
		var found := false
		for yi in range(0, img.get_height(), maxi(1, img.get_height() / 120)):
			for xi in range(int(img.get_width() * 0.25), int(img.get_width() * 0.75), maxi(1, img.get_width() / 60)):
				if img.get_pixel(xi, yi).a > 0.5:
					top = float(yi) / img.get_height() * h
					found = true
					break
			if found:
				break
	var ch := minf(h - top, w * 0.5)
	var at := AtlasTexture.new()
	at.atlas = base
	at.region = Rect2(0, top + h * 0.02, w, ch)
	_tex_cache[key] = at
	return at

## Chibi battle sprite. Evolved sprite unlocks at 5★.
static func sprite(id: String, star: int = 1) -> Texture2D:
	var sprites: Array = _entry(id).get("sprites", [])
	var base_list: Array = []
	var evo_list: Array = []
	for s in sprites:
		var p := str(s)
		if not ResourceLoader.exists(p):
			continue
		if p.contains("_evo") or p.contains("_special"):
			evo_list.append(p)
		else:
			base_list.append(p)
	base_list.sort()
	evo_list.sort()
	if star >= 5 and not evo_list.is_empty():
		return tex(evo_list[0])
	if not base_list.is_empty():
		return tex(base_list[0])
	if not evo_list.is_empty():
		return tex(evo_list[0])
	return art(id, 0)

static func boss_sprite(id: String) -> Texture2D:
	var sprites: Array = _entry(id).get("sprites", [])
	for s in sprites:
		if str(s).contains("_evo") and ResourceLoader.exists(str(s)):
			return tex(str(s))
	return sprite(id)

# ----------------------------------------------------------------- hero info

static func hero_ids() -> Array:
	var ids: Array = HEROES.keys()
	ids.sort_custom(func(a, b):
		var ra: int = ["SSR", "SR", "R"].find(HEROES[a]["rarity"])
		var rb: int = ["SSR", "SR", "R"].find(HEROES[b]["rarity"])
		return a < b if ra == rb else ra < rb)
	return ids

static func name_of(id: String) -> String:
	if id == "nar":
		return ""
	if id.begins_with("mirror:"):
		return "Mirror " + name_of(id.substr(7)).split(" ")[0]
	if id.begins_with("hollow:"):
		return "Hollow " + name_of(id.substr(7)).split(" ")[0]
	if id.begins_with("echo:"):
		return "Echo of " + name_of(id.substr(5)).split(" ")[0]
	if id.begins_with("ashen:"):
		return "Ashen " + name_of(id.substr(6)).split(" ")[0]
	if id.begins_with("feral:"):
		return "Feral " + name_of(id.substr(6)).split(" ")[0]
	var e := _entry(id)
	return str(e.get("display_name", id.capitalize()))

static func title_of(id: String) -> String:
	return str(_entry(id).get("title", ""))

static func element_of(id: String) -> String:
	return str(_entry(id).get("element", "LIGHT"))

static func theme_color(id: String) -> Color:
	if id.begins_with("mirror:"):
		return Color("#7a3cc8")
	if id.begins_with("hollow:"):
		return Color("#1f8a9a")
	if id.begins_with("echo:"):
		return Color("#9a8550")
	if id.begins_with("ashen:"):
		return Color("#8a3a20")
	if id.begins_with("feral:"):
		return Color("#9a2a1f")
	var c := str(_entry(id).get("theme_color", ""))
	if c != "":
		return Color(c)
	return ELEMENT_COLOR.get(element_of(id), Color("#a98cff"))

static func rarity_of(id: String) -> String:
	return str(HEROES.get(id, {}).get("rarity", "R"))

static func role_of(id: String) -> String:
	if HEROES.has(id):
		return str(HEROES[id]["role"])
	return str(ENEMIES.get(id, {}).get("role", "WARRIOR"))

static func skill_of(id: String) -> Dictionary:
	if HEROES.has(id):
		return HEROES[id]["skill"]
	return ENEMIES.get(id, {}).get("skill", {"name": "Strike", "aim": "front", "shape": "single", "mult": 1.0})

static func base_stats(id: String) -> Dictionary:
	var d: Dictionary = HEROES.get(id, ENEMIES.get(id, {}))
	return {"hp": int(d.get("hp", 1500)), "atk": int(d.get("atk", 150)), "def": int(d.get("def", 60))}

static func level_cap(star: int, lb: int = 0) -> int:
	return 20 + star * 10 + lb * LB_STEP

## Limit Break: 6★ heroes at their level cap can raise it +5 per step (up to Lv.100).
const MAX_LB := 4
const LB_STEP := 5

static func lb_cost(lb: int) -> Dictionary:
	return {"hunt_core": 40 * (lb + 1), "shards": 20 * (lb + 1), "gold": 60000 * (lb + 1)}

static func exp_to_next(level: int) -> int:
	return 80 + level * level * 6

static func gold_to_next(level: int) -> int:
	return 200 + level * 120

static func shards_for_star(star: int) -> int:
	return [0, 10, 20, 40, 60, 100, 0][clampi(star, 0, 6)]

static func bond_to_next(bond: int) -> int:
	return 60 + bond * 40

## Final stats for a hero instance (level, star, bond, oath).
static func stats_for(id: String, level: int, star: int, bond: int = 1, oath: bool = false) -> Dictionary:
	var b := base_stats(id)
	var m := (1.0 + 0.085 * float(level - 1)) * (1.0 + 0.14 * float(star - 1)) * (1.0 + 0.02 * float(bond - 1))
	if oath:
		m *= 1.10
	return {"hp": int(b["hp"] * m), "atk": int(b["atk"] * m), "def": int(b["def"] * m)}

static func power_of(stats: Dictionary) -> int:
	return int(stats["hp"] * 0.25 + stats["atk"] * 2.2 + stats["def"] * 1.6)

## The element group that deals +30% to `grp` ("" when nothing does).
static func counter_of(grp: String) -> String:
	for k in ELEMENT_BEATS.keys():
		if ELEMENT_BEATS[k] == grp:
			return k
	return ""

static func element_mult(att_elem: String, def_elem: String) -> float:
	var a: String = ELEMENT_GROUP.get(att_elem, att_elem)
	var d: String = ELEMENT_GROUP.get(def_elem, def_elem)
	if ELEMENT_BEATS.get(a, "") == d:
		return 1.3
	if ELEMENT_BEATS.get(d, "") == a and not (a in ["LIGHT", "DARK"]):
		return 0.85
	return 1.0

static func shape_label(skill: Dictionary) -> String:
	var aim := str(skill.get("aim", "front"))
	var shape := str(skill.get("shape", "single"))
	if aim == "ally_all":
		return "All allies"
	var aim_txt: String = {"front": "Front target", "back": "Furthest target", "lowest": "Weakest target"}.get(aim, "Target")
	var shape_txt: String = {"single": "single", "pierce": "+ behind", "line": "whole row", "column": "whole column", "cross": "cross", "square": "2x2", "x": "X shape", "all": "all enemies"}.get(shape, shape)
	return "%s • %s" % [aim_txt, shape_txt]

## Cells (col,row) hit by a shape around target cell. col 0 = front line.
static func shape_cells(shape: String, target: Vector2i) -> Array:
	var out: Array = []
	match shape:
		"single":
			out = [target]
		"pierce":
			out = [target, target + Vector2i(1, 0)]
		"line":
			out = [Vector2i(0, target.y), Vector2i(1, target.y), Vector2i(2, target.y)]
		"column":
			out = [Vector2i(target.x, 0), Vector2i(target.x, 1), Vector2i(target.x, 2)]
		"cross":
			out = [target, target + Vector2i(1, 0), target + Vector2i(-1, 0), target + Vector2i(0, 1), target + Vector2i(0, -1)]
		"square":
			var dy := 1 if target.y < 2 else -1
			out = [target, target + Vector2i(1, 0), target + Vector2i(0, dy), target + Vector2i(1, dy)]
		"x":
			out = [target, target + Vector2i(1, 1), target + Vector2i(-1, -1), target + Vector2i(1, -1), target + Vector2i(-1, 1)]
		"all":
			for c in 3:
				for r in 3:
					out.append(Vector2i(c, r))
	var valid: Array = []
	for v in out:
		if v.x >= 0 and v.x < 3 and v.y >= 0 and v.y < 3 and not valid.has(v):
			valid.append(v)
	return valid

# ----------------------------------------------------------------- stages

static func stage_count() -> int:
	return CHAPTERS.size() * STAGES_PER_CHAPTER

static func stage_id(index: int) -> String:
	return "%d-%d" % [index / STAGES_PER_CHAPTER + 1, index % STAGES_PER_CHAPTER + 1]

static func stage(index: int) -> Dictionary:
	var ch: int = index / STAGES_PER_CHAPTER
	var st: int = index % STAGES_PER_CHAPTER
	var chapter: Dictionary = CHAPTERS[ch]
	var is_boss := st == STAGES_PER_CHAPTER - 1
	# Arc 2 (chapter 7+) enemies are star-ranked to stay a late-game challenge
	var arc_star: int = 1 if ch < 6 else mini(5, ch - 3)
	var level := 1 + ch * 9 + int(st * 1.6)
	if ch >= 10:
		# Arc 3: gentler level curve (heroes cap at Lv.70); difficulty comes from Mirror bosses & 5★ foes
		level = 84 + (ch - 10) * 4 + int(st * 1.2)
	if ch >= 18:
		# Arc 5: endgame plateau — difficulty comes from astral bosses, not raw levels
		level = 114 + (ch - 18) * 2 + int(st * 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (index + 1)
	var count := mini(5, 2 + (st + ch * 2) / 2)
	if is_boss:
		count = mini(5, count + 1)
	var pool: Array = chapter["pool"]
	var units: Array = []
	var used: Array = []
	if is_boss:
		units.append({"id": chapter["boss"], "cell": Vector2i(1, 1), "level": level + 2, "boss": true, "star": arc_star, "elite": ch >= 6, "mirror": bool(chapter.get("mirror", false)), "variant": str(chapter.get("variant", "mirror" if chapter.get("mirror", false) else "")), "hp_mult": float(chapter.get("boss_hp", 3.5)), "atk_mult": float(chapter.get("boss_atk", 1.3))})
		used.append(Vector2i(1, 1))
	while units.size() < count:
		var eid: String = pool[rng.randi_range(0, pool.size() - 1)]
		if ch >= 10 and eid == "ygg_naar" and units.any(func(x): return x["id"] == "ygg_naar"):
			eid = "eroghost"
		var role := role_of(eid)
		var col := 0 if role in ["TANK", "WARRIOR"] else (2 if role in ["MAGE", "ASSASSIN", "RANGER"] else 1)
		if rng.randf() < 0.3:
			col = rng.randi_range(0, 2)
		var cell := Vector2i(col, rng.randi_range(0, 2))
		var tries := 0
		while used.has(cell) and tries < 20:
			cell = Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
			tries += 1
		if used.has(cell):
			break
		used.append(cell)
		units.append({"id": eid, "cell": cell, "level": level, "boss": false, "star": arc_star, "elite": ch >= 6})
	return {
		"index": index, "id": stage_id(index), "chapter": ch, "boss": is_boss,
		"name": ("BOSS • " if is_boss else "") + "%s %d" % [chapter["name"], st + 1], "mod": chapter.get("mod", {}),
		"bg": chapter["bg"], "level": level, "enemies": units, "energy": 6 + ch,
		"gold": 400 + index * 90, "hero_exp": 300 + index * 70, "player_exp": 35 + index * 4,
		"first_gems": 150 if is_boss else 50, "first_items": {"summon_ticket": 2} if is_boss else ({"summon_ticket": 1} if st == 2 else {}),
	}

## Hard mode: same map, stronger 3★ enemies, an extra unit and guaranteed hero shards
## (R/SR shards on normal nodes, SSR shards on the chapter boss).
static func hard_stage(index: int) -> Dictionary:
	var st := stage(index).duplicate(true)
	var ch: int = st["chapter"]
	st["hard"] = true
	st["id"] = "H" + str(st["id"])
	st["name"] = "HARD • " + str(st["name"])
	st["level"] = int(st["level"]) + 14
	var used: Array = []
	for e in st["enemies"]:
		e["level"] = int(e["level"]) + 14
		e["star"] = 4 if e.get("boss", false) else 3
		e["elite"] = true
		used.append(e["cell"])
	if st["enemies"].size() < 5:
		var pool: Array = CHAPTERS[ch]["pool"]
		for c in [Vector2i(2, 0), Vector2i(2, 2), Vector2i(1, 0), Vector2i(1, 2), Vector2i(0, 0)]:
			if not used.has(c):
				st["enemies"].append({"id": pool[index % pool.size()], "cell": c, "level": st["level"], "star": 3, "boss": false})
				break
	st["energy"] = int(st["energy"]) + 4
	st["gold"] = int(st["gold"]) * 2
	st["hero_exp"] = int(st["hero_exp"]) * 2
	st["first_gems"] = 200 if st["boss"] else 80
	st["first_items"] = {}
	var ids: Array = hero_ids()
	var ssr: Array = ids.filter(func(h): return rarity_of(h) == "SSR")
	var low: Array = ids.filter(func(h): return rarity_of(h) != "SSR")
	st["shard_id"] = ssr[ch % ssr.size()] if st["boss"] else low[(index * 7) % low.size()]
	st["shards"] = 5 if st["boss"] else 4
	return st

static func tower_floor(floor_no: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 104729 * floor_no
	var ids: Array = ENEMIES.keys()
	if floor_no >= 6:
		ids += ["fidelia", "rumi", "glytta", "scylla", "hyeonxa"]
	if floor_no >= 15:
		ids += ["shina", "xylia", "valeria"]
	var level := 4 + floor_no * 3
	var units: Array = []
	var used: Array = []
	var count := mini(5, 3 + floor_no / 4)
	while units.size() < count:
		var cell := Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
		if used.has(cell):
			continue
		used.append(cell)
		units.append({"id": ids[rng.randi_range(0, ids.size() - 1)], "cell": cell, "level": level, "star": clampi(1 + floor_no / 5, 1, 6), "boss": floor_no % 5 == 0 and units.is_empty()})
	return {"floor": floor_no, "level": level, "enemies": units, "bg": ["galaxy", "hell", "ice", "asgard"][floor_no % 4],
		"gems": 100 if floor_no % 5 == 0 else 30, "gold": 1500 + floor_no * 400, "items": {"summon_ticket": 1} if floor_no % 5 == 0 else {}}

# ---------------------------------------------------------------- messenger
## Heroes text the Commander. Each day up to MSG_PER_DAY new chats arrive; reply to raise Bond.
## Thread: [hero lines, [reply A, reply B], [answer A, answer B], index of the reply she likes best].
const MSG_PER_DAY := 3
const MSG_BOND := 2            # personal chat unlocks at this Bond level
const MSG_BOND_BEST := 40
const MSG_BOND_OK := 20
const MSG_PERSONAL_GEMS := 30
const MSG_LOG_MAX := 40
const MSG_PERSONAL := {
	"shina": [["Commander, are you awake?", "I accidentally melted the training dummy again. Third one this week."], ["Your flame is getting stronger. I'm proud of you.", "...Should I order them in bulk?"], ["P-proud? Hmph. Then I'll melt a fourth one just for you.", "Bulk?! ...Actually, yes. Fireproof ones, please."], 0],
	"xylia": [["I drew up plans for a new wing of the base.", "There's a balcony. Facing your office. Purely for strategic reasons."], ["Strategic reasons, huh?", "Approved. Build it."], ["...Fine. It has a nice view of you working. Is that a crime?", "Efficient. I like that about you. Construction starts tomorrow."], 1],
	"micca": [["Commander~ I found something shiny in the dungeon!", "Guess what's inside my box today. Wrong answers get bitten. Hehe."], ["Is it... me?", "Treasure?"], ["...How did you know?! Okay, it's a photo of you. Don't tell anyone.", "Close! It's a cookie I saved for you. Only slightly chewed."], 0],
	"cthollia": [["The abyss is quiet tonight.", "It usually screams. I think it's sulking because I talk about you too much."], ["Tell it I said hello.", "Maybe talk about me a little less?"], ["...It purred. The abyss has never purred before.", "No. The abyss will simply have to cope."], 0],
	"valeria": [["It snowed on the northern ridge.", "I built a small snow fort. It has two seats."], ["Save me a seat.", "Isn't it cold?"], ["Already saved. I'll bring a blanket... for you, not me.", "Cold? I'm a Frost Knight. ...But you can hold my hand if you're worried."], 0],
	"eropatra": [["Commander. Your Empress requires grapes.", "Peeled. By you. Within the hour."], ["Yes, Your Majesty.", "Peel them yourself~"], ["Good. Obedient AND handsome. I chose well.", "...How bold. Nobody has ever refused me. I find that intriguing."], 1],
	"furu": [["I lit a candle for everyone in the squad today.", "Yours was the biggest one. I hope that's okay."], ["Thank you, Furu.", "The biggest? Am I in trouble?"], ["You protect all of us. The light should protect you too.", "No! It's just... you're very important. To the squad. And to me."], 0],
	"glytta": [["I'm practicing a new dance!", "It needs a partner. Hint: it's you. Hint two: you can't say no."], ["I have two left feet.", "Teach me."], ["Then I'll lead! Crystal steps are very forgiving.", "Yay! One, two, crystal spin... You're a natural, Commander!"], 1],
	"hyeonxa": [["Nine heads, nine opinions.", "Today all nine agree on one thing. Lunch. With you."], ["Unanimous? Then I can't refuse.", "What do the heads want to eat?"], ["Democracy wins! Meet me at the mess hall.", "Head four wants spicy soup. Head seven wants whatever you're having."], 0],
	"scylla": [["The tide came in strange today.", "It left a perfect seashell right at my feet. I'm giving it to you."], ["I'll keep it on my desk.", "The sea must like you."], ["Then a piece of my ocean will always be with you.", "The sea and I agree on many things. Including you."], 0],
	"lumeira": [["Commander! A golden butterfly landed on my nose!", "That means great luck is coming. Maybe for both of us?"], ["I already feel lucky.", "Make a wish!"], ["Ehehe... the butterflies were right again!", "I did! ...I won't tell you what it was. But you're in it."], 0],
	"gemora": [["Recon report: the eastern pass is clear.", "Also, you skipped lunch. I can see your desk from here."], ["You're watching me?", "Okay, I'll eat now."], ["Overwatch is my job. Your health is... a priority target.", "Confirmed. Target is eating. Mission success."], 1],
	"fidelia": [["I reinforced the gate today.", "And the walls. And your door. Twice."], ["Twice?", "Thank you for always protecting me."], ["You can never be too safe. Especially you.", "...That's my oath. But it doesn't feel like a duty anymore."], 1],
	"lucidria": [["I found an old inscription in the ruins.", "A promise between a guardian and her lord. It made me think of us."], ["What did it say?", "Then let's make our own promise."], ["'Until the walls fall.' ...Mine never will.", "Agreed. I won't fall, and you won't stop trusting me."], 1],
	"eurnipha": [["It's cold today...", "Can I sit next to you for a while? Just to warm up."], ["Of course.", "I'll make you hot cocoa."], ["Mm... you're so warm, Commander. Five more minutes.", "With marshmallows? ...You spoil me."], 1],
	"rumi": [["Exorcised three ghosts at the old barracks!", "I believe the standard fee is one dessert per ghost."], ["Three desserts, coming up.", "That's not standard at all."], ["Pleasure doing business! Next ghost is half price for you.", "It is now. I set the standards. Pay up~"], 0],
	"mora": [["I paused time for a second today.", "Just to look at you a little longer. ...Don't make that face."], ["What face?", "You could've just asked."], ["That one. The smug one. I'm pausing time again.", "...Then I'm asking. Can I stay a little longer?"], 1],
	"abadonia": [["My lions are restless.", "They want to hunt. I want to ride. You're coming."], ["Is that an order?", "Lead the way, my Queen."], ["It's an invitation. From a queen, those are the same thing.", "Ha! Good answer. Saddle up, Commander."], 1],
	"atalanta": [["Ran around the whole base 40 times!", "Bet you can't do 10. Loser buys dinner~"], ["You're on.", "I'll just buy dinner now."], ["Ooh, brave! I'll wait at the finish line. For a while.", "Smart AND generous! Tonight, the big steak place~"], 0],
	"kali": [["I polished all hundred blades today.", "It took eight hours. I thought about you for most of it."], ["Only most?", "That's dedication."], ["The other hours were about how to impress you. So... all of it.", "Dedication is my weapon too. You'll see."], 0],
	"zennyo": [["One of my little dragons sneezed fire on the curtains.", "He's sorry. He wants a head pat from you as forgiveness."], ["Bring him over.", "Only if you get one too."], ["He's purring! I've never heard him purr before.", "...Fine. But only one. ...Okay, two."], 1],
	"aqua": [["I blessed the water supply today.", "Everyone who drinks it will feel refreshed. Especially you."], ["Is that why I feel so good?", "Thank you, Aqua."], ["Of course! And maybe a little because of me~", "Stay hydrated, Commander. The chalice is always full for you."], 0],
	"rubby": [["Small problem.", "Big boom. Nobody's hurt! The kitchen is just... redecorated."], ["Rubby...", "Was it at least fun?"], ["I'll fix it! With fewer explosions this time. Probably.", "SO fun. Next time I'll invite you. From a safe distance."], 1],
	"schylua": [["Harvest season for the frost reaper.", "I reaped many enemies today. I left a flower on your desk."], ["A flower from a reaper?", "It's beautiful."], ["Even reapers can grow things. ...Only for you.", "Like you. ...Forget I said that."], 1],
	"vexira": [["Ara~ I stole something from you today.", "Check your pocket, Commander~"], ["My lucky coin is gone!", "...You left a note instead?"], ["I'll return it... in exchange for a date. Fair trade~", "'IOU one kiss.' I always pay my debts, Commander~"], 1],
	"siv": [["I fixed your chair!", "It was squeaking. Now it's... in four pieces. But they're really strong pieces!"], ["Thanks, I guess?", "Let's fix it together."], ["I'll make you a NEW one! With a cupholder!", "Together? Okay! You hold, I hammer. Wait, not your hand—"], 1],
	"sven": [["I've been to many lands.", "None of them had a sunset like the one from your tower. Join me tonight?"], ["I'll be there.", "Tell me about the other lands."], ["Then my sword can rest. And so can I.", "Gladly. Though the best story is still how I met you."], 0],
	"angela": [["The heavens sent me another message.", "'Make sure the Commander sleeps before midnight.' ...I may have written that one myself."], ["Caught you.", "I'll go to bed now."], ["It's a holy mission! Self-assigned, but still holy.", "Good. I'll stand guard by the door. Goodnight, Commander."], 1],
	"kara": [["Death checked her list today.", "Your name isn't on it. I made sure. You're welcome."], ["That's... comforting?", "Thank you, Kara."], ["It should be. I'm very thorough.", "Don't thank me. Just stay alive. That's all I ask."], 1],
	"mei": [["Someone touched my ears at the market today.", "I almost drew my sword. ...You're the only one allowed."], ["I'm honored.", "Can I touch them now?"], ["You should be. It's a very exclusive privilege.", "...Just once. Gently. And you never tell anyone."], 1],
	"ninger": [["I flipped my lucky coin 10 times today!", "Heads every time. You know what that means? Today is YOUR lucky day!"], ["Then let's summon!", "Are you sure it's a fair coin?"], ["That's the spirit! Pull one for me too!", "It's... mostly fair. Luck is a skill, Commander!"], 0],
	"spimei": [["Drone 3 took a photo of you yawning.", "For security. I'm not keeping it. ...I'm keeping it."], ["Delete it!", "Send me a copy."], ["Sorry, access denied. Encryption level: crush.", "...Okay. But you have to send me a selfie back. Fair trade."], 1],
	"luby": [["Nya~ My mecha cat got an upgrade!", "It can give head pats now. ...Please test it. On me. For science."], ["For science, then.", "Why not ask the cat?"], ["Nyaa~ ...The experiment is a success. Repeat daily.", "It's not the same! Only your hands are calibrated right!"], 0],
}
## Everyday chats any hero can send (one is picked per hero per day).
const MSG_TOPICS := [
	[["Good morning, Commander!", "Did you sleep well?"], ["Like a rock. You?", "Not really. Too much paperwork."], ["Great! I dreamed we won every battle.", "Then take a break with me later. The paperwork can wait."], 1],
	[["That last battle was intense!", "Did you see my finishing move?"], ["You were amazing out there.", "I was busy giving orders."], ["Hehe... I fight better when you're watching.", "Then I'll do it again next time. Watch closely!"], 0],
	[["It's raining outside.", "Do you like the rain, Commander?"], ["I love the sound of it.", "I prefer sunny days."], ["Me too. It makes the base feel cozy.", "Then I'll be your sunshine until it stops."], 0],
	[["I'm starving after training.", "What should we eat tonight?"], ["Something sweet.", "Whatever you like."], ["Dessert for dinner? I like the way you think.", "Careful, I might pick something very expensive~"], 0],
	[["The stars are really clear tonight.", "Are you still awake?"], ["Yes. Want to stargaze?", "Just finishing some reports."], ["Meet me on the roof. I'll bring a blanket.", "Don't stay up too late. ...Okay, I'll keep you company."], 0],
	[["Hey, Commander.", "Thanks for always looking out for us."], ["That's what I'm here for.", "You all look out for me too."], ["Still. It means a lot. To me especially.", "...Then we'll keep looking out for each other. Deal?"], 1],
]

## Thread data for a key: "p" = her personal chat, "t<N>" = everyday topic N.
static func msg_thread(id: String, key: String) -> Array:
	if key == "p":
		return MSG_PERSONAL.get(base_id(id), [])
	var i := int(key.substr(1))
	return MSG_TOPICS[i] if i >= 0 and i < MSG_TOPICS.size() else []
