extends Screen
## Bestiary: every enemy type, filled in as you defeat them. Kill milestones give rewards.
## Each foe shows all her forms (upgrades / evolutions, unlocked by kills or taming bond),
## can be TAMED after enough kills, and then befriended like a hero (talk, pat, gifts).
## The art supports pinch-zoom; a tap plays a reaction, rubbing the head pats a tamed foe.

var _sel := ""
var _grid: GridContainer
var _detail: VBoxContainer
var _art: TextureRect
var _mid: Control
var _forms: HBoxContainer
var _form := 0
var _tab := "info"
var _zoom := 1.0
var _pinch: PinchZoom
var _down := false
var _start := Vector2.ZERO
var _rub := 0.0
var _moved := false
var _rig: CharRig
var _hint: Label

func build() -> void:
	set_bg("necro", 0.6)
	ambient(Color(0.8, 0.9, 1.0), 20)
	header("BESTIARY", ["gold", "gems"])
	var b := body(76)
	var lp := UI.panel()
	lp.anchor_right = 0.335
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	var seen := DB.ENEMIES.keys().filter(func(id): return Game.kills_of(id) > 0).size()
	var dh := UI.hbox(8)
	var dl := UI.label("DISCOVERED", 14, UI.GOLD, 3)
	dh.add_child(dl)
	var dn := UI.label("%d / %d" % [seen, DB.ENEMIES.size()], 14, Color.WHITE, 2)
	dn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dh.add_child(dn)
	lv.add_child(dh)
	lv.add_child(UI.bar(seen, DB.ENEMIES.size(), "GoldBar", 8))
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	lv.add_child(UI.scroll(_grid))
	var mid := Control.new()
	mid.anchor_left = 0.345
	mid.anchor_right = 0.705
	mid.anchor_bottom = 1.0
	mid.clip_contents = true
	b.add_child(mid)
	_mid = mid
	_art = UI.tex_rect(null)
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.offset_bottom = -112
	_art.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.gui_input.connect(_art_input)
	_art.resized.connect(func(): _art.pivot_offset = _art.size * 0.5)
	mid.add_child(_art)
	UI.live(_art, Color(1.0, 0.85, 0.9))
	_rig = CharRig.attach(_art)
	# floor glow under the figure
	var fl := Panel.new()
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	fl.offset_top = -150
	fl.offset_bottom = -108
	fl.offset_left = 30
	fl.offset_right = -30
	fl.add_theme_stylebox_override("panel", UI.style(Color(0.55, 0.35, 0.9, 0.14), Color(0, 0, 0, 0), 60, 0, 0))
	mid.add_child(fl)
	mid.move_child(fl, 0)
	_pinch = PinchZoom.new(func(f: float, _c: Vector2): _set_zoom(_zoom * f))
	_art.add_child(_pinch)
	var zb := UI.zoom_button(func():
		if Game.kills_of(_sel) <= 0:
			main.toast("Defeat this foe once to view her up close.", UI.MUTED)
			return
		var allowed: Array = []
		for k in DB.art_list(_sel).size():
			if Game.form_unlocked(_sel, k):
				allowed.append(k)
		ArtViewer.open(main, _sel, _form, allowed))
	zb.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	zb.offset_left = -64
	zb.offset_right = -6
	zb.offset_top = 6
	zb.offset_bottom = 64
	mid.add_child(zb)
	var zh := UI.label("", 11, UI.MUTED, 2)
	_hint = zh
	zh.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	zh.offset_top = -130
	zh.offset_bottom = -112
	zh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(zh)
	_forms = UI.hbox(6)
	_forms.alignment = BoxContainer.ALIGNMENT_CENTER
	var fs := ScrollContainer.new()
	fs.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fs.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	fs.offset_top = -108
	fs.add_child(_forms)
	mid.add_child(fs)
	var rp := UI.panel()
	rp.anchor_left = 0.715
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	_detail = UI.vbox(8)
	rp.add_child(UI.scroll(_detail))
	_sel = str(params.get("sel", DB.ENEMIES.keys()[0]))
	_render()

func _render() -> void:
	params["sel"] = _sel
	for c in _grid.get_children():
		c.queue_free()
	for id in DB.ENEMIES.keys():
		var eid: String = id
		var known := Game.kills_of(eid) > 0
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(110, 172)
		var ec: Color = DB.ELEMENT_COLOR.get(DB.element_of(eid), Color("#8a6ad0")) if known else Color("#3a2e58")
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color(0.06, 0.04, 0.1, 0.95), UI.GOLD if eid == _sel else Color("#4a3a6e"), 10, 2 if eid == _sel else 1, 0))
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(fr)
		# element-tinted backdrop so the full-body figure reads clearly
		var gl := Panel.new()
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		gl.offset_top = 70
		gl.add_theme_stylebox_override("panel", UI.style(Color(ec, 0.22), Color(0, 0, 0, 0), 0, 0, 0))
		fr.add_child(gl)
		var f := UI.art_rect(eid, 0)
		f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		f.offset_top = 4
		f.offset_left = 2
		f.offset_right = -2
		f.offset_bottom = -22
		if not known:
			f.modulate = Color(0, 0, 0, 0.85)
		fr.add_child(f)
		var nl := UI.label(DB.name_of(eid).split(" ")[0] if known else "???", 12, Color.WHITE if known else UI.MUTED, 3)
		nl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		nl.offset_top = -22
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fr.add_child(nl)
		for sp in DB.PET_STORY_REQ.size():
			if Game.pet_story_state(eid, sp) == "ready":
				var sd := UI.label("♥", 16, Color("#ff8fb8"), 4)
				sd.position = Vector2(4, 2)
				fr.add_child(sd)
				break
		for t in DB.BESTIARY_TIERS.size():
			if Game.bestiary_state(eid, t) == "ready":
				var dot := UI.label("!", 16, UI.GOLD, 4)
				dot.position = Vector2(92, 2)
				fr.add_child(dot)
				break
		btn.pressed.connect(func():
			Game.sfx("ui_click")
			_sel = eid
			_render())
		_grid.add_child(btn)
	_render_detail()

func _render_detail() -> void:
	for c in _detail.get_children():
		c.queue_free()
	var id := _sel
	var known := Game.kills_of(id) > 0
	var n_forms := DB.art_list(id).size()
	_form = clampi(_form, 0, maxi(0, n_forms - 1))
	if not Game.form_unlocked(id, _form):
		_form = 0
	_art.modulate = Color.WHITE if known else Color(0, 0, 0, 0.9)
	_show_art(DB.art(id, _form))
	_set_zoom(1.0)
	_render_forms()
	var title := UI.hbox(6)
	title.add_child(UI.label(DB.name_of(id) if known else "Unknown foe", 22, Color.WHITE, 4))
	if Game.is_tamed(id):
		title.add_child(UI.label("♥ TAMED", 13, Color("#ff8fb8"), 3))
	_detail.add_child(title)
	if not known:
		_unknown_detail(id)
		return
	var tabs := UI.hbox(6)
	for tb in [["info", "INFO"], ["tame", "TAMING ♥" if Game.is_tamed(id) else "TAMING"]]:
		var key: String = tb[0]
		var bt := UI.button(tb[1], func(): _tab = key; _render_detail(), "TabButton", Vector2(0, 36))
		bt.toggle_mode = true
		bt.button_pressed = key == _tab
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.add_theme_font_size_override("font_size", 12)
		tabs.add_child(bt)
	_detail.add_child(tabs)
	if _tab == "tame":
		_render_tame(id)
		return
	_detail.add_child(UI.label(DB.title_of(id), 13, Color("#d4b8ff"), 3))
	var el := UI.hbox(6)
	el.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(id), "elem_light")), Vector2(22, 22)))
	el.add_child(UI.label("%s  •  %s" % [DB.element_of(id), DB.role_of(id)], 14, DB.ELEMENT_COLOR.get(DB.element_of(id), UI.TEXT), 2))
	_detail.add_child(el)
	var sk: Dictionary = DB.ENEMIES[id]["skill"]
	_detail.add_child(UI.label("Skill: " + str(sk["name"]), 14, UI.GOLD, 2))
	_detail.add_child(UI.label("Defeated: %s" % Game.fmt(Game.kills_of(id)), 16, UI.GREEN, 3))
	var in_lobby := Game.lobby_enemy() == id and Game.lobby_enemy_form() == _form
	var lb := UI.button("🏠 IN LOBBY ✓" if in_lobby else "🏠 SET AS LOBBY", func():
		if in_lobby:
			Game.set_lobby_enemy("")
			main.toast("Your hero is back in the lobby.", UI.MUTED)
		elif Game.set_lobby_enemy(id, _form):
			Game.sfx("star_up")
			main.toast("%s now waits for you in the lobby." % DB.name_of(id), UI.GOLD)
		_render_detail(), "" if in_lobby else "GoldButton", Vector2(0, 38))
	lb.add_theme_font_size_override("font_size", 12)
	_detail.add_child(lb)
	_detail.add_child(_lore_card(id))
	_detail.add_child(UI.label("HUNTER MILESTONES", 14, UI.GOLD, 3))
	for t in DB.BESTIARY_TIERS.size():
		var tier: int = t
		var td: Dictionary = DB.BESTIARY_TIERS[tier]
		var st := Game.bestiary_state(id, tier)
		var p := UI.panel("CardPanel")
		_detail.add_child(p)
		var h := UI.hbox(6)
		p.add_child(h)
		var col := UI.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UI.label("Defeat %d" % int(td["kills"]), 13, Color.WHITE if st != "claimed" else UI.MUTED, 2))
		col.add_child(UI.reward_row(td["give"], 24, 11))
		h.add_child(col)
		if st == "claimed":
			h.add_child(UI.label("✓", 16, UI.GREEN, 2))
		else:
			var cb := UI.button("CLAIM", func():
				var g := Game.claim_bestiary(id, tier)
				if not g.is_empty():
					main.show_rewards("BESTIARY", g)
					_render(), "GoldButton" if st == "ready" else "", Vector2(80, 36))
			cb.add_theme_font_size_override("font_size", 12)
			cb.disabled = st != "ready"
			h.add_child(cb)

## Hunter's Lore: what your kills are worth in battle against her, and the next level.
func _lore_card(id: String) -> Control:
	var lv := Game.lore_level(id)
	var p := UI.styled_panel(Color("#2a3a14", 0.55), Color("#c8f08f", 0.55), 10, 1, 8.0)
	var v := UI.vbox(4)
	p.add_child(v)
	var h := UI.hbox(6)
	var t := UI.label("HUNTER'S LORE", 13, Color("#c8f08f"), 3)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var pips := ""
	for i in DB.BESTIARY_TIERS.size():
		pips += "◆" if i < lv else "◇"
	h.add_child(UI.label(pips, 14, Color("#c8f08f"), 2))
	v.add_child(h)
	if lv > 0:
		v.add_child(UI.label("+%d%% damage to her  •  −%d%% damage from her" % [roundi(DB.LORE_DMG * lv * 100), roundi(DB.LORE_GUARD * lv * 100)], 12, Color.WHITE, 2))
	else:
		v.add_child(UI.label("No bonus yet", 12, UI.MUTED, 1))
	if lv < DB.BESTIARY_TIERS.size():
		var need := int(DB.BESTIARY_TIERS[lv]["kills"])
		var k := Game.kills_of(id)
		v.add_child(UI.bar(k, need, "GoldBar", 6))
		v.add_child(UI.label("Lv.%d at %d kills (%d to go): +%d%% / −%d%%" % [lv + 1, need, need - k, roundi(DB.LORE_DMG * (lv + 1) * 100), roundi(DB.LORE_GUARD * (lv + 1) * 100)], 11, UI.MUTED, 1))
	else:
		v.add_child(UI.label("✦ Lore mastered", 12, UI.GOLD, 2))
	return p

# ---------------------------------------------------------------- forms (upgrade / evolution arts)

func _render_forms() -> void:
	for c in _forms.get_children():
		c.queue_free()
	var id := _sel
	var arts := DB.art_list(id)
	if arts.size() <= 1 or Game.kills_of(id) <= 0:
		return
	for k in arts.size():
		var fk: int = k
		var open := Game.form_unlocked(id, fk)
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(70, 100)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color(0.06, 0.04, 0.1, 0.95), UI.GOLD if fk == _form else Color("#4a3a6e"), 8, 2 if fk == _form else 1, 0))
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(fr)
		var th := UI.art_rect(id, fk)
		th.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		th.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		th.offset_top = 3
		th.offset_bottom = -16
		if not open:
			th.modulate = Color(0.06, 0.05, 0.1)
		fr.add_child(th)
		var lb := UI.label(("EVO %d" % (fk - _first_evo(id) + 1)) if fk >= _first_evo(id) else ("LV %d" % (fk + 1)), 10, Color.WHITE if open else UI.MUTED, 3)
		lb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		lb.offset_top = -16
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fr.add_child(lb)
		b.pressed.connect(func():
			if not open:
				var kk: int = DB.FORM_KILLS[mini(fk, DB.FORM_KILLS.size() - 1)]
				var bb: int = DB.FORM_BOND[mini(fk, DB.FORM_BOND.size() - 1)]
				main.toast("Locked — defeat %d (now %d) or reach Tamed Bond Lv.%d." % [kk, Game.kills_of(id), bb], UI.MUTED)
				return
			Game.sfx("ui_click")
			_form = fk
			_show_art(DB.art(id, fk))
			_set_zoom(1.0)
			UI.fade_in(_art, 0.25, Vector2(0, 10))
			_render_forms())
		_forms.add_child(b)

## index of the first "evo" state in the foe's art list (forms before it are level-ups)
func _first_evo(id: String) -> int:
	var arts := DB.art_list(id)
	for i in arts.size():
		if "_evo" in str(arts[i]).get_file():
			return i
	return arts.size()

# ---------------------------------------------------------------- art

func _show_art(tex: Texture2D) -> void:
	_art.texture = tex
	_hint.text = "Pinch to zoom • tap to interact • lens = full screen" if Game.kills_of(_sel) > 0 else "Defeat her once to reveal her."

# ---------------------------------------------------------------- zoom & interaction

func _set_zoom(z: float) -> void:
	_zoom = clampf(z, 1.0, 3.5)
	_art.scale = Vector2(_zoom, _zoom)
	if _zoom <= 1.01:
		_art.position = Vector2.ZERO

func _art_input(e: InputEvent) -> void:
	if Game.kills_of(_sel) <= 0:
		return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_set_zoom(_zoom * 1.1)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_set_zoom(_zoom / 1.1)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_down = true
				_start = e.position
				_rub = 0.0
				_moved = false
				if e.double_click:
					_set_zoom(1.0 if _zoom > 1.4 else 2.0)
			elif _down:
				_down = false
				if not _moved and not _pinch.active() and _rub < 40.0:
					_react(e.position.y / maxf(1.0, _art.size.y))
	elif e is InputEventMouseMotion and _down and not _pinch.active():
		if (e.position - _start).length() > 12.0:
			_moved = true
		if _zoom > 1.01:
			# pan while zoomed
			_art.position += e.relative
		elif Game.is_tamed(_sel) and e.position.y / maxf(1.0, _art.size.y) < 0.35:
			_rub += (e.relative as Vector2).length()
			if _rub > 260.0:
				_rub = 0.0
				_pat()

## Tap: a reaction animation (hop / shiver / lean) and a line if she is tamed.
func _react(ry: float) -> void:
	Game.sfx("ui_click")
	_rig.react(ry)
	var tw := _art.create_tween()
	var y0 := _art.position.y
	if ry < 0.35:
		tw.tween_property(_art, "rotation", 0.04, 0.08)
		tw.tween_property(_art, "rotation", -0.03, 0.1)
		tw.tween_property(_art, "rotation", 0.0, 0.1)
	elif ry < 0.7:
		for i in 3:
			tw.tween_property(_art, "position:x", _art.position.x + 6, 0.04)
			tw.tween_property(_art, "position:x", _art.position.x - 6, 0.04)
		tw.tween_property(_art, "position:x", _art.position.x, 0.04)
	else:
		tw.tween_property(_art, "position:y", y0 - 22, 0.12).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_art, "position:y", y0, 0.26).set_trans(Tween.TRANS_BOUNCE)
	var fl := _art.create_tween()
	fl.tween_property(_art, "self_modulate", Color(1.3, 1.15, 1.2), 0.08)
	fl.tween_property(_art, "self_modulate", Color.WHITE, 0.3)
	if Game.is_tamed(_sel):
		main.toast("%s: \"%s\"" % [DB.name_of(_sel), DB.pet_line(_sel, 1 + randi() % 3)], Color("#ff8fb8"))

func _pat() -> void:
	if not Game.pet_pat(_sel):
		main.toast("%s is happy, but that's enough pats for today." % DB.name_of(_sel), UI.MUTED)
		return
	Game.sfx("star_up")
	var h := UI.label("♥", 34, Color("#ff8fb8"), 6)
	h.position = _art.position + Vector2(_art.size.x * randf_range(0.35, 0.6), _art.size.y * 0.15)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mid.add_child(h)
	var ht := h.create_tween().set_parallel(true)
	ht.tween_property(h, "position:y", h.position.y - 70, 0.9)
	ht.tween_property(h, "modulate:a", 0.0, 0.5).set_delay(0.4)
	ht.chain().tween_callback(h.queue_free)
	main.toast("%s: \"%s\"" % [DB.name_of(_sel), DB.pet_line(_sel, 3)], Color("#ff8fb8"))
	if _tab == "tame":
		_render_detail()

# ---------------------------------------------------------------- taming

func _render_tame(id: String) -> void:
	if not Game.is_tamed(id):
		_detail.add_child(UI.wrap_label("Defeat her enough times and she starts to respect you. Then you can TAME her and grow a bond — talk, pat and give gifts, just like with your heroes.", 13, UI.MUTED))
		var k := Game.kills_of(id)
		_detail.add_child(UI.label("Trust: %d / %d defeats" % [mini(k, DB.TAME_KILLS), DB.TAME_KILLS], 15, UI.GREEN if k >= DB.TAME_KILLS else Color.WHITE, 3))
		var bar := ProgressBar.new()
		bar.max_value = DB.TAME_KILLS
		bar.value = mini(k, DB.TAME_KILLS)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		_detail.add_child(bar)
		_detail.add_child(UI.label("Cost: %s Gold" % Game.fmt(DB.TAME_GOLD), 14, UI.GOLD, 2))
		var err := Game.tame_error(id)
		var tb := UI.button("♥ TAME", func():
			var e2 := Game.tame(id)
			if e2 != "":
				main.toast(e2, UI.RED)
				return
			Game.sfx("awakening")
			main.dialogue([[id, DB.pet_line(id, 0)]], func(): _render_detail(), "", true)
			_render(), "GoldButton", Vector2(0, 50))
		tb.disabled = err != ""
		_detail.add_child(tb)
		if err != "":
			_detail.add_child(UI.wrap_label(err, 12, Color("#ff8a9a")))
		_detail.add_child(UI.wrap_label("Tamed foes unlock their evolved forms through bond and give rewards at Bond Lv.3 / 5 / 7 / 10.", 12, UI.MUTED))
		return
	var p := Game.pet(id)
	var lv := int(p["bond"])
	_detail.add_child(UI.label("Bond Lv.%d / %d" % [lv, DB.PET_MAX_BOND], 17, Color("#ff8fb8"), 3))
	var bb := ProgressBar.new()
	bb.max_value = DB.pet_bond_next(lv)
	bb.value = int(p["exp"]) if lv < DB.PET_MAX_BOND else bb.max_value
	bb.show_percentage = false
	bb.custom_minimum_size = Vector2(0, 12)
	_detail.add_child(bb)
	_detail.add_child(UI.label("Tamed on %s" % str(p.get("date", "")), 12, UI.MUTED, 2))
	var is_comp := Game.companion() == id
	var cb := UI.button("★ COMPANION  (+%.1f%% team ATK/HP)" % (DB.COMPANION_PER_BOND * lv * 100.0) if is_comp else "SET AS COMPANION", func():
		Game.set_companion("" if is_comp else id)
		Game.sfx("star_up")
		if not is_comp:
			main.toast("%s: \"%s\"" % [DB.name_of(id), DB.pet_line(id, 0)], Color("#ff8fb8"))
		_render_detail(), "" if is_comp else "GoldButton", Vector2(0, 40))
	cb.add_theme_font_size_override("font_size", 12)
	_detail.add_child(cb)
	_detail.add_child(UI.wrap_label("Your Companion follows you into battle and the lobby, and gives the whole team +0.5% ATK/HP per Bond level.", 11, UI.MUTED))
	var talk := UI.button("TALK  (1 / day)" if Game.pet_talk_ready(id) else "TALKED TODAY ✓", func():
		var line := Game.pet_talk(id)
		if line == "":
			return
		main.dialogue([["commander", "Hey, %s. How are you today?" % DB.name_of(id)], [id, line]], func(): _render_detail(), "", true), "GoldButton" if Game.pet_talk_ready(id) else "", Vector2(0, 44))
	talk.disabled = not Game.pet_talk_ready(id)
	_detail.add_child(talk)
	_detail.add_child(UI.label("Head-pats left today: %d  (rub her head)" % Game.pet_pats_left(id), 12, UI.MUTED, 2))
	_detail.add_child(UI.label("GIFTS  (favourite ×2: %s)" % DB.ITEMS[DB.fav_gift(id)]["name"], 13, UI.GOLD, 2))
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 6)
	gr.add_theme_constant_override("v_separation", 6)
	for g in DB.GIFTS:
		var gid: String = g
		var gname: String = str(DB.ITEMS[gid]["name"]).split(" ")[-1]
		var gb := UI.button("%s ×%d" % [gname, Game.amount(gid)], func():
			var e3 := Game.pet_gift(id, gid)
			if e3 != "":
				main.toast(e3, UI.RED)
				return
			main.toast("%s: \"%s\"" % [DB.name_of(id), DB.pet_line(id, 4)], Color("#ff8fb8"))
			_render_detail(), "", Vector2(0, 36))
		gb.add_theme_font_size_override("font_size", 11)
		gb.disabled = Game.amount(gid) <= 0
		gb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gr.add_child(gb)
	_detail.add_child(gr)
	_detail.add_child(UI.label("BOND STORIES", 13, UI.GOLD, 2))
	for ep in DB.PET_STORY_REQ.size():
		var epi: int = ep
		var st := Game.pet_story_state(id, epi)
		var row := UI.hbox(6)
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UI.label("%d. %s" % [epi + 1, DB.PET_STORY_TITLES[epi]], 12, Color.WHITE if st != "locked" else UI.MUTED, 2))
		info.add_child(UI.label("Bond Lv.%d" % DB.PET_STORY_REQ[epi] if st == "locked" else ("✓ read — tap to replay" if st == "read" else "NEW!"), 10, UI.GREEN if st == "ready" else UI.MUTED, 2))
		row.add_child(info)
		var rb := UI.button("READ" if st == "ready" else ("REPLAY" if st == "read" else "🔒"), func():
			main.dialogue(DB.pet_story(id, epi), func():
				var g := Game.read_pet_story(id, epi)
				if not g.is_empty():
					main.show_rewards(DB.PET_STORY_TITLES[epi], g)
				_render_detail(), "forest"), "GoldButton" if st == "ready" else "", Vector2(76, 32))
		rb.add_theme_font_size_override("font_size", 11)
		rb.disabled = st == "locked"
		row.add_child(rb)
		_detail.add_child(row)
	_detail.add_child(UI.label("BOND REWARDS", 13, UI.GOLD, 2))
	for lvk in DB.PET_REWARDS.keys():
		var row := UI.hbox(6)
		row.add_child(UI.label("Lv.%d" % lvk, 13, UI.GREEN if lv >= int(lvk) else Color.WHITE, 2))
		row.add_child(UI.reward_row(DB.PET_REWARDS[lvk], 22, 11))
		if lv >= int(lvk):
			row.add_child(UI.label("✓", 14, UI.GREEN, 2))
		_detail.add_child(row)


## Entry for a foe not met yet: where to find her and what hunting her is worth.
func _unknown_detail(id: String) -> void:
	_detail.add_child(UI.wrap_label("Defeat this enemy once to reveal her entry, art and forms.", 13, UI.MUTED))
	var role := str(DB.ENEMIES[id].get("role", ""))
	if role != "":
		var rp := UI.styled_panel(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.2), 8, 1, 6.0)
		rp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		rp.add_child(UI.label("Class hint: " + role, 12, UI.TEXT, 1))
		_detail.add_child(rp)
	var where: Array = []
	for d in DB.DUNGEONS:
		if (d["pool"] as Array).has(id):
			where.append([str(d["name"]), "dungeon", {"dungeon": d["id"]}])
	where.append(["Story stages", "story", {}])
	_detail.add_child(UI.label("WHERE TO FIND HER", 13, Color("#9fd0ff"), 2))
	for e in where:
		var scr: String = e[1]
		var prm: Dictionary = e[2]
		var row := UI.hbox(6)
		var nl := UI.label("• " + str(e[0]), 13, UI.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		if Game.feature_unlocked(scr):
			row.add_child(UI.button("GO", func(): main.go(scr, prm), "", Vector2(56, 32)))
		_detail.add_child(row)
	_detail.add_child(UI.label("HUNTING REWARDS", 13, UI.GOLD, 2))
	for t in DB.BESTIARY_TIERS:
		var tp := UI.styled_panel(Color(0.1, 0.08, 0.16, 0.85), Color(1, 1, 1, 0.12), 10, 1, 6.0)
		var th := UI.hbox(8)
		tp.add_child(th)
		var kl := UI.label("%d kills" % int(t["kills"]), 12, UI.MUTED, 1)
		kl.custom_minimum_size.x = 62
		kl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		th.add_child(kl)
		var rr := UI.reward_row(t["give"], 22, 12)
		rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		th.add_child(rr)
		_detail.add_child(tp)
	var tm := UI.styled_panel(Color("#ff8fb8", 0.08), Color("#ff8fb8", 0.4), 10, 1, 8.0)
	tm.add_child(UI.wrap_label("♥ After %d defeats she can be TAMED and befriended like a hero." % DB.TAME_KILLS, 12, Color("#ffc0d8")))
	_detail.add_child(tm)
