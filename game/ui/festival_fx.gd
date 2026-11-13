class_name FestivalFX
extends Control
## Seasonal particle layer: lanterns, snow, petals, hearts, leaves, rain, fireflies.

var kind := "lantern"
var color := Color.WHITE
var count := 34
var _p: Array = []

func _init(k: String = "lantern", col: Color = Color.WHITE, n: int = 34) -> void:
	kind = k
	color = col
	count = n if not Game.reduce_fx() else n / 3
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	if kind in ["lantern", "firefly"]:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	for i in count:
		_p.append(_spawn(true))
	_is_fall = _falls()
	_spin = 2.0 if kind in ["petal", "leaf"] else 0.0
	for i in _p.size():
		_make_part(i)

func _falls() -> bool:
	return kind in ["snow", "petal", "leaf", "rain"]

func _spawn(anywhere: bool) -> Dictionary:
	var s := size if size.x > 0 else Vector2(1280, 720)
	var y := randf() * s.y if anywhere else (-12.0 if _falls() else s.y + 20.0)
	var v := Vector2.ZERO
	match kind:
		"lantern": v = Vector2(randf_range(-6, 6), randf_range(-14, -30))
		"heart": v = Vector2(randf_range(-8, 8), randf_range(-20, -40))
		"firefly": v = Vector2(randf_range(-15, 15), randf_range(-8, 8))
		"snow": v = Vector2(randf_range(-10, 10), randf_range(25, 55))
		"petal": v = Vector2(randf_range(20, 45), randf_range(30, 60))
		"leaf": v = Vector2(randf_range(10, 35), randf_range(35, 65))
		"rain": v = Vector2(-60, randf_range(420, 560))
	return {"pos": Vector2(randf() * s.x, y), "v": v, "r": randf_range(3.0, 7.0) if kind != "rain" else randf_range(10, 22),
		"ph": randf() * TAU, "rot": randf() * TAU, "a": randf_range(0.45, 0.95)}

## Each particle is its own retained Node2D: its shape is recorded once (and again only when it respawns),
## and every frame only its transform / alpha changes. Pixel-identical to redrawing everything each frame,
## but far cheaper (the old per-frame _draw rebuilt thousands of polygons, which tanked the web build).
class _Part extends Node2D:
	var fx
	var d: Dictionary
	func _draw() -> void:
		fx._draw_part(self, d)

## Lantern tassel: its tip sways on its own, so this single line is the only part redrawn every frame.
class _Tassel extends Node2D:
	var fx
	var d: Dictionary
	func _draw() -> void:
		fx._draw_tassel(self, d)

var _nodes: Array = []
var _tassels: Array = []
var _is_fall := false
var _spin := 0.0

func _make_part(i: int) -> void:
	var n := _Part.new()
	n.fx = self
	n.d = _p[i]
	n.use_parent_material = true
	if kind in ["petal", "leaf"]:
		n.scale = Vector2(1.0, 0.55)
	add_child(n)
	_nodes.append(n)
	if kind == "lantern":
		var t := _Tassel.new()
		t.fx = self
		t.d = _p[i]
		t.use_parent_material = true
		n.add_child(t)
		_tassels.append(t)
	_sync(i)

func _respawn(i: int, anywhere: bool) -> void:
	_p[i] = _spawn(anywhere)
	_nodes[i].d = _p[i]
	_nodes[i].queue_redraw()
	if kind == "lantern":
		_tassels[i].d = _p[i]
		_tassels[i].queue_redraw()

## Per-frame state -> node transform / alpha.
func _sync(i: int) -> void:
	var p: Dictionary = _p[i]
	var n: Node2D = _nodes[i]
	n.position = p["pos"]
	match kind:
		"lantern":
			var ph: float = p["ph"]
			n.rotation = sin(ph * 0.8) * 0.12
			n.modulate.a = 0.82 + 0.18 * sin(ph * 3.0) * sin(ph * 1.3 + 1.0)
			_tassels[i].queue_redraw()
		"petal", "leaf":
			n.rotation = p["rot"]
		"firefly":
			n.modulate.a = 0.5 + 0.5 * sin(p["ph"] * 2.3)

func _process(delta: float) -> void:
	var s := size
	var firefly := kind == "firefly"
	var wob_x := 18.0 if kind != "rain" else 0.0
	for i in _p.size():
		var p: Dictionary = _p[i]
		p["ph"] += delta * 1.6
		p["rot"] += delta * _spin
		var wob := Vector2(sin(p["ph"]) * wob_x, 0)
		if firefly:
			wob = Vector2(sin(p["ph"] * 0.7) * 20.0, cos(p["ph"]) * 14.0)
		p["pos"] += (p["v"] + wob) * delta
		var out: bool = p["pos"].y > s.y + 20 if _is_fall else p["pos"].y < -30
		if firefly:
			out = p["pos"].x < -20 or p["pos"].x > s.x + 20 or p["pos"].y < -20 or p["pos"].y > s.y + 20
		if out:
			_respawn(i, firefly)
		_sync(i)

## One particle at its local origin. Time-varying alpha (flicker / twinkle) comes from the node's modulate.
func _draw_part(ci: CanvasItem, p: Dictionary) -> void:
	var r: float = p["r"]
	var c := Color(color.r, color.g, color.b, p["a"])
	match kind:
		"lantern":
			_lantern(ci, r * 1.15, c)
		"snow":
			ci.draw_circle(Vector2.ZERO, r * 0.7, c)
			ci.draw_circle(Vector2.ZERO, r * 1.5, Color(c.r, c.g, c.b, c.a * 0.15))
		"petal", "leaf":
			ci.draw_circle(Vector2.ZERO, r * (1.1 if kind == "petal" else 1.4), c)
		"heart":
			ci.draw_circle(Vector2(-r * 0.5, 0), r * 0.6, c)
			ci.draw_circle(Vector2(r * 0.5, 0), r * 0.6, c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-r * 1.08, r * 0.2), Vector2(r * 1.08, r * 0.2), Vector2(0, r * 1.4)]), c)
		"rain":
			ci.draw_line(Vector2.ZERO, Vector2(-2, r), Color(c.r, c.g, c.b, c.a * 0.5), 1.5)
		"firefly":
			ci.draw_circle(Vector2.ZERO, r * 2.2, Color(c.r, c.g, c.b, 0.12))
			ci.draw_circle(Vector2.ZERO, r * 0.5, c)

func _lantern_base(c: Color) -> Color:
	return Color(1.0, 0.62, 0.3, c.a) if c.s < 0.15 else c

func _draw_tassel(ci: CanvasItem, p: Dictionary) -> void:
	var r: float = p["r"] * 1.15
	var base := _lantern_base(Color(color.r, color.g, color.b, p["a"]))
	var h := r * 1.45
	ci.draw_line(Vector2(0, h), Vector2(sin(float(p["ph"]) * 2.0) * 1.5, h + r * 0.9), Color(base.r, base.g, base.b, 0.35), 1.0, true)


## Paper sky lantern: soft halo, barrel-shaped glowing body with ribs, bright flame core (tassel: _draw_tassel).
## Drawn additively, so shading comes from brightness (no dark fills). A plain white color gets a warm tint.
## Drawn upright at the origin; sway rotation and flame flicker come from the node's transform / modulate.
func _lantern(ci: CanvasItem, r: float, c: Color) -> void:
	var base := _lantern_base(c)
	ci.draw_circle(Vector2.ZERO, r * 4.2, Color(base.r, base.g, base.b, 0.05))
	ci.draw_circle(Vector2.ZERO, r * 2.4, Color(base.r, base.g, base.b, 0.09))
	# barrel body: wider in the middle, flat top and bottom
	var body := PackedVector2Array()
	var w := r * 1.05
	var h := r * 1.45
	for k in 13:
		var t := k / 12.0
		body.append(Vector2(-w * (0.72 + 0.28 * sin(t * PI)), lerpf(-h, h, t)))
	for k in 13:
		var t := 1.0 - k / 12.0
		body.append(Vector2(w * (0.72 + 0.28 * sin(t * PI)), lerpf(-h, h, t)))
	ci.draw_colored_polygon(body, Color(base.r * 0.75, base.g * 0.55, base.b * 0.45, 0.55 * base.a))
	# ribs
	for x in [-0.45, 0.0, 0.45]:
		ci.draw_line(Vector2(w * x * 0.8, -h + 1), Vector2(w * x, h - 1), Color(base.r, base.g * 0.8, base.b * 0.6, 0.22), 1.0, true)
	# glowing core: brighter towards the flame near the bottom
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.35))
	ci.draw_circle(Vector2(0, h * 0.12), r * 0.75, Color(base.r, base.g, base.b, 0.45))
	ci.draw_circle(Vector2(0, h * 0.2), r * 0.42, Color(1, 0.92, 0.65, 0.75))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_circle(Vector2(0, h * 0.42), r * 0.22, Color(1, 1, 0.9, 0.9))
	# rims
	ci.draw_line(Vector2(-w * 0.72, -h), Vector2(w * 0.72, -h), Color(1, 0.8, 0.5, 0.5), 1.6, true)
	ci.draw_line(Vector2(-w * 0.72, h), Vector2(w * 0.72, h), Color(1, 0.8, 0.5, 0.5), 1.6, true)
