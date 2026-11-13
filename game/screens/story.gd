extends Screen
## Campaign map: chapters, stage nodes, stage briefing, sweep & story dialogue.

const NODE_POS := [Vector2(0.09, 0.72), Vector2(0.25, 0.38), Vector2(0.42, 0.66), Vector2(0.58, 0.32), Vector2(0.74, 0.62), Vector2(0.9, 0.35)]

var _chapter := 0
var _sel := 0
var _map: PanelContainer
var _map_layer: Control
var _detail: VBoxContainer
var _actions: VBoxContainer
var _tabs: HBoxContainer
var _hard := false
var _mode_btns: Array = []

func _st(i: int) -> Dictionary:
	return DB.hard_stage(i) if _hard else DB.stage(i)

func _stars(i: int) -> int:
	return Game.hard_stars(i) if _hard else Game.stage_stars(i)

func _prog() -> int:
	return Game.hard_progress() if _hard else Game.story_progress()

func build() -> void:
	_hard = str(params.get("hard", false)).to_lower() == "true"
	_sel = int(params.get("select", _prog()))
	_sel = clampi(_sel, 0, _prog())
	_chapter = _sel / DB.STAGES_PER_CHAPTER
	set_bg("world", 0.5)
	ambient(Color(0.7, 0.9, 1.0), 25)
	var hb := header("STORY", ["gold", "gems", "energy"])
	for m in [["NORMAL", false], ["HARD", true]]:
		var hm: bool = m[1]
		var mb := UI.button(m[0], func(): _set_mode(hm), "TabButton", Vector2(110, 42))
		mb.toggle_mode = true
		mb.set_meta("hard", hm)
		if hm:
			mb.add_theme_color_override("font_color", Color("#ff8a9a"))
			mb.visible = Game.hard_chapter_open(0)   # stays out of a new player's way
		hb.add_child(mb)
		hb.move_child(mb, 2 + int(hm))
		_mode_btns.append(mb)
	_tabs = UI.hbox(6)
	var tsc := UI.scroll(_tabs, true)
	tsc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tsc.offset_left = 16
	tsc.offset_right = -16
	tsc.offset_top = 70
	tsc.offset_bottom = 114
	tsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tsc)

	_map = UI.styled_panel(Color(0.03, 0.02, 0.06, 1.0), UI.GOLD_DARK, 16, 2, 0)
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map.anchor_right = 0.64
	_map.offset_left = 16
	_map.offset_top = 122
	_map.offset_bottom = -16
	_map.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(_map)

	var rp := UI.panel()
	rp.set_anchors_preset(Control.PRESET_FULL_RECT)
	rp.anchor_left = 0.65
	rp.offset_right = -16
	rp.offset_top = 122
	rp.offset_bottom = -16
	add_child(rp)
	var col := UI.vbox(8)
	rp.add_child(col)
	_detail = UI.vbox(8)
	col.add_child(UI.scroll(_detail))
	_actions = UI.vbox(8)   # outside the scroll: BATTLE must always be on screen
	col.add_child(_actions)
	_render()
	tutorial("story")
	_chapter_card()

## First visit to a newly opened chapter: a cinematic title band sweeps across the map.
## Purely visual (ignores the mouse) and shown once per chapter.
func _chapter_card() -> void:
	if _hard or _chapter == 0 or _sel % DB.STAGES_PER_CHAPTER != 0 or _sel != _prog():
		return
	var seen: Array = Game.s["story"].get("seen", [])
	var key := "card%d" % _chapter
	if seen.has(key):
		return
	seen.append(key)
	Game.s["story"]["seen"] = seen
	Game.mark_dirty()
	var chd: Dictionary = DB.CHAPTERS[_chapter]
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var band := ColorRect.new()
	band.color = Color(0.02, 0.01, 0.05, 0.78)
	band.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	band.offset_top = -78
	band.offset_bottom = 78
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.pivot_offset = Vector2(get_viewport_rect().size.x * 0.5, 78)
	band.scale = Vector2(1, 0.0)
	layer.add_child(band)
	var lines: Array = []
	for y in [-78.0, 76.0]:
		var ln := ColorRect.new()
		ln.color = UI.GOLD
		ln.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
		ln.offset_top = y
		ln.offset_bottom = y + 2
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ln.pivot_offset = Vector2(get_viewport_rect().size.x * 0.5, 1)
		ln.scale = Vector2(0, 1)
		layer.add_child(ln)
		lines.append(ln)
	var v := UI.vbox(2)
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(v)
	var top := UI.label("✦  CHAPTER %d  ✦" % (_chapter + 1), 18, UI.GOLD, 3)
	var name_l := UI.label(str(chd["name"]).to_upper(), 46, Color.WHITE, 8)
	var sub := UI.label(_arc_name(_chapter), 14, Color("#c9b8ff"), 3)
	for l in [top, name_l, sub]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		v.add_child(l)
	name_l.add_theme_color_override("font_outline_color", DB.ELEMENT_COLOR.get(str(chd.get("element", "")), Color("#3a1d6e")).darkened(0.4))
	Game.sfx("star_up")
	var tw := layer.create_tween()
	tw.tween_property(band, "scale:y", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for ln in lines:
		tw.parallel().tween_property(ln, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(top, "modulate:a", 1.0, 0.2)
	tw.tween_property(name_l, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(name_l, "position:x", 0.0, 0.5).from(-60.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sub, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.6)
	tw.tween_property(layer, "modulate:a", 0.0, 0.45)
	tw.tween_callback(layer.queue_free)

func refresh() -> void:
	super.refresh()

func _set_mode(h: bool) -> void:
	if h and not Game.hard_chapter_open(0):
		main.toast("HARD mode opens after you clear the Chapter 1 boss on Normal.", UI.MUTED)
		_render()
		return
	_hard = h
	params["hard"] = h
	_sel = _prog()
	_chapter = _sel / DB.STAGES_PER_CHAPTER
	_render()

func _chapter_unlocked(ch: int) -> bool:
	if _hard:
		return Game.hard_chapter_open(ch) and ch * DB.STAGES_PER_CHAPTER <= _prog()
	return ch * DB.STAGES_PER_CHAPTER <= _prog()

func _render() -> void:
	for mb in _mode_btns:
		mb.button_pressed = bool(mb.get_meta("hard")) == _hard
	for c in _tabs.get_children():
		c.queue_free()
	# Arc selector + chapters of the current arc (keeps the tab row short with 14+ chapters)
	var arcs := [[0, 5], [6, 9], [10, 13], [14, 17], [18, 21], [22, 25], [26, 29], [30, 33], [34, 37], [38, 39], [40, DB.CHAPTERS.size() - 1]]
	var cur_arc := 0
	for ai in arcs.size():
		if _chapter >= arcs[ai][0] and _chapter <= arcs[ai][1]:
			cur_arc = ai
	for ai in arcs.size():
		var first: int = arcs[ai][0]
		var ab := UI.button("ARC %d" % (ai + 1), func():
			_chapter = first
			_sel = clampi(_prog(), first * DB.STAGES_PER_CHAPTER, first * DB.STAGES_PER_CHAPTER + DB.STAGES_PER_CHAPTER - 1)
			_render(), "TabButton", Vector2(58, 40))
		ab.toggle_mode = true
		ab.button_pressed = ai == cur_arc
		ab.disabled = not _chapter_unlocked(first)
		ab.visible = ai == 0 or _chapter_unlocked(arcs[ai - 1][0])   # reached arcs plus the next one
		ab.add_theme_color_override("font_color", Color("#d4b8ff"))
		_tabs.add_child(ab)
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.25)
	sep.custom_minimum_size = Vector2(2, 40)
	_tabs.add_child(sep)
	for ch in range(arcs[cur_arc][0], arcs[cur_arc][1] + 1):
		var cidx: int = ch
		var b := UI.button("CH.%d  %s" % [ch + 1, DB.CHAPTERS[ch]["name"]] if ch == _chapter else "CH.%d" % (ch + 1), func():
			_chapter = cidx
			_sel = mini(_prog(), cidx * DB.STAGES_PER_CHAPTER + DB.STAGES_PER_CHAPTER - 1)
			if _sel < cidx * DB.STAGES_PER_CHAPTER:
				_sel = cidx * DB.STAGES_PER_CHAPTER
			_render(), "TabButton", Vector2(0, 40))
		b.toggle_mode = true
		b.button_pressed = ch == _chapter
		b.disabled = not _chapter_unlocked(ch)
		if ch == _chapter:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tabs.add_child(b)
	_render_map()
	_render_detail()

func _render_map() -> void:
	for c in _map.get_children():
		c.queue_free()
	var chd: Dictionary = DB.CHAPTERS[_chapter]
	var bg := UI.tex_rect(DB.bg(chd["bg"]), Vector2.ZERO, true)
	_map.add_child(bg)
	if _hard:
		bg.modulate = Color(1.0, 0.55, 0.55)
	_map_layer = Control.new()
	_map_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_map.add_child(_map_layer)
	var title := UI.label("CHAPTER %d  •  %s" % [_chapter + 1, chd["name"].to_upper()], 22, UI.GOLD, 6)
	title.position = Vector2(18, 12)
	_map_layer.add_child(title)
	var arc := UI.label(_arc_name(_chapter), 13, Color("#d4b8ff"), 4)
	arc.position = Vector2(20, 44)
	_map_layer.add_child(arc)
	var rb := UI.button("▶ STORY ARCHIVE", _archive, "", Vector2(190, 40))
	rb.set_meta("keep", true)
	rb.add_theme_font_size_override("font_size", 14)
	rb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rb.offset_left = -206
	rb.offset_right = -16
	rb.offset_top = 12
	rb.offset_bottom = 52
	_map_layer.add_child(rb)
	var nnew := Game.interlude_new_count()
	var ib := UI.button("✦ INTERLUDES" + (" (%d NEW)" % nnew if nnew > 0 else ""), _interludes, "GoldButton" if nnew > 0 else "", Vector2(190, 40))
	ib.set_meta("keep", true)
	ib.add_theme_font_size_override("font_size", 14)
	ib.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ib.offset_left = -206
	ib.offset_right = -16
	ib.offset_top = 58
	ib.offset_bottom = 98
	_map_layer.add_child(ib)
	_map_layer.add_child(_star_bar())
	_map_layer.draw.connect(_draw_path)
	# the glowing dots flowing along cleared roads live on their own layer (drawn right after the roads,
	# before every stage medallion) so only they are redrawn each frame, not the whole anti-aliased road map
	_flow_layer = Control.new()
	_flow_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_layer.add_child(_flow_layer)
	_map_layer.move_child(_flow_layer, 0)
	_flow_layer.draw.connect(_draw_flow)
	_map_layer.resized.connect(_place_nodes)
	_place_nodes.call_deferred()

var _flow_t := 0.0
var _flow_layer: Control

func _process(delta: float) -> void:
	_flow_t += delta
	if is_instance_valid(_flow_layer):
		_flow_layer.queue_redraw()

## Star Chests bar along the bottom of the map: stars collected in this chapter + three chests to open.
func _star_bar() -> Control:
	var got := Game.chapter_stars(_chapter, _hard)
	var total := DB.STAGES_PER_CHAPTER * 3
	var bar := UI.styled_panel(Color(0.04, 0.02, 0.09, 0.82), Color(UI.GOLD, 0.45), 14, 1, 0)
	bar.set_meta("keep", true)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bar.offset_left = -470
	bar.offset_right = -14
	bar.offset_top = -74
	bar.offset_bottom = -12
	var h := UI.hbox(10)
	bar.add_child(UI.margin(h, 12, 2, 10, 2))
	var lv := UI.vbox(0)
	lv.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(lv)
	lv.add_child(UI.label("STAR CHESTS", 11, Color("#d4b8ff"), 2))
	lv.add_child(UI.label("★ %d / %d" % [got, total], 17, UI.GOLD, 3))
	# track with the three chests sitting on their thresholds
	var track := Control.new()
	track.custom_minimum_size = Vector2(300, 50)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(track)
	track.draw.connect(func():
		var y := 25.0
		var w := track.size.x - 26.0
		track.draw_line(Vector2(4, y), Vector2(4 + w, y), Color(0, 0, 0, 0.6), 8.0, true)
		track.draw_line(Vector2(4, y), Vector2(4 + w, y), Color(1, 1, 1, 0.12), 6.0, true)
		var f := clampf(float(got) / total, 0.0, 1.0)
		if f > 0.0:
			track.draw_line(Vector2(4, y), Vector2(4 + w * f, y), Color(1, 0.78, 0.3), 6.0, true)
			track.draw_line(Vector2(4, y - 1.5), Vector2(4 + w * f, y - 1.5), Color(1, 0.95, 0.7, 0.8), 1.5, true))
	for t in DB.STAR_CHEST_NEED.size():
		track.add_child(_star_chest(t, got))
	track.resized.connect(func():
		for c in track.get_children():
			c.position = Vector2(4 + (track.size.x - 26.0) * float(c.get_meta("need")) / total - 23, -2))
	return bar

func _star_chest(t: int, got: int) -> Control:
	var need: int = DB.STAR_CHEST_NEED[t]
	var stt := Game.star_chest_state(_chapter, t, _hard)
	var give := DB.star_chest_reward(_chapter, t, _hard)
	var tint: Color = [Color("#e0a070"), Color("#cfe0ff"), Color("#ffd479")][t]
	var box := Control.new()
	box.size = Vector2(46, 50)
	box.pivot_offset = Vector2(23, 30)
	box.tooltip_text = "%d★ chest:\n%s" % [need, Game.reward_text(give)]
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.set_meta("need", need)
	box.draw.connect(func():
		if stt == "ready":
			box.draw_circle(Vector2(23, 25), 24, Color(UI.GOLD, 0.22))
		box.draw_circle(Vector2(23, 25), 18, Color(0.08, 0.05, 0.14, 0.95))
		box.draw_arc(Vector2(23, 25), 18, 0, TAU, 32, tint if stt != "locked" else Color(0.45, 0.42, 0.55), 2.0, true))
	var ic := UI.tex_rect(DB.icon("item_royal_chest"), Vector2(30, 30))
	ic.position = Vector2(8, 10)
	ic.size = Vector2(30, 30)
	ic.modulate = tint if stt == "ready" else (Color(0.5, 0.48, 0.6) if stt == "locked" else Color(1, 1, 1, 0.4))
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(ic)
	var nl := UI.label("✓" if stt == "claimed" else "%d★" % need, 11, UI.GREEN if stt == "claimed" else (UI.GOLD if stt == "ready" else UI.MUTED), 3)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.position = Vector2(0, 40)
	nl.size = Vector2(46, 16)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(nl)
	if stt == "ready":
		var tw := box.create_tween().set_loops()
		tw.tween_property(box, "rotation", 0.12, 0.12)
		tw.tween_property(box, "rotation", -0.12, 0.12)
		tw.tween_property(box, "rotation", 0.0, 0.12)
		tw.tween_interval(0.9)
		box.mouse_filter = Control.MOUSE_FILTER_STOP
		box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		box.gui_input.connect(func(ev: InputEvent):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				var g := Game.claim_star_chest(_chapter, t, _hard)
				if not g.is_empty():
					Game.sfx("ui_click")
					main.show_rewards("%d★ CHEST OPENED" % need, g, func(): _render()))
	return box

## Points of the curved road between stage i and i+1 (quadratic bezier, bowing alternately).
func _curve(i: int, sz: Vector2) -> PackedVector2Array:
	var a: Vector2 = NODE_POS[i] * sz
	var b: Vector2 = NODE_POS[i + 1] * sz
	var n := (b - a).orthogonal().normalized()
	var c := (a + b) * 0.5 + n * (b - a).length() * (0.22 if i % 2 == 0 else -0.22)
	var pts := PackedVector2Array()
	for k in 25:
		var t := k / 24.0
		pts.append(a.lerp(c, t).lerp(c.lerp(b, t), t))
	return pts

func _draw_path() -> void:
	var s := _map_layer.size
	for i in NODE_POS.size() - 1:
		var idx := _chapter * DB.STAGES_PER_CHAPTER + i
		var done := _stars(idx) > 0
		var pts := _curve(i, s)
		# road bed + edge
		_map_layer.draw_polyline(pts, Color(0, 0, 0, 0.5), 16.0, true)
		_map_layer.draw_polyline(pts, Color(0.18, 0.12, 0.26, 0.85) if not done else Color(0.35, 0.24, 0.08, 0.9), 10.0, true)
		if done:
			_map_layer.draw_polyline(pts, Color(1, 0.8, 0.35, 0.35), 7.0, true)
			_map_layer.draw_polyline(pts, Color(1, 0.92, 0.6, 0.95), 2.5, true)
		else:
			# footstep dots on a road not walked yet
			for k in range(2, pts.size() - 2, 3):
				_map_layer.draw_circle(pts[k], 2.2, Color(1, 1, 1, 0.38))

func _draw_flow() -> void:
	var s := _map_layer.size
	for i in NODE_POS.size() - 1:
		if _stars(_chapter * DB.STAGES_PER_CHAPTER + i) <= 0:
			continue
		var pts := _curve(i, s)
		for k in 4:
			var f := fmod(_flow_t * 0.45 + k / 4.0, 1.0)
			var p: Vector2 = pts[int(f * (pts.size() - 1))]
			_flow_layer.draw_circle(p, 8.0, Color(1, 0.88, 0.45, 0.22))
			_flow_layer.draw_circle(p, 3.5, Color(1, 0.97, 0.75, 0.95))

func _place_nodes() -> void:
	if not is_instance_valid(_map_layer):
		return
	for c in _map_layer.get_children():
		if c is Button and not c.has_meta("keep"):
			c.queue_free()
	var s := _map_layer.size
	var prog := _prog()
	for i in DB.STAGES_PER_CHAPTER:
		var idx := _chapter * DB.STAGES_PER_CHAPTER + i
		var st := _st(idx)
		var boss: bool = st["boss"]
		var d := 92.0 if boss else 74.0
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(d, d + 26)
		b.position = NODE_POS[i] * s - Vector2(d * 0.5, d * 0.5)
		b.disabled = idx > prog
		var stars := _stars(idx)
		var col: Color = Color("#ff5c6c") if boss else (UI.GOLD if stars > 0 else Color("#8fb4ff"))
		var state := "locked" if idx > prog else ("current" if idx == prog and stars == 0 else ("cleared" if stars > 0 else "open"))
		var med := StageNode.new()
		med.d = d
		med.col = col if state != "locked" else Color(0.42, 0.42, 0.48)
		med.state = state
		med.selected = idx == _sel
		med.size = Vector2(d, d)
		med.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(med)
		# enemy portrait inside the medallion (boss = the boss, normal stage = its first enemy)
		var e0: Dictionary = st["enemies"][0]
		var face := CircleTex.new()
		face.tex = DB.face(e0["id"])
		face.inset = 7.0
		face.size = Vector2(d, d)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.modulate = Color(0.22, 0.22, 0.26) if state == "locked" else (Color.WHITE if boss else Color(0.62, 0.6, 0.7))
		if e0.get("mirror", false) and state != "locked":
			UI.corrupt(face, str(e0.get("variant", "")))
		med.add_child(face)
		var shade := StageShade.new()
		shade.d = d
		shade.locked = state == "locked"
		shade.size = Vector2(d, d)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		med.add_child(shade)
		var l := UI.label(st["id"], (22 if not boss else 18) if state != "locked" else 13, Color.WHITE if state != "locked" else Color(0.75, 0.75, 0.8), 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER if state != "locked" else VERTICAL_ALIGNMENT_BOTTOM
		l.size = Vector2(d, d - (0 if state != "locked" else 12))
		l.position = Vector2(0, 8 if boss and state != "locked" else 0)
		med.add_child(l)
		if boss:
			var bc := UI.styled_panel(Color("#7a0f1e"), Color("#ffb0b8"), 6, 1, 0)
			bc.add_child(UI.margin(UI.label("BOSS", 11, Color.WHITE, 3), 7, 0, 7, 0))
			bc.position = Vector2(d * 0.5 - 24, -9)
			bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			med.add_child(bc)
		# stars on a little dark pill
		var pill := UI.styled_panel(Color(0, 0, 0, 0.62), Color(col, 0.5) if state != "locked" else Color(1, 1, 1, 0.12), 9, 1, 0)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sl := UI.label("★".repeat(stars) + "☆".repeat(3 - stars) if state != "locked" else "LOCKED", 14 if state != "locked" else 10, UI.GOLD if state != "locked" else UI.MUTED, 3)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pill.add_child(UI.margin(sl, 6, 0, 6, 0))
		pill.position = Vector2(d * 0.5 - 34, d - 6)
		pill.custom_minimum_size = Vector2(68, 0)
		b.add_child(pill)
		var sel_idx: int = idx
		b.pressed.connect(func():
			Game.sfx("ui_click")
			_sel = sel_idx
			_render())
		_map_layer.add_child(b)
		if state == "current":
			# bouncing "NEXT" flag above the stage to play next
			var flag := UI.styled_panel(UI.GOLD, Color.WHITE, 8, 1, 0)
			var up: bool = NODE_POS[i].y > 0.45 # top-right nodes sit under the map buttons: flag goes below
			flag.add_child(UI.margin(UI.label("▼ NEXT" if up else "▲ NEXT", 12, Color("#3a1d05"), 0), 8, 1, 8, 1))
			flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flag.position = Vector2(d * 0.5 - 34, (-34 if not boss else -44) if up else d + 22)
			b.add_child(flag)
			var tw := flag.create_tween().set_loops()
			tw.tween_property(flag, "position:y", flag.position.y - 7, 0.5).set_trans(Tween.TRANS_SINE)
			tw.tween_property(flag, "position:y", flag.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	_map_layer.queue_redraw()
	var k := 0
	for c in _map_layer.get_children():
		if c is Button:
			c.pivot_offset = c.size * 0.5
			c.scale = Vector2(0.3, 0.3)
			c.modulate.a = 0.0
			var tw: Tween = c.create_tween().set_parallel(true)
			tw.tween_property(c, "scale", Vector2.ONE, 0.35).set_delay(k * 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(c, "modulate:a", 1.0, 0.2).set_delay(k * 0.06)
			k += 1

static func _arc_name(ch: int) -> String:
	if ch >= 40:
		return "ARC 11  •  THE FROSTBOUND CROWN"
	if ch >= 38:
		return "ARC 10  •  THE ABYSS CHOIR"
	if ch >= 34:
		return "ARC 9  •  THE WILD HUNT"
	if ch >= 30:
		return "ARC 8  •  THE GILDED GATE"
	if ch >= 26:
		return "ARC 7  •  ASHES OF ABADDON"
	if ch >= 22:
		return "ARC 6  •  ECHOES OF THE FIRST OATH"
	if ch >= 18:
		return "ARC 5  •  THE STARBOUND EXPEDITION"
	if ch >= 14:
		return "ARC 4  •  THE LAST LIGHT"
	if ch >= 10:
		return "ARC 3  •  THE HOUR OF DAWN"
	if ch >= 6:
		return "ARC 2  •  THE SECOND ECLIPSE"
	return "ARC 1  •  THE ECLIPSE"

## Interludes: battle-free episodes between arcs.
func _interludes() -> void:
	var v: VBoxContainer = main.popup("INTERLUDES", 680)
	v.add_child(UI.wrap_label("Quiet moments between the battles. Each one unlocks after an Arc. First read: 200 Gems + 1 Summon Ticket + Bond for the heroes in it.", 14, UI.MUTED))
	for it in DB.INTERLUDES:
		var item: Dictionary = it
		var open := Game.interlude_open(item)
		var read := Game.interlude_read(item["id"])
		var h := UI.hbox(10)
		v.add_child(h)
		var faces := UI.hbox(2)
		for hid in item["cast"]:
			var f := UI.tex_rect(DB.face(hid), Vector2(36, 36), true)
			if not open:
				f.modulate = Color(0.3, 0.3, 0.35)
			faces.add_child(f)
		h.add_child(faces)
		var txt := str(item["name"]) if open else "Clear %d stages to unlock" % int(item["req"])
		var b := UI.button(("▶  " if open else "LOCKED  •  ") + txt + ("" if read or not open else "   NEW!"), func():
			main.close_popup(v)
			var lines: Array = item["lines"]
			if Game.interlude_read(item["id"]):
				lines = lines.filter(func(ln): return str(ln[0]) != "?")
			main.dialogue(lines, func():
				var r := Game.finish_interlude(item)
				if not r.is_empty():
					main.show_rewards("INTERLUDE: " + str(item["name"]).to_upper(), r)
					_render(), str(item["bg"])), "GoldButton" if open and not read else "", Vector2(0, 46))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not open
		h.add_child(b)

## Replay any cutscene already seen in this chapter.
func _archive() -> void:
	var chd: Dictionary = DB.CHAPTERS[_chapter]
	var seen: Array = Game.s["story"].get("seen", [])
	var v: VBoxContainer = main.popup("STORY ARCHIVE  •  CH.%d %s" % [_chapter + 1, chd["name"]], 640)
	v.add_child(UI.label(_arc_name(_chapter), 14, Color("#d4b8ff"), 3))
	var boss_done := Game.stage_stars(_chapter * DB.STAGES_PER_CHAPTER + DB.STAGES_PER_CHAPTER - 1) > 0
	var scenes := [["intro", "Prologue", seen.has("intro%d" % _chapter)], ["mid", "Along the Way", seen.has("mid%d" % _chapter)],
		["mid2", "Before the Storm", seen.has("mid2%d" % _chapter)], ["boss_lines", "Confrontation", seen.has("boss%d" % _chapter)], ["outro", "Epilogue", boss_done]]
	var any := false
	for sc in scenes:
		var key: String = sc[0]
		if not chd.has(key):
			continue
		var open: bool = sc[2]
		any = any or open
		var b := UI.button(("▶  " + sc[1]) if open else ("LOCKED  •  " + sc[1] + "  (not seen yet)"), func():
			main.close_popup(v)
			# choices already gave their Bond reward the first time — replay without them
			main.dialogue((chd[key] as Array).filter(func(ln): return str(ln[0]) != "?"), Callable(), str(chd["bg"])), "", Vector2(0, 48))
		b.disabled = not open
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
	if not any:
		v.add_child(UI.label("Play this chapter to unlock its scenes.", 14, UI.MUTED))

func _render_detail() -> void:
	for c in _detail.get_children():
		c.queue_free()
	for c in _actions.get_children():
		c.queue_free()
	var st := _st(_sel)
	var stars := _stars(_sel)
	var boss: bool = st["boss"]
	# title: stage id + level on one line, name below, stars with the 3-star rule as tooltip
	var th := UI.hbox(8)
	_detail.add_child(th)
	var idc := UI.styled_panel(Color("#7a0f1e") if boss else Color(0.12, 0.16, 0.35), Color("#ffb0b8") if boss else Color("#9fb4ff"), 7, 1, 0)
	idc.add_child(UI.margin(UI.label(("BOSS  " if boss else "STAGE ") + str(st["id"]), 13, Color.WHITE, 2), 8, 1, 8, 1))
	th.add_child(idc)
	th.add_child(UI.label("Lv.%d" % st["level"], 14, UI.MUTED, 1))
	th.add_child(UI.spacer())
	var stl := UI.stars(stars, 20, 3)
	stl.tooltip_text = "3★: win • no hero lost • within 3 rounds"
	stl.mouse_filter = Control.MOUSE_FILTER_PASS
	th.add_child(stl)
	var nm := UI.label(str(st["name"]).trim_prefix("BOSS • "), 22, Color.WHITE, 5)
	nm.clip_text = true
	_detail.add_child(nm)
	# power: your team vs the enemy on one bar
	var ep := Game.enemy_power(st["enemies"])
	var tp := Game.team_power()
	var ok := tp >= ep
	var ph := UI.hbox(6)
	_detail.add_child(ph)
	ph.add_child(UI.label("⚔ " + Game.fmt(tp), 14, Color("#6fd3ff"), 2))
	ph.add_child(UI.spacer())
	ph.add_child(UI.label(("SAFE" if tp >= ep * 1.2 else "EVEN") if ok else "TOO STRONG", 12, UI.GREEN if ok else Color("#ff8a9a"), 2))
	ph.add_child(UI.spacer())
	ph.add_child(UI.label(Game.fmt(ep) + " ☠", 14, Color("#ff8a9a"), 2))
	var cmp := UI.bar(tp, tp + ep, "", 7)
	cmp.add_theme_stylebox_override("fill", UI.style(Color("#6fd3ff"), Color.TRANSPARENT, 3, 0, 0))
	cmp.add_theme_stylebox_override("background", UI.style(Color("#c8475a"), Color.TRANSPARENT, 3, 0, 0))
	cmp.tooltip_text = "Blue = your team power, red = enemy power" + ("" if ok else "\nYour team may be too weak!")
	cmp.mouse_filter = Control.MOUSE_FILTER_PASS
	_detail.add_child(cmp)

	var sc := Game.scout(st["enemies"])
	_detail.add_child(UI.label("ENEMIES" + ("  •  mostly %s" % sc["main"] if not sc.is_empty() else ""), 14, UI.GOLD, 3))
	var ef := HFlowContainer.new()
	ef.add_theme_constant_override("h_separation", 5)
	ef.add_theme_constant_override("v_separation", 5)
	for e in st["enemies"]:
		var p := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if e.get("boss", false) else Color("#6b4a7e"), 8, 2, 1)
		var fc := Control.new()
		fc.custom_minimum_size = Vector2(48, 48)
		fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(fc)
		var ft := UI.tex_rect(DB.face(e["id"]), Vector2(48, 48), true)
		ft.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if e.get("mirror", false):
			UI.corrupt(ft, str(e.get("variant", "")))
		fc.add_child(ft)
		var el := UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(e["id"]), "elem_light")), Vector2(16, 16))
		el.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		el.offset_left = -16
		el.offset_top = -16
		fc.add_child(el)
		p.tooltip_text = (str(e.get("variant", "")).capitalize() + " " if e.get("mirror", false) else "") + DB.name_of(e["id"])
		p.mouse_filter = Control.MOUSE_FILTER_PASS
		ef.add_child(p)
	_detail.add_child(ef)
	if not sc.is_empty():
		var sh := UI.hbox(6)
		sh.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON[sc["counter"]]), Vector2(22, 22)))
		var owned := (sc["heroes"] as Array).size()
		var note := "%d in team" % int(sc["deployed"]) if owned > 0 else "none owned"
		sh.add_child(UI.label("Bring %s: +30%% ATK  •  %s" % [sc["counter"], note], 13, Color("#9fe3c0"), 2))
		_detail.add_child(sh)

	# rewards: per clear + first clear bonus in one framed block
	var rp := UI.styled_panel(Color(0, 0, 0, 0.35), Color(UI.GOLD, 0.3), 10, 1, 6)
	_detail.add_child(rp)
	var rv := UI.vbox(4)
	rp.add_child(rv)
	var rw := {"gold": st["gold"], "hero_exp": st["hero_exp"]}
	if _hard:
		rw["shard:" + str(st["shard_id"])] = st["shards"]
	var r1 := UI.hbox(8)
	rv.add_child(r1)
	var rl := UI.label("REWARDS", 12, UI.GOLD, 2)
	rl.custom_minimum_size.x = 74
	r1.add_child(rl)
	var rr1 := UI.reward_row(rw, 26, 13)
	rr1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(rr1)
	if _hard:
		rv.add_child(UI.label("Guaranteed %s shards every clear!" % DB.name_of(st["shard_id"]), 12, Color("#ff9ad5"), 2))
	if stars == 0:
		var fr := {"gems": st["first_gems"]}
		for k in st["first_items"].keys():
			fr[k] = st["first_items"][k]
		var r2 := UI.hbox(8)
		rv.add_child(r2)
		var fl := UI.label("1ST CLEAR", 12, Color("#9fe3c0"), 2)
		fl.custom_minimum_size.x = 74
		r2.add_child(fl)
		var rr2 := UI.reward_row(fr, 26, 13)
		rr2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r2.add_child(rr2)
	var md: Dictionary = st.get("mod", {})
	if not md.is_empty():
		var mp := UI.styled_panel(Color(0.05, 0.1, 0.2, 0.9), Color("#5fb8ff"), 8, 1, 8)
		mp.add_child(UI.wrap_label("FIELD EFFECT • " + str(md["name"]) + " (both sides)", 13, Color("#9fd0ff")))
		_detail.add_child(mp)
	var bb := UI.button("⚔ BATTLE   (%d Energy)" % st["energy"], _battle, "GoldButton", Vector2(0, 56))
	_actions.add_child(bb)
	var sw := UI.hbox(8)
	_actions.add_child(sw)
	for n in [1, 5]:
		var times: int = n
		var b := UI.button("SWEEP x%d" % n, func(): _sweep(times), "", Vector2(0, 44))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = stars < 3
		sw.add_child(b)
	var fb := UI.button("FORMATION", func(): main.go("formation"), "", Vector2(0, 44))
	fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sw.add_child(fb)

func _sweep(times: int) -> void:
	var r := Game.sweep_stage(_sel, times, _hard)
	if r.has("error"):
		main.toast(r["error"], UI.RED)
		return
	main.show_rewards("SWEEP x%d" % times, r)

func _battle() -> void:
	if main._vn_active():
		return   # a story scene is already playing: don't stack another one on top
	if _hard and not Game.hard_unlocked(_sel):
		main.toast("Clear this chapter's boss on NORMAL (and the previous Hard stage) first.", UI.MUTED)
		return
	var st := _st(_sel)
	if Game.amount("energy") < int(st["energy"]):
		main.toast("Not enough Energy. Buy Energy Flasks in the Shop or wait for it to refill.", UI.RED)
		return
	var seen: Array = Game.s["story"].get("seen", [])
	var key := ""
	var lines: Array = []
	var chd: Dictionary = DB.CHAPTERS[st["chapter"]]
	if _sel % DB.STAGES_PER_CHAPTER == 0 and not seen.has("intro%d" % st["chapter"]):
		key = "intro%d" % st["chapter"]
		lines = chd["intro"]
	elif _sel % DB.STAGES_PER_CHAPTER == 2 and chd.has("mid") and not seen.has("mid%d" % st["chapter"]):
		key = "mid%d" % st["chapter"]
		lines = chd["mid"]
	elif _sel % DB.STAGES_PER_CHAPTER == 4 and chd.has("mid2") and not seen.has("mid2%d" % st["chapter"]):
		key = "mid2%d" % st["chapter"]
		lines = chd["mid2"]
	elif st["boss"] and not seen.has("boss%d" % st["chapter"]):
		key = "boss%d" % st["chapter"]
		lines = chd["boss_lines"]
	var go_prep := func(): main.go("formation", {"mode": "hard" if _hard else "story", "stage": _sel})
	if _hard:
		key = ""
	if key != "":
		seen.append(key)
		Game.s["story"]["seen"] = seen
		Game.mark_dirty()
		main.dialogue(lines, go_prep, str(chd["bg"]))
	else:
		go_prep.call()


## Stage medallion: soft glow, layered metal rim, rotating ring on the stage to play next.
## Drawn as one triangle batch (was ~10 draw calls, ~40 on the current stage). The animated stage splits
## into layers in the original paint order: shadow (self) → pulsing halo → static rim → turning arcs
## (cached per rotation step), so only the halo and arcs are re-submitted each frame.
class StageNode extends Control:
	const AABatch = preload("res://game/ui/aa_batch.gd")
	const SPIN_STEPS := 720
	static var _spin_cache := {}
	var d := 74.0
	var col := Color.WHITE
	var state := "open"
	var selected := false
	var _t := 0.0
	var _pulse_l: Node2D
	var _spin_l: Node2D

	func _animated() -> bool:
		return state == "current" or selected

	func _ready() -> void:
		if not _animated():
			return
		_pulse_l = Node2D.new()
		_pulse_l.draw.connect(_draw_pulse)
		var body := Node2D.new()
		body.draw.connect(_draw_body.bind(body))
		_spin_l = Node2D.new()
		_spin_l.draw.connect(_draw_spin)
		var k := 0
		for n in [_pulse_l, body, _spin_l]:
			add_child(n)
			move_child(n, k)
			k += 1

	func _process(delta: float) -> void:
		if _animated():
			_t += delta
			if _pulse_l:
				_pulse_l.queue_redraw()
				_spin_l.queue_redraw()

	func _draw() -> void:
		var c := Vector2(d, d) * 0.5
		var r := d * 0.5
		if _animated():
			draw_circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.45))
			return
		var b = AABatch.new()
		b.circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.45))
		if state != "locked":
			b.circle(c, r + 9 + 0.5 * 3.0, Color(col, 0.10 + 0.08 * 0.5))
		_rim(b)
		b.flush(self)

	func _draw_pulse() -> void:
		if state == "locked":
			return
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		_pulse_l.draw_circle(Vector2(d, d) * 0.5, d * 0.5 + 9 + pulse * 3.0, Color(col, 0.10 + 0.08 * pulse))

	func _draw_body(n: Node2D) -> void:
		var b = AABatch.new()
		_rim(b)
		b.flush(n)

	func _rim(b: Object) -> void:
		var c := Vector2(d, d) * 0.5
		var r := d * 0.5
		if state != "locked":
			b.circle(c, r + 4, Color(col, 0.22))
		b.circle(c, r, col.darkened(0.55))
		b.circle(c, r - 2, col)
		b.circle(c, r - 4.5, col.darkened(0.35))
		b.circle(c, r - 6.5, Color(0.05, 0.03, 0.1))
		b.arc(c, r - 1.2, PI * 1.1, PI * 1.9, 24, Color(1, 1, 1, 0.55), 1.5)

	func _draw_spin() -> void:
		var per := TAU / 10.0
		var step := int(round(fposmod(_t * 1.4, per) / per * SPIN_STEPS)) % SPIN_STEPS
		var ac := Color(col.lightened(0.3), 0.95)
		var key := "%.2f:%d:%s" % [d, step, ac]
		if not _spin_cache.has(key):
			var b = AABatch.new()
			var c := Vector2(d, d) * 0.5
			var a0 := per * step / SPIN_STEPS
			for k in 10:
				var s0 := a0 + k * TAU / 10.0
				b.arc(c, d * 0.5 + 8.0, s0, s0 + 0.32, 6, ac, 3.0)
			if _spin_cache.size() > 3000:
				_spin_cache.clear()
			_spin_cache[key] = [b.idx, b.pts, b.cols]
		var g: Array = _spin_cache[key]
		RenderingServer.canvas_item_add_triangle_array(_spin_l.get_canvas_item(), g[0], g[1], g[2])

## Texture drawn inside a circle (the enemy portrait).
class CircleTex extends Control:
	var tex: Texture2D
	var inset := 7.0

	func _draw() -> void:
		if tex == null:
			return
		var c := size * 0.5
		var r := size.x * 0.5 - inset
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for k in 40:
			var a := k * TAU / 40.0
			var v := Vector2(cos(a), sin(a))
			pts.append(c + v * r)
			uvs.append(Vector2(0.5, 0.45) + v * 0.5)
		draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, tex)

## Dark bottom gradient over the portrait (so the stage id reads) + a padlock on locked stages.
class StageShade extends Control:
	var d := 74.0
	var locked := false

	func _draw() -> void:
		var b = load("res://game/ui/aa_batch.gd").new()   # one draw call (was ~20)
		var c := Vector2(d, d) * 0.5
		var r := d * 0.5 - 7.0
		for k in 6:
			b.arc(c, r - 2 - k * 2.0, PI * 0.15, PI * 0.85, 20, Color(0, 0, 0, 0.16), 4.0)
		b.circle(c, r, Color(0, 0, 0, 0.18))
		if locked:
			var lc := Color(0.82, 0.82, 0.88, 0.9)
			var o := c + Vector2(0, -6)
			b.arc(o + Vector2(0, -6), 7.0, PI, TAU, 16, lc, 3.0)
			b.rect(Rect2(o + Vector2(-10, -6), Vector2(20, 15)), lc)
			b.circle(o + Vector2(0, 1), 2.5, Color(0.1, 0.08, 0.14))
		b.flush(self)
