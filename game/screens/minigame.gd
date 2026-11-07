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

func _show_intro() -> void:
	var v: VBoxContainer = main.popup("HEART CATCH", 600, false)
	v.get_meta("layer").set_meta("no_back", false)
	v.add_child(UI.tex_rect(DB.sprite(hero_id, int(Game.hero(hero_id).get("star", 1))), Vector2(0, 150)))
	v.add_child(UI.wrap_label("Move %s left and right (drag, tap or arrow keys) to catch falling hearts!\n♥ Pink +1   ★ Gold +5   ✘ Bomb: stunned & -3\nCatch in a row for a COMBO bonus." % DB.name_of(hero_id), 15, UI.TEXT))
	v.add_child(UI.label("Reward plays left today: %d / %d   •   Best: %d" % [Game.minigame_plays_left(), DB.MINIGAME_REWARD_PLAYS, int(Game.s["minigame"]["best"])], 14, UI.GOLD))
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("CHANGE HERO", func(): main.close_popup(v); _pick_hero(), "", Vector2(170, 50)))
	row.add_child(UI.button("START!", func(): main.close_popup(v); _start(), "GoldButton", Vector2(170, 50)))

func _pick_hero() -> void:
	var v: VBoxContainer = main.popup("CHOOSE A HERO", 760)
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 340)
	v.add_child(sc)
	for id in Game.s["heroes"].keys():
		var hid: String = id
		var c := HeroCard.new(hid, Vector2(108, 136), {"skin": true})
		c.pressed.connect(func():
			main.close_popup(v)
			main.replace("minigame", {"id": hid}))
		g.add_child(c)

func _start() -> void:
	_score = 0
	_combo = 0
	_time = DB.MINIGAME_SECONDS
	_running = true
	if is_instance_valid(_player):
		_player.queue_free()
	var sz := Vector2(140, 140)
	_player = UnitView.new(hero_id, false, DB.sprite(hero_id, int(Game.hero(hero_id).get("star", 1))), sz, -1, false)
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
	var r := Game.finish_minigame(hero_id, _score)
	var v: VBoxContainer = main.popup("TIME UP!", 560, false)
	var sl := UI.label("Score: %d" % _score, 40, UI.GOLD, 6)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sl)
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
	row.add_child(UI.button("EXIT", func(): main.close_popup(v); main.back(), "", Vector2(140, 50)))
