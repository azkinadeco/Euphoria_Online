extends Control
## Backdrop of the ULTIMATE cut-in: radial glow, rotating god rays, magic circle, halftone dots and a
## drifting watermark of the skill name. Drawn exactly like the old per-shape draw_* code (same shapes,
## same order) but batched with AABatch, and the parts that never move (glow, rings, dots) are built once,
## so it is ~6 draw calls instead of ~330.  Set `phase` 0..1 to animate.

const AABatch = preload("res://game/ui/aa_batch.gd")

var ec := Color.WHITE
var wm := ""
var phase := 0.0:
	set(v):
		phase = v
		queue_redraw()
		if _anim:
			_anim.queue_redraw()
			_wm.queue_redraw()

var _glow: Array = []
var _glow_size := Vector2(-1, -1)
var _anim: Control
var _wm: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer(_draw_rings)
	_anim = _layer(_draw_anim)
	_layer(_draw_dots)
	_wm = _layer(_draw_wm)

func _layer(cb: Callable) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	c.draw.connect(cb.bind(c))
	return c

func _gc() -> Vector2:
	return Vector2(size.x * 0.26, size.y * 0.46)

func _mc() -> Color:
	return Color(ec.lightened(0.45), 0.55)

## radial glow behind the hero (cached) + god rays
func _draw() -> void:
	var s := size
	var t: float = phase * 1.6
	var gc := _gc()
	if _glow_size != s:
		var g = AABatch.new()
		for k in 10:
			g.circle(gc, s.y * (0.75 - k * 0.06), Color(ec, 0.035))
		_glow = [g.pts, g.cols, g.idx]
		_glow_size = s
	var b = AABatch.new()
	b.pts = _glow[0]
	b.cols = _glow[1]
	b.idx = _glow[2]
	var c0 := Color(ec.lightened(0.5), 0.16)
	var c1 := Color(ec, 0.0)
	for k in 14:
		var a := t * 0.25 + k * TAU / 14.0
		var a2 := a + 0.07
		var R := s.x
		b.polygon(PackedVector2Array([gc, gc + Vector2(cos(a), sin(a)) * R, gc + Vector2(cos(a2), sin(a2)) * R]),
			PackedColorArray([c0, c1, c1]))
	b.flush(self)

## the two still rings of the magic circle
func _draw_rings(c: Control) -> void:
	var r1 := size.y * 0.42
	var mc := _mc()
	var b = AABatch.new()
	b.arc(_gc(), r1, 0, TAU, 96, mc, 2.5)
	b.arc(_gc(), r1 * 0.86, 0, TAU, 96, Color(mc, 0.35), 1.5)
	b.flush(c)

## rotating outer arc, ticks and the inscribed hexagram
func _draw_anim(c: Control) -> void:
	var t: float = phase * 1.6
	var gc := _gc()
	var r1 := size.y * 0.42
	var mc := _mc()
	var b = AABatch.new()
	b.arc(gc, r1 * 1.08, t * 0.8, t * 0.8 + PI * 1.3, 64, Color(mc, 0.5), 3.0)
	for k in 36:
		var a3 := -t * 0.6 + k * TAU / 36.0
		var d := Vector2(cos(a3), sin(a3))
		b.line(gc + d * r1 * 0.88, gc + d * r1 * (0.97 if k % 3 == 0 else 0.93), Color(mc, 0.6), 1.5)
	for tri in 2:
		var pts := PackedVector2Array()
		for k in 4:
			var a4 := t * 0.4 + tri * PI / 3.0 + k * TAU / 3.0 - PI / 2.0
			pts.append(gc + Vector2(cos(a4), sin(a4)) * r1 * 0.84)
		b.polyline(pts, Color(mc, 0.3), 1.5)
	b.flush(c)

## halftone dots fading toward the right side
func _draw_dots(c: Control) -> void:
	var s := size
	var col := Color(ec.lightened(0.3), 0.12)
	var b = AABatch.new()
	var step := 22.0
	var y := s.y * 0.55
	while y < s.y:
		var x := s.x * 0.45
		while x < s.x:
			var f := clampf((y - s.y * 0.55) / (s.y * 0.45), 0.0, 1.0) * clampf((x - s.x * 0.45) / (s.x * 0.4), 0.0, 1.0)
			if f > 0.05:
				b.circle(Vector2(x + fmod(y, step * 2.0) * 0.5, y), 1.0 + 4.0 * f, col)
			x += step
		y += step
	b.flush(c)

## giant watermark, drifting left
func _draw_wm(c: Control) -> void:
	var t: float = phase * 1.6
	c.draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.15 - t * 80.0, size.y * 0.97), wm, HORIZONTAL_ALIGNMENT_LEFT, -1, 150, Color(ec.lightened(0.6), 0.07))
