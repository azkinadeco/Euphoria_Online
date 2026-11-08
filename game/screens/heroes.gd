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

const STEP_ICON := {"own": "icon_gacha", "star5": "item_star_stone", "bond10": "icon_heart", "awaken5": "icon_awakening"}

## Hero Codex: overall progress, what each step pays, and one row per hero (ready-to-claim first).
func _codex() -> void:
	var v: VBoxContainer = main.popup("HERO CODEX", 1040)
	_codex_v = v
	_render_codex()

var _codex_v: VBoxContainer

func _render_codex() -> void:
	var v := _codex_v
	if not is_instance_valid(v):
		return
	for c in v.get_children():
		if c.has_meta("codex"):
			c.queue_free()
	var steps: Array = DB.CODEX_STEPS
	var ids: Array = DB.hero_ids()
	var done := 0
	var per_step := {}
	for id in ids:
		for st in steps:
			if Game.codex_claimed(id, st["id"]):
				done += 1
				per_step[st["id"]] = int(per_step.get(st["id"], 0)) + 1
	var total := ids.size() * steps.size()
	var root := UI.vbox(10)
	root.set_meta("codex", true)
	v.add_child(root)
	# --- summary: overall bar + one card per step with its reward
	var top := UI.hbox(10)
	root.add_child(top)
	var sum := UI.styled_panel(Color(1, 0.8, 0.4, 0.08), Color(UI.GOLD, 0.5), 12, 1, 10)
	sum.custom_minimum_size = Vector2(200, 0)
	top.add_child(sum)
	var sv := UI.vbox(4)
	sum.add_child(sv)
	sv.add_child(UI.label("CODEX PROGRESS", 12, UI.MUTED, 2))
	sv.add_child(UI.label("%d / %d" % [done, total], 26, UI.GOLD, 4))
	sv.add_child(UI.bar(done, total, "", 10))
	sv.add_child(UI.label("%d%% complete" % int(100.0 * done / maxf(1.0, total)), 12, UI.TEXT, 2))
	for st in steps:
		var sp := UI.styled_panel(Color(0.08, 0.05, 0.14, 0.9), Color(1, 1, 1, 0.15), 12, 1, 8)
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(sp)
		var spv := UI.vbox(3)
		sp.add_child(spv)
		var sh := UI.hbox(6)
		spv.add_child(sh)
		sh.add_child(UI.tex_rect(DB.icon(STEP_ICON.get(st["id"], "icon_codex")), Vector2(26, 26)))
		var sl := UI.label(str(st["name"]), 14, Color.WHITE, 2)
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sh.add_child(sl)
		sh.add_child(UI.label("%d/%d" % [int(per_step.get(st["id"], 0)), ids.size()], 12, UI.MUTED, 2))
		spv.add_child(UI.reward_row(st["give"], 24, 12))
	# --- hero rows
	ids.sort_custom(func(a, b):
		var ra := _codex_ready(a)
		var rb := _codex_ready(b)
		if (ra > 0) != (rb > 0):
			return ra > 0
		if Game.owns(a) != Game.owns(b):
			return Game.owns(a)
		return DB.name_of(a) < DB.name_of(b))
	var list := UI.vbox(6)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 330)
	root.add_child(sc)
	for id in ids:
		list.add_child(_codex_row(id))
	# --- footer
	var n := Game.codex_claimable()
	var foot := UI.hbox(12)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(foot)
	var pend := {}
	for id in Game.s["heroes"].keys():
		for st in steps:
			if Game.codex_reached(id, st["id"]) and not Game.codex_claimed(id, st["id"]):
				for k in st["give"].keys():
					pend[k] = int(pend.get(k, 0)) + int(st["give"][k])
	if not pend.is_empty():
		foot.add_child(UI.label("READY:", 13, UI.GOLD, 2))
		foot.add_child(UI.reward_row(pend, 26, 13))
	var b := UI.button("CLAIM ALL (%d)" % n, func():
		var r := Game.claim_codex_all()
		if not r.is_empty():
			main.show_rewards("CODEX REWARDS", r, func(): _render_codex(); _rebuild())
		, "GoldButton", Vector2(220, 46))
	b.disabled = n == 0
	foot.add_child(b)

func _codex_ready(id: String) -> int:
	var n := 0
	for st in DB.CODEX_STEPS:
		if Game.codex_reached(id, st["id"]) and not Game.codex_claimed(id, st["id"]):
			n += 1
	return n

## "3 / 5★"-style progress text for a step.
func _codex_prog(id: String, step: String) -> Array:
	var h := Game.hero(id)
	if h.is_empty():
		return [0, 1, "Not recruited"]
	match step:
		"star5": return [int(h["star"]), 5, "%d / 5★" % int(h["star"])]
		"bond10": return [int(h["bond"]), DB.MAX_BOND, "Bond %d / %d" % [int(h["bond"]), DB.MAX_BOND]]
		"awaken5": return [int(h.get("awaken", 0)), DB.MAX_AWAKEN, "A%d / A%d" % [int(h.get("awaken", 0)), DB.MAX_AWAKEN]]
	return [1, 1, "Recruited"]

func _codex_row(id: String) -> Control:
	var owned := Game.owns(id)
	var ready := _codex_ready(id)
	var rc: Color = DB.RARITY_COLOR[DB.rarity_of(id)]
	var row := UI.styled_panel(Color(1, 0.8, 0.3, 0.1) if ready > 0 else Color(0.06, 0.04, 0.1, 0.75), Color(UI.GOLD, 0.7) if ready > 0 else Color(1, 1, 1, 0.08), 12, 1, 6)
	var h := UI.hbox(10)
	row.add_child(h)
	var fp := UI.styled_panel(Color.BLACK, rc, 8, 2, 1)
	fp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fc := UI.tex_rect(DB.face(id), Vector2(46, 46), true)
	if not owned:
		fc.modulate = Color(0.32, 0.3, 0.38)
	fp.add_child(fc)
	h.add_child(fp)
	var nv := UI.vbox(0)
	nv.custom_minimum_size = Vector2(150, 0)
	nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(nv)
	nv.add_child(UI.label(DB.name_of(id), 16, Color.WHITE if owned else UI.MUTED, 2))
	var tags := UI.hbox(6)
	nv.add_child(tags)
	tags.add_child(UI.label(DB.rarity_of(id), 11, rc, 2))
	tags.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(id), "elem_light")), Vector2(16, 16)))
	if not owned:
		tags.add_child(UI.label("not recruited", 11, UI.MUTED, 1))
	for st in DB.CODEX_STEPS:
		h.add_child(_codex_chip(id, st))
	return row

func _codex_chip(id: String, st: Dictionary) -> Control:
	var sid: String = st["id"]
	var claimed := Game.codex_claimed(id, sid)
	var reached := Game.codex_reached(id, sid)
	var p: Array = _codex_prog(id, sid)
	var col: Color = UI.GREEN if claimed else (UI.GOLD if reached else Color(1, 1, 1, 0.3))
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = "%s — %s" % [st["name"], ", ".join(Array(st["give"].keys()).map(func(k): return "%s x%d" % [Game.reward_name(k), int(st["give"][k])]))]
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", UI.style(Color(col, 0.16 if reached and not claimed else 0.06), Color(col, 0.8 if reached else 0.25), 10, 2 if reached and not claimed else 1, 0))
	b.add_child(bg)
	var m := UI.margin(UI.vbox(2), 8, 4, 8, 4)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	var cv: VBoxContainer = m.get_child(0)
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	var t1 := UI.label(("✓ " + str(st["name"])) if claimed else (str(st["name"]) if not reached else "CLAIM ▸"), 13, col.lightened(0.15) if reached else UI.MUTED, 2)
	t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(t1)
	if not claimed and not reached:
		var pb := UI.bar(float(p[0]), float(p[1]), "", 6)
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(pb)
	var t2 := UI.label(str(p[2]) if not reached or claimed else str(st["name"]), 11, UI.MUTED if not reached else Color(col, 0.85), 1)
	t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(t2)
	if reached and not claimed:
		var tw := b.create_tween().set_loops()
		tw.tween_property(bg, "modulate:a", 0.55, 0.7)
		tw.tween_property(bg, "modulate:a", 1.0, 0.7)
		b.pressed.connect(func():
			var r := Game.claim_codex(id, sid)
			if not r.is_empty():
				Game.sfx("ui_click")
				main.show_rewards("CODEX REWARD", r, func(): _render_codex(); _rebuild()))
	return b

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
