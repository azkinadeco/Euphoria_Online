extends Screen
## Brown Dust style deployment: 3x3 grid, deploy order, enemy preview with
## live skill-range highlight for the selected hero.

var _board: GridBoard
var _enemy_board: GridBoard
var _roster: HBoxContainer
var _info: HBoxContainer
var _power: Label
var _sel := ""
var _enemies: Array = []
var _scout: Dictionary = {}
var _mode := ""
var _land := ""
var _land_fx: SkillFX
const SUPPORT := "@support"

func build() -> void:
	_mode = str(params.get("mode", ""))
	_enemies = Game.enemies_for(params)
	_scout = Game.scout(_enemies)
	set_bg(Game.battle_bg(params) if _mode != "" else "battle", 0.55)
	var bar := header("FORMATION" if _mode == "" else "BATTLE PREP", ["energy"] if _mode in ["story", "event", "hard"] else [])
	_power = UI.label("", 18, Color("#ffb86b"), 4)
	_power.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_power)
	bar.move_child(_power, 2)
	var tabs := UI.hbox(4)
	for i in 3:
		var pi: int = i
		var tb := UI.button("TEAM %d" % (i + 1), func():
			Game.switch_preset(pi)
			_sel = ""
			main.replace("formation", params), "TabButton", Vector2(86, 40))
		tb.toggle_mode = true
		tb.button_pressed = int(Game.s["preset_idx"]) == i
		tb.add_theme_font_size_override("font_size", 14)
		tabs.add_child(tb)
	bar.add_child(tabs)
	bar.move_child(tabs, 3)

	# selected hero strip
	var strip := UI.styled_panel(Color(0.05, 0.03, 0.1, 0.85), Color("#5b4790"), 12, 1, 10)
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.offset_left = 16
	strip.offset_right = -16
	strip.offset_top = 66
	strip.offset_bottom = 118
	add_child(strip)
	_info = UI.hbox(12)
	strip.add_child(_info)

	# boards
	var area := Control.new()
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.offset_top = 146
	area.offset_bottom = -196
	area.offset_left = 24
	area.offset_right = -24
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(area)
	_board = GridBoard.new()
	_board.interactive = true
	_board.anchor_right = 0.47
	_board.anchor_bottom = 1.0
	area.add_child(_board)
	_board.cell_pressed.connect(_on_cell)
	_board.resized.connect(_layout_units)
	_board.set_drag_forwarding(_board_get_drag, _board_can_drop, _board_drop)
	var lbl := UI.label("YOUR TEAM   •   FRONT LINE ▶", 13, UI.GOLD, 3)
	lbl.position = Vector2(0, -20)
	_board.add_child(lbl)

	if _enemies.is_empty():
		_build_tips(area)
	else:
		_enemy_board = GridBoard.new()
		_enemy_board.enemy_side = true
		_enemy_board.tile_color = Color(0.95, 0.35, 0.4, 0.16)
		_enemy_board.line_color = Color(1.0, 0.55, 0.6, 0.5)
		_enemy_board.anchor_left = 0.53
		_enemy_board.anchor_right = 0.97
		_enemy_board.anchor_bottom = 1.0
		area.add_child(_enemy_board)
		_enemy_board.resized.connect(_layout_enemies)
		var el := UI.label("◀ ENEMY FRONT LINE", 13, Color("#ff8a9a"), 3)
		el.position = Vector2(0, -20)
		_enemy_board.add_child(el)
		var vs := UI.label("VS", 40, Color("#ff5c6c"), 8)
		vs.anchor_left = 0.5
		vs.anchor_right = 0.5
		vs.anchor_top = 0.4
		vs.offset_left = -30
		vs.offset_right = 30
		vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		area.add_child(vs)

	# bottom dock
	var dock := UI.styled_panel(Color(0.04, 0.02, 0.08, 0.92), UI.GOLD_DARK, 14, 1, 10)
	dock.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_top = -188
	dock.offset_left = 16
	dock.offset_right = -16
	dock.offset_bottom = -12
	add_child(dock)
	var dh := UI.hbox(12)
	dock.add_child(dh)
	_roster = UI.hbox(10)
	var rs := UI.scroll(UI.margin(_roster, 4, 8, 4, 4), true)
	rs.set_drag_forwarding(Callable(), _roster_can_drop, _roster_drop)
	dh.add_child(rs)
	var btns := UI.vbox(8)
	btns.custom_minimum_size = Vector2(250, 0)
	dh.add_child(btns)
	var row := UI.hbox(8)
	btns.add_child(row)
	var ab := UI.button("AUTO", func(): Game.auto_formation(str(_scout.get("counter", ""))); _sel = ""; _render(), "", Vector2(0, 38 if _mode != "" else 50))
	ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ab)
	var cb := UI.button("CLEAR", func(): Game.s["formation"].clear(); Game.mark_dirty(); _sel = ""; _render(), "", Vector2(0, 38 if _mode != "" else 50))
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cb)
	var extra := UI.hbox(8)
	btns.add_child(extra)
	if _mode in ["story", "event", "tower", "dungeon", "hard", "hunt"]:
		var sb := UI.button("+ SUPPORT" if not params.has("support") else "CHANGE SUPPORT", _pick_support, "", Vector2(0, 34))
		sb.add_theme_color_override("font_color", UI.GREEN)
		sb.add_theme_font_size_override("font_size", 14)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		extra.add_child(sb)
	if _mode != "":
		var et := Game.equipped_tactic()
		var tb := UI.button(str(DB.tactic_def(et["id"])["name"]) if not et.is_empty() else "+ TACTIC", _pick_tactic, "", Vector2(0, 34))
		tb.tooltip_text = "Commander Tactic"
		tb.add_theme_color_override("font_color", UI.GOLD)
		tb.add_theme_font_size_override("font_size", 14)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.clip_text = true
		if not Game.tactic_unlocked("rally"):
			tb.disabled = true
			tb.text = "TACTIC (Lv.%d)" % DB.TACTICS[0]["req"]
		extra.add_child(tb)
	if extra.get_child_count() == 0:
		extra.queue_free()
	if _mode != "":
		var cost_txt := ""
		if _mode == "story":
			cost_txt = "\n%d Energy" % int(DB.stage(int(params["stage"]))["energy"])
		elif _mode == "hard":
			cost_txt = "\n%d Energy" % int(DB.hard_stage(int(params["stage"]))["energy"])
		elif _mode == "arena":
			cost_txt = "\n1 Ticket (%d left)" % int(Game.s["arena"]["tickets"])
		elif _mode == "event":
			cost_txt = "\n8 Energy"
		elif _mode == "dungeon":
			cost_txt = "\n1 Attempt (%d left)" % Game.dungeon_tries(str(params["dungeon"]))
		elif _mode == "trial":
			cost_txt = "\n%s must survive" % DB.name_of(str(params["hero"])).split(" ")[0]
		elif _mode == "rift":
			cost_txt = "\nFloor %d" % int(Game.s["rift"]["floor"])
		elif _mode == "hunt":
			cost_txt = "\n1 Hunt (%d left)" % Game.hunt_tries()
		elif _mode == "wboss":
			cost_txt = "\n1 Attempt (%d left)" % int(Game.s["wboss"]["tries"])
		elif _mode == "raid":
			cost_txt = "\n1 Attempt (%d left)" % int(Game.s["guild"]["raid_tries"])
		# the dock is 156px tall inside: three rows must fit, so REPEAT sits beside START
		var start_row := UI.hbox(8)
		btns.add_child(start_row)
		var go_b := UI.button("⚔ START BATTLE" + cost_txt, _start, "GoldButton", Vector2(0, 66))
		go_b.add_theme_font_size_override("font_size", 17)
		go_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		start_row.add_child(go_b)
		if _mode in ["story", "event", "dungeon", "hard"] and _cleared_before():
			var rb := UI.button("↻\nREPEAT", _ask_repeat, "", Vector2(76, 66))
			rb.add_theme_font_size_override("font_size", 13)
			rb.add_theme_color_override("font_color", Color("#9fd0ff"))
			start_row.add_child(rb)
	else:
		btns.add_child(UI.wrap_label("Tap a hero to deploy, then tap a tile to move. Drag & drop also works. Numbers = action order.", 13, UI.MUTED))
		btns.add_child(UI.button("STORY ▶", func(): main.go("story"), "GoldButton", Vector2(0, 48)))
	_render()
	if tutorial("formation"):
		# show the player which column is the front line while the tip is on screen
		var front := {}
		for r in 3:
			front[Vector2i(0, r)] = Color(1.0, 0.85, 0.3, 0.45)
		_board.highlights = front
		get_tree().create_timer(8.0).timeout.connect(func():
			if is_instance_valid(_board):
				_board.highlights = {})

func _build_tips(area: Control) -> void:
	var p := UI.panel()
	p.anchor_left = 0.53
	p.anchor_right = 1.0
	p.anchor_bottom = 1.0
	area.add_child(p)
	var v := UI.vbox(6)
	p.add_child(UI.scroll(v))
	v.add_child(UI.label("TACTICS GUIDE", 20, UI.GOLD, 3))
	for t in [
		"• Units attack the enemy standing in their SAME ROW.",
		"• Column 1 (front) takes the first hits — put Tanks there.",
		"• Order #1 acts first. Sides alternate: Ally#1 → Enemy#1 → Ally#2 ...",
		"• Healers late in the order heal after damage lands.",
		"• Elements: Fire > Wind > Earth > Water > Fire, Light ⇄ Dark (+30%).",
		"• Win in ≤3 rounds with no losses for 3★.",
		"• Synergy: 2/3/4/5 heroes of the same element → +5/10/15/20% ATK & HP for them.",
		"• Passives: Tanks guard, Warriors rage, Assassins crit, Mages pierce DEF, Rangers snipe, Healers mend.",
		"• Bosses ENRAGE below 50% HP (+30% ATK) — burst them down fast!",
		"• TAUNT pulls single-target attacks onto the tank. SILENCE turns a skill into a weak attack. HEAL ▼ blocks healing — bring Furu/Aqua to Cleanse.",
	]:
		v.add_child(UI.wrap_label(t, 14, UI.TEXT))
	var counts := {}
	for e in Game.formation():
		var el: String = DB.ELEMENT_GROUP.get(DB.element_of(e[0]), "LIGHT")
		counts[el] = int(counts.get(el, 0)) + 1
	var parts: Array = []
	for k in counts.keys():
		parts.append("%s ×%d" % [k, counts[k]])
	v.add_child(UI.label("Team elements: " + (", ".join(parts) if not parts.is_empty() else "-"), 14, Color("#9fd0ff")))

func refresh() -> void:
	super.refresh()

func _render() -> void:
	_power.text = "  Power %s" % Game.fmt(Game.team_power())
	if not _enemies.is_empty():
		var ep := Game.enemy_power(_enemies)
		_power.text += "   vs   Enemy %s" % Game.fmt(ep)
		_power.add_theme_color_override("font_color", UI.GREEN if Game.team_power() >= ep else Color("#ff8a9a"))
	var syn := DB.synergy(Game.formation().map(func(e): return e[0]))
	if float(syn["bonus"]) > 0.0:
		_power.text += "   •   SYNERGY %s x%d +%d%%" % [syn["element"], syn["count"], int(float(syn["bonus"]) * 100)]
	_render_info()
	_render_roster()
	_layout_units()
	_layout_enemies()

func _render_info() -> void:
	for c in _info.get_children():
		c.queue_free()
	if _sel == SUPPORT and params.has("support"):
		var sp: Dictionary = params["support"]
		var fp := UI.styled_panel(Color.BLACK, UI.GREEN, 8, 2, 1)
		fp.add_child(UI.tex_rect(DB.face(sp["id"]), Vector2(40, 40), true))
		_info.add_child(fp)
		var sv := UI.vbox(0)
		sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sv.add_child(UI.label("FRIEND SUPPORT • %s (%s) Lv.%d  •  %s" % [DB.name_of(sp["id"]), sp["friend"], sp["level"], DB.skill_of(sp["id"])["name"]], 16, UI.GREEN, 3))
		sv.add_child(UI.label("Acts last in your order. Tap an empty tile to move her.", 13, UI.TEXT))
		_info.add_child(sv)
		_info.add_child(UI.button("REMOVE", func(): params.erase("support"); _sel = ""; main.replace("formation", params), "", Vector2(100, 40)))
		return
	if _sel == "":
		var lk := Game.active_links()
		var hint := "select a hero to see her skill range"
		if not _scout.is_empty():
			hint = "enemies are mostly %s, bring %s (+30%% ATK)" % [_scout["main"], _scout["counter"]]
		var lt := UI.label("Deployed %d / %d   —   %s" % [Game.formation().size(), DB.MAX_DEPLOY, hint], 16, UI.MUTED)
		lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lt.clip_text = true
		_info.add_child(lt)
		var lb := UI.button("♥ LINKS %d" % lk.size(), _show_links, "GoldButton" if not lk.is_empty() else "", Vector2(120, 34))
		lb.add_theme_font_size_override("font_size", 13)
		_info.add_child(lb)
		return
	var face := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(_sel)], 8, 2, 1)
	face.add_child(UI.tex_rect(DB.face(_sel), Vector2(40, 40), true))
	_info.add_child(face)
	var sk := DB.skill_of(_sel)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pk := DB.passive_of(_sel)
	v.add_child(UI.label("%s  •  %s  [%s]%s" % [DB.name_of(_sel), sk["name"], DB.shape_label(sk), ("   •   " + str(DB.PASSIVES[pk]["name"])) if pk != "" else ""], 16, UI.GOLD, 3))
	v.add_child(UI.label(str(sk.get("desc", "")), 13, UI.TEXT))
	_info.add_child(v)
	var idx := -1
	for i in Game.formation().size():
		if Game.formation()[i][0] == _sel:
			idx = i
	if idx >= 0:
		_info.add_child(UI.label("ORDER #%d" % (idx + 1), 16, Color.WHITE, 3))
		_info.add_child(UI.button("▲", func(): Game.move_order(_sel, -1); _render(), "", Vector2(44, 40)))
		_info.add_child(UI.button("▼", func(): Game.move_order(_sel, 1); _render(), "", Vector2(44, 40)))
		_info.add_child(UI.button("REMOVE", func(): Game.remove_hero(_sel); _sel = ""; _render(), "", Vector2(100, 40)))
	else:
		_info.add_child(UI.label("Not deployed — tap a tile", 14, UI.MUTED))

func _render_roster() -> void:
	for c in _roster.get_children():
		c.queue_free()
	var ids: Array = Game.s["heroes"].keys()
	ids.sort_custom(func(a, b): return Game.hero_power(a) > Game.hero_power(b))
	for id in ids:
		var hid: String = id
		var order := -1
		for i in Game.formation().size():
			if Game.formation()[i][0] == hid:
				order = i
		var opts := {"skin": true}
		if order >= 0:
			opts["badge"] = order + 1
		var card := HeroCard.new(hid, Vector2(118, 150), opts)
		card.set_selected(hid == _sel)
		if order >= 0:
			card.modulate = Color(0.75, 0.75, 0.8)
		if (_scout.get("heroes", []) as Array).has(hid):
			var up := UI.styled_panel(Color(0, 0, 0, 0.8), UI.GREEN, 6, 1, 3)
			up.add_child(UI.label("▲ +30%", 12, UI.GREEN, 2))
			up.position = Vector2(8, 34)
			up.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(up)
		card.pressed.connect(func(): _on_roster(hid))
		card.set_drag_forwarding(func(_p): return _make_drag(hid, false), Callable(), Callable())
		_roster.add_child(card)

func _make_drag(hid: String, from_board: bool) -> Dictionary:
	var prev := UI.tex_rect(DB.sprite(hid, int(Game.hero(hid)["star"])), Vector2(110, 110))
	prev.size = Vector2(110, 110)
	prev.modulate.a = 0.85
	var holder := Control.new()
	holder.add_child(prev)
	prev.position = Vector2(-55, -90)
	set_drag_preview(holder)
	_sel = hid
	return {"hero": hid, "from_board": from_board}

func _on_roster(hid: String) -> void:
	Game.sfx("ui_click")
	if Game.formation_cell_of(hid).x < 0:
		var cell := _best_free_cell(hid)
		if cell.x >= 0 and Game.formation().size() < DB.MAX_DEPLOY:
			Game.place_hero(hid, cell)
			_land = hid
			Game.sfx("battle/dash")
		elif Game.formation().size() >= DB.MAX_DEPLOY:
			main.toast("Team is full — tap a deployed hero's tile to swap in %s." % DB.name_of(hid), UI.GOLD)
	_sel = hid
	_render()

func _best_free_cell(hid: String) -> Vector2i:
	var r := DB.role_of(hid)
	var pref := 0 if r in ["TANK", "PALADIN", "KNIGHT", "WARRIOR"] else (1 if r in ["HEALER", "BUFFER"] else 2)
	for col in [pref, 1, 0, 2]:
		for row in [1, 0, 2]:
			if Game.formation_at(Vector2i(col, row)) == "":
				return Vector2i(col, row)
	return Vector2i(-1, -1)

func _support_cell() -> Vector2i:
	if params.has("support"):
		return params["support"]["cell"]
	return Vector2i(-1, -1)

func _on_cell(cell: Vector2i) -> void:
	var occ := Game.formation_at(cell)
	if cell == _support_cell():
		_sel = "" if _sel == SUPPORT else SUPPORT
		_render()
		return
	if _sel == SUPPORT:
		if occ == "":
			params["support"]["cell"] = cell
			Game.sfx("ui_click")
		else:
			main.toast("Support hero can only move to an empty tile.", UI.RED)
		_render()
		return
	if _sel != "" and occ == _sel:
		_sel = ""
	elif _sel != "":
		var err := Game.place_hero(_sel, cell)
		if err != "":
			main.toast(err, UI.RED)
		else:
			Game.sfx("battle/dash")
			_land = _sel
	elif occ != "":
		_sel = occ
	_render()

# ---------------------------------------------------------------- drag & drop

func _board_get_drag(pos: Vector2) -> Variant:
	var cell := _board.cell_at(pos)
	var occ := Game.formation_at(cell) if cell.x >= 0 else ""
	if occ == "":
		return null
	return _make_drag(occ, true)

func _board_can_drop(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("hero")

func _board_drop(pos: Vector2, data: Variant) -> void:
	var cell := _board.cell_at(pos)
	if cell.x < 0:
		return
	if cell == _support_cell():
		main.toast("That tile is used by your friend's support hero.", UI.RED)
		return
	var err := Game.place_hero(data["hero"], cell)
	if err != "":
		main.toast(err, UI.RED)
	_sel = data["hero"]
	Game.sfx("ui_click")
	_render()

func _roster_can_drop(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("from_board", false)

func _roster_drop(_pos: Vector2, data: Variant) -> void:
	Game.remove_hero(data["hero"])
	_sel = ""
	_render()

# ---------------------------------------------------------------- unit layout

func _layout_units() -> void:
	if not is_instance_valid(_board):
		return
	for c in _board.get_children():
		if c is UnitView:
			c.queue_free()
	var th := _board.tile_h()
	var sz := Vector2(th * 1.3, th * 1.3)
	var f := Game.formation()
	# draw back rows first so front rows overlap correctly
	var order_list: Array = []
	for i in f.size():
		order_list.append(i)
	order_list.sort_custom(func(a, b): return f[a][2] < f[b][2])
	for i in order_list:
		var e: Array = f[i]
		var hid: String = e[0]
		var uv := UnitView.new(hid, false, DB.sprite(hid, int(Game.hero(hid)["star"])), sz, i, false)
		var foot := _board.cell_foot(Vector2i(e[1], e[2]))
		uv.position = foot - Vector2(sz.x * 0.5, sz.y)
		_board.add_child(uv)
		uv.start_idle()
		if hid == _sel:
			uv.sprite.self_modulate = Color(1.3, 1.2, 0.9)
		if hid == _land:
			_land = ""
			var target := uv.position
			uv.position = target - Vector2(0, 90)
			uv.modulate.a = 0.0
			var lt := uv.create_tween()
			lt.tween_property(uv, "modulate:a", 1.0, 0.08)
			lt.parallel().tween_property(uv, "position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			lt.tween_property(uv.sprite, "scale", Vector2(1.18, 0.82), 0.06)
			lt.tween_property(uv.sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
			if not is_instance_valid(_land_fx):
				_land_fx = SkillFX.new()
				_board.add_child(_land_fx)
			var foot_p := foot
			get_tree().create_timer(0.22).timeout.connect(func():
				if is_instance_valid(_land_fx):
					_land_fx.wave(foot_p, UI.GOLD, sz.x * 0.7)
					_land_fx.aura(foot_p, DB.ELEMENT_COLOR.get(DB.element_of(hid), UI.GOLD), sz.x * 0.4))
	if params.has("support"):
		var sp: Dictionary = params["support"]
		if Game.formation_at(sp["cell"]) != "":
			var free := _best_free_cell(sp["id"])
			if free.x >= 0:
				sp["cell"] = free
		var su := UnitView.new(sp["id"], false, DB.sprite(sp["id"], int(sp["star"])), sz, -1, false)
		su.position = _board.cell_foot(sp["cell"]) - Vector2(sz.x * 0.5, sz.y)
		_board.add_child(su)
		su.start_idle()
		su.status_label.text = "FRIEND"
		su.status_label.add_theme_color_override("font_color", UI.GREEN)
		su.sprite.self_modulate = Color(0.85, 1.2, 0.9) if _sel == SUPPORT else Color.WHITE
	if _sel == SUPPORT:
		_board.selected = _support_cell()
		_board.highlights = {}
		_board.queue_redraw()
		return
	_board.selected = Game.formation_cell_of(_sel) if _sel != "" else Vector2i(-1, -1)
	_board.highlights = {}
	_board.queue_redraw()

func _layout_enemies() -> void:
	if not is_instance_valid(_enemy_board):
		return
	for c in _enemy_board.get_children():
		if c is UnitView:
			c.queue_free()
	var th := _enemy_board.tile_h()
	var sorted := _enemies.duplicate()
	sorted.sort_custom(func(a, b): return a["cell"].y < b["cell"].y)
	for e in sorted:
		var boss: bool = e.get("boss", false)
		var sz := Vector2(th * (1.8 if boss else 1.35), th * (1.8 if boss else 1.35))
		var tex := DB.boss_sprite(e["id"]) if boss else DB.sprite(e["id"], int(e.get("star", 1)))
		var uv := UnitView.new(e["id"], true, tex, sz, _enemies.find(e), false, boss)
		if e.get("elite", false):
			UI.corrupt(uv.sprite)
		uv.position = _enemy_board.cell_foot(e["cell"]) - Vector2(sz.x * 0.5, sz.y)
		_enemy_board.add_child(uv)
		uv.start_idle()
		var lv := UI.label(("BOSS " if boss else "") + "Lv.%d" % int(e.get("level", 1)), 12, Color("#ff8a9a") if boss else Color.WHITE, 3)
		lv.position = Vector2(sz.x * 0.3, sz.y - 4)
		uv.add_child(lv)
	# skill range preview for the selected hero
	var hl := {}
	var sel_id := _sel
	var sel_cell := Game.formation_cell_of(_sel) if _sel != SUPPORT else _support_cell()
	if _sel == SUPPORT and params.has("support"):
		sel_id = params["support"]["id"]
	if sel_id != "" and sel_cell.x >= 0:
		var sim := BattleSim.new()
		sim.setup([{"id": sel_id, "cell": sel_cell, "level": 1, "star": 1}], _enemies, 1)
		var me: Dictionary = sim.units[0]
		var sk := DB.skill_of(sel_id)
		if sk.get("aim", "") != "ally_all":
			var tgt := sim._aim(me, sk.get("aim", "front"))
			if not tgt.is_empty():
				for c in DB.shape_cells(sk.get("shape", "single"), tgt["cell"]):
					hl[c] = Color(1.0, 0.35, 0.35, 0.55)
				hl[tgt["cell"]] = Color(1.0, 0.85, 0.3, 0.7)
	_enemy_board.highlights = hl
	_enemy_board.queue_redraw()

func _pick_support() -> void:
	var v: VBoxContainer = main.popup("FRIEND SUPPORT", 760)
	v.add_child(UI.wrap_label("Borrow one hero from a friend for this battle. She joins as an extra unit (acts last). Each friend can help once per day and you earn 20 Friend Points.", 14, UI.MUTED))
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	for f in Game.friends():
		var fr: Dictionary = f
		var box := UI.vbox(2)
		var card := HeroCard.new(fr["hero"], Vector2(130, 160), {"owned": true, "show_level": false})
		box.add_child(card)
		var l := UI.label("%s  Lv.%d %s" % [fr["name"], fr["level"], "★".repeat(fr["star"])], 12, UI.MUTED if fr["used"] else Color.WHITE, 2)
		box.add_child(l)
		if fr["used"]:
			card.disabled = true
			card.modulate = Color(0.4, 0.4, 0.45)
			l.text = "%s • used today" % fr["name"]
		else:
			card.pressed.connect(func():
				main.close_popup(v)
				choose_support(int(fr["idx"])))
		g.add_child(box)
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

func choose_support(idx: int) -> void:
	for fr in Game.friends():
		if int(fr["idx"]) == idx and not fr["used"]:
			params["support"] = {"idx": idx, "friend": fr["name"], "id": fr["hero"], "level": fr["level"], "star": fr["star"], "cell": _best_free_cell(fr["hero"])}
			_sel = SUPPORT
			Game.sfx("ui_click")
			main.replace("formation", params)
			return

func _cleared_before() -> bool:
	match _mode:
		"story": return Game.stage_stars(int(params["stage"])) > 0
		"event": return Game.event_stars(int(params["stage"])) > 0
		"hard": return Game.hard_stars(int(params["stage"])) > 0
		"dungeon": return int(params["diff"]) <= Game.dungeon_cleared(str(params["dungeon"]))
	return false

func _ask_repeat() -> void:
	if Game.formation().is_empty():
		main.toast("Deploy at least one hero!", UI.RED)
		return
	var v: VBoxContainer = main.popup("AUTO-REPEAT", 520)
	v.add_child(UI.wrap_label("Fight this stage several times in a row with your current team. Stops automatically on defeat or when you run out of Energy/attempts.", 14, UI.MUTED))
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for n in [3, 5, 10]:
		var times: int = n
		row.add_child(UI.button("x%d" % n, func():
			main.close_popup(v)
			_repeat(times), "GoldButton", Vector2(110, 50)))

func _repeat(times: int) -> void:
	var v: VBoxContainer = main.popup("AUTO-REPEAT", 600, false)
	var title := UI.label("Fighting...", 22, UI.GOLD, 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var bar := UI.bar(0, times, "GoldBar", 12)
	v.add_child(bar)
	var log_box := UI.vbox(2)
	v.add_child(log_box)
	var total := {}
	var wins := 0
	var stop_reason := ""
	var qp := params.duplicate()
	qp.erase("support")
	for i in times:
		var r := Game.quick_battle(qp)
		if r.has("error"):
			stop_reason = str(r["error"])
			break
		var line := UI.label("Run %d: %s %s" % [i + 1, "VICTORY" if r["won"] else "DEFEAT", "★".repeat(int(r["stars"]))], 15, UI.GREEN if r["won"] else UI.RED, 2)
		log_box.add_child(line)
		UI.pop(line, 0.2)
		bar.value = i + 1
		Game.sfx("battle/hit" if r["won"] else "defeat")
		for k in r["rewards"].keys():
			total[k] = int(total.get(k, 0)) + int(r["rewards"][k])
		if r["won"]:
			wins += 1
		else:
			stop_reason = "Stopped: defeated."
			break
		await get_tree().create_timer(0.35).timeout
		if not is_inside_tree():
			return
	Game.save_game()
	title.text = "DONE  •  %d win(s)" % wins
	if stop_reason != "":
		v.add_child(UI.label(stop_reason, 14, Color("#ff8a9a")))
	if not total.is_empty():
		var shown := total.duplicate()
		shown.erase("player_exp")
		var rr := UI.reward_row(shown, 34, 15)
		rr.alignment = FlowContainer.ALIGNMENT_CENTER
		v.add_child(rr)
		Game.sfx("victory")
	var ok := UI.button("OK", func(): main.close_popup(v); main.replace("formation", params), "GoldButton", Vector2(180, 48))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)

func _show_links() -> void:
	var v: VBoxContainer = main.popup("STORY LINKS", 760)
	v.add_child(UI.wrap_label("Heroes bound by the story fight better together. Deploy every member of a link to activate its bonus.", 14, UI.MUTED))
	var list := UI.vbox(6)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 420)
	v.add_child(sc)
	var active := Game.active_links()
	var sorted: Array = DB.LINKS.duplicate()
	sorted.sort_custom(func(a, b): return int(active.has(a)) > int(active.has(b)))
	for l in sorted:
		var on: bool = active.has(l)
		var p := UI.styled_panel(Color(0.22, 0.1, 0.16, 0.9) if on else Color(0.08, 0.06, 0.14, 0.9), Color("#ff8fb8") if on else Color("#3d3160"), 10, 2 if on else 1, 8)
		list.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		for hid in l["heroes"]:
			var f := UI.tex_rect(DB.face(hid), Vector2(44, 44), true)
			if not Game.owns(hid):
				f.modulate = Color(0.3, 0.3, 0.35)
			h.add_child(f)
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		info.add_child(UI.label(("♥ " if on else "") + str(l["name"]) + "   " + DB.link_bonus_text(l), 15, Color("#ffb8d6") if on else Color.WHITE, 2))
		info.add_child(UI.label("\"%s\"" % l["line"], 12, UI.MUTED))
		h.add_child(UI.label("ACTIVE" if on else "", 13, UI.GREEN, 2))

func _pick_tactic() -> void:
	var v: VBoxContainer = main.popup("COMMANDER TACTICS", 760)
	tutorial("tactics")
	v.add_child(UI.wrap_label("Pick one tactic. It fires automatically during battle when its trigger happens. Upgrade with Gold — max level rises with your Player level.", 14, UI.MUTED))
	var list := UI.vbox(8)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 400)
	v.add_child(sc)
	var eq := str(Game.s["tactics"].get("eq", ""))
	for td in DB.TACTICS:
		var id: String = td["id"]
		var open := Game.tactic_unlocked(id)
		var lv := Game.tactic_lv(id)
		var p := UI.styled_panel(Color(0.2, 0.15, 0.05, 0.9) if id == eq else Color(0.08, 0.06, 0.14, 0.9), UI.GOLD if id == eq else Color("#3d3160"), 10, 2 if id == eq else 1, 10)
		list.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		var ic := UI.tex_rect(DB.icon(td["icon"]), Vector2(48, 48))
		if not open:
			ic.modulate = Color(0.35, 0.35, 0.4)
		h.add_child(ic)
		var info := UI.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		info.add_child(UI.label("%s  Lv.%d" % [td["name"], lv] if open else "%s  (Player Lv.%d)" % [td["name"], td["req"]], 17, Color.WHITE if open else UI.MUTED, 2))
		info.add_child(UI.label("Trigger: " + str(td["trigger"]), 13, Color("#9fd0ff")))
		info.add_child(UI.wrap_label(DB.tactic_desc(id, lv), 13, UI.TEXT))
		if open and lv < DB.TACTIC_MAX_LV:
			info.add_child(UI.label("Next Lv: " + DB.tactic_desc(id, lv + 1), 12, UI.GREEN))
		if not open:
			continue
		var bv := UI.vbox(6)
		h.add_child(bv)
		bv.add_child(UI.button("EQUIPPED" if id == eq else "EQUIP", func():
			Game.equip_tactic("" if id == eq else id)
			main.close_popup(v)
			main.replace("formation", params), "GoldButton" if id != eq else "", Vector2(130, 42)))
		if lv < DB.TACTIC_MAX_LV:
			var ub := UI.button("UP  %s" % Game.fmt(DB.tactic_cost(lv)), func():
				var err := Game.upgrade_tactic(id)
				if err != "":
					main.toast(err, UI.RED)
					return
				Game.sfx("ui_click")
				main.toast("%s reached Lv.%d!" % [td["name"], Game.tactic_lv(id)], UI.GOLD)
				main.close_popup(v)
				_pick_tactic(), "", Vector2(130, 38))
			ub.add_theme_font_size_override("font_size", 13)
			bv.add_child(ub)

func _start() -> void:
	if Game.formation().is_empty():
		main.toast("Deploy at least one hero!", UI.RED)
		return
	var err := Game.pay_battle(params)
	if err != "":
		main.toast(err, UI.RED)
		return
	Game.meal_consume(params)
	Game.save_game()
	main.replace("battle", params)
