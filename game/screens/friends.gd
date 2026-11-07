extends Screen
## Friends: send hearts for Friend Points, browse friends' support heroes.

func build() -> void:
	set_bg("forest", 0.6)
	var bar := header("FRIENDS", ["friend_point"])
	var sent: bool = bool(Game.s["friends"]["hearts_sent"])
	var hb := UI.button("HEARTS SENT ✔" if sent else "♥ SEND HEARTS TO ALL", func():
		var fp := Game.send_hearts()
		if fp > 0:
			Game.sfx("star_up")
			main.show_rewards("HEARTS SENT", {"friend_point": fp}, func(): main.replace("friends")), "GoldButton", Vector2(240, 46))
	hb.disabled = sent
	bar.add_child(hb)
	bar.add_child(UI.button("FRIEND SHOP", func(): main.go("shop", {"tab": "friend_point"}), "", Vector2(160, 46)))

	var b := body(76)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	v.add_child(UI.label("AI FRIENDS • Real friends arrive with online mode.", 14, Color("#9fd0ff"), 2))
	v.add_child(UI.wrap_label("Friends lend you a support hero in Story, Event and Tower battles (tap + FRIEND SUPPORT in Battle Prep). Each friend can help once per day; you earn 20 Friend Points every time.", 14, UI.MUTED))
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var sc := UI.scroll(grid)
	v.add_child(sc)
	sc.resized.connect(func(): grid.columns = maxi(2, int(sc.size.x / 300.0)))
	for f in Game.friends():
		var p := UI.panel("CardPanel")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		h.add_child(HeroCard.new(f["hero"], Vector2(96, 124), {"owned": true, "show_level": false}))
		var fv := UI.vbox(2)
		fv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(fv)
		fv.add_child(UI.label(f["name"], 19, Color.WHITE, 2))
		fv.add_child(UI.label("Player Lv.%d" % f["player_level"], 13, UI.MUTED))
		fv.add_child(UI.label("Support: %s" % DB.name_of(f["hero"]), 14, UI.GOLD))
		fv.add_child(UI.label("Lv.%d  %s" % [f["level"], "★".repeat(f["star"])], 14, UI.GOLD, 2))
		fv.add_child(UI.label("Used today" if f["used"] else "Available", 13, UI.MUTED if f["used"] else UI.GREEN))
	UI.stagger(grid, 0.04)
