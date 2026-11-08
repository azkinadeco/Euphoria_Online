class_name ArtViewer
extends Control
## Full-screen character viewer for heroes AND enemies.
## Pinch / wheel / trackpad to zoom (around the fingers), drag to pan, double-tap to zoom in/out,
## tap to interact (reaction + alternate expression + voice), rub the head for hearts.
## Outfit / form arrows, an expression toggle and a "hide UI" button for clean screenshots.
## Opened with ArtViewer.open(main, id, index, indices) — it lives on the overlay layer, so BACK closes it.

const MIN_Z := 1.0
const MAX_Z := 4.0

var id := ""
var is_hero := true
var indices: Array = []     # outfit / form indices the player may browse
var _pos := 0               # position inside indices
var _expr := 0              # 0 = base art, n = n-th alternate expression
var _z := 1.0
var _stage: Control         # zoom / pan target
var _art: TextureRect
var _pinch: PinchZoom
var _ui: Array = []         # nodes hidden by HIDE UI
var _name_l: Label
var _sub_l: Label
var _zoom_l: Label
var _dots: HBoxContainer
var _bubble: PanelContainer
var _bubble_l: Label
var _expr_b: Button
var _down := false
var _start := Vector2.ZERO
var _moved := false
var _rub := 0.0
var _last_tap := 0
var _last_tap_pos := Vector2.ZERO
var _busy := false
var _pat_t := 0
var _hidden := false

static func open(main_node: Node, cid: String, index: int, allowed: Array) -> ArtViewer:
	var v := ArtViewer.new()
	v.id = DB.base_id(cid)
	v.is_hero = DB.HEROES.has(v.id)
	v.indices = allowed if not allowed.is_empty() else [0]
	v._pos = maxi(0, v.indices.find(index))
	main_node.overlay.add_child(v)
	return v

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("popup", true)
	var col := DB.theme_color(id) if is_hero else Color("#a77bff")
	# backdrop: deep night + a soft theme-coloured spotlight behind the character
	var base := ColorRect.new()
	base.color = Color(0.02, 0.01, 0.05, 1.0)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	# the hero's home map (by element), blurred-dark so the art pops
	var scene := UI.tex_rect(DB.bg(str(DB.ELEM_BG.get(DB.element_of(id), "lobby"))), Vector2.ZERO, true)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.modulate = Color(0.32, 0.28, 0.4)
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05, 0.45)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var glow := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.55)
	gt.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(col.lightened(0.1), 0.42))
	gr.set_color(1, Color(col, 0.0))
	gt.gradient = gr
	glow.texture = gt
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var gtw := glow.create_tween().set_loops()
	gtw.tween_property(glow, "modulate:a", 0.65, 2.4).set_trans(Tween.TRANS_SINE)
	gtw.tween_property(glow, "modulate:a", 1.0, 2.4).set_trans(Tween.TRANS_SINE)
	var floor_l := ColorRect.new()
	floor_l.color = Color(col, 0.10)
	floor_l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	floor_l.offset_top = -3
	floor_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_l)
	_sparkles(col)

	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_art = UI.tex_rect(null)
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.offset_top = 18
	_art.offset_bottom = -18
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_art)
	_art.resized.connect(func(): _art.pivot_offset = Vector2(_art.size.x * 0.5, _art.size.y))
	UI.live(_art, col.lightened(0.5))
	var tw := _art.create_tween().set_loops()
	tw.tween_property(_art, "scale", Vector2(1.004, 1.012), 1.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_art, "scale", Vector2.ONE, 1.9).set_trans(Tween.TRANS_SINE)
	gui_input.connect(_input_art)
	_pinch = PinchZoom.new(func(f: float, c: Vector2): _zoom_at(_z * f, c))
	add_child(_pinch)

	# --- top bar: name card (left), buttons (right)
	var card := UI.styled_panel(Color(0.04, 0.02, 0.09, 0.78), Color(col, 0.7), 14, 1, 12)
	card.position = Vector2(18, 16)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	_ui.append(card)
	var cv := UI.vbox(0)
	card.add_child(cv)
	var tags := UI.hbox(6)
	if is_hero:
		tags.add_child(UI.rarity_tag(DB.rarity_of(id), 13))
	tags.add_child(UI.element_tag(DB.element_of(id), 13))
	tags.add_child(UI.label("HERO" if is_hero else "FOE", 12, UI.MUTED, 2))
	cv.add_child(tags)
	_name_l = UI.label(DB.name_of(id), 30, Color.WHITE, 6)
	cv.add_child(_name_l)
	_sub_l = UI.label("", 13, col.lightened(0.45), 3)
	cv.add_child(_sub_l)

	var tb := UI.hbox(8)
	tb.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tb.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tb.offset_top = 16
	tb.offset_right = -18
	add_child(tb)
	_expr_b = _round_btn("☺", "Change expression", _cycle_expr)
	tb.add_child(_expr_b)
	tb.add_child(_round_btn("⟲", "Reset zoom", func(): _zoom_to(1.0, true)))
	var hide_b := _round_btn("◐", "Hide UI (tap anywhere to show again)", _toggle_ui)
	tb.add_child(hide_b)
	var close_b := _round_btn("✕", "Close", close)
	close_b.add_theme_stylebox_override("normal", UI.style(Color(0.35, 0.06, 0.12, 0.92), Color("#ff8fa8"), 26, 2, 0))
	tb.add_child(close_b)
	_ui.append(tb)

	# --- outfit arrows
	if indices.size() > 1:
		for d in [-1, 1]:
			var dir: int = d
			var ab := _round_btn("◀" if dir < 0 else "▶", "Previous outfit" if dir < 0 else "Next outfit", func(): _step(dir), Vector2(58, 76))
			ab.anchor_top = 0.5
			ab.anchor_bottom = 0.5
			ab.offset_top = -38
			ab.offset_bottom = 38
			if dir < 0:
				ab.offset_left = 18
				ab.offset_right = 76
			else:
				ab.anchor_left = 1.0
				ab.anchor_right = 1.0
				ab.offset_left = -76
				ab.offset_right = -18
			add_child(ab)
			_ui.append(ab)

	# --- bottom: outfit dots, zoom %, hint
	var bot := UI.vbox(6)
	bot.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bot.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bot.offset_bottom = -14
	bot.alignment = BoxContainer.ALIGNMENT_END
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot)
	_ui.append(bot)
	_dots = UI.hbox(6)
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	bot.add_child(_dots)
	var hint_p := UI.styled_panel(Color(0, 0, 0, 0.55), Color(1, 1, 1, 0.12), 16, 1, 8)
	hint_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot.add_child(hint_p)
	var hh := UI.hbox(10)
	hint_p.add_child(hh)
	_zoom_l = UI.label("100%", 13, UI.GOLD, 2)
	hh.add_child(_zoom_l)
	hh.add_child(UI.label("Pinch / scroll = zoom  •  drag = pan  •  double-tap = close-up  •  tap = interact  •  rub head = ♥", 12, UI.TEXT, 2))

	# --- speech bubble
	_bubble = UI.styled_panel(Color(1, 0.97, 0.99, 0.96), col, 18, 2, 12)
	_bubble.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_bubble.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bubble.offset_bottom = -92
	_bubble.custom_minimum_size = Vector2(380, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.modulate.a = 0.0
	add_child(_bubble)
	_bubble_l = UI.label("", 17, Color("#3a2340"), 0)
	_bubble_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_l.custom_minimum_size = Vector2(360, 0)
	_bubble.add_child(_bubble_l)

	_show()
	modulate.a = 0.0
	_art.scale = Vector2(0.94, 0.94)
	var ot := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ot.tween_property(self, "modulate:a", 1.0, 0.22)
	ot.tween_property(_art, "scale", Vector2.ONE, 0.35)
	Game.sfx("ui_click")
	if is_hero and Game.owns(id):
		_say(Game.voice(id, "greet"))

func _round_btn(t: String, tip: String, cb: Callable, sz: Vector2 = Vector2(52, 52)) -> Button:
	var b := UI.button(t, cb, "", sz)
	b.tooltip_text = tip
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_stylebox_override("normal", UI.style(Color(0.06, 0.03, 0.12, 0.85), Color(1, 1, 1, 0.25), 26, 1, 0))
	b.add_theme_stylebox_override("hover", UI.style(Color(0.16, 0.08, 0.26, 0.95), UI.GOLD, 26, 2, 0))
	b.add_theme_stylebox_override("pressed", UI.style(Color(0.24, 0.12, 0.36, 0.95), UI.GOLD, 26, 2, 0))
	return b

func _sparkles(col: Color) -> void:
	var p := CPUParticles2D.new()
	p.amount = 26
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(900, 20)
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.color = Color(col.lightened(0.5), 0.55)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	add_child(p)
	(func(): p.position = Vector2(size.x * 0.5, size.y + 10); p.emission_rect_extents = Vector2(size.x * 0.5, 10)).call_deferred()

# ---------------------------------------------------------------- content

func _index() -> int:
	return int(indices[_pos])

func _show() -> void:
	var alts := DB.alt_arts(id, _index())
	_expr = clampi(_expr, 0, alts.size())
	_art.texture = DB.tex(str(alts[_expr - 1])) if _expr > 0 else DB.art(id, _index())
	_expr_b.visible = not alts.is_empty()
	var arts := DB.art_list(id)
	var nm := "Outfit %d / %d" % [_index() + 1, arts.size()] if is_hero else "Form %d / %d" % [_index() + 1, arts.size()]
	if is_hero and DB.special_index(id) == _index():
		nm = "★ SPECIAL  •  " + str(DB.SPECIAL_SKINS.get(id, "Special Skin"))
	_sub_l.text = DB.title_of(id) + "   •   " + nm + ("   •   Expression %d/%d" % [_expr + 1, alts.size() + 1] if not alts.is_empty() else "")
	for c in _dots.get_children():
		c.queue_free()
	if indices.size() > 1:
		for i in indices.size():
			var dot := Panel.new()
			dot.custom_minimum_size = Vector2(22 if i == _pos else 9, 9)
			dot.add_theme_stylebox_override("panel", UI.style(UI.GOLD if i == _pos else Color(1, 1, 1, 0.35), Color(0, 0, 0, 0), 5, 0, 0))
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dots.add_child(dot)

func _step(dir: int) -> void:
	_pos = posmod(_pos + dir, indices.size())
	_expr = 0
	_zoom_to(1.0, false)
	Game.sfx("ui_click")
	_show()
	var x0 := _art.position.x
	_art.modulate.a = 0.0
	var t := _art.create_tween().set_parallel(true)
	t.tween_property(_art, "modulate:a", 1.0, 0.25)
	t.tween_property(_art, "position:x", x0, 0.3).from(x0 + dir * 60.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _cycle_expr() -> void:
	var alts := DB.alt_arts(id, _index())
	if alts.is_empty():
		return
	_expr = (_expr + 1) % (alts.size() + 1)
	Game.sfx("ui_click")
	_show()
	_bounce(0.2)

func _toggle_ui() -> void:
	_hidden = not _hidden
	for n in _ui:
		var c := n as Control
		if _hidden:
			c.visible = false
		else:
			c.visible = true
			c.modulate.a = 0.0
			c.create_tween().tween_property(c, "modulate:a", 1.0, 0.2)

func close() -> void:
	set_meta("popup", false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.18)
	t.tween_callback(queue_free)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- zoom & pan

func _zoom_at(nz: float, centre: Vector2) -> void:
	nz = clampf(nz, MIN_Z, MAX_Z)
	var local := centre - get_global_rect().position
	var p0 := (local - _stage.position) / _z
	_z = nz
	_stage.pivot_offset = Vector2.ZERO
	_stage.scale = Vector2(_z, _z)
	_stage.position = local - p0 * _z
	_clamp_pan()

func _zoom_to(nz: float, animate: bool, centre: Vector2 = Vector2.ZERO) -> void:
	if centre == Vector2.ZERO:
		centre = size * 0.5
	var p0 := (centre - _stage.position) / _z
	var target_pos := centre - p0 * nz if nz > 1.01 else Vector2.ZERO
	_z = nz
	if animate:
		var t := _stage.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(_stage, "scale", Vector2(nz, nz), 0.3)
		t.tween_property(_stage, "position", _clamped(target_pos), 0.3)
	else:
		_stage.scale = Vector2(nz, nz)
		_stage.position = _clamped(target_pos)
	_zoom_l.text = "%d%%" % roundi(_z * 100)

func _clamped(p: Vector2) -> Vector2:
	if _z <= 1.01:
		return Vector2.ZERO
	var w := size * (_z - 1.0)
	return Vector2(clampf(p.x, -w.x, 0.0), clampf(p.y, -w.y, 0.0))

func _clamp_pan() -> void:
	_stage.position = _clamped(_stage.position)
	_zoom_l.text = "%d%%" % roundi(_z * 100)

# ---------------------------------------------------------------- gestures

func _input_art(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP and not e.ctrl_pressed:
			_zoom_at(_z * 1.12, e.global_position)
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN and not e.ctrl_pressed:
			_zoom_at(_z / 1.12, e.global_position)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_down = true
				_start = e.position
				_moved = false
				_rub = 0.0
			elif _down:
				_down = false
				if _moved or _pinch.active():
					return
				if _hidden:
					_toggle_ui()
					return
				var now := Time.get_ticks_msec()
				if now - _last_tap < 320 and e.position.distance_to(_last_tap_pos) < 60.0:
					_last_tap = 0
					_zoom_to(1.0 if _z > 1.4 else 2.4, true, e.position)
					return
				_last_tap = now
				_last_tap_pos = e.position
				var at: Vector2 = e.position
				get_tree().create_timer(0.33).timeout.connect(func():
					if _last_tap == now and is_inside_tree():
						_tap(at))
	elif e is InputEventMouseMotion and _down:
		if (e.position - _start).length() > 12.0:
			_moved = true
		if _pinch.active():
			return
		if _z > 1.01:
			_stage.position += e.relative
			_clamp_pan()
		elif _art_ry(e.position) < 0.32:
			_rub += (e.relative as Vector2).length()
			if _rub > 70.0:
				_hearts(e.position, 1)
				if _rub > 600.0:
					_rub = 0.0
					_pat()

## Vertical position on the character (0 = top of the art, 1 = feet), accounting for zoom/pan.
func _art_ry(p: Vector2) -> float:
	var local := (p - _stage.position) / _z
	return clampf((local.y - _art.position.y) / maxf(1.0, _art.size.y), 0.0, 1.0)

func _tap(p: Vector2) -> void:
	if _busy:
		return
	_busy = true
	var ry := _art_ry(p)
	# expression flash: cycles through every alternate the outfit has
	var alts := DB.alt_arts(id, _index())
	if not alts.is_empty() and _expr == 0:
		UI.flash_expression(_art, DB.tex(str(alts[randi() % alts.size()])), 1.6)
	_bounce(ry)
	_hearts(p, 3 if ry < 0.32 else 1)
	_say(_line(ry))
	get_tree().create_timer(0.45).timeout.connect(func(): _busy = false)

func _line(ry: float) -> String:
	if is_hero:
		if not Game.owns(id):
			return Game.voice(id, "summon")
		Game.tap_hero(id)
		var cat := "bond" if ry < 0.32 and int(Game.hero(id).get("bond", 0)) >= 3 else ("greet" if ry < 0.32 else ("tap" if ry < 0.7 else "hurt"))
		return Game.voice(id, cat)
	if Game.is_tamed(id):
		return DB.pet_line(id, 1 + randi() % 3)
	return ["...!", "Hssss... don't touch me, tamer.", "You'll have to beat me first.", "Hmph. Bold, aren't you?", "...Again? You're strange."][randi() % 5]

func _pat() -> void:
	if is_hero and Game.owns(id):
		Game.add_bond(id, 2)
		_say(Game.voice(id, "bond"))
	elif not is_hero and Game.is_tamed(id):
		if Game.pet_pat(id):
			_say(DB.pet_line(id, 3))
		else:
			_say("%s is happy, but that's enough pats for today." % DB.name_of(id))
	Game.sfx("star_up")

func _bounce(ry: float) -> void:
	var tw := _art.create_tween()
	if ry < 0.32:
		tw.tween_property(_art, "scale", Vector2(1.025, 0.975), 0.12)
		tw.tween_property(_art, "scale", Vector2.ONE, 0.2)
	elif ry < 0.7:
		for i in 3:
			tw.tween_property(_art, "rotation", 0.016, 0.06)
			tw.tween_property(_art, "rotation", -0.016, 0.06)
		tw.tween_property(_art, "rotation", 0.0, 0.06)
	else:
		var y0 := _art.position.y
		tw.tween_property(_art, "position:y", y0 - 26, 0.14).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_art, "position:y", y0, 0.3).set_trans(Tween.TRANS_BOUNCE)
	var fl := _art.create_tween()
	fl.tween_property(_art, "self_modulate", Color(1.25, 1.12, 1.2), 0.08)
	fl.tween_property(_art, "self_modulate", Color.WHITE, 0.3)

func _hearts(p: Vector2, n: int) -> void:
	var now := Time.get_ticks_msec()
	if n == 1 and now - _pat_t < 130:
		return
	_pat_t = now
	for i in n:
		var l := UI.label(["♥", "♡", "✦"][randi() % 3], randi_range(24, 38), Color("#ff8fb8") if randf() < 0.7 else UI.GOLD, 5)
		l.position = p + Vector2(randf_range(-50, 30), randf_range(-30, 0))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		var lt := l.create_tween().set_parallel(true)
		lt.tween_property(l, "position:y", l.position.y - randf_range(60, 110), 1.0).set_trans(Tween.TRANS_SINE)
		lt.tween_property(l, "position:x", l.position.x + randf_range(-30, 30), 1.0)
		lt.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.5)
		lt.chain().tween_callback(l.queue_free)

func _say(t: String) -> void:
	if t == "":
		return
	_bubble_l.text = "%s:  \"%s\"" % [DB.name_of(id), t]
	if _bubble.has_meta("tw"):
		var old: Tween = _bubble.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	var tw := _bubble.create_tween()
	tw.tween_property(_bubble, "modulate:a", 1.0, 0.15)
	tw.tween_interval(3.0)
	tw.tween_property(_bubble, "modulate:a", 0.0, 0.4)
	_bubble.set_meta("tw", tw)
