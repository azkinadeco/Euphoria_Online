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
	# opts.lazy: a full-body art not loaded yet is filled a moment later by LazyTex (the roster spreads the
	# first-visit loading over several frames instead of freezing ~2 s before the screen appears)
	var art_i: int = int(h.get("skin", 0)) if opts.get("skin", false) else 0
	var lazy: bool = opts.get("lazy", false) and not DB.tex_loaded(DB.art_path(id, art_i))
	# opts.bust: half-body crop centred on the face (DB.bust_tex) so all picker cards share one proportion
	var bust: bool = opts.get("bust", false)
	var bust_aspect := (card_size.y - 4.0) / maxf(1.0, card_size.x - 4.0)
	var face := UI.tex_rect_lazy(not lazy, (func(): return DB.bust_tex(DB.art(id, art_i), bust_aspect)) if bust else (func(): return DB.art(id, art_i)), Vector2.ZERO, bust)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.offset_left = 2
	face.offset_top = 2 if bust else 4
	face.offset_right = -2
	face.offset_bottom = -2 if bust else -int(card_size.y * 0.1)
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
	if DB.rarity_rank(rarity) >= DB.rarity_rank("SSR") and owned and not Game.reduce_fx():
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

	# rarity border + aura (animated for LR / MR / GR / OR); dimmer for heroes not owned yet
	UI.rarity_frame(self, rarity, 10.0, 2.0 if card_size.x < 100 else 2.5, 6.0 if card_size.x < 100 else 9.0, 1.0 if owned else 0.25)

	var elem := UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(id), "elem_light")), Vector2(24, 24))
	elem.position = Vector2(5, 5)
	elem.size = Vector2(24, 24)
	frame.add_child(elem)

	# rarity logo in the top-right corner (owner's badge art), fitted in a small box so the wide
	# crests (LEGEND, ULTRA RARE) take the same corner space as SSR and never cover her head
	var rbadge := _fit_badge(DB.rarity_badge(rarity), clampf(card_size.x * 0.21, 18.0, 28.0), clampf(card_size.x * 0.42, 36.0, 62.0))
	rbadge.position = Vector2(card_size.x - rbadge.size.x - 5, 5 + (24.0 - rbadge.size.y) * 0.5)   # centred on the element icon row
	if not owned:
		rbadge.modulate = Color(0.75, 0.75, 0.8)
	frame.add_child(rbadge)

	# battle role word (owner's role lettering: MAGE / FIGHTER / TANK / ASSASSIN / SUPPORT): small, right end
	# of the Lv line, so it reads as a label next to the level instead of a title over the art
	if card_size.x >= 84:
		# MAGE is the shortest word, so it gets a larger scale to read as the same weight as the others
		var rk := 1.4 if str(DB.ROLE_BADGE.get(DB.role_of(id), "")) == "mage" else 1.2
		var rrole := _fit_badge(DB.role_badge(id), clampf(card_size.x * 0.07, 7.0, 10.0) * rk, card_size.x * 0.34 * rk)
		rrole.position = Vector2(card_size.x - rrole.size.x - 7, card_size.y - 64 + (16.0 - rrole.size.y) * 0.5)
		rrole.tooltip_text = str(DB.role_info(id)[0])
		frame.add_child(rrole)

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
	info.add_child(UI.rank_stars(star_n, int(h.get("evo", 0)), int(h.get("evo_star", 0)), 12, true))
	var nm := UI.label(DB.name_of(id).split(" ")[0], 14 if card_size.x >= 100 else 12, Color.WHITE, 4)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(nm)

	if owned and opts.get("show_level", true):
		var lv := UI.label("Lv.%d" % int(h.get("level", 1)), 12, UI.GOLD, 4)
		lv.position = Vector2(6, card_size.y - 64)
		lv.size = Vector2(60, 16)
		frame.add_child(lv)

	if not owned:
		face.modulate = Color(0.35, 0.35, 0.4)
		var lock := UI.label("NOT OWNED" if card_size.x >= 110 else "✕", 11, UI.MUTED, 3)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.anchor_right = 1.0
		lock.offset_top = card_size.y * 0.4
		frame.add_child(lock)

	# duplicate cards of this hero waiting in the inventory ("+3"), like a stack
	var cp := Game.copies(id) if owned and not opts.get("copy", false) else 0
	if cp > 0 and opts.get("show_copies", true):
		var cpl := UI.label("+%d" % cp, 20 if card_size.x >= 100 else 16, Color("#d8b4ff"), 5)
		cpl.add_theme_color_override("font_outline_color", Color("#2a0d4a"))
		cpl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cpl.anchor_left = 1.0
		cpl.anchor_right = 1.0
		cpl.offset_left = -60
		cpl.offset_right = -6
		cpl.offset_top = 22
		frame.add_child(cpl)
	if opts.get("copy", false):
		# a duplicate card in the inventory: material for rank-ups / dismantling
		var tag := UI.styled_panel(Color(0.18, 0.06, 0.3, 0.9), Color("#d8b4ff", 0.8), 6, 1, 3)
		tag.anchor_left = 0.5
		tag.anchor_right = 0.5
		tag.offset_left = -34
		tag.offset_right = 34
		tag.offset_top = card_size.y * 0.42
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tl := UI.label("COPY", 12, Color("#ecd8ff"), 3)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(tl)
		frame.add_child(tag)

	# evolution tier: a thin inner ring + soft glow in the tier colour (Abyss: violet-black)
	var evo_t := int(h.get("evo", 0)) if owned and not opts.get("copy", false) else 0
	if evo_t > 0:
		var ec2 := DB.evo_color(evo_t) if evo_t < DB.MAX_EVO else Color("#8a3cff")
		var er := Panel.new()
		er.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		er.offset_left = 3
		er.offset_top = 3
		er.offset_right = -3
		er.offset_bottom = -3
		er.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color.TRANSPARENT
		sb.border_color = Color(ec2, 0.9)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		sb.shadow_color = Color(ec2, 0.55)
		sb.shadow_size = 6
		er.add_theme_stylebox_override("panel", sb)
		frame.add_child(er)

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

	if opts.get("star_ready", false):
		# Star Up is affordable: a small pulsing green arrow in the top-right corner
		var up := UI.styled_panel(Color(0.04, 0.2, 0.1, 0.92), UI.GREEN, 10, 1, 0)
		up.add_child(UI.margin(UI.label("▲ ★", 11, UI.GREEN, 2), 5, 1, 5, 1))
		up.position = Vector2(card_size.x - 44, card_size.y * 0.42)
		up.mouse_filter = Control.MOUSE_FILTER_IGNORE
		up.tooltip_text = "Star Up ready"
		add_child(up)
		if not Game.reduce_fx():
			var ut := up.create_tween().set_loops()
			ut.tween_property(up, "modulate:a", 0.55, 0.7).set_trans(Tween.TRANS_SINE)
			ut.tween_property(up, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

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

## Badge art scaled to fit inside max_h x max_w, aspect kept.
static func _fit_badge(t: Texture2D, max_h: float, max_w: float) -> TextureRect:
	var r := UI.badge_rect(t, max_h)
	if r.size.x > max_w:
		var k := max_w / r.size.x
		r.custom_minimum_size *= k
		r.size *= k
	return r

func set_selected(v: bool) -> void:
	_sel.visible = v
