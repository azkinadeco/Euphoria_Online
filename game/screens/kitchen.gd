extends Screen
## Kitchen: cook ingredients into gift dishes or team meals (battle buffs).

var _left: VBoxContainer
var _list: VBoxContainer

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
	rv.add_child(UI.label("RECIPES", 15, UI.GOLD, 3))
	_list = UI.vbox(8)
	var ls := UI.scroll(_list)
	ls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(ls)
	_render()
	tutorial("kitchen")

func _render() -> void:
	_render_left()
	_render_recipes()
	_update_chips()

func _render_left() -> void:
	for c in _left.get_children():
		c.queue_free()
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lv := Game.kitchen_level()
	_left.add_child(UI.label("KITCHEN Lv.%d" % lv, 20, UI.GOLD, 3))
	var nxt := Game.kitchen_next()
	if nxt > 0:
		var cooked := int(Game.s["kitchen"]["cooked"])
		var goal := int(DB.KITCHEN_LV[lv])
		_left.add_child(UI.bar(cooked, goal, "", 10))
		_left.add_child(UI.label("Cook %d more dish%s for Lv.%d" % [nxt, "" if nxt == 1 else "es", lv + 1], 13, UI.MUTED))
	else:
		_left.add_child(UI.label("Master Chef! All recipes learned.", 13, UI.GREEN))

	# active meal
	var mp := UI.styled_panel(Color("#2a1f30"), Color("#ffb070"), 12, 1, 10.0)
	_left.add_child(mp)
	var mv := UI.vbox(4)
	mp.add_child(mv)
	mv.add_child(UI.label("TODAY'S MEAL", 13, Color("#ffb070"), 2))
	var m := Game.active_meal()
	if m.is_empty():
		mv.add_child(UI.wrap_label("No meal. Cook a meal and SERVE it to buff your team in battle (Arena excluded).", 13, UI.MUTED))
	else:
		var mh := UI.hbox(8)
		mh.add_child(UI.tex_rect(DB.icon(DB.ITEMS[m["id"]]["icon"]), Vector2(40, 40)))
		var mt := UI.vbox(0)
		mt.add_child(UI.label(DB.ITEMS[m["id"]]["name"], 15, Color.WHITE, 2))
		mt.add_child(UI.label(Game.meal_text(m["bonus"]), 13, UI.GREEN))
		mt.add_child(UI.label("%d battle%s left" % [m["left"], "" if int(m["left"]) == 1 else "s"], 12, UI.MUTED))
		mh.add_child(mt)
		mv.add_child(mh)

	# market basket
	var ready := Game.basket_ready()
	var bb := UI.button("MARKET BASKET  (free)" if ready else "Basket claimed today", func():
		var r := Game.claim_basket()
		if r.is_empty():
			return
		Game.sfx("star_up")
		main.show_rewards("MARKET BASKET", r, _render), "GoldButton" if ready else "", Vector2(0, 46))
	bb.disabled = not ready
	if ready:
		UI.add_badge(bb, 1)
	_left.add_child(bb)

	_left.add_child(UI.label("PANTRY", 14, UI.GOLD, 2))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	_left.add_child(grid)
	for k in DB.INGREDIENTS:
		var row := UI.hbox(4)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(UI.tex_rect(DB.icon(DB.ITEMS[k]["icon"]), Vector2(34, 34)))
		row.add_child(UI.label("x%d" % Game.amount(k), 15, Color.WHITE, 2))
		row.tooltip_text = DB.ITEMS[k]["name"]
		grid.add_child(row)
	_left.add_child(UI.wrap_label("Ingredients drop from story, Hard and Event battles, Garden visits and Herb Gathering.", 12, UI.MUTED))

	# dishes on hand
	var owned: Array = []
	for r in DB.RECIPES:
		if Game.amount(r["id"]) > 0:
			owned.append(r["id"])
	if not owned.is_empty():
		_left.add_child(UI.label("DISHES", 14, UI.GOLD, 2))
		for id in owned:
			var did: String = id
			var row := UI.hbox(8)
			row.add_child(UI.tex_rect(DB.icon(DB.ITEMS[did]["icon"]), Vector2(34, 34)))
			var nl := UI.label("%s x%d" % [DB.ITEMS[did]["name"], Game.amount(did)], 13)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			nl.custom_minimum_size.x = 40
			row.add_child(nl)
			if DB.MEALS.has(did):
				row.add_child(UI.button("SERVE", func(): _serve(did), "", Vector2(80, 38)))
			else:
				row.add_child(UI.button("GIFT", func(): main.go("hero_detail", {"id": Game.s["lobby_hero"], "tab": "BOND", "list": Game.s["heroes"].keys()}), "", Vector2(80, 38)))
			_left.add_child(row)

func _render_recipes() -> void:
	for c in _list.get_children():
		c.queue_free()
	for r in DB.RECIPES:
		var id: String = r["id"]
		var it: Dictionary = DB.ITEMS[id]
		var unlocked := Game.recipe_unlocked(id)
		var p := UI.panel("CardPanel")
		_list.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		var ic := UI.tex_rect(DB.icon(it["icon"]), Vector2(72, 72))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not unlocked:
			ic.modulate = Color(0.4, 0.4, 0.45)
		h.add_child(ic)
		var v := UI.vbox(3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var tr := UI.hbox(8)
		tr.add_child(UI.label(it["name"], 18, Color.WHITE if unlocked else UI.MUTED, 2))
		var tag := "MEAL" if DB.MEALS.has(id) else "GIFT"
		var tl := UI.label(tag, 12, Color("#ffb070") if tag == "MEAL" else Color("#ff8fb8"), 2)
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.add_child(tl)
		v.add_child(tr)
		v.add_child(UI.label(str(it["desc"]), 13, UI.GREEN if unlocked else UI.MUTED))
		var need := UI.hbox(10)
		for k in r["need"].keys():
			var have := Game.amount(k)
			var want := int(r["need"][k])
			var nh := UI.hbox(2)
			nh.add_child(UI.tex_rect(DB.icon(DB.ITEMS[k]["icon"]), Vector2(26, 26)))
			nh.add_child(UI.label("%d/%d" % [have, want], 13, UI.TEXT if have >= want else UI.RED, 2))
			need.add_child(nh)
		var gh := UI.hbox(2)
		gh.add_child(UI.tex_rect(DB.icon("icon_gold"), Vector2(22, 22)))
		gh.add_child(UI.label(Game.fmt(int(r["gold"])), 13, UI.TEXT if Game.amount("gold") >= int(r["gold"]) else UI.RED, 2))
		need.add_child(gh)
		v.add_child(need)
		var bv := UI.vbox(6)
		bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bv)
		if not unlocked:
			bv.add_child(UI.label("Kitchen Lv.%d" % int(r.get("lv", 1)), 13, UI.MUTED, 2))
			continue
		var n := Game.can_cook(id)
		var cb := UI.button("COOK", func(): _cook(id, 1), "GoldButton", Vector2(110, 44))
		cb.disabled = n <= 0
		bv.add_child(cb)
		if n > 1:
			var many := mini(n, 5)
			bv.add_child(UI.button("COOK x%d" % many, func(): _cook(id, many), "", Vector2(110, 38)))
	UI.stagger(_list, 0.03)

func _cook(id: String, times: int) -> void:
	var err := Game.cook(id, times)
	if err != "":
		main.toast(err, UI.RED)
		return
	Game.sfx("star_up")
	main.toast("Cooked %s x%d!" % [DB.ITEMS[id]["name"], times], Color("#ffb070"))
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
