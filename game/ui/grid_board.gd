class_name GridBoard
extends Control
## 3x3 perspective battle grid (Brown Dust style).
## col 0 = front line (closest to the enemy). Allies face right, enemies face left.

signal cell_pressed(cell: Vector2i)

@export var enemy_side := false
@export var tile_color := Color(0.55, 0.45, 0.95, 0.20)
@export var line_color := Color(0.75, 0.65, 1.0, 0.55)
const SKEW_K := 0.32
const GAP := 4.0

var highlights: Dictionary = {}:   # Vector2i -> Color
	set(v):
		highlights = v
		queue_redraw()
var selected := Vector2i(-1, -1):
	set(v):
		selected = v
		queue_redraw()
var hover := Vector2i(-1, -1)
var interactive := false:
	set(v):
		interactive = v
		mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if not highlights.is_empty() or selected.x >= 0:
		_t += delta
		queue_redraw()

var max_aspect := 0.52   # board height / width (battle uses a taller, closer board)

func _board_h() -> float:
	return minf(size.y, size.x * max_aspect)

func _origin_y() -> float:
	return (size.y - _board_h()) * 0.6

func tile_w() -> float:
	return size.x / (3.0 + 2.0 * SKEW_K)

func tile_h() -> float:
	return _board_h() / 3.0

func cell_poly(cell: Vector2i) -> PackedVector2Array:
	var tw := tile_w()
	var th := tile_h()
	var sk := tw * SKEW_K
	var col_vis: int = cell.x if enemy_side else 2 - cell.x
	var row := cell.y
	var x0: float
	var dx_bottom: float
	if enemy_side:
		x0 = col_vis * tw + row * sk
		dx_bottom = sk
	else:
		x0 = col_vis * tw + (2 - row) * sk
		dx_bottom = -sk
	var y0 := _origin_y() + row * th
	var g := GAP
	var a := Vector2(x0 + g, y0 + g)
	var b := Vector2(x0 + tw - g, y0 + g)
	var c := Vector2(x0 + tw - g + dx_bottom, y0 + th - g)
	var d := Vector2(x0 + g + dx_bottom, y0 + th - g)
	return PackedVector2Array([a, b, c, d])

func cell_center(cell: Vector2i) -> Vector2:
	var p := cell_poly(cell)
	return (p[0] + p[1] + p[2] + p[3]) * 0.25

## Point where a unit's feet should stand (slightly below tile centre).
func cell_foot(cell: Vector2i) -> Vector2:
	return cell_center(cell) + Vector2(0, tile_h() * 0.22)

func cell_at(local_point: Vector2) -> Vector2i:
	for c in 3:
		for r in 3:
			if Geometry2D.is_point_in_polygon(local_point, cell_poly(Vector2i(c, r))):
				return Vector2i(c, r)
	return Vector2i(-1, -1)

func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseMotion:
		var c := cell_at(event.position)
		if c != hover:
			hover = c
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c2 := cell_at(event.position)
		if c2.x >= 0:
			cell_pressed.emit(c2)
			accept_event()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	for c in 3:
		for r in 3:
			var cell := Vector2i(c, r)
			var poly := cell_poly(cell)
			var base := tile_color
			if c == 0:
				base = base.lerp(Color(1.0, 0.55, 0.45, base.a), 0.25)
			draw_colored_polygon(poly, base)
			if highlights.has(cell):
				var hc: Color = highlights[cell]
				draw_colored_polygon(poly, Color(hc.r, hc.g, hc.b, hc.a * (0.55 + 0.45 * pulse)))
			if cell == hover:
				draw_colored_polygon(poly, Color(1, 1, 1, 0.10))
			var closed := poly.duplicate()
			closed.append(poly[0])
			var lc := line_color
			var lw := 1.5
			if cell == selected:
				lc = Color(1.0, 0.85, 0.45, 0.7 + 0.3 * pulse)
				lw = 3.0
			draw_polyline(closed, lc, lw, true)
			# inner rune ring
			var ctr := cell_center(cell)
			draw_arc(ctr, tile_h() * 0.26, 0, TAU, 32, Color(lc.r, lc.g, lc.b, 0.22), 1.2, true)
