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
	var hrow := UI.hbox(8)
	hrow.add_child(UI.tex_rect(DB.face(hid), Vector2(44, 44), true))
	var hv := UI.vbox(0)
	hv.add_child(UI.label(DB.name_of(hid), 20, Color.WHITE, 4))
	var h := Game.hero(hid)
	hv.add_child(UI.label("Bond Lv.%d" % int(h["bond"]), 13, Color("#ff8fb8"), 3))
	hrow.add_child(hv)
	v.add_child(hrow)
	v.add_child(UI.bar(int(h["bond_exp"]), DB.bond_to_next(int(h["bond"])), "GoldBar", 8))
	var fav := DB.fav_room(hid) == _loc
	v.add_child(UI.label("♥ Her favourite room — Bond x2!" if fav else "Favourite room: " + str(DB.room_def(DB.fav_room(hid))["name"]), 13, Color("#ff8fb8") if fav else UI.MUTED, 2))
	var left := Game.room_visits_left()
	var tb := UI.button("♥ TALK  (%d / %d today)" % [left, DB.ROOM_VISITS], func():
		var lines := Game.room_talk(_loc)
		if lines.is_empty():
			main.toast("No visits left today.", UI.MUTED)
			return
		main.dialogue(lines, func(): main.replace("room", {"loc": _loc}), _loc), "GoldButton", Vector2(0, 52))
	tb.disabled = left <= 0
	v.add_child(tb)
	var rested: bool = (Game._room()["rested"] as Array).has(_loc)
	var rb := UI.button("REST TOGETHER  (+20 Energy)" if not rested else "RESTED HERE TODAY", func():
		var r := Game.room_rest(_loc)
		if r.is_empty():
			return
		Game.sfx("star_up")
		main.show_rewards("A QUIET MOMENT", r, func(): main.replace("room", {"loc": _loc})), "" , Vector2(0, 46))
	rb.disabled = rested
	v.add_child(rb)
	v.add_child(UI.label("GIFTS", 14, UI.GOLD, 3))
	var gf := HFlowContainer.new()
	gf.add_theme_constant_override("h_separation", 6)
	gf.add_theme_constant_override("v_separation", 6)
	v.add_child(gf)
	for gid in DB.GIFTS:
		var g: String = gid
		var n := Game.amount(g)
		var gb := UI.button("%s x%d%s" % [DB.ITEMS[g]["name"].split(" ")[-1], n, "  ♥" if DB.fav_gift(hid) == g else ""], func():
			var err := Game.give_gift(hid, g)
			if err != "":
				main.toast(err, UI.RED)
				return
			main.toast("%s loved it! %s" % [DB.name_of(hid).split(" ")[0], "(favourite x2)" if DB.fav_gift(hid) == g else ""], Color("#ff8fb8"))
			main.replace("room", {"loc": _loc}), "", Vector2(0, 38))
		gb.add_theme_font_size_override("font_size", 12)
		gb.disabled = n <= 0
		gf.add_child(gb)
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
		var opts := {"skin": true, "show_level": false}
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
