class_name SkillFX
extends Node2D
## Lightweight vector skill effects (additive blend). One node draws every
## active effect; call the spawn helpers with global-ish local positions.

const ELEMENT_FX := {"FIRE": "fire", "WATER": "water", "ICE": "ice", "WIND": "wind", "LIGHTNING": "thunder",
	"EARTH": "earth", "LIGHT": "light", "DARK": "dark", "CHAOS": "dark"}

var fx: Array = []
var speed := 1.0

func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m

func _process(delta: float) -> void:
	if fx.is_empty():
		return
	for f in fx:
		f["t"] += delta * speed
	fx = fx.filter(func(f): return f["t"] < f["dur"] + f["delay"])
	queue_redraw()

func clear() -> void:
	fx.clear()
	queue_redraw()

func _add(kind: String, pos: Vector2, color: Color, size: float, dur: float, delay: float = 0.0, extra: Dictionary = {}) -> void:
	var parts: Array = []
	for i in 18:
		parts.append(Vector3(randf() * TAU, randf_range(0.4, 1.0), randf_range(0.6, 1.4)))
	var f := {"kind": kind, "pos": pos, "color": color, "size": size, "dur": dur, "t": 0.0, "delay": delay, "parts": parts, "seed": randi()}
	f.merge(extra)
	fx.append(f)

# ------------------------------------------------------------------ public API

## Element impact at a point.
func impact(element: String, pos: Vector2, color: Color, size: float = 60.0, delay: float = 0.0) -> void:
	var k: String = ELEMENT_FX.get(element, "burst")
	_add(k, pos, color, size, 0.7 if k in ["light", "dark", "fire"] else 0.55, delay)
	_add("burst", pos, color, size * 0.8, 0.35, delay)

func beam(from: Vector2, to: Vector2, color: Color, width: float = 18.0, delay: float = 0.0) -> void:
	_add("beam", from, color, width, 0.45, delay, {"to": to})

func pillar(pos: Vector2, color: Color, size: float = 50.0, delay: float = 0.0) -> void:
	_add("pillar", pos, color, size, 0.5, delay)

func wave(pos: Vector2, color: Color, size: float = 600.0) -> void:
	_add("wave", pos, color, size, 0.6)

func aura(pos: Vector2, color: Color, size: float = 60.0) -> void:
	_add("aura", pos, color, size, 0.6)

func heal(pos: Vector2, size: float = 50.0) -> void:
	_add("heal", pos, Color("#7dffb0"), size, 0.8)

## A meteor falling from above onto pos (trail + flash on landing).
func meteor(pos: Vector2, color: Color, size: float = 60.0, delay: float = 0.0) -> void:
	_add("meteor", pos, color, size, 0.5, delay, {"from": pos + Vector2(-size * 2.2, -size * 6.0)})
	_add("burst", pos, color, size * 1.1, 0.4, delay + 0.36)
	debris(pos, color, size * 0.8, delay + 0.36)

## A crescent slash across pos. angle in radians.
func slash(pos: Vector2, color: Color, size: float = 70.0, angle: float = -0.6, delay: float = 0.0) -> void:
	_add("slash", pos, color, size, 0.32, delay, {"angle": angle})

## Shards thrown up that fall with gravity.
func debris(pos: Vector2, color: Color, size: float = 50.0, delay: float = 0.0) -> void:
	_add("debris", pos, color, size, 0.7, delay)

## A spiral vortex that tightens into pos.
func vortex(pos: Vector2, color: Color, size: float = 90.0, delay: float = 0.0) -> void:
	_add("vortex", pos, color, size, 0.7, delay)

func death(pos: Vector2, size: float = 50.0) -> void:
	_add("death", pos, Color(0.7, 0.4, 1.0), size, 0.8)

# ------------------------------------------------------------------ drawing

func _draw() -> void:
	for f in fx:
		var lt: float = f["t"] - f["delay"]
		if lt < 0.0:
			continue
		var p: float = clampf(lt / f["dur"], 0.0, 1.0)
		call("_draw_" + str(f["kind"]), f, p)

func _c(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, clampf(a, 0.0, 1.0))

func _draw_meteor(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	var from: Vector2 = f["from"]
	var to: Vector2 = f["pos"]
	var fall := clampf(p / 0.72, 0.0, 1.0)
	var head := from.lerp(to, fall * fall)
	if fall < 1.0:
		var dir := (to - from).normalized()
		for i in 8:
			var k := float(i) / 8.0
			var tp := head - dir * s * 1.6 * k
			draw_circle(tp, s * 0.22 * (1.0 - k), _c(c.lightened(0.3 * (1.0 - k)), 0.7 * (1.0 - k)))
		draw_circle(head, s * 0.26, _c(Color(1, 0.98, 0.9), 0.95))
	else:
		var q := (p - 0.72) / 0.28
		draw_circle(to, s * (0.4 + q * 0.9), _c(c.lightened(0.5), 0.6 * (1.0 - q)))

func _draw_slash(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	var ang: float = f["angle"]
	var sweep := clampf(p * 1.8, 0.0, 1.0)
	var fade := 1.0 - clampf((p - 0.45) / 0.55, 0.0, 1.0)
	var a0 := ang - 1.3
	var a1 := a0 + 2.6 * sweep
	for k in 4:
		var w := 9.0 - k * 2.0
		var r := s * (1.0 - k * 0.06)
		draw_arc(f["pos"], r, a0, a1, 28, _c(c.lightened(0.15 * k + 0.2), fade * (1.0 - k * 0.18)), w, true)
	draw_arc(f["pos"], s * 0.98, a0, a1, 28, _c(Color.WHITE, fade * 0.9), 2.5, true)

func _draw_debris(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	for v in f["parts"]:
		var vx: float = cos(v.x) * s * 1.6 * v.y
		var vy: float = -absf(sin(v.x)) * s * 2.6 * v.z
		var q: Vector2 = f["pos"] + Vector2(vx * p, vy * p + 900.0 * p * p * 0.5 * (s / 60.0))
		var sz: float = 2.5 + 3.0 * float(v.z)
		draw_rect(Rect2(q - Vector2(sz, sz) * 0.5, Vector2(sz, sz * 0.7)), _c(c.lightened(0.35), 1.0 - p))

func _draw_vortex(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	var a := sin(p * PI)
	for arm in 3:
		var pts := PackedVector2Array()
		for i in 24:
			var k := float(i) / 23.0
			var r := s * (1.0 - p * 0.7) * (1.0 - k * 0.85)
			var ang := k * 4.5 + arm * TAU / 3.0 + p * 7.0
			pts.append(f["pos"] + Vector2(cos(ang), sin(ang) * 0.55) * r)
		draw_polyline(pts, _c(c.lightened(0.3), 0.8 * a), 3.5, true)
	draw_circle(f["pos"], s * 0.18 * a, _c(Color.WHITE, 0.6 * a))

func _draw_burst(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	draw_circle(f["pos"], s * (0.3 + p * 0.7), _c(c, 0.35 * (1.0 - p)))
	draw_arc(f["pos"], s * (0.2 + p * 1.1), 0, TAU, 40, _c(c.lightened(0.4), 1.0 - p), 4.0 * (1.0 - p) + 1.0, true)
	for v in f["parts"]:
		var d: float = s * (0.2 + p * 1.3 * v.y)
		var q: Vector2 = f["pos"] + Vector2(cos(v.x), sin(v.x)) * d
		draw_circle(q, 3.0 * v.z * (1.0 - p), _c(c.lightened(0.5), 1.0 - p))

func _draw_aura(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	var a := sin(p * PI)
	draw_circle(f["pos"], s, _c(c, 0.18 * a))
	for i in 3:
		var r := s * (0.5 + 0.25 * i) + p * 10.0
		draw_arc(f["pos"], r, p * TAU + i, p * TAU + i + PI * 1.2, 24, _c(c.lightened(0.3), 0.8 * a), 3.0, true)

func _draw_fire(f: Dictionary, p: float) -> void:
	var c := Color(1.0, 0.45, 0.1)
	var s: float = f["size"]
	draw_circle(f["pos"], s * 0.7 * (1.0 - p * 0.5), _c(c, 0.4 * (1.0 - p)))
	for v in f["parts"]:
		var rise: float = p * s * 1.6 * v.y
		var q: Vector2 = f["pos"] + Vector2(cos(v.x) * s * 0.6 * v.z * (0.4 + p), -rise)
		var col := Color(1.0, 0.85 - p * 0.6, 0.2 * (1.0 - p))
		draw_circle(q, (9.0 * v.z) * (1.0 - p), _c(col, 1.0 - p))

func _draw_water(f: Dictionary, p: float) -> void:
	var c := Color(0.3, 0.7, 1.0)
	var s: float = f["size"]
	for i in 2:
		var pp := clampf(p * 1.3 - i * 0.2, 0.0, 1.0)
		draw_arc(f["pos"], s * (0.3 + pp), 0, TAU, 40, _c(c, 1.0 - pp), 5.0 * (1.0 - pp) + 1.0, true)
	for v in f["parts"]:
		var ang: float = -PI * 0.5 + (v.x - PI) * 0.35
		var d: float = s * 1.2 * v.y * p
		var q: Vector2 = f["pos"] + Vector2(cos(ang), sin(ang)) * d + Vector2(0, 160.0 * p * p)
		draw_circle(q, 4.0 * v.z * (1.0 - p), _c(c.lightened(0.4), 1.0 - p))

func _draw_ice(f: Dictionary, p: float) -> void:
	var c := Color(0.65, 0.92, 1.0)
	var s: float = f["size"]
	var grow := minf(1.0, p * 3.0)
	var fade := 1.0 - maxf(0.0, (p - 0.5) * 2.0)
	for i in 8:
		var ang := i * TAU / 8.0 + 0.2
		var dir := Vector2(cos(ang), sin(ang))
		var tip: Vector2 = f["pos"] + dir * s * 1.1 * grow * (0.7 + 0.3 * (i % 2))
		var side := dir.orthogonal() * 7.0
		draw_colored_polygon(PackedVector2Array([f["pos"] + side, tip, f["pos"] - side]), _c(c, 0.75 * fade))
	draw_circle(f["pos"], s * 0.35, _c(Color.WHITE, 0.6 * fade))

func _draw_thunder(f: Dictionary, p: float) -> void:
	var c := Color(0.8, 0.7, 1.0)
	var s: float = f["size"]
	var top: Vector2 = f["pos"] + Vector2(0, -420)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f["seed"]) + int(p * 12.0)
	var pts := PackedVector2Array([top])
	for i in range(1, 9):
		var y := lerpf(top.y, f["pos"].y, i / 8.0)
		pts.append(Vector2(f["pos"].x + rng.randf_range(-22, 22) * (1.0 - i / 8.0), y))
	pts.append(f["pos"])
	var a := 1.0 - p
	if fmod(p * 10.0, 2.0) < 1.4:
		draw_polyline(pts, _c(c, a * 0.5), 14.0, true)
		draw_polyline(pts, _c(Color.WHITE, a), 4.0, true)
	draw_circle(f["pos"], s * 0.6 * (1.0 - p * 0.5), _c(c, 0.4 * a))

func _draw_wind(f: Dictionary, p: float) -> void:
	var c := Color(0.45, 1.0, 0.65)
	var s: float = f["size"]
	var a := sin(p * PI)
	for i in 4:
		var r := s * (0.3 + 0.22 * i)
		var st := p * TAU * 2.0 + i * 1.3
		draw_arc(f["pos"], r, st, st + PI * 0.9, 20, _c(c, a * 0.9), 4.0, true)

func _draw_earth(f: Dictionary, p: float) -> void:
	var c := Color(0.85, 0.6, 0.3)
	var s: float = f["size"]
	draw_arc(f["pos"] + Vector2(0, s * 0.3), s * (0.4 + p * 1.2), PI, TAU, 30, _c(c, 1.0 - p), 6.0 * (1.0 - p) + 1.0, true)
	for i in 6:
		var v: Vector3 = f["parts"][i]
		var fall := clampf(p * 2.0 - i * 0.08, 0.0, 1.0)
		var q: Vector2 = f["pos"] + Vector2(cos(v.x) * s * 0.7, -260.0 * (1.0 - fall) - s * 0.2 * v.y)
		var r := 9.0 * v.z
		draw_colored_polygon(PackedVector2Array([q + Vector2(-r, 0), q + Vector2(-r * 0.3, -r), q + Vector2(r, -r * 0.4), q + Vector2(r * 0.6, r * 0.7)]), _c(c.darkened(0.2), 1.0 - maxf(0.0, p - 0.7) * 3.0))

func _draw_light(f: Dictionary, p: float) -> void:
	var c := Color(1.0, 0.92, 0.55)
	var s: float = f["size"]
	var a := sin(p * PI)
	var w := s * 0.9 * a
	draw_rect(Rect2(f["pos"].x - w * 0.5, f["pos"].y - 500, w, 500 + s * 0.3), _c(c, 0.35 * a))
	draw_rect(Rect2(f["pos"].x - w * 0.15, f["pos"].y - 500, w * 0.3, 500 + s * 0.3), _c(Color.WHITE, 0.5 * a))
	for v in f["parts"]:
		var q: Vector2 = f["pos"] + Vector2(cos(v.x) * s * 0.6 * v.y, -p * 200.0 * v.z)
		draw_circle(q, 3.0, _c(c.lightened(0.5), a))

func _draw_dark(f: Dictionary, p: float) -> void:
	var c := Color(0.65, 0.3, 1.0)
	var s: float = f["size"]
	var a := sin(p * PI)
	draw_circle(f["pos"], s * 0.8 * a, _c(Color(0.35, 0.05, 0.6), 0.45 * a))
	for i in 5:
		var r := s * (1.2 - p) * (0.4 + 0.15 * i)
		var st := -p * TAU * 1.5 + i * 1.25
		draw_arc(f["pos"], maxf(2.0, r), st, st + PI * 0.7, 20, _c(c, a), 3.5, true)

func _draw_beam(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var from: Vector2 = f["pos"]
	var to: Vector2 = f["to"]
	var grow := minf(1.0, p * 4.0)
	var end := from.lerp(to, grow)
	var a := 1.0 - maxf(0.0, (p - 0.5) * 2.0)
	var w: float = f["size"]
	draw_line(from, end, _c(c, 0.35 * a), w * 2.2, true)
	draw_line(from, end, _c(c.lightened(0.4), 0.8 * a), w, true)
	draw_line(from, end, _c(Color.WHITE, a), w * 0.3, true)

func _draw_pillar(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	var a := sin(p * PI)
	var w := s * 0.8 * a
	draw_rect(Rect2(f["pos"].x - w * 0.5, f["pos"].y - 520, w, 520), _c(c, 0.4 * a))
	draw_rect(Rect2(f["pos"].x - w * 0.12, f["pos"].y - 520, w * 0.24, 520), _c(Color.WHITE, 0.6 * a))
	draw_circle(f["pos"], s * 0.6 * a, _c(c, 0.5 * a))

func _draw_wave(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	for i in 3:
		var pp := clampf(p * 1.4 - i * 0.18, 0.0, 1.0)
		draw_arc(f["pos"], s * pp, 0, TAU, 64, _c(c, (1.0 - pp) * 0.8), 10.0 * (1.0 - pp) + 2.0, true)

func _draw_heal(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	var a := sin(p * PI)
	draw_circle(f["pos"], s * 0.7, _c(c, 0.18 * a))
	for i in 6:
		var v: Vector3 = f["parts"][i]
		var q: Vector2 = f["pos"] + Vector2(cos(v.x) * s * 0.6, s * 0.3 - p * s * 1.5 * v.z)
		var r := 6.0
		draw_rect(Rect2(q.x - r, q.y - 2, r * 2, 4), _c(c, a))
		draw_rect(Rect2(q.x - 2, q.y - r, 4, r * 2), _c(c, a))

func _draw_death(f: Dictionary, p: float) -> void:
	var c: Color = f["color"]
	var s: float = f["size"]
	for v in f["parts"]:
		var q: Vector2 = f["pos"] + Vector2(cos(v.x) * s * 0.5 * v.y, -p * s * 2.0 * v.z)
		draw_circle(q, 4.0 * (1.0 - p), _c(c, 1.0 - p))
