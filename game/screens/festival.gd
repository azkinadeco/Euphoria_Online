extends Screen
## Seasonal Festival: changes automatically with the calendar month. Featured heroes,
## a one-time greeting scene, a free daily wish and the Lantern Charm exchange.

var _charm_l: Label

func build() -> void:
	var f := Game.festival()
	if f.is_empty():
		set_bg("lobby", 0.5)
		header("FESTIVAL", ["gold", "gems"])
		var l := UI.label("No festival right now. Check back soon!", 22, UI.MUTED, 3)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		add_child(l)
		return
	var col := Color(str(f["color"]))
	set_bg(str(f["bg"]), 0.45)
	var fx := FestivalFX.new(str(f["fx"]), col, 46)
	add_child(fx)
	move_child(fx, mini(2, get_child_count() - 1))
	header("FESTIVAL", ["gold", "gems"])
	var b := body(76)

	# ---------------------------------------------------------------- left: featured heroes
	var left := Control.new()
	left.anchor_right = 0.56
	left.anchor_bottom = 1.0
	b.add_child(left)
	var feat: Array = f["featured"]
	for i in feat.size():
		var art := UI.tex_rect(DB.art(feat[i], int(Game.hero(feat[i]).get("skin", 0)) if Game.owns(feat[i]) else 0))
		art.anchor_left = 0.0 if i == 0 else 0.42
		art.anchor_right = 0.58 if i == 0 else 1.0
		art.anchor_bottom = 1.0
		art.offset_top = 40
		art.offset_bottom = -150
		UI.live(art, col.lightened(0.3))
		left.add_child(art)
		UI.fade_in(art, 0.6 + i * 0.2, Vector2(-40 if i == 0 else 40, 0))
	var top := UI.vbox(0)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	left.add_child(top)
	top.add_child(UI.label("SEASONAL FESTIVAL", 14, col.lightened(0.2), 3))
	top.add_child(UI.label(str(f["name"]), 32, Color.WHITE, 6))
	var secs := Game.festival_ends_in()
	top.add_child(UI.label("Ends in %dd %dh  •  A new festival every month" % [secs / 86400, (secs / 3600) % 24], 13, UI.MUTED, 3))

	var bot := UI.vbox(8)
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top = -144
	left.add_child(bot)
	var names := "%s & %s" % [DB.name_of(feat[0]).split(" ")[0], DB.name_of(feat[1]).split(" ")[0]]
	bot.add_child(UI.wrap_label("Win battles (Story, Hard, Event, Dungeon, Tower) to earn Lantern Charms — +5 extra for each of %s in your team." % names, 14, Color.WHITE))
	var st: Dictionary = Game._fest_state()
	_charm_l = UI.label("", 15, UI.GOLD, 3)
	bot.add_child(_charm_l)
	_update_charms()
	var row := UI.hbox(10)
	bot.add_child(row)
	var greeted: bool = st["greeted"]
	var gb := UI.button("♥ FESTIVAL SCENE" + ("" if greeted else "  (+Bond)"), _greet, "" if greeted else "GoldButton", Vector2(0, 50))
	gb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gb)
	var wb := UI.button("✦ DAILY WISH" if Game.fest_can_wish() else "WISH MADE TODAY", _wish, "GoldButton" if Game.fest_can_wish() else "", Vector2(0, 50))
	wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wb.disabled = not Game.fest_can_wish()
	row.add_child(wb)
	if not wb.disabled:
		var pt := wb.create_tween().set_loops()
		pt.tween_property(wb, "modulate", Color(1.25, 1.2, 1.1), 0.6)
		pt.tween_property(wb, "modulate", Color.WHITE, 0.6)

	# ---------------------------------------------------------------- right: exchange
	var rp := UI.panel()
	rp.anchor_left = 0.58
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	var hh := UI.hbox(8)
	hh.add_child(UI.tex_rect(DB.icon("item_season_token"), Vector2(30, 30)))
	hh.add_child(UI.label("FESTIVAL EXCHANGE", 18, UI.GOLD, 3))
	rv.add_child(hh)
	var list := UI.vbox(8)
	rv.add_child(UI.scroll(list))
	for it in DB.FEST_SHOP:
		var item: Dictionary = it
		var give := Game.fest_item_give(item)
		var left_n: int = int(item["limit"]) - Game.fest_bought(item["id"])
		var p := UI.panel("CardPanel")
		list.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		h.add_child(UI.reward_row(give, 40, 13))
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := str(item["name"])
		if nm.begins_with("Featured"):
			nm = "%s Shard x10" % DB.name_of(str(give.keys()[0]).substr(6)).split(" ")[0]
		info.add_child(UI.label(nm, 15, Color.WHITE, 2))
		info.add_child(UI.label("%d left" % left_n, 12, UI.MUTED))
		h.add_child(info)
		var bb := UI.button("%d ✦" % int(item["price"]), func():
			var err := Game.buy_fest(item)
			if err != "":
				main.toast(err, UI.RED)
				return
			Game.sfx("ui_click")
			main.show_rewards("EXCHANGED", give)
			main.replace("festival"), "GoldButton", Vector2(110, 44))
		bb.disabled = left_n <= 0
		h.add_child(bb)
	UI.stagger(list, 0.03)
	tutorial("festival")

func _update_charms() -> void:
	var st: Dictionary = Game._fest_state()
	_charm_l.text = "Lantern Charms: %s   •   Earned today %d / %d" % [Game.fmt(Game.amount("season_token")), int(st["today"]), DB.FEST_DAILY_CAP]

func _greet() -> void:
	var f := Game.festival()
	var lines: Array = (f["lines"] as Array).duplicate()
	lines.append(["nar", "— %s —" % f["name"]])
	main.dialogue(lines, func():
		if Game.fest_greet():
			main.toast("+60 Bond with %s & %s" % [DB.name_of(f["featured"][0]).split(" ")[0], DB.name_of(f["featured"][1]).split(" ")[0]], Color("#ff8fb8"))
			main.replace("festival"), str(f["bg"]))

func _wish() -> void:
	var r := Game.fest_wish()
	if r.is_empty():
		return
	Game.sfx("ui_click")
	var f := Game.festival()
	var hid: String = f["featured"][randi() % 2]
	main.show_rewards("%s granted your wish!" % DB.name_of(hid).split(" ")[0], r, func(): main.replace("festival"))
