class_name HeroCard
extends Button
## Portrait card used in roster lists, gacha results and formation dock.

var hero_id := ""
var _sel: Panel
static var _glow_tex: GradientTexture2D

## Shared radial glow (white, tinted per card with modulate) behind the portrait.
static func _glow() -> GradientTexture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0)])
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.38)
		_glow_tex.fill_to = Vector2(1.1, 0.95)
		_glow_tex.width = 96
		_glow_tex.height = 128
	return _glow_tex

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
	frame.add_theme_stylebox_override("panel", UI.style(DB.theme_color(id).darkened(0.86), rc, 10, 2, 0, 4))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(frame)

	# soft element-colored light behind the hero instead of a flat fill
	var glow := TextureRect.new()
	glow.texture = _glow()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ec: Color = DB.ELEMENT_COLOR.get(DB.element_of(id), DB.theme_color(id))
	glow.modulate = ec.lerp(DB.theme_color(id), 0.4) if owned else Color(0.4, 0.4, 0.45)
	glow.modulate.a = 0.75
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(glow)

	# full-body art, whole figure visible at its own proportions (no crop, no stretch)
	var face := UI.tex_rect(DB.art(id, int(h.get("skin", 0)) if opts.get("skin", false) else 0), Vector2.ZERO, false)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.offset_left = 2
	face.offset_top = 4
	face.offset_right = -2
	face.offset_bottom = -int(card_size.y * 0.1)
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

	var rchip := PanelContainer.new()
	rchip.add_theme_stylebox_override("panel", UI.style(Color(0, 0, 0, 0.55), Color(rc, 0.85), 6, 1, 0))
	rchip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rtag := UI.label(rarity, 11, rc.lightened(0.35), 3)
	rtag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rchip.add_child(UI.margin(rtag, 5, 0, 5, 0))
	rchip.position = Vector2(card_size.x - (40 if rarity == "SSR" else 32), 6)
	frame.add_child(rchip)

	# battle role tag under the element icon (TANK / DPS / MAGE / SUP)
	if card_size.x >= 100:
		var ri := DB.role_info(id)
		var short := str(ri[0]).split(" ")[0]
		if short == "SUPPORT":
			short = "SUP"
		var rcol := Color(str(ri[1]))
		var role_chip := PanelContainer.new()
		role_chip.add_theme_stylebox_override("panel", UI.style(Color(0, 0, 0, 0.6), Color(rcol, 0.8), 5, 1, 0))
		role_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		role_chip.add_child(UI.margin(UI.label(short, 9, rcol.lightened(0.25), 2), 4, 0, 4, 0))
		role_chip.position = Vector2(5, 32)
		frame.add_child(role_chip)

	# rarity accent line above the name plate
	var accent := ColorRect.new()
	accent.color = Color(rc, 0.75)
	accent.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	accent.offset_top = -49
	accent.offset_bottom = -48
	accent.offset_left = 10
	accent.offset_right = -10
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(accent)

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
		var need: int = Game.RECRUIT_SHARDS[rarity]
		var lv2 := UI.vbox(3)
		lv2.anchor_right = 1.0
		lv2.offset_left = 12
		lv2.offset_right = -12
		lv2.offset_top = card_size.y * 0.36
		lv2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lv2)
		var ready := sh >= need
		var lock := UI.label("🔒 NOT OWNED" if sh == 0 else ("✦ RECRUIT!" if ready else "SHARDS"), 11, UI.GOLD if ready else UI.MUTED, 3)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv2.add_child(lock)
		if sh > 0:
			var pb := UI.bar(mini(sh, need), need, "", 6)
			pb.add_theme_stylebox_override("fill", UI.style(UI.GOLD if ready else Color("#b48cff"), Color.TRANSPARENT, 3, 0, 0))
			pb.add_theme_stylebox_override("background", UI.style(Color(0, 0, 0, 0.6), Color(1, 1, 1, 0.2), 3, 1, 0))
			lv2.add_child(pb)
			var nl := UI.label("%d / %d" % [sh, need], 10, Color.WHITE if ready else UI.TEXT, 3)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lv2.add_child(nl)

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
