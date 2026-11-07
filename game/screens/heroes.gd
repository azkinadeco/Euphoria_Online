extends Screen
## Hero collection / codex.

var _grid: GridContainer
var _filter := "ALL"
var _elem := ""
var _elem_bar: HBoxContainer
var _sort := "power"
var _tabs: Array = []
var _count: Label

func build() -> void:
	set_bg("lobby", 0.62)
	header("HEROES")
	var b := body(76)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var bar := UI.hbox(8)
	v.add_child(bar)
	for f in ["ALL", "OWNED", "SSR", "SR", "R"]:
		var key: String = f
		var t := UI.button(f, func(): _filter = key; _rebuild(), "TabButton", Vector2(76, 40))
		t.toggle_mode = true
		bar.add_child(t)
		_tabs.append(t)
	bar.add_child(UI.spacer())
	_count = UI.label("", 15, UI.MUTED, 3)
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_count)
	var cbl := UI.label("Collection +%.1f%% stats" % (Game.collection_bonus() * 100.0), 14, UI.GREEN, 3)
	cbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cbl.tooltip_text = "Every hero you own gives +0.5% HP/ATK/DEF to all heroes."
	cbl.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.add_child(cbl)
	bar.add_child(UI.button("GALLERY", func(): main.go("gallery"), "", Vector2(104, 40)))
	var cx := UI.button("CODEX", _codex, "GoldButton" if Game.codex_claimable() > 0 else "", Vector2(96, 40))
	bar.add_child(cx)
	if Game.codex_claimable() > 0:
		UI.add_badge(cx, Game.codex_claimable())
	var sort_b := UI.button("Sort: Power", Callable(), "", Vector2(128, 40))
	sort_b.add_theme_font_size_override("font_size", 14)
	sort_b.pressed.connect(func():
		_sort = "rarity" if _sort == "power" else ("level" if _sort == "rarity" else "power")
		sort_b.text = "Sort: " + _sort.capitalize()
		_rebuild())
	bar.add_child(sort_b)
	_elem_bar = UI.hbox(6)
	v.add_child(_elem_bar)
	for el in ["", "FIRE", "WATER", "WIND", "EARTH", "LIGHT", "DARK"]:
		var e2: String = el
		var eb := Button.new()
		eb.theme_type_variation = "TabButton"
		eb.toggle_mode = true
		eb.focus_mode = Control.FOCUS_NONE
		eb.custom_minimum_size = Vector2(56 if el != "" else 70, 38)
		eb.set_meta("elem", el)
		if el == "":
			eb.text = "ALL"
		else:
			eb.icon = DB.icon(DB.ELEMENT_ICON[el])
			eb.expand_icon = true
			eb.tooltip_text = el
		eb.pressed.connect(func(): Game.sfx("ui_click"); _elem = e2; _rebuild())
		_elem_bar.add_child(eb)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	var sc := UI.scroll(UI.margin(_grid, 6, 6, 6, 6))
	v.add_child(sc)
	_grid.columns = 6
	_sc = sc
	# 6 cards per row (bigger art); the card size follows the available width
	sc.resized.connect(func():
		var w := clampf((sc.size.x - 20.0 - 14.0 * 5.0) / 6.0, 120.0, 220.0)
		if absf(w - _card_w) > 4.0:
			_card_w = w
			_rebuild())
	_rebuild()

var _sc: Control
var _card_w := 170.0

func _codex() -> void:
	var v: VBoxContainer = main.popup("HERO CODEX", 760)
	v.add_child(UI.wrap_label("Collect and raise heroes to earn one-time rewards: Recruited • 5★ • Bond 10 • Awakening A5.", 14, UI.MUTED))
	var list := UI.vbox(4)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 380)
	v.add_child(sc)
	for id in DB.hero_ids():
		var row := UI.hbox(8)
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(id)], 6, 2, 1)
		var fc := UI.tex_rect(DB.face(id), Vector2(40, 40), true)
		if not Game.owns(id):
			fc.modulate = Color(0.3, 0.3, 0.35)
		fp.add_child(fc)
		row.add_child(fp)
		var nl := UI.label(DB.name_of(id), 15, Color.WHITE if Game.owns(id) else UI.MUTED, 2)
		nl.custom_minimum_size = Vector2(140, 0)
		row.add_child(nl)
		for st in DB.CODEX_STEPS:
			var got := Game.codex_reached(id, st["id"])
			var cl := Game.codex_claimed(id, st["id"])
			var col: Color = UI.GREEN if cl else (UI.GOLD if got else Color(1, 1, 1, 0.25))
			var chip := UI.styled_panel(Color(0, 0, 0, 0.4), col, 8, 1, 6)
			chip.add_child(UI.label(("✔ " if cl else "") + str(st["name"]), 12, col))
			row.add_child(chip)
		list.add_child(row)
	var n := Game.codex_claimable()
	var b := UI.button("CLAIM ALL (%d)" % n, func():
		var r := Game.claim_codex_all()
		main.close_popup(v)
		if not r.is_empty():
			main.show_rewards("CODEX REWARDS", r, func(): main.replace("heroes")), "GoldButton", Vector2(220, 48))
	b.disabled = n == 0
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)

func _rebuild() -> void:
	for t in _tabs:
		t.button_pressed = t.text == _filter
	if is_instance_valid(_elem_bar):
		for eb in _elem_bar.get_children():
			eb.button_pressed = str(eb.get_meta("elem")) == _elem
	for c in _grid.get_children():
		c.queue_free()
	var ids: Array = []
	for id in DB.hero_ids():
		var owned := Game.owns(id)
		if _filter == "OWNED" and not owned:
			continue
		if _filter in ["SSR", "SR", "R"] and DB.rarity_of(id) != _filter:
			continue
		if _elem != "" and DB.ELEMENT_GROUP.get(DB.element_of(id), "") != _elem:
			continue
		ids.append(id)
	ids.sort_custom(func(a, b):
		var oa := Game.owns(a)
		var ob := Game.owns(b)
		if oa != ob:
			return oa
		match _sort:
			"rarity":
				return ["SSR", "SR", "R"].find(DB.rarity_of(a)) < ["SSR", "SR", "R"].find(DB.rarity_of(b))
			"level":
				return int(Game.hero(a).get("level", 0)) > int(Game.hero(b).get("level", 0))
		return Game.hero_power(a) > Game.hero_power(b))
	for id in ids:
		var hid: String = id
		var card := HeroCard.new(hid, Vector2(_card_w, _card_w * 1.3), {"skin": true})
		card.pressed.connect(func():
			Game.sfx("ui_click")
			main.go("hero_detail", {"id": hid, "list": ids}))
		_grid.add_child(card)
	_count.text = "Owned %d / %d" % [Game.s["heroes"].size(), DB.HEROES.size()]
	UI.stagger(_grid, 0.025)
