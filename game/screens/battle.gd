extends Screen
## Animated playback of a BattleSim result.

var sim: BattleSim
var summary: Dictionary
var _ally_board: GridBoard
var _enemy_board: GridBoard
var _views: Dictionary = {}       # uid -> UnitView
var _home: Dictionary = {}        # uid -> Vector2 position
var _round_label: Label
var _banner: PanelContainer
var _banner_label: Label
var _speed_btn: Button
var _order_strip: HBoxContainer
var _fx_layer: Control
var _speed := 1.0
var _skip := false
var _done := false
var _damage: Dictionary = {}      # uid -> damage dealt
var _taken: Dictionary = {}       # uid -> damage taken
var _healed: Dictionary = {}      # uid -> healing done
var _fx: SkillFX
var _pause_btn: Button
var _paused := false
var _pending_enrage: Array = []
var _enter_list: Array = []
var _banner_face: TextureRect
var _banner_elem: TextureRect
var _banner_who: Label
var _stack: Dictionary = {}       # uid -> floating-text stack index (prevents overlap)
var _ult_seen: Dictionary = {}
var _cameo: CompanionCameo    # hero id -> true once their ultimate cinematic played this battle

## Battlefield atmosphere per background: [particle kind, colour]
## Scene light per battle map: [light colour, ambient multiplier].
const LIGHT := {"hell": ["#ff9a4a", "#fff0e6"], "dragonfire": ["#ff8a3a", "#fff0e0"], "apocalypse": ["#ff7a4a", "#ffe8e0"], "abaddon": ["#ff9a5a", "#fff0e6"],
	"ice": ["#bfe8ff", "#eef6ff"], "aqua": ["#8fe9ff", "#e8f8ff"], "pool": ["#bff4ff", "#ffffff"], "galaxy": ["#d0b0ff", "#f0eaff"], "space": ["#b0c8ff", "#eef0ff"],
	"blackhole": ["#ffb070", "#f0e8ff"], "alien": ["#a0ffb0", "#eefff0"], "asgard": ["#ffe9a0", "#fffaf0"], "forest": ["#d8ffa0", "#f6fff0"], "bigtree": ["#e8ffb0", "#f8fff0"],
	"necro": ["#b0ffd8", "#e8f0f0"], "boss": ["#ff80c0", "#f8e8f8"], "outland": ["#ffd890", "#fff6ea"], "dino": ["#ffe0a0", "#fff8ee"]}
const ATMO := {"ice": ["snow", "#ffffff"], "hell": ["lantern", "#ff7a3d"], "boss": ["lantern", "#c050ff"], "forest": ["leaf", "#9be36b"],
	"aqua": ["firefly", "#8fe9ff"], "galaxy": ["firefly", "#c9a0ff"], "asgard": ["firefly", "#ffe9a0"], "battle": ["leaf", "#a08060"],
	"world": ["petal", "#ffd1e8"], "lobby": ["firefly", "#d4b8ff"]}

## Units dash in from their side of the screen at battle start.
var _foes: Array = []

func _entrance() -> void:
	if _skip:
		return
	_bsfx("dash")
	var k := 0
	for v in _enter_list:
		if not is_instance_valid(v):
			continue
		var home: Vector2 = v.position
		var dx: float = -700.0 if not v.enemy else 700.0
		v.position = home + Vector2(dx, 0)
		v.modulate.a = 0.0
		var tw: Tween = v.create_tween()
		tw.tween_interval(k * 0.05)
		tw.tween_property(v, "modulate:a", 1.0, 0.1)
		tw.parallel().tween_property(v, "position", home, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(v.sprite, "scale", Vector2(1.12, 0.88), 0.06)
		tw.tween_property(v.sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
		k += 1
	_enter_list.clear()
var _pause_layer: Control
var _started := false
var _retreat := false
var _chapter_clear := 0

func build() -> void:
	set_bg(Game.battle_bg(params), 0.25)
	_living_bg.call_deferred()
	var boss_fight := false
	_foes = Game.enemies_for(params)
	for en in _foes:
		if en.get("boss", false):
			boss_fight = true
	Game.play_bgm("battle/bgm_boss" if boss_fight else "battle/bgm_battle")

	_speed = float(Game.s["settings"].get("speed", 1))
	var allies: Array = Game.ally_team(params)
	sim = BattleSim.new()
	sim.setup(allies, Game.enemies_for(params), 0, Game.battle_mod(params))
	sim.tactic = Game.equipped_tactic()
	sim.companion = Game.companion_assist()
	summary = sim.run()

	# top bar
	var top := UI.hbox(10)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 10
	top.offset_bottom = 58
	add_child(top)
	var title := UI.label(Game.battle_title(params), 20, UI.GOLD, 5)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	top.add_child(UI.spacer())
	_round_label = UI.label("ROUND 1 / %d" % DB.MAX_ROUNDS, 20, Color.WHITE, 5)
	_round_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_round_label)
	top.add_child(UI.spacer())
	_speed_btn = UI.button("▶ x%d" % int(_speed), _cycle_speed, "", Vector2(90, 46))
	top.add_child(_speed_btn)
	_pause_btn = UI.button("❚❚", _toggle_pause, "", Vector2(56, 46))
	top.add_child(_pause_btn)
	top.add_child(UI.button("SKIP ▶▶", func(): _skip = true; _set_paused(false), "", Vector2(110, 46)))

	_order_strip = UI.hbox(4)
	_order_strip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_order_strip.offset_top = 64
	_order_strip.offset_left = -300
	_order_strip.offset_right = 300
	_order_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_order_strip)

	# atmosphere particles for the battlefield
	var bgk := Game.battle_bg(params)
	var atmo: Array = ATMO.get(bgk, ["firefly", "#d4b8ff"])
	var afx := FestivalFX.new(str(atmo[0]), Color(str(atmo[1])), 22)
	afx.modulate.a = 0.75
	add_child(afx)

	# boards
	_ally_board = GridBoard.new()
	_ally_board.tile_color = Color(0.45, 0.55, 1.0, 0.16)
	_ally_board.max_aspect = 0.6
	_ally_board.anchor_left = 0.045
	_ally_board.anchor_right = 0.485
	_ally_board.anchor_top = 0.27
	_ally_board.anchor_bottom = 0.93
	add_child(_ally_board)
	_enemy_board = GridBoard.new()
	_enemy_board.enemy_side = true
	_enemy_board.tile_color = Color(1.0, 0.4, 0.45, 0.14)
	_enemy_board.line_color = Color(1.0, 0.6, 0.65, 0.45)
	_enemy_board.max_aspect = 0.6
	_enemy_board.anchor_left = 0.515
	_enemy_board.anchor_right = 0.955
	_enemy_board.anchor_top = 0.27
	_enemy_board.anchor_bottom = 0.93
	add_child(_enemy_board)

	# the tamed Companion watches from the corner of the ally side
	if Game.companion() != "":
		_cameo = CompanionCameo.new(Game.companion())
		_cameo.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_cameo.offset_left = 8
		_cameo.offset_right = 118
		_cameo.offset_top = -150
		_cameo.offset_bottom = -6
		add_child(_cameo)
	_fx_layer = Control.new()
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx_layer)
	_fx = SkillFX.new()
	_fx_layer.add_child(_fx)

	_banner = UI.styled_panel(Color(0.05, 0.02, 0.1, 0.92), UI.GOLD, 30, 2, 0)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 108
	_banner.offset_left = -300
	_banner.offset_right = 300
	_banner.offset_bottom = 164
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bh := UI.hbox(12)
	_banner.add_child(UI.margin(bh, 6, 4, 22, 4))
	_banner_face = UI.tex_rect(null, Vector2(48, 48), true)
	bh.add_child(_banner_face)
	_banner_elem = UI.tex_rect(null, Vector2(26, 26))
	_banner_elem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bh.add_child(_banner_elem)
	var bv := UI.vbox(0)
	bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bh.add_child(bv)
	_banner_who = UI.label("", 13, UI.MUTED, 3)
	bv.add_child(_banner_who)
	_banner_label = UI.label("", 22, Color.WHITE, 4)
	bv.add_child(_banner_label)
	_banner.modulate.a = 0.0
	add_child(_banner)

	resized.connect(_place_units)
	_place_units.call_deferred()
	_play.call_deferred()

func skip() -> void:
	_skip = true

func on_back() -> bool:
	if _done:
		return false
	main.confirm("Retreat from battle? This counts as a defeat.", func(): _retreat = true; _skip = true)
	return true

func _cycle_speed() -> void:
	_speed = 1.0 if _speed >= 3.0 else _speed + 1.0
	_speed_btn.text = "▶ x%d" % int(_speed)
	Game.s["settings"]["speed"] = int(_speed)
	Game.mark_dirty()

func _place_units() -> void:
	for u in sim.units:
		var board: GridBoard = _enemy_board if u["side"] == 1 else _ally_board
		var th := board.tile_h()
		var big: bool = u["boss"]
		var sz := Vector2(th * (2.1 if big else 1.55), th * (2.1 if big else 1.55))
		var uid: int = u["uid"]
		var v: UnitView = _views.get(uid)
		if v == null:
			var tex := DB.boss_sprite(u["id"]) if big else DB.sprite(u["id"], int(u["star"]), int(Game.hero(u["id"]).get("skin", -1)) if u["side"] == 0 else -1)
			v = UnitView.new(u["id"], u["side"] == 1, tex, sz, u["order"], true, big)
			board.add_child(v)
			if not u.get("elite", false):
				v.sprite.material = _unit_light()
			v.start_idle()
			_enter_list.append(v)
			v.set_hp(u["max_hp"], u["max_hp"])
			v.snap_hp(u["max_hp"])
			_views[uid] = v
			if u.get("elite", false) and u["side"] == 1:
				UI.corrupt(v.sprite, str(u.get("variant", "")))
				var hollow: bool = str(u.get("variant", "")) == "hollow"
				var el := UI.label(str(u["variant"]).to_upper() if u.get("mirror", false) else ("ELITE" if not u["boss"] else "CORRUPTED"), 11, Color("#7ff6ff") if hollow else Color("#d48cff"), 4)
				el.position = Vector2(0, v.size.y * 0.05)
				el.size = Vector2(v.size.x, 16)
				el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				v.add_child(el)
			if int(u.get("awaken", 0)) > 0:
				var al := UI.label("A%d" % u["awaken"], 14, Color("#ffcf4a"), 4)
				al.position = Vector2(v.size.x - 30, v.size.y * 0.62)
				v.add_child(al)
			if int(u.get("awaken", 0)) >= 5:
				var gl := v.sprite.create_tween().set_loops()
				gl.tween_property(v.sprite, "self_modulate", Color(1.25, 1.15, 0.85), 0.9).set_trans(Tween.TRANS_SINE)
				gl.tween_property(v.sprite, "self_modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
		v.position = board.cell_foot(u["cell"]) - Vector2(sz.x * 0.5, sz.y)
		_home[uid] = v.position
	# z-order: rows further back drawn first
	for board in [_ally_board, _enemy_board]:
		var kids: Array = []
		for c in board.get_children():
			if c is UnitView:
				kids.append(c)
		kids.sort_custom(func(a, b): return a.position.y + a.size.y < b.position.y + b.size.y)
		for c in kids:
			board.move_child(c, -1)
	_update_order_strip(-1)

func _update_order_strip(active_uid: int) -> void:
	for c in _order_strip.get_children():
		c.queue_free()
	var a := sim.side_units(0, false)
	var e := sim.side_units(1, false)
	for i in maxi(a.size(), e.size()):
		for lst in [a, e]:
			if i < lst.size():
				var u: Dictionary = lst[i]
				var v: UnitView = _views.get(u["uid"])
				var alive := v != null and v.modulate.a > 0.5
				var col: Color = UI.GOLD if u["side"] == 0 else Color("#ff5c6c")
				var p := UI.styled_panel(Color.BLACK, col if u["uid"] == active_uid else col.darkened(0.5), 6, 3 if u["uid"] == active_uid else 1, 1)
				p.custom_minimum_size = Vector2(38, 38)
				var t := UI.tex_rect(DB.face(u["id"]), Vector2(34, 34), true)
				if not alive:
					t.modulate = Color(0.25, 0.25, 0.25)
				p.add_child(t)
				_order_strip.add_child(p)

# ---------------------------------------------------------------- playback

func _wait(t: float) -> void:
	if _skip:
		return
	await get_tree().create_timer(t / _speed, false).timeout

func _play() -> void:
	if _started:
		return
	_started = true
	_entrance()
	await _wait(0.9)
	await _intro_banners()
	var i := 0
	var ev: Array = sim.events
	while i < ev.size():
		if not is_inside_tree():
			return
		var e: Dictionary = ev[i]
		match e["t"]:
			"round":
				_round_label.text = "ROUND %d / %d" % [e["n"], DB.MAX_ROUNDS]
				if not _skip:
					_big_text("ROUND %d" % e["n"], Color.WHITE)
					_bsfx("round")
				await _wait(0.7)
			"act":
				var group: Array = []
				var j := i + 1
				while j < ev.size() and ev[j]["t"] in ["hit", "heal", "status", "status_end", "enrage", "revive", "cleanse"]:
					group.append(ev[j])
					j += 1
				await _play_action(e, group)
				i = j - 1
			"tactic":
				await _play_tactic(e)
			"companion":
				await _play_companion(e)
			"stunned":
				_float_text(e["uid"], "STUNNED", Color("#c9b6ff"), 20)
				_status_off(e["uid"], "STUN")
				_update_order_strip(e["uid"])
				await _wait(0.5)
			"dot":
				_apply_hit(e, Color("#c77dff"), false)
				if not _skip:
					var dv: UnitView = _views.get(e["uid"])
					if dv:
						_fx.impact("FIRE", _unit_center(dv), Color("#ff7a3d"), dv.size.x * 0.35)
				await _wait(0.3)
			"status_end":
				_status_off(e["uid"], e["kind"])
			"status":
				# standalone status (e.g. the Bastion set's opening shield)
				var sv0: UnitView = _views.get(e["uid"])
				if sv0:
					sv0.add_status(str(e["kind"]))
					_float_text(e["uid"], str(e["kind"]), Color("#9fe3ff"), 15, Vector2(0, sv0.size.y * 0.62))
			"enrage":
				await _enrage(e["uid"])
			"passive":
				var pv: UnitView = _views.get(e["uid"])
				if pv and not _skip:
					_float_text(e["uid"], str(e["text"]), Color("#ffb86b") if e["kind"] == "RAGE" else UI.GREEN, 15, Vector2(0, -20))
					_fx.aura(_unit_center(pv) + Vector2(0, pv.size.y * 0.3), Color("#ff5c3d") if e["kind"] == "RAGE" else Color("#7dffb0"), pv.size.x * 0.45)
				await _wait(0.15)
			"heal":
				var hv2: UnitView = _views.get(e["uid"])
				if hv2 and e.get("blocked", false):
					_float_text(e["uid"], "HEAL BLOCKED", Color("#ff6b7d"), 15)
				elif hv2:
					hv2.set_hp(e["hp"], sim.units[e["uid"]]["max_hp"])
					_float_text(e["uid"], "+%s" % Game.fmt(e["amt"]), UI.GREEN, 20)
					if not _skip:
						_fx.heal(_unit_center(hv2), hv2.size.x * 0.4)
				await _wait(0.2)
			"end":
				_finish(e)
		i += 1

const MELEE_ROLES := ["WARRIOR", "ASSASSIN", "KNIGHT", "PALADIN", "TANK"]
const ELEMENT_SFX := {"FIRE": "fire", "WATER": "water", "ICE": "ice", "WIND": "wind", "LIGHTNING": "thunder",
	"EARTH": "earth", "LIGHT": "light", "DARK": "dark", "CHAOS": "dark"}

var _voice_cd := 0

## Heroes cry out when hit hard or knocked out (rate-limited so it never spams).
func _react_voice(g: Dictionary) -> void:
	if _skip or _speed > 2.0:
		return
	var u: Dictionary = sim.units[g["uid"]]
	if u["side"] != 0 or not DB.HEROES.has(u["id"]):
		return
	var now := Time.get_ticks_msec()
	if now < _voice_cd:
		return
	if g.get("dead", false):
		Game.voice(u["id"], "ko")
		_voice_cd = now + 900
	elif g.get("crit", false) or randf() < 0.25:
		Game.voice(u["id"], "hurt")
		_voice_cd = now + 1400

func _bsfx(name: String) -> void:
	if not _skip:
		Game.sfx("battle/" + name)

## Position (in _fx_layer space) of a grid cell's unit centre.
func _cell_pos(side: int, cell: Vector2i) -> Vector2:
	var board: GridBoard = _enemy_board if side == 1 else _ally_board
	var foot := board.cell_foot(cell)
	return board.get_global_rect().position - _fx_layer.get_global_rect().position + foot - Vector2(0, board.tile_h() * 0.5)

func _play_action(e: Dictionary, group: Array) -> void:
	var uid: int = e["uid"]
	var u: Dictionary = sim.units[uid]
	var v: UnitView = _views.get(uid)
	_update_order_strip(uid)
	_show_arrow(uid)
	var sk: Dictionary = u["skill"]
	var shape := str(sk.get("shape", "single"))
	var aim := str(sk.get("aim", "front"))
	var elem: String = u["elem"]
	var ec: Color = DB.ELEMENT_COLOR.get(elem, Color.WHITE)
	var melee: bool = DB.role_of(u["id"]) in MELEE_ROLES and shape in ["single", "pierce", "square", "cross"] and aim != "ally_all"
	var dashed := false
	if not _skip and v:
		_fx.speed = _speed
		_banner_label.text = "%s%s" % [e["skill"], ("  Lv.%d" % int(u.get("skill_lv", 1))) if int(u.get("skill_lv", 1)) > 1 else ""]
		_banner_who.text = DB.name_of(u["id"]).to_upper()
		_banner_label.add_theme_color_override("font_color", UI.GOLD if u["side"] == 0 else Color("#ff8a9a"))
		_banner_face.texture = DB.face(u["id"])
		_banner_elem.texture = DB.icon(DB.ELEMENT_ICON.get(elem, "elem_light"))
		_banner.add_theme_stylebox_override("panel", UI.style(Color(ec.r * 0.18, ec.g * 0.12, ec.b * 0.2 + 0.04, 0.94), ec.lightened(0.2) if u["side"] == 0 else Color("#ff6b7d"), 30, 2, 0))
		_banner.pivot_offset = Vector2(300, 28)
		var bt := _banner.create_tween().set_parallel(true)
		_banner.scale = Vector2(0.85, 0.85)
		bt.tween_property(_banner, "modulate:a", 1.0, 0.1)
		bt.tween_property(_banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var board: GridBoard = _enemy_board if e["target_side"] == 1 else _ally_board
		var hl := {}
		var col := Color(1, 0.3, 0.3, 0.6) if e["target_side"] != u["side"] else Color(0.3, 1, 0.5, 0.55)
		for c in e["cells"]:
			hl[c] = col
		board.highlights = hl
		var me := _unit_center(v)
		_fx.aura(me + Vector2(0, v.size.y * 0.3), Color("#ffcf4a") if int(u.get("awaken", 0)) >= 5 else ec, v.size.x * (0.75 if int(u.get("awaken", 0)) >= 5 else 0.55))
		var ult: bool = u["side"] == 0 and not u["boss"] and DB.rarity_of(u["id"]) == "SSR" and not _ult_seen.has(u["id"])
		if not bool(Game.s["settings"].get("skip_cutin", false)) and (ult or u["boss"] or shape in ["all", "square", "x"]):
			var cd := _ultimate(u) if ult else (0.7 if _cut_in(u) else 0.0)
			if cd > 0.0:
				_punch(1.05)
				_bsfx("cast")
				await _wait(cd)
				if not is_inside_tree():
					return
		var dir := 1.0 if u["side"] == 0 else -1.0
		# anticipation: a quick crouch before every attack
		v.wind_up(0.1 / maxf(_speed, 1.0))
		await _wait(0.12)
		if not is_inside_tree():
			return
		if melee and e.has("target") and _views.has(e["target"]):
			# dash in front of the target, strike, come back later
			var tv: UnitView = _views[e["target"]]
			dashed = true
			v.z_index = 40
			_bsfx("dash")
			var dest := tv.global_position + Vector2(-tv.size.x * 0.55 * dir, tv.size.y * 0.05)
			var tw := v.create_tween()
			tw.tween_property(v, "global_position", dest, 0.22 / _speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await _wait(0.22)
			if not is_inside_tree():
				return
			var sw := v.sprite.create_tween()
			sw.tween_property(v.sprite, "rotation", 0.25 * dir, 0.06 / _speed)
			sw.tween_property(v.sprite, "rotation", -0.15 * dir, 0.08 / _speed)
			sw.tween_property(v.sprite, "rotation", 0.0, 0.1 / _speed)
			_bsfx("slash")
		else:
			# caster: rise + glow, then release
			_bsfx("cast" if aim != "ally_all" else "buff")
			var tw := v.create_tween()
			tw.tween_property(v, "position", _home[uid] + Vector2(16 * dir, -14), 0.18 / _speed).set_trans(Tween.TRANS_QUAD)
			tw.parallel().tween_property(v.sprite, "scale", Vector2(1.12, 1.12), 0.18 / _speed)
			v.flash(Color(1.6, 1.6, 1.6))
			await _wait(0.25)
			if not is_inside_tree():
				return
		_skill_fx(u, e, ec, melee)
		if u["side"] == 0 and _speed <= 2.0 and (u["boss"] or randf() < 0.6):
			Game.voice(u["id"], "skill")
		_bsfx(ELEMENT_SFX.get(elem, "hit") if aim != "ally_all" else "heal")
		await _wait(0.18 if melee else 0.3)
		if not is_inside_tree():
			return
		if shape in ["all", "square", "x"] or u["boss"]:
			_screen_flash(Color(ec.r, ec.g, ec.b, 0.22))
	var crit_any := false
	_stack.clear()
	var total_dmg := 0
	var hit_n := 0
	for g in group:
		match g["t"]:
			"hit":
				_apply_hit(g, Color.WHITE, true)
				_damage[g["src"]] = int(_damage.get(g["src"], 0)) + int(g["dmg"])
				_taken[g["uid"]] = int(_taken.get(g["uid"], 0)) + int(g["dmg"])
				crit_any = crit_any or bool(g.get("crit", false))
				total_dmg += int(g["dmg"])
				hit_n += 1
			"heal":
				_healed[uid] = int(_healed.get(uid, 0)) + int(g["amt"])
				var hv: UnitView = _views.get(g["uid"])
				if hv and g.get("blocked", false):
					_float_text(g["uid"], "HEAL BLOCKED", Color("#ff6b7d"), 15)
				elif hv:
					hv.set_hp(g["hp"], sim.units[g["uid"]]["max_hp"])
					_float_text(g["uid"], "+%s" % Game.fmt(g["amt"]), UI.GREEN, 22)
					hv.flash(Color(0.6, 2.0, 0.8))
					if not _skip:
						_fx.heal(_unit_center(hv), hv.size.x * 0.5)
			"status_end":
				_status_off(g["uid"], g["kind"])
			"revive":
				var rv: UnitView = _views.get(g["uid"])
				if rv:
					rv.revive_anim()
					rv.set_hp(g["hp"], sim.units[g["uid"]]["max_hp"])
					_float_text(g["uid"], "REVIVE!", UI.GOLD, 26)
					if not _skip:
						_fx.pillar(_unit_center(rv), Color("#ffe27a"), rv.size.x * 0.8)
						_bsfx("light")
			"cleanse":
				var cv: UnitView = _views.get(g["uid"])
				if cv:
					for k in ["BURN", "STUN", "DEF ▼", "SILENCE", "HEAL ▼"]:
						cv.remove_status(k)
					_float_text(g["uid"], "CLEANSE", Color("#9fe3ff"), 16, Vector2(0, -14))
			"enrage":
				_pending_enrage.append(g["uid"])
			"status":
				var stv: UnitView = _views.get(g["uid"])
				_float_text(g["uid"], g["kind"], Color("#ffd479"), 15, Vector2(0, stv.size.y * 0.62 if stv else 40))
				var sv: UnitView = _views.get(g["uid"])
				if sv:
					sv.add_status(str(g["kind"]))
				if str(g["kind"]) in ["ATK ▲", "SHIELD"]:
					_bsfx("buff")
				elif str(g["kind"]) in ["DEF ▼", "BURN", "STUN"]:
					_bsfx("debuff")
	if not _skip and group.size() > 0:
		_bsfx("crit" if crit_any else "hit")
		_shake(6.0 if crit_any else (4.0 if group.size() > 2 else 2.5))
		if crit_any:
			_punch(1.035)
			await _hitstop(0.09)
		if hit_n >= 2:
			_total_popup(total_dmg, hit_n, ec, u["side"] == 0)
	while not _pending_enrage.is_empty():
		await _enrage(_pending_enrage.pop_front())
	await _wait(0.45)
	if not is_inside_tree():
		return
	if v:
		var back := 0.15 / maxf(_speed, 1.0) * (2.0 if dashed else 1.0)
		var tw2 := v.create_tween()
		tw2.tween_property(v, "position", _home[uid], back).set_trans(Tween.TRANS_QUAD)
		tw2.parallel().tween_property(v.sprite, "scale", Vector2.ONE, back)
		tw2.tween_callback(func(): v.z_index = 0)
		if _skip:
			tw2.kill()
			v.position = _home[uid]
			v.sprite.scale = Vector2.ONE
			v.z_index = 0
	_ally_board.highlights = {}
	_enemy_board.highlights = {}
	_banner.create_tween().tween_property(_banner, "modulate:a", 0.0, 0.15)
	await _wait(0.12 + (0.15 if dashed else 0.0))

## Element + area-shape animation for a skill.
func _skill_fx(u: Dictionary, e: Dictionary, ec: Color, melee: bool) -> void:
	var sk: Dictionary = u["skill"]
	var shape := str(sk.get("shape", "single"))
	var elem: String = u["elem"]
	var side: int = e["target_side"]
	var board: GridBoard = _enemy_board if side == 1 else _ally_board
	var cell_size := board.tile_h() * 0.9
	if str(sk.get("aim", "")) == "ally_all":
		for c in e["cells"]:
			_fx.heal(_cell_pos(side, c), cell_size * 0.6)
		return
	var v: UnitView = _views.get(e["uid"])
	var me := _unit_center(v)
	var cells: Array = e["cells"]
	match shape:
		"line", "pierce":
			var row: int = cells[0].y
			var far := _cell_pos(side, Vector2i(2, row))
			if not melee:
				_fx.beam(me, far + (far - me).normalized() * 60.0, ec, 16.0)
			for i in cells.size():
				_fx.impact(elem, _cell_pos(side, cells[i]), ec, cell_size * 0.7, 0.08 * i)
		"column":
			for i in cells.size():
				_fx.pillar(_cell_pos(side, cells[i]), ec, cell_size * 0.7, 0.07 * i)
				_fx.impact(elem, _cell_pos(side, cells[i]), ec, cell_size * 0.6, 0.07 * i + 0.1)
		"all":
			var center := _cell_pos(side, Vector2i(1, 1))
			_fx.wave(center, ec, board.size.x * 0.9)
			if elem in ["WIND", "DARK", "CHAOS", "WATER"]:
				_fx.vortex(center, ec, board.size.x * 0.35)
			for i in cells.size():
				if elem in ["FIRE", "EARTH", "LIGHT", "LIGHTNING"]:
					_fx.meteor(_cell_pos(side, cells[i]), ec, cell_size * 0.55, randf_range(0.0, 0.3))
				_fx.impact(elem, _cell_pos(side, cells[i]), ec, cell_size * 0.6, randf_range(0.0, 0.25) + 0.3)
		"square":
			# a rain of meteors on the 2x2
			for i in cells.size():
				_fx.meteor(_cell_pos(side, cells[i]), ec, cell_size * 0.6, 0.09 * i)
				_fx.impact(elem, _cell_pos(side, cells[i]), ec, cell_size * 0.6, 0.09 * i + 0.36)
		"cross", "x":
			var c0 := _cell_pos(side, cells[0])
			_fx.slash(c0, ec, cell_size * 1.1, -0.7)
			_fx.slash(c0, ec, cell_size * 1.1, 0.7 + PI, 0.08)
			for i in cells.size():
				_fx.impact(elem, _cell_pos(side, cells[i]), ec, cell_size * (0.8 if i == 0 else 0.55), 0.1 + 0.05 * i)
				_fx.debris(_cell_pos(side, cells[i]), ec, cell_size * 0.4, 0.12 + 0.05 * i)
		_:
			if not melee and shape == "single":
				_vfx_projectile(v, e, ec)
			if melee and cells.size() > 0:
				# melee: a crescent slash across the target
				_fx.slash(_cell_pos(side, cells[0]), ec, cell_size * 0.95, -0.6 if u["side"] == 0 else PI + 0.6)
			for i in cells.size():
				var big := i == 0
				_fx.impact(elem, _cell_pos(side, cells[i]), ec, cell_size * (0.85 if big else 0.6), (0.18 if not melee and shape == "single" else 0.0) + 0.06 * i)
				if big:
					_fx.debris(_cell_pos(side, cells[i]), ec, cell_size * 0.45, (0.2 if not melee else 0.05))

func _apply_hit(g: Dictionary, color: Color, show_em: bool) -> void:
	var v: UnitView = _views.get(g["uid"])
	if v == null:
		return
	v.set_hp(g["hp"], sim.units[g["uid"]]["max_hp"])
	if _skip:
		v.snap_hp(g["hp"])
	else:
		v.flash()
		var crit: bool = g.get("crit", false)
		var src_elem: String = sim.units[g["src"]]["elem"] if g.has("src") else "DARK"
		_vfx_slash(v, DB.ELEMENT_COLOR.get(src_elem, Color.WHITE), crit)
		var txt := Game.fmt(g["dmg"])
		var c := color
		var sz := 24
		if crit:
			txt = txt + "!"
			c = Color("#ffcf4a")
			sz = 38
			_float_text(g["uid"], "CRITICAL", Color("#ff9f43"), 14, Vector2(0, -28))
		_float_text(g["uid"], txt, c, sz)
		if show_em and float(g.get("em", 1.0)) > 1.0:
			_float_text(g["uid"], "WEAK!", Color("#ff9f43"), 16, Vector2(0, 30))
		elif show_em and float(g.get("em", 1.0)) < 1.0:
			_float_text(g["uid"], "RESIST", Color("#8aa2c8"), 14, Vector2(0, 30))
		var sq := v.sprite.create_tween()
		sq.tween_property(v.sprite, "scale", Vector2(1.12, 0.86) if crit else Vector2(1.06, 0.93), 0.05)
		sq.tween_property(v.sprite, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)
		var kb := Vector2(-10 if sim.units[g["uid"]]["side"] == 0 else 10, 0)
		var tw := v.create_tween()
		tw.tween_property(v, "position", _home[g["uid"]] + kb, 0.06)
		tw.tween_property(v, "position", _home[g["uid"]], 0.12)
	_react_voice(g)
	if g.get("dead", false):
		var kcol: Color = DB.ELEMENT_COLOR.get(sim.units[g["src"]]["elem"], Color(1, 0.55, 0.2)) if g.has("src") else Color(1, 0.55, 0.2)
		v.die(kcol)
		if not _skip:
			_bsfx("death")
			_fx.death(_unit_center(v), v.size.x * 0.5)
			if sim.units[g["uid"]]["side"] == 1 and _enemies_left_after(g["uid"]) == 0:
				_finisher(v, kcol)

# ---------------------------------------------------------------- vfx

func _unit_center(v: UnitView) -> Vector2:
	return v.get_global_rect().position - _fx_layer.get_global_rect().position + v.size * Vector2(0.5, 0.55)

func _vfx_circle(v: UnitView, col: Color, scale_mul: float = 1.0) -> void:
	if _skip or v == null:
		return
	var t := UI.tex_rect(DB.tex("res://art/vfx/vfx_magic_circle.png"))
	var s := v.size.x * 1.1 * scale_mul
	t.size = Vector2(s, s * 0.45)
	t.pivot_offset = t.size * 0.5
	t.position = _unit_center(v) + Vector2(-s * 0.5, v.size.y * 0.33 - s * 0.225)
	t.modulate = Color(col.r * 1.4, col.g * 1.4, col.b * 1.4, 0.0)
	t.scale = Vector2(0.4, 0.4)
	_fx_layer.add_child(t)
	var tw := t.create_tween().set_parallel(true)
	tw.tween_property(t, "modulate:a", 0.95, 0.12 / _speed)
	tw.tween_property(t, "scale", Vector2(1.15, 1.15), 0.35 / _speed).set_trans(Tween.TRANS_BACK)
	tw.tween_property(t, "rotation", 1.2, 0.7 / _speed)
	tw.chain().tween_property(t, "modulate:a", 0.0, 0.3 / _speed)
	tw.chain().tween_callback(t.queue_free)

func _vfx_slash(v: UnitView, col: Color, crit: bool) -> void:
	if _skip or v == null:
		return
	var t := UI.tex_rect(DB.tex("res://art/vfx/vfx_slash_arc.png"))
	var s := v.size.x * (1.2 if crit else 0.9)
	t.size = Vector2(s, s)
	t.pivot_offset = t.size * 0.5
	t.position = _unit_center(v) - t.size * 0.5
	t.rotation = randf_range(-0.9, 0.9)
	t.modulate = Color(col.r * 1.6 + 0.3, col.g * 1.6 + 0.3, col.b * 1.6 + 0.3, 1.0)
	t.scale = Vector2(0.5, 0.5)
	_fx_layer.add_child(t)
	var tw := t.create_tween().set_parallel(true)
	tw.tween_property(t, "scale", Vector2(1.2, 1.2), 0.18 / _speed).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(t, "modulate:a", 0.0, 0.28 / _speed).set_delay(0.08 / _speed)
	tw.chain().tween_callback(t.queue_free)
	# sparks
	for i in (8 if crit else 5):
		var p := ColorRect.new()
		p.color = col.lightened(0.4)
		p.size = Vector2(5, 5)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.position = _unit_center(v)
		_fx_layer.add_child(p)
		var ang := randf() * TAU
		var dist := randf_range(30, 80) * (1.4 if crit else 1.0)
		var pt := p.create_tween().set_parallel(true)
		pt.tween_property(p, "position", p.position + Vector2(cos(ang), sin(ang)) * dist, 0.35 / _speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pt.tween_property(p, "modulate:a", 0.0, 0.35 / _speed)
		pt.chain().tween_callback(p.queue_free)

func _vfx_projectile(v: UnitView, e: Dictionary, col: Color) -> void:
	if _skip or v == null or not e.has("target"):
		return
	var tv: UnitView = _views.get(e["target"])
	if tv == null:
		return
	var orb := Panel.new()
	orb.add_theme_stylebox_override("panel", UI.style(col.lightened(0.3), Color(1, 1, 1, 0.8), 14, 2, 0))
	orb.size = Vector2(26, 26)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orb.position = _unit_center(v) - orb.size * 0.5
	_fx_layer.add_child(orb)
	var tw := orb.create_tween()
	tw.tween_property(orb, "position", _unit_center(tv) - orb.size * 0.5, 0.26 / _speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(orb.queue_free)

## Big portrait cut-in for boss / area skills (Brown Dust style).
## SSR Ultimate: once per hero per battle, a full-screen cinematic —
## element-tinted sky, racing speed lines, the full illustration sweeping in,
## the skill name slamming down, then a white flash into the attack.
func _ultimate(u: Dictionary) -> float:
	if _skip or _speed > 2.0 or Game.reduce_fx():
		return 0.7 if _cut_in(u) else 0.0
	_ult_seen[u["id"]] = true
	var hid: String = u["id"]
	var ec: Color = DB.ELEMENT_COLOR.get(str(u.get("element", DB.element_of(hid))), UI.GOLD)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 30
	_fx_layer.add_child(root)
	var sky := ColorRect.new()
	sky.color = Color(ec.darkened(0.82), 0.94)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(sky)
	# diagonal speed lines rushing right → left
	var lines := Control.new()
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lines)
	var seeds: Array = []
	for k in 46:
		seeds.append(Vector3(randf(), randf_range(0.6, 1.6), randf_range(80.0, 360.0)))
	var phase := [0.0]
	lines.draw.connect(func():
		var s := lines.size
		for sd in seeds:
			var y: float = sd.x * s.y * 1.3 - s.y * 0.15
			var x: float = fposmod(s.x * 1.2 - phase[0] * s.x * 2.2 * sd.y, s.x * 1.4) - s.x * 0.2
			var ln: float = sd.z
			var c := ec.lightened(0.55)
			c.a = 0.18 + 0.32 * sd.y / 1.6
			lines.draw_line(Vector2(x, y), Vector2(x + ln, y - ln * 0.18), c, 2.0 + sd.y * 2.0))
	var lt := lines.create_tween()
	lt.tween_method(func(p: float):
		phase[0] = p
		lines.queue_redraw(), 0.0, 1.0, 1.6)
	# a bright slanted band behind the hero
	var band := Polygon2D.new()
	var vs := get_viewport_rect().size
	band.polygon = PackedVector2Array([Vector2(-50, vs.y * 0.62), Vector2(vs.x + 50, vs.y * 0.3), Vector2(vs.x + 50, vs.y * 0.52), Vector2(-50, vs.y * 0.86)])
	band.color = Color(ec.lightened(0.3), 0.22)
	root.add_child(band)
	# the full illustration sweeps in from the left and drifts
	var art := UI.tex_rect(DB.art(hid, int(Game.hero(hid).get("skin", 0))) if Game.owns(hid) else DB.art(hid, 0))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_left = 0.02
	art.anchor_right = 0.5
	art.anchor_top = -0.04
	art.anchor_bottom = 1.08
	root.add_child(art)
	art.resized.connect(func(): art.pivot_offset = art.size * Vector2(0.5, 0.35))
	art.position.x -= 420
	art.scale = Vector2(1.18, 1.18)
	var at := art.create_tween().set_parallel(true)
	at.tween_property(art, "position:x", art.position.x + 420, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	at.tween_property(art, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# text block
	var tv := UI.vbox(2)
	tv.set_anchors_preset(Control.PRESET_FULL_RECT)
	tv.anchor_left = 0.5
	tv.anchor_right = 0.97
	tv.anchor_top = 0.3
	tv.anchor_bottom = 0.75
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(tv)
	tv.add_child(UI.label("✦ ULTIMATE ✦", 18, ec.lightened(0.5), 4))
	var nm := UI.label(str(u["skill"]["name"]).to_upper(), 54, UI.GOLD, 10)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(nm)
	tv.add_child(UI.label(DB.name_of(hid) + "  •  " + DB.title_of(hid), 18, Color.WHITE, 5))
	tv.modulate.a = 0.0
	(func():
		nm.pivot_offset = nm.size * Vector2(0.0, 0.5)
		nm.scale = Vector2(2.2, 2.2)
		var nt := tv.create_tween().set_parallel(true)
		nt.tween_property(tv, "modulate:a", 1.0, 0.12).set_delay(0.22)
		nt.tween_property(nm, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.22)).call_deferred()
	Game.voice(hid, "skill")
	_bsfx("light")
	# finish: white flash, then the attack resumes underneath
	var fl := ColorRect.new()
	fl.color = Color(1, 0.98, 0.9, 0.0)
	fl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(fl)
	var hold := 1.25 / _speed
	var ft := fl.create_tween()
	ft.tween_interval(hold)
	ft.tween_property(fl, "color:a", 0.9, 0.08)
	ft.tween_callback(root.queue_free)
	ft.tween_property(fl, "color:a", 0.0, 0.35)
	ft.tween_callback(fl.queue_free)
	return hold + 0.12

func _cut_in(u: Dictionary) -> bool:
	if _skip or _speed > 2.0:
		return false
	var band := Control.new()
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.anchor_top = 0.3
	band.anchor_bottom = 0.62
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.clip_contents = true
	_fx_layer.add_child(band)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.add_child(bg)
	var art := UI.tex_rect(DB.cutin(u["id"]), Vector2.ZERO, true)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_left = 0.0 if u["side"] == 0 else 0.55
	art.anchor_right = 0.45 if u["side"] == 0 else 1.0
	band.add_child(art)
	var l := UI.label(u["skill"]["name"].to_upper(), 40, UI.GOLD if u["side"] == 0 else Color("#ff8a9a"), 10)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.anchor_left = 0.45 if u["side"] == 0 else 0.05
	l.anchor_right = 0.95 if u["side"] == 0 else 0.55
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band.add_child(l)
	var streak := ColorRect.new()
	streak.color = Color(1, 1, 1, 0.5)
	streak.set_anchors_preset(Control.PRESET_TOP_WIDE)
	streak.offset_bottom = 3
	band.add_child(streak)
	var streak2 := streak.duplicate()
	streak2.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	streak2.offset_top = -3
	streak2.offset_bottom = 0
	band.add_child(streak2)
	var dx := -300.0 if u["side"] == 0 else 300.0
	art.position.x += dx
	band.modulate.a = 0.0
	var tw := band.create_tween()
	tw.tween_property(band, "modulate:a", 1.0, 0.1)
	tw.parallel().tween_property(art, "position:x", art.position.x - dx, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.45 / _speed)
	tw.tween_property(band, "modulate:a", 0.0, 0.2)
	tw.tween_callback(band.queue_free)
	return true

func _float_text(uid: int, text: String, color: Color, size: int, offset: Vector2 = Vector2.ZERO) -> void:
	if _skip:
		return
	var v: UnitView = _views.get(uid)
	if v == null:
		return
	# stack texts on the same unit so they never overlap
	var k: int = int(_stack.get(uid, 0))
	_stack[uid] = k + 1
	var l := UI.label(text, size + 4, color, 7)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(240, 48)
	var gp := v.get_global_rect().position - _fx_layer.get_global_rect().position
	l.position = gp + Vector2(v.size.x * 0.5 - 120, v.size.y * 0.18 - k * (size + 6)) + offset + Vector2(randf_range(-10, 10), 0)
	_fx_layer.add_child(l)
	l.pivot_offset = Vector2(120, 24)
	l.scale = Vector2(0.3, 0.3)
	var drift := randf_range(-18, 18)
	var tw := l.create_tween()
	# pop in, hop up in an arc, settle, fade
	tw.tween_property(l, "scale", Vector2(1.3, 1.3), 0.1 / _speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position", l.position + Vector2(drift * 0.5, -26), 0.12 / _speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, 0.1 / _speed)
	tw.parallel().tween_property(l, "position", l.position + Vector2(drift, -14), 0.16 / _speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.25 / _speed)
	tw.tween_property(l, "position:y", l.position.y - 46, 0.4 / _speed)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4 / _speed)
	tw.tween_callback(l.queue_free)

## Short freeze on big hits so they "land" (Brown Dust / fighting-game feel).
func _hitstop(t: float) -> void:
	if _skip or Game.reduce_fx():
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(t, true, false, true).timeout
	Engine.time_scale = 1.0

## Running total for multi-target skills.
func _total_popup(total: int, hits: int, col: Color, ally: bool) -> void:
	if _skip:
		return
	var p := UI.styled_panel(Color(0.04, 0.02, 0.08, 0.85), col.lightened(0.2), 18, 2, 10)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(8)
	p.add_child(h)
	h.add_child(UI.label("%d HITS" % hits, 16, col.lightened(0.45), 4))
	var n := UI.label("0", 30, UI.GOLD if ally else Color("#ff8a9a"), 6)
	h.add_child(n)
	_fx_layer.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	p.offset_top = 176
	p.offset_left = -130 if ally else -130
	p.offset_right = 130
	p.pivot_offset = Vector2(130, 24)
	p.scale = Vector2(0.6, 0.6)
	UI.count_to(n, 0, total, func(x): return Game.fmt(x), 0.35 / _speed)
	var tw := p.create_tween()
	tw.tween_property(p, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.8 / _speed)
	tw.tween_property(p, "modulate:a", 0.0, 0.3 / _speed)
	tw.tween_callback(p.queue_free)

func _big_text(text: String, color: Color) -> void:
	var l := UI.label(text, 64, color, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.offset_left = -400
	l.offset_right = 400
	l.offset_top = -60
	l.offset_bottom = 20
	_fx_layer.add_child(l)
	l.pivot_offset = Vector2(400, 40)
	l.modulate.a = 0.0
	l.scale = Vector2(1.6, 1.6)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.15 / _speed)
	tw.parallel().tween_property(l, "scale", Vector2.ONE, 0.2 / _speed).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.3 / _speed)
	tw.tween_property(l, "modulate:a", 0.0, 0.2 / _speed)
	tw.tween_callback(l.queue_free)

func _screen_flash(c: Color) -> void:
	if Game.reduce_fx():
		return
	var f := ColorRect.new()
	f.color = c
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.3 / _speed)
	tw.tween_callback(f.queue_free)

func _shake(amount: float) -> void:
	if Game.reduce_fx():
		return
	var tw := create_tween()
	for k in 4:
		tw.tween_property(self, "position", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.03)
	tw.tween_property(self, "position", Vector2.ZERO, 0.03)

# ---------------------------------------------------------------- result

# ---------------------------------------------------------------- new battle presentation

func _show_arrow(uid: int) -> void:
	for k in _views.keys():
		var v: UnitView = _views[k]
		v.arrow.visible = k == uid and not _skip

func _status_off(uid: int, kind: String) -> void:
	var v: UnitView = _views.get(uid)
	if v:
		v.remove_status(kind)
		if kind == "SHIELD" and not _skip:
			_float_text(uid, "SHIELD BREAK", Color("#9fd0ff"), 15, Vector2(0, 20))

## Camera punch-in: briefly scales the whole battle view.
var _light_mat: ShaderMaterial

func _unit_light() -> ShaderMaterial:
	if _light_mat == null:
		_light_mat = ShaderMaterial.new()
		_light_mat.shader = load("res://game/ui/unit_light.gdshader")
		var lc: Array = LIGHT.get(Game.battle_bg(params), ["#fff0d8", "#ffffff"])
		_light_mat.set_shader_parameter("light_col", Color(str(lc[0])))
		_light_mat.set_shader_parameter("ambient", Color(str(lc[1])))
		_light_mat.set_shader_parameter("rim", 0.3 if Game.reduce_fx() else 0.55)
	return _light_mat

## The battle backdrop slowly drifts and breathes (a camera that is never quite still).
func _living_bg() -> void:
	if get_child_count() == 0 or Game.reduce_fx():
		return
	var bgr := get_child(0) as TextureRect
	if bgr == null:
		return
	bgr.resized.connect(func(): bgr.pivot_offset = bgr.size * 0.5)
	bgr.pivot_offset = bgr.size * 0.5
	var tw := bgr.create_tween().set_loops()
	tw.tween_property(bgr, "scale", Vector2(1.07, 1.07), 9.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bgr, "position:x", -18.0, 9.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(bgr, "scale", Vector2(1.03, 1.03), 9.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bgr, "position:x", 14.0, 9.0).set_trans(Tween.TRANS_SINE)
	# light shafts on bright maps
	var bgk := Game.battle_bg(params)
	if bgk in ["asgard", "forest", "bigtree", "pool", "outland", "dino", "aqua", "world"] and ResourceLoader.exists("res://art/ui/rays.png"):
		var rays := TextureRect.new()
		rays.texture = load("res://art/ui/rays.png")
		rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rays.size = Vector2(1400, 1400)
		rays.pivot_offset = Vector2(700, 700)
		rays.position = Vector2(-700 + 120, -700 - 40)
		rays.modulate = Color(Color(str(LIGHT.get(bgk, ["#fff0d8"])[0])), 0.22)
		rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rm := CanvasItemMaterial.new()
		rm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rays.material = rm
		add_child(rays)
		move_child(rays, 1)
		var rt := rays.create_tween().set_loops()
		rt.tween_property(rays, "rotation", 0.12, 7.0).set_trans(Tween.TRANS_SINE)
		rt.tween_property(rays, "rotation", -0.05, 7.0).set_trans(Tween.TRANS_SINE)

func _punch(amount: float) -> void:
	if Game.reduce_fx():
		return
	if _skip:
		return
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(amount, amount), 0.06).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD)

func _enrage(uid: int) -> void:
	var v: UnitView = _views.get(uid)
	if v == null or _skip:
		if v:
			v.sprite.modulate = Color(1.4, 0.6, 0.6)
		return
	_bsfx("dark")
	_screen_flash(Color(1, 0, 0, 0.3))
	_shake(8.0)
	_punch(1.06)
	_big_text("BOSS ENRAGED!", Color("#ff4d63"))
	_float_text(uid, "ATK +30%", Color("#ff4d63"), 22, Vector2(0, -10))
	var tw := v.sprite.create_tween()
	tw.tween_property(v.sprite, "modulate", Color(1.6, 0.5, 0.5), 0.3)
	tw.tween_property(v.sprite, "scale", Vector2(1.15, 1.15), 0.15)
	tw.tween_property(v.sprite, "scale", Vector2.ONE, 0.2)
	_fx.aura(_unit_center(v) + Vector2(0, v.size.y * 0.3), Color("#ff3030"), v.size.x * 0.7)
	await _wait(1.0)

func _intro_banners() -> void:
	if _skip:
		return
	var lines: Array = []
	var syn: Dictionary = sim.synergies[0]
	if float(syn.get("bonus", 0.0)) > 0.0:
		lines.append(["SYNERGY: %s x%d  →  +%d%% ATK/HP" % [syn["element"], syn["count"], int(float(syn["bonus"]) * 100)], DB.ELEMENT_COLOR.get(syn["element"], UI.GOLD)])
	var esyn: Dictionary = sim.synergies[1]
	if float(esyn.get("bonus", 0.0)) > 0.0:
		lines.append(["ENEMY SYNERGY: %s x%d" % [esyn["element"], esyn["count"]], Color("#ff8a9a")])
	if not sim.modifier.is_empty():
		lines.append(["FIELD: " + str(sim.modifier.get("name", "")), Color("#9fd0ff")])
	if str(params.get("mode", "")) != "" and not Game.active_links().is_empty():
		lines.append(["LINKS: " + ", ".join(Game.active_links().map(func(l): return l["name"])), Color("#ffb8d6")])
	if Game.companion() != "":
		lines.append(["COMPANION: %s  →  +%.1f%% team ATK/HP" % [DB.name_of(Game.companion()), Game.companion_bonus() * 100.0], Color("#ffb8d6")])
		if is_instance_valid(_cameo):
			_cameo.cheer()
	if not sim.tactic.is_empty():
		var td := DB.tactic_def(str(sim.tactic["id"]))
		lines.append(["TACTIC: %s Lv.%d  •  %s" % [td["name"], int(sim.tactic["lv"]), td["trigger"]], UI.GOLD])
	var first_fight: bool = str(params.get("mode", "")) == "story" and Game.stages_cleared() == 0
	if first_fight:
		lines.append(["Your team fights on its own. Your Formation decides the battle!", UI.GOLD])
	if lines.is_empty():
		return
	var box := UI.vbox(4)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -360
	box.offset_right = 360
	box.offset_top = 124
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(box)
	for l in lines:
		var p := UI.styled_panel(Color(0.04, 0.02, 0.1, 0.82), l[1], 16, 1, 6)
		p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p.custom_minimum_size.x = 420
		var lab := UI.label(l[0], 14, l[1].lightened(0.2), 3)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(lab)
		box.add_child(p)
	UI.stagger(box, 0.08)
	_bsfx("buff")
	await _wait(2.8 if first_fight else 1.1)
	if is_instance_valid(box):
		var tw := box.create_tween()
		tw.tween_property(box, "modulate:a", 0.0, 0.25)
		tw.tween_callback(box.queue_free)

func _toggle_pause() -> void:
	_set_paused(not _paused)

func _set_paused(p: bool) -> void:
	if _done:
		return
	_paused = p
	get_tree().paused = p
	_pause_btn.text = "▶" if p else "❚❚"
	if p and not is_instance_valid(_pause_layer):
		_pause_layer = Control.new()
		_pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		_pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_pause_layer)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.55)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_pause_layer.add_child(dim)
		var v := UI.vbox(14)
		v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		v.offset_left = -160
		v.offset_right = 160
		v.offset_top = -110
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		_pause_layer.add_child(v)
		var t := UI.label("PAUSED", 48, Color.WHITE, 8)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		var rb := UI.button("RESUME", func(): _set_paused(false), "GoldButton", Vector2(0, 52))
		rb.process_mode = Node.PROCESS_MODE_ALWAYS
		v.add_child(rb)
		var sb := UI.button("SKIP TO RESULT", func(): _skip = true; _set_paused(false), "", Vector2(0, 46))
		sb.process_mode = Node.PROCESS_MODE_ALWAYS
		v.add_child(sb)
	elif not p and is_instance_valid(_pause_layer):
		_pause_layer.queue_free()

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if get_tree() and get_tree().paused:
		get_tree().paused = false

## Surviving heroes jump in celebration.
func _celebrate() -> void:
	var k := 0
	for u in sim.side_units(0):
		var v: UnitView = _views.get(u["uid"])
		if v == null:
			continue
		var tw := v.create_tween().set_loops(3)
		tw.tween_interval(k * 0.08)
		tw.tween_property(v, "position:y", _home[u["uid"]].y - 30, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(v, "position:y", _home[u["uid"]].y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		k += 1

func _finish(e: Dictionary) -> void:
	_done = true
	_skip = false
	# make sure every view shows its final state
	for u in sim.units:
		var v: UnitView = _views.get(u["uid"])
		if v:
			v.snap_hp(u["hp"])
			if not u["alive"] and v.modulate.a > 0.5:
				v.die()
	if params.has("support"):
		Game.use_support(int(params["support"]["idx"]))
		params.erase("support")
	Game.record_kills(Game.killed_enemies(sim))
	var won: bool = e["won"] and not _retreat
	var stars: int = e["stars"] if won else 0
	if _retreat:
		e["reason"] = "retreat"
	var rewards := {}
	match str(params.get("mode", "")):
		"story":
			rewards = Game.apply_stage_result(int(params["stage"]), won, stars)
			if rewards.has("chapter_clear"):
				_chapter_clear = int(rewards["chapter_clear"])
				rewards.erase("chapter_clear")
		"arena":
			rewards = Game.apply_arena_result(won)
		"tower":
			rewards = Game.apply_tower_result(int(params["floor"]), won)
		"event":
			rewards = Game.apply_event_result(int(params["stage"]), won, stars)
		"dungeon":
			rewards = Game.apply_dungeon_result(str(params["dungeon"]), int(params["diff"]), won)
		"hard":
			rewards = Game.apply_hard_result(int(params["stage"]), won, stars)
		"hunt":
			rewards = Game.apply_hunt_result(str(params["hunt"]), int(params["diff"]), won)
		"rift":
			rewards = Game.apply_rift_result(won)
		"trial":
			var thid := str(params["hero"])
			var alive := false
			for u in sim.units:
				if u["side"] == 0 and u["id"] == thid and u["alive"]:
					alive = true
			if won and not alive:
				won = false
				stars = 0
				e["reason"] = "trial_fallen"
			rewards = Game.apply_trial_result(thid, int(params["tier"]), won, alive)
		"wboss":
			var wdmg := _tactic_damage()
			for ev in sim.events:
				if ev["t"] in ["hit", "dot"] and sim.units[ev["uid"]]["side"] == 1:
					wdmg += int(ev["dmg"])
			if _retreat:
				wdmg /= 2
			var before_rank := Game.wboss_rank()
			rewards = Game.apply_wboss_result(wdmg)
			Game.save_game()
			Game.sfx("victory")
			_show_wboss_result(wdmg, rewards, before_rank)
			return
		"raid":
			var dmg := _tactic_damage()
			for ev in sim.events:
				if ev["t"] in ["hit", "dot"] and sim.units[ev["uid"]]["side"] == 1:
					dmg += int(ev["dmg"])
			if _retreat:
				dmg /= 2
			rewards = Game.apply_raid_result(dmg)
			Game.save_game()
			Game.sfx("victory")
			_show_raid_result(dmg, rewards)
			return
	if won:
		var ft := Game.festival_drop(str(params.get("mode", "")))
		if ft > 0:
			rewards["season_token"] = ft
	Game.save_game()
	Game.play_bgm("bgm_story")
	Game.sfx("victory" if won else "defeat")
	_show_arrow(-1)
	if won:
		_celebrate()
	if won:
		await get_tree().create_timer(1.3, false).timeout
		if not is_inside_tree():
			return
	_show_result(won, stars, rewards, str(e.get("reason", "")))

var _pending_outro: Array = []

## Plays the chapter epilogue (once), then runs the button's own action.
func _leave_with_outro(then: Callable) -> void:
	if _pending_outro.is_empty() or main._vn_active():
		if then.is_valid():
			then.call()
		return
	var po := _pending_outro
	_pending_outro = []
	var done := [false]
	var go_on := func():
		if done[0]:
			return
		done[0] = true
		if then.is_valid():
			then.call()
	var vn: VNDialogue = main.dialogue(po[0], go_on, po[1])
	# closed any other way (e.g. a popup sweep): still carry on, never leave the player on the result
	vn.tree_exiting.connect(func(): go_on.call_deferred())

## The result column must fit the screen (chapter clears add a line, big drops wrap to 2 rows):
## shrink the title, stars and crest until the buttons are visible.
func _fit_result(v: VBoxContainer) -> void:
	if not is_instance_valid(v):
		return
	await get_tree().process_frame
	if not is_instance_valid(v):
		return
	# a VBox grows to fit its children, so measure against the screen, not v.size
	var room := get_viewport_rect().size.y - v.offset_top + v.offset_bottom
	var steps := 0
	while v.get_combined_minimum_size().y > room and steps < 4:
		steps += 1
		for c in v.get_children():
			if c is TextureRect and steps == 1:
				c.visible = false   # crest
			elif c is Label and c.get_theme_font_size("font_size") >= 60:
				c.add_theme_font_size_override("font_size", 60 if steps == 1 else 48)
			elif c is HBoxContainer:
				for st in c.get_children():
					if st is Label and st.text == "★":
						st.add_theme_font_size_override("font_size", 46 if steps == 1 else 36)
		v.add_theme_constant_override("separation", 6 if steps >= 2 else 9)
		if steps >= 3:
			v.offset_top = 30
			room = get_viewport_rect().size.y - v.offset_top + v.offset_bottom
		await get_tree().process_frame
		if not is_instance_valid(v):
			return

## Enemies still standing on screen, ignoring `except` (views not yet dissolved).
func _enemies_left_after(except: int) -> int:
	var n := 0
	for u in sim.units:
		if u["side"] == 1 and u["uid"] != except and _views.has(u["uid"]) and _views[u["uid"]].modulate.a > 0.5 and not _views[u["uid"]].has_meta("dead"):
			n += 1
	return n

## Last enemy down: slow-motion, punch-in, white flash and a big FINISH! (once per battle).
func _finisher(v: UnitView, col: Color) -> void:
	if has_meta("finished") or Game.reduce_fx():
		return
	set_meta("finished", true)
	_screen_flash(Color(1, 1, 1, 0.55))
	_punch(1.08)
	_big_text("FINISH!", col.lightened(0.35))
	_fx.wave(_unit_center(v), col, 520.0)
	_bsfx("crit")
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.55, true, false, true).timeout
	Engine.time_scale = 1.0

func _tactic_damage() -> int:
	var n := 0
	for ev in sim.events:
		if ev["t"] == "tactic":
			for f in ev["fx"]:
				if f["kind"] == "dmg":
					n += int(f["amt"])
	return n

## Commander Tactic cut-in: gold banner, then each effect.
func _play_tactic(e: Dictionary) -> void:
	if not _skip:
		_screen_flash(Color(1.0, 0.85, 0.4, 0.28))
		_big_text("TACTIC: " + str(e["name"]).to_upper(), UI.GOLD)
		_bsfx("buff")
		await _wait(0.6)
	for f in e["fx"]:
		var v: UnitView = _views.get(f["uid"])
		if v == null:
			continue
		match str(f["kind"]):
			"atk":
				v.add_status("ATK ▲")
				_float_text(f["uid"], "ATK ▲", UI.GOLD, 15, Vector2(0, v.size.y * 0.62))
			"shield":
				v.add_status("SHIELD")
				_float_text(f["uid"], "SHIELD", Color("#9fe3ff"), 15, Vector2(0, v.size.y * 0.62))
			"heal":
				v.set_hp(f["hp"], sim.units[f["uid"]]["max_hp"])
				for k in ["BURN", "STUN", "DEF ▼", "SILENCE", "HEAL ▼"]:
					v.remove_status(k)
				if int(f["amt"]) > 0:
					_float_text(f["uid"], "+%s" % Game.fmt(f["amt"]), UI.GREEN, 20)
				if not _skip:
					_fx.heal(_unit_center(v), v.size.x * 0.4)
			"dmg":
				v.set_hp(f["hp"], sim.units[f["uid"]]["max_hp"])
				_float_text(f["uid"], Game.fmt(f["amt"]), Color("#ffb86b"), 22)
				if not _skip:
					_fx.impact("FIRE", _unit_center(v), Color("#ffb05c"), v.size.x * 0.4)
				if f.get("dead", false):
					v.die()
			"revive":
				v.revive_anim()
				v.set_hp(f["hp"], sim.units[f["uid"]]["max_hp"])
				_float_text(f["uid"], "SECOND WIND!", UI.GOLD, 24)
				if not _skip:
					_fx.pillar(_unit_center(v), Color("#ffe27a"), v.size.x * 0.8)
	if not _skip:
		_shake(3.0)
	await _wait(0.5)

## Companion assist: her chibi leaps in with a name banner, then every enemy is struck.
func _play_companion(e: Dictionary) -> void:
	var cid := str(e["id"])
	if not _skip:
		if is_instance_valid(_cameo):
			_cameo.cheer()
		_screen_flash(Color(1.0, 0.6, 0.85, 0.25))
		_big_text("%s ASSIST!" % DB.name_of(cid).split(" ")[0].to_upper(), Color("#ffb8d6"))
		_bsfx("cast")
		# her sprite dashes across the enemy side
		var dash := UI.tex_rect(DB.sprite(cid, 1), Vector2(220, 220))
		dash.size = Vector2(220, 220)
		var vs := get_viewport_rect().size
		dash.position = Vector2(vs.x * 0.3, vs.y * 0.45)
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dash.modulate.a = 0.0
		_fx_layer.add_child(dash)
		var dt := dash.create_tween().set_parallel(true)
		dt.tween_property(dash, "modulate:a", 1.0, 0.12)
		dt.tween_property(dash, "position:x", vs.x * 0.62, 0.4 / _speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		dt.chain().tween_property(dash, "modulate:a", 0.0, 0.25)
		dt.chain().tween_callback(dash.queue_free)
		await _wait(0.5)
	var ec: Color = DB.ELEMENT_COLOR.get(DB.element_of(cid), Color("#ffb8d6"))
	for f in e["fx"]:
		var v: UnitView = _views.get(f["uid"])
		if v == null:
			continue
		v.set_hp(f["hp"], sim.units[f["uid"]]["max_hp"])
		_float_text(f["uid"], Game.fmt(f["amt"]), Color("#ffb8d6"), 22)
		if f.has("status"):
			v.add_status(str(f["status"]))
			_float_text(f["uid"], str(f["status"]), Color("#ffd479"), 14, Vector2(0, v.size.y * 0.62))
		if not _skip:
			_fx.impact(DB.element_of(cid), _unit_center(v), ec, v.size.x * 0.4)
		if f.get("dead", false):
			v.die(ec)
	if not _skip:
		_shake(3.0)
	await _wait(0.5)

## Result popups are "no_back" (they can't be dismissed by accident), so CONTINUE must
## close the popup itself before leaving — otherwise main.back() stops at the popup and the game is stuck.
func _leave_result(v: Control) -> void:
	main.close_popup(v)
	main.back()

func _show_wboss_result(dmg: int, rewards: Dictionary, before_rank: int) -> void:
	var v: VBoxContainer = main.popup("WORLD BOSS", 620, false)
	v.get_meta("layer").set_meta("no_back", true)
	var wb: Dictionary = Game.s["wboss"]
	var l := UI.label("Damage Dealt", 18, UI.MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var d := UI.label("0", 56, UI.GOLD, 8)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	UI.count_to(d, 0, dmg, func(x): return Game.fmt(x), 1.0)
	if dmg >= int(wb["best"]) and dmg > 0:
		var nb := UI.label("★ NEW PERSONAL BEST ★", 16, Color("#ff8fb8"), 4)
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nb)
		UI.pop(nb, 0.4)
	var rk := Game.wboss_rank()
	var info := UI.label("Weekly total %s   •   Rank #%d%s" % [Game.fmt(wb["total"]), rk, ("  (▲%d)" % (before_rank - rk)) if rk < before_rank else ""], 15, Color.WHITE)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)
	var rr := UI.reward_row(rewards, 40, 16)
	rr.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(rr)
	var ok := UI.button("CONTINUE", func(): _leave_result(v), "GoldButton", Vector2(200, 52))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)

func _show_raid_result(dmg: int, rewards: Dictionary) -> void:
	var v: VBoxContainer = main.popup("RAID COMPLETE", 600, false)
	v.get_meta("layer").set_meta("no_back", true)
	var l := UI.label("Total Damage", 18, UI.MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var d := UI.label(Game.fmt(dmg), 56, UI.GOLD, 8)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	UI.pop(d, 0.5)
	var gd: Dictionary = Game.s["guild"]
	var hp := UI.label("Boss HP %s / %s   •   Best %s" % [Game.fmt(maxi(0, gd["raid_hp"])), Game.fmt(DB.raid_max_hp(gd["raid_lv"])), Game.fmt(gd["raid_best"])], 15, Color.WHITE)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hp)
	var rr := UI.reward_row(rewards, 40, 16)
	rr.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(rr)
	var ok := UI.button("CONTINUE", func(): _leave_result(v), "GoldButton", Vector2(200, 52))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)

func _show_stats() -> void:
	var v: VBoxContainer = main.popup("BATTLE STATS", 720)
	var allies := sim.side_units(0, false)
	var mx := 1
	for u in allies:
		mx = maxi(mx, maxi(int(_damage.get(u["uid"], 0)), maxi(int(_healed.get(u["uid"], 0)), int(_taken.get(u["uid"], 0)))))
	for u in allies:
		var uid: int = u["uid"]
		var h := UI.hbox(10)
		v.add_child(h)
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR.get(DB.rarity_of(u["id"]), UI.ACCENT), 6, 2, 1)
		var face := UI.tex_rect(DB.face(u["id"]), Vector2(48, 48), true)
		if not u["alive"]:
			face.modulate = Color(0.4, 0.4, 0.4)
		fp.add_child(face)
		h.add_child(fp)
		var col := UI.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		col.add_child(UI.label("%s%s" % [DB.name_of(u["id"]), "" if u["alive"] else "  (KO)"], 15, Color.WHITE, 2))
		for row in [["DMG", _damage, Color("#ff7b5c")], ["HEAL", _healed, UI.GREEN], ["TAKEN", _taken, Color("#8fb4ff")]]:
			var val := int((row[1] as Dictionary).get(uid, 0))
			if val == 0 and row[0] != "DMG":
				continue
			var r := UI.hbox(6)
			var lab := UI.label(row[0], 11, UI.MUTED)
			lab.custom_minimum_size = Vector2(44, 0)
			r.add_child(lab)
			var b := UI.bar(val, mx, "", 10)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var sb := UI.style(row[2], Color.TRANSPARENT, 4, 0, 0)
			b.add_theme_stylebox_override("fill", sb)
			r.add_child(b)
			var nl := UI.label(Game.fmt(val), 12, Color.WHITE)
			nl.custom_minimum_size = Vector2(70, 0)
			r.add_child(nl)
			col.add_child(r)
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

func _mvp() -> String:
	var best := -1
	var best_uid := -1
	for u in sim.units:
		if u["side"] == 0 and int(_damage.get(u["uid"], 0)) > best:
			best = int(_damage.get(u["uid"], 0))
			best_uid = u["uid"]
	if best_uid < 0:
		return Game.formation()[0][0] if not Game.formation().is_empty() else Game.s["lobby_hero"]
	return sim.units[best_uid]["id"]

func _show_result(won: bool, stars: int, rewards: Dictionary, reason: String) -> void:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.06, 0.0, 0.72) if won else Color(0.15, 0.0, 0.02, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var mvp := _mvp()
	if won and ResourceLoader.exists("res://art/ui/rays.png"):
		# slowly rotating light rays behind the MVP (victory pose)
		var rays := TextureRect.new()
		rays.texture = load("res://art/ui/rays.png")
		rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rays.size = Vector2(900, 900)
		rays.pivot_offset = Vector2(450, 450)
		rays.position = Vector2(get_viewport_rect().size.x * 0.25 - 450, get_viewport_rect().size.y * 0.5 - 450)
		var rm := CanvasItemMaterial.new()
		rm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rays.material = rm
		layer.add_child(rays)
		var rt := rays.create_tween().set_loops()
		rt.tween_property(rays, "rotation", TAU, 40.0).from(0.0)
		rays.modulate.a = 0.0
		rays.create_tween().tween_property(rays, "modulate:a", 1.0, 0.6)
	var art := UI.tex_rect(DB.art(mvp, int(Game.hero(mvp).get("skin", 0))))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_right = 0.5
	art.offset_top = 20
	if not won:
		art.modulate = Color(0.55, 0.35, 0.4)
	layer.add_child(art)
	UI.live(art, DB.theme_color(mvp).lightened(0.5))
	UI.fade_in(art, 0.5, Vector2(-40, 0))

	var v := UI.vbox(12)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.anchor_left = 0.48
	v.offset_right = -40
	v.offset_top = 80
	v.offset_bottom = -40
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(v)
	var t := UI.label("VICTORY" if won else "DEFEAT", 84, UI.GOLD if won else Color("#ff4d63"), 12)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	UI.pop(t, 0.5)
	if won and ResourceLoader.exists("res://art/ui/crest.png"):
		var crest := TextureRect.new()
		crest.texture = load("res://art/ui/crest.png")
		crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crest.custom_minimum_size = Vector2(0, 70)
		crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(crest)
		v.move_child(crest, t.get_index())
		UI.fade_in(crest, 0.5, Vector2(0, -10))
	if won:
		var sh := UI.hbox(14)
		sh.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(sh)
		for k in 3:
			var s := UI.label("★", 64, UI.GOLD if k < stars else Color(1, 1, 1, 0.18), 6)
			sh.add_child(s)
			if k < stars:
				s.modulate.a = 0.0
				var tw := s.create_tween()
				tw.tween_interval(0.35 + 0.25 * k)
				tw.tween_callback(func(): Game.sfx("star_up"))
				tw.tween_property(s, "modulate:a", 1.0, 0.2)
		var conds := UI.label("✔ Victory    %s No hero lost    %s Within 3 rounds" % ["✔" if stars >= 2 and summary["deaths"] == 0 else "✘", "✔" if summary["rounds"] <= 3 else "✘"], 15, Color.WHITE, 3)
		conds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(conds)
		var q := UI.label("MVP %s: \"%s\"" % [DB.name_of(mvp), Game.voice(mvp, "win")], 16, Color("#ffe6a3"), 3)
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(q)
	else:
		var why := "Your team has fallen."
		if reason == "timeout":
			why = "Time over — defeat all enemies within %d rounds." % DB.MAX_ROUNDS
		elif reason == "retreat":
			why = "You retreated from battle."
		elif reason == "trial_fallen":
			why = "%s fell in battle — in her Trial she must survive to the end." % DB.name_of(str(params.get("hero", ""))).split(" ")[0]
		var l := UI.wrap_label(why + "\nTip: " + Game.defeat_tip(_foes), 16, Color.WHITE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	if not rewards.is_empty():
		var rp := UI.styled_panel(Color(0, 0, 0, 0.5), UI.GOLD_DARK, 12, 1, 14)
		var rv := UI.vbox(6)
		rp.add_child(rv)
		rv.add_child(UI.label("REWARDS", 16, UI.GOLD, 3))
		var shown := rewards.duplicate()
		shown.erase("player_exp")
		rv.add_child(UI.reward_row(shown, 40, 16))
		v.add_child(rp)
	var btns := UI.hbox(12)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(btns)
	if _chapter_clear > 0:
		var cc := UI.label("CHAPTER %d CLEAR!  +%d Gems  +%d Tickets  +Gear Chest" % [_chapter_clear, DB.CHAPTER_REWARD["gems"], DB.CHAPTER_REWARD["summon_ticket"]], 18, UI.GREEN, 4)
		cc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cc)
		v.move_child(cc, btns.get_index())
		var ch := _chapter_clear - 1
		# the chapter epilogue plays when the player leaves the result (NEXT STAGE / CONTINUE / ...),
		# never on a timer, so it can't stack with the next chapter's prologue or hide the buttons
		_pending_outro = [DB.CHAPTERS[ch]["outro"], str(DB.CHAPTERS[ch]["bg"])]
	var mode := str(params.get("mode", ""))
	if won and mode == "story" and int(params["stage"]) + 1 < DB.stage_count():
		btns.add_child(UI.button("NEXT STAGE ▶", func(): main.replace("story", {"select": int(params["stage"]) + 1}), "GoldButton", Vector2(200, 54)))
	if won and mode == "event" and int(params["stage"]) + 1 < DB.EVENT["stages"].size():
		btns.add_child(UI.button("NEXT STAGE ▶", func(): main.replace("formation", {"mode": "event", "stage": int(params["stage"]) + 1}), "GoldButton", Vector2(200, 54)))
	if won and mode == "dungeon" and int(params["diff"]) + 1 < DB.DUNGEON_LEVELS.size() and Game.dungeon_tries(str(params["dungeon"])) > 0:
		btns.add_child(UI.button("NEXT LEVEL ▶", func(): main.replace("formation", {"mode": "dungeon", "dungeon": params["dungeon"], "diff": int(params["diff"]) + 1}), "GoldButton", Vector2(200, 54)))
	if won and mode == "hard" and int(params["stage"]) + 1 < DB.stage_count() and Game.hard_unlocked(int(params["stage"]) + 1):
		btns.add_child(UI.button("NEXT HARD ▶", func(): main.replace("formation", {"mode": "hard", "stage": int(params["stage"]) + 1}), "GoldButton", Vector2(200, 54)))
	if won and mode == "tower":
		btns.add_child(UI.button("NEXT FLOOR ▶", func(): main.replace("formation", {"mode": "tower", "floor": int(Game.s["tower"]["floor"])}), "GoldButton", Vector2(200, 54)))
	if not won:
		btns.add_child(UI.button("RETRY", func(): main.replace("formation", params), "GoldButton", Vector2(160, 54)))
		btns.add_child(UI.button("UPGRADE HEROES", func(): main.replace("heroes"), "", Vector2(200, 54)))
	btns.add_child(UI.button("STATS", _show_stats, "", Vector2(110, 54)))
	btns.add_child(UI.button("CONTINUE", func(): main.back(), "", Vector2(160, 54)))
	if not _pending_outro.is_empty():
		for b in btns.get_children():
			if b is Button and b.text != "STATS":
				var cbs: Array = b.pressed.get_connections()
				for cn in cbs:
					b.pressed.disconnect(cn["callable"])
				var orig: Callable = cbs[0]["callable"] if not cbs.is_empty() else Callable()
				b.pressed.connect(func(): _leave_with_outro(orig))
	_fit_result.call_deferred(v)
