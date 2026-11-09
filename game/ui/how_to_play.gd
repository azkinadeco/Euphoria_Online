class_name HowToPlay
extends Control
## Illustrated "How to Play" guide: 7 pages with drawn diagrams (battlefield, ranges, roles,
## elements, growth, daily routine). Shown once after the intro and any time from Settings.

signal finished

const PAGES := [
	{"title": "WELCOME, COMMANDER", "hero": "shina",
		"text": "Euphoria is falling to the Eclipse. Gather heroes, place them on the battlefield and clear the Story to push the darkness back.\n\nBattles play out automatically — your job is the plan: WHO you bring and WHERE they stand.",
		"draw": "welcome"},
	{"title": "THE BATTLEFIELD", "hero": "fidelia",
		"text": "Each side has a 3x3 grid. The column closest to the enemy is the FRONT line — it gets hit first. Put tough heroes there and fragile ones in the BACK.\n\nThe gold numbers are the action order: heroes act 1 → 5, alternating with the enemy.",
		"draw": "grid"},
	{"title": "SKILLS & RANGES", "hero": "rumi",
		"text": "Every hero's attack hits a SHAPE: one target, a line, a cross, a 2x2 square, a whole row or column, or every enemy.\n\nTap a hero in Formation to see her range on the enemy grid before the fight.",
		"draw": "shapes"},
	{"title": "ROLES", "hero": "lucidria",
		"text": "TANK — front line, absorbs damage.\nDPS / ASSASSIN — deal the damage, crits on key targets.\nMAGE — area damage that ignores armour.\nSUPPORT — heals and buffs, stay in the back.\n\nIn battle, tap any unit to check its role and skill.",
		"draw": "roles"},
	{"title": "ELEMENTS", "hero": "furu",
		"text": "Fire beats Wind, Wind beats Earth, Earth beats Water, Water beats Fire. Light and Dark beat each other.\n\nAdvantage = +30% damage, disadvantage = -15%. Two or more heroes of one element give a team Synergy bonus.",
		"draw": "elements"},
	{"title": "GROW YOUR TEAM", "hero": "shina",
		"text": "LEVEL UP with Hero EXP · STAR UP with shards · equip GEAR sets · raise BOND with gifts, talks and dates.\n\nIf a stage is too hard, the defeat screen tells you why and what to upgrade.",
		"draw": "growth"},
	{"title": "YOUR DAILY ROUTINE", "hero": "fidelia",
		"text": "Claim the Login Bonus and AFK rewards, finish Daily Missions, run Dungeons for gold and EXP, fight in the Arena, and check your Mailbox.\n\nThe STEP guide in the lobby always shows the next thing to do. Good luck!",
		"draw": "daily"},
]

var _i := 0
var _card: Control
var _art: TextureRect
var _title: Label
var _text: Label
var _diag: Control
var _dots: HBoxContainer
var _prev: Button
var _next: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("popup", true)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var vs := get_viewport().get_visible_rect().size
	_card = UI.styled_panel(Color(0.05, 0.03, 0.1, 0.98), UI.GOLD, 16, 2, 0)
	_card.custom_minimum_size = Vector2(minf(1060.0, vs.x - 30.0), minf(600.0, vs.y - 30.0))
	_card.clip_contents = true
	center.add_child(_card)
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(stack)
	_art = UI.tex_rect(null)
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.anchor_right = 0.3
	_art.offset_top = 40
	_art.modulate = Color(1, 1, 1, 0.95)
	stack.add_child(_art)
	var fade := Control.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.draw.connect(func():
		var x0 := fade.size.x * 0.18
		var x1 := fade.size.x * 0.32
		var dk := Color(0.05, 0.03, 0.1, 0.98)
		var cl := Color(0.05, 0.03, 0.1, 0.0)
		fade.draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, fade.size.y), Vector2(x0, fade.size.y)]), PackedColorArray([cl, dk, dk, cl])))
	stack.add_child(fade)
	var v := UI.vbox(10)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.anchor_left = 0.29
	v.offset_right = -26
	v.offset_top = 22
	v.offset_bottom = -18
	stack.add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	var tag := UI.label("HOW TO PLAY", 13, Color("#c9a2ff"), 2)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tag)
	head.add_child(UI.button("SKIP", _close, "", Vector2(90, 36)))
	_title = UI.label("", 30, UI.GOLD, 0)
	_title.add_theme_color_override("font_outline_color", Color("#2a1608"))
	_title.add_theme_constant_override("outline_size", 8)
	v.add_child(_title)
	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	_text = UI.wrap_label("", 16, UI.TEXT)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_stretch_ratio = 1.1
	_text.add_theme_constant_override("line_spacing", 4)
	body.add_child(_text)
	_diag = Control.new()
	_diag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_diag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_diag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_diag.draw.connect(_draw_diag)
	body.add_child(_diag)
	var foot := UI.hbox(10)
	v.add_child(foot)
	_prev = UI.button("◀ BACK", func(): _go(_i - 1), "", Vector2(130, 48))
	foot.add_child(_prev)
	_dots = UI.hbox(8)
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_child(_dots)
	_next = UI.button("NEXT ▶", func(): _go(_i + 1), "GoldButton", Vector2(170, 48))
	foot.add_child(_next)
	var t := Timer.new()
	t.wait_time = 1.0 / 20.0
	t.autostart = true
	t.timeout.connect(_diag.queue_redraw)
	add_child(t)
	_go(0)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _go(i: int) -> void:
	if i >= PAGES.size():
		_close()
		return
	_i = clampi(i, 0, PAGES.size() - 1)
	var pg: Dictionary = PAGES[_i]
	_title.text = pg["title"]
	_text.text = pg["text"]
	_art.texture = DB.art(pg["hero"], 0)
	_prev.disabled = _i == 0
	_next.text = "LET'S GO! ▶" if _i == PAGES.size() - 1 else "NEXT ▶"
	for c in _dots.get_children():
		c.queue_free()
	for k in PAGES.size():
		var d := Panel.new()
		d.custom_minimum_size = Vector2(22 if k == _i else 10, 10)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.add_theme_stylebox_override("panel", UI.style(UI.GOLD if k == _i else Color(1, 1, 1, 0.3), Color.TRANSPARENT, 5, 0, 0))
		_dots.add_child(d)
	_text.modulate.a = 0.0
	_text.create_tween().tween_property(_text, "modulate:a", 1.0, 0.25)
	Game.sfx("ui_click")
	_diag.queue_redraw()

func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		finished.emit()
		queue_free())

# ---------------------------------------------------------------- diagrams

func _t() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _grid(o: Vector2, cell: float, cols_col: Array, label_front_right: bool) -> void:
	for c in 3:
		for r in 3:
			var p := o + Vector2(c * cell, r * cell)
			var col: Color = cols_col[c]
			_diag.draw_rect(Rect2(p + Vector2(2, 2), Vector2(cell - 4, cell - 4)), Color(col, 0.18))
			_diag.draw_rect(Rect2(p + Vector2(2, 2), Vector2(cell - 4, cell - 4)), Color(col, 0.7), false, 1.5)

func _draw_diag() -> void:
	var sz := _diag.size
	if sz.x < 50:
		return
	var f := ThemeDB.fallback_font
	var kind: String = PAGES[_i]["draw"]
	var t := _t()
	match kind:
		"welcome":
			var c := sz * 0.5
			for k in 3:
				_diag.draw_arc(c, 70.0 + k * 26.0, t * (0.5 + k * 0.2), t * (0.5 + k * 0.2) + PI * 1.3, 48, Color(UI.GOLD, 0.5 - k * 0.12), 3.0, true)
			_diag.draw_string(f, c + Vector2(-60, 10), "AUTO", HORIZONTAL_ALIGNMENT_CENTER, 120, 26, Color.WHITE)
			_diag.draw_string(f, c + Vector2(-60, 36), "BATTLE", HORIZONTAL_ALIGNMENT_CENTER, 120, 16, UI.GOLD)
		"grid":
			var cell := minf(sz.x / 7.5, sz.y / 4.2)
			var o1 := Vector2(sz.x * 0.5 - cell * 3.3, sz.y * 0.5 - cell * 1.5)
			var o2 := Vector2(sz.x * 0.5 + cell * 0.3, o1.y)
			var blue := Color("#7fd0ff")
			var red := Color("#ff6b7d")
			_grid(o1, cell, [Color(0.6, 0.6, 0.8), Color(0.7, 0.7, 0.9), blue], false)
			_grid(o2, cell, [red, Color(0.9, 0.6, 0.7), Color(0.8, 0.6, 0.7)], true)
			_diag.draw_string(f, o1 + Vector2(cell * 2, -8), "FRONT", HORIZONTAL_ALIGNMENT_CENTER, cell, 12, blue)
			_diag.draw_string(f, o1 + Vector2(0, -8), "BACK", HORIZONTAL_ALIGNMENT_CENTER, cell, 12, Color(0.7, 0.7, 0.9))
			_diag.draw_string(f, o2 + Vector2(0, -8), "FRONT", HORIZONTAL_ALIGNMENT_CENTER, cell, 12, red)
			var order := [[2, 1, "1"], [2, 0, "2"], [1, 1, "3"], [0, 0, "4"], [0, 2, "5"]]
			for e in order:
				var p := o1 + Vector2(int(e[0]) * cell + cell * 0.5, int(e[1]) * cell + cell * 0.5)
				_diag.draw_circle(p, cell * 0.22, UI.GOLD)
				_diag.draw_string(f, p + Vector2(-10, 6), str(e[2]), HORIZONTAL_ALIGNMENT_CENTER, 20, 16, Color("#2a1608"))
			for k in 3:
				var ep := o2 + Vector2(cell * (0.5 + k), cell * (0.5 + k % 2))
				_diag.draw_circle(ep, cell * 0.18, Color(red, 0.85))
			var q := fmod(t * 0.8, 1.0)
			var a := o1 + Vector2(cell * 2.5, cell * 1.5)
			var b := o2 + Vector2(cell * 0.5, cell * 1.5)
			_diag.draw_line(a, a.lerp(b, q), Color(UI.GOLD, 0.8), 3.0, true)
			_diag.draw_string(f, Vector2(0, sz.y - 6), "Your team                         Enemy", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 13, UI.MUTED)
		"shapes":
			var shapes := [["SINGLE", [Vector2i(0, 1)]], ["LINE", [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]],
				["CROSS", [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]], ["2x2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]],
				["COLUMN", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]], ["ALL", []]]
			var cell2 := minf(sz.x / 12.0, sz.y / 8.0)
			for k in shapes.size():
				var o := Vector2((k % 3) * (cell2 * 3.8) + cell2 * 0.6, (k / 3) * (cell2 * 4.2) + cell2 * 0.8)
				var hit: Array = shapes[k][1]
				var pulse := 0.6 + 0.4 * sin(t * 4.0 + k)
				for c in 3:
					for r in 3:
						var on: bool = hit.is_empty() or hit.has(Vector2i(c, r))
						var rr := Rect2(o + Vector2(c * cell2, r * cell2) + Vector2(1, 1), Vector2(cell2 - 2, cell2 - 2))
						_diag.draw_rect(rr, Color(1, 0.35, 0.4, 0.75 * pulse) if on else Color(1, 1, 1, 0.08))
				_diag.draw_string(f, o + Vector2(0, cell2 * 3 + 16), str(shapes[k][0]), HORIZONTAL_ALIGNMENT_CENTER, cell2 * 3, 12, UI.GOLD)
		"roles":
			var rows := [["TANK", "#7fb8ff", "FRONT"], ["DPS / ASSASSIN", "#ff5c8a", "FRONT / MID"], ["MAGE", "#c58cff", "MID / BACK"], ["SUPPORT", "#6be0a0", "BACK"]]
			var y := sz.y * 0.12
			for e in rows:
				var c := Color(str(e[1]))
				var w := sz.x * 0.86
				var rr := Rect2(Vector2(sz.x * 0.07, y), Vector2(w, sz.y * 0.17))
				_diag.draw_rect(rr, Color(c, 0.14))
				_diag.draw_rect(Rect2(rr.position, Vector2(6, rr.size.y)), c)
				_diag.draw_string(f, rr.position + Vector2(18, rr.size.y * 0.62), str(e[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, c.lightened(0.2))
				_diag.draw_string(f, rr.position + Vector2(0, rr.size.y * 0.62), str(e[2]), HORIZONTAL_ALIGNMENT_RIGHT, rr.size.x - 14, 13, UI.MUTED)
				y += sz.y * 0.21
		"elements":
			var c := sz * 0.5 + Vector2(0, -10)
			var rad := minf(sz.x, sz.y) * 0.3
			var ring := ["FIRE", "WIND", "EARTH", "WATER"]
			for k in 4:
				var a0 := -PI / 2 + k * TAU / 4.0
				var a1 := -PI / 2 + (k + 1) * TAU / 4.0
				var p0 := c + Vector2(cos(a0), sin(a0)) * rad
				var p1 := c + Vector2(cos(a1), sin(a1)) * rad
				var col: Color = DB.ELEMENT_COLOR[ring[k]]
				var q := fmod(t * 0.7 + k * 0.25, 1.0)
				_diag.draw_line(p0.lerp(p1, 0.2), p0.lerp(p1, 0.8), Color(col, 0.6), 3.0, true)
				_diag.draw_circle(p0.lerp(p1, 0.2 + 0.6 * q), 4.0, Color.WHITE)
				var tip := p0.lerp(p1, 0.8)
				var dir := (p1 - p0).normalized()
				_diag.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 12 + dir.orthogonal() * 7, tip - dir * 12 - dir.orthogonal() * 7]), col)
				_diag.draw_circle(p0, 26.0, Color(col, 0.25))
				_diag.draw_texture_rect(DB.icon(DB.ELEMENT_ICON[ring[k]]), Rect2(p0 - Vector2(20, 20), Vector2(40, 40)), false)
			var ly := sz.y - 30
			_diag.draw_texture_rect(DB.icon("elem_light"), Rect2(Vector2(sz.x * 0.5 - 70, ly - 16), Vector2(32, 32)), false)
			_diag.draw_string(f, Vector2(sz.x * 0.5 - 34, ly + 6), "⇄", HORIZONTAL_ALIGNMENT_CENTER, 68, 22, Color.WHITE)
			_diag.draw_texture_rect(DB.icon("elem_dark"), Rect2(Vector2(sz.x * 0.5 + 38, ly - 16), Vector2(32, 32)), false)
		"growth":
			var steps := [["LEVEL", "icon_crystal", "#8fd8ff"], ["STAR", "icon_shards", "#ffd479"], ["GEAR", "icon_equipment", "#ff9a5c"], ["BOND", "icon_heart", "#ff8fb8"]]
			var bw := sz.x / 4.0
			for k in 4:
				var e: Array = steps[k]
				var col := Color(str(e[2]))
				var cx := bw * (k + 0.5)
				var cy := sz.y * 0.42 - sin(t * 2.0 + k) * 4.0
				_diag.draw_circle(Vector2(cx, cy), bw * 0.36, Color(col, 0.18))
				_diag.draw_arc(Vector2(cx, cy), bw * 0.36, 0, TAU, 40, col, 2.0, true)
				_diag.draw_texture_rect(DB.icon(str(e[1])), Rect2(Vector2(cx, cy) - Vector2(22, 22), Vector2(44, 44)), false)
				_diag.draw_string(f, Vector2(cx - bw * 0.5, cy + bw * 0.36 + 22), str(e[0]), HORIZONTAL_ALIGNMENT_CENTER, bw, 15, col)
			_diag.draw_string(f, Vector2(0, sz.y * 0.88), "= more POWER", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, UI.GOLD)
		"daily":
			var items := [["Login Bonus", "icon_ticket"], ["Daily Missions", "icon_quest"], ["AFK Rewards", "icon_afk"], ["Dungeons", "icon_dungeon"], ["Arena", "icon_arena"], ["Mailbox", "icon_mail"]]
			var y2 := sz.y * 0.06
			for k in items.size():
				var e: Array = items[k]
				var rr := Rect2(Vector2(sz.x * 0.08, y2), Vector2(sz.x * 0.84, sz.y * 0.13))
				_diag.draw_rect(rr, Color(1, 1, 1, 0.05))
				_diag.draw_texture_rect(DB.icon(str(e[1])), Rect2(rr.position + Vector2(8, 4), Vector2(rr.size.y - 8, rr.size.y - 8)), false)
				_diag.draw_string(f, rr.position + Vector2(rr.size.y + 12, rr.size.y * 0.66), str(e[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
				var on := fmod(t * 0.8, float(items.size())) > k
				_diag.draw_string(f, rr.position + Vector2(0, rr.size.y * 0.66), "✔" if on else "○", HORIZONTAL_ALIGNMENT_RIGHT, rr.size.x - 12, 18, UI.GREEN if on else UI.MUTED)
				y2 += sz.y * 0.155
