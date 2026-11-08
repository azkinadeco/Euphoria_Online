extends Screen
## Garden (Sakura Oath style dorm): chibi heroes wander around, tap them for
## voice lines, Bond EXP and the occasional gift.

var _area: Control
var _walkers: Array = []   # {id, node: UnitView, target: Vector2, wait: float, speed}
var _bubble: PanelContainer
var _bubble_l: Label
var _bubble_owner: Control
var _hud: PanelContainer

func build() -> void:
	set_bg("forest", 0.12)
	ambient(Color(1.0, 0.95, 0.7), 30)
	var bar := header("GARDEN", ["gold", "gems"])
	bar.add_child(UI.button("♥ MINI-GAME (%d)" % Game.minigame_plays_left(), func(): main.go("minigame"), "GoldButton", Vector2(200, 46)))
	bar.add_child(UI.button("RESIDENTS", _pick_residents, "", Vector2(150, 46)))
	_area = Control.new()
	_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_area.anchor_top = 0.42
	_area.offset_bottom = -20
	_area.offset_left = 285
	_area.offset_right = -40
	_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_area)
	var hint := UI.styled_panel(Color(0, 0, 0, 0.5), Color(1, 1, 1, 0.15), 16, 1, 6.0)
	hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint.offset_top = 84
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.add_child(UI.label("  ♥  Tap a hero to play with her — up to %d Bond taps each per day  " % DB.GARDEN_TAPS_PER_DAY, 14, Color.WHITE, 2))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	_hud = UI.styled_panel(Color(0.06, 0.04, 0.1, 0.82), Color(UI.GOLD, 0.5), 12, 1, 10.0)
	_hud.position = Vector2(16, 88)
	_hud.custom_minimum_size = Vector2(250, 0)
	add_child(_hud)
	_bubble = UI.styled_panel(Color(1, 1, 1, 0.95), UI.GOLD, 14, 2, 10)
	_bubble.custom_minimum_size = Vector2(280, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_l = UI.wrap_label("", 14, Color("#2a1a3a"))
	_bubble.add_child(_bubble_l)
	_bubble.visible = false
	_bubble.z_index = 50
	add_child(_bubble)
	_spawn.call_deferred()
	tutorial("garden")

func _taps(id: String) -> int:
	return int(Game.s["quests"]["progress"].get("garden_" + id, 0))

## Left card: each resident's Bond taps used today as heart pips.
func _render_hud() -> void:
	for c in _hud.get_children():
		c.queue_free()
	var v := UI.vbox(6)
	_hud.add_child(v)
	var ids: Array = Game.s["garden"]
	var left := 0
	for id in ids:
		left += maxi(0, DB.GARDEN_TAPS_PER_DAY - _taps(id))
	var t := UI.hbox(6)
	v.add_child(t)
	var tl := UI.label("RESIDENTS TODAY", 13, UI.GOLD, 2)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_child(tl)
	t.add_child(UI.label("%d taps left" % left, 11, UI.GREEN if left > 0 else UI.MUTED, 0))
	for id in ids:
		var r := UI.hbox(8)
		v.add_child(r)
		r.add_child(UI.tex_rect(DB.face(id), Vector2(32, 32), true))
		var rv := UI.vbox(0)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(rv)
		var nm := UI.label("%s  •  Bond %d" % [DB.name_of(id).split(" ")[0], int(Game.hero(id)["bond"])], 12, Color.WHITE, 0)
		nm.clip_text = true
		rv.add_child(nm)
		var used := _taps(id)
		rv.add_child(UI.label("♥".repeat(mini(used, DB.GARDEN_TAPS_PER_DAY)) + "♡".repeat(maxi(0, DB.GARDEN_TAPS_PER_DAY - used)), 12, Color("#ff8fb8") if used < DB.GARDEN_TAPS_PER_DAY else UI.MUTED, 0))
	if ids.is_empty():
		v.add_child(UI.label("Nobody lives here yet.", 12, UI.MUTED, 0))

func _spawn() -> void:
	_render_hud()
	for w in _walkers:
		w["node"].queue_free()
	_walkers.clear()
	var ids: Array = Game.s["garden"]
	if ids.is_empty():
		var l := UI.label("No residents. Tap RESIDENTS to invite heroes!", 20, Color.WHITE, 6)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_area.add_child(l)
		return
	for id in ids:
		var sz := Vector2(150, 150)
		var uv := UnitView.new(id, false, DB.sprite(id, int(Game.hero(id).get("star", 1)), int(Game.hero(id).get("skin", 0))), sz, -1, false)
		uv.mouse_filter = Control.MOUSE_FILTER_STOP
		uv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		uv.position = _rand_point(sz)
		_area.add_child(uv)
		uv.start_idle()
		var hid: String = id
		uv.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_tap(hid, uv))
		var name_l := UI.label(DB.name_of(id), 13, Color.WHITE, 4)
		name_l.position = Vector2(0, sz.y + 2)
		name_l.size = Vector2(sz.x, 18)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		uv.add_child(name_l)
		_walkers.append({"id": id, "node": uv, "target": _rand_point(sz), "wait": randf_range(0.0, 2.0), "speed": randf_range(40, 70)})

func _rand_point(sz: Vector2) -> Vector2:
	var s := _area.size
	return Vector2(randf_range(0, maxf(10.0, s.x - sz.x)), randf_range(0, maxf(10.0, s.y - sz.y)))

func _process(delta: float) -> void:
	for w in _walkers:
		var n: UnitView = w["node"]
		if not is_instance_valid(n):
			continue
		if w["wait"] > 0.0:
			w["wait"] -= delta
			if randf() < delta * 0.25:
				_emote(n)
			continue
		var to: Vector2 = w["target"] - n.position
		if to.length() < 4.0:
			w["wait"] = randf_range(1.0, 4.0)
			w["target"] = _rand_point(n.size)
			continue
		var step: Vector2 = to.normalized() * float(w["speed"]) * delta
		n.position += step
		n.sprite.flip_h = step.x < 0.0
		# a little hop while walking
		n.sprite.position.y = -absf(sin(Time.get_ticks_msec() / 130.0 + n.position.x * 0.05)) * 6.0
	# keep depth order (lower on screen = in front)
	var nodes: Array = []
	for w in _walkers:
		if is_instance_valid(w["node"]):
			nodes.append(w["node"])
	nodes.sort_custom(func(a, b): return a.position.y < b.position.y)
	for i in nodes.size():
		nodes[i].z_index = i
	if _bubble.visible and is_instance_valid(_bubble_owner):
		var gp := _bubble_owner.get_global_rect().position - get_global_rect().position
		_bubble.position = gp + Vector2(_bubble_owner.size.x * 0.5 - 140, -_bubble.size.y - 4)

func _tap(id: String, uv: UnitView) -> void:
	Game.sfx("ui_click")
	for w in _walkers:
		if w["id"] == id:
			w["wait"] = 2.5
	var r := Game.garden_tap(id)
	# happy jump with a slight grow
	var tw := uv.create_tween()
	tw.tween_property(uv, "scale", Vector2(1.18, 1.18), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(uv.sprite, "position:y", -42.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(uv.sprite, "position:y", 0.0, 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(uv, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD)
	_hearts(uv)
	_bubble_l.text = "%s\n%s" % [DB.name_of(id), r["line"]]
	_bubble_owner = uv
	_bubble.visible = true
	UI.pop(_bubble, 0.2)
	if _bubble.has_meta("tw"):
		var old: Tween = _bubble.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	var bt := _bubble.create_tween()
	bt.tween_interval(3.0)
	bt.tween_callback(func(): _bubble.visible = false)
	_bubble.set_meta("tw", bt)
	_render_hud()
	if int(r["bond"]) > 0:
		_float(uv, "+%d Bond" % r["bond"], Color("#ff8fb8"))
	else:
		_float(uv, "Bond limit reached today", UI.MUTED)
	if not r["gift"].is_empty():
		main.toast("%s found a gift for you: %s!" % [DB.name_of(id), Game.reward_text(r["gift"])], UI.GOLD)

const EMOTES := [["♪", Color("#7dffb0")], ["♥", Color("#ff8fb8")], ["…", Color.WHITE], ["zZ", Color("#9fd0ff")], ["!", Color("#ffd479")], ["?", Color("#c9b6ff")]]

## Small speech-bubble emote above an idle hero.
func _emote(uv: Control) -> void:
	var e: Array = EMOTES[randi() % EMOTES.size()]
	var p := UI.styled_panel(Color(1, 1, 1, 0.92), e[1], 14, 2, 4)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(e[0], 20, e[1].darkened(0.3) if e[0] != "…" else Color("#444"), 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.custom_minimum_size = Vector2(44, 34)
	p.position = Vector2(uv.size.x * 0.62, uv.size.y * 0.05)
	p.z_index = 40
	uv.add_child(p)
	p.pivot_offset = Vector2(22, 34)
	p.scale = Vector2(0.2, 0.2)
	var tw := p.create_tween()
	tw.tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(p, "position:y", p.position.y - 6, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(1.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)

func _hearts(uv: Control) -> void:
	for i in 6:
		var h := UI.tex_rect(DB.icon("icon_heart"), Vector2(26, 26))
		h.size = Vector2(26, 26)
		var base := uv.get_global_rect().position - get_global_rect().position + Vector2(uv.size.x * 0.5, uv.size.y * 0.3)
		h.position = base + Vector2(randf_range(-50, 50), randf_range(-10, 20))
		h.z_index = 60
		add_child(h)
		var tw := h.create_tween().set_parallel(true)
		tw.tween_property(h, "position:y", h.position.y - randf_range(70, 130), 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(h, "modulate:a", 0.0, 0.9).set_delay(0.3)
		tw.chain().tween_callback(h.queue_free)

func _float(uv: Control, text: String, col: Color) -> void:
	var l := UI.label(text, 16, col, 5)
	l.size = Vector2(240, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = uv.get_global_rect().position - get_global_rect().position + Vector2(uv.size.x * 0.5 - 120, uv.size.y * 0.1)
	l.z_index = 60
	add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)

func _pick_residents() -> void:
	var v: VBoxContainer = main.popup("GARDEN RESIDENTS (max %d)" % DB.GARDEN_SLOTS, 780)
	var sel: Array = Game.s["garden"].duplicate()
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 380)
	v.add_child(sc)
	var ids: Array = Game.s["heroes"].keys()
	for id in ids:
		var hid: String = id
		var card := HeroCard.new(hid, Vector2(108, 136), {"skin": true})
		card.set_selected(sel.has(hid))
		card.pressed.connect(func():
			if sel.has(hid):
				sel.erase(hid)
			elif sel.size() < DB.GARDEN_SLOTS:
				sel.append(hid)
			else:
				main.toast("Max %d residents." % DB.GARDEN_SLOTS, UI.RED)
			card.set_selected(sel.has(hid)))
		g.add_child(card)
	var ok := UI.button("CONFIRM", func():
		Game.set_garden(sel)
		main.close_popup(v)
		_spawn(), "GoldButton", Vector2(200, 48))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
