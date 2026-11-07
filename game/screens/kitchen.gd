extends Screen
## Kitchen: cook ingredients into gift dishes or team meals (battle buffs).

const MEAL_COL := Color("#ffb070")
const GIFT_COL := Color("#ff8fb8")
const RANKS := ["Apprentice", "Home Cook", "Chef", "Master Chef"]

var _left: VBoxContainer
var _list: VBoxContainer
var _ready_lbl: Label
var _tabs: HBoxContainer
var _filter := "ALL"
var _just_cooked := ""
var _cooked_n := 0

func build() -> void:
	set_bg("lobby", 0.65)
	ambient(Color(1.0, 0.9, 0.75), 16)
	header("KITCHEN", ["gold", "gems"])
	var b := body(76)

	var lp := UI.panel()
	lp.anchor_right = 0.34
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	_left = UI.vbox(10)
	lp.add_child(UI.scroll(_left))

	var rp := UI.panel()
	rp.anchor_left = 0.36
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	var top := UI.hbox(8)
	rv.add_child(top)
	var tl := UI.label("RECIPES", 15, UI.GOLD, 3)
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(tl)
	_ready_lbl = UI.label("", 13, UI.GREEN, 2)
	_ready_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ready_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_ready_lbl)
	_tabs = UI.hbox(6)
	top.add_child(_tabs)
	_list = UI.vbox(8)
	var ls := UI.scroll(_list)
	ls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(ls)
	_render()
	tutorial("kitchen")

func _render() -> void:
	_render_left()
	_render_tabs()
	_render_recipes()
	_update_chips()

# ------------------------------------------------------------------ left column

func _render_left() -> void:
	for c in _left.get_children():
		c.queue_free()
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.add_child(_level_card())
	_left.add_child(_meal_card())

	# market basket
	var ready := Game.basket_ready()
	var bb := UI.button("MARKET BASKET  (free)" if ready else "Basket claimed today", func():
		var r := Game.claim_basket()
		if r.is_empty():
			return
		Game.sfx("star_up")
		main.show_rewards("MARKET BASKET", r, _render), "GoldButton" if ready else "", Vector2(0, 46))
	bb.disabled = not ready
	bb.tooltip_text = "Free ingredients once a day. Bigger at higher Kitchen levels."
	if ready:
		UI.add_badge(bb, 1)
	_left.add_child(bb)

	var ph := UI.hbox(6)
	ph.add_child(UI.label("PANTRY", 14, UI.GOLD, 2))
	var hint := UI.label("tap to find more", 12, UI.MUTED)
	hint.size_flags_vertical = Control.SIZE_SHRINK_END
	ph.add_child(hint)
	_left.add_child(ph)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_left.add_child(grid)
	for k in DB.INGREDIENTS:
		grid.add_child(_pantry_tile(k))

	# dishes on hand
	var owned: Array = []
	for r in DB.RECIPES:
		if Game.amount(r["id"]) > 0:
			owned.append(r["id"])
	if not owned.is_empty():
		_left.add_child(UI.label("DISHES ON HAND", 14, UI.GOLD, 2))
		for id in owned:
			var did: String = id
			var is_meal := DB.MEALS.has(did)
			var dp := UI.styled_panel(Color(0.12, 0.09, 0.18, 0.85), (MEAL_COL if is_meal else GIFT_COL).darkened(0.35), 10, 1, 6.0)
			var row := UI.hbox(8)
			dp.add_child(row)
			row.add_child(UI.tex_rect(DB.icon(DB.ITEMS[did]["icon"]), Vector2(34, 34)))
			var nv := UI.vbox(0)
			nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var nl := UI.label(DB.ITEMS[did]["name"], 13, Color.WHITE, 2)
			nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			nl.custom_minimum_size.x = 40
			nv.add_child(nl)
			nv.add_child(UI.label("x%d" % Game.amount(did), 12, UI.MUTED))
			row.add_child(nv)
			if is_meal:
				row.add_child(UI.button("SERVE", func(): _serve(did), "GoldButton", Vector2(78, 36)))
			else:
				row.add_child(UI.button("GIFT", func(): main.go("hero_detail", {"id": Game.s["lobby_hero"], "tab": "BOND", "list": Game.s["heroes"].keys()}), "", Vector2(78, 36)))
			_left.add_child(dp)

## Level ring + rank + what the next level unlocks.
func _level_card() -> Control:
	var lv := Game.kitchen_level()
	var nxt := Game.kitchen_next()
	var cooked := int(Game.s["kitchen"]["cooked"])
	var lo := int(DB.KITCHEN_LV[lv - 1]) if lv >= 1 else 0
	var hi := int(DB.KITCHEN_LV[lv]) if nxt > 0 else lo
	var frac := 1.0 if nxt <= 0 else clampf(float(cooked - lo) / float(maxi(1, hi - lo)), 0.0, 1.0)

	var p := UI.styled_panel(Color(0.16, 0.11, 0.2, 0.9), Color(UI.GOLD, 0.45), 12, 1, 10.0)
	var h := UI.hbox(12)
	p.add_child(h)
	var ring := Control.new()
	ring.custom_minimum_size = Vector2(70, 70)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.draw.connect(func():
		var c := ring.size * 0.5
		var r := minf(c.x, c.y) - 4.0
		ring.draw_circle(c, r + 2.0, Color(0.08, 0.05, 0.12))
		ring.draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.1), 6.0, true)
		if frac > 0.0:
			ring.draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * frac, 48, MEAL_COL if nxt > 0 else UI.GOLD, 6.0, true)
		var f := ThemeDB.fallback_font
		ring.draw_string(f, c + Vector2(-30, -3), "Lv", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, UI.MUTED)
		ring.draw_string(f, c + Vector2(-30, 16), str(lv), HORIZONTAL_ALIGNMENT_CENTER, 60, 22, Color.WHITE))
	h.add_child(ring)

	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("KITCHEN", 12, UI.MUTED, 2))
	v.add_child(UI.label(RANKS[clampi(lv - 1, 0, RANKS.size() - 1)], 19, UI.GOLD, 3))
	if nxt > 0:
		v.add_child(UI.label("%d / %d dishes" % [cooked, hi], 12, UI.TEXT))
		var unlocks: Array = []
		for r in DB.RECIPES:
			if int(r.get("lv", 1)) == lv + 1:
				unlocks.append(DB.ITEMS[r["id"]]["name"])
		unlocks.append("bigger basket")
		var ul := UI.wrap_label("Lv.%d: %s" % [lv + 1, ", ".join(unlocks)], 12, MEAL_COL)
		v.add_child(ul)
	else:
		v.add_child(UI.wrap_label("All recipes learned. %d dishes cooked!" % cooked, 12, UI.GREEN))
	return p

func _meal_card() -> Control:
	var m := Game.active_meal()
	var on := not m.is_empty()
	var mp := UI.styled_panel(Color("#2a1f30") if on else Color(0.12, 0.09, 0.16, 0.8), MEAL_COL if on else Color(MEAL_COL, 0.35), 12, 2 if on else 1, 10.0)
	var mv := UI.vbox(4)
	mp.add_child(mv)
	var th := UI.hbox(6)
	th.add_child(UI.label("TODAY'S MEAL", 13, MEAL_COL, 2))
	if on:
		var act := UI.label("ACTIVE", 11, UI.GREEN, 2)
		act.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		th.add_child(act)
	mv.add_child(th)
	if not on:
		mv.add_child(UI.wrap_label("No meal served. Cook a MEAL dish and SERVE it to buff your whole team (Arena excluded).", 12, UI.MUTED))
		return mp
	var mh := UI.hbox(10)
	var ic := UI.tex_rect(DB.icon(DB.ITEMS[m["id"]]["icon"]), Vector2(46, 46))
	mh.add_child(ic)
	var mt := UI.vbox(2)
	mt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mt.add_child(UI.label(DB.ITEMS[m["id"]]["name"], 15, Color.WHITE, 2))
	mt.add_child(UI.label(Game.meal_text(m["bonus"]), 13, UI.GREEN, 2))
	# one pip per battle the meal lasts
	var total := int(DB.MEALS[m["id"]]["battles"])
	var left := int(m["left"])
	var pips := Control.new()
	pips.custom_minimum_size = Vector2(total * 16 + 70, 14)
	pips.draw.connect(func():
		for i in total:
			var c := Vector2(6 + i * 16, 7)
			if i < left:
				pips.draw_circle(c, 5.5, MEAL_COL)
			else:
				pips.draw_arc(c, 5.0, 0.0, TAU, 20, Color(1, 1, 1, 0.25), 1.5, true)
		pips.draw_string(ThemeDB.fallback_font, Vector2(total * 16 + 4, 12), "%d left" % left, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.MUTED))
	mt.add_child(pips)
	mh.add_child(mt)
	mv.add_child(mh)
	UI.breathe(ic, 0.05, 2.4)
	return mp

func _pantry_tile(k: String) -> Control:
	var have := Game.amount(k)
	var bt := Button.new()
	bt.custom_minimum_size = Vector2(0, 54)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var empty := have <= 0
	var sb := UI.style(Color(0.13, 0.1, 0.19, 0.9), Color(UI.RED, 0.45) if empty else Color(1, 1, 1, 0.12), 10, 1, 6.0)
	bt.add_theme_stylebox_override("normal", sb)
	var hv := sb.duplicate()
	hv.border_color = UI.GOLD
	bt.add_theme_stylebox_override("hover", hv)
	bt.add_theme_stylebox_override("pressed", hv)
	bt.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var h := UI.hbox(6)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 6
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bt.add_child(h)
	var ic := UI.tex_rect(DB.icon(DB.ITEMS[k]["icon"]), Vector2(38, 38))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if empty:
		ic.modulate = Color(0.6, 0.6, 0.65)
	h.add_child(ic)
	var v := UI.vbox(-2)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nl := UI.label(str(DB.ITEMS[k]["name"]), 11, UI.MUTED)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nl.custom_minimum_size.x = 50
	v.add_child(nl)
	var al := UI.label("x%d" % have, 16, UI.RED if empty else Color.WHITE, 2)
	al.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(al)
	h.add_child(v)
	var src := DB.item_sources(k)
	var tip := str(DB.ITEMS[k]["name"])
	for e in src:
		tip += "\n• " + str(e[0])
	bt.tooltip_text = tip
	bt.pressed.connect(func(): _find_more(k))
	UI.hover_fx(bt, 1.03)
	return bt

## Jump to the first unlocked place that drops this ingredient (other than the Kitchen itself).
func _find_more(k: String) -> void:
	for e in DB.item_sources(k):
		var scr: String = e[1]
		if scr == "kitchen":
			continue
		if Game.feature_unlocked(scr):
			main.go(scr, e[2])
			return
	if Game.basket_ready():
		main.toast("Claim the free Market Basket first!", MEAL_COL)
	else:
		main.toast("%s: %s" % [DB.ITEMS[k]["name"], ", ".join(DB.item_sources(k).map(func(e): return str(e[0])))], UI.MUTED)

# ------------------------------------------------------------------ recipes

func _render_tabs() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	for t in ["ALL", "MEALS", "GIFTS"]:
		var tn: String = t
		var on := _filter == tn
		var bt := UI.button(tn, func():
			_filter = tn
			_render_tabs()
			_render_recipes(), "GoldButton" if on else "", Vector2(76, 32))
		bt.add_theme_font_size_override("font_size", 12)
		_tabs.add_child(bt)

func _render_recipes() -> void:
	for c in _list.get_children():
		c.queue_free()
	var ready_n := 0
	for r in DB.RECIPES:
		if Game.can_cook(r["id"]) > 0:
			ready_n += 1
	_ready_lbl.text = "• %d ready to cook" % ready_n if ready_n > 0 else ""
	var pop_card: Control = null
	for r in DB.RECIPES:
		var id: String = r["id"]
		var is_meal := DB.MEALS.has(id)
		if (_filter == "MEALS" and not is_meal) or (_filter == "GIFTS" and is_meal):
			continue
		var card := _recipe_card(r)
		_list.add_child(card)
		if id == _just_cooked:
			pop_card = card
	if pop_card != null:
		_cook_fx(pop_card, _cooked_n)
		_just_cooked = ""
	else:
		UI.stagger(_list, 0.03)

func _recipe_card(r: Dictionary) -> Control:
	var id: String = r["id"]
	var it: Dictionary = DB.ITEMS[id]
	var unlocked := Game.recipe_unlocked(id)
	var is_meal := DB.MEALS.has(id)
	var col := MEAL_COL if is_meal else GIFT_COL
	var n := Game.can_cook(id)
	var ready := n > 0

	var border := UI.GREEN if ready else (Color(col, 0.4) if unlocked else Color(1, 1, 1, 0.1))
	var p := UI.styled_panel(Color(0.13, 0.1, 0.2, 0.92) if unlocked else Color(0.09, 0.08, 0.12, 0.85), Color(border, 0.75) if ready else border, 12, 2 if ready else 1, 10.0)
	var h := UI.hbox(12)
	p.add_child(h)

	# coloured accent stripe
	var stripe := ColorRect.new()
	stripe.color = col if unlocked else Color(1, 1, 1, 0.12)
	stripe.custom_minimum_size = Vector2(4, 0)
	h.add_child(stripe)

	# dish icon on a soft glow plate
	var plate := Control.new()
	plate.custom_minimum_size = Vector2(78, 78)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.draw.connect(func():
		var c := plate.size * 0.5
		for i in 4:
			plate.draw_circle(c, 39.0 - i * 5.0, Color(col, (0.05 + i * 0.03) if unlocked else 0.03)))
	var ic := UI.tex_rect(DB.icon(it["icon"]), Vector2(70, 70))
	ic.position = Vector2(4, 4)
	if not unlocked:
		ic.modulate = Color(0.35, 0.35, 0.4)
	plate.add_child(ic)
	if not unlocked:
		var lk := UI.label("LOCKED", 11, Color.WHITE, 3)
		lk.position = Vector2(0, 30)
		lk.size = Vector2(78, 18)
		lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plate.add_child(lk)
	h.add_child(plate)
	p.set_meta("plate", plate)

	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	var tr := UI.hbox(8)
	var name_l := UI.label(it["name"], 18, Color.WHITE if unlocked else UI.MUTED, 2)
	tr.add_child(name_l)
	var tag := UI.styled_panel(Color(col, 0.18), Color(col, 0.7), 8, 1, 5.0)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_child(UI.label("MEAL" if is_meal else "GIFT", 10, col, 1))
	tr.add_child(tag)
	if is_meal:
		var dur := UI.label("%d battles" % int(DB.MEALS[id]["battles"]), 11, UI.MUTED)
		dur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.add_child(dur)
	v.add_child(tr)
	v.add_child(UI.label(str(it["desc"]), 13, UI.GREEN if unlocked else UI.MUTED))

	var need := UI.hbox(6)
	for k in r["need"].keys():
		need.add_child(_need_chip(DB.icon(DB.ITEMS[k]["icon"]), Game.amount(k), int(r["need"][k]), str(DB.ITEMS[k]["name"]), unlocked))
	need.add_child(_need_chip(DB.icon("icon_gold"), Game.amount("gold"), int(r["gold"]), "Gold", unlocked, true))
	v.add_child(need)

	var bv := UI.vbox(6)
	bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bv.custom_minimum_size.x = 116
	h.add_child(bv)
	if not unlocked:
		var need_lv := int(r.get("lv", 1))
		var gl := UI.label("Kitchen Lv.%d" % need_lv, 14, UI.GOLD, 2)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(gl)
		var more := int(DB.KITCHEN_LV[need_lv - 1]) - int(Game.s["kitchen"]["cooked"])
		var ml := UI.label("%d more dishes" % maxi(0, more), 12, UI.MUTED)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(ml)
		return p
	if ready:
		var rl := UI.label("READY x%d" % n, 12, UI.GREEN, 2)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(rl)
	var cb := UI.button("COOK", func(): _cook(id, 1), "GoldButton", Vector2(116, 44))
	cb.disabled = not ready
	if not ready:
		cb.tooltip_text = "Missing ingredients or Gold."
	bv.add_child(cb)
	if n > 1:
		var many := mini(n, 5)
		bv.add_child(UI.button("COOK x%d" % many, func(): _cook(id, many), "", Vector2(116, 36)))
	if ready:
		var tw := p.create_tween().set_loops()
		tw.tween_property(p, "self_modulate", Color(1.12, 1.12, 1.05), 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(p, "self_modulate", Color.WHITE, 1.0).set_trans(Tween.TRANS_SINE)
	return p

## "have/want" chip: green tick when enough, red when short.
func _need_chip(tex: Texture2D, have: int, want: int, nm: String, unlocked: bool, money: bool = false) -> Control:
	var ok := have >= want
	var c: Color = UI.GREEN if ok else UI.RED
	if not unlocked:
		c = UI.MUTED
	var chip := UI.styled_panel(Color(0, 0, 0, 0.3), Color(c, 0.35), 8, 1, 5.0)
	var hh := UI.hbox(3)
	chip.add_child(hh)
	hh.add_child(UI.tex_rect(tex, Vector2(22, 22)))
	var txt := Game.fmt(want) if money else "%d/%d" % [mini(have, 999), want]
	var l := UI.label(txt, 12, c if not ok or not unlocked else UI.TEXT, 2)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hh.add_child(l)
	if ok and unlocked:
		var t := UI.label("✓", 12, UI.GREEN, 1)
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hh.add_child(t)
	chip.tooltip_text = "%s: have %s, need %s" % [nm, Game.fmt(have), Game.fmt(want)]
	return chip

## Pop the freshly cooked card and float a "+N" over it.
func _cook_fx(card: Control, n: int) -> void:
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	UI.pop(card, 0.35)
	var plate: Control = card.get_meta("plate")
	var fl := UI.label("+%d" % n, 26, MEAL_COL, 4)
	fl.z_index = 5
	fl.position = Vector2(46, 22)
	plate.add_child(fl)
	var tw := fl.create_tween().set_parallel(true)
	tw.tween_property(fl, "position:y", fl.position.y - 40, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(fl, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(fl.queue_free)

func _cook(id: String, times: int) -> void:
	var err := Game.cook(id, times)
	if err != "":
		main.toast(err, UI.RED)
		return
	Game.sfx("star_up")
	main.toast("Cooked %s x%d!" % [DB.ITEMS[id]["name"], times], MEAL_COL)
	_just_cooked = id
	_cooked_n = times
	_render()

func _serve(id: String) -> void:
	var replacing := not Game.active_meal().is_empty()
	var err := Game.serve_meal(id)
	if err != "":
		main.toast(err, UI.RED)
		return
	Game.sfx("buff")
	var m := Game.active_meal()
	main.toast("%s%s served: %s for %d battles" % ["New meal! " if replacing else "", DB.ITEMS[id]["name"], Game.meal_text(m["bonus"]), int(m["left"])], UI.GREEN)
	_render()
