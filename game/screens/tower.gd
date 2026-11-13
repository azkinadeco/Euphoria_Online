extends Screen
## Tower of Trials: endless floors with rising difficulty and first-clear gems.
## Left: the climb (a lit spine of floors). Right: the current floor's scene, rivals and reward.

const ROW_H := 64
var _scroll: ScrollContainer
var _cur_row: Control

func build() -> void:
	set_bg("galaxy", 0.45)
	ambient(Color(0.75, 0.7, 1.0), 14)
	header("TOWER OF TRIALS", ["gold", "gems"])
	var cur := int(Game.s["tower"]["floor"])
	var b := body(76)

	# ------------------------------------------------------------ climb column
	var lp := UI.panel()
	lp.anchor_right = 0.4
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	var top := UI.hbox(10)
	lv.add_child(top)
	var tb := UI.vbox(0)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tb)
	tb.add_child(UI.label("THE CLIMB", 15, UI.GOLD, 3))
	tb.add_child(UI.label("Best: Floor %d" % (cur - 1) if cur > 1 else "Not climbed yet", 13, UI.MUTED))
	var next_g := cur + (5 - cur % 5) % 5
	var gl := UI.label("Guardian in %d" % (next_g - cur) if next_g != cur else "GUARDIAN NOW", 13, Color("#ff7a8a"), 2)
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(gl)

	var floors := UI.vbox(0)
	floors.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll = UI.scroll(floors)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(_scroll)
	var hi := cur + 6
	var lo := maxi(1, cur - 6)
	for f in range(hi, lo - 1, -1):
		floors.add_child(_floor_row(f, cur, f == hi, f == lo))
	UI.stagger(floors, 0.025)
	_scroll_to_current.call_deferred()

	# ------------------------------------------------------------ floor detail
	var rp := UI.panel()
	rp.anchor_left = 0.42
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var v := UI.vbox(10)
	rp.add_child(v)
	var t := DB.tower_floor(cur)
	var guardian := cur % 5 == 0

	# scene banner: the floor's battlefield behind the title
	var ban := Control.new()
	ban.custom_minimum_size = Vector2(0, 100)
	ban.clip_contents = true
	v.add_child(ban)
	var bt := UI.tex_rect(DB.bg(str(t["bg"])), Vector2.ZERO, true)
	bt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bt.modulate = Color(0.75, 0.7, 0.85)
	ban.add_child(bt)
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.03, 0.01, 0.08, 0.92))
	g.set_color(1, Color(0.03, 0.01, 0.08, 0.05))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 64
	gt.height = 8
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ban.add_child(shade)
	var tv := UI.vbox(0)
	tv.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	tv.offset_left = 18
	tv.offset_right = 520
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	ban.add_child(tv)
	if guardian:
		tv.add_child(UI.label("GUARDIAN FLOOR", 14, Color("#ff7a8a"), 3))
	tv.add_child(UI.label("FLOOR %d" % cur, 34, UI.GOLD, 6))
	tv.add_child(UI.label("Enemy Lv.%d  •  %d foes  •  %s" % [t["level"], t["enemies"].size(), str(t["bg"]).capitalize()], 14, Color(0.9, 0.88, 1.0), 3))

	# threat meter: your power vs theirs
	var ep := Game.enemy_power(t["enemies"])
	var tp := Game.team_power()
	var ratio := float(tp) / maxf(1.0, float(ep))
	var verdict := "FAVORED" if ratio >= 1.15 else ("EVEN FIGHT" if ratio >= 0.9 else ("RISKY" if ratio >= 0.7 else "DEADLY"))
	var vcol: Color = UI.GREEN if ratio >= 1.15 else (UI.GOLD if ratio >= 0.9 else (Color("#ffa04a") if ratio >= 0.7 else UI.RED))
	var th := UI.hbox(10)
	v.add_child(th)
	th.add_child(UI.label("THREAT", 13, UI.MUTED, 2))
	var tbar := UI.bar(minf(ratio, 2.0) * 50.0, 100.0, "", 10)
	tbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tbar.add_theme_stylebox_override("fill", UI.style(vcol, Color.TRANSPARENT, 5, 0, 0))
	tbar.add_theme_stylebox_override("background", UI.style(Color(0, 0, 0, 0.45), Color(1, 1, 1, 0.12), 5, 1, 0))
	th.add_child(tbar)
	th.add_child(UI.label(verdict, 14, vcol, 3))
	v.add_child(UI.label("Your team %s  vs  Enemy %s" % [Game.fmt(tp), Game.fmt(ep)], 13, UI.MUTED))

	# rivals
	var ef := HFlowContainer.new()
	ef.add_theme_constant_override("h_separation", 8)
	ef.add_theme_constant_override("v_separation", 8)
	for e in t["enemies"]:
		ef.add_child(_enemy_card(e))
	v.add_child(ef)

	# rewards
	var rw := UI.styled_panel(Color(0.16, 0.1, 0.04, 0.85), Color("#a07a3a"), 10, 1, 10.0)
	v.add_child(rw)
	var rv := UI.hbox(14)
	rw.add_child(rv)
	var rl := UI.vbox(2)
	rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rl.add_child(UI.label("FIRST CLEAR", 13, UI.GOLD, 2))
	rl.add_child(UI.label("one-time", 11, UI.MUTED))
	rv.add_child(rl)
	var r := {"gems": t["gems"], "gold": t["gold"]}
	for k in t["items"].keys():
		r[k] = t["items"][k]
	var rr := UI.reward_row(r, 36, 16)
	rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_child(rr)
	if not guardian:
		var gt2 := DB.tower_floor(next_g)
		var gv := UI.vbox(0)
		gv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gv.add_child(UI.label("FLOOR %d" % next_g, 12, Color("#ff7a8a"), 2))
		var gh := UI.hbox(4)
		gh.add_child(UI.tex_rect(DB.icon("icon_gem"), Vector2(22, 22)))
		gh.add_child(UI.label("%d" % int(gt2["gems"]), 13, Color.WHITE, 2))
		gh.add_child(UI.tex_rect(DB.icon(DB.ITEMS["summon_ticket"]["icon"]), Vector2(22, 22)))
		gv.add_child(gh)
		rv.add_child(gv)

	v.add_child(_milestones(cur))
	v.add_child(UI.spacer(false))
	var btns := UI.hbox(10)
	v.add_child(btns)
	btns.add_child(UI.button("TEAM", func(): main.go("formation"), "", Vector2(130, 60)))
	btns.get_child(0).tooltip_text = "No energy cost. Each floor can only be cleared once.\nEvery 5th floor has a Guardian and a bonus Summon Ticket."
	var cb := UI.button("⚔ CHALLENGE FLOOR %d" % cur, func(): main.go("formation", {"mode": "tower", "floor": cur}), "GoldButton", Vector2(0, 60))
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(cb)
	UI.fade_in(v, 0.3)

func _floor_row(f: int, cur: int, is_top: bool, is_bottom: bool) -> Control:
	var done := f < cur
	var now := f == cur
	var boss := f % 5 == 0
	var row := UI.hbox(8)
	row.custom_minimum_size = Vector2(0, ROW_H)
	# spine: a vertical line through the floor node; lit up to the current floor
	var spine := Control.new()
	spine.custom_minimum_size = Vector2(46, ROW_H)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lit := Color("#ffd27a")
	var dark := Color(0.35, 0.3, 0.5, 0.6)
	spine.draw.connect(func():
		var cx := 23.0
		var cy := ROW_H * 0.5
		if not is_top:
			spine.draw_line(Vector2(cx, 0), Vector2(cx, cy), lit if f < cur else dark, 3.0)
		if not is_bottom:
			spine.draw_line(Vector2(cx, cy), Vector2(cx, ROW_H), lit if f <= cur else dark, 3.0)
		var rad := 15.0 if boss or now else 11.0
		var fill := Color("#5a1020") if boss else (Color("#3a2a10") if done or now else Color("#1a1030"))
		var edge := Color("#ff6b7d") if boss else (lit if done or now else dark)
		if now:
			spine.draw_circle(Vector2(cx, cy), rad + 5, Color(1, 0.8, 0.4, 0.25))
		spine.draw_circle(Vector2(cx, cy), rad, fill)
		spine.draw_arc(Vector2(cx, cy), rad, 0, TAU, 32, edge, 2.0, true)
		if done:
			spine.draw_polyline(PackedVector2Array([Vector2(cx - 5, cy), Vector2(cx - 1, cy + 4), Vector2(cx + 6, cy - 4)]), UI.GREEN, 2.5, true)
	)
	row.add_child(spine)

	var bg := Color(0.3, 0.2, 0.05, 0.95) if now else (Color(0.22, 0.05, 0.1, 0.85) if boss and not done else Color(0.1, 0.06, 0.18, 0.75 if done else 0.9))
	var bd: Color = UI.GOLD if now else (Color("#ff6b7d") if boss and not done else Color("#4a3a6e"))
	var p := UI.styled_panel(bg, bd, 10, 2 if now else 1, 8)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(p)
	# stone masonry behind the plaque (PanelContainer stacks it under the content)
	var bricks := Control.new()
	bricks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bricks.clip_contents = true
	var mortar := Color(1, 0.85, 0.6, 0.07) if now else (Color(1, 0.4, 0.5, 0.07) if boss and not done else Color(1, 1, 1, 0.045))
	bricks.draw.connect(func():
		var sz := bricks.size
		var bh := 12.0
		var bw := 34.0
		var rows := int(ceil((sz.y + 16.0) / bh))
		for r in rows:
			var y := -8.0 + r * bh
			bricks.draw_line(Vector2(-8, y), Vector2(sz.x + 8, y), mortar, 1.0)
			var off := 0.0 if r % 2 == 0 else bw * 0.5
			var x := -8.0 + off
			while x < sz.x + 8:
				bricks.draw_line(Vector2(x, y), Vector2(x, y + bh), mortar, 1.0)
				x += bw)
	p.add_child(bricks)
	var h := UI.hbox(8)
	p.add_child(h)
	if boss and not done:
		# the guardian's face in a red ring
		var gid: String = DB.tower_floor(f)["enemies"][0]["id"]
		var gp := UI.styled_panel(Color.BLACK, Color("#ff6b7d"), 16, 2, 1)
		gp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gp.add_child(UI.face_rect(gid, Vector2(32, 32)))
		gp.tooltip_text = "Guardian: " + DB.name_of(gid)
		gp.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(gp)
	elif now and not Game.formation().is_empty():
		# your leader stands on the current floor
		var lid: String = Game.formation()[0][0]
		var hd: Dictionary = Game.hero(lid)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(36, 36)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var spr := UI.tex_rect(DB.sprite(lid, int(hd.get("star", 1)), int(hd.get("skin", -1))), Vector2(48, 48), true)
		spr.size = Vector2(48, 48)
		spr.position = Vector2(-6, -12)
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(spr)
		var bob := spr.create_tween().set_loops()
		bob.tween_property(spr, "position:y", -16.0, 0.5).set_trans(Tween.TRANS_SINE)
		bob.tween_property(spr, "position:y", -12.0, 0.5).set_trans(Tween.TRANS_SINE)
		h.add_child(holder)
	else:
		var ic := UI.tex_rect(DB.icon("icon_boss" if boss else "icon_tower"), Vector2(32, 32))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
	var nv := UI.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nv)
	nv.add_child(UI.label("FLOOR %d" % f, 17, Color.WHITE if not done else UI.MUTED, 3))
	nv.add_child(UI.label("CLEARED" if done else ("CURRENT" if now else ("GUARDIAN" if boss else "Lv.%d" % (4 + f * 3))), 11, UI.GREEN if done else (UI.GOLD if now else (Color("#ff7a8a") if boss else UI.MUTED)), 2))
	if not done:
		var gh := UI.hbox(2)
		gh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gh.add_child(UI.tex_rect(DB.icon("icon_gem"), Vector2(20, 20)))
		gh.add_child(UI.label("%d" % (100 if boss else 30), 12, Color.WHITE, 2))
		if boss:
			gh.add_child(UI.tex_rect(DB.icon(DB.ITEMS["summon_ticket"]["icon"]), Vector2(20, 20)))
		h.add_child(gh)
	if done:
		row.modulate.a = 0.7
	if now:
		_cur_row = row
		var tw := p.create_tween().set_loops()
		tw.tween_property(p, "self_modulate", Color(1.25, 1.15, 0.95), 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(p, "self_modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
	return row

func _enemy_card(e: Dictionary) -> Control:
	var boss: bool = e.get("boss", false)
	var fp := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if boss else Color("#6b4a7e"), 8, 2, 1)
	var c := Control.new()
	c.custom_minimum_size = Vector2(84, 100)
	c.clip_contents = true
	fp.add_child(c)
	var face := UI.face_rect(e["id"], Vector2.ZERO)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(face)
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.7)
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -20
	c.add_child(strip)
	var nl := UI.label(DB.name_of(str(e["id"])).split(" ")[0], 11, Color.WHITE, 2)
	nl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nl.offset_top = -20
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	c.add_child(nl)
	var el := UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(str(e["id"])), "elem_light")), Vector2(22, 22))
	el.position = Vector2(60, 2)
	el.size = Vector2(22, 22)
	c.add_child(el)
	var lvl := UI.label("Lv.%d" % int(e.get("level", 1)), 11, Color.WHITE, 3)
	lvl.position = Vector2(4, 62)
	c.add_child(lvl)
	if boss:
		var bl := UI.label("BOSS", 11, Color("#ff7a8a"), 3)
		bl.position = Vector2(4, 2)
		c.add_child(bl)
		var tw := fp.create_tween().set_loops()
		tw.tween_property(fp, "self_modulate", Color(1.4, 0.8, 0.85), 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(fp, "self_modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	fp.tooltip_text = "%s  Lv.%d  %s" % [DB.name_of(str(e["id"])), int(e.get("level", 1)), "★".repeat(int(e.get("star", 1)))]
	return fp

func _scroll_to_current() -> void:
	if _scroll == null or _cur_row == null:
		return
	await get_tree().process_frame
	_scroll.scroll_vertical = maxi(0, int(_cur_row.position.y) - int(_scroll.size.y * 0.5) + ROW_H / 2)

## Milestone chests: a road of 5 nodes (from the first unclaimed one), lit up to the current floor.
func _milestones(cur: int) -> Control:
	var ms: Array = DB.TOWER_MILESTONES
	var first := ms.size() - 1
	for i in ms.size():
		if Game.tower_milestone_state(i) != "claimed":
			first = i
			break
	var start := clampi(first, 0, maxi(0, ms.size() - 5))
	var p := UI.styled_panel(Color(0.08, 0.05, 0.15, 0.9), Color("#6b4a9e"), 12, 1, 10)
	var v := UI.vbox(6)
	p.add_child(v)
	var hh := UI.hbox(8)
	v.add_child(hh)
	hh.add_child(UI.label("MILESTONE CHESTS", 13, UI.GOLD, 2))
	hh.add_child(UI.spacer())
	var ready := Game.tower_milestones_ready()
	hh.add_child(UI.label(("%d READY TO CLAIM" % ready) if ready > 0 else "Floors cleared: %d" % (cur - 1), 12, UI.GREEN if ready > 0 else UI.MUTED, 2))
	var road := UI.hbox(0)
	v.add_child(road)
	var prev := 0 if start == 0 else int(ms[start - 1]["floor"])
	for i in range(start, mini(ms.size(), start + 5)):
		var need := int(ms[i]["floor"])
		var seg := UI.bar(clampi(cur - 1 - prev, 0, need - prev), need - prev, "", 6)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		seg.add_theme_stylebox_override("fill", UI.style(Color("#ffd27a"), Color.TRANSPARENT, 3, 0, 0))
		seg.add_theme_stylebox_override("background", UI.style(Color(1, 1, 1, 0.08), Color.TRANSPARENT, 3, 0, 0))
		seg.custom_minimum_size = Vector2(16, 6)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		road.add_child(seg)
		road.add_child(_milestone_node(i, need, cur))
		prev = need
	return p

func _milestone_node(i: int, need: int, cur: int) -> Control:
	var give: Dictionary = DB.TOWER_MILESTONES[i]["give"]
	var stt := Game.tower_milestone_state(i)
	var key := "gems"
	for k in ["oath_ring", "skin_ticket", "summon_ticket", "gear_chest", "rune_chest", "celestial_gem"]:
		if give.has(k):
			key = k
			break
	var col: Color = UI.GREEN if stt == "ready" else (Color("#ffd27a") if stt == "claimed" else Color("#8a78b8"))
	var nv := UI.vbox(2)
	nv.custom_minimum_size = Vector2(70, 0)
	nv.tooltip_text = "Clear Floor %d:\n%s" % [need, Game.reward_text(give)]
	nv.mouse_filter = Control.MOUSE_FILTER_PASS
	var med := Control.new()
	med.custom_minimum_size = Vector2(70, 56)
	med.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.add_child(med)
	var big := need % 50 == 0
	med.draw.connect(func():
		var c := Vector2(35, 28)
		var r := 25.0 if big else 22.0
		if stt == "ready":
			med.draw_circle(c, r + 6, Color(UI.GREEN, 0.22))
		med.draw_circle(c, r, Color(0.12, 0.08, 0.2) if stt != "claimed" else Color(0.18, 0.13, 0.06))
		med.draw_arc(c, r, 0, TAU, 40, col, 3.0 if big else 2.0, true))
	var ic := UI.tex_rect(Game.reward_icon(key), Vector2(34, 34))
	ic.position = Vector2(18, 11)
	ic.size = Vector2(34, 34)
	if stt == "locked":
		ic.modulate = Color(0.55, 0.5, 0.65)
	elif stt == "claimed":
		ic.modulate = Color(1, 1, 1, 0.45)
	med.add_child(ic)
	if stt == "claimed":
		var ck := UI.label("✓", 20, UI.GREEN, 3)
		ck.position = Vector2(46, 26)
		med.add_child(ck)
	if stt == "ready":
		var chip := UI.styled_panel(Color(0.1, 0.45, 0.25, 0.95), UI.GREEN, 9, 1, 0)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var cl := UI.label("CLAIM F%d" % need, 11, Color.WHITE, 2)
		chip.add_child(UI.margin(cl, 6, 1, 6, 1))
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nv.add_child(chip)
		nv.mouse_filter = Control.MOUSE_FILTER_STOP
		nv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		nv.gui_input.connect(func(ev: InputEvent):
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				var g := Game.claim_tower_milestone(i)
				if not g.is_empty():
					main.show_rewards("TOWER MILESTONE", g)
					main.replace("tower"))
	else:
		var fl := UI.label("F%d" % need, 12, col if stt != "locked" else UI.MUTED, 2)
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nv.add_child(fl)
	if stt == "ready":
		var tw := med.create_tween().set_loops()
		tw.tween_property(med, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(med, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
		med.pivot_offset = Vector2(35, 28)
	return nv
