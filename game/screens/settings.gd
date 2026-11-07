extends Screen
## Settings: audio, battle speed, player name, save management.

func build() -> void:
	set_bg("lobby", 0.75)
	header("SETTINGS", [])
	var b := body(76)
	var sc := DragScroll.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	b.add_child(sc)
	var c := CenterContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(c)
	var p := UI.panel()
	p.custom_minimum_size = Vector2(640, 0)
	c.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	v.add_child(UI.tex_rect(DB.tex("res://art/brand/logo_text_glow.png"), Vector2(0, 110)))
	var st: Dictionary = Game.s["settings"]

	v.add_child(UI.label("AUDIO", 18, UI.GOLD, 3))
	for k in [["bgm", "Music"], ["sfx", "Sound Effects"], ["voice", "Voice"]]:
		var key: String = k[0]
		var h := UI.hbox(12)
		var l := UI.label(k[1], 16)
		l.custom_minimum_size = Vector2(160, 0)
		h.add_child(l)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 1
		s.step = 0.05
		s.value = float(st[key])
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.custom_minimum_size = Vector2(0, 30)
		s.value_changed.connect(func(val):
			st[key] = val
			Game.refresh_volume()
			Game.mark_dirty())
		h.add_child(s)
		v.add_child(h)

	v.add_child(UI.label("BATTLE", 18, UI.GOLD, 3))
	var cut_ch := CheckButton.new()
	cut_ch.text = "Skip skill cut-ins (faster battles)"
	cut_ch.button_pressed = bool(st.get("skip_cutin", false))
	cut_ch.focus_mode = Control.FOCUS_NONE
	cut_ch.toggled.connect(func(on):
		st["skip_cutin"] = on
		Game.mark_dirty())
	v.add_child(cut_ch)
	var lv := CheckButton.new()
	lv.text = "2.5D Live art (heroes tilt with depth & light — turn off on slow phones)"
	lv.button_pressed = bool(st.get("live25d", true))
	lv.focus_mode = Control.FOCUS_NONE
	lv.toggled.connect(func(on):
		st["live25d"] = on
		Game.mark_dirty())
	v.add_child(lv)
	var rf := CheckButton.new()
	rf.text = "Reduce effects (no screen flash / shake — easier on the eyes)"
	rf.button_pressed = bool(st.get("reduce_fx", false))
	rf.focus_mode = Control.FOCUS_NONE
	rf.toggled.connect(func(on):
		st["reduce_fx"] = on
		Game.mark_dirty())
	v.add_child(rf)

	v.add_child(UI.label("DISPLAY", 18, UI.GOLD, 3))
	var sh := UI.hbox(8)
	var sl := UI.label("UI Size", 16)
	sl.custom_minimum_size = Vector2(160, 0)
	sh.add_child(sl)
	var cur_scale := float(st.get("ui_scale", -1.0))
	for opt in [[-1.0, "AUTO"], [1.0, "NORMAL"], [1.15, "LARGE"], [1.3, "X-LARGE"]]:
		var val: float = opt[0]
		var sb := UI.button(opt[1], func():
			st["ui_scale"] = val
			Game.apply_ui_scale()
			Game.mark_dirty()
			main.replace("settings"), "TabButton", Vector2(0, 40))
		sb.toggle_mode = true
		sb.button_pressed = is_equal_approx(cur_scale, val)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sh.add_child(sb)
	v.add_child(sh)

	v.add_child(UI.label("PLAYER", 18, UI.GOLD, 3))
	var nh := UI.hbox(10)
	var le := LineEdit.new()
	le.text = str(Game.s["player"]["name"])
	le.max_length = 16
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(0, 44)
	nh.add_child(le)
	nh.add_child(UI.button("RENAME", func():
		var n := le.text.strip_edges()
		if n.length() < 2:
			main.toast("Name too short.", UI.RED)
			return
		Game.s["player"]["name"] = n
		Game.mark_dirty()
		main.toast("Name changed to %s" % n), "", Vector2(130, 44)))
	v.add_child(nh)

	v.add_child(UI.label("DATA", 18, UI.GOLD, 3))
	v.add_child(UI.wrap_label("Progress is saved automatically on this device. Browsers (especially Safari on iPhone) may delete game data if you don't play for a while — make a BACKUP CODE and keep it somewhere safe.", 14, UI.MUTED))
	var bh := UI.hbox(10)
	var eb := UI.button("BACKUP CODE", _export_save, "GoldButton", Vector2(0, 46))
	eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(eb)
	var ib := UI.button("RESTORE FROM CODE", _import_save, "", Vector2(0, 46))
	ib.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(ib)
	v.add_child(bh)
	var dh := UI.hbox(10)
	dh.add_child(UI.button("REPLAY INTRO", func():
		main.dialogue([["furu", "Commander, welcome back to Euphoria."], ["shina", "Let's show the Eclipse what we're made of!"]]), "", Vector2(0, 46)))
	dh.add_child(UI.button("RESET SAVE", func():
		main.confirm("Delete ALL progress and start over? This cannot be undone.", func():
			Game.reset_save()
			main.home(), "DELETE"), "", Vector2(0, 46)))
	for ch in dh.get_children():
		ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(dh)
	v.add_child(UI.label("Euphoria Online  •  v2.1", 13, UI.MUTED))
	v.add_child(UI.button("BACK TO TITLE", func(): main.history.clear(); main.go("title", {}, false), "", Vector2(0, 42)))


func _export_save() -> void:
	var code := Game.export_code()
	var v: VBoxContainer = main.popup("BACKUP CODE", 720)
	v.add_child(UI.wrap_label("Copy this code and save it (Notes app, chat to yourself, etc.). Use RESTORE FROM CODE on any device to get your progress back.", 14, UI.MUTED))
	var te := TextEdit.new()
	te.text = code
	te.editable = false
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.custom_minimum_size = Vector2(0, 200)
	v.add_child(te)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("COPY", func():
		DisplayServer.clipboard_set(code)
		te.select_all()
		main.toast("Backup code copied!", UI.GREEN), "GoldButton", Vector2(160, 46)))
	row.add_child(UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 46)))

func _import_save() -> void:
	var v: VBoxContainer = main.popup("RESTORE FROM CODE", 720)
	v.add_child(UI.wrap_label("Paste your backup code below. This REPLACES the progress on this device.", 14, UI.MUTED))
	var te := TextEdit.new()
	te.placeholder_text = "EO2:..."
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.custom_minimum_size = Vector2(0, 200)
	v.add_child(te)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("RESTORE", func():
		var err := Game.import_code(te.text)
		if err != "":
			main.toast(err, UI.RED)
			return
		main.close_popup(v)
		main.toast("Progress restored!", UI.GREEN)
		main.home(), "GoldButton", Vector2(160, 46)))
	row.add_child(UI.button("CANCEL", func(): main.close_popup(v), "", Vector2(160, 46)))
