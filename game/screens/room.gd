extends Screen
## Private Room: invite a hero to a personal space. Talk (5 visits/day), give gifts,
## rest together (+Energy, once per room per day). Rooms unlock by highest Bond.

var _loc := "gameroom"
var _art: TextureRect

func build() -> void:
	_loc = str(params.get("loc", Game._room()["loc"]))
	if not Game.room_unlocked(DB.room_def(_loc)):
		_loc = "gameroom"
	Game.s["room"]["loc"] = _loc
	set_bg(_loc, 0.05)
	if _loc in ["onsen", "shower"]:
		var steam := FestivalFX.new("snow", Color(1, 1, 1), 26)
		steam.modulate.a = 0.35
		add_child(steam)
	header("PRIVATE ROOM", ["gems", "energy"])
	var hid := Game.room_hero()
	var b := body(76)

	# ---------------------------------------------------------------- the hero
	_art = UI.tex_rect(DB.art(hid, int(Game.hero(hid).get("skin", 0))))
	_art.anchor_left = 0.2
	_art.anchor_right = 0.62
	_art.anchor_bottom = 1.0
	_art.offset_top = 10
	_art.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UI.live(_art, DB.theme_color(hid).lightened(0.5))
	b.add_child(_art)
	_art.resized.connect(func(): _art.pivot_offset = Vector2(_art.size.x * 0.5, _art.size.y))
	UI.fade_in(_art, 0.5, Vector2(0, 30))
	_art.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var line := Game.tap_hero(hid)
			if line != "":
				main.toast("%s: \"%s\"" % [DB.name_of(hid).split(" ")[0], line], Color("#ff8fb8"))
			var tw := _art.create_tween()
			tw.tween_property(_art, "scale", Vector2(1.03, 0.97), 0.08)
			tw.tween_property(_art, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK))

	# ---------------------------------------------------------------- rooms (left)
	var lv := UI.vbox(6)
	lv.anchor_right = 0.18
	lv.anchor_bottom = 1.0
	b.add_child(lv)
	for rd in DB.ROOMS:
		var key: String = rd["key"]
		var open := Game.room_unlocked(rd)
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 92)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color.BLACK, UI.GOLD if key == _loc else Color("#4a3a6e"), 10, 3 if key == _loc else 1, 0))
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(fr)
		var th := UI.tex_rect(DB.bg(key), Vector2.ZERO, true)
		th.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		th.modulate = Color.WHITE if open else Color(0.25, 0.25, 0.3)
		fr.add_child(th)
		var nm := UI.label(("♥ " if DB.fav_room(hid) == key else "") + (str(rd["name"]) if open else "Bond %d" % int(rd["bond"])), 13, Color.WHITE if open else UI.MUTED, 4)
		nm.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		nm.offset_top = -24
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fr.add_child(nm)
		btn.pressed.connect(func():
			if not open:
				main.toast("Reach Bond %d with any hero to unlock this room." % int(rd["bond"]), UI.MUTED)
				return
			Game.sfx("ui_click")
			main.replace("room", {"loc": key}))
		lv.add_child(btn)

	# ---------------------------------------------------------------- actions (right)
	var rp := UI.panel()
	rp.anchor_left = 0.64
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var v := UI.vbox(8)
	rp.add_child(UI.scroll(v))
	var rd2 := DB.room_def(_loc)
	v.add_child(UI.label(str(rd2["name"]).to_upper(), 13, Color("#ffb8d6"), 3))
	var h := Game.hero(hid)
	var fav := DB.fav_room(hid) == _loc
	v.add_child(_bond_card(hid, h))
	v.add_child(UI.label("♥ Her favourite room — Bond x2!" if fav else "Favourite room: " + str(DB.room_def(DB.fav_room(hid))["name"]), 13, Color("#ff8fb8") if fav else UI.MUTED, 2))
	var left := Game.room_visits_left()
	var maxb := int(h["bond"]) >= DB.MAX_BOND
	var talk_gain := 0 if maxb else (30 if fav else 15)
	var tb := UI.button(("♥ TALK  (%d / %d)" % [left, DB.ROOM_VISITS]) + ("   +%d ♥" % talk_gain if talk_gain > 0 else ""), func():
		var lines := Game.room_talk(_loc)
		if lines.is_empty():
			main.toast("No visits left today.", UI.MUTED)
			return
		main.dialogue(lines, func(): main.replace("room", {"loc": _loc, "gain": talk_gain}), _loc), "GoldButton", Vector2(0, 52))
	tb.disabled = left <= 0
	v.add_child(tb)
	var rested: bool = (Game._room()["rested"] as Array).has(_loc)
	var rest_gain := 0 if maxb else (60 if fav else 30)
	var rb := UI.button(("REST TOGETHER  +20 ⚡" + ("  +%d ♥" % rest_gain if rest_gain > 0 else "")) if not rested else "RESTED HERE TODAY", func():
		var r := Game.room_rest(_loc)
		if r.is_empty():
			return
		Game.sfx("star_up")
		main.show_rewards("A QUIET MOMENT", r, func(): main.replace("room", {"loc": _loc, "gain": rest_gain})), "" , Vector2(0, 46))
	rb.disabled = rested
	v.add_child(rb)
	v.add_child(UI.label("GIFTS", 14, UI.GOLD, 3))
	var gf := GridContainer.new()
	gf.columns = 3
	gf.add_theme_constant_override("h_separation", 6)
	gf.add_theme_constant_override("v_separation", 6)
	v.add_child(gf)
	for gid in DB.GIFTS + DB.DISH_GIFTS:
		gf.add_child(_gift_tile(hid, gid))
	var row := UI.hbox(8)
	v.add_child(row)
	var ch := UI.button("CHANGE HERO", _pick_hero, "", Vector2(0, 42))
	ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ch)
	var sl := UI.button("SET AS LOBBY", func():
		Game.s["lobby_bg"] = _loc
		Game.mark_dirty()
		main.toast("Lobby scene set to " + str(rd2["name"]), UI.GOLD), "", Vector2(0, 42))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sl)

	tutorial("room")
	if int(params.get("gain", 0)) > 0:
		_float_hearts(int(params["gain"]))
	params.erase("gain")

const PINK := Color("#ff8fb8")

## Bond Journey: face + level, EXP numbers, 10 heart pips (milestones marked) and what the next level unlocks.
func _bond_card(hid: String, h: Dictionary) -> Control:
	var lv := int(h["bond"])
	var maxed := lv >= DB.MAX_BOND
	var card := UI.styled_panel(Color(0.16, 0.06, 0.14, 0.75), Color(PINK, 0.45), 12, 1, 8)
	var v := UI.vbox(6)
	card.add_child(v)
	var hrow := UI.hbox(8)
	v.add_child(hrow)
	var fp := UI.styled_panel(Color.BLACK, PINK, 22, 2, 0)
	fp.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	fp.add_child(UI.face_rect(hid, Vector2(44, 44), int(h.get("skin", 0))))
	hrow.add_child(fp)
	var hv := UI.vbox(0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(hv)
	hv.add_child(UI.label(DB.name_of(hid), 19, Color.WHITE, 4))
	var need := DB.bond_to_next(lv)
	var sub := "♥ Bond Lv.%d" % lv + ("  •  MAX" if maxed else "   %d / %d" % [int(h["bond_exp"]), need])
	hv.add_child(UI.label(sub, 13, PINK, 3))
	if bool(h.get("oath", false)):
		hrow.add_child(UI.label("💍", 20, UI.GOLD, 0))
	var bar := UI.bar(need if maxed else int(h["bond_exp"]), need, "", 8)
	bar.add_theme_stylebox_override("fill", UI.style(PINK, Color.TRANSPARENT, 4, 0, 0))
	bar.add_theme_stylebox_override("background", UI.style(Color(1, 1, 1, 0.08), Color.TRANSPARENT, 4, 0, 0))
	v.add_child(bar)
	# heart track: one pip per level; milestone levels get a gold ring and a tooltip
	var track := UI.hbox(2)
	track.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(track)
	for i in range(1, DB.MAX_BOND + 1):
		var un := DB.bond_unlocks(hid, i)
		var reached := i <= lv
		var pl := UI.label("♥" if reached else "♡", 17 if un.is_empty() else 20, PINK if reached else (UI.GOLD if not un.is_empty() else Color(1, 1, 1, 0.4)), 2)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.custom_minimum_size = Vector2(26, 24)
		pl.mouse_filter = Control.MOUSE_FILTER_PASS
		pl.tooltip_text = "Bond %d: +2%% all stats%s" % [i, "" if un.is_empty() else "\n• " + "\n• ".join(un)]
		track.add_child(pl)
	# next reward
	if maxed:
		v.add_child(UI.label("✦ Max Bond — Oath Ceremony in Hero Details" if not bool(h.get("oath", false)) else "✦ Sworn forever", 12, UI.GOLD, 2))
	else:
		var nxt := lv + 1
		var goal := nxt
		while goal < DB.MAX_BOND and DB.bond_unlocks(hid, goal).is_empty():
			goal += 1
		var un := DB.bond_unlocks(hid, goal)
		var nl := UI.label(("NEXT  Lv.%d" % goal) + ("" if un.is_empty() else ":  " + str(un[0])), 12, UI.GOLD, 2)
		nl.clip_text = true
		nl.custom_minimum_size.x = 0
		nl.tooltip_text = "\n".join(un)
		nl.mouse_filter = Control.MOUSE_FILTER_PASS
		v.add_child(nl)
	return card

## Little hearts that rise from the hero after a talk / rest, with the Bond gained.
func _float_hearts(gain: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_art):
		return
	var c := _art.get_parent() as Control
	var base := Vector2(c.size.x * 0.41, c.size.y * 0.42)
	var big := UI.label("+%d ♥" % gain, 34, PINK, 6)
	big.position = base - Vector2(40, 0)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(big)
	var tw := big.create_tween()
	tw.tween_property(big, "position:y", base.y - 90, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(big, "modulate:a", 0.0, 0.6).set_delay(0.9)
	tw.tween_callback(big.queue_free)
	for i in 7:
		var hl := UI.label("♥", randi_range(18, 30), PINK.lightened(randf() * 0.4), 3)
		hl.position = base + Vector2(randf_range(-110, 110), randf_range(-20, 60))
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hl.modulate.a = 0.0
		c.add_child(hl)
		var t2 := hl.create_tween()
		t2.tween_interval(i * 0.08)
		t2.tween_property(hl, "modulate:a", 1.0, 0.15)
		t2.parallel().tween_property(hl, "position:y", hl.position.y - randf_range(120, 200), 1.3).set_trans(Tween.TRANS_SINE)
		t2.tween_property(hl, "modulate:a", 0.0, 0.3)
		t2.tween_callback(hl.queue_free)

func _pick_hero() -> void:
	var v: VBoxContainer = main.popup("INVITE A HERO", 820)
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 420)
	v.add_child(sc)
	var ids: Array = Game.s["heroes"].keys()
	ids.sort_custom(func(a, b): return int(Game.hero(a)["bond"]) > int(Game.hero(b)["bond"]))
	for id in ids:
		var hid: String = id
		var opts := {"skin": true, "show_level": false, "lazy": true}
		if DB.fav_room(hid) == _loc:
			opts["badge"] = "♥"
		var card := HeroCard.new(hid, Vector2(108, 136), opts)
		card.set_selected(hid == Game.room_hero())
		card.pressed.connect(func():
			Game.s["room"]["hero"] = hid
			Game.mark_dirty()
			main.close_popup(v)
			main.replace("room", {"loc": _loc}))
		g.add_child(card)


## Gift tile: icon, count and a heart on her favourite. Tap to give.
func _gift_tile(hid: String, g: String) -> Control:
	var n := Game.amount(g)
	var fav := DB.fav_gift(hid) == g
	var bt := Button.new()
	bt.focus_mode = Control.FOCUS_NONE
	bt.custom_minimum_size = Vector2(0, 56)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := Color("#ff8fb8") if fav else Color(1, 1, 1, 0.14)
	var sb := UI.style(Color(0.12, 0.08, 0.18, 0.9) if n > 0 else Color(0.08, 0.06, 0.11, 0.7), border, 10, 2 if fav else 1, 4.0)
	bt.add_theme_stylebox_override("normal", sb)
	var hv := sb.duplicate()
	hv.border_color = UI.GOLD
	bt.add_theme_stylebox_override("hover", hv)
	bt.add_theme_stylebox_override("pressed", hv)
	bt.add_theme_stylebox_override("disabled", sb)
	var h := UI.hbox(4)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 6
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bt.add_child(h)
	var ic := UI.tex_rect(DB.icon(DB.ITEMS[g]["icon"]), Vector2(38, 38))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if n <= 0:
		ic.modulate = Color(1, 1, 1, 0.3)
	h.add_child(ic)
	var cl := UI.label("x%d" % n, 14, Color.WHITE if n > 0 else UI.MUTED, 2)
	cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(cl)
	if fav:
		var hl := UI.label("♥", 14, Color("#ff8fb8"), 3)
		hl.position = Vector2(4, 0)
		bt.add_child(hl)
	bt.tooltip_text = "%s%s\n%s" % [DB.ITEMS[g]["name"], "  (her favourite: Bond x2)" if fav else "", DB.ITEMS[g].get("desc", "")]
	bt.disabled = n <= 0
	bt.pressed.connect(func():
		var err := Game.give_gift(hid, g)
		if err != "":
			main.toast(err, UI.RED)
			return
		Game.sfx("star_up")
		main.toast("%s loved it! %s" % [DB.name_of(hid).split(" ")[0], "(favourite x2)" if fav else ""], Color("#ff8fb8"))
		main.replace("room", {"loc": _loc}))
	UI.hover_fx(bt, 1.04)
	return bt
