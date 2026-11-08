extends Screen
## Heart Catch mini-game: move your hero to catch falling hearts.
## Pink +1, gold +5, bombs stun and cost 3. Rewards Bond EXP + Gold (3x/day).

var hero_id := ""
var _field: Control
var _player: UnitView
var _items: Array = []   # {node, kind, vy}
var _score := 0
var _combo := 0
var _time := 0.0
var _spawn_t := 0.0
var _stun := 0.0
var _running := false
var _target_x := 0.0
var _score_l: Label
var _time_l: Label
var _combo_l: Label
var _intro: Control

func build() -> void:
	hero_id = str(params.get("id", Game.s["garden"][0] if not Game.s["garden"].is_empty() else Game.s["lobby_hero"]))
	set_bg("forest", 0.3)
	ambient(Color(1.0, 0.8, 0.9), 20)
	header("HEART CATCH", ["gold"])
	_field = Control.new()
	_field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_field.offset_top = 76
	_field.mouse_filter = Control.MOUSE_FILTER_STOP
	_field.clip_contents = true
	add_child(_field)
	_field.gui_input.connect(_input_field)
	var hud := UI.hbox(30)
	hud.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hud.offset_top = 82
	hud.offset_left = -300
	hud.offset_right = 300
	hud.alignment = BoxContainer.ALIGNMENT_CENTER
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	_score_l = UI.label("", 30, UI.GOLD, 6)
	hud.add_child(_score_l)
	_time_l = UI.label("", 30, Color.WHITE, 6)
	hud.add_child(_time_l)
	_combo_l = UI.label("", 22, Color("#ff8fb8"), 5)
	_combo_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_combo_l.offset_top = 124
	_combo_l.offset_left = -200
	_combo_l.offset_right = 200
	_combo_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_combo_l)
	_show_intro()

## Score milestones shown on the start screen (mirrors Game.finish_minigame).
const MILESTONES := [
	[1, "gold", "Gold  = score x150"],
	[40, "bouquet", "Flower Bouquet"],
	[70, "gems", "30 Gems"],
]
const PINK := Color("#ff8fb8")

## Start screen: the hero on the left, rules / rewards / hero picker card on the right.
func _show_intro() -> void:
	if is_instance_valid(_intro):
		_intro.queue_free()
	_intro = Control.new()
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.offset_top = 76
	add_child(_intro)
	var col: Color = DB.ELEMENT_COLOR.get(DB.element_of(hero_id), PINK)
	# --- left: the hero, with a soft pink glow and floating hearts
	var stage := Control.new()
	stage.anchor_right = 0.44
	stage.anchor_bottom = 1.0
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_child(stage)
	var glow := TextureRect.new()
	glow.texture = _glow(PINK, 0.42)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(glow)
	var gtw := glow.create_tween().set_loops()
	gtw.tween_property(glow, "modulate:a", 0.6, 1.8).set_trans(Tween.TRANS_SINE)
	gtw.tween_property(glow, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_SINE)
	var hearts := CPUParticles2D.new()
	hearts.amount = 14
	hearts.lifetime = 4.0
	hearts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	hearts.emission_rect_extents = Vector2(220, 10)
	hearts.position = Vector2(270, 640)
	hearts.direction = Vector2(0, -1)
	hearts.spread = 12
	hearts.gravity = Vector2.ZERO
	hearts.initial_velocity_min = 40
	hearts.initial_velocity_max = 80
	hearts.scale_amount_min = 3
	hearts.scale_amount_max = 6
	hearts.color = Color(PINK, 0.55)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.2, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	hearts.color_ramp = ramp
	stage.add_child(hearts)
	var art := UI.tex_rect(DB.art(hero_id, int(Game.hero(hero_id).get("skin", 0))))
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_top = 6
	art.offset_bottom = -64
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(art)
	UI.live(art)
	# name plate under the hero
	var plate := UI.styled_panel(Color(0.07, 0.04, 0.12, 0.85), Color(col, 0.7), 14, 1, 8)
	plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plate.offset_bottom = -14
	stage.add_child(plate)
	var pr := UI.hbox(10)
	plate.add_child(pr)
	pr.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(hero_id), "elem_light")), Vector2(28, 28)))
	pr.add_child(UI.label(DB.name_of(hero_id), 20, Color.WHITE, 4))
	var h := Game.hero(hero_id)
	pr.add_child(UI.label("♥ Bond %d" % int(h.get("bond", 0)), 15, PINK, 3))
	# --- right: the card
	var card := UI.styled_panel(Color(0.06, 0.03, 0.11, 0.9), Color(PINK, 0.55), 18, 2, 18)
	card.anchor_left = 0.45
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = 0
	card.offset_right = -18
	card.offset_top = 10
	card.offset_bottom = -12
	_intro.add_child(card)
	var v := UI.vbox(10)
	card.add_child(v)
	var tr := UI.hbox(10)
	v.add_child(tr)
	var tl := UI.vbox(0)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr.add_child(tl)
	tl.add_child(UI.label("HEART CATCH", 28, UI.GOLD, 5))
	tl.add_child(UI.label("%d seconds  •  catch hearts with %s" % [DB.MINIGAME_SECONDS, DB.name_of(hero_id)], 13, UI.MUTED, 2))
	# plays left as heart pips
	var pips := UI.vbox(2)
	tr.add_child(pips)
	var pl := UI.label("REWARD PLAYS", 11, UI.MUTED, 2)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pips.add_child(pl)
	var pr2 := UI.hbox(4)
	pr2.alignment = BoxContainer.ALIGNMENT_END
	pips.add_child(pr2)
	var left := Game.minigame_plays_left()
	for i in DB.MINIGAME_REWARD_PLAYS:
		pr2.add_child(UI.label("♥", 26, PINK if i < left else Color(1, 1, 1, 0.18), 3))
	# how to play: three item tiles
	var how := UI.hbox(8)
	v.add_child(how)
	for it in [["♥", "HEART", "+1", Color("#ff6fa8")], ["★", "GOLD STAR", "+5", UI.GOLD], ["✘", "BOMB", "-3 & stun", Color("#ff4d63")]]:
		var t := UI.styled_panel(Color(it[3], 0.1), Color(it[3], 0.5), 12, 1, 6)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		how.add_child(t)
		var tv := UI.vbox(0)
		t.add_child(tv)
		var sym := UI.label(it[0], 34, it[3] if it[1] != "BOMB" else Color("#3a2a4a"), 6)
		if it[1] == "BOMB":
			sym.add_theme_color_override("font_outline_color", Color("#ff4d63"))
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(sym)
		var n := UI.label(it[1], 12, Color.WHITE, 2)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(n)
		var p := UI.label(it[2], 15, it[3].lightened(0.25), 3)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(p)
	v.add_child(UI.wrap_label("Drag, tap or use the arrow keys to move.  Every 5 catches in a row adds +1 to each catch (COMBO).", 13, UI.TEXT))
	# reward track with the best score marker
	var best := int(Game.s["minigame"]["best"])
	var rh := UI.hbox(8)
	v.add_child(rh)
	var rt := UI.label("REWARDS", 14, UI.GOLD, 3)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rh.add_child(rt)
	rh.add_child(UI.label("Best  %d" % best, 14, PINK, 3))
	var track := UI.hbox(6)
	v.add_child(track)
	for m in MILESTONES:
		var got := best >= int(m[0])
		var mc: Color = UI.GOLD if got else Color(1, 1, 1, 0.35)
		var mp := UI.styled_panel(Color(mc, 0.1), Color(mc, 0.6), 10, 1, 6)
		mp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.add_child(mp)
		var mh := UI.hbox(6)
		mp.add_child(mh)
		mh.add_child(UI.tex_rect(Game.reward_icon(str(m[1])), Vector2(30, 30)))
		var mv := UI.vbox(0)
		mh.add_child(mv)
		mv.add_child(UI.label(("SCORE %d+" % int(m[0])) if int(m[0]) > 1 else "ANY SCORE", 11, mc, 2))
		mv.add_child(UI.label(str(m[2]), 12, Color.WHITE if got else UI.TEXT, 2))
	v.add_child(UI.label("+ up to 60 Bond EXP with %s" % DB.name_of(hero_id), 13, PINK, 2))
	# hero picker strip
	v.add_child(UI.label("PLAY AS", 13, UI.MUTED, 2))
	var strip := UI.hbox(6)
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 64)
	sc.add_child(strip)
	v.add_child(sc)
	var ids: Array = Game.s["heroes"].keys()
	ids.sort_custom(func(a, b): return int(Game.hero(a).get("bond", 0)) > int(Game.hero(b).get("bond", 0)))
	for id in ids:
		var hid: String = id
		var on := hid == hero_id
		var fb := Button.new()
		fb.flat = true
		fb.focus_mode = Control.FOCUS_NONE
		fb.custom_minimum_size = Vector2(58, 58)
		fb.tooltip_text = DB.name_of(hid)
		var ring := Panel.new()
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.add_theme_stylebox_override("panel", UI.style(Color(0, 0, 0, 0.4), PINK if on else Color(1, 1, 1, 0.2), 29, 3 if on else 1, 0))
		fb.add_child(ring)
		var fc := UI.tex_rect(DB.face(hid), Vector2(50, 50), true)
		fc.position = Vector2(4, 4)
		fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fb.add_child(fc)
		fb.pressed.connect(func():
			if hid != hero_id:
				Game.sfx("ui_click")
				hero_id = hid
				_show_intro())
		strip.add_child(fb)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var go := UI.button("START!" if left > 0 else "PLAY FOR FUN", func(): _start(), "GoldButton", Vector2(0, 56))
	go.add_theme_font_size_override("font_size", 22)
	v.add_child(go)
	UI.hover_fx(go)
	if left <= 0:
		var nl := UI.label("No reward plays left today — scores still count for your Best.", 12, UI.MUTED, 2)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nl)
	# keep the selected face in view
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_horizontal = maxi(0, ids.find(hero_id) * 64 - 120)

func _glow(c: Color, a: float) -> GradientTexture2D:
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.55)
	gt.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(c, a))
	gr.set_color(1, Color(c, 0.0))
	gt.gradient = gr
	return gt

func _start() -> void:
	if is_instance_valid(_intro):
		_intro.queue_free()
	_score = 0
	_combo = 0
	_time = DB.MINIGAME_SECONDS
	_running = true
	if is_instance_valid(_player):
		_player.queue_free()
	var sz := Vector2(140, 140)
	_player = UnitView.new(hero_id, false, DB.sprite(hero_id, int(Game.hero(hero_id).get("star", 1)), int(Game.hero(hero_id).get("skin", 0))), sz, -1, false)
	_player.position = Vector2(_field.size.x * 0.5 - sz.x * 0.5, _field.size.y - sz.y - 10)
	_field.add_child(_player)
	_player.start_idle()
	_target_x = _player.position.x
	Game.sfx("battle/round")
	_update_hud()

func _input_field(e: InputEvent) -> void:
	if e is InputEventMouseMotion or (e is InputEventMouseButton and e.pressed) or e is InputEventScreenDrag or e is InputEventScreenTouch:
		_target_x = e.position.x - 70.0

func _unhandled_key_input(e: InputEvent) -> void:
	if not _running:
		return
	if e.is_action_pressed("ui_left"):
		_target_x -= 120.0
	elif e.is_action_pressed("ui_right"):
		_target_x += 120.0

func _process(delta: float) -> void:
	if not _running or not is_instance_valid(_player):
		return
	_time -= delta
	if _time <= 0.0:
		_end()
		return
	if Input.is_action_pressed("ui_left"):
		_target_x -= 500.0 * delta
	if Input.is_action_pressed("ui_right"):
		_target_x += 500.0 * delta
	_target_x = clampf(_target_x, 0.0, _field.size.x - _player.size.x)
	if _stun > 0.0:
		_stun -= delta
		_player.sprite.rotation = sin(_stun * 30.0) * 0.2
	else:
		_player.sprite.rotation = 0.0
		var dx := _target_x - _player.position.x
		_player.position.x += clampf(dx, -700.0 * delta, 700.0 * delta)
		_player.sprite.flip_h = dx < -2.0
	# spawn
	_spawn_t -= delta
	var rate := lerpf(0.55, 0.28, 1.0 - _time / DB.MINIGAME_SECONDS)
	if _spawn_t <= 0.0:
		_spawn_t = rate
		_spawn()
	# move + collide
	var catch_rect := Rect2(_player.position + Vector2(25, 40), Vector2(_player.size.x - 50, 70))
	for it in _items.duplicate():
		var n: Control = it["node"]
		it["vy"] += 260.0 * delta
		n.position.y += it["vy"] * delta
		n.rotation += delta * 2.0
		if catch_rect.has_point(n.position + n.size * 0.5) and _stun <= 0.0:
			_collect(it)
		elif n.position.y > _field.size.y:
			if it["kind"] != "bomb":
				_combo = 0
			_items.erase(it)
			n.queue_free()
	_update_hud()

func _spawn() -> void:
	var r := randf()
	var kind := "heart"
	if r < 0.12:
		kind = "gold"
	elif r < 0.3:
		kind = "bomb"
	var l := UI.label({"heart": "♥", "gold": "★", "bomb": "✘"}[kind], 44 if kind != "heart" else 40, {"heart": Color("#ff6fa8"), "gold": UI.GOLD, "bomb": Color("#3a2a4a")}[kind], 6)
	l.size = Vector2(50, 50)
	l.pivot_offset = Vector2(25, 25)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if kind == "bomb":
		l.add_theme_color_override("font_outline_color", Color("#ff4d63"))
	l.position = Vector2(randf_range(20, _field.size.x - 70), -50)
	_field.add_child(l)
	_items.append({"node": l, "kind": kind, "vy": randf_range(120, 220)})

func _collect(it: Dictionary) -> void:
	var n: Control = it["node"]
	_items.erase(it)
	var pos: Vector2 = n.position
	n.queue_free()
	var pts := 0
	match it["kind"]:
		"heart":
			_combo += 1
			pts = 1 + _combo / 5
			Game.sfx("ui_click")
		"gold":
			_combo += 1
			pts = 5 + _combo / 5
			Game.sfx("star_up")
		"bomb":
			_combo = 0
			pts = -3
			_stun = 1.0
			Game.sfx("battle/hit")
			_player.flash(Color(2, 0.5, 0.5))
	_score = maxi(0, _score + pts)
	var f := UI.label(("+%d" % pts) if pts > 0 else str(pts), 24, UI.GOLD if pts > 0 else UI.RED, 5)
	f.position = pos
	_field.add_child(f)
	var tw := f.create_tween().set_parallel(true)
	tw.tween_property(f, "position:y", pos.y - 60, 0.6)
	tw.tween_property(f, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(f.queue_free)
	if pts > 0:
		var j := _player.sprite.create_tween()
		j.tween_property(_player.sprite, "position:y", -14.0, 0.08)
		j.tween_property(_player.sprite, "position:y", 0.0, 0.12)

func _update_hud() -> void:
	_score_l.text = "♥ %d" % _score
	_time_l.text = "TIME %d" % int(ceil(maxf(_time, 0.0)))
	_combo_l.text = "COMBO x%d!" % _combo if _combo >= 3 else ""

func _end() -> void:
	_running = false
	for it in _items:
		it["node"].queue_free()
	_items.clear()
	Game.sfx("victory")
	var prev_best := int(Game.s["minigame"]["best"])
	var r := Game.finish_minigame(hero_id, _score)
	var v: VBoxContainer = main.popup("TIME UP!", 560, false)
	var sl := UI.label("♥ %d" % _score, 48, UI.GOLD, 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sl)
	if _score > prev_best:
		var nb := UI.styled_panel(Color(PINK, 0.2), PINK, 12, 1, 4)
		nb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		nb.add_child(UI.label("  NEW BEST!  ", 16, Color.WHITE, 3))
		v.add_child(nb)
		var bt := nb.create_tween().set_loops()
		bt.tween_property(nb, "modulate:a", 0.55, 0.6)
		bt.tween_property(nb, "modulate:a", 1.0, 0.6)
	var nxt := ""
	for m in MILESTONES:
		if _score < int(m[0]):
			nxt = "%d more for %s" % [int(m[0]) - _score, str(m[2])]
			break
	if nxt != "":
		var nl := UI.label(nxt, 13, UI.MUTED, 2)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nl)
	var line := UI.wrap_label("\"%s\"" % Game.voice(hero_id, "win"), 16, Color("#ffe6a3"))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(line)
	if r.is_empty():
		v.add_child(UI.label("No reward plays left today (best: %d)." % int(Game.s["minigame"]["best"]), 14, UI.MUTED))
	else:
		v.add_child(UI.label("+%d Bond EXP with %s" % [mini(60, _score), DB.name_of(hero_id)], 15, Color("#ff8fb8")))
		var rr := UI.reward_row(r, 36, 16)
		rr.alignment = FlowContainer.ALIGNMENT_CENTER
		v.add_child(rr)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("PLAY AGAIN", func(): main.close_popup(v); _start(), "GoldButton", Vector2(170, 50)))
	row.add_child(UI.button("MENU", func(): main.close_popup(v); _score_l.text = ""; _time_l.text = ""; _combo_l.text = ""; _player.queue_free(); _show_intro(), "", Vector2(140, 50)))
