extends Screen
## Title screen: logo, rotating hero art, tap to start.

var _hint: Label
var _started := false

func build() -> void:
	set_bg("lobby", 0.35)
	ambient(Color(1.0, 0.8, 1.0), 60)
	var owned: Array = Game.s["heroes"].keys()
	var hid: String = Game.s["lobby_hero"] if randf() < 0.5 or owned.is_empty() else owned[randi() % owned.size()]

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

	var logo := UI.tex_rect(DB.tex("res://art/brand/logo_emblem.png"))
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

	_hint = UI.label("TAP TO START", 30, Color.WHITE, 8)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint.anchor_left = 0.03
	_hint.anchor_right = 0.55
	_hint.anchor_top = 0.74
	_hint.anchor_bottom = 0.82
	add_child(_hint)
	var bl := _hint.create_tween().set_loops()
	bl.tween_property(_hint, "modulate:a", 0.25, 0.9).set_trans(Tween.TRANS_SINE)
	bl.tween_property(_hint, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

	var info := UI.label("%s  •  Lv.%d  •  %d heroes" % [Game.s["player"]["name"], int(Game.s["player"]["level"]), owned.size()], 15, UI.MUTED, 4)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.set_anchors_preset(Control.PRESET_FULL_RECT)
	info.anchor_left = 0.03
	info.anchor_right = 0.55
	info.anchor_top = 0.83
	info.anchor_bottom = 0.88
	add_child(info)

	var ver := UI.label("v2.1", 13, UI.MUTED, 3)
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

func on_back() -> bool:
	return true

func _start() -> void:
	if _started:
		return
	_started = true
	Game.sfx("gacha_gate")
	var flash := ColorRect.new()
	flash.color = Color(1, 0.9, 1, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.8, 0.25)
	tw.tween_callback(func(): main.enter_game())
