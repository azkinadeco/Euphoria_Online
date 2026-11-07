class_name OathCeremony
extends Control
## Oath Ceremony cinematic (played once when an Oath is sworn, replayable from the Bond tab):
## 1) a heavenly hall fades in under falling petals
## 2) the Oath Ring rises from the dark, spinning and glowing
## 3) a white bloom, then she appears in her Oath outfit with golden rays
## 4) "OATH SWORN" + the date; tap to hear her vow.

signal finished

var hero_id := ""
var _ring: Control
var _ring_t := 0.0
var _ring_glow := 0.0
var _phase := 0
var _done := false

func _init(id: String) -> void:
	hero_id = id
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40

func _ready() -> void:
	var dark := ColorRect.new()
	dark.color = Color(0.02, 0.01, 0.04, 1.0)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)
	var hall := UI.tex_rect(DB.bg("asgard"), Vector2.ZERO, true)
	hall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hall.modulate = Color(1.0, 0.92, 0.85, 0.0)
	hall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hall)
	var warm := ColorRect.new()
	warm.color = Color(1.0, 0.8, 0.85, 0.16)
	warm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	warm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm)
	add_child(FestivalFX.new("petal", Color("#ffc4dc"), 46))
	hall.create_tween().tween_property(hall, "modulate:a", 0.38, 1.2)
	Game.sfx("awakening")
	# --- the ring
	_ring = Control.new()
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	_ring.modulate.a = 0.0
	var rt := _ring.create_tween().set_parallel(true)
	rt.tween_property(_ring, "modulate:a", 1.0, 0.8).set_delay(0.4)
	var vow := UI.label("With this ring, I bind my heart to yours.", 22, Color("#ffe6f0"), 6)
	vow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	vow.offset_top = -120
	vow.offset_bottom = -80
	vow.offset_left = -500
	vow.offset_right = 500
	vow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vow.modulate.a = 0.0
	add_child(vow)
	vow.create_tween().tween_property(vow, "modulate:a", 1.0, 0.8).set_delay(1.0)
	await _sleep(3.0)
	if not is_inside_tree():
		return
	vow.queue_free()
	_reveal()

func _sleep(t: float) -> void:
	# tapping skips ahead
	var k := 0.0
	while k < t and is_inside_tree() and _phase == 0:
		await get_tree().create_timer(0.1).timeout
		k += 0.1

func _process(delta: float) -> void:
	_ring_t += delta
	_ring_glow = 0.5 + 0.5 * sin(_ring_t * 3.0)
	if is_instance_valid(_ring):
		_ring.queue_redraw()

func _draw_ring() -> void:
	var s := _ring.size
	var rise := minf(1.0, _ring_t / 1.6)
	var c := Vector2(s.x * 0.5, s.y * (0.62 - 0.14 * (1.0 - pow(1.0 - rise, 3.0))))
	var spin := cos(_ring_t * 1.8)       # fake 3D spin: squash the band horizontally
	var r := 96.0
	# glow halo
	for k in 6:
		var a := (0.10 - k * 0.014) * (0.6 + _ring_glow * 0.6)
		_ring.draw_circle(c, r * (1.3 + k * 0.32), Color(1.0, 0.85, 0.55, maxf(a, 0.0)))
	# light beam from above
	_ring.draw_rect(Rect2(c.x - 26, 0, 52, c.y), Color(1.0, 0.95, 0.8, 0.06 + _ring_glow * 0.05))
	# band (ellipse outline drawn with a polyline)
	var pts := PackedVector2Array()
	for i in 49:
		var ang := TAU * i / 48.0
		pts.append(c + Vector2(cos(ang) * r * maxf(0.18, absf(spin)), sin(ang) * r))
	_ring.draw_polyline(pts, Color("#b8862e"), 13.0, true)
	_ring.draw_polyline(pts, Color("#ffd479"), 8.0, true)
	_ring.draw_polyline(pts, Color(1, 0.97, 0.85, 0.8), 2.5, true)
	# gem on top
	var g := c + Vector2(0, -r - 6)
	var gw := 20.0 * maxf(0.4, absf(spin))
	var gem := PackedVector2Array([g + Vector2(0, -24), g + Vector2(gw, -8), g + Vector2(0, 14), g + Vector2(-gw, -8)])
	_ring.draw_colored_polygon(gem, Color("#ff8fb8"))
	_ring.draw_colored_polygon(PackedVector2Array([g + Vector2(0, -24), g + Vector2(gw, -8), g + Vector2(0, -6)]), Color("#ffd0e4"))
	# sparkle cross on the gem
	var sp := 10.0 + _ring_glow * 16.0
	_ring.draw_line(g + Vector2(-sp, -8), g + Vector2(sp, -8), Color(1, 1, 1, 0.9), 2.0)
	_ring.draw_line(g + Vector2(0, -8 - sp), g + Vector2(0, -8 + sp), Color(1, 1, 1, 0.9), 2.0)

func _reveal() -> void:
	_phase = 1
	Game.sfx("star_up")
	var bloom := ColorRect.new()
	bloom.color = Color(1, 0.97, 0.95, 0.0)
	bloom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloom.z_index = 5
	add_child(bloom)
	var bt := bloom.create_tween()
	bt.tween_property(bloom, "color:a", 1.0, 0.25)
	bt.tween_callback(func():
		if is_instance_valid(_ring):
			_ring.queue_free()
		_show_hero())
	bt.tween_property(bloom, "color:a", 0.0, 0.7)
	bt.tween_callback(bloom.queue_free)

func _show_hero() -> void:
	if ResourceLoader.exists("res://art/ui/rays.png"):
		var rays := TextureRect.new()
		rays.texture = load("res://art/ui/rays.png")
		rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var vs := get_viewport_rect().size
		rays.size = Vector2(1200, 1200)
		rays.pivot_offset = Vector2(600, 600)
		rays.position = Vector2(vs.x * 0.36 - 600, vs.y * 0.45 - 600)
		rays.modulate = Color(1, 0.85, 0.9, 0.7)
		var rm := CanvasItemMaterial.new()
		rm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rays.material = rm
		rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rays)
		rays.create_tween().set_loops().tween_property(rays, "rotation", TAU, 30.0).from(0.0)
	var art := UI.tex_rect(DB.art(hero_id, int(Game.hero(hero_id).get("skin", 0))))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_left = 0.08
	art.anchor_right = 0.62
	art.offset_top = 10
	add_child(art)
	UI.live(art, Color("#ffd0e4"))
	art.modulate.a = 0.0
	art.resized.connect(func(): art.pivot_offset = art.size * Vector2(0.5, 0.4))
	art.scale = Vector2(1.12, 1.12)
	var at := art.create_tween().set_parallel(true)
	at.tween_property(art, "modulate:a", 1.0, 0.6)
	at.tween_property(art, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.02, 0.08, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.anchor_left = 0.57
	shade.anchor_top = 0.24
	shade.anchor_bottom = 0.82
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	UI.fade_in(shade, 0.6, Vector2(50, 0))
	var v := UI.vbox(6)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.anchor_left = 0.6
	v.anchor_right = 0.96
	v.anchor_top = 0.26
	v.anchor_bottom = 0.8
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(v)
	v.add_child(UI.label("♥  ETERNAL OATH  ♥", 18, Color("#ff8fb8"), 4))
	var t := UI.label("OATH SWORN", 54, UI.GOLD, 10)
	v.add_child(t)
	v.add_child(UI.label(DB.name_of(hero_id), 28, Color.WHITE, 6))
	v.add_child(UI.label(DB.title_of(hero_id), 15, Color("#ffd0e4"), 3))
	v.add_child(UI.label("Bound on %s" % Game.oath_date(hero_id), 16, Color("#ffe6a3"), 3))
	v.add_child(UI.label("+10% all stats  •  Oath outfit unlocked", 15, UI.GREEN, 3))
	var tap := UI.label("Tap to continue", 14, UI.MUTED, 3)
	v.add_child(tap)
	tap.create_tween().set_loops().tween_property(tap, "modulate:a", 0.3, 0.8).from(1.0)
	UI.fade_in(v, 0.6, Vector2(50, 0))
	Game.voice(hero_id, "bond")
	await get_tree().create_timer(1.0).timeout
	_phase = 2

func _gui_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed):
		return
	if _phase == 0:
		_phase = 1
		_reveal()
	elif _phase == 2 and not _done:
		_done = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func():
			finished.emit()
			queue_free())
