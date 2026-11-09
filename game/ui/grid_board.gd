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

var _frame := 0
func _process(delta: float) -> void:
	_t += delta
	_frame += 1
	# highlights animate every frame; the idle rune rotation only needs ~20 fps
	if not highlights.is_empty() or selected.x >= 0 or _frame % 3 == 0:
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

## Polygon shrunk toward its centre by `k` (0..1).
func _inset(poly: PackedVector2Array, k: float) -> PackedVector2Array:
	var c := (poly[0] + poly[1] + poly[2] + poly[3]) * 0.25
	var out := PackedVector2Array()
	for p in poly:
		out.append(p.lerp(c, k))
	return out

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	for c in 3:
		for r in 3:
			var cell := Vector2i(c, r)
			var poly := cell_poly(cell)
			var base := tile_color
			if c == 0:
				base = base.lerp(Color(1.0, 0.55, 0.45, base.a), 0.25)
			# tile: darker at the back edge, lighter toward the viewer (reads as a lit stone slab)
			var top := Color(base.r * 0.6, base.g * 0.6, base.b * 0.7, base.a * 0.75)
			var bot := Color(minf(1.0, base.r * 1.15), minf(1.0, base.g * 1.1), minf(1.0, base.b * 1.1), base.a * 1.25)
			draw_polygon(poly, PackedColorArray([top, top, bot, bot]))
			if highlights.has(cell):
				var hc: Color = highlights[cell]
				var ha := hc.a * (0.55 + 0.45 * pulse)
				# glow fill (stronger at the front edge) + bright inner frame + a sweep line
				draw_polygon(poly, PackedColorArray([Color(hc, ha * 0.45), Color(hc, ha * 0.45), Color(hc, ha * 0.95), Color(hc, ha * 0.95)]))
				var ip := _inset(poly, 0.08)
				ip.append(ip[0])
				draw_polyline(ip, Color(hc.lightened(0.35), 0.55 + 0.4 * pulse), 2.0, true)
				var q := fmod(_t * 0.9 + (c + r) * 0.17, 1.0)
				var la := poly[0].lerp(poly[3], q)
				var lb := poly[1].lerp(poly[2], q)
				draw_line(la, lb, Color(1, 1, 1, 0.35 * (1.0 - absf(q - 0.5) * 2.0)), 2.0, true)
			if cell == hover:
				draw_colored_polygon(poly, Color(1, 1, 1, 0.10))
			var closed := poly.duplicate()
			closed.append(poly[0])
			var lc := line_color
			var lw := 1.5
			if cell == selected:
				lc = Color(1.0, 0.85, 0.45, 0.7 + 0.3 * pulse)
				lw = 3.0
			# soft outer glow + crisp edge
			draw_polyline(closed, Color(lc, lc.a * 0.25), lw + 3.0, true)
			draw_polyline(closed, lc, lw, true)
			# bevel: a faint inner highlight line
			var bev := _inset(poly, 0.06)
			bev.append(bev[0])
			draw_polyline(bev, Color(1, 1, 1, 0.07), 1.0, true)
			# corner brackets
			var cc := Color(lc.lightened(0.3), minf(1.0, lc.a + 0.25))
			for k in 4:
				var p0: Vector2 = poly[k]
				var pn: Vector2 = poly[(k + 1) % 4]
				var pp: Vector2 = poly[(k + 3) % 4]
				draw_line(p0, p0.lerp(pn, 0.14), cc, 2.0, true)
				draw_line(p0, p0.lerp(pp, 0.18), cc, 2.0, true)
			# inner rune: squashed (perspective) dashed ring turning slowly + 4 ticks
			var ctr := cell_center(cell)
			var rr := tile_h() * 0.26
			var rc := Color(lc.r, lc.g, lc.b, 0.2)
			var rot := _t * (0.35 if enemy_side else -0.35) + (c * 3 + r) * 0.7
			for k in 12:
				if k % 2 == 1:
					continue
				var a0 := rot + k * TAU / 12.0
				var pts := PackedVector2Array()
				for m in 5:
					var a := a0 + (TAU / 12.0) * m / 4.0
					pts.append(ctr + Vector2(cos(a) * rr * 1.25, sin(a) * rr * 0.62))
				draw_polyline(pts, rc, 1.2, true)
			for k in 4:
				var a2 := rot * -0.5 + k * PI / 2.0
				var d := Vector2(cos(a2) * 1.25, sin(a2) * 0.62)
				draw_line(ctr + d * rr * 0.55, ctr + d * rr * 0.8, Color(rc, 0.3), 1.2, true)
