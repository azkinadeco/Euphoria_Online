extends Control


## One-shot sparkle burst: a soft flash, light rays and four-point stars flying outward. Frees itself.

var col := Color(1, 0.85, 0.4)
var radius := 60.0
var dur := 0.7
var _t := 0.0
var wait := 0.0
var _rays: Array = []
var _stars: Array = []

static func spawn(parent: Node, center: Vector2, color: Color, r: float = 60.0, delay: float = 0.0) -> void:
	if Game.reduce_fx():
		return
	var b = load("res://game/ui/burst_fx.gd").new()
	b.col = color
	b.radius = r
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.position = center
	b.size = Vector2.ZERO
	parent.add_child(b)
	b.wait = delay

func _ready() -> void:
	for i in 10:
		_rays.append([TAU * i / 10.0 + randf_range(-0.15, 0.15), randf_range(0.7, 1.15)])
	for i in 8:
		_stars.append([randf() * TAU, randf_range(0.6, 1.25), randf_range(3.0, 6.5), randf_range(-3.0, 3.0)])

func _process(delta: float) -> void:
	if wait > 0.0:
		wait -= delta
		return
	_t += delta
	if _t >= dur:
		queue_free()
		return
	queue_redraw()

func _star(p: Vector2, s: float, rot: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := rot + TAU * i / 8.0
		var r := s if i % 2 == 0 else s * 0.28
		pts.append(p + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, c)

func _draw() -> void:
	if wait > 0.0:
		return
	var k := _t / dur
	var e := 1.0 - pow(1.0 - k, 3.0)
	var fade := 1.0 - k
	# flash
	var fl := maxf(0.0, 1.0 - k * 3.0)
	draw_circle(Vector2.ZERO, radius * (0.3 + 0.5 * e), Color(col.r, col.g, col.b, 0.35 * fl))
	draw_circle(Vector2.ZERO, radius * (0.15 + 0.25 * e), Color(1, 1, 1, 0.5 * fl))
	# rays
	for r in _rays:
		var dir := Vector2(cos(float(r[0])), sin(float(r[0])))
		var a := dir * radius * (0.25 + 0.35 * e)
		var b := dir * radius * (0.45 + 0.75 * e) * float(r[1])
		draw_line(a, b, Color(col.r, col.g, col.b, 0.8 * fade), 2.5 * fade + 0.5, true)
	# stars
	for st in _stars:
		var dir := Vector2(cos(float(st[0])), sin(float(st[0])))
		var p := dir * radius * (0.3 + 0.9 * e) * float(st[1]) + Vector2(0, 10.0 * k * k)
		_star(p, float(st[2]) * (0.6 + 0.6 * fade), float(st[3]) * _t, Color(1, 1, 0.9, fade))
		_star(p, float(st[2]) * 1.7 * fade, float(st[3]) * _t, Color(col.r, col.g, col.b, 0.35 * fade))
