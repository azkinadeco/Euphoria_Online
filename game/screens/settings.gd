extends Screen
## Settings: audio, battle speed, player name, save management.

var _st: Dictionary

func build() -> void:
	set_bg("lobby", 0.75)
	ambient(Color(0.85, 0.8, 1.0), 16)
	header("SETTINGS", [])
	_st = Game.s["settings"]
	var b := body(76)
	# ---------------- left: profile + data
	var lp := UI.panel()
	lp.anchor_right = 0.36
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lsc := DragScroll.new()
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(lsc)
	var lv := UI.vbox(12)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(lv)
	_profile(lv)
	_data(lv)
	# ---------------- right: settings cards
	var rsc := DragScroll.new()
	rsc.anchor_left = 0.37
	rsc.anchor_right = 1.0
	rsc.anchor_bottom = 1.0
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	b.add_child(rsc)
	var rv := UI.vbox(12)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(rv)
	_audio(rv)
	_battle(rv)
	_display(rv)
	_account(rv)
	UI.stagger(rv, 0.04)

# ---------------------------------------------------------------- building blocks

## A titled card with an icon; returns the content box.
func _card(parent: Control, title: String, icon: String, col: Color) -> VBoxContainer:
	var p := UI.styled_panel(Color(0.07, 0.04, 0.12, 0.9), Color(col, 0.45), 14, 1, 14)
	parent.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var h := UI.hbox(8)
	if icon != "":
		h.add_child(UI.tex_rect(DB.icon(icon), Vector2(26, 26)))
	h.add_child(UI.label(title, 17, col.lightened(0.25), 3))
	var line := ColorRect.new()
	line.color = Color(col, 0.3)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(line)
	v.add_child(h)
	return v

## Switch row: bold title, muted explanation, toggle on the right.
func _toggle(parent: Control, title: String, sub: String, key: String, def: bool) -> void:
	var row := UI.hbox(10)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(title, 15, Color.WHITE, 2))
	tv.add_child(UI.wrap_label(sub, 12, UI.MUTED))
	row.add_child(tv)
	var cb := CheckButton.new()
	cb.button_pressed = bool(_st.get(key, def))
	cb.focus_mode = Control.FOCUS_NONE
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var state := UI.label("ON" if cb.button_pressed else "OFF", 12, UI.GREEN if cb.button_pressed else UI.MUTED, 2)
	state.custom_minimum_size = Vector2(30, 0)
	state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cb.toggled.connect(func(on):
		_st[key] = on
		state.text = "ON" if on else "OFF"
		state.add_theme_color_override("font_color", UI.GREEN if on else UI.MUTED)
		Game.sfx("ui_click")
		Game.mark_dirty())
	row.add_child(state)
	row.add_child(cb)
	parent.add_child(row)

## Segmented choice: buttons in a row, the current one highlighted.
func _choice(parent: Control, title: String, opts: Array, is_cur: Callable, pick: Callable) -> void:
	var v := UI.vbox(6)
	v.add_child(UI.label(title, 14, UI.TEXT, 2))
	var h := UI.hbox(6)
	for o in opts:
		var val = o[0]
		var bt := UI.button(str(o[1]), func(): pick.call(val), "TabButton", Vector2(0, 40))
		bt.toggle_mode = true
		bt.button_pressed = is_cur.call(val)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.add_theme_font_size_override("font_size", 13)
		h.add_child(bt)
	v.add_child(h)
	parent.add_child(v)

# ---------------------------------------------------------------- left column

func _profile(parent: Control) -> void:
	var lh: String = str(Game.s["lobby_hero"])
	var col := DB.theme_color(lh)
	var p := UI.styled_panel(Color(col.darkened(0.8), 0.92), Color(col, 0.6), 16, 1, 14)
	parent.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var top := UI.hbox(12)
	v.add_child(top)
	var av := Control.new()
	av.custom_minimum_size = Vector2(84, 84)
	var clip := Panel.new()
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	clip.add_theme_stylebox_override("panel", UI.style(Color.WHITE, Color.TRANSPARENT, 42, 0, 0))
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	av.add_child(clip)
	var face := UI.tex_rect(DB.face(lh), Vector2.ZERO, true)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_child(face)
	var ring := Panel.new()
	ring.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, UI.GOLD, 42, 2, 0))
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.add_child(ring)
	top.add_child(av)
	var nv := UI.vbox(2)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nv)
	nv.add_child(UI.label(str(Game.s["player"]["name"]), 22, Color.WHITE, 4))
	nv.add_child(UI.label("COMMANDER  Lv.%d" % int(Game.s["player"]["level"]), 14, UI.GOLD, 3))
	nv.add_child(UI.label("ID  %08d" % (absi(hash(str(Game.s["player"]["name"]))) % 100000000), 12, UI.MUTED, 0))
	var eb := UI.bar(int(Game.s["player"]["exp"]), Game.player_exp_needed(), "GoldBar", 6)
	nv.add_child(eb)
	var chips := GridContainer.new()
	chips.columns = 2
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	v.add_child(chips)
	for c in [["HEROES", "%d / %d" % [Game.s["heroes"].size(), DB.hero_ids().size()], "#ff8fb8"],
			["STAGES", "%d / %d" % [Game.stages_cleared(), DB.stage_count()], "#9fd0ff"],
			["TEAM POWER", Game.fmt(Game.team_power()), "#ffd479"],
			["PARTNER", DB.name_of(lh).split(" ")[0], col.lightened(0.4).to_html(false)]]:
		var cp := UI.styled_panel(Color(0, 0, 0, 0.35), Color(Color(str(c[2])), 0.4), 10, 1, 8)
		cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cv := UI.vbox(0)
		cp.add_child(cv)
		cv.add_child(UI.label(str(c[0]), 11, UI.MUTED, 2))
		cv.add_child(UI.label(str(c[1]), 16, Color(str(c[2])), 3))
		chips.add_child(cp)
	var nh := UI.hbox(8)
	var le := LineEdit.new()
	le.text = str(Game.s["player"]["name"])
	le.max_length = 16
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(0, 42)
	nh.add_child(le)
	nh.add_child(UI.button("RENAME", func():
		var n := le.text.strip_edges()
		if n.length() < 2:
			main.toast("Name too short.", UI.RED)
			return
		Game.s["player"]["name"] = n
		Game.mark_dirty()
		main.toast("Name changed to %s" % n)
		main.replace("settings"), "", Vector2(110, 42)))
	v.add_child(nh)
	var hp := UI.button("📖 HOW TO PLAY", func(): main.show_how_to_play(), "GoldButton", Vector2(0, 44))
	hp.tooltip_text = "Battlefield, ranges, roles, elements, growth and daily routine"
	v.add_child(hp)

func _data(parent: Control) -> void:
	var v := _card(parent, "SAVE DATA", "icon_codex", Color("#7ee08a"))
	var warn := UI.styled_panel(Color(0.3, 0.2, 0.05, 0.5), Color("#ffcf5a", 0.5), 10, 1, 10)
	warn.add_child(UI.wrap_label("Progress is saved on this device. Browsers (especially Safari on iPhone) may delete it if you don't play for a while — keep a BACKUP CODE somewhere safe.", 12, Color("#ffe3a0")))
	v.add_child(warn)
	var eb := UI.button("BACKUP CODE", _export_save, "GoldButton", Vector2(0, 46))
	v.add_child(eb)
	v.add_child(UI.button("RESTORE FROM CODE", _import_save, "", Vector2(0, 42)))
	var dh := UI.hbox(8)
	var ri := UI.button("REPLAY INTRO", func():
		main.dialogue([["furu", "Commander, welcome back to Euphoria."], ["shina", "Let's show the Eclipse what we're made of!"]]), "", Vector2(0, 40))
	ri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ri.add_theme_font_size_override("font_size", 13)
	dh.add_child(ri)
	var tb := UI.button("TITLE SCREEN", func(): main.history.clear(); main.go("title", {}, false), "", Vector2(0, 40))
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_theme_font_size_override("font_size", 13)
	dh.add_child(tb)
	v.add_child(dh)
	var rs := UI.button("RESET SAVE", func():
		main.confirm("Delete ALL progress and start over? This cannot be undone.", func():
			Game.reset_save()
			main.home(), "DELETE"), "", Vector2(0, 40))
	rs.add_theme_color_override("font_color", Color("#ff8a8a"))
	rs.add_theme_stylebox_override("normal", UI.style(Color(0.25, 0.04, 0.08, 0.85), Color("#ff6b6b", 0.6), 10, 1, 0))
	v.add_child(rs)
	var ver := UI.label("Euphoria Online  •  v2.1  •  %d heroes  •  %d chapters" % [DB.hero_ids().size(), DB.CHAPTERS.size()], 12, UI.MUTED, 0)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ver)

# ---------------------------------------------------------------- right column

func _audio(parent: Control) -> void:
	var v := _card(parent, "AUDIO", "icon_messenger", Color("#c49bff"))
	for k in [["bgm", "Music", "♪"], ["sfx", "Sound Effects", "✦"], ["voice", "Voice", "♥"]]:
		var key: String = k[0]
		var h := UI.hbox(10)
		var ic := UI.label(str(k[2]), 18, Color("#c49bff"), 2)
		ic.custom_minimum_size = Vector2(22, 0)
		h.add_child(ic)
		var l := UI.label(k[1], 15)
		l.custom_minimum_size = Vector2(130, 0)
		h.add_child(l)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 1
		s.step = 0.05
		s.value = float(_st[key])
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(0, 30)
		h.add_child(s)
		var pct := UI.label("%d%%" % roundi(float(_st[key]) * 100), 14, UI.GOLD, 2)
		pct.custom_minimum_size = Vector2(48, 0)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(pct)
		var mute := UI.button("MUTE" if float(_st[key]) > 0.01 else "ON", func(): pass, "", Vector2(64, 32))
		mute.add_theme_font_size_override("font_size", 12)
		mute.pressed.connect(func():
			s.value = 0.0 if s.value > 0.01 else 0.8)
		h.add_child(mute)
		s.value_changed.connect(func(val):
			_st[key] = val
			pct.text = "%d%%" % roundi(val * 100)
			mute.text = "MUTE" if val > 0.01 else "ON"
			Game.refresh_volume()
			Game.mark_dirty())
		v.add_child(h)
	var tv := UI.button("▶  Test voice (%s)" % DB.name_of(str(Game.s["lobby_hero"])).split(" ")[0], func():
		main.toast("%s: \"%s\"" % [DB.name_of(str(Game.s["lobby_hero"])), Game.voice(str(Game.s["lobby_hero"]), "greet")], Color("#ff8fb8")), "", Vector2(0, 36))
	tv.add_theme_font_size_override("font_size", 13)
	tv.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(tv)

func _battle(parent: Control) -> void:
	var v := _card(parent, "BATTLE & GRAPHICS", "icon_combat_speed", Color("#ff9a6b"))
	_toggle(v, "Skip skill cut-ins", "Faster battles: skip the full-screen ultimate animation.", "skip_cutin", false)
	_toggle(v, "2.5D Live art", "Heroes tilt with depth and light. Turn off on slow phones.", "live25d", true)
	_toggle(v, "Reduce effects", "No screen flash or shake — easier on the eyes.", "reduce_fx", false)

func _display(parent: Control) -> void:
	var v := _card(parent, "DISPLAY", "icon_settings", Color("#5fb8ff"))
	var cur_scale := float(_st.get("ui_scale", -1.0))
	_choice(v, "UI size", [[-1.0, "AUTO"], [1.0, "NORMAL"], [1.15, "LARGE"], [1.3, "X-LARGE"]],
		func(val): return is_equal_approx(cur_scale, float(val)),
		func(val):
			_st["ui_scale"] = float(val)
			Game.apply_ui_scale()
			Game.mark_dirty()
			main.replace("settings"))
	_choice(v, "Frame rate", [[60, "60 FPS  •  smooth"], [30, "30 FPS  •  battery saver"]],
		func(val): return Game.fps_cap() == int(val),
		func(val):
			_st["fps"] = int(val)
			Game.apply_fps()
			Game.mark_dirty()
			main.replace("settings"))

func _account(parent: Control) -> void:
	var v := _card(parent, "REDEEM CODE", "icon_mail", Color("#ffcf5a"))
	v.add_child(UI.wrap_label("Got a code from an event or the community? Enter it here for free rewards.", 12, UI.MUTED))
	var rh := UI.hbox(8)
	var ce := LineEdit.new()
	ce.placeholder_text = "Enter code"
	ce.max_length = 24
	ce.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ce.custom_minimum_size = Vector2(0, 42)
	rh.add_child(ce)
	rh.add_child(UI.button("REDEEM", func():
		var r := Game.redeem(ce.text)
		if r.has("error"):
			main.toast(str(r["error"]), UI.RED)
			return
		ce.text = ""
		main.show_rewards("CODE REDEEMED", r["give"]), "GoldButton", Vector2(120, 42)))
	v.add_child(rh)

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
