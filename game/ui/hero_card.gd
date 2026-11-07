class_name HeroCard
extends Button
## Portrait card used in roster lists, gacha results and formation dock.

var hero_id := ""
var _sel: Panel

func _init(id: String = "", card_size: Vector2 = Vector2(118, 150), opts: Dictionary = {}) -> void:
	hero_id = id
	theme_type_variation = "FlatButton"
	custom_minimum_size = card_size
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = false
	var owned: bool = opts.get("owned", Game.owns(id))
	var rarity := DB.rarity_of(id)
	var rc: Color = DB.RARITY_COLOR[rarity]
	var h := Game.hero(id)

	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", UI.style(DB.theme_color(id).darkened(0.72), rc, 10, 2, 0, 4))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(frame)

	var face := UI.tex_rect(DB.face(id, int(h.get("skin", 0)) if opts.get("skin", false) else -1), Vector2.ZERO, true)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.offset_left = 3
	face.offset_top = 3
	face.offset_right = -3
	face.offset_bottom = -3
	frame.add_child(face)

	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0, 0, 0, 0.92))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0.45)
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(shade)

	# holographic sweep across owned SSR cards (Sakura Oath / Brown Dust style)
	if rarity == "SSR" and owned and not Game.reduce_fx():
		var sh := TextureRect.new()
		var sg := Gradient.new()
		sg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		sg.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 0.95, 0.8, 0.38), Color(1, 1, 1, 0)])
		var sgt := GradientTexture2D.new()
		sgt.gradient = sg
		sgt.width = 64
		sgt.height = 8
		sh.texture = sgt
		sh.stretch_mode = TextureRect.STRETCH_SCALE
		sh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sh.size = Vector2(card_size.x * 0.45, card_size.y * 1.8)
		sh.rotation = 0.35
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shm := CanvasItemMaterial.new()
		shm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sh.material = shm
		sh.position = Vector2(-card_size.x, -card_size.y * 0.4)
		frame.add_child(sh)
		var stw := sh.create_tween().set_loops()
		stw.tween_interval(randf_range(0.5, 3.5))
		stw.tween_property(sh, "position:x", card_size.x * 1.3, 0.9).set_trans(Tween.TRANS_SINE)
		stw.tween_callback(func(): sh.position.x = -card_size.x)
		stw.tween_interval(2.6)

	var elem := UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(id), "elem_light")), Vector2(24, 24))
	elem.position = Vector2(5, 5)
	elem.size = Vector2(24, 24)
	frame.add_child(elem)

	var rtag := UI.label(rarity, 13, rc.lightened(0.25), 4)
	rtag.position = Vector2(card_size.x - 36, 4)
	rtag.size = Vector2(32, 18)
	rtag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frame.add_child(rtag)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -2)
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_top = -46
	info.offset_bottom = -4
	info.offset_left = 6
	info.offset_right = -6
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(info)
	var star_n: int = int(h.get("star", DB.RARITY_START_STAR[rarity]))
	var st := UI.stars(star_n, 12)
	if int(h.get("awaken", 0)) > 0:
		st.text += "  A%d" % int(h["awaken"])
	info.add_child(st)
	var nm := UI.label(DB.name_of(id).split(" ")[0], 14 if card_size.x >= 100 else 12, Color.WHITE, 4)
	nm.clip_text = true
	info.add_child(nm)

	if owned and opts.get("show_level", true):
		var lv := UI.label("Lv.%d" % int(h.get("level", 1)), 12, UI.GOLD, 4)
		lv.position = Vector2(6, card_size.y - 64)
		lv.size = Vector2(60, 16)
		frame.add_child(lv)

	if not owned:
		face.modulate = Color(0.35, 0.35, 0.4)
		var sh: int = int(Game.s["shards"].get(id, 0))
		var lock := UI.label("NOT OWNED" if sh == 0 else "Shards %d" % sh, 11, UI.MUTED, 3)
		lock.position = Vector2(6, card_size.y * 0.42)
		lock.size = Vector2(card_size.x - 12, 16)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		frame.add_child(lock)

	# ornate rarity frame overlay (art/ui/frame_*.png)
	var fpath := "res://art/ui/frame_%s.png" % rarity.to_lower()
	if ResourceLoader.exists(fpath):
		var np := NinePatchRect.new()
		np.texture = load(fpath)
		np.patch_margin_left = 16
		np.patch_margin_right = 16
		np.patch_margin_top = 16
		np.patch_margin_bottom = 16
		np.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		np.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not owned:
			np.modulate = Color(0.6, 0.6, 0.65)
		add_child(np)

	if opts.has("badge"):
		var b := Panel.new()
		b.add_theme_stylebox_override("panel", UI.style(Color("#ffd479"), Color("#2a1600"), 12, 2, 0))
		b.size = Vector2(26, 26)
		b.position = Vector2(-6, -6)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bl := UI.label(str(opts["badge"]), 14, Color("#2a1600"))
		bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(bl)
		add_child(b)

	_sel = Panel.new()
	_sel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sel.offset_left = -3
	_sel.offset_top = -3
	_sel.offset_right = 3
	_sel.offset_bottom = 3
	_sel.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, UI.GOLD, 12, 3, 0))
	_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sel.visible = false
	add_child(_sel)

func set_selected(v: bool) -> void:
	_sel.visible = v
