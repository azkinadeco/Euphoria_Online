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

func _process(delta: float) -> void:
	var s := size
	for i in _p.size():
		var p: Dictionary = _p[i]
		p["ph"] += delta * 1.6
		p["rot"] += delta * (2.0 if kind in ["petal", "leaf"] else 0.0)
		var wob := Vector2(sin(p["ph"]) * (18.0 if kind != "rain" else 0.0), 0)
		if kind == "firefly":
			wob = Vector2(sin(p["ph"] * 0.7) * 20.0, cos(p["ph"]) * 14.0)
		p["pos"] += (p["v"] + wob) * delta
		var out: bool = p["pos"].y > s.y + 20 if _falls() else p["pos"].y < -30
		if kind == "firefly":
			out = p["pos"].x < -20 or p["pos"].x > s.x + 20 or p["pos"].y < -20 or p["pos"].y > s.y + 20
		if out:
			_p[i] = _spawn(kind == "firefly")
	queue_redraw()

func _draw() -> void:
	for p in _p:
		var pos: Vector2 = p["pos"]
		var r: float = p["r"]
		var c := Color(color.r, color.g, color.b, p["a"])
		match kind:
			"lantern":
				_lantern(pos, r * 1.15, c, p["ph"])
			"snow":
				draw_circle(pos, r * 0.7, c)
				draw_circle(pos, r * 1.5, Color(c.r, c.g, c.b, c.a * 0.15))
			"petal", "leaf":
				draw_set_transform(pos, p["rot"], Vector2(1.0, 0.55))
				draw_circle(Vector2.ZERO, r * (1.1 if kind == "petal" else 1.4), c)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"heart":
				draw_circle(pos + Vector2(-r * 0.5, 0), r * 0.6, c)
				draw_circle(pos + Vector2(r * 0.5, 0), r * 0.6, c)
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-r * 1.08, r * 0.2), pos + Vector2(r * 1.08, r * 0.2), pos + Vector2(0, r * 1.4)]), c)
			"rain":
				draw_line(pos, pos + Vector2(-2, r), Color(c.r, c.g, c.b, c.a * 0.5), 1.5)
			"firefly":
				var tw := 0.5 + 0.5 * sin(p["ph"] * 2.3)
				draw_circle(pos, r * 2.2, Color(c.r, c.g, c.b, 0.12 * tw))
				draw_circle(pos, r * 0.5, Color(c.r, c.g, c.b, c.a * tw))


## Paper sky lantern: soft halo, barrel-shaped glowing body with ribs, bright flame core and a tassel.
## Drawn additively, so shading comes from brightness (no dark fills). A plain white color gets a warm tint.
func _lantern(pos: Vector2, r: float, c: Color, ph: float) -> void:
	var base := c
	if c.s < 0.15:
		base = Color(1.0, 0.62, 0.3, c.a)
	var fl := 0.82 + 0.18 * sin(ph * 3.0) * sin(ph * 1.3 + 1.0)
	draw_set_transform(pos, sin(ph * 0.8) * 0.12, Vector2.ONE)
	draw_circle(Vector2.ZERO, r * 4.2, Color(base.r, base.g, base.b, 0.05 * fl))
	draw_circle(Vector2.ZERO, r * 2.4, Color(base.r, base.g, base.b, 0.09 * fl))
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
	draw_colored_polygon(body, Color(base.r * 0.75, base.g * 0.55, base.b * 0.45, 0.55 * base.a * fl))
	# ribs
	for x in [-0.45, 0.0, 0.45]:
		draw_line(Vector2(w * x * 0.8, -h + 1), Vector2(w * x, h - 1), Color(base.r, base.g * 0.8, base.b * 0.6, 0.22 * fl), 1.0, true)
	# glowing core: brighter towards the flame near the bottom
	draw_set_transform(pos, sin(ph * 0.8) * 0.12, Vector2(1.0, 1.35))
	draw_circle(Vector2(0, h * 0.12), r * 0.75, Color(base.r, base.g, base.b, 0.45 * fl))
	draw_circle(Vector2(0, h * 0.2), r * 0.42, Color(1, 0.92, 0.65, 0.75 * fl))
	draw_set_transform(pos, sin(ph * 0.8) * 0.12, Vector2.ONE)
	draw_circle(Vector2(0, h * 0.42), r * 0.22, Color(1, 1, 0.9, 0.9 * fl))
	# rims + tassel
	draw_line(Vector2(-w * 0.72, -h), Vector2(w * 0.72, -h), Color(1, 0.8, 0.5, 0.5 * fl), 1.6, true)
	draw_line(Vector2(-w * 0.72, h), Vector2(w * 0.72, h), Color(1, 0.8, 0.5, 0.5 * fl), 1.6, true)
	draw_line(Vector2(0, h), Vector2(sin(ph * 2.0) * 1.5, h + r * 0.9), Color(base.r, base.g, base.b, 0.35 * fl), 1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
