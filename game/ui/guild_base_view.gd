extends Control
## Guild Base: an isometric guild hall where every online member's main hero walks around as a chibi.
## The room is drawn in code (no art assets): wooden floor, two walls with windows and light, a rug in the
## guild colour with its emblem, and furniture blocks that are also the guild's stations:
##   raid portal (Guild Raid), notice board (check-in / donate), shop counter (Guild Shop),
##   bookshelf (Guild Tech), banner (members). Tapping a station emits `station(key)`.
## Tap the floor to walk your own chibi (Commander's lobby hero) there; tap a member to emit `member(m)`.
## Online members are simulated for now ([AI]); with online mode `set_members()` gets the real ones.
## Preloaded by screens/guild.gd, no class_name.

signal station(key: String)
signal member(m: Dictionary)

const N := 12.0          # tiles along the right wall (x)
const M := 10.0          # tiles along the left wall (y)
const WALL := 2.6        # wall height in tile widths * 0.5

var guild_color := Color("#ffd479")
var guild_initial := "G"
var _k := 40.0           # tile width in px
var _o := Vector2.ZERO   # screen position of grid (0, 0) = the back corner of the floor
var _walkers: Array = [] # {m, node, g (grid pos), target, wait, speed, you}
var _labels: Dictionary = {}   # station key -> Button (floating sign)
var _anim: Control       # portal + motes, redrawn every frame
var _t := 0.0
var _chat_t := 4.0
var _bubbles: Array = [] # {node, owner, t}
var _you: Dictionary = {}

const STATIONS := {
	"raid": {"label": "GUILD RAID", "icon": "icon_boss", "g": Vector2(9.2, 6.6), "col": "#ff5c6c"},
	"board": {"label": "CHECK-IN & DONATE", "icon": "icon_quest", "g": Vector2(0.2, 3.2), "col": "#ffd479"},
	"shop": {"label": "GUILD SHOP", "icon": "icon_shop", "g": Vector2(1.0, 7.4), "col": "#7ee08a"},
	"tech": {"label": "GUILD TECH", "icon": "icon_skills", "g": Vector2(10.2, 0.6), "col": "#9fd0ff"},
	"members": {"label": "MEMBERS", "icon": "icon_guild", "g": Vector2(5.6, 0.1), "col": "#d8b4ff"},
}

const CHAT := ["Raid boss is almost down!", "Thanks for the donation!", "Anyone up for the Tower?", "Good evening, guild!",
	"That boss hits so hard...", "GG everyone!", "Checked in for today.", "Who has a Crimson hero already?",
	"Need Evo Crystals... dismantling time.", "Our tech is getting strong!", "Welcome, Commander!", "Brb, dinner."]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_anim = Control.new()
	_anim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_anim.draw.connect(_draw_anim)
	add_child(_anim)
	for key in STATIONS.keys():
		_labels[key] = _make_sign(str(key))
	resized.connect(_layout)
	gui_input.connect(_on_input)

# ---------------------------------------------------------------- geometry

func g2s(g: Vector2) -> Vector2:
	return _o + Vector2((g.x - g.y) * _k * 0.5, (g.x + g.y) * _k * 0.25)

func s2g(p: Vector2) -> Vector2:
	var d := p - _o
	var a := d.x / (_k * 0.5)
	var b := d.y / (_k * 0.25)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)

func _up(h: float) -> Vector2:
	return Vector2(0, -h * _k * 0.5)

func _layout() -> void:
	if size.x <= 0.0:
		return
	var span := (N + M) * 0.5            # floor width in tiles
	var k_w := size.x * 0.96 / span
	var k_h := size.y * 0.94 / ((N + M) * 0.25 + WALL * 0.5)
	_k = minf(k_w, k_h)
	var floor_w := span * _k
	var total_h := (N + M) * 0.25 * _k + WALL * 0.5 * _k
	# grid (0,0) sits at x = left edge + M tiles, below the walls
	_o = Vector2((size.x - floor_w) * 0.5 + M * _k * 0.5, (size.y - total_h) * 0.5 + WALL * 0.5 * _k)
	for key in _labels.keys():
		var b: Button = _labels[key]
		var p := g2s(STATIONS[key]["g"]) + _up(_sign_height(str(key)))
		b.position = p - Vector2(b.size.x * 0.5, b.size.y)
	for w in _walkers:
		_place(w)
	queue_redraw()

func _sign_height(key: String) -> float:
	return {"raid": 1.6, "board": 3.0, "shop": 2.0, "tech": 3.6, "members": 3.4}.get(key, 2.0)

# ---------------------------------------------------------------- static room

func _draw() -> void:
	var c00 := g2s(Vector2(0, 0))
	var cN0 := g2s(Vector2(N, 0))
	var cNM := g2s(Vector2(N, M))
	var c0M := g2s(Vector2(0, M))
	var up := _up(WALL)
	# walls: left (along y) and right (along x)
	var lw := PackedVector2Array([c0M, c00, c00 + up, c0M + up])
	var rw := PackedVector2Array([c00, cN0, cN0 + up, c00 + up])
	draw_colored_polygon(lw, Color("#3a2a44"))
	draw_colored_polygon(rw, Color("#4a3656"))
	# wainscoting (lower 40%) + trim
	var wu := _up(WALL * 0.4)
	draw_colored_polygon(PackedVector2Array([c0M, c00, c00 + wu, c0M + wu]), Color("#2a1c24"))
	draw_colored_polygon(PackedVector2Array([c00, cN0, cN0 + wu, c00 + wu]), Color("#35232d"))
	for e in [[c0M, c00], [c00, cN0]]:
		draw_line(e[0] + wu, e[1] + wu, Color("#c9a55a"), maxf(1.5, _k * 0.05))
		draw_line(e[0] + up, e[1] + up, Color("#6e4f7e"), maxf(2.0, _k * 0.08))
	# wall panel lines
	for i in range(1, int(M)):
		var a := g2s(Vector2(0, i))
		draw_line(a, a + wu, Color(0, 0, 0, 0.25), 1.0)
	for i in range(1, int(N)):
		var a := g2s(Vector2(i, 0))
		draw_line(a, a + wu, Color(0, 0, 0, 0.25), 1.0)
	# windows on the right wall + their light on the floor
	for wx in [[1.6, 3.4], [6.8, 8.6]]:
		_window_x(float(wx[0]), float(wx[1]))
	# window on the left wall
	_window_y(6.0, 7.6)
	# floor planks
	draw_colored_polygon(PackedVector2Array([c00, cN0, cNM, c0M]), Color("#6b4a32"))
	for i in int(N):
		for j in int(M):
			if (i + j * 3) % 5 == 0:
				var p := PackedVector2Array([g2s(Vector2(i, j)), g2s(Vector2(i + 1, j)), g2s(Vector2(i + 1, j + 1)), g2s(Vector2(i, j + 1))])
				draw_colored_polygon(p, Color(1, 0.9, 0.7, 0.04))
	for j in range(0, int(M) + 1):
		draw_line(g2s(Vector2(0, j)), g2s(Vector2(N, j)), Color(0.15, 0.08, 0.04, 0.45), 1.0)
	for i in range(0, int(N) + 1, 3):
		for j in int(M):
			var off := 1.5 if j % 2 == 0 else 0.0
			var x := float(i) + off
			if x < N:
				draw_line(g2s(Vector2(x, j)), g2s(Vector2(x, j + 1)), Color(0.15, 0.08, 0.04, 0.35), 1.0)
	# light patches from the windows
	for wx in [[1.6, 3.4], [6.8, 8.6]]:
		var a := float(wx[0])
		var b := float(wx[1])
		draw_colored_polygon(PackedVector2Array([g2s(Vector2(a, 0)), g2s(Vector2(b, 0)), g2s(Vector2(b + 1.2, 3.4)), g2s(Vector2(a + 1.2, 3.4))]), Color(1.0, 0.92, 0.7, 0.10))
	# rug in the guild colour, emblem in the middle
	var rug := [Vector2(3.6, 3.0), Vector2(8.0, 3.0), Vector2(8.0, 7.2), Vector2(3.6, 7.2)]
	draw_colored_polygon(PackedVector2Array(rug.map(func(g): return g2s(g))), guild_color.darkened(0.55))
	var inner := [Vector2(4.0, 3.4), Vector2(7.6, 3.4), Vector2(7.6, 6.8), Vector2(4.0, 6.8)]
	draw_colored_polygon(PackedVector2Array(inner.map(func(g): return g2s(g))), guild_color.darkened(0.3))
	var ring_c := g2s(Vector2(5.8, 5.1))
	_iso_ellipse(ring_c, _k * 1.1, guild_color.lightened(0.2), 2.5)
	_iso_ellipse(ring_c, _k * 0.8, Color(guild_color, 0.5), 1.5)
	# furniture (back to front)
	_bookshelf(Vector2(9.4, 0.0), Vector2(2.4, 0.9), 3.0)
	_banner(5.6)
	_plant(Vector2(0.4, 0.4))
	_plant(Vector2(11.4, 2.2))
	_board(2.2, 4.2)
	_counter(Vector2(0.0, 6.2), Vector2(1.3, 2.6))
	_table(Vector2(2.6, 8.4))
	_plant(Vector2(0.5, 9.4))
	# portal base (the animated swirl is on _anim)
	_iso_ellipse(g2s(STATIONS["raid"]["g"]), _k * 1.25, Color("#ff5c6c", 0.9), 3.0)
	_iso_ellipse(g2s(STATIONS["raid"]["g"]), _k * 1.45, Color("#ff5c6c", 0.35), 2.0)
	# room outline
	draw_polyline(PackedVector2Array([c0M + up, c00 + up, cN0 + up]), Color("#1a1020"), maxf(2.0, _k * 0.06))

func _window_x(a: float, b: float) -> void:
	var lo := 0.95
	var hi := 2.15
	var p := PackedVector2Array([g2s(Vector2(a, 0)) + _up(lo), g2s(Vector2(b, 0)) + _up(lo), g2s(Vector2(b, 0)) + _up(hi), g2s(Vector2(a, 0)) + _up(hi)])
	draw_colored_polygon(p, Color("#8fd0ff"))
	draw_colored_polygon(PackedVector2Array([p[0], p[1], (p[1] + p[2]) * 0.5, (p[0] + p[3]) * 0.5]), Color("#c9ecff", 0.6))
	draw_polyline(PackedVector2Array([p[0], p[1], p[2], p[3], p[0]]), Color("#f0e0b0"), maxf(2.0, _k * 0.07))
	var m := (g2s(Vector2((a + b) * 0.5, 0)))
	draw_line(m + _up(lo), m + _up(hi), Color("#f0e0b0"), maxf(1.5, _k * 0.05))
	draw_line((p[0] + p[3]) * 0.5, (p[1] + p[2]) * 0.5, Color("#f0e0b0"), maxf(1.5, _k * 0.05))

func _window_y(a: float, b: float) -> void:
	var lo := 0.95
	var hi := 2.15
	var p := PackedVector2Array([g2s(Vector2(0, a)) + _up(lo), g2s(Vector2(0, b)) + _up(lo), g2s(Vector2(0, b)) + _up(hi), g2s(Vector2(0, a)) + _up(hi)])
	draw_colored_polygon(p, Color("#6fb4e8"))
	draw_polyline(PackedVector2Array([p[0], p[1], p[2], p[3], p[0]]), Color("#f0e0b0"), maxf(2.0, _k * 0.07))
	draw_line((p[0] + p[3]) * 0.5, (p[1] + p[2]) * 0.5, Color("#f0e0b0"), maxf(1.5, _k * 0.05))

## Iso block: footprint from grid `g` size `s`, height `h` (half-tile units), standing `base` above the floor.
func _box(g: Vector2, s: Vector2, h: float, col: Color, base: float = 0.0) -> void:
	var b := _up(base)
	var p0 := g2s(g) + b
	var p1 := g2s(g + Vector2(s.x, 0)) + b
	var p2 := g2s(g + s) + b
	var p3 := g2s(g + Vector2(0, s.y)) + b
	var u := _up(h)
	var ol := Color(0.08, 0.04, 0.06, 0.9)
	draw_colored_polygon(PackedVector2Array([p3, p2, p2 + u, p3 + u]), col.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([p1, p2, p2 + u, p1 + u]), col.darkened(0.38))
	draw_colored_polygon(PackedVector2Array([p0 + u, p1 + u, p2 + u, p3 + u]), col.lightened(0.12))
	draw_polyline(PackedVector2Array([p3, p2, p1, p1 + u, p0 + u, p3 + u, p3]), ol, 1.5)
	draw_line(p2, p2 + u, ol, 1.5)
	draw_line(p2 + u, p1 + u, ol, 1.0)
	draw_line(p2 + u, p3 + u, ol, 1.0)

func _bookshelf(g: Vector2, s: Vector2, h: float) -> void:
	_box(g, s, h, Color("#5a3a26"))
	# book spines on the front-left face, 4 shelves
	var cols := [Color("#c0392b"), Color("#2e86c1"), Color("#27ae60"), Color("#f1c40f"), Color("#8e44ad"), Color("#d35400")]
	for shelf in 4:
		var y0 := 0.35 + shelf * 0.68
		var n := 7
		for i in n:
			var t0 := (float(i) + 0.15) / n
			var t1 := (float(i) + 0.8) / n
			var a := g + Vector2(s.x * t0, s.y)
			var b := g + Vector2(s.x * t1, s.y)
			var hh := 0.42 + 0.12 * float((i * 7 + shelf * 3) % 3) / 2.0
			var q := PackedVector2Array([g2s(a) + _up(y0), g2s(b) + _up(y0), g2s(b) + _up(y0 + hh), g2s(a) + _up(y0 + hh)])
			draw_colored_polygon(q, cols[(i + shelf * 2) % cols.size()].darkened(0.15))
		draw_line(g2s(g + Vector2(0, s.y)) + _up(y0), g2s(g + s) + _up(y0), Color("#2a1810"), 2.0)

func _banner(x: float) -> void:
	var w := 1.4
	var top := 2.45
	var bot := 0.6
	var a := g2s(Vector2(x - w * 0.5, 0))
	var b := g2s(Vector2(x + w * 0.5, 0))
	var m := g2s(Vector2(x, 0))
	draw_colored_polygon(PackedVector2Array([a + _up(top), b + _up(top), b + _up(bot + 0.35), m + _up(bot), a + _up(bot + 0.35)]), guild_color.darkened(0.25))
	draw_polyline(PackedVector2Array([a + _up(top), b + _up(top), b + _up(bot + 0.35), m + _up(bot), a + _up(bot + 0.35), a + _up(top)]), Color("#f0e0b0"), 2.0)
	draw_line(a + _up(top + 0.08), b + _up(top + 0.08), Color("#c9a55a"), maxf(2.0, _k * 0.08))
	var f := get_theme_default_font()
	var fs := int(_k * 0.6)
	var c := m + _up((top + bot) * 0.55)
	draw_string(f, c - Vector2(fs * 0.34, -fs * 0.35), guild_initial, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color("#fff4d0"))

func _board(y0: float, y1: float) -> void:
	var lo := 0.75
	var hi := 2.05
	var p := PackedVector2Array([g2s(Vector2(0, y0)) + _up(lo), g2s(Vector2(0, y1)) + _up(lo), g2s(Vector2(0, y1)) + _up(hi), g2s(Vector2(0, y0)) + _up(hi)])
	draw_colored_polygon(p, Color("#7a5232"))
	draw_polyline(PackedVector2Array([p[0], p[1], p[2], p[3], p[0]]), Color("#3a2414"), 3.0)
	# pinned notes
	var notes := [[0.15, 0.3, Color("#fff4c0")], [0.45, 0.55, Color("#ffd0e0")], [0.7, 0.25, Color("#d0f0ff")], [0.3, 0.75, Color("#e0ffd0")]]
	for n in notes:
		var ty := lerpf(y0, y1, float(n[0]))
		var th := lerpf(lo, hi, float(n[1]))
		var q := PackedVector2Array([g2s(Vector2(0, ty)) + _up(th), g2s(Vector2(0, ty + 0.35)) + _up(th), g2s(Vector2(0, ty + 0.35)) + _up(th + 0.42), g2s(Vector2(0, ty)) + _up(th + 0.42)])
		draw_colored_polygon(q, n[2])
		draw_circle((q[2] + q[3]) * 0.5 + Vector2(0, 2), 2.0, Color("#d0392b"))

func _counter(g: Vector2, s: Vector2) -> void:
	_box(g, s, 1.15, Color("#6e4a30"))
	# cloth + goods on top
	var u := _up(1.15)
	draw_colored_polygon(PackedVector2Array([g2s(g + Vector2(0.15, 0.2)) + u, g2s(g + Vector2(s.x - 0.1, 0.2)) + u, g2s(g + Vector2(s.x - 0.1, s.y - 0.2)) + u, g2s(g + Vector2(0.15, s.y - 0.2)) + u]), Color("#2f8a5a"))
	_box(g + Vector2(0.3, 0.4), Vector2(0.45, 0.45), 0.45, Color("#c9a55a"), 1.15)
	_box(g + Vector2(0.4, 1.3), Vector2(0.35, 0.35), 0.3, Color("#8e44ad"), 1.15)
	draw_circle(g2s(g + Vector2(0.65, 2.1)) + _up(1.35), _k * 0.14, Color("#ff7a5c"))

func _table(g: Vector2) -> void:
	_box(g, Vector2(1.2, 0.9), 0.75, Color("#5a3a26"))
	var c := g2s(g + Vector2(0.6, 0.45)) + _up(0.75)
	draw_line(c, c + _up(0.4), Color("#f5f0dc"), 3.0)
	draw_circle(c + _up(0.48), 3.0, Color("#ffcf5a"))

func _plant(g: Vector2) -> void:
	_box(g - Vector2(0.3, 0.3), Vector2(0.6, 0.6), 0.6, Color("#8a5a3a"))
	var c := g2s(g) + _up(1.25)
	for i in 5:
		var a := TAU * i / 5.0
		draw_circle(c + Vector2(cos(a), sin(a) * 0.6) * _k * 0.22, _k * 0.24, Color("#2e7d4f").lightened(0.06 * i))
	draw_circle(c + _up(0.2), _k * 0.22, Color("#3f9e63"))

func _iso_ellipse(c: Vector2, r: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.5))
	draw_polyline(pts, col, w, true)

# ---------------------------------------------------------------- animated layer (portal swirl, motes)

func _process(delta: float) -> void:
	_t += delta
	_anim.queue_redraw()
	_walk(delta)
	_chat_t -= delta
	if _chat_t <= 0.0:
		_chat_t = randf_range(5.0, 10.0)
		_random_chat()
	for b in _bubbles.duplicate():
		b["t"] = float(b["t"]) - delta
		var n: Control = b["node"]
		var o: Control = b["owner"]
		if b["t"] <= 0.0 or not is_instance_valid(o):
			if is_instance_valid(n):
				n.queue_free()
			_bubbles.erase(b)
		elif is_instance_valid(n):
			n.position = o.position + Vector2(o.size.x * 0.5 - n.size.x * 0.5, -n.size.y + o.size.y * 0.12)

func _draw_anim() -> void:
	var c := g2s(STATIONS["raid"]["g"])
	for i in 3:
		var a0 := _t * (1.2 + i * 0.5) + i * 2.1
		var pts := PackedVector2Array()
		for s in 18:
			var a := a0 + s * 0.22
			var r := _k * (0.35 + s * 0.045)
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.5))
		_anim.draw_polyline(pts, Color(1.0, 0.35 + 0.15 * i, 0.45, 0.75 - i * 0.18), 2.0, true)
	_anim.draw_circle(c, _k * (0.28 + 0.04 * sin(_t * 3.0)), Color(1.0, 0.4, 0.5, 0.35))
	# rising sparks above the portal
	for i in 6:
		var ph := fmod(_t * 0.6 + i * 0.17, 1.0)
		var p := c + Vector2(sin(i * 2.3 + _t) * _k * 0.6, -ph * _k * 1.6)
		_anim.draw_circle(p, 2.0, Color(1.0, 0.55, 0.6, 1.0 - ph))
	# dust in the window light
	for i in 10:
		var ph := fmod(_t * 0.05 + i * 0.1, 1.0)
		var g := Vector2(2.0 + (i % 5) * 1.4, 0.4 + ph * 3.0)
		_anim.draw_circle(g2s(g) + _up(1.2 - ph), 1.5, Color(1, 0.95, 0.8, 0.5 * sin(ph * PI)))

# ---------------------------------------------------------------- station signs

func _make_sign(key: String) -> Button:
	var st: Dictionary = STATIONS[key]
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var p := UI.styled_panel(Color(0.08, 0.04, 0.12, 0.88), Color(str(st["col"])), 14, 2, 6)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(UI.tex_rect(DB.icon(str(st["icon"])), Vector2(24, 24)))
	h.add_child(UI.label(str(st["label"]), 13, Color(str(st["col"])).lightened(0.3), 3))
	p.add_child(h)
	b.add_child(p)
	p.resized.connect(func():
		b.custom_minimum_size = p.size
		b.size = p.size
		_layout())
	b.pressed.connect(func():
		Game.sfx("ui_click")
		station.emit(key))
	add_child(b)
	# gentle bob so the signs read as interactive
	var tw := p.create_tween().set_loops()
	tw.tween_property(p, "position:y", -4.0, 1.1 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(p, "position:y", 0.0, 1.1 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
	return b

func badge(key: String, on: bool) -> void:
	if not _labels.has(key):
		return
	var b: Button = _labels[key]
	var old := b.get_node_or_null("dot")
	if old:
		old.queue_free()
	if on:
		var d := UI.label("!", 14, Color.WHITE, 4)
		d.name = "dot"
		var bg := UI.styled_panel(Color("#ff4d5e"), Color.WHITE, 10, 1, 2)
		bg.name = "dot"
		bg.add_child(d)
		bg.position = Vector2(-6, -8)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bg)

# ---------------------------------------------------------------- members

func _walkable(g: Vector2) -> bool:
	if g.x < 1.4 or g.y < 1.9 or g.x > N - 0.6 or g.y > M - 0.5:
		return false
	if g.x < 2.2 and g.y > 5.6:            # shop counter
		return false
	if g.x > 8.8 and g.y < 2.4:            # bookshelf
		return false
	if g.distance_to(STATIONS["raid"]["g"]) < 1.2:   # portal
		return false
	if g.x > 2.2 and g.x < 4.2 and g.y > 8.0:        # table
		return false
	return true

## A free floor cell, kept away from where the other members stand or walk to (no crowd in the middle).
func _rand_cell() -> Vector2:
	var best := Vector2(6, 5)
	var best_d := -1.0
	for i in 40:
		var g := Vector2(randf_range(1.4, N - 0.6), randf_range(1.9, M - 0.5))
		if not _walkable(g):
			continue
		var d := 99.0
		for w in _walkers:
			d = minf(d, minf(g.distance_to(w["g"]), g.distance_to(w["target"])))
		if d >= 2.2:
			return g
		if d > best_d:
			best_d = d
			best = g
	return best

## Members currently in the base (each with their main hero) + the player.
func set_members(online: Array, you_hero: String, you_name: String) -> void:
	for w in _walkers:
		if is_instance_valid(w["node"]):
			w["node"].queue_free()
	_walkers.clear()
	_you = {}
	for m in online:
		_add_walker(m, false)
	_you = _add_walker({"name": you_name, "hero": you_hero, "you": true}, true)
	_layout()

func _add_walker(m: Dictionary, you: bool) -> Dictionary:
	var hid := str(m["hero"])
	var sz := Vector2(_k * 1.7, _k * 1.7)
	var st := int(Game.hero(hid).get("star", 1)) if you and Game.owns(hid) else 1
	var uv := UnitView.new(hid, false, DB.sprite(hid, st, int(Game.hero(hid).get("skin", 0)) if you and Game.owns(hid) else -1), sz, -1, false)
	uv.mouse_filter = Control.MOUSE_FILTER_STOP
	uv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(uv)
	uv.start_idle()
	var nm := UI.label(("★ " if you else "") + str(m["name"]).replace(" (You)", ""), 12, UI.GOLD if you else Color.WHITE, 4)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(-20, sz.y * 0.96)
	nm.size = Vector2(sz.x + 40, 16)
	uv.add_child(nm)
	var w := {"m": m, "node": uv, "g": _rand_cell(), "target": _rand_cell(), "wait": randf_range(0.5, 3.0), "speed": randf_range(0.9, 1.5), "you": you, "name": nm}
	uv.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Game.sfx("ui_click")
			_hop(uv)
			member.emit(m)
			accept_event())
	_walkers.append(w)
	_place(w)
	return w

func _place(w: Dictionary) -> void:
	var n: UnitView = w["node"]
	if not is_instance_valid(n):
		return
	var sz := Vector2(_k * 1.7, _k * 1.7)
	if n.size != sz:
		n.custom_minimum_size = sz
		n.size = sz
		n.pivot_offset = Vector2(sz.x * 0.5, sz.y)
		(w["name"] as Label).position = Vector2(-20, sz.y * 0.96)
		(w["name"] as Label).size = Vector2(sz.x + 40, 16)
	n.position = g2s(w["g"]) - Vector2(sz.x * 0.5, sz.y * 0.9)

func _walk(delta: float) -> void:
	for w in _walkers:
		var n: UnitView = w["node"]
		if not is_instance_valid(n):
			continue
		if float(w["wait"]) > 0.0:
			w["wait"] = float(w["wait"]) - delta
			n.sprite.position.y = 0.0
			continue
		var to: Vector2 = w["target"] - w["g"]
		if to.length() < 0.08:
			w["wait"] = randf_range(2.0, 6.0) if not w["you"] else 999999.0
			if not w["you"]:
				w["target"] = _rand_cell()
			continue
		var step: Vector2 = to.normalized() * float(w["speed"]) * delta
		if step.length() > to.length():
			step = to
		w["g"] = w["g"] + step
		# screen direction of the step decides the facing
		n.sprite.flip_h = (step.x - step.y) < 0.0
		n.sprite.position.y = -absf(sin(Time.get_ticks_msec() / 130.0 + float(w["g"].x) * 2.0)) * _k * 0.12
		_place(w)
	# depth: further down the screen = in front
	var nodes: Array = []
	for w in _walkers:
		if is_instance_valid(w["node"]):
			nodes.append(w)
	nodes.sort_custom(func(a, b): return (a["g"].x + a["g"].y) < (b["g"].x + b["g"].y))
	# draw order by child order, not z_index (a positive z_index would also draw over the popups)
	var top := get_child_count() - 1
	for i in nodes.size():
		move_child(nodes[i]["node"], top)
	for key in _labels.keys():
		move_child(_labels[key], top)
	for b in _bubbles:
		if is_instance_valid(b["node"]):
			move_child(b["node"], top)

func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not _you.is_empty():
		var g := s2g((e as InputEventMouseButton).position)
		if _walkable(g):
			_you["target"] = g
			_you["wait"] = 0.0
			_ping(g)
		accept_event()

## A small ring where the player tapped.
func _ping(g: Vector2) -> void:
	var r := Control.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = g2s(g)
	add_child(r)
	move_child(r, 1)
	var rad := [0.2]
	r.draw.connect(func():
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a), sin(a) * 0.5) * _k * float(rad[0]))
		r.draw_polyline(pts, Color(1, 0.85, 0.4, r.modulate.a), 2.0, true))
	var tw := r.create_tween()
	tw.tween_method(func(v: float):
		rad[0] = v
		r.queue_redraw(), 0.2, 0.8, 0.4)
	tw.parallel().tween_property(r, "modulate:a", 0.0, 0.4)
	tw.tween_callback(r.queue_free)

func _hop(n: Control) -> void:
	var s: Control = (n as UnitView).sprite
	var tw := s.create_tween()
	tw.tween_property(s, "position:y", -_k * 0.5, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func say(w_node: Control, text: String) -> void:
	var p := UI.styled_panel(Color(1, 1, 1, 0.95), guild_color, 12, 2, 6)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 12, Color("#2a1a3a"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(150, 0)
	p.add_child(l)
	add_child(p)
	_bubbles.append({"node": p, "owner": w_node, "t": 3.2})

func _random_chat() -> void:
	var others := _walkers.filter(func(w): return not w["you"] and is_instance_valid(w["node"]))
	if others.is_empty():
		return
	var w: Dictionary = others[randi() % others.size()]
	say(w["node"], str(CHAT[randi() % CHAT.size()]))

func walker_count() -> int:
	return _walkers.size()
