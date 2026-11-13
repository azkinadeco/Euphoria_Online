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
		if _live:
			_live.queue_redraw()
var selected := Vector2i(-1, -1):
	set(v):
		selected = v
		queue_redraw()
		if _live:
			_live.queue_redraw()
		if _runes:
			_runes.queue_redraw()
var hover := Vector2i(-1, -1)
var interactive := false:
	set(v):
		interactive = v
		mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE
var _t := 0.0

## The turning runes sit on their own child layer (always drawn last in each cell, and cells never overlap),
## so the idle board only redraws the runes; the tiles / frames / brackets stay recorded.
var _runes: Node2D
## Highlighted / selected cells pulse every frame: they are drawn on their own layer (between the tiles
## and the runes) so the other cells stay recorded. Cells are 8 px apart and their outlines reach < 4 px
## beyond the tile, so splitting them across layers does not change any pixel.
var _live: Node2D
const AABatch = preload("res://game/ui/aa_batch.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	_live = Node2D.new()
	add_child(_live)
	_live.draw.connect(_draw_live)
	resized.connect(_live.queue_redraw)
	_runes = Node2D.new()
	add_child(_runes)
	_runes.draw.connect(_draw_runes)
	resized.connect(queue_redraw)
	resized.connect(_runes.queue_redraw)

var _frame := 0
func _process(delta: float) -> void:
	_t += delta
	_frame += 1
	# highlights animate every frame; the idle rune rotation only needs ~20 fps
	if not highlights.is_empty() or selected.x >= 0:
		_live.queue_redraw()
		_runes.queue_redraw()
	elif _frame % 3 == 0:
		_runes.queue_redraw()

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

func _is_live(cell: Vector2i) -> bool:
	return cell == selected or highlights.has(cell)

func _draw() -> void:
	_draw_cells(self, false)

func _draw_live() -> void:
	_draw_cells(_live, true)

## Idle cells never change until the board is resized / recoloured / hovered, so each one's triangles
## are cached and re-submitted as is (a highlight change no longer rebuilds all nine cells).
var _cell_cache := {}

func _draw_cells(target: CanvasItem, live: bool) -> void:
	var b = AABatch.new()
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var rid := target.get_canvas_item()
	for c in 3:
		for r in 3:
			var cell := Vector2i(c, r)
			if _is_live(cell) != live:
				continue
			if live:
				_cell_into(b, cell, pulse)
				continue
			var key := "%d,%d|%s|%s|%s|%s|%s" % [c, r, size, max_aspect, cell == hover, tile_color, line_color]
			if not _cell_cache.has(key):
				var cb = AABatch.new()
				_cell_into(cb, cell, pulse)
				if _cell_cache.size() > 200:
					_cell_cache.clear()
				_cell_cache[key] = [cb.idx, cb.pts, cb.cols]
			var g: Array = _cell_cache[key]
			RenderingServer.canvas_item_add_triangle_array(rid, g[0], g[1], g[2])
	b.flush(target)

func _cell_into(b: Object, cell: Vector2i, pulse: float) -> void:
	var c := cell.x
	var r := cell.y
	var poly := cell_poly(cell)
	var base := tile_color
	if c == 0:
		base = base.lerp(Color(1.0, 0.55, 0.45, base.a), 0.25)
	# tile: darker at the back edge, lighter toward the viewer (reads as a lit stone slab)
	var top := Color(base.r * 0.6, base.g * 0.6, base.b * 0.7, base.a * 0.75)
	var bot := Color(minf(1.0, base.r * 1.15), minf(1.0, base.g * 1.1), minf(1.0, base.b * 1.1), base.a * 1.25)
	b.polygon(poly, PackedColorArray([top, top, bot, bot]))
	if highlights.has(cell):
		var hc: Color = highlights[cell]
		var ha := hc.a * (0.55 + 0.45 * pulse)
		# glow fill (stronger at the front edge) + bright inner frame + a sweep line
		b.polygon(poly, PackedColorArray([Color(hc, ha * 0.45), Color(hc, ha * 0.45), Color(hc, ha * 0.95), Color(hc, ha * 0.95)]))
		var ip := _inset(poly, 0.08)
		ip.append(ip[0])
		b.polyline(ip, Color(hc.lightened(0.35), 0.55 + 0.4 * pulse), 2.0)
		var q := fmod(_t * 0.9 + (c + r) * 0.17, 1.0)
		var la := poly[0].lerp(poly[3], q)
		var lb := poly[1].lerp(poly[2], q)
		b.line(la, lb, Color(1, 1, 1, 0.35 * (1.0 - absf(q - 0.5) * 2.0)), 2.0)
	if cell == hover:
		b.polygon(poly, PackedColorArray([Color(1, 1, 1, 0.10)]))
	var closed := poly.duplicate()
	closed.append(poly[0])
	var lc := line_color
	var lw := 1.5
	if cell == selected:
		lc = Color(1.0, 0.85, 0.45, 0.7 + 0.3 * pulse)
		lw = 3.0
	# soft outer glow + crisp edge
	b.polyline(closed, Color(lc, lc.a * 0.25), lw + 3.0)
	b.polyline(closed, lc, lw)
	# bevel: a faint inner highlight line
	var bev := _inset(poly, 0.06)
	bev.append(bev[0])
	b.polyline(bev, Color(1, 1, 1, 0.07), 1.0)
	# corner brackets
	var cc := Color(lc.lightened(0.3), minf(1.0, lc.a + 0.25))
	for k in 4:
		var p0: Vector2 = poly[k]
		var pn: Vector2 = poly[(k + 1) % 4]
		var pp: Vector2 = poly[(k + 3) % 4]
		b.line(p0, p0.lerp(pn, 0.14), cc, 2.0)
		b.line(p0, p0.lerp(pp, 0.18), cc, 2.0)

func _cell_line_color(cell: Vector2i, pulse: float) -> Color:
	if cell == selected:
		return Color(1.0, 0.85, 0.45, 0.7 + 0.3 * pulse)
	return line_color

## Rune geometry is cached per rotation step (local to the cell centre): the dashed ring repeats every
## TAU/6 and the ticks every PI/2, so RUNE_STEPS shapes per size cover the whole spin. Each redraw then only
## translates cached arrays (C++) and submits the 9 cells as one triangle array (1 draw call, was ~170).
const RUNE_STEPS := 240
static var _rune_geo := {}     # "rr:kind:step" -> PackedVector2Array
static var _rune_topo := {}    # "idx" / "cls" -> one cell's indices / vertex colour classes
static var _rune_cols := {}    # Color -> PackedColorArray for one cell

static func _rune_build(rr: float, rot_d: float, rot_t: float, dc: Color, tc: Color) -> Object:
	var b = AABatch.new()
	for k in 12:
		if k % 2 == 1:
			continue
		var a0 := rot_d + k * TAU / 12.0
		var pts := PackedVector2Array()
		for m in 5:
			var a := a0 + (TAU / 12.0) * m / 4.0
			pts.append(Vector2(cos(a) * rr * 1.25, sin(a) * rr * 0.62))
		b.polyline(pts, dc, 1.2)
	b.set_meta("split", b.pts.size())
	for k in 4:
		var a2 := rot_t + k * PI / 2.0
		var d := Vector2(cos(a2) * 1.25, sin(a2) * 0.62)
		b.line(d * rr * 0.55, d * rr * 0.8, tc, 1.2)
	return b

static func _rune_part(rr: float, kind: int, step: int) -> PackedVector2Array:
	var key := "%.3f:%d:%d" % [rr, kind, step]
	if not _rune_geo.has(key):
		var per := TAU / 6.0 if kind == 0 else PI / 2.0
		var ang := per * step / RUNE_STEPS
		var b = _rune_build(rr, ang, ang, Color(1, 0, 0, 1), Color(0, 1, 0, 1))
		var split: int = b.get_meta("split")
		_rune_geo[key] = b.pts.slice(0, split) if kind == 0 else b.pts.slice(split)
		if not _rune_topo.has("idx"):
			_rune_topo["idx"] = b.idx
			var cls := PackedByteArray()
			for c in b.cols:
				cls.append((0 if c.r > 0.5 else 2) + (0 if c.a > 0.5 else 1))
			_rune_topo["cls"] = cls
		if _rune_geo.size() > 4000:
			_rune_geo.clear()
	return _rune_geo[key]

static func _step(angle: float, per: float) -> int:
	return int(round(fposmod(angle, per) / per * RUNE_STEPS)) % RUNE_STEPS

func _rune_cell_cols(rc: Color) -> PackedColorArray:
	if not _rune_cols.has(rc):
		var b = AABatch.new()
		var tc: Color = b._h(Color(rc, 0.3))
		var pal := [rc, Color(rc.r, rc.g, rc.b, 0.0), tc, b._h(Color(Color(rc, 0.3), 0.0))]
		var out := PackedColorArray()
		for k in _rune_topo["cls"]:
			out.append(pal[k])
		if _rune_cols.size() > 64:
			_rune_cols.clear()
		_rune_cols[rc] = out
	return _rune_cols[rc]

func _draw_runes() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var rr := tile_h() * 0.26
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for c in 3:
		for r in 3:
			var cell := Vector2i(c, r)
			var lc := _cell_line_color(cell, pulse)
			# inner rune: squashed (perspective) dashed ring turning slowly + 4 ticks
			var rc := Color(lc.r, lc.g, lc.b, 0.2)
			var rot := _t * (0.35 if enemy_side else -0.35) + (c * 3 + r) * 0.7
			var xf := Transform2D(0.0, cell_center(cell))
			var dash := _rune_part(rr, 0, _step(rot, TAU / 6.0))
			var tick := _rune_part(rr, 1, _step(rot * -0.5, PI / 2.0))
			pts.append_array(xf * dash)
			pts.append_array(xf * tick)
			cols.append_array(_rune_cell_cols(rc))
	if not _rune_topo.has("idx9"):
		# every cell has the same topology: 9 copies of one cell's indices, offset per cell
		var one: PackedInt32Array = _rune_topo["idx"]
		var nv: int = pts.size() / 9
		var all := PackedInt32Array()
		for k in 9:
			for i in one:
				all.append(i + k * nv)
		_rune_topo["idx9"] = all
	RenderingServer.canvas_item_add_triangle_array(_runes.get_canvas_item(), _rune_topo["idx9"], pts, cols)
