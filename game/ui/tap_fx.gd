extends Control
## A tiny burst of light wherever the screen is tapped: a ring that opens and a few sparks. Purely cosmetic,
## never takes input. One node on top of everything (added by Main); off with Reduce effects.

var _bursts: Array = []   # {p, age, sparks:[{d, sp, w}], col}
const LIFE := 0.42

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add
	set_process(false)

func burst(at: Vector2, col: Color = Color(1.0, 0.88, 0.6)) -> void:
	if _bursts.size() > 6:
		_bursts.pop_front()
	var sparks: Array = []
	for i in 6:
		var a := randf() * TAU
		sparks.append({"d": Vector2(cos(a), sin(a)), "sp": randf_range(46.0, 96.0), "w": randf_range(1.4, 2.6)})
	_bursts.append({"p": at, "age": 0.0, "sparks": sparks, "col": col})
	set_process(true)

func _process(delta: float) -> void:
	for b in _bursts:
		b["age"] = float(b["age"]) + delta
	_bursts = _bursts.filter(func(b): return float(b["age"]) < LIFE)
	if _bursts.is_empty():
		set_process(false)
	queue_redraw()

func _draw() -> void:
	for b in _bursts:
		var k: float = float(b["age"]) / LIFE
		var e := 1.0 - pow(1.0 - k, 3.0)          # ease out
		var p: Vector2 = b["p"]
		var col: Color = b["col"]
		draw_arc(p, 6.0 + e * 22.0, 0, TAU, 28, Color(col, 0.55 * (1.0 - k)), 2.2 * (1.0 - k) + 0.4, true)
		draw_circle(p, 5.0 * (1.0 - k), Color(col.lightened(0.5), 0.5 * (1.0 - k)))
		for s in b["sparks"]:
			var q: Vector2 = p + (s["d"] as Vector2) * float(s["sp"]) * e
			var q0: Vector2 = q - (s["d"] as Vector2) * 7.0 * (1.0 - k)
			draw_line(q0, q, Color(col.lightened(0.3), 0.9 * (1.0 - k)), float(s["w"]) * (1.0 - k) + 0.3, true)
