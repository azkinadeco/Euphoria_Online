extends Screen
## Inventory: items, hero shards. Usable items can be consumed here.

var _grid: GridContainer
var _detail: VBoxContainer
var _sel := ""
var _tab := "ITEMS"
var _filter := "ALL"
var _filters: HBoxContainer
var _summary: Label

## Item kind -> [filter group, frame colour]
const KIND_STYLE := {
	"currency": ["CURRENCY", "#5fb8ff"], "use": ["UPGRADE", "#7ee08a"], "material": ["UPGRADE", "#7ee08a"], "shard": ["UPGRADE", "#7ee08a"],
	"chest": ["CHESTS", "#ffcf5a"], "runes": ["CHESTS", "#ffcf5a"], "gift": ["GIFTS", "#ff8fb8"], "oath": ["GIFTS", "#ff8fb8"],
	"meal": ["FOOD", "#ffa860"], "ingredient": ["FOOD", "#ffa860"],
}

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
		var tb := UI.button(t, func(): _tab = key; _sel = ""; _filter = "ALL"; _render(), "TabButton", Vector2(140, 40))
		tb.toggle_mode = true
		tb.set_meta("key", key)
		tabs.add_child(tb)
	_filters = UI.hbox(6)
	lv.add_child(_filters)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	var sc := UI.scroll(_grid)
	lv.add_child(sc)
	sc.resized.connect(func(): _grid.columns = maxi(3, int(sc.size.x / 116.0)) if not _entries().is_empty() else 1)
	_summary = UI.label("", 13, UI.MUTED, 2)
	lv.add_child(_summary)
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
		if _filter != "ALL":
			out = out.filter(func(k): return _group(k) == _filter)
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

func _group(k: String) -> String:
	if k in ["gold", "gems", "hero_exp", "energy", "arena_coin"]:
		return "CURRENCY"
	return str(KIND_STYLE.get(str(DB.ITEMS.get(k, {}).get("kind", "")), ["UPGRADE"])[0])

func _frame_col(k: String, gk: Dictionary, rk: Dictionary) -> Color:
	if not gk.is_empty():
		return DB.RARITY_COLOR[gk["rarity"]]
	if not rk.is_empty():
		return DB.RUNES[rk["type"]]["color"]
	if k.begins_with("shard:"):
		return DB.theme_color(k.substr(6))
	if k in ["gold", "gems", "hero_exp", "energy", "arena_coin"]:
		return Color("#5fb8ff")
	return Color(str(KIND_STYLE.get(str(DB.ITEMS.get(k, {}).get("kind", "")), ["", "#b9a6e0"])[1]))

## Can this entry be used / opened straight from the bag?
func _actionable(k: String) -> bool:
	return str(DB.ITEMS.get(k, {}).get("kind", "")) in ["use", "chest", "runes"]

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
			var tk: String = tb.get_meta("key")
			tb.button_pressed = tk == _tab
			tb.text = "%s  %d" % [tk, _count_tab(tk)]
	for c in _grid.get_children():
		c.queue_free()
	for c in _filters.get_children():
		c.queue_free()
	_filters.visible = _tab == "ITEMS"
	if _tab == "ITEMS":
		for f in ["ALL", "CURRENCY", "UPGRADE", "CHESTS", "GIFTS", "FOOD"]:
			var fk: String = f
			var fb := UI.button(fk, func(): _filter = fk; _sel = ""; _render(), "TabButton", Vector2(0, 30))
			fb.toggle_mode = true
			fb.button_pressed = fk == _filter
			fb.add_theme_font_size_override("font_size", 12)
			_filters.add_child(fb)
	var entries := _entries()
	if not entries.has(_sel):
		_sel = entries[0] if not entries.is_empty() else ""
	var sc := _grid.get_parent() as Control
	_grid.columns = maxi(3, int(sc.size.x / 116.0)) if not entries.is_empty() and sc.size.x > 0 else (1 if entries.is_empty() else _grid.columns)
	var usable := 0
	for k in entries:
		var key: String = k
		var gk := _gear(key)
		var rk := _rune(key)
		var col := _frame_col(key, gk, rk)
		var picked := key == _sel
		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(104, 136)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): Game.sfx("ui_click"); _sel = key; _render())
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st := UI.style(Color(col.darkened(0.82), 0.95), col if picked else Color(col, 0.45), 12, 3 if picked else 1, 0)
		st.shadow_color = Color(col, 0.55 if picked else 0.0)
		st.shadow_size = 10 if picked else 0
		fr.add_theme_stylebox_override("panel", st)
		btn.add_child(fr)
		# soft glow behind the icon
		var gl := TextureRect.new()
		gl.texture = _glow_tex(col, 0.45)
		gl.stretch_mode = TextureRect.STRETCH_SCALE
		gl.position = Vector2(12, 2)
		gl.size = Vector2(80, 80)
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(gl)
		var v := UI.vbox(2)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_top = 10
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(v)
		var is_shard := key.begins_with("shard:")
		var tex: Texture2D
		if not gk.is_empty():
			tex = DB.icon(DB.GEAR[gk["slot"]]["icon"])
		elif not rk.is_empty():
			tex = DB.icon("icon_shards")
		elif is_shard:
			tex = DB.face(key.substr(6))
		else:
			tex = Game.reward_icon(key)
		var ic := UI.tex_rect(tex, Vector2(62, 62), is_shard)
		if not rk.is_empty():
			ic.modulate = DB.RUNES[rk["type"]]["color"].lightened(0.2)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var nl := UI.label(_short_name(key, gk, rk), 11, Color.WHITE if picked else UI.TEXT, 2)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nl.custom_minimum_size.x = 96
		nl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(nl)
		if is_shard:
			var hid := key.substr(6)
			var need: int = int(Game.star_up_cost(hid)["shards"]) if Game.owns(hid) else int(Game.RECRUIT_SHARDS[DB.rarity_of(hid)])
			var sb := UI.bar(_count(key), need, "GoldBar", 5)
			sb.custom_minimum_size.x = 80
			sb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			v.add_child(sb)
		# quantity / tier pill at the bottom
		var qt := "x" + Game.fmt(_count(key))
		var qc := UI.GOLD
		if not rk.is_empty():
			qt = "T%d" % int(rk["tier"])
			qc = DB.RUNES[rk["type"]]["color"].lightened(0.3)
		elif not gk.is_empty():
			qt = "%s +%d" % [gk["rarity"], int(gk["lv"])]
			qc = DB.RARITY_COLOR[gk["rarity"]].lightened(0.3)
		var qp := UI.styled_panel(Color(0, 0, 0, 0.6), Color(qc, 0.5), 9, 1, 0)
		qp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		qp.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		qp.grow_horizontal = Control.GROW_DIRECTION_BOTH
		qp.grow_vertical = Control.GROW_DIRECTION_BEGIN
		qp.offset_bottom = -6
		var ql := UI.label(qt, 13, qc, 3)
		ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ql.custom_minimum_size.x = 60
		qp.add_child(ql)
		btn.add_child(qp)
		# corner badge: E = equipped, ! = ready to use / open, L = locked gear
		var badge := ""
		var bcol := UI.GREEN
		if (not gk.is_empty() and str(gk["owner"]) != "") or (not rk.is_empty() and str(rk["owner"]) != ""):
			badge = "E"
			bcol = Color("#9fd0ff")
		elif _actionable(key):
			badge = "!"
			usable += 1
		elif not gk.is_empty() and gk.get("lock", false):
			badge = "L"
			bcol = UI.GOLD
		if badge != "":
			var bp := UI.styled_panel(bcol.darkened(0.55), bcol, 11, 1, 0)
			bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bp.position = Vector2(78, 5)
			bp.custom_minimum_size = Vector2(22, 22)
			var bl := UI.label(badge, 12, Color.WHITE, 2)
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			bp.add_child(bl)
			btn.add_child(bp)
			if badge == "!":
				var pt := bp.create_tween().set_loops()
				pt.tween_property(bp, "modulate:a", 0.45, 0.7).set_trans(Tween.TRANS_SINE)
				pt.tween_property(bp, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		UI.hover_fx(btn)
		_grid.add_child(btn)
	_summary.text = ""
	if not entries.is_empty():
		match _tab:
			"ITEMS": _summary.text = "%d item type%s%s" % [entries.size(), "" if entries.size() == 1 else "s", ("   •   %d ready to use / open (!)" % usable) if usable > 0 else ""]
			"GEAR": _summary.text = "%d pieces   •   %d equipped (E)" % [entries.size(), entries.filter(func(q): return str(_gear(q)["owner"]) != "").size()]
			"RUNES": _summary.text = "%d runes   •   %d equipped (E)" % [entries.size(), entries.filter(func(q): return str(_rune(q)["owner"]) != "").size()]
			_: _summary.text = "%d heroes with shards   •   bar = progress to the next Star Up / recruit" % entries.size()
	else:
		_empty_state()
	UI.stagger(_grid, 0.02)
	_render_detail()

func _glow_tex(col: Color, a: float) -> GradientTexture2D:
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(col, a))
	gr.set_color(1, Color(col, 0.0))
	gt.gradient = gr
	return gt

func _count_tab(t: String) -> int:
	match t:
		"GEAR": return Game.s["gear"].size()
		"RUNES": return Game.s["runes"].size()
		"SHARDS": return DB.hero_ids().filter(func(id): return int(Game.s["shards"].get(id, 0)) > 0).size()
	var saved := [_tab, _filter]
	_tab = "ITEMS"
	_filter = "ALL"
	var n := _entries().size()
	_tab = saved[0]
	_filter = saved[1]
	return n

## Friendly empty tab: what goes here and where to get it.
func _empty_state() -> void:
	var all := {
		"GEAR": ["gear_weapon", "NO GEAR YET", "Weapons, armor and relics drop from Boss Hunts, the Dungeon and story bosses.", "BOSS HUNT", "hunt"],
		"RUNES": ["icon_shards", "NO RUNES YET", "Runes socket into heroes for bonus stats. Hunt the Spore Queen or open Rune Chests.", "BOSS HUNT", "hunt"],
		"SHARDS": ["icon_gacha", "NO HERO SHARDS", "Duplicate summons and Boss Hunts give shards. Use them to Star Up or recruit heroes.", "SUMMON", "gacha"],
	}
	var info: Array = all.get(_tab, ["icon_bag", "NOTHING HERE", "Items of this type will show up here.", "SHOP", "shop"])
	var ep := UI.styled_panel(Color(0.08, 0.05, 0.14, 0.7), Color(1, 1, 1, 0.12), 16, 1, 22)
	ep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ev := UI.vbox(8)
	ev.alignment = BoxContainer.ALIGNMENT_CENTER
	ep.add_child(ev)
	var ic := UI.tex_rect(DB.icon(str(info[0])), Vector2(88, 88))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.modulate = Color(1, 1, 1, 0.8)
	ev.add_child(ic)
	var t := UI.label(str(info[1]), 20, UI.GOLD, 4)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(t)
	var d := UI.wrap_label(str(info[2]), 14, UI.TEXT)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(d)
	var scr: String = info[4]
	var gb := UI.button("GO TO " + str(info[3]), func(): main.go(scr), "GoldButton", Vector2(240, 46))
	gb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not Game.feature_unlocked(scr):
		gb.disabled = true
		gb.text = "%s  •  Lv.%d" % [info[3], int(DB.FEATURE_UNLOCK.get(scr, 1))]
	ev.add_child(gb)
	_grid.add_child(ep)
	# the empty right panel gets a matching hint
	for c in _detail.get_children():
		c.queue_free()
	var hv := UI.vbox(10)
	hv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	var hi := UI.tex_rect(DB.icon("icon_bag"), Vector2(70, 70))
	hi.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hi.modulate = Color(1, 1, 1, 0.35)
	hv.add_child(hi)
	var hl := UI.wrap_label("Pick something in the grid to see its details here.", 14, UI.MUTED)
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(hl)
	(func(): _detail.add_child(hv)).call_deferred()

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

## Top of the detail panel: glowing icon medallion, name, group tag and the owned count.
func _detail_header(tex: Texture2D, title: String, col: Color, round_icon: bool) -> void:
	var hold := Control.new()
	hold.custom_minimum_size = Vector2(0, 150)
	_detail.add_child(hold)
	var gl := TextureRect.new()
	gl.texture = _glow_tex(col, 0.55)
	gl.stretch_mode = TextureRect.STRETCH_SCALE
	gl.set_anchors_preset(Control.PRESET_CENTER)
	gl.offset_left = -85
	gl.offset_right = 85
	gl.offset_top = -80
	gl.offset_bottom = 80
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hold.add_child(gl)
	var gtw := gl.create_tween().set_loops()
	gtw.tween_property(gl, "modulate:a", 0.55, 1.6).set_trans(Tween.TRANS_SINE)
	gtw.tween_property(gl, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	var ic := UI.tex_rect(tex, Vector2(116, 116), round_icon)
	ic.set_anchors_preset(Control.PRESET_CENTER)
	ic.offset_left = -58
	ic.offset_right = 58
	ic.offset_top = -58
	ic.offset_bottom = 58
	hold.add_child(ic)
	var nl := UI.label(title, 22, Color.WHITE, 4)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.add_child(nl)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var tag := UI.styled_panel(Color(col, 0.18), Color(col, 0.7), 10, 1, 0)
	tag.add_child(UI.label("  %s  " % ("HERO SHARD" if _sel.begins_with("shard:") else _group(_sel)), 12, col.lightened(0.35), 2))
	row.add_child(tag)
	row.add_child(UI.label("Owned  %s" % Game.fmt(_count(_sel)), 16, UI.GOLD, 3))
	_detail.add_child(row)
	var sep := ColorRect.new()
	sep.color = Color(col, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	_detail.add_child(sep)

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
	_detail_header(Game.reward_icon(_sel) if not _sel.begins_with("shard:") else DB.face(_sel.substr(6)), Game.reward_name(_sel), _frame_col(_sel, {}, {}), _sel.begins_with("shard:"))
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
	_add_sources(_sel)
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
		"meal":
			var mk := _sel
			_detail.add_child(UI.button("SERVE MEAL", func():
				var err := Game.serve_meal(mk)
				main.toast(err if err != "" else "%s served!" % DB.ITEMS[mk]["name"], UI.RED if err != "" else UI.GREEN)
				_render(), "GoldButton", Vector2(0, 48)))
			_detail.add_child(UI.button("GO TO KITCHEN", func(): main.go("kitchen"), "", Vector2(0, 44)))
		"ingredient":
			_detail.add_child(UI.button("GO TO KITCHEN", func(): main.go("kitchen"), "GoldButton", Vector2(0, 48)))
		"currency":
			_detail.add_child(UI.button("GO TO SUMMON", func(): main.go("gacha"), "GoldButton", Vector2(0, 48)))

## "OBTAIN FROM" list with GO buttons. Locked screens show their unlock level.
func _add_sources(id: String) -> void:
	var src := DB.item_sources(id)
	if src.is_empty():
		return
	_detail.add_child(UI.label("OBTAIN FROM", 13, UI.GOLD, 2))
	for e in src.slice(0, 4):
		var row := UI.hbox(8)
		var dot := UI.label("•", 15, Color("#ffb070"))
		row.add_child(dot)
		var nl := UI.label(str(e[0]), 14, UI.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nl.custom_minimum_size.x = 60
		row.add_child(nl)
		var scr: String = e[1]
		var prm: Dictionary = e[2]
		if Game.feature_unlocked(scr):
			row.add_child(UI.button("GO", func(): main.go(scr, prm), "", Vector2(64, 32)))
		else:
			row.add_child(UI.label("Lv.%d" % int(DB.FEATURE_UNLOCK.get(scr, 1)), 13, UI.MUTED, 2))
		_detail.add_child(row)
