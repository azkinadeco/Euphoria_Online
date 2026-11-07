extends Screen
## Inventory: items, hero shards. Usable items can be consumed here.

var _grid: GridContainer
var _detail: VBoxContainer
var _sel := ""
var _tab := "ITEMS"

func build() -> void:
	set_bg("lobby", 0.65)
	header("BAG")
	var b := body(76)
	var lp := UI.panel()
	lp.anchor_right = 0.64
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(10)
	lp.add_child(lv)
	var tabs := UI.hbox(8)
	lv.add_child(tabs)
	for t in ["ITEMS", "GEAR", "RUNES", "SHARDS"]:
		var key: String = t
		var tb := UI.button(t, func(): _tab = key; _sel = ""; _render(), "TabButton", Vector2(140, 40))
		tb.toggle_mode = true
		tb.set_meta("key", key)
		tabs.add_child(tb)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	var sc := UI.scroll(_grid)
	lv.add_child(sc)
	sc.resized.connect(func(): _grid.columns = maxi(3, int(sc.size.x / 116.0)))
	var rp := UI.panel()
	rp.anchor_left = 0.66
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	_detail = UI.vbox(10)
	rp.add_child(_detail)
	_render()

func refresh() -> void:
	super.refresh()

func _entries() -> Array:
	var out: Array = []
	if _tab == "ITEMS":
		for k in ["gold", "gems", "hero_exp", "energy", "arena_coin"]:
			if k in ["gold", "gems"] or Game.amount(k) > 0:
				out.append(k)
		for k in DB.ITEMS.keys():
			if Game.amount(k) > 0:
				out.append(k)
	elif _tab == "RUNES":
		var rl: Array = Game.s["runes"].duplicate()
		rl.sort_custom(func(a, b): return DB.rune_value(a) > DB.rune_value(b) if a["type"] == b["type"] else a["type"] < b["type"])
		for r in rl:
			out.append("rid:%d" % int(r["uid"]))
	elif _tab == "GEAR":
		var gl: Array = Game.s["gear"].duplicate()
		gl.sort_custom(func(a, b): return DB.gear_score(a) > DB.gear_score(b))
		for g in gl:
			out.append("uid:%d" % int(g["uid"]))
	else:
		for id in DB.hero_ids():
			if int(Game.s["shards"].get(id, 0)) > 0:
				out.append("shard:" + id)
	return out

func _gear(k: String) -> Dictionary:
	return Game.gear_by_uid(int(k.substr(4))) if k.begins_with("uid:") else {}

func _rune(k: String) -> Dictionary:
	return Game.rune_by_uid(int(k.substr(4))) if k.begins_with("rid:") else {}

func _count(k: String) -> int:
	if k.begins_with("uid:") or k.begins_with("rid:"):
		return 1
	if k.begins_with("shard:"):
		return int(Game.s["shards"].get(k.substr(6), 0))
	return Game.amount(k)

func _render() -> void:
	for tb in find_children("*", "Button", true, false):
		if tb.has_meta("key"):
			tb.button_pressed = tb.get_meta("key") == _tab
	for c in _grid.get_children():
		c.queue_free()
	var entries := _entries()
	if _sel == "" and not entries.is_empty():
		_sel = entries[0]
	for k in entries:
		var key: String = k
		var btn := Button.new()
		btn.theme_type_variation = "TabButton"
		btn.toggle_mode = true
		btn.button_pressed = key == _sel
		btn.custom_minimum_size = Vector2(104, 132)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): Game.sfx("ui_click"); _sel = key; _render())
		var v := UI.vbox(2)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(v)
		var gk := _gear(key)
		var rk := _rune(key)
		var ic := UI.tex_rect(DB.icon(DB.GEAR[gk["slot"]]["icon"]) if not gk.is_empty() else (DB.icon("icon_shards") if not rk.is_empty() else Game.reward_icon(key)), Vector2(60, 60), key.begins_with("shard:"))
		if not rk.is_empty():
			ic.modulate = DB.RUNES[rk["type"]]["color"].lightened(0.2)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var l := UI.label("x" + Game.fmt(_count(key)), 14, UI.GOLD, 3)
		if not rk.is_empty():
			l.text = "T%d%s" % [int(rk["tier"]), " ●" if rk["owner"] != "" else ""]
			l.add_theme_color_override("font_color", DB.RUNES[rk["type"]]["color"].lightened(0.3))
		if not gk.is_empty():
			l.text = "%s +%d" % [gk["rarity"], int(gk["lv"])]
			l.add_theme_color_override("font_color", DB.RARITY_COLOR[gk["rarity"]].lightened(0.3))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		var nm := _short_name(key, gk, rk)
		if nm != "":
			var nl := UI.label(nm, 11, UI.MUTED, 2)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			nl.custom_minimum_size.x = 96
			nl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			v.add_child(nl)
		_grid.add_child(btn)
	if entries.is_empty():
		_grid.add_child(UI.label("Nothing here yet.", 16, UI.MUTED))
	UI.stagger(_grid, 0.02)
	_render_detail()

func _short_name(k: String, gk: Dictionary, rk: Dictionary) -> String:
	if not gk.is_empty():
		return str(DB.GEAR_SETS[DB.gear_set(gk)]["name"])
	if not rk.is_empty():
		return str(DB.RUNES[rk["type"]]["name"])
	if k.begins_with("shard:"):
		return DB.name_of(k.substr(6))
	return Game.reward_name(k)

func _fuse_fx() -> void:
	var fx := SkillFX.new()
	add_child(fx)
	var c := _detail.get_global_rect().get_center() - get_global_rect().position
	fx.wave(c, UI.GOLD, 260.0)
	fx.impact("LIGHT", c, UI.GOLD, 120.0)
	get_tree().create_timer(1.2).timeout.connect(fx.queue_free)

func _render_detail() -> void:
	for c in _detail.get_children():
		c.queue_free()
	if _sel == "":
		return
	var rk := _rune(_sel)
	if not rk.is_empty():
		var ricon := UI.tex_rect(DB.icon("icon_shards"), Vector2(0, 100))
		ricon.modulate = DB.RUNES[rk["type"]]["color"].lightened(0.2)
		_detail.add_child(ricon)
		_detail.add_child(UI.label(DB.rune_label(rk), 18, DB.RUNES[rk["type"]]["color"].lightened(0.3), 3))
		var ro := str(rk["owner"])
		_detail.add_child(UI.label("Equipped by %s" % DB.name_of(ro) if ro != "" else "Not equipped", 15))
		var same := Game.fusable(rk["type"], int(rk["tier"]))
		if int(rk["tier"]) < DB.RUNE_MAX_TIER:
			_detail.add_child(UI.label("Fusion: %d / 3 free T%d %s" % [same.size(), rk["tier"], DB.RUNES[rk["type"]]["name"]], 14, UI.TEXT))
			var rtype: String = rk["type"]
			var rtier: int = int(rk["tier"])
			var fb := UI.button("FUSE 3 → T%d  (%s Gold)" % [rtier + 1, Game.fmt(2000 * rtier)], func():
				var nr := Game.fuse_runes(rtype, rtier)
				if nr.is_empty():
					main.toast("Need 3 free runes of the same type/tier and enough Gold.", UI.RED)
					return
				Game.sfx("awakening")
				_fuse_fx()
				main.toast("Fusion success! %s" % DB.rune_label(nr), UI.GOLD)
				_sel = "rid:%d" % int(nr["uid"])
				_render(), "GoldButton", Vector2(0, 50))
			fb.disabled = same.size() < 3
			_detail.add_child(fb)
		else:
			_detail.add_child(UI.label("Maximum tier!", 15, UI.GREEN))
		if ro != "":
			_detail.add_child(UI.button("VIEW HERO", func(): main.go("hero_detail", {"id": ro, "tab": "GEAR"}), "", Vector2(0, 44)))
		return
	var gk := _gear(_sel)
	if not gk.is_empty():
		_detail.add_child(UI.tex_rect(DB.icon(DB.GEAR[gk["slot"]]["icon"]), Vector2(0, 110)))
		_detail.add_child(UI.label(DB.gear_name(gk), 22, DB.RARITY_COLOR[gk["rarity"]].lightened(0.3), 4))
		_detail.add_child(UI.label("%s %s" % [gk["rarity"], gk["slot"].to_upper()], 14, UI.MUTED))
		_detail.add_child(UI.label(DB.gear_desc(gk), 16, UI.GREEN))
		_detail.add_child(UI.label(DB.gear_subs_desc(gk), 14, UI.SUB_STAT))
		var gsd: Dictionary = DB.GEAR_SETS[DB.gear_set(gk)]
		_detail.add_child(UI.label("◆ " + str(gsd["name"]), 15, Color(str(gsd["color"])), 2))
		var owner := str(gk["owner"])
		_detail.add_child(UI.label("Equipped by %s" % DB.name_of(owner) if owner != "" else "Not equipped", 15))
		var uid: int = gk["uid"]
		_detail.add_child(UI.button("UNLOCK" if gk.get("lock", false) else "LOCK", func():
			Game.toggle_gear_lock(uid)
			_render(), "", Vector2(0, 44)))
		if owner != "":
			_detail.add_child(UI.button("VIEW HERO", func(): main.go("hero_detail", {"id": owner, "tab": "GEAR"}), "", Vector2(0, 44)))
		elif not gk.get("lock", false):
			_detail.add_child(UI.button("SALVAGE", func():
				main.confirm("Salvage %s for Gold and Forge Embers?" % DB.gear_name(gk), func():
					var embers := Game.salvage_embers(gk)
					var gold := Game.salvage_gear(uid)
					main.toast("+%s Gold  +%d Embers" % [Game.fmt(gold), embers], UI.GOLD)
					_sel = ""
					_render(), "SALVAGE"), "", Vector2(0, 44)))
		_detail.add_child(UI.button("OPEN FORGE", func(): main.go("forge", {"uid": uid}), "GoldButton", Vector2(0, 44)))
		return
	var ic := UI.tex_rect(Game.reward_icon(_sel), Vector2(0, 120), _sel.begins_with("shard:"))
	_detail.add_child(ic)
	_detail.add_child(UI.label(Game.reward_name(_sel), 22, UI.GOLD, 4))
	_detail.add_child(UI.label("Owned: %s" % Game.fmt(_count(_sel)), 16))
	var desc := ""
	if _sel.begins_with("shard:"):
		var hid := _sel.substr(6)
		desc = "Used to Star Up %s%s." % [DB.name_of(hid), "" if Game.owns(hid) else " or recruit her (%d needed)" % Game.RECRUIT_SHARDS[DB.rarity_of(hid)]]
		_detail.add_child(UI.wrap_label(desc, 15, UI.TEXT))
		_detail.add_child(UI.button("VIEW HERO", func(): main.go("hero_detail", {"id": hid}), "GoldButton", Vector2(0, 48)))
		return
	match _sel:
		"gold": desc = "Used for leveling and Star Up."
		"gems": desc = "Premium currency for summoning and the Gem Shop."
		"hero_exp": desc = "Spend it to level up heroes. Earned from AFK, stages and EXP Potions."
		"energy": desc = "Needed to enter story stages. Refills 1 every 3 minutes."
		"arena_coin": desc = "Earned in the Arena. Spend it in the Arena Shop."
		_: desc = str(DB.ITEMS.get(_sel, {}).get("desc", ""))
	_detail.add_child(UI.wrap_label(desc, 15, UI.TEXT))
	var it: Dictionary = DB.ITEMS.get(_sel, {})
	match str(it.get("kind", "")):
		"use":
			var key := _sel
			_detail.add_child(UI.button("USE x1", func(): Game.use_item(key, 1); _render(), "GoldButton", Vector2(0, 48)))
			if _count(key) > 1:
				_detail.add_child(UI.button("USE ALL (x%d)" % _count(key), func(): Game.use_item(key, _count(key)); _sel = ""; _render(), "", Vector2(0, 44)))
		"chest", "runes":
			var ck := _sel
			_detail.add_child(UI.button("OPEN x1", func(): Game.use_item(ck, 1); _render(), "GoldButton", Vector2(0, 48)))
			if _count(ck) > 1:
				_detail.add_child(UI.button("OPEN ALL (x%d)" % _count(ck), func(): Game.use_item(ck, _count(ck)); _sel = ""; _render(), "", Vector2(0, 44)))
		"gift", "oath":
			_detail.add_child(UI.button("GIVE TO A HERO", func(): main.go("hero_detail", {"id": Game.s["lobby_hero"], "tab": "BOND", "list": Game.s["heroes"].keys()}), "GoldButton", Vector2(0, 48)))
		"currency":
			_detail.add_child(UI.button("GO TO SUMMON", func(): main.go("gacha"), "GoldButton", Vector2(0, 48)))
