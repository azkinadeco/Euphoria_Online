extends Node
## Autoload "Game": the single source of truth for the player's save data.
## Every screen reads from here and calls these functions to mutate state,
## then listens to `changed` to refresh. Nothing in the UI stores game state.

signal changed
signal toast(text: String, color: Color)
signal bond_up(id: String, level: int)

const SAVE_PATH := "user://euphoria_v2_save.json"
var last_sub_up := {}     # the substat the last enhance upgraded (empty if none)
const SAVE_VERSION := 2
const ENERGY_REGEN_SEC := 180
const AFK_CAP_SEC := 12 * 3600
const ARENA_TICKETS := 5

var s: Dictionary = {}
var _bgm: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _voice: AudioStreamPlayer
var _sfx_i := 0
var _tick_accum := 0.0
var _save_dirty := false
var persist := true   # false in automated tests: never touch the real save file

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio()
	load_game()
	capture_away()
	_check_day()
	_regen_energy()

func _process(delta: float) -> void:
	_tick_accum += delta
	if _tick_accum >= 1.0:
		_tick_accum = 0.0
		var before := int(s["cur"]["energy"])
		_regen_energy()
		if int(s["cur"]["energy"]) != before:
			changed.emit()
		if _save_dirty:
			_save_dirty = false
			save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

# =================================================================== save

func now() -> int:
	return int(Time.get_unix_time_from_system())

func day_key() -> int:
	return int((now() + 7 * 3600) / 86400)  # resets at 00:00 WIB (UTC+7)

func new_state() -> Dictionary:
	var st := {
		"version": SAVE_VERSION,
		"player": {"name": "Commander", "level": 1, "exp": 0},
		"cur": {"gold": 20000, "gems": 300, "hero_exp": 2000, "energy": 120, "arena_coin": 0, "guild_coin": 0, "friend_point": 0},
		"items": {"summon_ticket": 0, "bouquet": 3},
		"heroes": {},
		"shards": {},
		"formation": [],
		"lobby_hero": "shina",
		"story": {"cleared": {}, "hard": {}},
		"tower": {"floor": 1},
		"arena": {"rp": 1000, "wins": 0, "losses": 0, "tickets": ARENA_TICKETS, "refresh": 0, "season": -1, "pending": {}, "last_tier": ""},
		"gacha": {"pity": 0, "total": 0, "free_day": -1},
		"quests": {"day": -1, "progress": {}, "claimed": {}},
		"achievements": {},
		"mail_claimed": [],
		"first_steps": [],
		"shop": {"day": -1, "bought": {}},
		"stats": {"oaths": 0},
		"gear": [],
		"gear_uid": 0,
		"login": {"streak": 0, "last_day": -1, "claimed_day": -1},
		"friends": {"day": -1, "used": [], "hearts_sent": false},
		"dungeon": {"day": -1, "tries": {}, "cleared": {}},
		"bond_stories": {},
		"pass": {"season": -1, "exp": 0, "premium": false, "free": [], "prem": []},
		"presets": [[], [], []],
		"weekly": {"week": -1, "progress": {}, "claimed": {}},
		"codex": {},
		"runes": [],
		"rune_uid": 0,
		"skins_bought": {},
		"minigame": {"day": -1, "plays": 0, "best": 0},
		"market": {"day": -1, "refresh": 0, "offers": []},
		"preset_idx": 0,
		"garden": ["shina", "furu", "fidelia", "rumi", "lucidria"],
		"expeditions": {},
		"event": {"period": -1, "cleared": {}, "bought": {}},
		"tactics": {"eq": "", "lv": {}},
		"room": {"day": -1, "visits": 0, "rested": [], "hero": "", "loc": "gameroom"},
		"rift": {"week": -1, "floor": 1, "best": 0, "bless": [], "offer": [], "alive": false, "claimed": [], "runs": 0},
		"hunt": {"day": -1, "used": 0, "cleared": {}, "week": -1, "bought": {}, "abyss": false},
		"fest": {"id": "", "day": -1, "today": 0, "bought": {}, "greeted": false, "wish_day": -1, "total": 0},
		"wboss": {"week": -1, "day": -1, "tries": 3, "total": 0, "best": 0, "claimed": [], "last_rank": 0, "rank_claimed": true},
		"guild": {"joined": "", "level": 1, "exp": 0, "checkin_day": -1, "donate_day": -1, "donates": 0,
			"raid_day": -1, "raid_tries": 3, "raid_lv": 1, "raid_hp": -1, "raid_best": 0, "raid_total": 0},
		"energy_ts": now(),
		"afk_ts": now(),
		"settings": {"bgm": 0.6, "sfx": 0.8, "voice": 0.9, "speed": 1, "ui_scale": -1.0},
	}
	for id in ["fidelia", "lucidria", "rumi", "furu", "shina"]:
		st["heroes"][id] = _new_hero(id)
	st["formation"] = [
		["fidelia", 0, 0], ["shina", 0, 1], ["lucidria", 0, 2], ["rumi", 2, 1], ["furu", 1, 1],
	]
	return st

func _new_hero(id: String) -> Dictionary:
	return {"level": 1, "star": DB.RARITY_START_STAR[DB.rarity_of(id)], "bond": 1, "bond_exp": 0, "oath": false, "skin": 0, "taps": 0, "skill_lv": 1, "awaken": 0}

func load_game() -> void:
	s = new_state()
	if not persist:
		return
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and int(parsed.get("version", 0)) == SAVE_VERSION:
		_merge(s, parsed)
	_sanitize()

func _merge(dst: Dictionary, src: Dictionary) -> void:
	for k in src.keys():
		if dst.has(k) and dst[k] is Dictionary and src[k] is Dictionary and k not in ["heroes", "shards", "cleared", "progress", "claimed", "bought", "items", "gear", "bond_stories", "tries", "expeditions", "runes", "skins_bought", "codex"]:
			_merge(dst[k], src[k])
		else:
			dst[k] = src[k]

## Special skins sort last, so a saved index past the end of the outfit list is a withdrawn skin.
func _withdraw_skins() -> void:
	for hid in DB.WITHDRAWN_SKINS:
		var n: int = DB.art_list(hid).size()
		var kept: Array = (s["skins_bought"].get(hid, []) as Array).filter(func(x): return int(x) < n)
		var lost: int = (s["skins_bought"].get(hid, []) as Array).size() - kept.size()
		if lost > 0:
			s["skins_bought"][hid] = kept
			s["items"]["skin_ticket"] = int(s["items"].get("skin_ticket", 0)) + lost
		if s["heroes"].has(hid) and int(s["heroes"][hid]["skin"]) >= n:
			s["heroes"][hid]["skin"] = unlocked_skins(hid) - 1

func _sanitize() -> void:
	_ensure_gear_subs()
	# JSON turns ints into floats; normalise the numbers we do maths on.
	for k in s["cur"].keys():
		s["cur"][k] = int(s["cur"][k])
	for k in s["items"].keys():
		s["items"][k] = int(s["items"][k])
	for id in s["heroes"].keys():
		if not DB.HEROES.has(id):
			s["heroes"].erase(id)
			continue
		var h: Dictionary = s["heroes"][id]
		var base := _new_hero(id)
		for k in base.keys():
			if not h.has(k):
				h[k] = base[k]
		for k in ["level", "star", "bond", "bond_exp", "skin", "taps", "skill_lv", "awaken"]:
			h[k] = int(h[k])
	var clean: Array = []
	for e in s["formation"]:
		if e is Array and e.size() == 3 and s["heroes"].has(str(e[0])):
			clean.append([str(e[0]), int(e[1]), int(e[2])])
	s["formation"] = clean
	var gclean: Array = []
	for g in s["gear"]:
		if g is Dictionary and DB.GEAR.has(str(g.get("slot", ""))):
			g["uid"] = int(g["uid"])
			g["lv"] = int(g.get("lv", 0))
			if str(g.get("owner", "")) != "" and not s["heroes"].has(str(g["owner"])):
				g["owner"] = ""
			gclean.append(g)
	s["gear"] = gclean
	for hid in s["bond_stories"].keys():
		var eps: Array = []
		for e in s["bond_stories"][hid]:
			eps.append(int(e))
		s["bond_stories"][hid] = eps
	for k in ["free", "prem"]:
		var l: Array = []
		for x in s["pass"][k]:
			l.append(int(x))
		s["pass"][k] = l
	s["pass"]["exp"] = int(s["pass"]["exp"])
	var pres: Array = []
	for pr in s["presets"]:
		var cl: Array = []
		if pr is Array:
			for e in pr:
				if e is Array and e.size() == 3 and s["heroes"].has(str(e[0])):
					cl.append([str(e[0]), int(e[1]), int(e[2])])
		pres.append(cl)
	while pres.size() < 3:
		pres.append([])
	s["presets"] = pres
	s["preset_idx"] = clampi(int(s["preset_idx"]), 0, 2)
	var rclean: Array = []
	for r in s["runes"]:
		if r is Dictionary and DB.RUNES.has(str(r.get("type", ""))):
			r["uid"] = int(r["uid"])
			r["tier"] = int(r["tier"])
			r["slot"] = int(r.get("slot", -1))
			if str(r.get("owner", "")) != "" and not s["heroes"].has(str(r["owner"])):
				r["owner"] = ""
			rclean.append(r)
	s["runes"] = rclean
	s["rune_uid"] = int(s["rune_uid"])
	for hid in s["skins_bought"].keys():
		var arr: Array = []
		for x in s["skins_bought"][hid]:
			arr.append(int(x))
		s["skins_bought"][hid] = arr
	_withdraw_skins()
	for o in s["market"]["offers"]:
		o["price"] = int(o["price"])
		o["off"] = int(o.get("off", 0))
	var gl: Array = []
	for g in s["garden"]:
		if s["heroes"].has(str(g)) and not gl.has(str(g)):
			gl.append(str(g))
	s["garden"] = gl
	for k in s["expeditions"].keys():
		var ex: Dictionary = s["expeditions"][k]
		ex["start"] = int(ex["start"])
	var dclr: Dictionary = s["dungeon"]["cleared"]
	for k in dclr.keys():
		dclr[k] = int(dclr[k])
	var used: Array = []
	for u in s["friends"].get("used", []):
		used.append(int(u))
	s["friends"]["used"] = used
	s["gear_uid"] = int(s["gear_uid"])
	if not s["heroes"].has(s["lobby_hero"]):
		s["lobby_hero"] = s["heroes"].keys()[0]

func save_game() -> void:
	if not persist:
		return
	s["last_seen"] = now()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(s))

func mark_dirty() -> void:
	_save_dirty = true
	changed.emit()

func reset_save() -> void:
	s = new_state()
	_check_day()
	save_game()
	changed.emit()

func _check_day() -> void:
	var d := day_key()
	if int(s["quests"]["day"]) != d:
		s["quests"] = {"day": d, "progress": {}, "claimed": {}}
		s["arena"]["tickets"] = ARENA_TICKETS
		s["arena"]["refresh"] = 0
		quest_progress("login")
	if int(s["shop"]["day"]) != d:
		s["shop"] = {"day": d, "bought": {}}
	if int(s["friends"]["day"]) != d:
		s["friends"] = {"day": d, "used": [], "hearts_sent": false}
	if int(s["weekly"]["week"]) != d / 7:
		s["weekly"] = {"week": d / 7, "progress": {}, "claimed": {}}
	var wb: Dictionary = s["wboss"]
	if int(wb["week"]) != d / 7:
		var had := int(wb["week"]) >= 0 and int(wb["total"]) > 0
		var rk := wboss_rank() if had else 0
		s["wboss"] = {"week": d / 7, "day": d, "tries": DB.WB_TRIES, "total": 0, "best": 0, "claimed": [], "last_rank": rk, "rank_claimed": not had}
		wb = s["wboss"]
	if int(wb["day"]) != d:
		wb["day"] = d
		wb["tries"] = DB.WB_TRIES
	if int(s["market"]["day"]) != d:
		s["market"] = {"day": d, "refresh": 0, "offers": []}
		_roll_market()
	if int(s["minigame"]["day"]) != d:
		s["minigame"]["day"] = d
		s["minigame"]["plays"] = 0
	_check_arena_season()
	if int(s["dungeon"]["day"]) != d:
		s["dungeon"]["day"] = d
		s["dungeon"]["tries"] = {}
	var season := d / DB.PASS_DAYS
	if int(s["pass"]["season"]) != season:
		s["pass"] = {"season": season, "exp": 0, "premium": false, "free": [], "prem": []}
	var lg: Dictionary = s["login"]
	if int(lg["last_day"]) != d:
		lg["streak"] = int(lg["streak"]) % 7 + 1
		lg["last_day"] = d
	var p := event_period()
	DB.set_event_period(p)
	if int(s["event"]["period"]) != p:
		s["event"] = {"period": p, "cleared": {}, "bought": {}}
	var gd: Dictionary = s["guild"]
	if int(gd["raid_day"]) != d:
		if int(gd["raid_day"]) >= 0 and gd["joined"] != "":
			_guildmates_raid(d - int(gd["raid_day"]))
		gd["raid_day"] = d
		gd["raid_tries"] = 3
	if int(gd["raid_hp"]) < 0:
		gd["raid_hp"] = DB.raid_max_hp(int(gd["raid_lv"]))

# =================================================================== audio

func _setup_audio() -> void:
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	_bgm.finished.connect(func(): _bgm.play())
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)

func play_bgm(name: String = "bgm_lobby") -> void:
	var path := "res://audio/%s.wav" % name
	if not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path)
	if _bgm.stream == st and _bgm.playing:
		return
	if _bgm.playing:
		# quick crossfade
		var tw := create_tween()
		tw.tween_property(_bgm, "volume_db", -40.0, 0.25)
		tw.tween_callback(func():
			_bgm.stream = st
			refresh_volume()
			_bgm.play())
		return
	_bgm.stream = st
	_bgm.volume_db = linear_to_db(maxf(0.001, float(s["settings"]["bgm"]) * 0.7))
	_bgm.play()

## Accessibility: no screen flashes, shakes or camera punches.
func reduce_fx() -> bool:
	return bool(s["settings"].get("reduce_fx", false))

## UI scale: -1 = automatic (bigger on touch screens / phones).
func ui_scale() -> float:
	var v := float(s["settings"].get("ui_scale", -1.0))
	if v > 0.0:
		return v
	return 1.15 if DisplayServer.is_touchscreen_available() else 1.0

func apply_ui_scale() -> void:
	var tree := get_tree()
	if tree:
		tree.root.content_scale_factor = ui_scale()

func refresh_volume() -> void:
	_bgm.volume_db = linear_to_db(maxf(0.001, float(s["settings"]["bgm"]) * 0.7))

func sfx(name: String) -> void:
	var path := "res://audio/%s.wav" % name
	if not ResourceLoader.exists(path) or float(s["settings"]["sfx"]) <= 0.01:
		return
	var p := _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = load(path)
	p.volume_db = linear_to_db(float(s["settings"]["sfx"]))
	p.play()

## Plays a hero voice line and returns its subtitle (English text).
func voice(id: String, cat: String) -> String:
	var v := DB.voice(id, cat)
	var path: String = v["path"]
	var vol := float(s["settings"].get("voice", 0.9))
	if path != "" and vol > 0.01 and ResourceLoader.exists(path):
		_voice.stop()
		_voice.stream = load(path)
		_voice.volume_db = linear_to_db(vol)
		_voice.play()
	return str(v["en"])

func notify(text: String, color: Color = Color("#ffd479")) -> void:
	toast.emit(text, color)

# =================================================================== currency & items

func amount(key: String) -> int:
	if s["cur"].has(key):
		return int(s["cur"][key])
	return int(s["items"].get(key, 0))

func give(rewards: Dictionary) -> void:
	for k in rewards.keys():
		var n := int(rewards[k])
		if k == "player_exp":
			add_player_exp(n)
		elif s["cur"].has(k):
			s["cur"][k] = int(s["cur"][k]) + n
		elif k.begins_with("shard:"):
			var hid: String = k.substr(6)
			s["shards"][hid] = int(s["shards"].get(hid, 0)) + n
		elif k.begins_with("rune:"):
			var rp: PackedStringArray = str(k).split(":")
			for i in n:
				add_rune(rp[1], int(rp[2]))
		elif k.begins_with("gear:"):
			var parts: PackedStringArray = str(k).split(":")
			for i in n:
				var gslot: String = parts[1] if parts[1] != "any" else DB.GEAR_SLOTS[randi() % 3]
				add_gear(gslot, parts[2], parts[3] if parts.size() > 3 else "")
		else:
			s["items"][k] = int(s["items"].get(k, 0)) + n
	mark_dirty()

func spend(key: String, n: int) -> bool:
	if amount(key) < n:
		return false
	if s["cur"].has(key):
		s["cur"][key] = int(s["cur"][key]) - n
	else:
		s["items"][key] = int(s["items"][key]) - n
	mark_dirty()
	return true

func reward_text(rewards: Dictionary) -> String:
	var parts: Array = []
	for k in rewards.keys():
		parts.append("%s x%s" % [reward_name(k), fmt(int(rewards[k]))])
	return ", ".join(parts)

func reward_name(k: String) -> String:
	match k:
		"gold": return "Gold"
		"gems": return "Gems"
		"hero_exp": return "Hero EXP"
		"energy": return "Energy"
		"arena_coin": return "Arena Coin"
		"player_exp": return "Player EXP"
		"guild_coin": return "Guild Coin"
		"friend_point": return "Friend Point"
	if k.begins_with("shard:"):
		return "%s Shard" % DB.name_of(k.substr(6))
	if k.begins_with("gear:"):
		var p := k.split(":")
		if p.size() > 3:
			return "%s %s Gear" % [p[2], DB.GEAR_SETS[p[3]]["name"]]
		return "%s %s" % [p[2], DB.GEAR[p[1]]["names"][p[2]]]
	if k.begins_with("rune:"):
		var rp := k.split(":")
		return "%s T%s" % [DB.RUNES[rp[1]]["name"], rp[2]]
	return str(DB.ITEMS.get(k, {}).get("name", k.capitalize()))

func reward_icon(k: String) -> Texture2D:
	match k:
		"gold": return DB.icon("icon_gold")
		"gems": return DB.icon("icon_gem")
		"hero_exp": return DB.icon("icon_crystal")
		"energy": return DB.icon("icon_energy")
		"arena_coin": return DB.icon("icon_arena")
		"player_exp": return DB.icon("icon_quest")
		"guild_coin": return DB.icon("icon_guild")
		"friend_point": return DB.icon("icon_heart")
	if k.begins_with("shard:"):
		return DB.face(k.substr(6))
	if k.begins_with("gear:"):
		var gs: String = k.split(":")[1]
		return DB.icon(DB.GEAR[gs]["icon"] if DB.GEAR.has(gs) else "icon_equipment")
	if k.begins_with("rune:"):
		return DB.icon("icon_shards")
	return DB.icon(str(DB.ITEMS.get(k, {}).get("icon", "icon_bag")))

static func fmt(n: int) -> String:
	var neg := n < 0
	var t := str(absi(n))
	var out := ""
	while t.length() > 3:
		out = "," + t.substr(t.length() - 3) + out
		t = t.substr(0, t.length() - 3)
	return ("-" if neg else "") + t + out

func use_item(item_id: String, count: int = 1) -> bool:
	var it: Dictionary = DB.ITEMS.get(item_id, {})
	if it.get("kind", "") == "chest" and amount(item_id) >= count:
		spend(item_id, count)
		var got: Array = []
		for i in count:
			var roll := randf()
			var rar := "R"
			if roll < float(it["rates"].get("SSR", 0.0)):
				rar = "SSR"
			elif roll < float(it["rates"].get("SSR", 0.0)) + float(it["rates"].get("SR", 0.0)):
				rar = "SR"
			var g := add_gear(DB.GEAR_SLOTS[randi() % 3], rar)
			got.append(DB.gear_name(g) + " (" + rar + ")")
		notify("Opened %s: %s" % [it["name"], ", ".join(got)], Color("#7dffb0"))
		return true
	if it.get("kind", "") == "runes" and amount(item_id) >= count:
		spend(item_id, count)
		var got: Array = []
		for i in count * int(it["count"]):
			var rt: String = DB.RUNES.keys()[randi() % DB.RUNES.size()]
			var tier := 1 + (randi() % int(it["max_tier"]))
			add_rune(rt, tier)
			got.append("%s T%d" % [DB.RUNES[rt]["name"], tier])
		notify("Opened %s: %s" % [it["name"], ", ".join(got)], Color("#7dffb0"))
		return true
	if it.get("kind", "") != "use" or amount(item_id) < count:
		return false
	spend(item_id, count)
	var g: Dictionary = {}
	for k in it["give"].keys():
		g[k] = int(it["give"][k]) * count
	give(g)
	notify("Used %s x%d → %s" % [it["name"], count, reward_text(g)], Color("#7dffb0"))
	return true

# =================================================================== player

func energy_max() -> int:
	return 100 + int(s["player"]["level"]) * 2

func _regen_energy() -> void:
	var cur := int(s["cur"]["energy"])
	var mx := energy_max()
	var t := now()
	if cur >= mx:
		s["energy_ts"] = t
		return
	var elapsed := t - int(s["energy_ts"])
	var gained := elapsed / ENERGY_REGEN_SEC
	if gained > 0:
		s["cur"]["energy"] = mini(mx, cur + gained)
		s["energy_ts"] = int(s["energy_ts"]) + gained * ENERGY_REGEN_SEC
		_save_dirty = true

func energy_next_in() -> int:
	if int(s["cur"]["energy"]) >= energy_max():
		return 0
	return ENERGY_REGEN_SEC - (now() - int(s["energy_ts"])) % ENERGY_REGEN_SEC

func player_exp_needed() -> int:
	return 60 + int(s["player"]["level"]) * 40

func add_player_exp(n: int) -> void:
	var p: Dictionary = s["player"]
	p["exp"] = int(p["exp"]) + n
	while int(p["exp"]) >= player_exp_needed():
		p["exp"] = int(p["exp"]) - player_exp_needed()
		p["level"] = int(p["level"]) + 1
		s["cur"]["energy"] = int(s["cur"]["energy"]) + 30
		s["cur"]["gems"] = int(s["cur"]["gems"]) + 50
		notify("PLAYER LEVEL UP! Lv.%d  (+30 Energy, +50 Gems)" % int(p["level"]), Color("#ffd479"))
		for f in DB.FEATURE_UNLOCK.keys():
			if int(DB.FEATURE_UNLOCK[f]) == int(p["level"]) and f != "minigame":
				notify("NEW FEATURE UNLOCKED: %s!" % str(f).capitalize(), Color("#7dffb0"))
				var nu: Array = s.get("new_unlocks", [])
				nu.append(f)
				s["new_unlocks"] = nu

# =================================================================== heroes

func owns(id: String) -> bool:
	return s["heroes"].has(id)

func hero(id: String) -> Dictionary:
	return s["heroes"].get(id, {})

func hero_stats(id: String) -> Dictionary:
	var h := hero(id)
	if h.is_empty():
		return DB.stats_for(id, 1, DB.RARITY_START_STAR[DB.rarity_of(id)])
	return apply_bonus(DB.stats_for(id, h["level"], h["star"], h["bond"], h["oath"]), stat_bonus(id))

func apply_bonus(st: Dictionary, b: Dictionary) -> Dictionary:
	return {"hp": int(st["hp"] * (1.0 + b["hp"])), "atk": int(st["atk"] * (1.0 + b["atk"])), "def": int(st["def"] * (1.0 + b["def"]))}

## Percentage bonuses from equipment + guild level.
func stat_bonus(id: String) -> Dictionary:
	var b := {"hp": 0.0, "atk": 0.0, "def": 0.0}
	for g in s["gear"]:
		if g.get("owner", "") == id:
			var gs := DB.gear_stats(g)
			for k in b.keys():
				b[k] += gs[k]
	var gb := guild_bonus()
	b["hp"] += gb
	b["atk"] += gb
	var pb := companion_bonus()
	b["hp"] += pb
	b["atk"] += pb
	var cb := collection_bonus() + DB.AWAKEN_STAT * int(hero(id).get("awaken", 0))
	for k in b.keys():
		b[k] += cb
	var sk := int(hero(id).get("skin", 0))
	var ob := 0.10 if sk == DB.special_index(id) else DB.outfit_bonus(sk)
	b["atk"] += ob
	b["hp"] += ob
	b["crit"] = 0.0
	for g in s["gear"]:
		if g.get("owner", "") == id:
			var sub := DB.gear_sub_totals(g)
			for k in sub.keys():
				b[k] += sub[k]
	# gear sets (after the flat bonuses so "sets" is never summed)
	var setc := gear_set_counts(id)
	var full: Array = []
	for sid in setc.keys():
		if int(setc[sid]) >= 2:
			var two: Dictionary = DB.GEAR_SETS[sid]["two"]
			for k in two.keys():
				b[k] = float(b.get(k, 0.0)) + float(two[k])
		if int(setc[sid]) >= 3:
			full.append(sid)
	b["sets"] = full
	for r in s["runes"]:
		if r.get("owner", "") == id:
			b[DB.RUNES[r["type"]]["stat"]] = float(b.get(DB.RUNES[r["type"]]["stat"], 0.0)) + DB.rune_value(r)
	return b

func hero_power(id: String) -> int:
	return DB.power_of(hero_stats(id))

func team_power() -> int:
	var p := 0
	for e in s["formation"]:
		p += hero_power(e[0])
	return p

func add_hero(id: String) -> Dictionary:
	if owns(id):
		var n: int = DB.DUPE_SHARDS[DB.rarity_of(id)]
		s["shards"][id] = int(s["shards"].get(id, 0)) + n
		return {"new": false, "shards": n}
	s["heroes"][id] = _new_hero(id)
	return {"new": true, "shards": 0}

const RECRUIT_SHARDS := {"R": 30, "SR": 50, "SSR": 80}

func recruit_with_shards(id: String) -> String:
	if owns(id):
		return "Already recruited."
	var need: int = RECRUIT_SHARDS[DB.rarity_of(id)]
	var have := int(s["shards"].get(id, 0))
	if have < need:
		return "Need %d shards (have %d)." % [need, have]
	s["shards"][id] = have - need
	s["heroes"][id] = _new_hero(id)
	mark_dirty()
	return ""

func level_up(id: String, times: int = 1) -> int:
	var h := hero(id)
	var done := 0
	for i in times:
		if h["level"] >= hero_cap(id):
			break
		var ec := DB.exp_to_next(h["level"])
		var gc := DB.gold_to_next(h["level"])
		if amount("hero_exp") < ec or amount("gold") < gc:
			break
		s["cur"]["hero_exp"] -= ec
		s["cur"]["gold"] -= gc
		h["level"] += 1
		done += 1
	if done > 0:
		quest_progress("levelup")
		mark_dirty()
	return done

func level_up_block_reason(id: String) -> String:
	var h := hero(id)
	if h["level"] >= hero_cap(id):
		if int(h["star"]) >= DB.MAX_STAR:
			return "Level cap reached. Limit Break to raise it further." if int(h.get("lb", 0)) < DB.MAX_LB else "Absolute max level reached!"
		return "Level cap reached. Star Up to raise the cap."
	if amount("hero_exp") < DB.exp_to_next(h["level"]):
		return "Not enough Hero EXP (claim AFK rewards or use EXP Potions)."
	if amount("gold") < DB.gold_to_next(h["level"]):
		return "Not enough Gold."
	return ""

func skill_up_cost(id: String) -> Dictionary:
	var lv := int(hero(id).get("skill_lv", 1))
	return {"skill_book": [1, 2, 3, 5, 0][clampi(lv - 1, 0, 4)], "gold": 8000 * lv}

func skill_up(id: String) -> String:
	var h := hero(id)
	if int(h["skill_lv"]) >= DB.MAX_SKILL_LV:
		return "Skill is already at max level."
	var c := skill_up_cost(id)
	if amount("skill_book") < int(c["skill_book"]):
		return "Need %d Skill Book(s). Get them from the Crystal Sanctum dungeon, Arena Shop or Season Pass." % c["skill_book"]
	if amount("gold") < int(c["gold"]):
		return "Not enough Gold."
	spend("skill_book", c["skill_book"])
	spend("gold", c["gold"])
	h["skill_lv"] = int(h["skill_lv"]) + 1
	quest_progress("levelup")
	mark_dirty()
	return ""

func star_up_cost(id: String) -> Dictionary:
	var h := hero(id)
	return {"shards": DB.shards_for_star(h["star"]), "gold": 5000 * int(h["star"])}

func star_up(id: String) -> String:
	var h := hero(id)
	if h["star"] >= DB.MAX_STAR:
		return "Already at max stars."
	var c := star_up_cost(id)
	var own := int(s["shards"].get(id, 0))
	var uni := amount("star_stone")
	if own + uni < c["shards"]:
		return "Need %d shards (have %d + %d universal)." % [c["shards"], own, uni]
	if amount("gold") < c["gold"]:
		return "Not enough Gold."
	var from_own := mini(own, c["shards"])
	s["shards"][id] = own - from_own
	s["items"]["star_stone"] = uni - (c["shards"] - from_own)
	s["cur"]["gold"] -= c["gold"]
	h["star"] += 1
	var arts := DB.art_list(id)
	if unlocked_skins(id) <= arts.size():
		h["skin"] = clampi(unlocked_skins(id) - 1, 0, arts.size() - 1)
	mark_dirty()
	return ""

## Outfit unlock milestones (Sakura Oath style): stars, bond levels, oath.
func skin_milestones(id: String) -> Array:
	var h := hero(id)
	var start: int = DB.RARITY_START_STAR[DB.rarity_of(id)]
	var star: int = int(h.get("star", start))
	var bond: int = int(h.get("bond", 1))
	var stars: Array = []
	for st in range(start + 1, DB.MAX_STAR + 1):
		stars.append({"label": "%d★" % st, "ok": star >= st})
	var bonds: Array = []
	for b in [4, 7, 10]:
		bonds.append({"label": "Bond %d" % b, "ok": bond >= b})
	var out: Array = []
	# interleave stars and bond milestones, oath last
	while not stars.is_empty() or not bonds.is_empty():
		if not stars.is_empty():
			out.append(stars.pop_front())
		if not bonds.is_empty():
			out.append(bonds.pop_front())
	out.append({"label": "OATH", "ok": bool(h.get("oath", false))})
	return out

## Milestone index (0-based) required to unlock outfit `i` (i >= 1).
func skin_requirement(id: String, i: int) -> int:
	var m := skin_milestones(id).size()
	var extra := DB.art_list(id).size() - 1
	if extra <= m:
		return i - 1
	return int(ceil(float(i) * m / extra)) - 1

func skin_unlocked(id: String, i: int) -> bool:
	if i == 0:
		return true
	if not owns(id):
		return false
	if (s["skins_bought"].get(id, []) as Array).has(i):
		return true
	if i == DB.special_index(id):
		return false    # special skins come only from the Wardrobe
	var ms := skin_milestones(id)
	return bool(ms[clampi(skin_requirement(id, i), 0, ms.size() - 1)]["ok"])

func skin_lock_label(id: String, i: int) -> String:
	if i == DB.special_index(id):
		return "SPECIAL • WARDROBE"
	var ms := skin_milestones(id)
	return str(ms[clampi(skin_requirement(id, i), 0, ms.size() - 1)]["label"])

## Highest unlocked outfit index + 1 (used to auto-equip new outfits).
func unlocked_skins(id: String) -> int:
	var n := 1
	for i in range(1, DB.art_list(id).size()):
		if skin_unlocked(id, i):
			n = i + 1
	return n

func set_skin(id: String, idx: int) -> void:
	if skin_unlocked(id, idx):
		hero(id)["skin"] = idx
		mark_dirty()

func add_bond(id: String, n: int) -> bool:
	var h := hero(id)
	if h.is_empty() or h["bond"] >= DB.MAX_BOND:
		return false
	h["bond_exp"] += n
	var leveled := false
	while h["bond"] < DB.MAX_BOND and h["bond_exp"] >= DB.bond_to_next(h["bond"]):
		h["bond_exp"] -= DB.bond_to_next(h["bond"])
		h["bond"] += 1
		leveled = true
	if h["bond"] >= DB.MAX_BOND:
		h["bond_exp"] = 0
	if leveled:
		bond_up.emit(id, int(h["bond"]))
	mark_dirty()
	return leveled

func give_gift(id: String, item_id: String) -> String:
	if amount(item_id) <= 0:
		return "You have no %s." % DB.ITEMS[item_id]["name"]
	if hero(id)["bond"] >= DB.MAX_BOND:
		return "Bond is already at max level."
	spend(item_id, 1)
	var mult := 2 if DB.fav_gift(id) == item_id else 1
	var up := add_bond(id, int(DB.ITEMS[item_id]["bond"]) * mult)
	quest_progress("bond")
	sfx("star_up")
	if up:
		notify("%s Bond Lv.%d! ♥" % [DB.name_of(id), hero(id)["bond"]], Color("#ff8fb8"))
	return ""

func tap_hero(id: String) -> String:
	var h := hero(id)
	if h.is_empty():
		return ""
	quest_progress("bond")
	if int(s["quests"]["progress"].get("tap_" + id, 0)) < 5:
		s["quests"]["progress"]["tap_" + id] = int(s["quests"]["progress"].get("tap_" + id, 0)) + 1
		add_bond(id, 4)
	var cat := "tap"
	if h["oath"] or (int(h["bond"]) >= 5 and randf() < 0.5):
		cat = "bond"
	elif randf() < 0.3:
		cat = "greet"
	return voice(id, cat)

## "5 Nov 2026" style date the Oath was sworn (older saves: "a day to remember").
func oath_date(id: String) -> String:
	var d := str(hero(id).get("oath_date", ""))
	if d.length() < 10:
		return "a day to remember"
	var p := d.split("-")
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%d %s %s" % [int(p[2]), months[clampi(int(p[1]) - 1, 0, 11)], p[0]]

func swear_oath(id: String) -> String:
	var h := hero(id)
	if h["oath"]:
		return "Already sworn."
	if h["bond"] < DB.MAX_BOND:
		return "Requires Bond Lv.%d." % DB.MAX_BOND
	if not spend("oath_ring", 1):
		return "You need an Oath Ring (Arena Shop)."
	h["oath"] = true
	h["oath_date"] = Time.get_date_string_from_system()
	s["stats"]["oaths"] = int(s["stats"]["oaths"]) + 1
	h["skin"] = unlocked_skins(id) - 1
	mark_dirty()
	return ""

# =================================================================== formation

func formation() -> Array:
	return s["formation"]

func formation_cell_of(id: String) -> Vector2i:
	for e in s["formation"]:
		if e[0] == id:
			return Vector2i(e[1], e[2])
	return Vector2i(-1, -1)

func formation_at(cell: Vector2i) -> String:
	for e in s["formation"]:
		if e[1] == cell.x and e[2] == cell.y:
			return e[0]
	return ""

func place_hero(id: String, cell: Vector2i) -> String:
	var occupant := formation_at(cell)
	var old := formation_cell_of(id)
	if occupant == id:
		return ""
	if old.x >= 0:
		# Moving a deployed hero: swap with the occupant if any.
		for e in s["formation"]:
			if e[0] == id:
				e[1] = cell.x
				e[2] = cell.y
			elif e[0] == occupant:
				e[1] = old.x
				e[2] = old.y
	elif occupant != "":
		for e in s["formation"]:
			if e[0] == occupant:
				e[0] = id
	else:
		if s["formation"].size() >= DB.MAX_DEPLOY:
			return "Max %d heroes can be deployed." % DB.MAX_DEPLOY
		s["formation"].append([id, cell.x, cell.y])
	mark_dirty()
	return ""

func remove_hero(id: String) -> void:
	for i in range(s["formation"].size() - 1, -1, -1):
		if s["formation"][i][0] == id:
			s["formation"].remove_at(i)
	mark_dirty()

func move_order(id: String, dir: int) -> void:
	var f: Array = s["formation"]
	for i in f.size():
		if f[i][0] == id:
			var j := clampi(i + dir, 0, f.size() - 1)
			var tmp = f[i]
			f[i] = f[j]
			f[j] = tmp
			break
	mark_dirty()

## Builds the strongest team. `prefer` (an element group) counts as its +30% ATK advantage.
func auto_formation(prefer: String = "") -> void:
	var ids: Array = s["heroes"].keys()
	var score := func(id: String) -> float:
		return hero_power(id) * (1.3 if prefer != "" and DB.ELEMENT_GROUP.get(DB.element_of(id), "") == prefer else 1.0)
	ids.sort_custom(func(a, b): return score.call(a) > score.call(b))
	ids = ids.slice(0, DB.MAX_DEPLOY)
	var front: Array = []
	var mid: Array = []
	var back: Array = []
	for id in ids:
		var r := DB.role_of(id)
		if r in ["TANK", "PALADIN", "KNIGHT", "WARRIOR"]:
			front.append(id)
		elif r in ["HEALER", "BUFFER"]:
			mid.append(id)
		else:
			back.append(id)
	var f: Array = []
	var rows := [1, 0, 2]
	for col_list in [[0, front], [1, mid], [2, back]]:
		var col: int = col_list[0]
		var i := 0
		for id in col_list[1]:
			if i < 3:
				f.append([id, col, rows[i]])
			else:
				# overflow into the next free cell
				for c in 3:
					var placed := false
					for r in 3:
						var taken := false
						for e in f:
							if e[1] == c and e[2] == r:
								taken = true
						if not taken:
							f.append([id, c, r])
							placed = true
							break
					if placed:
						break
			i += 1
	# Action order: damage dealers & tanks first, healers last (BD-style strategy)
	f.sort_custom(func(a, b): return DB.role_of(a[0]) not in ["HEALER", "BUFFER"] and DB.role_of(b[0]) in ["HEALER", "BUFFER"])
	s["formation"] = f
	mark_dirty()

# =================================================================== story

func stage_stars(index: int) -> int:
	return int(s["story"]["cleared"].get(DB.stage_id(index), 0))

func story_progress() -> int:
	## Index of the furthest unlocked stage.
	var i := 0
	while i < DB.stage_count() and stage_stars(i) > 0:
		i += 1
	return mini(i, DB.stage_count() - 1)

func stages_cleared() -> int:
	return s["story"]["cleared"].size()

func apply_stage_result(index: int, won: bool, stars: int) -> Dictionary:
	var st := DB.stage(index)
	if not won:
		# Partial energy refund on defeat, like most gacha RPGs.
		s["cur"]["energy"] = int(s["cur"]["energy"]) + int(st["energy"]) / 2
		mark_dirty()
		return {}
	var first := stage_stars(index) == 0
	var rewards := {"gold": st["gold"], "hero_exp": st["hero_exp"], "player_exp": st["player_exp"]}
	if first:
		rewards["gems"] = st["first_gems"]
		for k in st["first_items"].keys():
			rewards[k] = st["first_items"][k]
		if st["boss"]:
			for k in DB.CHAPTER_REWARD.keys():
				rewards[k] = int(rewards.get(k, 0)) + int(DB.CHAPTER_REWARD[k])
			rewards["chapter_clear"] = int(st["chapter"]) + 1
	# Random shard drop for a non-owned or owned R/SR hero
	if randf() < 0.35:
		var pool: Array = []
		for id in DB.HEROES.keys():
			if DB.rarity_of(id) != "SSR":
				pool.append(id)
		rewards["shard:" + str(pool[randi() % pool.size()])] = 2
	if st["boss"] or randf() < 0.3:
		var ch: int = st["chapter"]
		var rar := "R"
		var roll := randf()
		if roll < 0.02 + ch * 0.02 + (0.1 if st["boss"] else 0.0):
			rar = "SSR"
		elif roll < 0.25 + ch * 0.06:
			rar = "SR"
		rewards["gear:%s:%s" % [DB.GEAR_SLOTS[randi() % 3], rar]] = 1
	s["story"]["cleared"][DB.stage_id(index)] = maxi(stars, stage_stars(index))
	quest_progress("stage")
	var g := rewards.duplicate()
	g.erase("chapter_clear")
	give(g)
	return rewards

func sweep_stage(index: int, times: int, hard: bool = false) -> Dictionary:
	if hard:
		return _sweep_hard(index, times)
	var st := DB.stage(index)
	if stage_stars(index) < 3:
		return {"error": "Clear this stage with 3★ to unlock Sweep."}
	var cost := int(st["energy"]) * times
	if amount("energy") < cost:
		return {"error": "Not enough Energy."}
	spend("energy", cost)
	var total := {"gold": int(st["gold"]) * times, "hero_exp": int(st["hero_exp"]) * times, "player_exp": int(st["player_exp"]) * times}
	for i in times:
		quest_progress("stage")
	give(total)
	return total

# =================================================================== AFK

func afk_rate() -> Dictionary:
	var c := stages_cleared()
	return {"gold": 900 + c * 160, "hero_exp": 600 + c * 110}  # per hour

func afk_pending() -> Dictionary:
	var secs := clampi(now() - int(s["afk_ts"]), 0, AFK_CAP_SEC)
	var r := afk_rate()
	return {"secs": secs, "gold": int(r["gold"] * secs / 3600.0), "hero_exp": int(r["hero_exp"] * secs / 3600.0)}

func claim_afk() -> Dictionary:
	var p := afk_pending()
	if p["secs"] < 60:
		return {}
	var rewards := {"gold": p["gold"], "hero_exp": p["hero_exp"]}
	if p["secs"] >= 4 * 3600 and randf() < 0.5:
		rewards["exp_potion"] = 1
	s["afk_ts"] = now()
	quest_progress("afk")
	give(rewards)
	return rewards

# =================================================================== gacha

func can_free_pull() -> bool:
	return int(s["gacha"]["free_day"]) != day_key()

## How a summon of `count` is paid: tickets first, Gems cover the rest.
func pull_pay(count: int) -> String:
	var tk := amount("summon_ticket")
	return "ticket" if tk >= count else ("mixed" if tk > 0 else "gems")

func pull(banner_id: String, count: int, pay: String) -> Dictionary:
	var banner: Dictionary = {}
	for b in DB.BANNERS:
		if b["id"] == banner_id:
			banner = b
	if pay == "free":
		if not can_free_pull() or count != 1:
			return {"error": "Free summon already used today."}
		s["gacha"]["free_day"] = day_key()
	elif pay == "ticket":
		if not spend("summon_ticket", count):
			return {"error": "Not enough Summon Tickets."}
	elif pay == "mixed":
		var tk := mini(amount("summon_ticket"), count)
		if amount("gems") < DB.GACHA_COST * (count - tk):
			return {"error": "Not enough Gems."}
		spend("summon_ticket", tk)
		spend("gems", DB.GACHA_COST * (count - tk))
	else:
		if not spend("gems", DB.GACHA_COST * count):
			return {"error": "Not enough Gems."}
	var results: Array = []
	var got_sr := false
	for i in count:
		s["gacha"]["pity"] = int(s["gacha"]["pity"]) + 1
		var roll := randf()
		var rarity := "R"
		if int(s["gacha"]["pity"]) >= DB.GACHA_PITY or roll < DB.GACHA_RATES["SSR"]:
			rarity = "SSR"
		elif roll < DB.GACHA_RATES["SSR"] + DB.GACHA_RATES["SR"]:
			rarity = "SR"
		if count >= 10 and i == count - 1 and not got_sr and rarity == "R":
			rarity = "SR"
		if count >= 10 and i == count - 1 and not bool(s["gacha"].get("first10_done", false)) and not results.any(func(x): return x["rarity"] == "SSR") and rarity != "SSR":
			rarity = "SSR"
		if rarity != "R":
			got_sr = true
		if rarity == "SSR":
			s["gacha"]["pity"] = 0
		var pool: Array = []
		for id in DB.HEROES.keys():
			if DB.rarity_of(id) == rarity:
				pool.append(id)
		var id: String = pool[randi() % pool.size()]
		# rate-up: half of the pulls of the featured hero's rarity become her (SSR banners and SR/R pick-ups)
		if str(banner.get("featured", "")) != "" and DB.rarity_of(str(banner["featured"])) == rarity and randf() < 0.5:
			id = banner["featured"]
		var res := add_hero(id)
		res["id"] = id
		res["rarity"] = rarity
		results.append(res)
		if str(banner.get("featured", "")) != "":
			var sp: Dictionary = s["gacha"].get("spark", {})
			sp[banner_id] = int(sp.get(banner_id, 0)) + 1
			s["gacha"]["spark"] = sp
		var hist: Array = s["gacha"].get("history", [])
		hist.push_front({"id": id, "r": rarity, "t": now(), "b": banner_id})
		if hist.size() > 100:
			hist.resize(100)
		s["gacha"]["history"] = hist
	if count >= 10:
		s["gacha"]["first10_done"] = true
	s["gacha"]["total"] = int(s["gacha"]["total"]) + count
	for i in count:
		quest_progress("summon")
	mark_dirty()
	save_game()
	return {"results": results}

# =================================================================== quests & achievements

func quest_progress(qid: String, n: int = 1) -> void:
	for wq in DB.WEEKLY_QUESTS:
		if wq["src"] == qid:
			var wp: Dictionary = s["weekly"]["progress"]
			wp[wq["id"]] = int(wp.get(wq["id"], 0)) + n
	if DB.PASS_EXP.has(qid):
		add_pass_exp(int(DB.PASS_EXP[qid]) * n)
	var p: Dictionary = s["quests"]["progress"]
	p[qid] = int(p.get(qid, 0)) + n
	_save_dirty = true

func quest_state(q: Dictionary) -> String:
	if s["quests"]["claimed"].get(q["id"], false):
		return "claimed"
	if int(s["quests"]["progress"].get(q["id"], 0)) >= int(q["target"]):
		return "ready"
	return "progress"

func claim_quest(q: Dictionary) -> bool:
	if quest_state(q) != "ready":
		return false
	s["quests"]["claimed"][q["id"]] = true
	quest_progress("quest")   # also grants Pass EXP via DB.PASS_EXP["quest"]
	give(q["give"])
	return true

func stat_value(stat: String) -> int:
	match stat:
		"stages_cleared": return stages_cleared()
		"heroes_owned": return s["heroes"].size()
		"total_pulls": return int(s["gacha"]["total"])
		"tower_floor": return int(s["tower"]["floor"]) - 1
		"max_star":
			var m := 0
			for id in s["heroes"].keys():
				m = maxi(m, int(s["heroes"][id]["star"]))
			return m
		"oaths": return int(s["stats"]["oaths"])
		"max_skill":
			var m2 := 0
			for id in s["heroes"].keys():
				m2 = maxi(m2, int(s["heroes"][id].get("skill_lv", 1)))
			return m2
		"memories":
			var n := 0
			for id in s["bond_stories"].keys():
				n += (s["bond_stories"][id] as Array).size()
			return n
		"pass_level": return pass_level()
		"hard_cleared": return (s["story"].get("hard", {}) as Dictionary).size()
	return 0

func achievement_state(a: Dictionary) -> String:
	if s["achievements"].get(a["id"], false):
		return "claimed"
	return "ready" if stat_value(a["stat"]) >= int(a["target"]) else "progress"

func claim_achievement(a: Dictionary) -> bool:
	if achievement_state(a) != "ready":
		return false
	s["achievements"][a["id"]] = true
	give(a["give"])
	return true

func badge_quests() -> int:
	var n := 0
	for wq in DB.WEEKLY_QUESTS:
		if weekly_state(wq) == "ready":
			n += 1
	for q in DB.DAILY_QUESTS:
		if quest_state(q) == "ready":
			n += 1
	for a in DB.ACHIEVEMENTS:
		if achievement_state(a) == "ready":
			n += 1
	return n

# =================================================================== mail & shop

func mail_unclaimed() -> int:
	var n := 0
	for m in DB.MAIL:
		if not s["mail_claimed"].has(m["id"]):
			n += 1
	return n

func claim_mail(id: String) -> Dictionary:
	for m in DB.MAIL:
		if m["id"] == id and not s["mail_claimed"].has(id):
			s["mail_claimed"].append(id)
			give(m["give"])
			return m["give"]
	return {}

func shop_bought(id: String) -> int:
	return int(s["shop"]["bought"].get(id, 0))

func buy(item: Dictionary) -> String:
	if shop_bought(item["id"]) >= int(item["limit"]):
		return "Sold out for today."
	if int(item["price"]) > 0 and not spend(item["cur"], int(item["price"])):
		return "Not enough %s." % reward_name(item["cur"])
	s["shop"]["bought"][item["id"]] = shop_bought(item["id"]) + 1
	give(item["give"])
	return ""

# =================================================================== arena & tower

const ARENA_NAMES := ["Valkyrie_Queen", "ShadowReaper", "DarkArchon", "AstralKnight", "NyxBlade", "Seraphim07", "LunaticFox", "IronMaiden", "CrimsonOath", "AbyssWalker"]

func arena_opponents() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = day_key() * 31 + int(s["arena"]["refresh"]) * 977
	var avg := 1
	var stars := 1
	var n := 0
	for e in s["formation"]:
		avg += int(hero(e[0])["level"])
		stars += int(hero(e[0])["star"])
		n += 1
	avg = maxi(1, avg / maxi(1, n))
	stars = maxi(1, stars / maxi(1, n))
	var out: Array = []
	var ids: Array = DB.HEROES.keys()
	for i in 4:
		var lvl := maxi(1, avg + rng.randi_range(-3, 4) + i)
		var team: Array = []
		var used: Array = []
		var pool := ids.duplicate()
		for k in 5:
			var hid: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			var cell := Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
			while used.has(cell):
				cell = Vector2i(rng.randi_range(0, 2), rng.randi_range(0, 2))
			used.append(cell)
			team.append({"id": hid, "cell": cell, "level": lvl, "star": clampi(stars + rng.randi_range(-1, 1), 1, 6)})
		var pw := 0
		for u in team:
			pw += DB.power_of(DB.stats_for(u["id"], u["level"], u["star"]))
		out.append({"name": ARENA_NAMES[rng.randi_range(0, ARENA_NAMES.size() - 1)], "rp": int(s["arena"]["rp"]) + rng.randi_range(-80, 120), "team": team, "power": pw})
	return out

func apply_arena_result(won: bool) -> Dictionary:
	var a: Dictionary = s["arena"]
	quest_progress("arena")
	if won:
		a["rp"] = int(a["rp"]) + 24
		a["wins"] = int(a["wins"]) + 1
		var r := {"arena_coin": 60, "gold": 3000}
		if randf() < 0.3:
			r["rune:%s:%d" % [DB.RUNES.keys()[randi() % 4], 1 + randi() % 2]] = 1
		give(r)
		return r
	a["rp"] = maxi(0, int(a["rp"]) - 12)
	a["losses"] = int(a["losses"]) + 1
	var r2 := {"arena_coin": 15}
	give(r2)
	return r2

## Battle context helpers. params: {mode: story|arena|tower, stage|opp|floor}
func enemies_for(params: Dictionary) -> Array:
	match str(params.get("mode", "")):
		"story":
			return DB.stage(int(params["stage"]))["enemies"]
		"arena":
			return arena_opponents()[int(params["opp"])]["team"]
		"tower":
			return DB.tower_floor(int(params["floor"]))["enemies"]
		"event":
			return DB.event_stage(int(params["stage"]))["enemies"]
		"hard":
			return DB.hard_stage(int(params["stage"]))["enemies"]
		"raid":
			return DB.raid_boss(int(s["guild"]["raid_lv"]))
		"hunt":
			return DB.hunt_stage(str(params["hunt"]), int(params["diff"]))["enemies"]
		"rift":
			return DB.rift_floor(int(_rift()["floor"]), day_key() / 7)["enemies"]
		"trial":
			return DB.trial_stage(str(params["hero"]), int(params["tier"]))["enemies"]
		"wboss":
			return [{"id": wboss()["id"], "cell": Vector2i(1, 1), "level": _avg_level() + 8, "boss": true, "raid": true, "elite": true, "star": 5}]
		"dungeon":
			return DB.dungeon_stage(str(params["dungeon"]), int(params["diff"]))["enemies"]
	return []

func battle_title(params: Dictionary) -> String:
	match str(params.get("mode", "")):
		"story":
			var st := DB.stage(int(params["stage"]))
			return "STAGE %s  •  %s" % [st["id"], st["name"]]
		"arena":
			return "ARENA  •  vs %s" % arena_opponents()[int(params["opp"])]["name"]
		"tower":
			return "TOWER OF TRIALS  •  FLOOR %d" % int(params["floor"])
		"event":
			return "%s  •  %s" % [DB.EVENT["name"].to_upper(), DB.event_stage(int(params["stage"]))["name"]]
		"hard":
			var hs := DB.hard_stage(int(params["stage"]))
			return "STAGE %s  •  %s" % [hs["id"], hs["name"]]
		"raid":
			return "GUILD RAID  •  Ygg-Naar Lv.%d" % int(s["guild"]["raid_lv"])
		"wboss":
			return "WORLD BOSS  •  " + str(wboss()["name"])
		"hunt":
			return "BOSS HUNT  •  " + str(DB.hunt_stage(str(params["hunt"]), int(params["diff"]))["name"])
		"rift":
			return "STARLIGHT RIFT  •  FLOOR %d" % int(_rift()["floor"])
		"trial":
			return "HERO TRIAL  •  " + str(DB.trial_stage(str(params["hero"]), int(params["tier"]))["name"])
		"dungeon":
			return "DAILY DUNGEON  •  " + str(DB.dungeon_stage(str(params["dungeon"]), int(params["diff"]))["name"])
	return "BATTLE"

func battle_bg(params: Dictionary) -> String:
	match str(params.get("mode", "")):
		"story":
			var st := DB.stage(int(params["stage"]))
			return "boss" if st["boss"] else str(st["bg"])
		"arena":
			return "battle"
		"tower":
			return str(DB.tower_floor(int(params["floor"]))["bg"])
		"event":
			return str(DB.EVENT["bg"])
		"hard":
			var hs2 := DB.hard_stage(int(params["stage"]))
			return "boss" if hs2["boss"] else str(hs2["bg"])
		"raid":
			return "boss"
		"wboss":
			return str(wboss()["bg"])
		"hunt":
			return str(DB.hunt_def(str(params["hunt"]))["bg"])
		"rift":
			return str(DB.rift_floor(int(_rift()["floor"]), day_key() / 7)["bg"])
		"trial":
			return str(DB.trial_stage(str(params["hero"]), int(params["tier"]))["bg"])
		"dungeon":
			return str(DB.dungeon_def(str(params["dungeon"]))["bg"])
	return "battle"

## Battle-ready ally list from the current formation (+ optional friend support).
func ally_team(params: Dictionary = {}) -> Array:
	var allies: Array = []
	var links := active_links()
	var rift_b: Array = rift_blessings() if str(params.get("mode", "")) == "rift" else []
	for e in s["formation"]:
		var h := hero(e[0])
		var bonus: Dictionary = stat_bonus(e[0]).duplicate()
		for l in links:
			if (l["heroes"] as Array).has(e[0]):
				for k in l["bonus"].keys():
					bonus[k] = float(bonus.get(k, 0.0)) + float(l["bonus"][k])
		for bl in rift_b:
			if bl.has("elem") and DB.ELEMENT_GROUP.get(DB.element_of(e[0]), "") != str(bl["elem"]):
				continue
			for k in bl["bonus"].keys():
				bonus[k] = float(bonus.get(k, 0.0)) + float(bl["bonus"][k])
		allies.append({"id": e[0], "cell": Vector2i(e[1], e[2]), "level": h["level"], "star": h["star"], "bond": h["bond"], "oath": h["oath"], "bonus": bonus, "skill_lv": h["skill_lv"], "awaken": h["awaken"]})
	if params.has("support"):
		var sp: Dictionary = params["support"]
		allies.append({"id": sp["id"], "cell": sp["cell"], "level": sp["level"], "star": sp["star"]})
	return allies

## Resolves a battle instantly (used by Auto-Repeat). Returns {won, stars, rewards} or {error}.
func quick_battle(params: Dictionary) -> Dictionary:
	var err := pay_battle(params)
	if err != "":
		return {"error": err}
	var sim := BattleSim.new()
	sim.setup(ally_team(params), enemies_for(params), 0, battle_mod(params))
	sim.tactic = equipped_tactic()
	sim.companion = companion_assist()
	var res := sim.run()
	record_kills(killed_enemies(sim))
	var won: bool = res["won"]
	var stars: int = res["stars"]
	var r: Dictionary = {}
	match str(params.get("mode", "")):
		"story":
			r = apply_stage_result(int(params["stage"]), won, stars)
			r.erase("chapter_clear")
		"event":
			r = apply_event_result(int(params["stage"]), won, stars)
		"dungeon":
			r = apply_dungeon_result(str(params["dungeon"]), int(params["diff"]), won)
		"hard":
			r = apply_hard_result(int(params["stage"]), won, stars)
		"hunt":
			r = apply_hunt_result(str(params["hunt"]), int(params["diff"]), won)
		"rift":
			r = apply_rift_result(won)
	if won:
		var ft := festival_drop(str(params.get("mode", "")))
		if ft > 0:
			r["season_token"] = ft
	return {"won": won, "stars": stars, "rewards": r}

func battle_mod(params: Dictionary) -> Dictionary:
	if str(params.get("mode", "")) in ["story", "hard"]:
		return DB.stage(int(params["stage"])).get("mod", {})
	if str(params.get("mode", "")) == "wboss":
		return wboss()["mod"]
	if str(params.get("mode", "")) == "hunt":
		return DB.hunt_stage(str(params["hunt"]), int(params["diff"]))["mod"]
	return {}

func enemy_power(enemies: Array) -> int:
	var p := 0
	for e in enemies:
		var st := DB.stats_for(e["id"], int(e.get("level", 1)), int(e.get("star", 1)))
		p += DB.power_of(st) * (3 if e.get("boss", false) else 1)
	return p

## What to bring against `enemies`: their main element (bosses weigh 3x), the element that
## counters it, the owned heroes of that element (strongest first) and how many are deployed.
func scout(enemies: Array) -> Dictionary:
	var weight := {}
	for e in enemies:
		var g: String = DB.ELEMENT_GROUP.get(DB.element_of(e["id"]), "")
		if g != "":
			weight[g] = int(weight.get(g, 0)) + (3 if e.get("boss", false) else 1)
	var top := ""
	for g in weight.keys():
		if top == "" or int(weight[g]) > int(weight[top]):
			top = g
	var counter := DB.counter_of(top)
	if counter == "":
		return {}
	var heroes: Array = s["heroes"].keys().filter(func(id): return DB.ELEMENT_GROUP.get(DB.element_of(id), "") == counter)
	heroes.sort_custom(func(a, b): return hero_power(a) > hero_power(b))
	var deployed: int = s["formation"].filter(func(e): return heroes.has(e[0])).size()
	return {"main": top, "counter": counter, "heroes": heroes, "deployed": deployed}

## The most useful single piece of advice after losing to `enemies`.
func defeat_tip(enemies: Array) -> String:
	var ep := enemy_power(enemies)
	var tp := team_power()
	if tp * 10 < ep * 7:
		return "This enemy is far stronger (Power %s vs your %s). Level up or Star Up your team first." % [fmt(ep), fmt(tp)]
	var sc := scout(enemies)
	if not sc.is_empty() and int(sc["deployed"]) == 0:
		if (sc["heroes"] as Array).is_empty():
			return "These enemies are mostly %s. %s heroes deal +30%% ATK to them, so look for one at the Aether Gate." % [sc["main"], sc["counter"]]
		return "These enemies are mostly %s. Bring %s: %s heroes deal +30%% ATK to them." % [sc["main"], DB.name_of(sc["heroes"][0]).split(" ")[0], sc["counter"]]
	return "Move tanks to the front column and line heroes up with the rows of key enemies."

## Pays the entry cost. Returns "" on success or an error message.
func pay_battle(params: Dictionary) -> String:
	match str(params.get("mode", "")):
		"story":
			var cost: int = DB.stage(int(params["stage"]))["energy"]
			if not spend("energy", cost):
				return "Not enough Energy (%d needed). Buy Energy Flasks in the Shop." % cost
		"arena":
			if int(s["arena"]["tickets"]) <= 0:
				return "No Arena tickets left today."
			s["arena"]["tickets"] = int(s["arena"]["tickets"]) - 1
			mark_dirty()
		"event":
			if not spend("energy", 8):
				return "Not enough Energy (8 needed)."
		"hard":
			var hc: int = DB.hard_stage(int(params["stage"]))["energy"]
			if not spend("energy", hc):
				return "Not enough Energy (%d needed)." % hc
		"dungeon":
			if dungeon_tries(str(params["dungeon"])) <= 0:
				return "No attempts left for this dungeon today."
			s["dungeon"]["tries"][str(params["dungeon"])] = DB.DUNGEON_TRIES - dungeon_tries(str(params["dungeon"])) + 1
			mark_dirty()
		"trial":
			var tid := str(params["hero"])
			if not s["formation"].any(func(e): return e[0] == tid):
				return "%s must be in your team for her Trial." % DB.name_of(tid).split(" ")[0]
		"hunt":
			if hunt_tries() <= 0:
				return "No hunts left today."
			s["hunt"]["used"] = int(s["hunt"]["used"]) + 1
			mark_dirty()
		"wboss":
			if int(s["wboss"]["tries"]) <= 0:
				return "No World Boss attempts left today."
			s["wboss"]["tries"] = int(s["wboss"]["tries"]) - 1
			mark_dirty()
		"raid":
			if int(s["guild"]["raid_tries"]) <= 0:
				return "No raid attempts left today."
			s["guild"]["raid_tries"] = int(s["guild"]["raid_tries"]) - 1
			mark_dirty()
	return ""

func apply_tower_result(floor_no: int, won: bool) -> Dictionary:
	if not won or floor_no != int(s["tower"]["floor"]):
		return {}
	var t := DB.tower_floor(floor_no)
	var r := {"gems": t["gems"], "gold": t["gold"]}
	for k in t["items"].keys():
		r[k] = t["items"][k]
	if floor_no % 5 == 0:
		r["gear:%s:%s" % [DB.GEAR_SLOTS[randi() % 3], "SSR" if floor_no >= 20 else "SR"]] = 1
		r["rune:%s:%d" % [DB.RUNES.keys()[randi() % 4], clampi(1 + floor_no / 10, 1, 4)]] = 1
	elif randf() < 0.4:
		r["gear:%s:%s" % [DB.GEAR_SLOTS[randi() % 3], "SR" if randf() < 0.3 + floor_no * 0.02 else "R"]] = 1
	s["tower"]["floor"] = floor_no + 1
	give(r)
	return r

# =================================================================== equipment

func add_gear(slot: String, rarity: String, set_id: String = "") -> Dictionary:
	s["gear_uid"] = int(s["gear_uid"]) + 1
	var sid: String = set_id if DB.GEAR_SETS.has(set_id) else DB.GEAR_SET_IDS[randi() % DB.GEAR_SET_IDS.size()]
	var g := {"uid": int(s["gear_uid"]), "slot": slot, "rarity": rarity, "lv": 0, "owner": "", "set": sid, "subs": []}
	_fill_subs(g)
	s["gear"].append(g)
	return g

## Rolls substats until the piece has as many as its rarity allows.
func _fill_subs(g: Dictionary) -> void:
	var subs: Array = g["subs"]
	while subs.size() < int(DB.GEAR_SUB_COUNT[g["rarity"]]):
		subs.append(DB.roll_gear_sub(subs.map(func(sb): return sb["k"])))

## Gear from saves older than substats: roll them once, with the upgrades its level has earned.
func _ensure_gear_subs() -> void:
	for g in s["gear"]:
		if g.has("subs"):
			continue
		g["subs"] = []
		_fill_subs(g)
		for lv in DB.GEAR_SUB_UP_LV:
			if int(g["lv"]) >= int(lv):
				_upgrade_sub(g)

func _upgrade_sub(g: Dictionary) -> Dictionary:
	var sb: Dictionary = g["subs"][randi() % g["subs"].size()]
	sb["up"] = int(sb.get("up", 0)) + 1
	return sb

## {set id: pieces worn} for a hero.
func gear_set_counts(id: String) -> Dictionary:
	var c := {}
	for g in s["gear"]:
		if g.get("owner", "") == id:
			var sid := DB.gear_set(g)
			c[sid] = int(c.get(sid, 0)) + 1
	return c

func gear_by_uid(uid: int) -> Dictionary:
	for g in s["gear"]:
		if int(g["uid"]) == uid:
			return g
	return {}

func gear_on(id: String, slot: String) -> Dictionary:
	for g in s["gear"]:
		if g["owner"] == id and g["slot"] == slot:
			return g
	return {}

func equip(uid: int, id: String) -> void:
	var g := gear_by_uid(uid)
	if g.is_empty():
		return
	var cur := gear_on(id, g["slot"])
	if not cur.is_empty():
		cur["owner"] = ""
	g["owner"] = id
	mark_dirty()

func unequip(uid: int) -> void:
	var g := gear_by_uid(uid)
	if not g.is_empty():
		g["owner"] = ""
		mark_dirty()

func enhance_gear(uid: int) -> String:
	var g := gear_by_uid(uid)
	if g.is_empty():
		return "Item not found."
	last_sub_up = {}
	if int(g["lv"]) >= DB.GEAR_MAX_LV:
		return "Already at +%d." % DB.GEAR_MAX_LV
	var c := DB.gear_enhance_cost(g)
	if not spend("gold", c):
		return "Need %s Gold." % fmt(c)
	g["lv"] = int(g["lv"]) + 1
	if DB.GEAR_SUB_UP_LV.has(int(g["lv"])):
		last_sub_up = _upgrade_sub(g)
	quest_progress("levelup")
	mark_dirty()
	return ""

func salvage_gear(uid: int) -> int:
	for i in s["gear"].size():
		var g: Dictionary = s["gear"][i]
		if int(g["uid"]) == uid:
			if str(g.get("owner", "")) != "" or g.get("lock", false):
				return 0
			var gold := salvage_gold(g)
			var embers := salvage_embers(g)
			s["gear"].remove_at(i)
			give({"gold": gold, "forge_ember": embers})
			return gold
	return 0

func salvage_gold(g: Dictionary) -> int:
	return int({"R": 800, "SR": 3000, "SSR": 12000}[g["rarity"]] + DB.gear_enhance_cost(g) * int(g["lv"]) * 0.5)

func salvage_embers(g: Dictionary) -> int:
	return int(DB.GEAR_EMBERS[g["rarity"]]) + int(g["lv"]) / 2

func toggle_gear_lock(uid: int) -> bool:
	var g := gear_by_uid(uid)
	g["lock"] = not g.get("lock", false)
	mark_dirty()
	return g["lock"]

## Gear a bulk salvage would destroy: free, unlocked, and un-enhanced unless asked.
func salvage_list(rarities: Array, enhanced: bool) -> Array:
	return s["gear"].filter(func(g): return rarities.has(g["rarity"]) and str(g.get("owner", "")) == "" and not g.get("lock", false) and (enhanced or int(g["lv"]) == 0))

func salvage_bulk(rarities: Array, enhanced: bool) -> Dictionary:
	var out := {"count": 0, "gold": 0, "forge_ember": 0}
	for g in salvage_list(rarities, enhanced):
		out["forge_ember"] += salvage_embers(g)
		out["gold"] += salvage_gear(int(g["uid"]))
		out["count"] += 1
	return out

## Reforge: change a piece's set for Embers (keeps rarity, level and owner).
func reforge_gear(uid: int, set_id: String) -> String:
	var g := gear_by_uid(uid)
	if g.is_empty() or not DB.GEAR_SETS.has(set_id):
		return "Item not found."
	if DB.gear_set(g) == set_id:
		return "It already belongs to that set."
	if not spend("forge_ember", int(DB.REFORGE_COST[g["rarity"]])):
		return "Need %d Forge Embers." % int(DB.REFORGE_COST[g["rarity"]])
	g["set"] = set_id
	mark_dirty()
	return ""

## The 2 pieces a fusion would consume: free, unlocked, same rarity, weakest first.
func fuse_fodder(uid: int) -> Array:
	var base := gear_by_uid(uid)
	var l: Array = s["gear"].filter(func(g): return int(g["uid"]) != uid and g["rarity"] == base.get("rarity", "") and str(g.get("owner", "")) == "" and not g.get("lock", false))
	l.sort_custom(func(a, b): return int(a["lv"]) < int(b["lv"]))
	return l.slice(0, 2)

## Fusion: the chosen piece rises one rarity (keeps slot, set, level and owner).
func fuse_gear(uid: int) -> String:
	var g := gear_by_uid(uid)
	if g.is_empty() or not DB.GEAR_NEXT.has(g["rarity"]):
		return "This piece can't rise any higher."
	var fodder := fuse_fodder(uid)
	if fodder.size() < 2:
		return "Need 2 more free %s pieces." % g["rarity"]
	if not spend("gold", int(DB.FUSE_GOLD[g["rarity"]])):
		return "Need %s Gold." % fmt(int(DB.FUSE_GOLD[g["rarity"]]))
	for f in fodder:
		s["gear"].erase(f)
	g["rarity"] = DB.GEAR_NEXT[g["rarity"]]
	_fill_subs(g)
	mark_dirty()
	return ""

## Temper: pays and returns {"subs": new rolls} without touching the piece, so the player can
## compare and call temper_accept() (or walk away with the old stats). Kept indexes stay as they
## are; rerolled slots keep their upgrades. On failure returns {"err": message}.
func temper_gear(uid: int, keep: Array) -> Dictionary:
	var g := gear_by_uid(uid)
	if g.is_empty():
		return {"err": "Item not found."}
	var old: Array = g["subs"]
	if keep.size() >= old.size():
		return {"err": "Leave at least one substat to reroll."}
	var cost := DB.temper_cost(g, keep.size())
	if not spend("forge_ember", cost):
		return {"err": "Need %d Forge Embers." % cost}
	var taken: Array = keep.map(func(i): return old[i]["k"])
	var out: Array = []
	for i in old.size():
		if keep.has(i):
			out.append(old[i].duplicate())
		else:
			var sb := DB.roll_gear_sub(taken)
			sb["up"] = int(old[i].get("up", 0))
			taken.append(sb["k"])
			out.append(sb)
	mark_dirty()
	return {"subs": out}

func temper_accept(uid: int, subs: Array) -> void:
	gear_by_uid(uid)["subs"] = subs
	mark_dirty()

## Best piece of a set per slot, from this hero's own or free gear: {slot: gear}.
func set_stock(id: String, set_id: String) -> Dictionary:
	var out := {}
	for g in s["gear"]:
		var ow := str(g.get("owner", ""))
		if DB.gear_set(g) == set_id and (ow == "" or ow == id):
			var cur: Dictionary = out.get(g["slot"], {})
			if cur.is_empty() or DB.gear_score(g) > DB.gear_score(cur):
				out[g["slot"]] = g
	return out

func auto_equip_set(id: String, set_id: String) -> int:
	var n := 0
	var stock := set_stock(id, set_id)
	for slot in stock.keys():
		if str(stock[slot].get("owner", "")) != id:
			equip(int(stock[slot]["uid"]), id)
			n += 1
	return n

## Equip the best free item in each slot (never steals from other heroes).
func auto_equip(id: String) -> int:
	var changed_n := 0
	for slot in DB.GEAR_SLOTS:
		var best: Dictionary = gear_on(id, slot)
		# a piece that holds a set bonus together is only replaced by the same set
		var keep_set := ""
		if not best.is_empty() and int(gear_set_counts(id).get(DB.gear_set(best), 0)) >= 2:
			keep_set = DB.gear_set(best)
		for g in s["gear"]:
			if g["slot"] == slot and g["owner"] == "" and (keep_set == "" or DB.gear_set(g) == keep_set) and (best.is_empty() or DB.gear_score(g) > DB.gear_score(best)):
				best = g
		if not best.is_empty() and best["owner"] != id:
			equip(int(best["uid"]), id)
			changed_n += 1
	return changed_n

# =================================================================== login calendar

func can_claim_login() -> bool:
	return int(s["login"]["claimed_day"]) != day_key()

func claim_login() -> Dictionary:
	if not can_claim_login():
		return {}
	s["login"]["claimed_day"] = day_key()
	var r: Dictionary = DB.LOGIN_REWARDS[clampi(int(s["login"]["streak"]) - 1, 0, 6)]
	give(r)
	save_game()
	return r

# =================================================================== event

func event_period() -> int:
	return day_key() / DB.EVENT_DAYS

func event_ends_in() -> int:
	var end_day: int = (event_period() + 1) * DB.EVENT_DAYS
	return end_day * 86400 - 7 * 3600 - now()

func event_stars(i: int) -> int:
	return int(s["event"]["cleared"].get(str(i), 0))

func apply_event_result(i: int, won: bool, stars: int) -> Dictionary:
	var st := DB.event_stage(i)
	if not won:
		s["cur"]["energy"] = int(s["cur"]["energy"]) + 4
		mark_dirty()
		return {}
	var r := {"festival_token": int(st["tokens"]) + stars * 5, "gold": 1000 + i * 800}
	if event_stars(i) == 0:
		r["gems"] = st["first_gems"]
	s["event"]["cleared"][str(i)] = maxi(stars, event_stars(i))
	quest_progress("stage")
	give(r)
	return r

func event_bought(id: String) -> int:
	return int(s["event"]["bought"].get(id, 0))

func buy_event(item: Dictionary) -> String:
	if event_bought(item["id"]) >= int(item["limit"]):
		return "Sold out for this event."
	if not spend(item["cur"], int(item["price"])):
		return "Not enough Moon Tokens."
	s["event"]["bought"][item["id"]] = event_bought(item["id"]) + 1
	give(item["give"])
	return ""

# =================================================================== guild

func in_guild() -> bool:
	return str(s["guild"]["joined"]) != ""

func join_guild(name: String, level: int = 1) -> void:
	var gd: Dictionary = s["guild"]
	gd["joined"] = name
	gd["level"] = level
	gd["exp"] = 0
	notify("Welcome to %s!" % name, Color("#9fd0ff"))
	mark_dirty()

func create_guild(name: String) -> String:
	if name.strip_edges().length() < 3:
		return "Guild name must be at least 3 characters."
	if not spend("gems", 300):
		return "Creating a guild costs 300 Gems."
	join_guild(name.strip_edges(), 1)
	return ""

func leave_guild() -> void:
	s["guild"]["joined"] = ""
	mark_dirty()

func guild_exp_needed() -> int:
	return 300 * int(s["guild"]["level"])

func guild_bonus() -> float:
	if not in_guild():
		return 0.0
	return 0.01 * float(int(s["guild"]["level"]) - 1)

func _add_guild_exp(n: int) -> void:
	var gd: Dictionary = s["guild"]
	gd["exp"] = int(gd["exp"]) + n
	while int(gd["level"]) < DB.GUILD_MAX_LV and int(gd["exp"]) >= guild_exp_needed():
		gd["exp"] = int(gd["exp"]) - guild_exp_needed()
		gd["level"] = int(gd["level"]) + 1
		notify("GUILD LEVEL UP! Lv.%d  (+%d%% ATK/HP for all heroes)" % [gd["level"], int(guild_bonus() * 100)], Color("#9fd0ff"))

func guild_checkin() -> Dictionary:
	var gd: Dictionary = s["guild"]
	if int(gd["checkin_day"]) == day_key():
		return {}
	gd["checkin_day"] = day_key()
	_add_guild_exp(40)
	quest_progress("guild")
	var r := {"guild_coin": 50, "gold": 3000}
	give(r)
	return r

func guild_donate() -> String:
	var gd: Dictionary = s["guild"]
	if int(gd["donate_day"]) != day_key():
		gd["donate_day"] = day_key()
		gd["donates"] = 0
	if int(gd["donates"]) >= 3:
		return "You can donate 3 times per day."
	if not spend("gold", 10000):
		return "Donation costs 10,000 Gold."
	gd["donates"] = int(gd["donates"]) + 1
	_add_guild_exp(60)
	quest_progress("guild")
	give({"guild_coin": 30})
	return ""

func guild_members() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(s["guild"]["joined"]))
	var out: Array = []
	var names := DB.MEMBER_NAMES.duplicate()
	for i in 11:
		var nm: String = names.pop_at(rng.randi_range(0, names.size() - 1))
		var ids: Array = DB.HEROES.keys()
		out.append({"name": nm, "level": rng.randi_range(8, 45), "hero": ids[rng.randi_range(0, ids.size() - 1)],
			"dmg": rng.randi_range(20000, 260000), "role": "Leader" if i == 0 else ("Officer" if i < 3 else "Member")})
	out.append({"name": str(s["player"]["name"]) + " (You)", "level": int(s["player"]["level"]), "hero": s["lobby_hero"], "dmg": int(s["guild"]["raid_total"]), "role": "Member"})
	out.sort_custom(func(a, b): return int(a["dmg"]) > int(b["dmg"]))
	return out

func _guildmates_raid(days: int) -> void:
	# Simulated guild members chip away at the raid boss each day.
	var gd: Dictionary = s["guild"]
	var dmg := int(DB.raid_max_hp(int(gd["raid_lv"])) * 0.18 * clampi(days, 1, 3))
	_damage_raid(dmg)

func _damage_raid(dmg: int) -> bool:
	var gd: Dictionary = s["guild"]
	gd["raid_hp"] = int(gd["raid_hp"]) - dmg
	if int(gd["raid_hp"]) <= 0:
		gd["raid_lv"] = int(gd["raid_lv"]) + 1
		gd["raid_hp"] = DB.raid_max_hp(int(gd["raid_lv"]))
		return true
	return false

func apply_raid_result(dmg: int) -> Dictionary:
	var gd: Dictionary = s["guild"]
	gd["raid_best"] = maxi(int(gd["raid_best"]), dmg)
	gd["raid_total"] = int(gd["raid_total"]) + dmg
	var lv := int(gd["raid_lv"])
	var r := {"guild_coin": clampi(20 + dmg / 1500, 20, 250), "gold": clampi(dmg / 8, 1000, 60000)}
	if _damage_raid(dmg):
		r["gems"] = 200 + lv * 50
		r["gear:%s:SSR" % DB.GEAR_SLOTS[randi() % 3]] = 1
		notify("RAID BOSS DEFEATED! Ygg-Naar Lv.%d appears." % int(gd["raid_lv"]), UI_GOLD)
	_add_guild_exp(30)
	give(r)
	return r

const UI_GOLD := Color("#ffd479")

# =================================================================== friends / support

func _avg_level() -> int:
	var total := 0
	for id in s["heroes"].keys():
		total += int(s["heroes"][id]["level"])
	return maxi(1, total / maxi(1, s["heroes"].size()))

## AI friends; each lends one support hero scaled to the player's progress.
func friends() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242 + day_key()
	var lvl := _avg_level()
	var ids: Array = DB.HEROES.keys()
	var out: Array = []
	for i in DB.FRIEND_NAMES.size():
		var hid: String = ids[rng.randi_range(0, ids.size() - 1)]
		var r := DB.rarity_of(hid)
		out.append({"idx": i, "name": DB.FRIEND_NAMES[i], "player_level": maxi(1, int(s["player"]["level"]) + rng.randi_range(-2, 6)),
			"hero": hid, "level": maxi(1, lvl + rng.randi_range(-1, 5)),
			"star": clampi(DB.RARITY_START_STAR[r] + rng.randi_range(0, 2), 1, 6),
			"used": s["friends"]["used"].has(i)})
	return out

func send_hearts() -> int:
	if bool(s["friends"]["hearts_sent"]):
		return 0
	s["friends"]["hearts_sent"] = true
	var fp := 10 * DB.FRIEND_NAMES.size()
	give({"friend_point": fp})
	return fp

func use_support(idx: int) -> void:
	if not s["friends"]["used"].has(idx):
		s["friends"]["used"].append(idx)
	give({"friend_point": 20})

# =================================================================== guide

## Recommended next step for new players (shown in the lobby).
func first_step_done(id: String) -> bool:
	match id:
		"mail": return not (s["mail_claimed"] as Array).is_empty()
		"summon": return int(s["gacha"]["total"]) > 0
		"stage1": return stages_cleared() >= 1
		"level": return s["heroes"].values().any(func(h): return int(h["level"]) >= 5)
		"bond": return s["heroes"].values().any(func(h): return int(h["bond"]) >= 2 or int(h["bond_exp"]) > 0)
		"stage3": return stages_cleared() >= 3
		"gear": return s["gear"].any(func(g): return str(g.get("owner", "")) != "")
		"chapter1": return stages_cleared() >= DB.STAGES_PER_CHAPTER
	return false

## The first step not yet claimed ({} once the path is finished).
func first_step() -> Dictionary:
	for st in DB.FIRST_STEPS:
		if not (s["first_steps"] as Array).has(st["id"]):
			return st
	return {}

## Claims the current step if it is done. Returns its rewards ({} otherwise).
func claim_first_step() -> Dictionary:
	var st := first_step()
	if st.is_empty() or not first_step_done(st["id"]):
		return {}
	s["first_steps"].append(st["id"])
	give(st["give"])
	return st["give"]

func next_goal() -> Dictionary:
	var st := first_step()
	if not st.is_empty():
		var step := "STEP %d/%d" % [(s["first_steps"] as Array).size() + 1, DB.FIRST_STEPS.size()]
		if first_step_done(st["id"]):
			return {"text": "Done! Reward: %s" % reward_text(st["give"]), "route": "", "ready": true, "tag": step}
		return {"text": st["text"], "route": st["route"], "params": st.get("params", {}), "tag": step}
	var g := _next_goal_raw()
	if str(g.get("route", "")) != "" and not feature_unlocked(str(g["route"])):
		return {"text": "Continue the story: Stage %s" % DB.stage_id(story_progress()), "route": "story"}
	return g

func _next_goal_raw() -> Dictionary:
	if mail_unclaimed() > 0:
		return {"text": "Collect your gifts in the Mailbox", "route": "mail"}
	if int(s["gacha"]["total"]) == 0:
		return {"text": "Summon new heroes at the Aether Gate", "route": "gacha"}
	if stages_cleared() == 0:
		return {"text": "Start the story: clear Stage 1-1", "route": "story"}
	if badge_quests() > 0:
		return {"text": "Claim your mission rewards", "route": "quests"}
	var nxt := story_progress()
	var st := DB.stage(nxt)
	if team_power() < enemy_power(st["enemies"]):
		for id in s["heroes"].keys():
			if level_up_block_reason(id) == "":
				return {"text": "Team too weak for %s — level up your heroes" % st["id"], "route": "heroes"}
		if s["gear"].size() > 0:
			for e in s["formation"]:
				for slot in DB.GEAR_SLOTS:
					if gear_on(e[0], slot).is_empty():
						for g in s["gear"]:
							if g["slot"] == slot and g["owner"] == "":
								return {"text": "Equip free gear on %s" % DB.name_of(e[0]), "route": "hero_detail", "params": {"id": e[0], "tab": "GEAR"}}
		if afk_pending()["secs"] > 1800:
			return {"text": "Claim AFK rewards for more Hero EXP", "route": ""}
	if not in_guild() and feature_unlocked("guild"):
		return {"text": "Join a Guild for daily rewards and a stat buff", "route": "guild"}
	if stages_cleared() < DB.stage_count():
		return {"text": "Continue the story: Stage %s" % st["id"], "route": "story"}
	return {"text": "Climb the Tower of Trials — Floor %d" % int(s["tower"]["floor"]), "route": "tower"}

# =================================================================== daily dungeons

func dungeon_tries(id: String) -> int:
	return DB.DUNGEON_TRIES - int(s["dungeon"]["tries"].get(id, 0))

## Highest difficulty index cleared (-1 = none).
func dungeon_cleared(id: String) -> int:
	return int(s["dungeon"]["cleared"].get(id, -1))

func dungeon_unlocked(id: String, diff: int) -> bool:
	return diff <= dungeon_cleared(id) + 1

func apply_dungeon_result(id: String, diff: int, won: bool) -> Dictionary:
	if not won:
		# failed attempts are refunded
		s["dungeon"]["tries"][id] = maxi(0, int(s["dungeon"]["tries"].get(id, 0)) - 1)
		mark_dirty()
		return {}
	var st := DB.dungeon_stage(id, diff)
	var r: Dictionary = st["rewards"].duplicate()
	if randf() < 0.25 + diff * 0.1:
		r["rune:%s:%d" % [DB.RUNES.keys()[randi() % 4], clampi(1 + diff / 2, 1, 3)]] = 1
	if id == "gear":
		var rar := "SSR" if randf() < 0.05 + diff * 0.06 else ("SR" if randf() < 0.35 + diff * 0.12 else "R")
		r["gear:%s:%s" % [DB.GEAR_SLOTS[randi() % 3], rar]] = 1
		r["gear:any:%s:%s" % [DB.ARMORY_GEAR[diff], DB.armory_set(day_key())]] = 1
	s["dungeon"]["cleared"][id] = maxi(dungeon_cleared(id), diff)
	quest_progress("dungeon")
	give(r)
	return r

func sweep_dungeon(id: String, diff: int) -> Dictionary:
	if diff > dungeon_cleared(id):
		return {"error": "Clear this difficulty once to unlock Sweep."}
	var e := pay_battle({"mode": "dungeon", "dungeon": id, "diff": diff})
	if e != "":
		return {"error": e}
	return apply_dungeon_result(id, diff, true)

# =================================================================== bond stories

func bond_story_unlocked(id: String, ep: int) -> bool:
	return owns(id) and int(hero(id)["bond"]) >= int(DB.BOND_STORY_REQ[ep])

func bond_story_read(id: String, ep: int) -> bool:
	return (s["bond_stories"].get(id, []) as Array).has(ep)

func bond_stories_new() -> int:
	var n := 0
	for id in s["heroes"].keys():
		for ep in DB.BOND_STORY_REQ.size():
			if bond_story_unlocked(id, ep) and not bond_story_read(id, ep):
				n += 1
	return n

## Marks an episode as read. Returns first-read rewards ({} when already read).
func read_bond_story(id: String, ep: int) -> Dictionary:
	if not bond_story_unlocked(id, ep) or bond_story_read(id, ep):
		return {}
	var l: Array = s["bond_stories"].get(id, [])
	l.append(ep)
	s["bond_stories"][id] = l
	var r: Dictionary = DB.BOND_STORY_REWARDS[ep]
	give(r)
	return r

# =================================================================== season pass

func add_pass_exp(n: int) -> void:
	var before := pass_level()
	s["pass"]["exp"] = mini(int(s["pass"]["exp"]) + n, DB.PASS_LEVELS * DB.PASS_EXP_PER_LV)
	if pass_level() > before:
		notify("SEASON PASS Lv.%d reached!" % pass_level(), Color("#c77dff"))
	_save_dirty = true

func pass_level() -> int:
	return mini(DB.PASS_LEVELS, int(s["pass"]["exp"]) / DB.PASS_EXP_PER_LV)

func pass_claimable() -> int:
	var n := 0
	for lv in range(1, pass_level() + 1):
		if not s["pass"]["free"].has(lv):
			n += 1
		if bool(s["pass"]["premium"]) and not s["pass"]["prem"].has(lv):
			n += 1
	return n

func claim_pass(lv: int, premium: bool) -> Dictionary:
	if lv > pass_level() or (premium and not bool(s["pass"]["premium"])):
		return {}
	var key := "prem" if premium else "free"
	if s["pass"][key].has(lv):
		return {}
	s["pass"][key].append(lv)
	var r := DB.pass_reward(lv, premium)
	give(r)
	return r

func claim_all_pass() -> Dictionary:
	var total := {}
	for lv in range(1, pass_level() + 1):
		for prem in [false, true]:
			var r := claim_pass(lv, prem)
			for k in r.keys():
				total[k] = int(total.get(k, 0)) + int(r[k])
	return total

func buy_premium_pass() -> String:
	if bool(s["pass"]["premium"]):
		return "Premium already unlocked."
	if not spend("gems", DB.PASS_PRICE):
		return "Need %d Gems." % DB.PASS_PRICE
	s["pass"]["premium"] = true
	mark_dirty()
	return ""

func pass_ends_in() -> int:
	var end_day: int = (int(s["pass"]["season"]) + 1) * DB.PASS_DAYS
	return end_day * 86400 - 7 * 3600 - now()

# =================================================================== collection

func collection_bonus() -> float:
	return DB.COLLECTION_PER_HERO * s["heroes"].size()

# =================================================================== formation presets

func switch_preset(i: int) -> void:
	i = clampi(i, 0, 2)
	var cur := int(s["preset_idx"])
	if i == cur:
		return
	s["presets"][cur] = s["formation"].duplicate(true)
	var nxt: Array = s["presets"][i]
	if nxt.is_empty() and s["formation"].size() > 0:
		nxt = s["formation"].duplicate(true)
	s["formation"] = nxt.duplicate(true)
	s["preset_idx"] = i
	mark_dirty()

# =================================================================== garden

## Returns {"line": subtitle, "bond": gained, "gift": reward or {}}.
func garden_tap(id: String) -> Dictionary:
	var key := "garden_" + id
	var n := int(s["quests"]["progress"].get(key, 0))
	var out := {"line": voice(id, "tap" if randf() < 0.6 else "greet"), "bond": 0, "gift": {}}
	quest_progress("bond")
	if n < DB.GARDEN_TAPS_PER_DAY:
		s["quests"]["progress"][key] = n + 1
		add_bond(id, 6)
		out["bond"] = 6
		if randf() < 0.15:
			var g := {"bouquet": 1} if randf() < 0.8 else {"celestial_gem": 1}
			give(g)
			out["gift"] = g
	mark_dirty()
	return out

func set_garden(ids: Array) -> void:
	s["garden"] = ids.slice(0, DB.GARDEN_SLOTS)
	mark_dirty()

# =================================================================== expeditions

func expedition_def(eid: String) -> Dictionary:
	for e in DB.EXPEDITIONS:
		if e["id"] == eid:
			return e
	return {}

func heroes_on_expedition() -> Array:
	var out: Array = []
	for k in s["expeditions"].keys():
		out.append_array(s["expeditions"][k]["heroes"])
	return out

func expedition_left(eid: String) -> int:
	if not s["expeditions"].has(eid):
		return -1
	var ex: Dictionary = s["expeditions"][eid]
	return maxi(0, int(ex["start"]) + int(expedition_def(eid)["hours"]) * 3600 - now())

func start_expedition(eid: String, ids: Array) -> String:
	var d := expedition_def(eid)
	if s["expeditions"].has(eid):
		return "Already in progress."
	if ids.size() != int(d["heroes"]):
		return "Select %d hero(es)." % d["heroes"]
	var busy := heroes_on_expedition()
	for id in ids:
		if busy.has(id):
			return "%s is already on an expedition." % DB.name_of(id)
		if int(hero(id)["level"]) < int(d["min_level"]):
			return "%s must be at least Lv.%d." % [DB.name_of(id), d["min_level"]]
	s["expeditions"][eid] = {"heroes": ids.duplicate(), "start": now()}
	mark_dirty()
	return ""

func finish_now_cost(eid: String) -> int:
	return maxi(10, int(ceil(expedition_left(eid) / 600.0)) * 10)

func claim_expedition(eid: String, instant: bool = false) -> Dictionary:
	if not s["expeditions"].has(eid):
		return {}
	if expedition_left(eid) > 0:
		if not instant or not spend("gems", finish_now_cost(eid)):
			return {}
	var ex: Dictionary = s["expeditions"][eid]
	var r: Dictionary = expedition_def(eid)["give"].duplicate()
	for id in ex["heroes"]:
		add_bond(id, 10)
	s["expeditions"].erase(eid)
	add_pass_exp(20)
	give(r)
	return r

func expeditions_ready() -> int:
	var n := 0
	for k in s["expeditions"].keys():
		if expedition_left(k) == 0:
			n += 1
	return n

# =================================================================== runes

func add_rune(type: String, tier: int) -> Dictionary:
	s["rune_uid"] = int(s["rune_uid"]) + 1
	var r := {"uid": int(s["rune_uid"]), "type": type, "tier": clampi(tier, 1, DB.RUNE_MAX_TIER), "owner": "", "slot": -1}
	s["runes"].append(r)
	return r

func rune_by_uid(uid: int) -> Dictionary:
	for r in s["runes"]:
		if int(r["uid"]) == uid:
			return r
	return {}

func rune_on(id: String, slot: int) -> Dictionary:
	for r in s["runes"]:
		if r["owner"] == id and int(r["slot"]) == slot:
			return r
	return {}

func equip_rune(uid: int, id: String, slot: int) -> void:
	var r := rune_by_uid(uid)
	if r.is_empty():
		return
	var cur := rune_on(id, slot)
	if not cur.is_empty():
		cur["owner"] = ""
		cur["slot"] = -1
	r["owner"] = id
	r["slot"] = slot
	mark_dirty()

func unequip_rune(uid: int) -> void:
	var r := rune_by_uid(uid)
	if not r.is_empty():
		r["owner"] = ""
		r["slot"] = -1
		mark_dirty()

func fusable(type: String, tier: int) -> Array:
	var out: Array = []
	for r in s["runes"]:
		if r["type"] == type and int(r["tier"]) == tier and r["owner"] == "":
			out.append(r)
	return out

## Combines 3 unequipped runes of the same type & tier into 1 of the next tier.
func fuse_runes(type: String, tier: int) -> Dictionary:
	if tier >= DB.RUNE_MAX_TIER:
		return {}
	var pool := fusable(type, tier)
	if pool.size() < 3:
		return {}
	var cost := 2000 * tier
	if not spend("gold", cost):
		return {}
	for i in 3:
		s["runes"].erase(pool[i])
	var r := add_rune(type, tier + 1)
	mark_dirty()
	return r

func auto_runes(id: String) -> int:
	var n := 0
	for slot in DB.RUNE_SLOTS:
		var best := rune_on(id, slot)
		for r in s["runes"]:
			if r["owner"] == "" and (best.is_empty() or DB.rune_value(r) > DB.rune_value(best)):
				best = r
		if not best.is_empty() and best["owner"] == "":
			equip_rune(int(best["uid"]), id, slot)
			n += 1
	return n

# =================================================================== costume unlock

func buy_costume(id: String, idx: int) -> String:
	if skin_unlocked(id, idx):
		return "Already unlocked."
	if not owns(id):
		return "Recruit this hero first."
	if idx == DB.special_index(id):
		if not spend("skin_ticket", 1) and not spend("gems", DB.SPECIAL_PRICE):
			return "Need a Special Skin Ticket or %d Gems." % DB.SPECIAL_PRICE
	else:
		var price := DB.costume_price(idx)
		if not spend("gems", price):
			return "Need %d Gems." % price
	var l: Array = s["skins_bought"].get(id, [])
	l.append(idx)
	s["skins_bought"][id] = l
	mark_dirty()
	return ""

# =================================================================== mini-game

## Everything still worth doing today: [route, icon, title, status text, remaining(int, 0 = done)].
func daily_board() -> Array:
	var rows: Array = []
	var dq_done := 0
	for q in DB.DAILY_QUESTS:
		if quest_state(q) == "claimed":
			dq_done += 1
	rows.append(["quests", "icon_quest", "Daily Missions", "%d / %d claimed" % [dq_done, DB.DAILY_QUESTS.size()], DB.DAILY_QUESTS.size() - dq_done])
	if can_claim_login():
		rows.append(["login", "icon_ticket", "Login Bonus", "Ready to claim", 1])
	var afk := afk_pending()
	rows.append(["afk", "icon_afk", "AFK Rewards", "%s Gold waiting" % fmt(int(afk.get("gold", 0))), 1 if int(afk.get("gold", 0)) > 0 else 0])
	rows.append(["gacha", "icon_gacha", "Free Summon", "Available" if can_free_pull() else "Used", 1 if can_free_pull() else 0])
	if mail_unclaimed() > 0:
		rows.append(["mail", "icon_mail", "Mailbox", "%d unclaimed" % mail_unclaimed(), mail_unclaimed()])
	rows.append(["heroes", "icon_heart", "Daily Talks", "%d / %d left" % [talks_left(), TALKS_PER_DAY], talks_left()])
	if feature_unlocked("dungeon"):
		var dl := 0
		for d in DB.DUNGEONS:
			dl += dungeon_tries(d["id"])
		rows.append(["dungeon", "icon_dungeon", "Daily Dungeons", "%d attempts left" % dl, dl])
	if feature_unlocked("arena"):
		rows.append(["arena", "icon_arena", "Arena", "%d tickets left" % int(s["arena"]["tickets"]), int(s["arena"]["tickets"])])
	if feature_unlocked("worldboss"):
		rows.append(["worldboss", "icon_boss", "World Boss", "%d / %d attacks left" % [int(s["wboss"]["tries"]), DB.WB_TRIES], int(s["wboss"]["tries"])])
	if feature_unlocked("hunt"):
		rows.append(["hunt", "icon_combat_target", "Boss Hunt", "%d / %d hunts left" % [hunt_tries(), DB.HUNT_TRIES], hunt_tries()])
	if feature_unlocked("expedition") and expeditions_ready() > 0:
		rows.append(["expedition", "icon_afk", "Expeditions", "%d completed" % expeditions_ready(), expeditions_ready()])
	if feature_unlocked("festival") and not festival().is_empty():
		rows.append(["festival", "icon_festival", "Festival Wish", "Available" if fest_can_wish() else "Made today", 1 if fest_can_wish() else 0])
	if feature_unlocked("guild") and in_guild():
		var ci := int(s["guild"]["checkin_day"]) == day_key()
		rows.append(["guild", "icon_guild", "Guild Check-in & Raid", "%d raid attempts" % int(s["guild"]["raid_tries"]) if ci else "Not checked in", int(s["guild"]["raid_tries"]) + (0 if ci else 1)])
	if feature_unlocked("minigame"):
		rows.append(["minigame", "icon_heart", "Heart Catch", "%d reward plays left" % minigame_plays_left(), minigame_plays_left()])
	rows.sort_custom(func(a, b): return int(a[4] > 0) > int(b[4] > 0))
	return rows

func minigame_plays_left() -> int:
	return DB.MINIGAME_REWARD_PLAYS - int(s["minigame"]["plays"])

func finish_minigame(id: String, score: int) -> Dictionary:
	s["minigame"]["best"] = maxi(int(s["minigame"]["best"]), score)
	if minigame_plays_left() <= 0 or score <= 0:
		mark_dirty()
		return {}
	s["minigame"]["plays"] = int(s["minigame"]["plays"]) + 1
	add_bond(id, mini(60, score))
	var r := {"gold": score * 150}
	if score >= 40:
		r["bouquet"] = 1
	if score >= 70:
		r["gems"] = 30
	give(r)
	return r

# =================================================================== arena season

func arena_season() -> int:
	return day_key() / DB.ARENA_SEASON_DAYS

func arena_season_ends_in() -> int:
	return (arena_season() + 1) * DB.ARENA_SEASON_DAYS * 86400 - 7 * 3600 - now()

func _check_arena_season() -> void:
	var a: Dictionary = s["arena"]
	var cur := arena_season()
	if int(a.get("season", -1)) == -1:
		a["season"] = cur
		return
	if int(a["season"]) != cur:
		var tier := DB.arena_tier(int(a["rp"]))
		a["pending"] = tier["give"]
		a["last_tier"] = tier["name"]
		a["rp"] = 1000 + (int(a["rp"]) - 1000) / 2
		a["season"] = cur

func claim_arena_season() -> Dictionary:
	var r: Dictionary = s["arena"].get("pending", {})
	if r.is_empty():
		return {}
	s["arena"]["pending"] = {}
	give(r)
	return r

func arena_leaderboard() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = arena_season() * 7919
	var out: Array = []
	var ids: Array = DB.HEROES.keys()
	for i in 29:
		var rp := int(1700 - i * 28 + rng.randi_range(-15, 15))
		out.append({"name": ARENA_NAMES[i % ARENA_NAMES.size()] + ("" if i < ARENA_NAMES.size() else str(i)), "rp": rp, "hero": ids[rng.randi_range(0, ids.size() - 1)], "me": false})
	out.append({"name": str(s["player"]["name"]), "rp": int(s["arena"]["rp"]), "hero": s["lobby_hero"], "me": true})
	out.sort_custom(func(a, b): return int(a["rp"]) > int(b["rp"]))
	return out

# =================================================================== awakening

func awaken_cost(id: String) -> Dictionary:
	var a := int(hero(id).get("awaken", 0))
	return {"shards": DB.AWAKEN_SHARDS[clampi(a, 0, 4)], "gold": 50000 * (a + 1)}

func awaken_block(id: String) -> String:
	var h := hero(id)
	if int(h["star"]) < DB.MAX_STAR:
		return "Awakening unlocks at %d★." % DB.MAX_STAR
	if int(h["awaken"]) >= DB.MAX_AWAKEN:
		return "Fully awakened!"
	var c := awaken_cost(id)
	if int(s["shards"].get(id, 0)) + amount("star_stone") < int(c["shards"]):
		return "Need %d shards." % c["shards"]
	if amount("gold") < int(c["gold"]):
		return "Not enough Gold."
	return ""

func awaken(id: String) -> String:
	var err := awaken_block(id)
	if err != "":
		return err
	var c := awaken_cost(id)
	var own := int(s["shards"].get(id, 0))
	var from_own := mini(own, int(c["shards"]))
	s["shards"][id] = own - from_own
	s["items"]["star_stone"] = amount("star_stone") - (int(c["shards"]) - from_own)
	spend("gold", int(c["gold"]))
	hero(id)["awaken"] = int(hero(id)["awaken"]) + 1
	mark_dirty()
	return ""

# =================================================================== black market

func _roll_market() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = day_key() * 131 + int(s["market"]["refresh"]) * 7 + hash(str(s["player"]["name"]))
	var offers: Array = []
	# one hero-shard offer, favouring heroes you own
	var ids: Array = DB.HEROES.keys()
	var hid: String = ids[rng.randi_range(0, ids.size() - 1)]
	offers.append({"give": {"shard:" + hid: 10}, "price": DB.MARKET_SHARD_PRICE[DB.rarity_of(hid)], "cur": "gems", "sold": false, "off": 0})
	var total := 0
	for o in DB.MARKET_POOL:
		total += int(o["w"])
	while offers.size() < DB.MARKET_SIZE:
		var r := rng.randi_range(1, total)
		for o in DB.MARKET_POOL:
			r -= int(o["w"])
			if r <= 0:
				var off: int = [0, 0, 10, 20, 30, 50][rng.randi_range(0, 5)]
				offers.append({"give": o["give"].duplicate(), "price": int(int(o["price"]) * (100 - off) / 100.0), "cur": o["cur"], "sold": false, "off": off})
				break
	s["market"]["offers"] = offers

func market_offers() -> Array:
	if (s["market"]["offers"] as Array).is_empty():
		_roll_market()
	return s["market"]["offers"]

func market_buy(i: int) -> String:
	var o: Dictionary = market_offers()[i]
	if bool(o["sold"]):
		return "Sold out."
	if not spend(o["cur"], int(o["price"])):
		return "Not enough %s." % reward_name(o["cur"])
	o["sold"] = true
	give(o["give"])
	return ""

func market_refresh() -> String:
	if int(s["market"]["refresh"]) >= DB.MARKET_REFRESHES:
		return "No refreshes left today."
	if not spend("gems", DB.MARKET_REFRESH_COST):
		return "Need %d Gems." % DB.MARKET_REFRESH_COST
	s["market"]["refresh"] = int(s["market"]["refresh"]) + 1
	_roll_market()
	mark_dirty()
	return ""

# =================================================================== feature gating

func feature_req(route: String) -> int:
	return int(DB.FEATURE_UNLOCK.get(route, 1))

func feature_unlocked(route: String) -> bool:
	return int(s["player"]["level"]) >= feature_req(route)

## Number of claimable things behind a feature (for badges). 0 when locked.
func feature_badge(route: String) -> int:
	if not feature_unlocked(route):
		return 0
	var n := 0
	match route:
		"mail": n = mail_unclaimed()
		"quests": n = badge_quests() + road_ready()
		"login": n = 1 if can_claim_login() else 0
		"friends": n = 0 if bool(s["friends"]["hearts_sent"]) else 1
		"heroes": n = bond_stories_new() + codex_claimable() if stages_cleared() > 0 else 0   # quiet until the first win
		"pass": n = pass_claimable()
		"expedition": n = expeditions_ready()
		"hunt": n = hunt_tries() + hunt_shop_ready()
		"bestiary": n = bestiary_ready()
		"wardrobe": n = amount("skin_ticket")
		"rift":
			for i in DB.RIFT_MILESTONES.size():
				if rift_milestone_state(i) == "ready":
					n += 1
			if not (_rift()["offer"] as Array).is_empty():
				n += 1
		"room": n = room_visits_left() if feature_unlocked("room") else 0
		"messenger": n = msg_unread()
		"date": n = dates_left() if s["heroes"].values().any(func(h): return int(h["bond"]) >= DB.DATE_BOND) else 0
		"news": n = news_unread()
		"festival": n = (1 if fest_can_wish() else 0) + (0 if festival().is_empty() or bool(_fest_state()["greeted"]) else 1)
		"worldboss": n = wboss_badge() + (1 if int(s["wboss"]["tries"]) == DB.WB_TRIES else 0)
		"dungeon":
			for d in DB.DUNGEONS:
				n += dungeon_tries(d["id"])
		"guild": n = 1 if in_guild() and int(s["guild"]["checkin_day"]) != day_key() else 0
		"garden": n = minigame_plays_left() if feature_unlocked("minigame") else 0
	if (s.get("new_unlocks", []) as Array).has(route):
		n = maxi(n, 1)
	return n

func seen_unlock(route: String) -> void:
	var nu: Array = s.get("new_unlocks", [])
	if nu.has(route):
		nu.erase(route)
		mark_dirty()

# =================================================================== save backup (export / import code)

const EXPORT_PREFIX := "EO2"

## Compact text code containing the whole save (gzip + base64).
func export_code() -> String:
	var raw := JSON.stringify(s).to_utf8_buffer()
	var packed := raw.compress(FileAccess.COMPRESSION_GZIP)
	return "%s:%d:%s" % [EXPORT_PREFIX, raw.size(), Marshalls.raw_to_base64(packed)]

## Restores a save from an export code. Returns "" on success or an error.
func import_code(code: String) -> String:
	var parts := code.strip_edges().split(":")
	if parts.size() != 3 or parts[0] != EXPORT_PREFIX or not parts[1].is_valid_int():
		return "Invalid save code."
	var packed := Marshalls.base64_to_raw(parts[2])
	if packed.is_empty():
		return "Invalid save code."
	var raw := packed.decompress(int(parts[1]), FileAccess.COMPRESSION_GZIP)
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if not (parsed is Dictionary) or int(parsed.get("version", 0)) != SAVE_VERSION or not parsed.has("heroes"):
		return "This code is damaged or from another version."
	var fresh := new_state()
	_merge(fresh, parsed)
	s = fresh
	_sanitize()
	_check_day()
	save_game()
	changed.emit()
	return ""

# =================================================================== hard mode

func hard_stars(index: int) -> int:
	return int(s["story"].get("hard", {}).get(DB.stage_id(index), 0))

func hard_progress() -> int:
	var i := 0
	while i < DB.stage_count() and hard_stars(i) > 0:
		i += 1
	return mini(i, DB.stage_count() - 1)

## Hard chapter N opens once the Normal chapter N boss is cleared.
func hard_chapter_open(ch: int) -> bool:
	return stage_stars(ch * DB.STAGES_PER_CHAPTER + DB.STAGES_PER_CHAPTER - 1) > 0

func hard_unlocked(index: int) -> bool:
	return index <= hard_progress() and hard_chapter_open(index / DB.STAGES_PER_CHAPTER)

func apply_hard_result(index: int, won: bool, stars: int) -> Dictionary:
	var st := DB.hard_stage(index)
	if not won:
		s["cur"]["energy"] = int(s["cur"]["energy"]) + int(st["energy"]) / 2
		mark_dirty()
		return {}
	var r := {"gold": st["gold"], "hero_exp": st["hero_exp"], "player_exp": st["player_exp"], "shard:" + str(st["shard_id"]): st["shards"]}
	if hard_stars(index) == 0:
		r["gems"] = st["first_gems"]
	if not s["story"].has("hard"):
		s["story"]["hard"] = {}
	s["story"]["hard"][DB.stage_id(index)] = maxi(stars, hard_stars(index))
	quest_progress("stage")
	give(r)
	return r

func _sweep_hard(index: int, times: int) -> Dictionary:
	var st := DB.hard_stage(index)
	if hard_stars(index) < 3:
		return {"error": "Clear this Hard stage with 3★ to unlock Sweep."}
	var cost := int(st["energy"]) * times
	if amount("energy") < cost:
		return {"error": "Not enough Energy."}
	spend("energy", cost)
	var total := {"gold": int(st["gold"]) * times, "hero_exp": int(st["hero_exp"]) * times, "player_exp": int(st["player_exp"]) * times, "shard:" + str(st["shard_id"]): int(st["shards"]) * times}
	for i in times:
		quest_progress("stage")
	give(total)
	return total

# =================================================================== daily talk

const TALKS_PER_DAY := 3

func talks_left() -> int:
	return TALKS_PER_DAY - int(s["quests"]["progress"].get("talks", 0))

## Returns VN lines for a talk with `id` ({} when no talks left).
func start_talk(id: String) -> Array:
	if talks_left() <= 0 or not owns(id):
		return []
	s["quests"]["progress"]["talks"] = int(s["quests"]["progress"].get("talks", 0)) + 1
	quest_progress("bond")
	mark_dirty()
	var topic: Array = DB.TALK_TOPICS[randi() % DB.TALK_TOPICS.size()]
	return [[id, topic[0]], DB.choice_line(id, topic[1], 0.6)]

# =================================================================== weekly missions

func weekly_state(q: Dictionary) -> String:
	if s["weekly"]["claimed"].get(q["id"], false):
		return "claimed"
	if int(s["weekly"]["progress"].get(q["id"], 0)) >= int(q["target"]):
		return "ready"
	return "progress"

func claim_weekly(q: Dictionary) -> bool:
	if weekly_state(q) != "ready":
		return false
	s["weekly"]["claimed"][q["id"]] = true
	give(q["give"])
	return true

func weekly_ends_in() -> int:
	return (int(s["weekly"]["week"]) + 1) * 7 * 86400 - 7 * 3600 - now()

# =================================================================== codex rewards

func codex_reached(id: String, step: String) -> bool:
	var h := hero(id)
	if h.is_empty():
		return false
	match step:
		"own": return true
		"star5": return int(h["star"]) >= 5
		"bond10": return int(h["bond"]) >= DB.MAX_BOND
		"awaken5": return int(h.get("awaken", 0)) >= DB.MAX_AWAKEN
	return false

func codex_claimed(id: String, step: String) -> bool:
	return bool(s["codex"].get("%s:%s" % [id, step], false))

func codex_claimable() -> int:
	var n := 0
	for id in s["heroes"].keys():
		for st in DB.CODEX_STEPS:
			if codex_reached(id, st["id"]) and not codex_claimed(id, st["id"]):
				n += 1
	return n

func claim_codex_all() -> Dictionary:
	var total := {}
	for id in s["heroes"].keys():
		for st in DB.CODEX_STEPS:
			if codex_reached(id, st["id"]) and not codex_claimed(id, st["id"]):
				s["codex"]["%s:%s" % [id, st["id"]]] = true
				for k in st["give"].keys():
					total[k] = int(total.get(k, 0)) + int(st["give"][k])
	if not total.is_empty():
		give(total)
	return total

# =================================================================== welcome back / birthdays / scenes

## Seconds since the player last saved (captured once at boot, before the first save).
var away_secs := 0

func capture_away() -> void:
	away_secs = maxi(0, now() - int(s.get("last_seen", now())))

func birthday_heroes() -> Array:
	var d := Time.get_date_dict_from_system()
	var key := "%02d-%02d" % [d["month"], d["day"]]
	var out: Array = []
	for id in s["heroes"].keys():
		if str(DB.profile(id).get("birthday", "")) == key:
			out.append(id)
	return out

## Gives each birthday hero's present once per year. Returns ids celebrated now.
func claim_birthdays() -> Array:
	var year: int = int(Time.get_date_dict_from_system()["year"])
	var done: Dictionary = s.get("bday", {})
	var out: Array = []
	for id in birthday_heroes():
		if int(done.get(id, 0)) != year:
			done[id] = year
			add_bond(id, 120)
			give({"celestial_gem": 1, "gems": 100})
			out.append(id)
	s["bday"] = done
	return out

func scene_unlocked(sc: Dictionary) -> bool:
	return stages_cleared() >= int(sc["req"])

# =================================================================== world boss

func wboss() -> Dictionary:
	return DB.world_boss(day_key() / 7)

## AI leaderboard for this week's World Boss (deterministic per week), player included.
func wboss_board() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("wb%d" % (day_key() / 7))
	var names := ["Kurogane", "Mireille", "Takumi_77", "Aster", "Nyx", "Ryoko", "BladeOfDawn", "Sora", "Hikari", "Vermilion", "LunaFox", "Gale", "Ophelia", "Kaito", "Seraph"]
	# One full day of attacks ≈ 3 attacks × 3× team power (measured). Rivals range from casual to whale.
	var days := float(posmod(day_key(), 7) + 1)
	var base := 9.0 * float(maxi(team_power(), 6000)) * days
	var out: Array = []
	for i in 14:
		var dmg := int(base * (rng.randf_range(1.6, 2.6) if i < 2 else rng.randf_range(0.25, 1.5)))
		out.append({"name": names[i] + " [AI]", "dmg": dmg, "hero": DB.HEROES.keys()[rng.randi() % DB.HEROES.size()], "me": false})
	out.append({"name": str(s["player"]["name"]) + " (You)", "dmg": int(s["wboss"]["total"]), "hero": s["lobby_hero"], "me": true})
	out.sort_custom(func(a, b): return int(a["dmg"]) > int(b["dmg"]))
	return out

func wboss_rank() -> int:
	var b := wboss_board()
	for i in b.size():
		if b[i]["me"]:
			return i + 1
	return b.size()

func wboss_milestone_state(i: int) -> String:
	if s["wboss"]["claimed"].has(i):
		return "claimed"
	return "ready" if int(s["wboss"]["total"]) >= int(DB.WB_MILESTONES[i]["dmg"]) else "locked"

func claim_wboss_milestone(i: int) -> Dictionary:
	if wboss_milestone_state(i) != "ready":
		return {}
	s["wboss"]["claimed"].append(i)
	var r: Dictionary = DB.WB_MILESTONES[i]["give"]
	give(r)
	return r

func wboss_badge() -> int:
	var n := 0
	for i in DB.WB_MILESTONES.size():
		if wboss_milestone_state(i) == "ready":
			n += 1
	if not bool(s["wboss"].get("rank_claimed", true)):
		n += 1
	return n

## Last week's ranking reward (once).
func claim_wboss_rank() -> Dictionary:
	var wb: Dictionary = s["wboss"]
	if bool(wb.get("rank_claimed", true)):
		return {}
	wb["rank_claimed"] = true
	var r := DB.wb_rank_reward(int(wb["last_rank"]))
	give(r)
	return r

func apply_wboss_result(dmg: int) -> Dictionary:
	var wb: Dictionary = s["wboss"]
	wb["best"] = maxi(int(wb["best"]), dmg)
	wb["total"] = int(wb["total"]) + dmg
	if int(wb["total"]) >= 1000000:
		s["player"]["slayer"] = true
	var r := {"gold": clampi(dmg / 10, 2000, 50000), "exp_potion": 1}
	give(r)
	mark_dirty()
	return r

# =================================================================== seasonal festival

func festival() -> Dictionary:
	var d := Time.get_date_dict_from_system()
	var f: Dictionary = DB.FESTIVALS.get(int(d["month"]), {}).duplicate()
	if f.is_empty():
		return f
	f["id"] = "%d-%02d" % [d["year"], d["month"]]
	return f

## Seconds until the current festival (calendar month) ends.
func festival_ends_in() -> int:
	var d := Time.get_datetime_dict_from_system()
	var y: int = d["year"]
	var m: int = d["month"] + 1
	if m > 12:
		m = 1
		y += 1
	var end := Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": 1, "hour": 0, "minute": 0, "second": 0})
	return maxi(0, int(end - Time.get_unix_time_from_datetime_dict(d)))

func _fest_state() -> Dictionary:
	var f := festival()
	var st: Dictionary = s["fest"]
	if str(st["id"]) != str(f.get("id", "")):
		s["fest"] = {"id": f.get("id", ""), "day": -1, "today": 0, "bought": {}, "greeted": false, "wish_day": -1, "total": 0}
		st = s["fest"]
	if int(st["day"]) != day_key():
		st["day"] = day_key()
		st["today"] = 0
	return st

## Lantern Charms for a won battle: 10 base, +5 per featured hero deployed. Daily cap.
func festival_drop(mode: String) -> int:
	var f := festival()
	if f.is_empty() or not (mode in ["story", "hard", "event", "dungeon", "tower", "hunt"]):
		return 0
	var st := _fest_state()
	var n := 10
	for e in s["formation"]:
		if f["featured"].has(e[0]):
			n += 5
	n = mini(n, DB.FEST_DAILY_CAP - int(st["today"]))
	if n <= 0:
		return 0
	st["today"] = int(st["today"]) + n
	st["total"] = int(st["total"]) + n
	give({"season_token": n})
	return n

func fest_item_give(it: Dictionary) -> Dictionary:
	var f := festival()
	var out: Dictionary = {}
	for k in it["give"].keys():
		var key: String = k
		if key.begins_with("shard:@"):
			key = "shard:" + str(f["featured"][int(key.substr(7))])
		out[key] = it["give"][k]
	return out

func fest_bought(id: String) -> int:
	return int(_fest_state()["bought"].get(id, 0))

func buy_fest(it: Dictionary) -> String:
	if fest_bought(it["id"]) >= int(it["limit"]):
		return "Sold out for this festival."
	if not spend("season_token", int(it["price"])):
		return "Not enough Lantern Charms."
	var st := _fest_state()
	st["bought"][it["id"]] = fest_bought(it["id"]) + 1
	give(fest_item_give(it))
	return ""

func fest_can_wish() -> bool:
	return not festival().is_empty() and int(_fest_state()["wish_day"]) != day_key()

## Free daily festival wish: random charms + a small gift.
func fest_wish() -> Dictionary:
	if not fest_can_wish():
		return {}
	_fest_state()["wish_day"] = day_key()
	var r := {"season_token": randi_range(20, 60)}
	var extra: Array = [{"gold": 15000}, {"exp_potion": 2}, {"energy_potion": 1}, {"bouquet": 1}, {"gems": 30}]
	r.merge(extra[randi() % extra.size()])
	give(r)
	return r

## One-time festival greeting: +60 Bond to each featured hero you own.
func fest_greet() -> bool:
	var st := _fest_state()
	if bool(st["greeted"]):
		return false
	st["greeted"] = true
	for id in festival()["featured"]:
		add_bond(id, 60)
	mark_dirty()
	return true

# =================================================================== commander tactics

func tactic_unlocked(id: String) -> bool:
	return int(s["player"]["level"]) >= int(DB.tactic_def(id).get("req", 999))

func tactic_lv(id: String) -> int:
	return int(s["tactics"]["lv"].get(id, 1))

## Max level allowed by Player level (1 + 1 per 8 levels, max 5).
func tactic_lv_cap() -> int:
	return clampi(1 + int(s["player"]["level"]) / 8, 1, DB.TACTIC_MAX_LV)

func equip_tactic(id: String) -> bool:
	if id != "" and not tactic_unlocked(id):
		return false
	s["tactics"]["eq"] = id
	mark_dirty()
	return true

func equipped_tactic() -> Dictionary:
	var id := str(s["tactics"].get("eq", ""))
	if id == "" or not tactic_unlocked(id):
		return {}
	return {"id": id, "lv": tactic_lv(id)}

func upgrade_tactic(id: String) -> String:
	if not tactic_unlocked(id):
		return "Locked."
	var lv := tactic_lv(id)
	if lv >= DB.TACTIC_MAX_LV:
		return "Already at max level."
	if lv >= tactic_lv_cap():
		return "Raise your Player level to upgrade further (Lv.%d needed)." % (lv * 8)
	if not spend("gold", DB.tactic_cost(lv)):
		return "Not enough Gold."
	s["tactics"]["lv"][id] = lv + 1
	mark_dirty()
	return ""

# =================================================================== spark / profile / titles

func spark_points(banner_id: String) -> int:
	return int(s["gacha"].get("spark", {}).get(banner_id, 0))

## Exchange SPARK_COST points for the banner's featured hero. Returns add_hero() result or {error}.
func spark_exchange(banner_id: String) -> Dictionary:
	var b: Dictionary = {}
	for x in DB.BANNERS:
		if x["id"] == banner_id:
			b = x
	if str(b.get("featured", "")) == "":
		return {"error": "This banner has no featured hero."}
	if spark_points(banner_id) < DB.SPARK_COST:
		return {"error": "Need %d Summon Points." % DB.SPARK_COST}
	s["gacha"]["spark"][banner_id] = spark_points(banner_id) - DB.SPARK_COST
	var res := add_hero(b["featured"])
	res["id"] = b["featured"]
	mark_dirty()
	save_game()
	return res

func title_unlocked(id: String) -> bool:
	match id:
		"rookie": return true
		"summoner": return int(s["gacha"]["total"]) >= 100
		"collector": return s["heroes"].size() >= 15
		"beloved": return s["heroes"].values().any(func(h): return int(h["bond"]) >= DB.MAX_BOND)
		"oathbound": return s["heroes"].values().any(func(h): return bool(h["oath"]))
		"eclipse": return stages_cleared() >= 36
		"second": return stages_cleared() >= 60
		"time": return stages_cleared() >= 84
		"light": return stages_cleared() >= 108
		"starbound": return stages_cleared() >= 132
		"second_oath": return stages_cleared() >= 156
		"abaddon": return stages_cleared() >= 180
		"mirror_master": return trials_done() >= 30
		"homebody": return DB.ROOMS.all(func(r): return room_unlocked(r))
		"limitless": return s["heroes"].values().any(func(x): return int(x.get("lb", 0)) >= DB.MAX_LB)
		"hunter": return bool(s["hunt"].get("abyss", false))
		"tower": return int(s["tower"]["floor"]) > 30
		"arena": return int(s["arena"]["rp"]) >= 1500
		"slayer": return int(s["wboss"]["total"]) >= 1000000 or bool(s["player"].get("slayer", false))
		"tactician": return s["tactics"]["lv"].values().any(func(l): return int(l) >= DB.TACTIC_MAX_LV)
	return false

func title_name() -> String:
	var id := str(s["player"].get("title", "rookie"))
	for t in DB.TITLES:
		if t["id"] == id and title_unlocked(id):
			return t["name"]
	return DB.TITLES[0]["name"]

func set_title(id: String) -> bool:
	if not title_unlocked(id):
		return false
	s["player"]["title"] = id
	mark_dirty()
	return true

func avatar_id() -> String:
	var a := str(s["player"].get("avatar", ""))
	return a if owns(a) else str(s["lobby_hero"])

func set_avatar(id: String) -> void:
	if owns(id):
		s["player"]["avatar"] = id
		mark_dirty()

func rename(n: String) -> String:
	n = n.strip_edges()
	if n.length() < 2 or n.length() > 14:
		return "Name must be 2-14 characters."
	s["player"]["name"] = n
	mark_dirty()
	return ""

# =================================================================== interludes

const INTERLUDE_REWARD := {"gems": 200, "summon_ticket": 1}

func interlude_open(it: Dictionary) -> bool:
	return stages_cleared() >= int(it["req"])

func interlude_read(id: String) -> bool:
	return (s["story"].get("interludes", []) as Array).has(id)

func interlude_new_count() -> int:
	var n := 0
	for it in DB.INTERLUDES:
		if interlude_open(it) and not interlude_read(it["id"]):
			n += 1
	return n

## First read: reward + Bond for the cast. Returns the reward ({} if already read).
func finish_interlude(it: Dictionary) -> Dictionary:
	if interlude_read(it["id"]) or not interlude_open(it):
		return {}
	var done: Array = s["story"].get("interludes", [])
	done.append(it["id"])
	s["story"]["interludes"] = done
	for hid in it["cast"]:
		add_bond(hid, 40)
	give(INTERLUDE_REWARD)
	return INTERLUDE_REWARD

# =================================================================== story links

## Links whose members are all in the current formation.
func active_links() -> Array:
	var ids: Array = s["formation"].map(func(e): return e[0])
	return DB.LINKS.filter(func(l): return (l["heroes"] as Array).all(func(h): return ids.has(h)))

# =================================================================== boss hunt

func _hunt_state() -> Dictionary:
	var h: Dictionary = s["hunt"]
	if int(h["day"]) != day_key():
		h["day"] = day_key()
		h["used"] = 0
	if int(h["week"]) != day_key() / 7:
		h["week"] = day_key() / 7
		h["bought"] = {}
	return h

func hunt_tries() -> int:
	return DB.HUNT_TRIES - int(_hunt_state()["used"])

func hunt_cleared(id: String) -> int:
	return int(s["hunt"]["cleared"].get(id, -1))

func hunt_unlocked(id: String, diff: int) -> bool:
	return diff <= hunt_cleared(id) + 1

func apply_hunt_result(id: String, diff: int, won: bool) -> Dictionary:
	var h := _hunt_state()
	if not won:
		h["used"] = maxi(0, int(h["used"]) - 1)    # failed hunts are refunded
		mark_dirty()
		return {}
	var st := DB.hunt_stage(id, diff)
	var r: Dictionary = st["rewards"].duplicate()
	if diff > hunt_cleared(id):
		r["gems"] = int(st["first_gems"])
	match str(DB.hunt_def(id)["focus"]):
		"stone":
			r["star_stone"] = 3 + diff * 4
		"core":
			r["hunt_core"] = int(int(r["hunt_core"]) * 1.6)
		"gear":
			var rar := "SSR" if randf() < 0.15 + diff * 0.2 else "SR"
			r["gear:%s:%s" % [DB.GEAR_SLOTS[randi() % 3], rar]] = 1
		"rune":
			r["rune:%s:%d" % [DB.RUNES.keys()[randi() % DB.RUNES.size()], clampi(2 + diff / 2, 1, 3)]] = 1 + (1 if diff >= 2 else 0)
		"shard":
			var ids: Array = s["heroes"].keys()
			var hid: String = ids[randi() % ids.size()]
			r["shard:" + hid] = 4 + diff * 3
	h["cleared"][id] = maxi(hunt_cleared(id), diff)
	if diff >= DB.HUNT_DIFFS.size() - 1:
		h["abyss"] = true
	give(r)
	quest_progress("dungeon")
	mark_dirty()
	return r

func hunt_bought(id: String) -> int:
	return int(_hunt_state()["bought"].get(id, 0))

func hunt_shop_ready() -> int:
	var n := 0
	for it in DB.HUNT_SHOP:
		if hunt_bought(it["id"]) < int(it["limit"]) and amount("hunt_core") >= int(it["price"]) and str(it["id"]).begins_with("hs_ssr"):
			n = 1
	return n

func buy_hunt(it: Dictionary) -> String:
	if hunt_bought(it["id"]) >= int(it["limit"]):
		return "Sold out this week."
	if not spend("hunt_core", int(it["price"])):
		return "Not enough Hunt Cores."
	_hunt_state()["bought"][it["id"]] = hunt_bought(it["id"]) + 1
	give(it["give"])
	return ""

## Instant re-run of an already-cleared hunt difficulty (uses one attempt).
func sweep_hunt(id: String, diff: int) -> Dictionary:
	if diff > hunt_cleared(id):
		return {"error": "Clear this difficulty once to unlock Sweep."}
	var e := pay_battle({"mode": "hunt", "hunt": id, "diff": diff})
	if e != "":
		return {"error": e}
	var r := apply_hunt_result(id, diff, true)
	var ft := festival_drop("hunt")
	if ft > 0:
		r["season_token"] = ft
	return r

# =================================================================== limit break

func hero_cap(id: String) -> int:
	var h := hero(id)
	return DB.level_cap(int(h["star"]), int(h.get("lb", 0)))

func limit_break_block(id: String) -> String:
	var h := hero(id)
	var lb := int(h.get("lb", 0))
	if int(h["star"]) < DB.MAX_STAR:
		return "Requires %d★" % DB.MAX_STAR
	if lb >= DB.MAX_LB:
		return "MAX LIMIT BREAK"
	if int(h["level"]) < hero_cap(id):
		return "Reach Lv.%d first" % hero_cap(id)
	var c := DB.lb_cost(lb)
	if amount("hunt_core") < int(c["hunt_core"]):
		return "Need %d Hunt Cores" % c["hunt_core"]
	if int(s["shards"].get(id, 0)) + amount("star_stone") < int(c["shards"]):
		return "Need %d shards" % c["shards"]
	if amount("gold") < int(c["gold"]):
		return "Not enough Gold"
	return ""

func limit_break(id: String) -> String:
	var err := limit_break_block(id)
	if err != "":
		return err
	var h := hero(id)
	var c := DB.lb_cost(int(h.get("lb", 0)))
	spend("hunt_core", int(c["hunt_core"]))
	spend("gold", int(c["gold"]))
	var need := int(c["shards"])
	var own := int(s["shards"].get(id, 0))
	var use_own := mini(own, need)
	s["shards"][id] = own - use_own
	if need > use_own:
		spend("star_stone", need - use_own)
	h["lb"] = int(h.get("lb", 0)) + 1
	mark_dirty()
	save_game()
	return ""

# =================================================================== starlight rift

func _rift() -> Dictionary:
	var r: Dictionary = s["rift"]
	if int(r["week"]) != day_key() / 7:
		s["rift"] = {"week": day_key() / 7, "floor": 1, "best": 0, "bless": [], "offer": [], "alive": false, "claimed": [], "runs": 0}
		r = s["rift"]
	return r

func rift_blessings() -> Array:
	var out: Array = []
	for b in _rift()["bless"]:
		if DB.BLESSINGS.has(b):
			out.append(DB.BLESSINGS[b])
	return out

func rift_start() -> void:
	var r := _rift()
	r["floor"] = 1
	r["bless"] = []
	r["offer"] = []
	r["alive"] = true
	r["runs"] = int(r["runs"]) + 1
	mark_dirty()

func _roll_offer() -> Array:
	var keys: Array = DB.BLESSINGS.keys()
	var out: Array = []
	var guard := 0
	while out.size() < 3 and guard < 100:
		guard += 1
		var k: String = keys[randi() % keys.size()]
		var rar: String = DB.BLESSINGS[k]["rar"]
		var keep := 1.0 if rar == "R" else (0.6 if rar == "SR" else 0.2)
		if not out.has(k) and randf() < keep:
			out.append(k)
	return out

## Won floor → next floor + 3 blessing choices. Lost → run ends.
func apply_rift_result(won: bool) -> Dictionary:
	var r := _rift()
	if not won:
		r["alive"] = false
		mark_dirty()
		return {}
	var cleared := int(r["floor"])
	r["best"] = maxi(int(r["best"]), cleared)
	r["floor"] = cleared + 1
	r["offer"] = _roll_offer()
	var gold := 1500 + cleared * 400
	give({"gold": gold})
	mark_dirty()
	return {"gold": gold}

func rift_pick(k: String) -> bool:
	var r := _rift()
	if not (r["offer"] as Array).has(k):
		return false
	r["bless"].append(k)
	r["offer"] = []
	mark_dirty()
	return true

func rift_milestone_state(i: int) -> String:
	var r := _rift()
	if (r["claimed"] as Array).has(i):
		return "claimed"
	return "ready" if int(r["best"]) >= int(DB.RIFT_MILESTONES[i]["floor"]) else "locked"

func claim_rift_milestone(i: int) -> Dictionary:
	if rift_milestone_state(i) != "ready":
		return {}
	_rift()["claimed"].append(i)
	var g: Dictionary = DB.RIFT_MILESTONES[i]["give"]
	give(g)
	return g

## AI leaderboard by best floor this week (player included).
func rift_board() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("rb%d" % (day_key() / 7))
	var names := ["Kurogane", "Mireille", "Takumi_77", "Aster", "Nyx", "Ryoko", "BladeOfDawn", "Sora", "Hikari", "Vermilion", "LunaFox", "Gale", "Ophelia", "Kaito"]
	var day_f := float(posmod(day_key(), 7) + 1) / 7.0
	var expect := 4.0 + float(team_power()) / 2500.0
	var out: Array = []
	for i in names.size():
		out.append({"name": names[i] + " [AI]", "floor": maxi(1, int(expect * rng.randf_range(0.5, 1.6) * (0.4 + 0.6 * day_f))), "hero": DB.HEROES.keys()[rng.randi() % DB.HEROES.size()], "me": false})
	out.append({"name": str(s["player"]["name"]) + " (You)", "floor": int(_rift()["best"]), "hero": s["lobby_hero"], "me": true})
	out.sort_custom(func(a, b): return int(a["floor"]) > int(b["floor"]))
	return out

# =================================================================== private room

func _room() -> Dictionary:
	var r: Dictionary = s["room"]
	if int(r["day"]) != day_key():
		r["day"] = day_key()
		r["visits"] = 0
		r["rested"] = []
	return r

func max_bond() -> int:
	var m := 0
	for h in s["heroes"].values():
		m = maxi(m, int(h["bond"]))
	return m

func room_unlocked(r: Dictionary) -> bool:
	return max_bond() >= int(r["bond"])

func room_visits_left() -> int:
	return DB.ROOM_VISITS - int(_room()["visits"])

func room_hero() -> String:
	var h := str(_room()["hero"])
	return h if owns(h) else str(s["lobby_hero"])

## Talk in a room: returns VN lines (empty when no visits left). Bond is added here; x2 in the hero's favourite room.
func room_talk(loc: String) -> Array:
	var r := _room()
	if room_visits_left() <= 0:
		return []
	r["visits"] = int(r["visits"]) + 1
	var hid := room_hero()
	var rd := DB.room_def(loc)
	var fav := DB.fav_room(hid) == loc
	add_bond(hid, 30 if fav else 15)
	quest_progress("bond")
	mark_dirty()
	var line: String = rd["lines"][randi() % rd["lines"].size()]
	var out: Array = [[hid, line]]
	if fav:
		out.append([hid, "...This is my favourite place, you know. I'm glad it's with you."])
	out.append(DB.choice_line(hid, ["Stay as long as you like.", "You look happy here.", "Let's do this again."], 0.5))
	return out

## Rest together: once per room per day → +Energy and Bond.
func room_rest(loc: String) -> Dictionary:
	var r := _room()
	if (r["rested"] as Array).has(loc):
		return {}
	r["rested"].append(loc)
	var hid := room_hero()
	add_bond(hid, 60 if DB.fav_room(hid) == loc else 30)
	give({"energy": 20})
	mark_dirty()
	return {"energy": 20}

# =================================================================== notices

func news_unread() -> int:
	var seen: Array = s.get("news_seen", [])
	return DB.news().filter(func(n): return not seen.has(n["id"])).size()

func mark_news_read() -> void:
	s["news_seen"] = DB.news().map(func(n): return n["id"])
	mark_dirty()

# =================================================================== hero trials

## Highest trial tier cleared for a hero (-1 = none).
func trial_cleared(id: String) -> int:
	return int(s.get("trials", {}).get(id, -1))

func trial_open(id: String, tier: int) -> bool:
	return owns(id) and tier <= trial_cleared(id) + 1

## First clear of a tier: gems/etc + hero shards. Needs the hero alive at the end.
func apply_trial_result(id: String, tier: int, won: bool, hero_alive: bool) -> Dictionary:
	if not won or not hero_alive or tier <= trial_cleared(id):
		return {}
	var t: Dictionary = DB.TRIAL_TIERS[tier]
	var r: Dictionary = t["give"].duplicate()
	r["shard:" + id] = int(t["shards"])
	var tr: Dictionary = s.get("trials", {})
	tr[id] = tier
	s["trials"] = tr
	give(r)
	add_bond(id, 50)
	mark_dirty()
	return r

func trials_done() -> int:
	var n := 0
	for v in s.get("trials", {}).values():
		n += int(v) + 1
	return n

# =================================================================== secretary moment

func secretary_ready() -> bool:
	return int(s.get("sec_day", -1)) != day_key() and s["heroes"].size() > 0

## Today's moment for the lobby hero: VN lines + reward (marks the day used).
func secretary_moment() -> Dictionary:
	if not secretary_ready():
		return {}
	s["sec_day"] = day_key()
	var hid: String = s["lobby_hero"]
	var m: Dictionary = DB.SECRETARY_MOMENTS[posmod(day_key() + hash(hid), DB.SECRETARY_MOMENTS.size())]
	var lines: Array = []
	for l in m["lines"]:
		lines.append([hid, l])
	lines.append(DB.choice_line(hid, m["opts"], 1.0))
	give(m["give"])
	add_bond(hid, 20)
	mark_dirty()
	return {"lines": lines, "give": m["give"], "hero": hid}

# =================================================================== Hairly's fortune

func fortune_ready() -> bool:
	return int(s.get("fortune_day", -1)) != day_key()

## Draws today's card (random, once per day) and gives its gift.
func fortune_draw() -> Dictionary:
	if not fortune_ready():
		return {}
	s["fortune_day"] = day_key()
	var f: Dictionary = DB.FORTUNES[randi() % DB.FORTUNES.size()]
	s["fortune_card"] = f["card"]
	give(f["give"])
	mark_dirty()
	return f

# =================================================================== bestiary

func record_kills(ids: Array) -> void:
	var b: Dictionary = s.get("bestiary", {})
	for id in ids:
		if DB.ENEMIES.has(id):
			b[id] = int(b.get(id, 0)) + 1
	s["bestiary"] = b

func kills_of(id: String) -> int:
	return int(s.get("bestiary", {}).get(id, 0))

func bestiary_state(id: String, tier: int) -> String:
	if (s.get("bestiary_claimed", {}).get(id, []) as Array).has(tier):
		return "claimed"
	return "ready" if kills_of(id) >= int(DB.BESTIARY_TIERS[tier]["kills"]) else "locked"

func claim_bestiary(id: String, tier: int) -> Dictionary:
	if bestiary_state(id, tier) != "ready":
		return {}
	var c: Dictionary = s.get("bestiary_claimed", {})
	var arr: Array = c.get(id, [])
	arr.append(tier)
	c[id] = arr
	s["bestiary_claimed"] = c
	var g: Dictionary = DB.BESTIARY_TIERS[tier]["give"]
	give(g)
	return g

# =================================================================== taming

func pet(id: String) -> Dictionary:
	return s.get("tamed", {}).get(id, {})

func is_tamed(id: String) -> bool:
	return not pet(id).is_empty()

func tame_error(id: String) -> String:
	if is_tamed(id):
		return "Already tamed."
	if kills_of(id) < DB.TAME_KILLS:
		return "Defeat %d more to earn her trust." % (DB.TAME_KILLS - kills_of(id))
	if amount("gold") < DB.TAME_GOLD:
		return "Need %s Gold." % fmt(DB.TAME_GOLD)
	return ""

func tame(id: String) -> String:
	var err := tame_error(id)
	if err != "":
		return err
	spend("gold", DB.TAME_GOLD)
	var t: Dictionary = s.get("tamed", {})
	t[id] = {"bond": 1, "exp": 0, "talk_day": -1, "pat_day": -1, "pats": 0, "claimed": [], "date": Time.get_date_string_from_system()}
	s["tamed"] = t
	mark_dirty()
	return ""

func pet_story_state(id: String, ep: int) -> String:
	if not is_tamed(id):
		return "locked"
	if (pet(id).get("stories", []) as Array).has(ep):
		return "read"
	return "ready" if int(pet(id)["bond"]) >= int(DB.PET_STORY_REQ[ep]) else "locked"

## Marks an episode read; first read gives its reward (returned).
func read_pet_story(id: String, ep: int) -> Dictionary:
	var st := pet_story_state(id, ep)
	if st == "locked":
		return {}
	if st == "read":
		return {}
	var p := pet(id)
	var arr: Array = p.get("stories", [])
	arr.append(ep)
	p["stories"] = arr
	var g: Dictionary = DB.PET_STORY_REWARDS[ep]
	give(g)
	mark_dirty()
	return g

func pet_stories_ready() -> int:
	var n := 0
	for id in s.get("tamed", {}).keys():
		for ep in DB.PET_STORY_REQ.size():
			if pet_story_state(id, ep) == "ready":
				n += 1
	return n

## Companion: one tamed foe follows you — team +0.5% ATK/HP per Bond level (max +5%).
func companion() -> String:
	var c := str(s.get("companion", ""))
	return c if is_tamed(c) else ""

func set_companion(id: String) -> void:
	s["companion"] = id if is_tamed(id) else ""
	mark_dirty()

## Battle assist data for BattleSim.companion (empty when no Companion).
func companion_assist() -> Dictionary:
	var c := companion()
	return {} if c == "" else {"id": c, "bond": int(pet(c)["bond"])}

func companion_bonus() -> float:
	var c := companion()
	return 0.0 if c == "" else DB.COMPANION_PER_BOND * int(pet(c)["bond"])

func tamed_count() -> int:
	return s.get("tamed", {}).size()

## Adds pet bond EXP; returns rewards granted by milestones (may be empty).
func pet_add_exp(id: String, n: int) -> Dictionary:
	var p := pet(id)
	if p.is_empty() or int(p["bond"]) >= DB.PET_MAX_BOND:
		return {}
	p["exp"] = int(p["exp"]) + n
	var got := {}
	while int(p["bond"]) < DB.PET_MAX_BOND and int(p["exp"]) >= DB.pet_bond_next(int(p["bond"])):
		p["exp"] = int(p["exp"]) - DB.pet_bond_next(int(p["bond"]))
		p["bond"] = int(p["bond"]) + 1
		var lv := int(p["bond"])
		notify("%s Bond Lv.%d! ♥" % [DB.name_of(id), lv], Color("#ff8fb8"))
		if DB.PET_REWARDS.has(lv) and not (p["claimed"] as Array).has(lv):
			(p["claimed"] as Array).append(lv)
			var g: Dictionary = DB.PET_REWARDS[lv]
			give(g)
			for k in g.keys():
				got[k] = int(got.get(k, 0)) + int(g[k])
	if int(p["bond"]) >= DB.PET_MAX_BOND:
		p["exp"] = 0
	mark_dirty()
	return got

func pet_talk_ready(id: String) -> bool:
	return is_tamed(id) and int(pet(id)["talk_day"]) != day_key()

func pet_talk(id: String) -> String:
	if not pet_talk_ready(id):
		return ""
	pet(id)["talk_day"] = day_key()
	pet_add_exp(id, 25)
	quest_progress("bond")
	return DB.pet_line(id, 1 + randi() % 3)

func pet_pats_left(id: String) -> int:
	var p := pet(id)
	if p.is_empty():
		return 0
	if int(p["pat_day"]) != day_key():
		return DB.PET_PATS_PER_DAY
	return maxi(0, DB.PET_PATS_PER_DAY - int(p["pats"]))

func pet_pat(id: String) -> bool:
	if pet_pats_left(id) <= 0:
		return false
	var p := pet(id)
	if int(p["pat_day"]) != day_key():
		p["pat_day"] = day_key()
		p["pats"] = 0
	p["pats"] = int(p["pats"]) + 1
	pet_add_exp(id, 6)
	return true

func pet_gift(id: String, item_id: String) -> String:
	if not is_tamed(id):
		return "Tame her first."
	if amount(item_id) <= 0:
		return "You have no %s." % DB.ITEMS[item_id]["name"]
	if int(pet(id)["bond"]) >= DB.PET_MAX_BOND:
		return "Bond is already at max level."
	spend(item_id, 1)
	var mult := 2 if DB.fav_gift(id) == item_id else 1
	pet_add_exp(id, int(DB.ITEMS[item_id]["bond"]) * mult)
	sfx("star_up")
	return ""

## Forms (evolution arts) of a foe the player has unlocked: by kills or by pet bond.
func form_unlocked(id: String, k: int) -> bool:
	if k == 0:
		return kills_of(id) > 0
	var kk: int = DB.FORM_KILLS[mini(k, DB.FORM_KILLS.size() - 1)]
	var bb: int = DB.FORM_BOND[mini(k, DB.FORM_BOND.size() - 1)]
	return kills_of(id) >= kk or (is_tamed(id) and int(pet(id)["bond"]) >= bb)

func bestiary_ready() -> int:
	var n := 0
	for id in DB.ENEMIES.keys():
		for t in DB.BESTIARY_TIERS.size():
			if bestiary_state(id, t) == "ready":
				n += 1
	return n

## Ids of enemy units killed in a finished simulation.
static func killed_enemies(sim: BattleSim) -> Array:
	var out: Array = []
	for u in sim.units:
		if u["side"] == 1 and not u["alive"]:
			out.append(u["id"])
	return out

# =================================================================== dates

func _date_state() -> Dictionary:
	var d: Dictionary = s.get("dates", {"day": -1, "used": 0, "album": []})
	if int(d["day"]) != day_key():
		d["day"] = day_key()
		d["used"] = 0
	s["dates"] = d
	return d

func dates_left() -> int:
	return DB.DATE_PER_DAY - int(_date_state()["used"])

func can_date(id: String) -> bool:
	return owns(id) and int(hero(id)["bond"]) >= DB.DATE_BOND

func date_spot_open(sp: Dictionary) -> bool:
	return stages_cleared() >= int(sp["req"])

## VN lines for a date: narration + hero line + choice per beat.
func date_lines(id: String, key: String) -> Array:
	var sp := DB.date_spot(key)
	var first := DB.name_of(id).split(" ")[0]
	var out: Array = []
	for beat in sp["beats"]:
		out.append(["nar", str(beat[0]).replace("{n}", first)])
		out.append([id, str(beat[1])])
		out.append(DB.choice_line(id, beat[2], 1.0))
	return out

## Score = sum of the bond gains from the 3 choices (max 120). Saves the photo.
func finish_date(id: String, key: String, score: int) -> Dictionary:
	var d := _date_state()
	d["used"] = int(d["used"]) + 1
	var rank: Array = DB.DATE_RANKS[2]
	for r in DB.DATE_RANKS:
		if score >= int(r[1]):
			rank = r
			break
	var album: Array = d["album"]
	album.push_front({"hero": id, "spot": key, "rank": rank[0], "day": day_key()})
	if album.size() > 60:
		album.resize(60)
	var bonus := 40 if rank[0] == "PERFECT DATE" else (20 if rank[0] == "SWEET DATE" else 0)
	add_bond(id, bonus)
	var r := {"gems": 20 + bonus}
	give(r)
	quest_progress("bond")
	mark_dirty()
	return {"rank": rank, "reward": r, "bonus": bonus}

func date_album() -> Array:
	return _date_state()["album"]

# =================================================================== messenger

## {"day", "pending": {hero: key}, "done": {hero: [keys]}, "log": {hero: [[who, text], ...]}}
## who: "h" = hero, "p" = player. New chats are delivered once per day, up to DB.MSG_PER_DAY waiting.
func _msg_state() -> Dictionary:
	var m: Dictionary = s.get("messenger", {"day": -1, "pending": {}, "done": {}, "log": {}})
	s["messenger"] = m
	if int(m["day"]) != day_key() and feature_unlocked("messenger"):
		m["day"] = day_key()
		_msg_deliver(m)
	return m

func _msg_next_key(id: String, m: Dictionary) -> String:
	var done: Array = m["done"].get(id, [])
	if DB.MSG_PERSONAL.has(DB.base_id(id)) and not done.has("p") and int(hero(id)["bond"]) >= DB.MSG_BOND:
		return "p"
	return "t%d" % ((day_key() + id.hash()) % DB.MSG_TOPICS.size())

func _msg_deliver(m: Dictionary) -> void:
	var pending: Dictionary = m["pending"]
	var free := DB.MSG_PER_DAY - pending.size()
	if free <= 0:
		return
	var cands: Array = s["heroes"].keys().filter(func(id): return not pending.has(id))
	var day := day_key()
	# personal chats first, then a daily rotation so every hero gets a turn
	cands.sort_custom(func(a, b):
		var pa := _msg_next_key(a, m) == "p"
		var pb := _msg_next_key(b, m) == "p"
		if pa != pb:
			return pa
		return (str(a) + str(day)).hash() < (str(b) + str(day)).hash())
	for id in cands.slice(0, free):
		pending[id] = _msg_next_key(id, m)
	mark_dirty()

func msg_pending() -> Dictionary:
	return _msg_state()["pending"]

func msg_unread() -> int:
	return msg_pending().size() if feature_unlocked("messenger") else 0

func msg_log(id: String) -> Array:
	return _msg_state()["log"].get(id, [])

## Heroes with any chat history or a waiting message; waiting ones first.
func msg_contacts() -> Array:
	var m := _msg_state()
	var out: Array = []
	for id in s["heroes"].keys():
		if m["pending"].has(id) or m["log"].has(id):
			out.append(id)
	out.sort_custom(func(a, b):
		var pa: bool = m["pending"].has(a)
		var pb: bool = m["pending"].has(b)
		return pa if pa != pb else int(hero(a)["bond"]) > int(hero(b)["bond"]))
	return out

## Answer the waiting chat from a hero with reply 0 or 1.
## Returns {answer, best, bond, gems} or {} when nothing is waiting.
func msg_reply(id: String, choice: int) -> Dictionary:
	var m := _msg_state()
	if not m["pending"].has(id) or not owns(id):
		return {}
	var key: String = m["pending"][id]
	var th := DB.msg_thread(id, key)
	if th.is_empty():
		m["pending"].erase(id)
		return {}
	choice = clampi(choice, 0, 1)
	var hist: Array = m["log"].get(id, [])
	for line in th[0]:
		hist.append(["h", line])
	hist.append(["p", th[1][choice]])
	hist.append(["h", th[2][choice]])
	while hist.size() > DB.MSG_LOG_MAX:
		hist.pop_front()
	m["log"][id] = hist
	m["pending"].erase(id)
	var done: Array = m["done"].get(id, [])
	var first := not done.has(key)
	if first:
		done.append(key)
	m["done"][id] = done
	var best: bool = choice == int(th[3])
	var bond := DB.MSG_BOND_BEST if best else DB.MSG_BOND_OK
	add_bond(id, bond)
	var gems := DB.MSG_PERSONAL_GEMS if key == "p" and first else 0
	if gems > 0:
		give({"gems": gems})
	quest_progress("bond")
	mark_dirty()
	return {"answer": th[2][choice], "best": best, "bond": bond, "gems": gems}

# =================================================================== commander road

func road_state(lv: int) -> String:
	if (s.get("road", []) as Array).has(lv):
		return "claimed"
	return "ready" if int(s["player"]["level"]) >= lv else "locked"

func claim_road(lv: int) -> bool:
	if road_state(lv) != "ready":
		return false
	var r: Array = s.get("road", [])
	r.append(lv)
	s["road"] = r
	give(DB.road_reward(lv))
	return true

func road_ready() -> int:
	return DB.road_levels().filter(func(l): return road_state(l) == "ready").size()
