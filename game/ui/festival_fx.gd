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
				var fl := 0.8 + 0.2 * sin(p["ph"] * 3.0)
				draw_circle(pos, r * 4.0, Color(c.r, c.g, c.b, 0.10 * fl))
				draw_rect(Rect2(pos - Vector2(r, r * 1.3), Vector2(r * 2, r * 2.6)), Color(c.r, c.g, c.b, c.a * fl))
				draw_rect(Rect2(pos - Vector2(r * 0.5, r * 0.8), Vector2(r, r * 1.6)), Color(1, 0.95, 0.75, 0.7 * fl))
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
