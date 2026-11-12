extends Screen
## Title screen: logo with light rays, rotating hero art + name plate, ornate TAP TO START.

var _hint: Control
var _logo: TextureRect
var _started := false

## Soft light rays slowly turning behind the logo.
class Rays extends Control:
	var col := Color(1.0, 0.75, 1.0)
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		var c := size * 0.5
		var r := maxf(size.x, size.y) * 0.62
		var n := 14
		for i in n:
			var a := t * 0.12 + TAU * float(i) / float(n)
			var w := 0.07 + 0.03 * sin(t * 0.7 + float(i))
			var alpha := 0.07 + 0.04 * sin(t * 0.9 + float(i) * 1.7)
			var pts := PackedVector2Array([c, c + Vector2.from_angle(a - w) * r, c + Vector2.from_angle(a + w) * r])
			var cols := PackedColorArray([Color(col, alpha), Color(col, 0.0), Color(col, 0.0)])
			draw_polygon(pts, cols)
		# soft core glow
		for k in 6:
			draw_circle(c, r * (0.12 + 0.07 * k), Color(col, 0.035))

## Band behind TAP TO START: dark gradient fading to both sides, gold lines, diamonds and a moving sheen.
class StartPlate extends Control:
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cy := h * 0.5
		var gold := Color(1.0, 0.84, 0.5)
		# band (alpha fades toward the edges)
		var steps := 24
		for i in steps:
			var x0 := w * float(i) / float(steps)
			var x1 := w * float(i + 1) / float(steps)
			var m := 1.0 - absf((x0 + x1) * 0.5 / w - 0.5) * 2.0
			draw_rect(Rect2(x0, 6, x1 - x0, h - 12), Color(0.06, 0.02, 0.1, 0.72 * smoothstep(0.0, 0.5, m)))
		# gold rules top & bottom, fading out
		for y in [6.0, h - 6.0]:
			draw_line(Vector2(w * 0.08, y), Vector2(w * 0.5, y), Color(gold, 0.0), 1.5)
			draw_polyline_colors(PackedVector2Array([Vector2(w * 0.08, y), Vector2(w * 0.5, y), Vector2(w * 0.92, y)]),
				PackedColorArray([Color(gold, 0.0), Color(gold, 0.85), Color(gold, 0.0)]), 1.5, true)
		# diamonds left & right of the text
		var pulse := 0.6 + 0.4 * sin(t * 2.4)
		for sx in [w * 0.17, w * 0.83]:
			var d := 7.0
			draw_colored_polygon(PackedVector2Array([Vector2(sx, cy - d), Vector2(sx + d, cy), Vector2(sx, cy + d), Vector2(sx - d, cy)]), Color(gold, pulse))
			draw_line(Vector2(sx - 40 if sx < w * 0.5 else sx + 12, cy), Vector2(sx - 12 if sx < w * 0.5 else sx + 40, cy), Color(gold, 0.6), 1.2)
		# sheen sweeping across every 3 s
		var p := fmod(t, 3.0) / 1.2
		if p < 1.0:
			var sx2 := lerpf(-60.0, w + 60.0, p)
			draw_colored_polygon(PackedVector2Array([Vector2(sx2 - 18, 6), Vector2(sx2 + 10, 6), Vector2(sx2 - 10, h - 6), Vector2(sx2 - 38, h - 6)]), Color(1, 1, 1, 0.12))

func build() -> void:
	set_bg("lobby", 0.35)
	ambient(Color(1.0, 0.8, 1.0), 60)
	var owned: Array = Game.s["heroes"].keys()
	var hid: String = Game.s["lobby_hero"] if randf() < 0.5 or owned.is_empty() else owned[randi() % owned.size()]
	var tc: Color = DB.theme_color(hid)

	# glow of the hero's theme colour behind the art
	var halo := Rays.new()
	halo.col = tc.lightened(0.35)
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	halo.anchor_left = 0.5
	halo.anchor_top = 0.0
	halo.anchor_bottom = 1.1
	halo.modulate.a = 0.6
	add_child(halo)

	var art := UI.tex_rect(DB.art(hid, int(Game.hero(hid).get("skin", 0))))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_left = 0.52
	art.offset_top = 30
	add_child(art)
	UI.live(art)
	UI.fade_in(art, 0.8, Vector2(60, 0))

	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.02, 0.01, 0.05, 0.85))
	grad.set_color(1, Color(0.02, 0.01, 0.05, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.anchor_right = 0.6
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# bottom vignette so the footer text stays readable
	var foot := TextureRect.new()
	var g2 := Gradient.new()
	g2.set_color(0, Color(0.02, 0.01, 0.05, 0.0))
	g2.set_color(1, Color(0.02, 0.01, 0.05, 0.8))
	var gt2 := GradientTexture2D.new()
	gt2.gradient = g2
	gt2.fill_from = Vector2(0, 0)
	gt2.fill_to = Vector2(0, 1)
	foot.texture = gt2
	foot.set_anchors_preset(Control.PRESET_FULL_RECT)
	foot.anchor_top = 0.78
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(foot)

	# light rays behind the logo
	var rays := Rays.new()
	rays.set_anchors_preset(Control.PRESET_FULL_RECT)
	rays.anchor_left = 0.0
	rays.anchor_right = 0.58
	rays.anchor_top = 0.0
	rays.anchor_bottom = 0.76
	add_child(rays)
	rays.modulate.a = 0.0
	rays.create_tween().tween_property(rays, "modulate:a", 1.0, 1.2).set_delay(0.3)

	_logo = UI.tex_rect(DB.tex("res://art/brand/logo_emblem.png"))
	var logo := _logo
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.anchor_left = 0.03
	logo.anchor_right = 0.55
	logo.anchor_top = 0.08
	logo.anchor_bottom = 0.68
	add_child(logo)
	logo.resized.connect(func(): logo.pivot_offset = logo.size * 0.5)
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.85, 0.85)
	var tw := logo.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "modulate:a", 1.0, 0.6)
	tw.tween_property(logo, "scale", Vector2.ONE, 0.8)
	var fl := logo.create_tween().set_loops()
	fl.tween_property(logo, "position:y", logo.position.y - 6, 2.0).set_trans(Tween.TRANS_SINE).set_delay(0.9)
	fl.tween_property(logo, "position:y", logo.position.y, 2.0).set_trans(Tween.TRANS_SINE)

	# hero name plate (bottom right, over the art)
	_name_plate(hid, tc)

	# ornate TAP TO START
	var plate := StartPlate.new()
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	plate.anchor_left = 0.03
	plate.anchor_right = 0.55
	plate.anchor_top = 0.72
	plate.anchor_bottom = 0.82
	add_child(plate)
	var tl := UI.label("TAP TO START", 30, Color(1.0, 0.95, 0.85), 8)
	tl.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.3))
	tl.add_theme_constant_override("shadow_offset_y", 3)
	tl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.add_child(tl)
	_hint = tl
	var bl := tl.create_tween().set_loops()
	bl.tween_property(tl, "modulate:a", 0.45, 0.9).set_trans(Tween.TRANS_SINE)
	bl.tween_property(tl, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	plate.modulate.a = 0.0
	plate.create_tween().tween_property(plate, "modulate:a", 1.0, 0.5).set_delay(0.7)

	# commander card
	var info_row := UI.hbox(0)
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_row.anchor_left = 0.03
	info_row.anchor_right = 0.55
	info_row.anchor_top = 0.835
	info_row.anchor_bottom = 0.9
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_row)
	var card := UI.styled_panel(Color(0.05, 0.02, 0.09, 0.7), Color(1.0, 0.84, 0.5, 0.35), 16, 1, 6)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_child(card)
	var ch := UI.hbox(14)
	card.add_child(UI.margin(ch, 8, 0, 8, 0))
	ch.add_child(UI.label(str(Game.s["player"]["name"]), 15, Color.WHITE, 3))
	ch.add_child(_info_chip("Lv.%d" % int(Game.s["player"]["level"]), UI.GOLD))
	ch.add_child(_info_chip("%d heroes" % owned.size(), Color("#c9b8ff")))
	if not owned.is_empty():
		ch.add_child(_info_chip("Power %s" % _fmt(Game.team_power()), Color("#ffb38a")))
	for c in card.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ver := UI.label("v2.1  •  Offline Mode", 13, UI.MUTED, 3)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	ver.offset_left = 16
	ver.offset_top = -30
	add_child(ver)

	var tap := Button.new()
	tap.theme_type_variation = "FlatButton"
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(_start)
	add_child(tap)

	# NOTICES (on top of the tap catcher, top right)
	var nb := UI.button("📜 NOTICES", func():
		Game.sfx("ui_click")
		main.show_news(0), "", Vector2(140, 40))
	nb.add_theme_font_size_override("font_size", 14)
	nb.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	nb.offset_left = -156
	nb.offset_right = -16
	nb.offset_top = 16
	nb.offset_bottom = 56
	add_child(nb)
	var unseen := Game.news_unread()
	if unseen > 0:
		UI.add_badge(nb, unseen)

func _name_plate(hid: String, tc: Color) -> void:
	var box := UI.vbox(0)
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	box.offset_left = -330
	box.offset_right = -24
	box.offset_top = -112
	box.offset_bottom = -20
	box.alignment = BoxContainer.ALIGNMENT_END
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var ttl := DB.title_of(hid)
	if ttl != "":
		var tt := UI.label(ttl.to_upper(), 13, tc.lightened(0.55), 4)
		tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		box.add_child(tt)
	var nm := UI.label(DB.name_of(hid), 34, Color.WHITE, 8)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	nm.add_theme_color_override("font_outline_color", tc.darkened(0.55))
	nm.add_theme_constant_override("shadow_offset_y", 3)
	nm.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	box.add_child(nm)
	var line := ColorRect.new()
	line.color = Color(tc.lightened(0.3), 0.9)
	line.custom_minimum_size = Vector2(0, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)
	var tags := UI.hbox(6)
	tags.alignment = BoxContainer.ALIGNMENT_END
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tags)
	tags.add_child(UI.label(DB.rarity_of(hid), 13, DB.RARITY_COLOR[DB.rarity_of(hid)], 3))
	tags.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(hid), "elem_light")), Vector2(18, 18)))
	box.modulate.a = 0.0
	var tw := box.create_tween().set_parallel(true)
	tw.tween_property(box, "modulate:a", 1.0, 0.5).set_delay(0.9)
	tw.tween_property(box, "position:x", box.position.x, 0.5).from(box.position.x + 40).set_delay(0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _info_chip(text: String, col: Color) -> Control:
	var l := UI.label(text, 14, col, 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func on_back() -> bool:
	return true

func _start() -> void:
	if _started:
		return
	_started = true
	Game.sfx("gacha_gate")
	if is_instance_valid(_logo):
		_logo.create_tween().tween_property(_logo, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_CUBIC)
	if is_instance_valid(_hint):
		_hint.modulate = Color(1.6, 1.4, 1.0)
	var flash := ColorRect.new()
	flash.color = Color(1, 0.9, 1, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.8, 0.25)
	tw.tween_callback(func(): main.enter_game())
