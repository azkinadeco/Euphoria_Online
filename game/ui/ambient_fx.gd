class_name AmbientFX
extends Control
## Floating glowing motes / petals drifting upward. Purely decorative.

var color := Color(1.0, 0.8, 1.0)
var count := 40
var _p: Array = []

func _init(col: Color = Color(1.0, 0.8, 1.0), n: int = 40) -> void:
	color = col
	count = n
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	for i in count:
		_p.append(_spawn(true))

func _spawn(anywhere: bool) -> Dictionary:
	var s := size if size.x > 0 else Vector2(1280, 720)
	return {"pos": Vector2(randf() * s.x, randf() * s.y if anywhere else s.y + 10.0),
		"v": Vector2(randf_range(-12, 12), randf_range(-18, -45)), "r": randf_range(1.5, 4.0),
		"ph": randf() * TAU, "a": randf_range(0.25, 0.8)}

func _process(delta: float) -> void:
	for i in _p.size():
		var p: Dictionary = _p[i]
		p["ph"] += delta * 2.0
		p["pos"] += (p["v"] + Vector2(sin(p["ph"]) * 10.0, 0)) * delta
		if p["pos"].y < -10.0:
			_p[i] = _spawn(false)
	queue_redraw()

func _draw() -> void:
	for p in _p:
		var tw := 0.6 + 0.4 * sin(p["ph"] * 1.7)
		var c := Color(color.r, color.g, color.b, p["a"] * tw)
		draw_circle(p["pos"], p["r"] * 2.6, Color(c.r, c.g, c.b, c.a * 0.18))
		draw_circle(p["pos"], p["r"], c)
