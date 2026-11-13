extends RefCounted
## Collects polygons / antialiased polylines / lines and submits them as ONE triangle array (one draw call).
##
## Each Godot draw_polyline(..., true) is 3 draw calls (strip + 2 feather strips) and every polygon is its
## own draw call, so a board of outlined tiles costs hundreds of calls per frame (slow on weak GPUs/WebGL).
## The geometry below is a line-for-line port of Godot 4.7's RendererCanvasCull::canvas_item_add_polyline /
## canvas_item_add_line / canvas_item_add_polygon, emitted in the same order, so the pixels match.
## Usage (inside a draw callback):  var b = AABatch.new(); b.polyline(...); b.line(...); b.flush(node)

const FEATHER := 1.25
const CMP_EPS := 0.00001

var idx := PackedInt32Array()
var pts := PackedVector2Array()
var cols := PackedColorArray()
var _half := PackedByteArray()
## Like CanvasItem.draw_set_transform: applied to every shape added afterwards.
var xf := Transform2D.IDENTITY

func _init() -> void:
	_half.resize(2)

func is_empty() -> bool:
	return idx.is_empty()

## Sends everything collected so far to `ci` (a CanvasItem, during its draw) and clears the buffers.
func flush(ci: CanvasItem) -> void:
	if not idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)
	idx = PackedInt32Array()
	pts = PackedVector2Array()
	cols = PackedColorArray()

static func comp_width(w: float) -> float:
	if w > 0.0:
		if w <= FEATHER * 2.0 + CMP_EPS:
			return w * 0.5
		elif w <= FEATHER * 4.0 + CMP_EPS:
			return remap(w, FEATHER * 2.0, FEATHER * 4.0, w * 0.5, w - FEATHER * 0.5)
		return w - FEATHER * 0.5
	return w

func _put(p: PackedVector2Array) -> void:
	pts.append_array(p if xf == Transform2D.IDENTITY else xf * p)

func _strip(p: PackedVector2Array, c: PackedColorArray) -> void:
	var b := pts.size()
	_put(p)
	cols.append_array(c)
	for k in p.size() - 2:
		idx.append(b + k)
		idx.append(b + k + 1)
		idx.append(b + k + 2)

## Same as CanvasItem.draw_polygon (colors: 1 or one per point).
func polygon(p: PackedVector2Array, c: PackedColorArray) -> void:
	var tri := Geometry2D.triangulate_polygon(p)
	if tri.is_empty():
		return
	var b := pts.size()
	_put(p)
	if c.size() == p.size():
		cols.append_array(c)
	else:
		for i in p.size():
			cols.append(c[0])
	for t in tri:
		idx.append(b + t)

static func _seg_dir(p: PackedVector2Array, i: int, prev: Vector2) -> Vector2:
	if i == p.size() - 1:
		return prev
	var d := (p[i + 1] - p[i]).normalized()
	if d.is_zero_approx():
		d = prev
	return d

static func _edge_off(seg: Vector2, prev: Vector2) -> Vector2:
	var length := 1.0
	var bis := (prev * seg.length() - seg * prev.length()).normalized()
	var ang := atan2(bis.cross(prev), bis.dot(prev))
	var s := sin(ang)
	if not is_zero_approx(s) and not seg.is_equal_approx(prev):
		length = clampf(1.0 / s, -3.0, 3.0)
	else:
		bis = seg.orthogonal()
	if bis.is_zero_approx():
		bis = seg.orthogonal()
	return bis * length

## Same as CanvasItem.draw_polyline(p, color, width, true).
func polyline(p: PackedVector2Array, color: Color, width: float) -> void:
	var n := p.size()
	if n < 2:
		return
	width = comp_width(width)
	var ppc := n * 2
	var loop := p[0].is_equal_approx(p[n - 1])
	var first_dir := Vector2.ZERO
	var last_dir := Vector2.ZERO
	for i in range(1, n):
		first_dir = (p[i] - p[i - 1]).normalized()
		if not first_dir.is_zero_approx():
			break
	for i in range(n - 1, 0, -1):
		last_dir = (p[i] - p[i - 1]).normalized()
		if not last_dir.is_zero_approx():
			break
	var extra := 0 if loop else 4
	var mp := PackedVector2Array(); mp.resize(ppc + extra)
	var mc := PackedColorArray(); mc.resize(ppc + extra)
	var lp := PackedVector2Array(); lp.resize(ppc + (0 if loop else 5))
	var lcol := PackedColorArray(); lcol.resize(ppc + (0 if loop else 5))
	var rp := PackedVector2Array(); rp.resize(ppc + (0 if loop else 5))
	var rcol := PackedColorArray(); rcol.resize(ppc + (0 if loop else 5))
	var bsz := FEATHER
	if width < 1.0:
		bsz *= width
	var c := color
	var c2 := Color(color.r, color.g, color.b, 0.0)
	var prev := Vector2.ZERO
	for i in n:
		var is_first := i == 0
		var is_last := i == n - 1
		var seg := _seg_dir(p, i, prev)
		if is_first and loop:
			prev = last_dir
		elif is_last and loop:
			prev = first_dir
		var beo: Vector2
		if is_first and not loop:
			beo = first_dir.orthogonal()
		elif is_last and not loop:
			beo = last_dir.orthogonal()
		else:
			beo = _edge_off(seg, prev)
		var eo := beo * (width * 0.5)
		var border := beo * bsz
		var pos := p[i]
		var j := i * 2 + (0 if loop else 2)
		mp[j] = pos + eo
		mp[j + 1] = pos - eo
		lp[j] = pos + eo
		lp[j + 1] = pos + eo + border
		rp[j] = pos - eo
		rp[j + 1] = pos - eo - border
		mc[j] = c; mc[j + 1] = c
		lcol[j] = c; lcol[j + 1] = c2
		rcol[j] = c; rcol[j + 1] = c2
		if is_first and not loop:
			var bb := -seg * bsz
			mp[0] = pos + eo + bb
			mp[1] = pos - eo + bb
			mc[0] = c2; mc[1] = c2
			lp[0] = pos + eo + bb
			lp[1] = pos + eo + bb + border
			lcol[0] = c2; lcol[1] = c2
			rp[0] = pos - eo + bb
			rp[1] = pos - eo + bb - border
			rcol[0] = c2; rcol[1] = c2
		if is_last and not loop:
			var eb := prev * bsz
			var e := ppc + 2
			mp[e] = pos + eo + eb
			mp[e + 1] = pos - eo + eb
			mc[e] = c2; mc[e + 1] = c2
			lp[e] = pos + eo
			lp[e + 1] = pos + eo + eb + border
			lp[e + 2] = pos + eo + eb
			lcol[e] = c; lcol[e + 1] = c2; lcol[e + 2] = c2
			rp[e] = pos - eo
			rp[e + 1] = pos - eo + eb - border
			rp[e + 2] = pos - eo + eb
			rcol[e] = c; rcol[e + 1] = c2; rcol[e + 2] = c2
		prev = seg
	_strip(mp, mc)
	_strip(lp, lcol)
	_strip(rp, rcol)

## Primitive colours go through half floats in the GL renderer; round the same way.
func _h(c: Color) -> Color:
	var o := Color()
	for k in 4:
		_half.encode_half(0, c[k])
		o[k] = _half.decode_half(0)
	return o

func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var s := pts.size()
	_put(PackedVector2Array([a, b, c, d]))
	cols.append(ca); cols.append(cb); cols.append(cc); cols.append(cd)
	idx.append(s); idx.append(s + 1); idx.append(s + 2)
	idx.append(s); idx.append(s + 2); idx.append(s + 3)

## Same as CanvasItem.draw_line(a, b, color, width, aa).
func line(from: Vector2, to: Vector2, color: Color, width: float, aa: bool = true) -> void:
	var diff := from - to
	var dir := diff.orthogonal().normalized()
	if aa:
		width = comp_width(width)
	var t := dir * width * 0.5
	var bl := from + t
	var br := from - t
	var el := to + t
	var er := to - t
	var col := _h(color)
	var tr := _h(Color(color, 0.0))
	_quad(bl, br, er, el, col, col, col, col)
	if not aa:
		return
	var bsz := FEATHER
	if 0.0 <= width and width < 1.0:
		bsz *= width
	var dir2 := diff.normalized()
	var border := dir * bsz
	var border2 := dir2 * bsz
	_quad(bl, bl + border, el + border, el, col, tr, tr, col)
	_quad(br, br - border, er - border, er, col, tr, tr, col)
	_quad(bl, bl + border2, br + border2, br, col, tr, tr, col)
	_quad(el, el - border2, er - border2, er, col, tr, tr, col)
	_quad(bl, bl + border2, bl + border + border2, bl + border, col, tr, tr, tr)
	_quad(br, br + border2, br - border + border2, br - border, col, tr, tr, tr)
	_quad(el, el - border2, el + border - border2, el + border, col, tr, tr, tr)
	_quad(er, er - border2, er - border - border2, er - border, col, tr, tr, tr)

## Same as CanvasItem.draw_circle(pos, r, color) (filled, not antialiased): a 64-segment fan.
func circle(pos: Vector2, r: float, color: Color) -> void:
	var p := PackedVector2Array()
	p.resize(66)
	var step := TAU / 64.0
	for i in 65:
		var a := i * step
		p[i] = Vector2(cos(a) * r, sin(a) * r) + pos
	p[65] = pos
	var b := pts.size()
	_put(p)
	for i in 66:
		cols.append(color)
	for i in 64:
		idx.append(b + 65)
		idx.append(b + i)
		idx.append(b + i + 1)

## Same as CanvasItem.draw_arc(c, r, a0, a1, n, color, width, true).
func arc(c: Vector2, r: float, a0: float, a1: float, n: int, color: Color, width: float) -> void:
	var p := PackedVector2Array()
	p.resize(n)
	var da := clampf(a1 - a0, -TAU, TAU)
	for i in n:
		var th := (i / (n - 1.0)) * da + a0
		p[i] = c + Vector2(r * cos(th), r * sin(th))
	polyline(p, color, width)

## Same as CanvasItem.draw_rect(rect, color) (filled).
func rect(r: Rect2, color: Color) -> void:
	var col := _h(color)
	_quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), col, col, col, col)
