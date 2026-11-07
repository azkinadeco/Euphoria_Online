class_name ShapePreview
extends Control
## Small 3x3 diagram showing which enemy cells a skill hits.
## Left column = enemy front line. Gold = aimed cell, red = also hit.

var skill: Dictionary = {}

func _init(sk: Dictionary = {}, sz: Vector2 = Vector2(96, 96)) -> void:
	skill = sk
	custom_minimum_size = sz
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var cell := minf(size.x, size.y) / 3.0
	var off := Vector2((size.x - cell * 3) * 0.5, (size.y - cell * 3) * 0.5)
	var aim := str(skill.get("aim", "front"))
	var shape := str(skill.get("shape", "single"))
	var target := Vector2i(2 if aim == "back" else 0, 1)
	var hits: Array = DB.shape_cells(shape, target)
	if aim == "ally_all":
		hits = DB.shape_cells("all", target)
	for c in 3:
		for r in 3:
			var rect := Rect2(off + Vector2(c * cell, r * cell) + Vector2(2, 2), Vector2(cell - 4, cell - 4))
			var col := Color(1, 1, 1, 0.08)
			if hits.has(Vector2i(c, r)):
				col = Color("#5ce07a", 0.75) if aim == "ally_all" else Color("#ff5c6c", 0.75)
			if Vector2i(c, r) == target and aim != "ally_all":
				col = Color("#ffd479", 0.95)
			draw_rect(rect, col, true)
			draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)
	var font := get_theme_default_font()
	draw_string(font, off + Vector2(0, cell * 3 + 12), "FRONT" if aim != "ally_all" else "ALLIES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.5))
