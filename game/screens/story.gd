extends Screen
## Campaign map: chapters, stage nodes, stage briefing, sweep & story dialogue.

const NODE_POS := [Vector2(0.09, 0.72), Vector2(0.25, 0.38), Vector2(0.42, 0.66), Vector2(0.58, 0.32), Vector2(0.74, 0.62), Vector2(0.9, 0.3)]

var _chapter := 0
var _sel := 0
var _map: PanelContainer
var _map_layer: Control
var _detail: VBoxContainer
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
	_hard = bool(params.get("hard", false))
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
	_detail = UI.vbox(8)
	rp.add_child(UI.scroll(_detail))
	_render()
	tutorial("story")

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
	var arcs := [[0, 5], [6, 9], [10, 13], [14, 17], [18, 21], [22, 25], [26, 29], [30, 33], [34, DB.CHAPTERS.size() - 1]]
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
	_map_layer.draw.connect(_draw_path)
	_map_layer.resized.connect(_place_nodes)
	_place_nodes.call_deferred()

var _flow_t := 0.0

func _process(delta: float) -> void:
	_flow_t += delta
	if is_instance_valid(_map_layer):
		_map_layer.queue_redraw()

func _draw_path() -> void:
	var s := _map_layer.size
	for i in NODE_POS.size() - 1:
		var a: Vector2 = NODE_POS[i] * s
		var b: Vector2 = NODE_POS[i + 1] * s
		var idx := _chapter * DB.STAGES_PER_CHAPTER + i
		var col := Color(1, 0.85, 0.45, 0.9) if _stars(idx) > 0 else Color(1, 1, 1, 0.35)
		_map_layer.draw_line(a, b, Color(0, 0, 0, 0.6), 9.0, true)
		_map_layer.draw_dashed_line(a, b, col, 4.0, 12.0, true)
		if _stars(idx) > 0:
			for k in 3:
				var f := fmod(_flow_t * 0.5 + k / 3.0, 1.0)
				var p := a.lerp(b, f)
				_map_layer.draw_circle(p, 7.0, Color(1, 0.9, 0.5, 0.25))
				_map_layer.draw_circle(p, 3.5, Color(1, 0.95, 0.7, 0.95))

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
		var ring := Panel.new()
		var stars := _stars(idx)
		var col: Color = Color("#ff5c6c") if boss else (UI.GOLD if stars > 0 else Color("#8fb4ff"))
		if idx > prog:
			col = Color(0.4, 0.4, 0.45)
		ring.add_theme_stylebox_override("panel", UI.style(Color(0.05, 0.03, 0.1, 0.9), col, int(d / 2), 4 if idx == _sel else 2, 0, 6))
		ring.size = Vector2(d, d)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ring)
		if boss:
			var bf := UI.tex_rect(DB.face(st["enemies"][0]["id"]), Vector2(d - 12, d - 12), true)
			bf.position = Vector2(6, 6)
			bf.size = Vector2(d - 12, d - 12)
			if idx > prog:
				bf.modulate = Color(0.3, 0.3, 0.3)
			if st["enemies"][0].get("mirror", false):
				UI.corrupt(bf, str(st["enemies"][0].get("variant", "")))
			ring.add_child(bf)
		var l := UI.label(st["id"], 22 if not boss else 18, Color.WHITE, 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(d, d)
		ring.add_child(l)
		var sl := UI.label("★".repeat(stars) + "☆".repeat(3 - stars) if idx <= prog else "LOCKED", 16 if idx <= prog else 11, UI.GOLD if idx <= prog else UI.MUTED, 4)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.position = Vector2(0, d - 2)
		sl.size = Vector2(d, 22)
		b.add_child(sl)
		var sel_idx: int = idx
		b.pressed.connect(func():
			Game.sfx("ui_click")
			_sel = sel_idx
			_render())
		_map_layer.add_child(b)
		if idx == prog and stars == 0:
			ring.pivot_offset = Vector2(d, d) * 0.5
			var tw := ring.create_tween().set_loops()
			tw.tween_property(ring, "scale", Vector2(1.1, 1.1), 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(ring, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
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
	var st := _st(_sel)
	var stars := _stars(_sel)
	_detail.add_child(UI.label("STAGE %s" % st["id"], 15, Color("#9fb4ff"), 3))
	_detail.add_child(UI.label(st["name"], 24, Color.WHITE, 5))
	var sr := UI.hbox(8)
	sr.add_child(UI.stars(stars, 22, 3))
	sr.add_child(UI.label("Lv.%d enemies" % st["level"], 15, UI.MUTED))
	_detail.add_child(sr)
	var ep := Game.enemy_power(st["enemies"])
	var tp := Game.team_power()
	var pw := UI.label("Enemy Power %s   •   Your Team %s" % [Game.fmt(ep), Game.fmt(tp)], 15, UI.GREEN if tp >= ep else Color("#ff8a9a"), 3)
	_detail.add_child(pw)
	if tp < ep:
		_detail.add_child(UI.label("⚠ Your team may be too weak!", 14, Color("#ff8a9a")))

	_detail.add_child(UI.label("ENEMIES", 15, UI.GOLD, 3))
	var ef := HFlowContainer.new()
	ef.add_theme_constant_override("h_separation", 6)
	for e in st["enemies"]:
		var p := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if e.get("boss", false) else Color("#6b4a7e"), 8, 2, 1)
		var ft := UI.tex_rect(DB.face(e["id"]), Vector2(58, 58), true)
		if e.get("mirror", false):
			UI.corrupt(ft, str(e.get("variant", "")))
		p.add_child(ft)
		p.tooltip_text = (str(e.get("variant", "")).capitalize() + " " if e.get("mirror", false) else "") + DB.name_of(e["id"])
		ef.add_child(p)
	_detail.add_child(ef)

	_detail.add_child(UI.label("REWARDS", 15, UI.GOLD, 3))
	var rw := {"gold": st["gold"], "hero_exp": st["hero_exp"]}
	if _hard:
		rw["shard:" + str(st["shard_id"])] = st["shards"]
	_detail.add_child(UI.reward_row(rw, 30, 14))
	if _hard:
		_detail.add_child(UI.label("Guaranteed %s shards every clear!" % DB.name_of(st["shard_id"]), 13, Color("#ff9ad5"), 2))
	if stars == 0:
		var fr := {"gems": st["first_gems"]}
		for k in st["first_items"].keys():
			fr[k] = st["first_items"][k]
		_detail.add_child(UI.label("First clear bonus:", 13, UI.MUTED))
		_detail.add_child(UI.reward_row(fr, 30, 14))
	_detail.add_child(UI.label("3★: win • no hero lost • within 3 rounds", 13, UI.MUTED))
	var md: Dictionary = st.get("mod", {})
	if not md.is_empty():
		var mp := UI.styled_panel(Color(0.05, 0.1, 0.2, 0.9), Color("#5fb8ff"), 8, 1, 8)
		mp.add_child(UI.wrap_label("FIELD EFFECT • " + str(md["name"]) + " (both sides)", 13, Color("#9fd0ff")))
		_detail.add_child(mp)
	_detail.add_child(UI.spacer(false))
	var bb := UI.button("⚔ BATTLE   (%d Energy)" % st["energy"], _battle, "GoldButton", Vector2(0, 56))
	_detail.add_child(bb)
	var sw := UI.hbox(8)
	_detail.add_child(sw)
	for n in [1, 5]:
		var times: int = n
		var b := UI.button("SWEEP x%d" % n, func(): _sweep(times), "", Vector2(0, 44))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = stars < 3
		sw.add_child(b)
	_detail.add_child(UI.button("FORMATION", func(): main.go("formation"), "", Vector2(0, 44)))

func _sweep(times: int) -> void:
	var r := Game.sweep_stage(_sel, times, _hard)
	if r.has("error"):
		main.toast(r["error"], UI.RED)
		return
	main.show_rewards("SWEEP x%d" % times, r)

func _battle() -> void:
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
