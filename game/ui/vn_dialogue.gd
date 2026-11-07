class_name VNDialogue
extends Control
## Visual-novel cutscene: background, two speaker slots (left/right) with the
## inactive one dimmed, name plate, typewriter text with tick sound,
## AUTO / LOG / SKIP controls. lines = [[speaker_id, text], ...]

signal finished
signal chose(index: int, bond: int)

## Choice line format: ["?", hero_id, [option texts], [reply texts], [bond gains]]
var _choice_box: VBoxContainer

var lines: Array = []
var bg_key := ""
var _i := -1
var _slots := {}          # speaker -> "L"/"R"
var _left: TextureRect
var _right: TextureRect
var _name_plate: PanelContainer
var _name_l: Label
var _text_l: Label
var _hint: Label
var _auto := false
var _auto_btn: Button
var _typing: Tween
var _auto_t := 0.0
var _tick_t := 0.0
var _log_layer: Control
var compact := false
var cg_hero := ""        # CG mode: full-screen illustration with a slow camera pan
var cg_key := ""         # art/cg/<cg_key>.png overrides the placeholder     # tutorial mode: small portrait, light dim, screen stays visible
var _mini: TextureRect

func _init(p_lines: Array = [], p_bg: String = "") -> void:
	lines = p_lines
	bg_key = p_bg
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("popup", true)
	set_meta("no_back", true)

func _ready() -> void:
	if bg_key != "":
		var bg := UI.tex_rect(DB.bg(bg_key), Vector2.ZERO, true)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		bg.modulate = Color(0.7, 0.7, 0.8)
	if cg_hero != "":
		_build_cg()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.12 if compact else (0.35 if bg_key != "" else 0.6))
	if cg_hero != "":
		dim.color = Color(0, 0, 0, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_left = _make_slot(0.0, 0.5)
	_right = _make_slot(0.5, 1.0)
	_right.flip_h = true
	if compact or cg_hero != "":
		_left.visible = false
		_right.visible = false
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.75))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.55)
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.visible = not compact
	add_child(shade)

	var box := UI.styled_panel(Color(0.05, 0.03, 0.1, 0.94), UI.GOLD_DARK, 16, 2, 22)
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 60 if not compact else 200
	box.offset_right = -60 if not compact else -200
	box.offset_top = -180 if not compact else -130
	box.offset_bottom = -22 if not compact else -12
	if compact:
		_mini = UI.tex_rect(null, Vector2.ZERO, true)
		_mini.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_mini.offset_left = 60
		_mini.offset_right = 190
		_mini.offset_top = -150
		_mini.offset_bottom = -12
		add_child(_mini)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var v := UI.vbox(6)
	box.add_child(v)
	_text_l = UI.wrap_label("", 20, Color.WHITE)
	_text_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_text_l)
	_hint = UI.label("▼", 18, UI.GOLD, 3)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_hint)
	var ht := _hint.create_tween().set_loops()
	ht.tween_property(_hint, "modulate:a", 0.2, 0.5)
	ht.tween_property(_hint, "modulate:a", 1.0, 0.5)

	_name_plate = UI.styled_panel(Color("#3a2468"), UI.GOLD, 10, 2, 10)
	_name_plate.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_name_plate.offset_left = 84
	_name_plate.offset_top = -204
	_name_plate.offset_bottom = -168
	_name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_l = UI.label("", 20, UI.GOLD, 4)
	_name_plate.add_child(_name_l)
	add_child(_name_plate)

	var bar := UI.hbox(8)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bar.offset_left = -380
	bar.offset_right = -20
	bar.offset_top = 18
	bar.alignment = BoxContainer.ALIGNMENT_END
	add_child(bar)
	_auto_btn = UI.button("AUTO", _toggle_auto, "TabButton", Vector2(100, 42))
	_auto_btn.toggle_mode = true
	bar.add_child(_auto_btn)
	bar.add_child(UI.button("LOG", _show_log, "", Vector2(90, 42)))
	bar.add_child(UI.button("SKIP ▶▶", _finish, "", Vector2(120, 42)))
	if compact:
		# tutorials: keep the screen's header visible, a single small SKIP near the text box
		_auto_btn.visible = false
		bar.get_child(1).visible = false
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		bar.offset_left = -330
		bar.offset_right = -210
		bar.offset_top = -176
		bar.offset_bottom = -138
	gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_advance())
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	_assign_slots()
	_advance()

func _build_cg() -> void:
	var real: Texture2D = null
	for ext in ["png", "jpg"]:
		var p := "res://art/cg/%s.%s" % [cg_key, ext]
		if cg_key != "" and ResourceLoader.exists(p):
			real = load(p)
			break
	var back := ColorRect.new()
	back.color = Color(0.03, 0.01, 0.06)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = true
	add_child(holder)
	var img := UI.tex_rect(real if real else DB.art(cg_hero, Game.unlocked_skins(cg_hero) - 1), Vector2.ZERO, real != null)
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if real == null:
		# placeholder: blurred-looking backdrop of the same art + crisp art in front
		var bgimg := UI.tex_rect(img.texture, Vector2.ZERO, true)
		bgimg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bgimg.modulate = Color(0.35, 0.25, 0.4)
		bgimg.scale = Vector2(1.3, 1.3)
		holder.add_child(bgimg)
		UI.live(img, DB.theme_color(cg_hero).lightened(0.5), 0.8)
	holder.add_child(img)
	holder.resized.connect(func(): img.pivot_offset = img.size * Vector2(0.5, 0.3))
	img.scale = Vector2(1.0, 1.0)
	var kb := img.create_tween().set_loops()
	kb.tween_property(img, "scale", Vector2(1.18, 1.18), 9.0).set_trans(Tween.TRANS_SINE)
	kb.parallel().tween_property(img, "position:y", 40.0, 9.0).set_trans(Tween.TRANS_SINE)
	kb.tween_property(img, "scale", Vector2(1.05, 1.05), 9.0).set_trans(Tween.TRANS_SINE)
	kb.parallel().tween_property(img, "position:y", -10.0, 9.0).set_trans(Tween.TRANS_SINE)
	var amb := AmbientFX.new(Color(1.0, 0.8, 0.95), 30)
	add_child(amb)
	var cin := UI.label("✦ MEMORY ✦", 16, Color("#ffd1e8"), 4)
	cin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	cin.position = Vector2(28, 22)
	add_child(cin)

func _make_slot(a: float, b: float) -> TextureRect:
	var t := UI.tex_rect(null)
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.anchor_left = a
	t.anchor_right = b
	t.offset_top = 20
	t.offset_bottom = -60
	t.modulate.a = 0.0
	add_child(t)
	UI.live(t, Color(1, 0.9, 1), 0.8)
	return t

## First speaker goes left, the next different speaker right, then alternate.
func _assign_slots() -> void:
	var next := "L"
	for ln in lines:
		var sid: String = ln[0]
		if _slots.has(sid) or sid in ["nar", "commander", "?"] or DB.art(sid, 0) == null:
			continue
		_slots[sid] = next
		next = "R" if next == "L" else "L"

func _toggle_auto() -> void:
	_auto = _auto_btn.button_pressed
	_auto_t = 0.0

func _process(delta: float) -> void:
	if _text_l.visible_ratio < 1.0:
		_tick_t -= delta
		if _tick_t <= 0.0:
			_tick_t = 0.07
			if randf() < 0.25:
				Game.sfx("ui_click")
	elif _auto and not is_instance_valid(_log_layer):
		_auto_t += delta
		if _auto_t > 1.4 + _text_l.text.length() * 0.02:
			_auto_t = 0.0
			_advance()

func _advance() -> void:
	if _finished or is_instance_valid(_log_layer) or is_instance_valid(_choice_box):
		return
	if _text_l.visible_ratio < 1.0 and _i >= 0:
		if _typing:
			_typing.kill()
		_text_l.visible_ratio = 1.0
		return
	_i += 1
	if _i >= lines.size():
		_finish()
		return
	_show(_i)

func _show(i: int) -> void:
	var ln: Array = lines[i]
	if str(ln[0]) == "?":
		_show_choice(ln)
		return
	var sid: String = ln[0]
	var is_cmd := sid == "commander"
	_name_plate.visible = sid != "nar"
	_text_l.add_theme_color_override("font_color", Color("#d8cdf0") if sid == "nar" else Color.WHITE)
	_name_l.text = "Commander" if is_cmd else DB.name_of(sid)
	_name_plate.add_theme_stylebox_override("panel", UI.style(DB.theme_color(sid).darkened(0.5) if not is_cmd else Color("#24406a"), UI.GOLD, 10, 2, 10))
	var side: String = _slots.get(sid, "")
	if side == "R":
		_name_plate.anchor_left = 1.0
		_name_plate.anchor_right = 1.0
		_name_plate.offset_left = -84 - maxf(160.0, _name_l.get_minimum_size().x + 24)
		_name_plate.offset_right = -84
	else:
		_name_plate.anchor_left = 0.0
		_name_plate.anchor_right = 0.0
		_name_plate.offset_left = 84
		_name_plate.offset_right = 84 + maxf(160.0, _name_l.get_minimum_size().x + 24)
	_text_l.text = str(ln[1])
	_text_l.visible_ratio = 0.0
	_typing = _text_l.create_tween()
	_typing.tween_property(_text_l, "visible_ratio", 1.0, clampf(_text_l.text.length() * 0.025, 0.3, 2.0))
	_auto_t = 0.0
	if compact and _mini:
		_mini.texture = DB.face(sid) if sid != "commander" else null
		_name_plate.anchor_left = 0.0
		_name_plate.anchor_right = 0.0
		_name_plate.offset_left = 200
		_name_plate.offset_right = 200 + maxf(160.0, _name_l.get_minimum_size().x + 24)
		_name_plate.offset_top = -154
		_name_plate.offset_bottom = -118
		return
	if side != "":
		var slot := _left if side == "L" else _right
		var variant := "mirror" if sid.begins_with("mirror:") else ("hollow" if sid.begins_with("hollow:") else ("echo" if sid.begins_with("echo:") else ("ashen" if sid.begins_with("ashen:") else ("feral" if sid.begins_with("feral:") else ""))))
		var mirror := variant != ""
		var tex := DB.art(sid, 0 if mirror else (int(Game.hero(sid).get("skin", 0)) if Game.owns(sid) else 0))
		if slot.texture != tex or str(slot.get_meta("variant", "")) != variant:
			slot.texture = tex
			slot.set_meta("variant", variant)
			if mirror:
				UI.corrupt(slot, variant)
			else:
				UI.live(slot, Color(1, 0.9, 1), 0.8)
			slot.modulate.a = 0.0
			slot.position.x += -40.0 if side == "L" else 40.0
			var tw := slot.create_tween().set_parallel(true)
			tw.tween_property(slot, "modulate:a", 1.0, 0.25)
			tw.tween_property(slot, "position:x", slot.position.x + (40.0 if side == "L" else -40.0), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# active speaker bright + slight hop, the other dimmed
		_focus(slot, true)
		_focus(_right if side == "L" else _left, false)
	else:
		_focus(_left, false)
		_focus(_right, false)

func _focus(slot: TextureRect, on: bool) -> void:
	if slot.texture == null:
		return
	var tw := slot.create_tween().set_parallel(true)
	tw.tween_property(slot, "self_modulate", Color.WHITE if on else Color(0.45, 0.45, 0.55), 0.2)
	tw.tween_property(slot, "scale", Vector2(1.03, 1.03) if on else Vector2.ONE, 0.2)
	slot.pivot_offset = Vector2(slot.size.x * 0.5, slot.size.y)

func _show_choice(ln: Array) -> void:
	var hid: String = ln[1]
	var opts: Array = ln[2]
	_auto = false
	if _auto_btn:
		_auto_btn.button_pressed = false
	_text_l.text = "..."
	_text_l.visible_ratio = 1.0
	_choice_box = UI.vbox(10)
	_choice_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_choice_box.offset_left = -300
	_choice_box.offset_right = 300
	_choice_box.offset_top = -170
	_choice_box.offset_bottom = 40
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_choice_box)
	for k in opts.size():
		var idx: int = k
		var b := UI.button(str(opts[k]), func(): _pick(ln, hid, idx), "", Vector2(600, 56))
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_stylebox_override("normal", UI.style(Color(0.08, 0.05, 0.16, 0.95), Color("#ff8fb8"), 14, 2, 14))
		_choice_box.add_child(b)
	UI.stagger(_choice_box, 0.08)

func _pick(ln: Array, hid: String, idx: int) -> void:
	Game.sfx("ui_click")
	var bond: int = int(ln[4][idx])
	_choice_box.queue_free()
	_choice_box = null
	chose.emit(idx, bond)
	# splice the hero's reply in right after the choice
	lines.insert(_i + 1, [hid, str(ln[3][idx])])
	var mark := UI.label(("♥ +%d Bond" % bond) if bond >= 20 else ("+%d Bond" % bond), 26, Color("#ff8fb8") if bond >= 20 else UI.MUTED, 6)
	mark.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	mark.offset_left = -200
	mark.offset_right = 200
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mark)
	var tw := mark.create_tween()
	tw.tween_property(mark, "position:y", mark.position.y - 60, 0.9)
	tw.parallel().tween_property(mark, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.tween_callback(mark.queue_free)
	if bond >= 20:
		Game.sfx("star_up")
	_advance()

func _show_log() -> void:
	_log_layer = Control.new()
	_log_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_log_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_log_layer)
	var d := ColorRect.new()
	d.color = Color(0, 0, 0, 0.85)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_log_layer.add_child(d)
	var v := UI.vbox(10)
	var sc := UI.scroll(UI.margin(v, 80, 30, 80, 30))
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.offset_bottom = -80
	_log_layer.add_child(sc)
	for k in range(0, mini(_i + 1, lines.size())):
		var ln: Array = lines[k]
		if str(ln[0]) == "?":
			continue
		var sid: String = ln[0]
		if sid != "nar":
			v.add_child(UI.label("Commander" if sid == "commander" else DB.name_of(sid), 16, UI.GOLD, 3))
		v.add_child(UI.wrap_label(str(ln[1]), 16, Color.WHITE))
	var c := UI.button("CLOSE", func(): _log_layer.queue_free(), "GoldButton", Vector2(160, 46))
	c.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	c.offset_left = -80
	c.offset_right = 80
	c.offset_top = -66
	c.offset_bottom = -20
	_log_layer.add_child(c)
	sc.set_deferred("scroll_vertical", 100000)

var _finished := false

## Ends the dialogue exactly once (taps during the fade-out must not fire `finished` again).
func _finish() -> void:
	if _finished:
		return
	_finished = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		finished.emit()
		queue_free())
