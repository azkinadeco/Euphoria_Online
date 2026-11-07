extends Screen
## Photo Studio: compose a picture with any owned hero / outfit / map, a colour filter,
## a frame, a caption and (optionally) the Companion — then SNAP it into the photo album.
## Drag the hero to move her, pinch / wheel to scale, FLIP to mirror. Web builds can download photos.

const FILTERS := [
	["None", {}],
	["Warm", {"tint": Color(1.08, 0.97, 0.86), "saturation": 1.1, "vignette": 0.3}],
	["Cool", {"tint": Color(0.88, 0.97, 1.1), "saturation": 0.95, "vignette": 0.3}],
	["Night", {"tint": Color(0.7, 0.75, 1.05), "brightness": -0.08, "contrast": 1.1, "vignette": 0.55}],
	["Sepia", {"sepia": 0.85, "saturation": 0.6, "vignette": 0.45}],
	["Dreamy", {"tint": Color(1.08, 0.94, 1.05), "bloom": 0.6, "brightness": 0.04, "vignette": 0.2}],
	["Mono", {"saturation": 0.0, "contrast": 1.15, "vignette": 0.4}],
	["Vivid", {"saturation": 1.35, "contrast": 1.1, "vignette": 0.25}],
]
const FRAMES := ["None", "Gold", "Polaroid", "Film", "Hearts"]
const MAX_PHOTOS := 30

var _hero := ""
var _skin := 0
var _bg_i := 0
var _filter_i := 0
var _frame_i := 0
var _flip := false
var _with_pet := true
var _zoom := 1.0
var _stage: Control
var _bgt: TextureRect
var _art: TextureRect
var _pet: Control
var _grade: ColorRect
var _frame: Control
var _caption: Label
var _cap_edit: LineEdit
var _panel: Control
var _hdr: Control
var _info: Label
var _drag := false
var _pinch: PinchZoom
var _bg_keys: Array = []

func build() -> void:
	_bg_keys = DB.BG.keys().filter(func(k): return not (k in ["battle", "boss"]))
	_hero = str(params.get("hero", Game.s["lobby_hero"]))
	if not Game.owns(_hero):
		_hero = Game.s["heroes"].keys()[0]
	_skin = int(Game.hero(_hero).get("skin", 0))
	_bg_i = maxi(0, _bg_keys.find(str(Game.s.get("lobby_bg", "lobby"))))
	# ---- stage (what ends up in the photo)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_stage_input)
	add_child(_stage)
	_bgt = UI.tex_rect(null, Vector2.ZERO, true)
	_bgt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_bgt)
	_art = UI.tex_rect(null)
	_art.size = Vector2(520, 680)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_art)
	UI.live(_art, Color(1, 0.9, 1))
	_pinch = PinchZoom.new(func(f: float, _c: Vector2): _set_zoom(_zoom * f))
	_stage.add_child(_pinch)
	_grade = ColorRect.new()
	_grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := ShaderMaterial.new()
	gm.shader = load("res://game/ui/photo_grade.gdshader")
	_grade.material = gm
	_stage.add_child(_grade)
	_frame = Control.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_frame)
	_caption = UI.label("", 28, Color.WHITE, 8)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_top = -84
	_caption.offset_bottom = -34
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_caption)
	# ---- UI
	_hdr = header("PHOTO STUDIO", [])
	_build_panel()
	(func():
		var hgt := size.y * 0.8
		_art.size = Vector2(hgt * 0.78, hgt)
		_art.position = Vector2(size.x * 0.36 - _art.size.x * 0.5, size.y - _art.size.y - 8)
		_art.pivot_offset = _art.size * Vector2(0.5, 1.0)).call_deferred()
	_apply_all()
	tutorial("photo")

func _build_panel() -> void:
	_panel = UI.panel()
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.anchor_left = 0.74
	_panel.offset_left = 0
	_panel.offset_right = -10
	_panel.offset_top = 76
	_panel.offset_bottom = -10
	add_child(_panel)
	var v := UI.vbox(7)
	_panel.add_child(UI.scroll(v))
	_info = UI.label("", 13, UI.GOLD, 3)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_info)
	v.add_child(UI.button("CHANGE HERO", _pick_hero, "", Vector2(0, 38)))
	v.add_child(_stepper("OUTFIT", func(d): _cycle_skin(d)))
	v.add_child(_stepper("BACKGROUND", func(d): _bg_i = posmod(_bg_i + d, _bg_keys.size()); _apply_all()))
	v.add_child(_stepper("FILTER", func(d): _filter_i = posmod(_filter_i + d, FILTERS.size()); _apply_all()))
	v.add_child(_stepper("FRAME", func(d): _frame_i = posmod(_frame_i + d, FRAMES.size()); _apply_all()))
	var row := UI.hbox(6)
	var fb := UI.button("FLIP ⇆", func(): _flip = not _flip; _apply_all(), "", Vector2(0, 36))
	fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fb)
	if Game.companion() != "":
		var pb := UI.button("COMPANION", func(): _with_pet = not _with_pet; _apply_all(), "", Vector2(0, 36))
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(pb)
	v.add_child(row)
	_cap_edit = LineEdit.new()
	_cap_edit.placeholder_text = "Caption (optional)"
	_cap_edit.max_length = 40
	_cap_edit.custom_minimum_size = Vector2(0, 38)
	_cap_edit.text_changed.connect(func(tx): _caption.text = tx)
	v.add_child(_cap_edit)
	v.add_child(UI.wrap_label("Drag her to move • pinch / wheel to resize", 11, UI.MUTED))
	v.add_child(UI.button("📷  SNAP", _snap, "GoldButton", Vector2(0, 52)))
	v.add_child(UI.button("ALBUM (%d)" % _photo_files().size(), _album, "", Vector2(0, 38)))

func _stepper(title: String, cb: Callable) -> Control:
	var h := UI.hbox(4)
	var l := UI.button("◀", func(): cb.call(-1), "", Vector2(40, 36))
	var mid := UI.label(title, 12, Color.WHITE, 2)
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r := UI.button("▶", func(): cb.call(1), "", Vector2(40, 36))
	h.add_child(l)
	h.add_child(mid)
	h.add_child(r)
	return h

func _cycle_skin(d: int) -> void:
	var n := DB.art_list(_hero).size()
	for i in n:
		_skin = posmod(_skin + d, n)
		if Game.skin_unlocked(_hero, _skin):
			break
	_apply_all()

func _apply_all() -> void:
	_bgt.texture = DB.bg(_bg_keys[_bg_i])
	_art.texture = DB.art(_hero, _skin)
	_art.flip_h = _flip
	var gm := _grade.material as ShaderMaterial
	var fp: Dictionary = FILTERS[_filter_i][1]
	for k in ["tint", "saturation", "contrast", "brightness", "sepia", "vignette", "bloom"]:
		var defv = {"tint": Color.WHITE, "saturation": 1.0, "contrast": 1.0, "brightness": 0.0, "sepia": 0.0, "vignette": 0.0, "bloom": 0.0}[k]
		gm.set_shader_parameter(k, fp.get(k, defv))
	_grade.visible = _filter_i != 0
	_build_frame()
	if is_instance_valid(_pet):
		_pet.queue_free()
		_pet = null
	if _with_pet and Game.companion() != "":
		_pet = CompanionCameo.new(Game.companion())
		_pet.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_pet.anchor_left = 0.5
		_pet.anchor_right = 0.5
		_pet.offset_left = 0
		_pet.offset_right = 150
		_pet.offset_top = -230
		_pet.offset_bottom = -30
		_stage.add_child(_pet)
		_stage.move_child(_pet, _art.get_index() + 1)
	_info.text = "%s  •  %s\n%s  •  %s filter  •  %s frame" % [DB.name_of(_hero), _outfit_name(), _bg_keys[_bg_i].capitalize(), FILTERS[_filter_i][0], FRAMES[_frame_i]]

func _outfit_name() -> String:
	if _skin == DB.special_index(_hero):
		return str(DB.SPECIAL_SKINS.get(_hero, "Special"))
	return "Outfit %d" % (_skin + 1)

func _build_frame() -> void:
	for c in _frame.get_children():
		c.queue_free()
	var f: String = FRAMES[_frame_i]
	if f == "None":
		return
	var p := Panel.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	match f:
		"Gold":
			sb.border_color = UI.GOLD
			sb.set_border_width_all(14)
			sb.corner_radius_top_left = 6
			sb.shadow_color = Color(0, 0, 0, 0.5)
			sb.shadow_size = 12
		"Polaroid":
			sb.border_color = Color(0.97, 0.96, 0.93)
			sb.set_border_width_all(22)
			sb.border_width_bottom = 96
		"Film":
			sb.border_color = Color(0.05, 0.05, 0.06)
			sb.border_width_top = 46
			sb.border_width_bottom = 46
		"Hearts":
			sb.border_color = Color("#ff8fb8")
			sb.set_border_width_all(10)
	p.add_theme_stylebox_override("panel", sb)
	_frame.add_child(p)
	if f == "Film":
		for side in [0, 1]:
			var holes := HBoxContainer.new()
			holes.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if side == 0 else Control.PRESET_BOTTOM_WIDE)
			holes.offset_top = 14 if side == 0 else -32
			holes.offset_bottom = 32 if side == 0 else -14
			holes.add_theme_constant_override("separation", 26)
			holes.alignment = BoxContainer.ALIGNMENT_CENTER
			holes.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for i in 30:
				var r := ColorRect.new()
				r.custom_minimum_size = Vector2(16, 18)
				r.color = Color(0.85, 0.82, 0.75)
				holes.add_child(r)
			_frame.add_child(holes)
	elif f == "Hearts":
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 26:
			var h := UI.label("♥", rng.randi_range(22, 40), Color("#ff8fb8"), 4)
			var edge := rng.randi() % 4
			var vs := get_viewport_rect().size
			var pos := Vector2(rng.randf() * vs.x, rng.randf() * vs.y)
			if edge == 0: pos.y = rng.randf_range(0, 40)
			elif edge == 1: pos.y = vs.y - rng.randf_range(40, 70)
			elif edge == 2: pos.x = rng.randf_range(0, 40)
			else: pos.x = vs.x - rng.randf_range(40, 70)
			h.position = pos
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_frame.add_child(h)
	elif f == "Polaroid":
		var d := UI.label(Time.get_date_string_from_system(), 16, Color(0.35, 0.3, 0.3), 0)
		d.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		d.offset_left = -180
		d.offset_top = -40
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame.add_child(d)

func _set_zoom(z: float) -> void:
	_zoom = clampf(z, 0.5, 2.6)
	_art.scale = Vector2(_zoom, _zoom)

func _stage_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_set_zoom(_zoom * 1.08)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_set_zoom(_zoom / 1.08)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			_drag = e.pressed
	elif e is InputEventMouseMotion and _drag and not _pinch.active():
		_art.position += e.relative

func _pick_hero() -> void:
	var v: VBoxContainer = main.popup("CHOOSE A MODEL", 820)
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 420)
	v.add_child(sc)
	for id in Game.s["heroes"].keys():
		var hid: String = id
		var card := HeroCard.new(hid, Vector2(108, 136), {"skin": true, "show_level": false})
		card.set_selected(hid == _hero)
		card.pressed.connect(func():
			main.close_popup(v)
			_hero = hid
			_skin = int(Game.hero(hid).get("skin", 0))
			_apply_all())
		g.add_child(card)

# ---------------------------------------------------------------- snap & album

func _photo_files() -> Array:
	var out: Array = []
	var d := DirAccess.open("user://photos")
	if d:
		for f in d.get_files():
			if f.ends_with(".png"):
				out.append("user://photos/" + f)
	out.sort()
	out.reverse()
	return out

func _snap() -> void:
	Game.sfx("ui_click")
	_panel.visible = false
	_hdr.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var img := get_viewport().get_texture().get_image()
	_panel.visible = true
	_hdr.visible = true
	DirAccess.make_dir_recursive_absolute("user://photos")
	var path := "user://photos/photo_%d.png" % int(Time.get_unix_time_from_system() * 1000.0)
	img.save_png(path)
	var all := _photo_files()
	while all.size() > MAX_PHOTOS:
		DirAccess.remove_absolute(all.pop_back())
	Game.s["stats"]["photos"] = int(Game.s["stats"].get("photos", 0)) + 1
	Game.mark_dirty()
	# shutter flash
	var fl := ColorRect.new()
	fl.color = Color(1, 1, 1, 0.9)
	fl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fl)
	fl.create_tween().tween_property(fl, "modulate:a", 0.0, 0.4)
	get_tree().create_timer(0.45).timeout.connect(fl.queue_free)
	Game.sfx("star_up")
	Game.voice(_hero, "bond")
	_show_photo(path, img)

func _show_photo(path: String, img: Image) -> void:
	var v: VBoxContainer = main.popup("PHOTO SAVED", 760)
	var t := UI.tex_rect(ImageTexture.create_from_image(img), Vector2(700, 394))
	v.add_child(t)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	if OS.has_feature("web"):
		row.add_child(UI.button("DOWNLOAD", func(): _download(img), "GoldButton", Vector2(180, 46)))
	row.add_child(UI.button("DELETE", func():
		DirAccess.remove_absolute(path)
		main.close_popup(v)
		main.toast("Photo deleted.", UI.MUTED), "", Vector2(140, 46)))
	row.add_child(UI.button("OK", func(): main.close_popup(v), "", Vector2(120, 46)))

## Web: hand the PNG to the browser as a download.
func _download(img: Image) -> void:
	if not OS.has_feature("web"):
		return
	var b64 := Marshalls.raw_to_base64(img.save_png_to_buffer())
	JavaScriptBridge.eval("(function(){var a=document.createElement('a');a.href='data:image/png;base64,%s';a.download='euphoria_photo_%d.png';document.body.appendChild(a);a.click();a.remove();})()" % [b64, int(Time.get_unix_time_from_system())], true)

func _album() -> void:
	var files := _photo_files()
	var v: VBoxContainer = main.popup("PHOTO ALBUM  (%d / %d)" % [files.size(), MAX_PHOTOS], 1000)
	if files.is_empty():
		v.add_child(UI.label("No photos yet — compose a shot and press SNAP!", 16, UI.MUTED, 2))
		return
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 460)
	v.add_child(sc)
	for f in files:
		var fp: String = f
		var img := Image.load_from_file(fp)
		if img == null or img.is_empty():
			continue
		img.resize(220, int(220.0 * img.get_height() / img.get_width()))
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(220, img.get_height())
		var tr := UI.tex_rect(ImageTexture.create_from_image(img))
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(tr)
		b.pressed.connect(func():
			main.close_popup(v)
			_show_photo(fp, Image.load_from_file(fp)))
		g.add_child(b)
