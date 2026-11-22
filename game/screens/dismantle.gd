extends Screen
## Dismantle: turn duplicate hero cards (Game.copies) into Evo Crystals + Gold, and manage the hero inventory
## size. Tap a card to pick one more copy (tapping past the last copy clears it). Quick picks never take UR+
## cards; dismantling UR+ asks first. params: {"id": hero} preselects that hero's duplicates.

var _pick := {}            # hero id -> copies picked
var _grid: HFlowContainer
var _side: VBoxContainer

func build() -> void:
	set_bg("hell", 0.62)
	ambient(Color(0.85, 0.7, 1.0), 18)
	header("DISMANTLE", ["gold", "star_stone"])
	tutorial("dismantle")
	if params.has("id") and Game.copies(str(params["id"])) > 0:
		_pick[str(params["id"])] = Game.copies(str(params["id"]))
	var b := body(76)
	var lp := UI.panel()
	lp.anchor_right = 0.63
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var sc := DragScroll.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(sc)
	_grid = HFlowContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(_grid)
	var rp := UI.panel()
	rp.anchor_left = 0.645
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rsc := DragScroll.new()
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rp.add_child(rsc)
	_side = UI.vbox(10)
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(_side)
	_render()

func refresh() -> void:
	super.refresh()

func _ids() -> Array:
	var ids: Array = Game.s["copies"].keys().filter(func(k): return Game.copies(str(k)) > 0)
	ids.sort_custom(func(a, b):
		var ra := DB.rarity_rank(DB.rarity_of(str(a)))
		var rb := DB.rarity_rank(DB.rarity_of(str(b)))
		return ra < rb if ra != rb else str(a) < str(b))
	return ids

func _render() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for c in _side.get_children():
		c.queue_free()
	var ids := _ids()
	if ids.is_empty():
		var em := UI.vbox(10)
		em.custom_minimum_size = Vector2(520, 0)
		em.add_child(UI.tex_rect(DB.icon("icon_gacha"), Vector2(0, 90)))
		em.add_child(UI.label("NO DUPLICATE CARDS", 20, UI.GOLD, 3))
		em.add_child(UI.wrap_label("Summoning a hero you already have puts a duplicate card in your hero inventory. Use cards to Star Up and Evolve heroes, or dismantle them here into Evo Crystals.", 14, UI.MUTED))
		_grid.add_child(em)
	for id in ids:
		_grid.add_child(_card(str(id)))
	_side_panel()

func _card(id: String) -> Control:
	var have := Game.copies(id)
	var picked := int(_pick.get(id, 0))
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(118, 178)
	var card := HeroCard.new(id, Vector2(118, 150), {"copy": true, "lazy": true, "show_level": false})
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(card)
	var cnt := UI.label("x%d" % have, 16, Color.WHITE, 4)
	cnt.position = Vector2(8, 6)
	b.add_child(cnt)
	var sel := UI.label("PICKED %d / %d" % [picked, have] if picked > 0 else "tap to pick", 13, UI.GOLD if picked > 0 else UI.MUTED, 3)
	sel.position = Vector2(0, 154)
	sel.size = Vector2(118, 20)
	sel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(sel)
	if picked > 0:
		card.set_selected(true)
	b.pressed.connect(func():
		var n := int(_pick.get(id, 0)) + 1
		if n > Game.copies(id):
			_pick.erase(id)
		else:
			_pick[id] = n
		Game.sfx("ui_click")
		_render())
	return b

func _side_panel() -> void:
	var cap := UI.hbox(8)
	cap.add_child(UI.label("HERO INVENTORY", 16, UI.GOLD, 3))
	_side.add_child(cap)
	_side.add_child(UI.label("%d / %d cards  (heroes %d + duplicates %d)" % [Game.hero_cards(), Game.hero_slots(), Game.s["heroes"].size(), Game.total_copies()], 14, Color.WHITE))
	var bar := UI.bar(Game.hero_cards(), Game.hero_slots(), "GoldBar", 10)
	_side.add_child(bar)
	var ex := UI.button("+%d SLOTS  (%d Gems)" % [DB.HERO_SLOTS_STEP, DB.HERO_SLOTS_PRICE] if Game.hero_slots() < DB.HERO_SLOTS_MAX else "MAX SIZE", func():
		var err := Game.expand_hero_slots()
		main.toast(err if err != "" else "Hero inventory: %d slots" % Game.hero_slots(), UI.RED if err != "" else UI.GREEN)
		_render(), "", Vector2(0, 42))
	ex.disabled = Game.hero_slots() >= DB.HERO_SLOTS_MAX
	_side.add_child(ex)
	_side.add_child(UI.label("QUICK PICK", 15, UI.GOLD, 3))
	var qa := UI.hbox(8)
	for q in [["N & R", ["N", "R"]], ["SR", ["SR"]], ["SSR", ["SSR"]]]:
		var rar: Array = q[1]
		var qb := UI.button(str(q[0]), func():
			var plan := Game.dismantle_plan(rar)
			for k in plan.keys():
				_pick[k] = plan[k]
			if plan.is_empty():
				main.toast("No %s duplicates." % str(q[0]), UI.MUTED)
			_render(), "", Vector2(0, 40))
		qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		qa.add_child(qb)
	_side.add_child(qa)
	_side.add_child(UI.wrap_label("Quick picks never take UR or rarer cards — tap those yourself.", 12, UI.MUTED))
	# reward preview
	var n := 0
	var crystals := 0
	var gold := 0
	var rare := false
	for id in _pick.keys():
		var k := int(_pick[id])
		n += k
		crystals += DB.dismantle_crystals(DB.rarity_of(str(id))) * k
		gold += 1000 * (DB.rarity_rank(DB.rarity_of(str(id))) + 1) * k
		if DB.rarity_rank(DB.rarity_of(str(id))) >= DB.rarity_rank("UR"):
			rare = true
	var rv := UI.styled_panel(Color(0.1, 0.05, 0.18, 0.85), Color("#d8b4ff", 0.5), 10, 1, 10)
	var rvv := UI.vbox(6)
	rv.add_child(rvv)
	rvv.add_child(UI.label("%d card(s) picked" % n, 16, Color.WHITE, 2))
	var rr := UI.hbox(10)
	rr.add_child(UI.tex_rect(DB.icon("item_star_stone"), Vector2(30, 30)))
	rr.add_child(UI.label("+%s Evo Crystals" % Game.fmt(crystals), 16, Color("#9fd0ff"), 2))
	rvv.add_child(rr)
	var gr := UI.hbox(10)
	gr.add_child(UI.tex_rect(DB.icon("icon_gold"), Vector2(30, 30)))
	gr.add_child(UI.label("+%s Gold" % Game.fmt(gold), 16, UI.GOLD, 2))
	rvv.add_child(gr)
	_side.add_child(rv)
	var row := UI.hbox(8)
	var go := UI.button("DISMANTLE", func():
		if rare:
			main.confirm("Dismantle UR-or-rarer duplicate cards? They are hard to get and also raise that hero's stars.", _do, "DISMANTLE")
		else:
			_do(), "GoldButton", Vector2(0, 48))
	go.disabled = n == 0
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(go)
	var cl := UI.button("CLEAR", func(): _pick.clear(); _render(), "", Vector2(110, 48))
	cl.disabled = n == 0
	row.add_child(cl)
	_side.add_child(row)

func _do() -> void:
	var r := Game.dismantle_many(_pick)
	_pick.clear()
	if r.is_empty():
		return
	Game.sfx("awakening")
	main.show_rewards("DISMANTLED", r)
	_render()
