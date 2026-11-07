extends Screen
## The Forge: REFORGE a piece into another set, TEMPER its substats, FUSE 3 of a rarity into the
## next one, SALVAGE spare gear in bulk for Gold and Forge Embers.

const TABS := [["reforge", "REFORGE"], ["temper", "TEMPER"], ["fuse", "FUSE"], ["salvage", "SALVAGE"]]

var _tab := "reforge"
var _sel := 0                 # selected gear uid
var _filter := ""             # set filter for the list
var _set_pick := ""           # target set on the REFORGE tab
var _keep: Array = []         # substat indexes kept on the TEMPER tab
var _rar := {"R": true, "SR": false, "SSR": false}
var _enhanced := false
var _grid: GridContainer
var _well: Control
var _right: VBoxContainer
var _filters: HBoxContainer
var _tiles := {}              # uid -> frame Panel

func build() -> void:
	_tab = str(params.get("tab", "reforge"))
	_sel = int(params.get("uid", 0))
	set_bg("hell", 0.6)
	var fx := FestivalFX.new("firefly", Color("#ff8a3d"), 34)
	add_child(fx)
	move_child(fx, mini(2, get_child_count() - 1))
	var bar := header("FORGE", ["gold", "forge_ember"])
	for i in TABS.size():
		var key: String = TABS[i][0]
		var tb := UI.button(TABS[i][1], func(): main.replace("forge", {"tab": key, "uid": _sel}), "TabButton", Vector2(0, 42))
		tb.toggle_mode = true
		tb.button_pressed = key == _tab
		bar.add_child(tb)
		bar.move_child(tb, 4 + i)
	var b := body(76)
	# ---- left: gear list
	var lp := UI.panel()
	lp.anchor_right = 0.42
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(6)
	lp.add_child(lv)
	_filters = UI.hbox(4)
	lv.add_child(_filters)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	var sc := UI.scroll(_grid)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(sc)
	# ---- centre: the forge well
	_well = Control.new()
	_well.anchor_left = 0.43
	_well.anchor_right = 0.7
	_well.anchor_bottom = 1.0
	_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(_well)
	# ---- right: controls
	var rp := UI.panel()
	rp.anchor_left = 0.71
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	_right = UI.vbox(8)
	rp.add_child(UI.scroll(_right))
	_render()
	tutorial("temper" if _tab == "temper" else "forge")

func _render() -> void:
	_render_filters()
	_render_list()
	_render_well()
	_render_right()
	refresh()

## Gear shown on the current tab, best first.
func _items() -> Array:
	var l: Array
	if _tab == "salvage":
		l = Game.salvage_list(_rar.keys().filter(func(k): return _rar[k]), _enhanced)
	else:
		l = Game.s["gear"].filter(func(g): return (_filter == "" or DB.gear_set(g) == _filter) and (_tab != "fuse" or DB.GEAR_NEXT.has(g["rarity"])))
	l.sort_custom(func(a, c): return DB.gear_score(a) > DB.gear_score(c))
	return l

func _render_filters() -> void:
	for c in _filters.get_children():
		c.queue_free()
	if _tab == "salvage":
		_filters.add_child(UI.label("WILL BE SALVAGED", 14, Color("#ff8a9a"), 2))
		return
	_filters.add_child(_set_chip("ALL", "", UI.GOLD))
	for sid in DB.GEAR_SET_IDS:
		var sd: Dictionary = DB.GEAR_SETS[sid]
		_filters.add_child(_set_chip(str(sd["name"]).split(" ")[0], sid, Color(str(sd["color"]))))

func _set_chip(text: String, key: String, col: Color) -> Button:
	var on := _filter == key
	var b := UI.button(text, func():
		_filter = key
		_render(), "", Vector2(0, 34))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_stylebox_override("normal", UI.style(Color(col.r, col.g, col.b, 0.3 if on else 0.08), col if on else Color("#4a3a6e"), 8, 2 if on else 1, 2))
	b.add_theme_color_override("font_color", col.lightened(0.3))
	return b

func _render_list() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_tiles.clear()
	var items := _items()
	if items.is_empty():
		_grid.columns = 1
		var msg := "Nothing matches these options." if _tab == "salvage" else "No gear here. Armory Ruins, Gear Chests and story bosses drop equipment."
		if _tab == "fuse":
			msg = "Only R and SR pieces can be fused."
		_grid.add_child(UI.wrap_label(msg, 14, UI.MUTED))
		_sel = 0
		return
	_grid.columns = 4
	if _tab != "salvage" and not items.any(func(g): return int(g["uid"]) == _sel):
		_sel = int(items[0]["uid"])
	for g in items:
		_grid.add_child(_tile(g))
	_mark_sel()

func _tile(g: Dictionary) -> Button:
	var uid: int = g["uid"]
	var rc: Color = DB.RARITY_COLOR[g["rarity"]]
	var sd: Dictionary = DB.GEAR_SETS[DB.gear_set(g)]
	var btn := Button.new()
	btn.theme_type_variation = "FlatButton"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(88, 88)
	var fr := Panel.new()
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(fr)
	_tiles[uid] = fr
	var ic := UI.tex_rect(DB.icon(DB.GEAR[g["slot"]]["icon"]))
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 12
	ic.offset_top = 8
	ic.offset_right = -12
	ic.offset_bottom = -16
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(ic)
	var dot := ColorRect.new()
	dot.color = Color(str(sd["color"]))
	dot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dot.offset_top = -7
	dot.offset_left = 6
	dot.offset_right = -6
	dot.offset_bottom = -3
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(dot)
	var rl := UI.label(str(g["rarity"]) + ("  +%d" % int(g["lv"]) if int(g["lv"]) > 0 else ""), 11, rc.lightened(0.35), 3)
	rl.position = Vector2(6, 3)
	btn.add_child(rl)
	var ow := str(g.get("owner", ""))
	if ow != "":
		var face := UI.tex_rect(DB.face(ow), Vector2(26, 26), true)
		face.position = Vector2(58, 50)
		face.size = Vector2(26, 26)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(face)
	if g.get("lock", false):
		var ll := UI.label("LOCK", 10, UI.GOLD, 3)
		ll.position = Vector2(6, 62)
		btn.add_child(ll)
	btn.pressed.connect(func():
		Game.sfx("ui_click")
		if _tab == "salvage":
			return
		_sel = uid
		_set_pick = ""
		_keep = []
		_mark_sel()
		_render_well()
		_render_right())
	return btn

func _mark_sel() -> void:
	for uid in _tiles.keys():
		var g := Game.gear_by_uid(uid)
		var on: bool = uid == _sel and _tab != "salvage"
		var rc: Color = DB.RARITY_COLOR[g["rarity"]]
		_tiles[uid].add_theme_stylebox_override("panel", UI.style(Color(0.08, 0.05, 0.14, 0.95), UI.GOLD if on else rc, 10, 3 if on else 1, 0))

## The glowing gear (or the salvage pile) in the middle of the screen.
func _render_well() -> void:
	for c in _well.get_children():
		c.queue_free()
	var col := Color("#ff8a3d")
	var g := Game.gear_by_uid(_sel)
	if _tab != "salvage" and not g.is_empty():
		col = Color(str(DB.GEAR_SETS[DB.gear_set(g)]["color"]))
	var glow := TextureRect.new()
	glow.texture = load("res://art/ui/rays.png")
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.modulate = Color(col.r, col.g, col.b, 0.55)
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = gm
	_well.add_child(glow)
	glow.resized.connect(func(): glow.pivot_offset = glow.size * 0.5)
	glow.create_tween().set_loops().tween_property(glow, "rotation", TAU, 40.0).from(0.0)
	var v := UI.vbox(6)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_well.add_child(v)
	if _tab == "salvage":
		v.add_child(_center(UI.tex_rect(DB.icon("item_forge_ember"), Vector2(150, 150))))
		v.add_child(_center(UI.label("THE FURNACE", 22, UI.GOLD, 4)))
		return
	if g.is_empty():
		return
	var ic := UI.tex_rect(DB.icon(DB.GEAR[g["slot"]]["icon"]), Vector2(170, 170))
	v.add_child(_center(ic))
	v.add_child(_center(UI.label(DB.gear_name(g), 21, DB.RARITY_COLOR[g["rarity"]].lightened(0.35), 4)))
	v.add_child(_center(UI.label("%s %s" % [g["rarity"], str(g["slot"]).to_upper()], 13, UI.MUTED, 3)))
	v.add_child(_center(UI.label(DB.gear_desc(g), 14, UI.GREEN, 3)))
	v.add_child(_center(UI.label(DB.gear_subs_desc(g), 13, UI.SUB_STAT, 3)))
	v.add_child(_center(UI.label("◆ " + str(DB.GEAR_SETS[DB.gear_set(g)]["name"]), 16, col, 3)))
	var ow := str(g.get("owner", ""))
	if ow != "":
		v.add_child(_center(UI.label("Worn by " + DB.name_of(ow), 13, UI.TEXT, 3)))

func _center(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if c is Label:
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return c

func _render_right() -> void:
	for c in _right.get_children():
		c.queue_free()
	match _tab:
		"fuse": _right_fuse()
		"temper": _right_temper()
		"salvage": _right_salvage()
		_: _right_reforge()

func _lock_button(g: Dictionary) -> void:
	var uid: int = g["uid"]
	_right.add_child(UI.button("UNLOCK" if g.get("lock", false) else "LOCK (protect from Salvage & Fuse)", func():
		Game.toggle_gear_lock(uid)
		_render(), "", Vector2(0, 40)))

func _right_reforge() -> void:
	_right.add_child(UI.label("REFORGE", 18, UI.GOLD, 3))
	var g := Game.gear_by_uid(_sel)
	if g.is_empty():
		_right.add_child(UI.wrap_label("Pick a piece from the list.", 13, UI.MUTED))
		return
	_right.add_child(UI.wrap_label("Pick a new set. Rarity, level and owner stay the same.", 12, UI.MUTED))
	var cur := DB.gear_set(g)
	for s0 in DB.GEAR_SET_IDS:
		var sid: String = s0
		if sid == cur:
			continue
		var sd: Dictionary = DB.GEAR_SETS[sid]
		var col := Color(str(sd["color"]))
		var on := sid == _set_pick
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 64)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.add_theme_stylebox_override("panel", UI.style(Color(col.r, col.g, col.b, 0.22 if on else 0.06), col if on else Color("#4a3a6e"), 8, 2 if on else 1, 0))
		b.add_child(fr)
		var t := UI.label("◆ " + str(sd["name"]), 14, col, 2)
		t.position = Vector2(10, 4)
		b.add_child(t)
		var d := UI.wrap_label("%s  •  %s" % [sd["two_text"], sd["three_text"]], 11, UI.TEXT)
		d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		d.offset_left = 10
		d.offset_right = -8
		d.offset_top = 24
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(d)
		b.pressed.connect(func():
			Game.sfx("ui_click")
			_set_pick = sid
			_render_right())
		_right.add_child(b)
	var cost := int(DB.REFORGE_COST[g["rarity"]])
	var rb := UI.button("REFORGE  %d Embers" % cost, _do_reforge, "GoldButton", Vector2(0, 50))
	rb.disabled = _set_pick == "" or Game.amount("forge_ember") < cost
	_right.add_child(rb)
	_lock_button(g)

func _do_reforge() -> void:
	var err := Game.reforge_gear(_sel, _set_pick)
	if err != "":
		main.toast(err, UI.RED)
		return
	var col := Color(str(DB.GEAR_SETS[_set_pick]["color"]))
	main.toast("Reforged into %s!" % DB.GEAR_SETS[_set_pick]["name"], col)
	_set_pick = ""
	_render()
	_strike(col)

func _right_temper() -> void:
	_right.add_child(UI.label("TEMPER", 18, UI.GOLD, 3))
	var g := Game.gear_by_uid(_sel)
	if g.is_empty():
		_right.add_child(UI.wrap_label("Pick a piece from the list.", 13, UI.MUTED))
		return
	_right.add_child(UI.wrap_label("Rerolls substats. Upgrades (▲) stay on their slot. You compare the result before it applies.", 12, UI.MUTED))
	var subs: Array = g["subs"]
	for i0 in subs.size():
		var i: int = i0
		var cb := CheckButton.new()
		cb.text = DB.gear_sub_text(subs[i]) + ("▲" if int(subs[i].get("up", 0)) > 0 else "")
		cb.focus_mode = Control.FOCUS_NONE
		cb.button_pressed = _keep.has(i)
		# something must be left to reroll
		cb.disabled = subs.size() == 1 or (_keep.size() == subs.size() - 1 and not _keep.has(i))
		cb.toggled.connect(func(on: bool):
			if on:
				_keep.append(i)
			else:
				_keep.erase(i)
			_render_right())
		_right.add_child(cb)
	_right.add_child(UI.wrap_label("Switch on the substats to KEEP. Each one doubles the cost.", 12, UI.MUTED) if subs.size() > 1 else UI.wrap_label("One substat: nothing to keep.", 12, UI.MUTED))
	var cost := DB.temper_cost(g, _keep.size())
	var tb := UI.button("TEMPER  %d Embers" % cost, _do_temper, "GoldButton", Vector2(0, 50))
	tb.disabled = Game.amount("forge_ember") < cost
	_right.add_child(tb)
	_lock_button(g)

func _do_temper() -> void:
	var res := Game.temper_gear(_sel, _keep)
	if res.has("err"):
		main.toast(res["err"], UI.RED)
		return
	refresh()
	_strike(UI.SUB_STAT)
	var uid := _sel
	var g := Game.gear_by_uid(uid)
	var v: VBoxContainer = main.popup("TEMPERED", 620, false)
	v.get_meta("layer").set_meta("no_back", true)
	var h := UI.hbox(24)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	h.add_child(_sub_column("CURRENT", g["subs"], [], UI.MUTED))
	h.add_child(_sub_column("NEW", res["subs"], g["subs"], UI.SUB_STAT))
	var btns := UI.hbox(14)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(btns)
	btns.add_child(UI.button("KEEP CURRENT", func():
		main.close_popup(v)
		_render(), "", Vector2(200, 52)))
	btns.add_child(UI.button("TAKE NEW", func():
		main.close_popup(v)
		Game.temper_accept(uid, res["subs"])
		_keep = []
		Game.sfx("star_up")
		_render(), "GoldButton", Vector2(200, 52)))

## One side of the comparison; rows that differ from `base` are highlighted.
func _sub_column(title: String, subs: Array, base: Array, col: Color) -> VBoxContainer:
	var c := UI.vbox(6)
	c.custom_minimum_size = Vector2(240, 0)
	c.add_child(_center(UI.label(title, 15, col, 2)))
	for i in subs.size():
		var same: bool = base.is_empty() or subs[i] == base[i]
		c.add_child(_center(UI.label(DB.gear_sub_text(subs[i]) + ("▲" if int(subs[i].get("up", 0)) > 0 else ""), 18, UI.TEXT if same else UI.SUB_STAT, 3)))
	return c

func _right_fuse() -> void:
	_right.add_child(UI.label("FUSE", 18, UI.GOLD, 3))
	var g := Game.gear_by_uid(_sel)
	if g.is_empty():
		_right.add_child(UI.wrap_label("3 pieces of one rarity fuse into the next rarity: R to SR, SR to SSR.", 13, UI.MUTED))
		return
	var nxt: String = DB.GEAR_NEXT[g["rarity"]]
	_right.add_child(UI.wrap_label("Raises this piece from %s to %s. It keeps its slot, set, level and owner." % [g["rarity"], nxt], 12, UI.MUTED))
	var after := g.duplicate()
	after["rarity"] = nxt
	_right.add_child(UI.label("After fusing:", 13, UI.TEXT, 2))
	_right.add_child(UI.wrap_label(DB.gear_desc(after) + "\n+1 new substat", 14, UI.GREEN))
	var fodder := Game.fuse_fodder(_sel)
	_right.add_child(UI.label("Consumes (%d/2):" % fodder.size(), 13, UI.TEXT if fodder.size() >= 2 else Color("#ff8a9a"), 2))
	for f in fodder:
		var fd: Dictionary = f
		_right.add_child(UI.label("• %s  ◆ %s" % [DB.gear_name(fd), DB.GEAR_SETS[DB.gear_set(fd)]["name"]], 12, UI.MUTED))
	var cost := int(DB.FUSE_GOLD[g["rarity"]])
	var fb := UI.button("FUSE  %s Gold" % Game.fmt(cost), func():
		main.confirm("Consume the 2 pieces listed to raise %s to %s?" % [DB.gear_name(g), nxt], _do_fuse, "FUSE"), "GoldButton", Vector2(0, 50))
	fb.disabled = fodder.size() < 2 or Game.amount("gold") < cost
	_right.add_child(fb)
	_lock_button(g)

func _do_fuse() -> void:
	var err := Game.fuse_gear(_sel)
	if err != "":
		main.toast(err, UI.RED)
		return
	main.toast("Fusion complete: %s!" % DB.gear_name(Game.gear_by_uid(_sel)), UI.GOLD)
	# an SSR leaves the FUSE list: show it on REFORGE instead of jumping to another piece
	if Game.gear_by_uid(_sel)["rarity"] == "SSR":
		Game.sfx("star_up")
		main.replace("forge", {"tab": "reforge", "uid": _sel})
		return
	_render()
	_strike(UI.GOLD)

func _right_salvage() -> void:
	_right.add_child(UI.label("BULK SALVAGE", 18, UI.GOLD, 3))
	_right.add_child(UI.wrap_label("Equipped and locked pieces are never touched.", 12, UI.MUTED))
	for r0 in ["R", "SR", "SSR"]:
		var r: String = r0
		var cb := CheckButton.new()
		cb.text = "Include %s" % r
		cb.focus_mode = Control.FOCUS_NONE
		cb.button_pressed = _rar[r]
		cb.toggled.connect(func(on: bool):
			_rar[r] = on
			_render())
		_right.add_child(cb)
	var eb := CheckButton.new()
	eb.text = "Include enhanced (+1 and up)"
	eb.focus_mode = Control.FOCUS_NONE
	eb.button_pressed = _enhanced
	eb.toggled.connect(func(on: bool):
		_enhanced = on
		_render())
	_right.add_child(eb)
	var gold := 0
	var embers := 0
	var list := _items()
	for g in list:
		gold += Game.salvage_gold(g)
		embers += Game.salvage_embers(g)
	_right.add_child(UI.label("%d piece(s)" % list.size(), 15, Color.WHITE, 2))
	_right.add_child(UI.label("+%s Gold   +%d Embers" % [Game.fmt(gold), embers], 15, UI.GREEN, 2))
	var sb := UI.button("SALVAGE ALL", func():
		main.confirm("Salvage %d piece(s)? This can't be undone." % list.size(), _do_salvage, "SALVAGE"), "GoldButton", Vector2(0, 50))
	sb.disabled = list.is_empty()
	_right.add_child(sb)

func _do_salvage() -> void:
	var res := Game.salvage_bulk(_rar.keys().filter(func(k): return _rar[k]), _enhanced)
	main.toast("%d salvaged: +%s Gold  +%d Embers" % [res["count"], Game.fmt(res["gold"]), res["forge_ember"]], UI.GOLD)
	_render()
	_strike(Color("#ff8a3d"))

## Hammer blow on the well: sound, shockwave and sparks.
func _strike(col: Color) -> void:
	Game.sfx("star_up")
	var fx := SkillFX.new()
	add_child(fx)
	var c := _well.get_global_rect().get_center() - get_global_rect().position
	fx.wave(c, col, 300.0)
	fx.impact("FIRE", c, col, 120.0)
	fx.debris(c, col, 80.0, 0.1)
	get_tree().create_timer(1.3).timeout.connect(fx.queue_free)
	var pop := _well.get_child(_well.get_child_count() - 1) as Control
	if pop and not Game.reduce_fx():
		UI.pop(pop, 0.35)
