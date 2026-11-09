extends Screen
## Starlight Rift: weekly roguelite climb. Win a floor → pick 1 of 3 Blessings (they stack).
## The run ends on the first defeat; the best floor counts for milestones and the [AI] ranking.

const RAR_COL := {"R": Color("#9fd0ff"), "SR": Color("#d48cff"), "SSR": Color("#ffd479")}
var _tab := "run"

func build() -> void:
	_tab = str(params.get("tab", _tab))
	var r := Game._rift()
	var fl := DB.rift_floor(int(r["floor"]), Game.day_key() / 7)
	set_bg(str(fl["bg"]), 0.5)
	var fx := FestivalFX.new("firefly", Color("#d4b8ff"), 30)
	add_child(fx)
	move_child(fx, mini(2, get_child_count() - 1))
	header("STARLIGHT RIFT", ["gold", "gems"])
	var b := body(76)

	# ---------------------------------------------------------------- left: current run
	var lp := UI.panel()
	lp.anchor_right = 0.5
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(UI.scroll(lv))
	lv.add_child(UI.label("WEEKLY ROGUELITE CLIMB", 13, Color("#d4b8ff"), 3))
	var alive: bool = r["alive"]
	lv.add_child(UI.label("FLOOR %d" % int(r["floor"]) if alive else "NO ACTIVE RUN", 32, Color.WHITE, 6))
	var days_left := 7 - Game.day_key() % 7
	lv.add_child(UI.label("Best this week: Floor %d   •   Runs: %d   •   Resets in %dd" % [int(r["best"]), int(r["runs"]), days_left], 14, UI.GOLD, 3))
	if alive:
		var nf := UI.label(("BOSS FLOOR — a %s hero awaits!" % str(fl["enemies"][0]["variant"]).capitalize()) if fl["boss"] else "Enemies Lv.%d  •  %d foes" % [fl["level"], fl["enemies"].size()], 14, Color("#ff8a9a") if fl["boss"] else UI.MUTED, 3)
		lv.add_child(nf)
	lv.add_child(_rift_map(int(r["floor"]) if alive else 1, int(r["best"]), alive))
	lv.add_child(_guardian_card(int(r["floor"]) if alive else 1))
	lv.add_child(UI.label("BLESSINGS (%d)" % (r["bless"] as Array).size(), 15, UI.GOLD, 3))
	if (r["bless"] as Array).is_empty():
		lv.add_child(UI.wrap_label("Win a floor to choose your first Blessing. Blessings stack for the whole run.", 13, UI.MUTED))
	else:
		var counts := {}
		for k in r["bless"]:
			counts[k] = int(counts.get(k, 0)) + 1
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		lv.add_child(flow)
		for k in counts.keys():
			var bd: Dictionary = DB.BLESSINGS[k]
			var chip := UI.styled_panel(Color(0.08, 0.05, 0.14, 0.95), RAR_COL[bd["rar"]], 10, 1, 6)
			chip.tooltip_text = bd["desc"]
			chip.add_child(UI.label("%s%s" % [bd["name"], (" x%d" % counts[k]) if int(counts[k]) > 1 else ""], 13, RAR_COL[bd["rar"]], 2))
			flow.add_child(chip)
	var row := UI.hbox(10)
	lv.add_child(row)
	if alive:
		var go := UI.button("⚔ CHALLENGE FLOOR %d" % int(r["floor"]), func(): main.go("formation", {"mode": "rift"}), "GoldButton", Vector2(0, 58))
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(go)
		row.add_child(UI.button("ABANDON", func():
			main.confirm("Abandon this run? Your best floor is kept.", func():
				Game.s["rift"]["alive"] = false
				Game.mark_dirty()
				main.replace("rift"), "ABANDON"), "", Vector2(130, 58)))
	else:
		var st := UI.button("✦ START NEW RUN", func():
			Game.rift_start()
			main.replace("rift"), "GoldButton", Vector2(0, 58))
		st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(st)
	lv.add_child(UI.wrap_label("Each floor gets harder; every 5th floor a variant hero (Mirror, Hollow, Astral or Echo) guards the way. One defeat ends the run — start again any time.", 12, UI.MUTED))

	# ---------------------------------------------------------------- right: milestones / ranking
	var rp := UI.panel()
	rp.anchor_left = 0.52
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	var tabs := UI.hbox(8)
	rv.add_child(tabs)
	for t in [["run", "FLOOR REWARDS"], ["rank", "RANKING [AI]"]]:
		var key: String = t[0]
		var tb := UI.button(t[1], func():
			main.replace("rift", {"tab": key}), "GoldButton" if _tab == key else "", Vector2(0, 42))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tb)
	var list := UI.vbox(6)
	rv.add_child(UI.scroll(list))
	if _tab == "run":
		for i in DB.RIFT_MILESTONES.size():
			var m: Dictionary = DB.RIFT_MILESTONES[i]
			var stt := Game.rift_milestone_state(i)
			var need := int(m["floor"])
			var best := int(Game._rift()["best"])
			var bc := UI.GREEN if stt == "ready" else (Color(1, 1, 1, 0.1) if stt == "claimed" else Color("#d4b8ff", 0.35))
			var p := UI.styled_panel(Color(0.1, 0.07, 0.17, 0.9) if stt != "claimed" else Color(0.07, 0.06, 0.1, 0.8), bc, 12, 2 if stt == "ready" else 1, 8.0)
			list.add_child(p)
			var h := UI.hbox(10)
			p.add_child(h)
			var med := Control.new()
			med.custom_minimum_size = Vector2(46, 46)
			med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var mc: Color = UI.GREEN if stt != "locked" else Color("#d4b8ff")
			var done := stt == "claimed"
			med.draw.connect(func():
				var c := Vector2(23, 23)
				var pts := PackedVector2Array([c + Vector2(0, -21), c + Vector2(21, 0), c + Vector2(0, 21), c + Vector2(-21, 0)])
				med.draw_colored_polygon(pts, Color(mc, 0.18))
				pts.append(pts[0])
				med.draw_polyline(pts, mc, 2.0, true)
				med.draw_string(ThemeDB.fallback_font, Vector2(0, 29), "✓" if done else str(need), HORIZONTAL_ALIGNMENT_CENTER, 46, 15, mc))
			h.add_child(med)
			var col := UI.vbox(3)
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_child(UI.label("Reach Floor %d" % need, 15, Color.WHITE if not done else UI.MUTED, 2))
			col.add_child(UI.reward_row(m["give"], 26, 12))
			if stt == "locked":
				var pb := UI.bar(mini(best, need), need, "", 6)
				pb.add_theme_stylebox_override("fill", UI.style(Color("#d4b8ff"), Color.TRANSPARENT, 3, 0, 0))
				col.add_child(pb)
			h.add_child(col)
			if done:
				var cl := UI.label("CLAIMED", 12, UI.GREEN, 2)
				cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h.add_child(cl)
			elif stt == "ready":
				var idx := i
				var cb := UI.button("CLAIM", func():
					var g := Game.claim_rift_milestone(idx)
					if not g.is_empty():
						main.show_rewards("RIFT REWARD", g)
						main.replace("rift"), "GoldButton", Vector2(100, 42))
				cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h.add_child(cb)
				var tw := cb.create_tween().set_loops()
				tw.tween_property(cb, "modulate", Color(1.25, 1.25, 1.25), 0.5)
				tw.tween_property(cb, "modulate", Color.WHITE, 0.5)
			else:
				var ll := UI.label("%d / %d" % [mini(best, need), need], 13, UI.MUTED, 2)
				ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				ll.custom_minimum_size.x = 60
				ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				h.add_child(ll)
	else:
		list.add_child(UI.wrap_label("Simulated rivals for now — real players arrive with online mode.", 12, UI.MUTED))
		var board := Game.rift_board()
		var pod := UI.hbox(8)
		list.add_child(pod)
		for k in [1, 0, 2]:
			if k < board.size():
				pod.add_child(UI.podium(board[k], k, "Floor %d" % int(board[k]["floor"])))
		for i in board.size():
			if i < 3:
				continue
			var e: Dictionary = board[i]
			var me: bool = e["me"]
			var p := UI.styled_panel(Color(0.2, 0.15, 0.05, 0.9) if me else Color(0.08, 0.06, 0.14, 0.85), UI.GOLD if me else Color("#3d3160"), 8, 2 if me else 1, 6)
			list.add_child(p)
			var h := UI.hbox(10)
			p.add_child(h)
			var rl := UI.label("#%d" % (i + 1), 17, UI.GOLD if me else UI.MUTED, 3)
			rl.custom_minimum_size = Vector2(44, 0)
			h.add_child(rl)
			h.add_child(UI.tex_rect(DB.face(e["hero"]), Vector2(34, 34), true))
			var nl := UI.label(e["name"], 15, Color.WHITE, 2)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(nl)
			h.add_child(UI.label("Floor %d" % int(e["floor"]), 15, UI.GOLD, 2))
	UI.stagger(list, 0.03)
	if not (r["offer"] as Array).is_empty():
		_offer.call_deferred()
	else:
		tutorial("rift")

## 1-of-3 Blessing choice after a win.
func _offer() -> void:
	var r := Game._rift()
	var v: VBoxContainer = main.popup("CHOOSE A BLESSING", 900, false)
	v.get_meta("layer").set_meta("no_back", true)
	v.add_child(UI.label("Floor %d cleared! Blessings last for the rest of this run." % (int(r["floor"]) - 1), 15, UI.GOLD, 3))
	var h := UI.hbox(14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	for k in r["offer"]:
		var key: String = k
		var bd: Dictionary = DB.BLESSINGS[key]
		var col: Color = RAR_COL[bd["rar"]]
		var card := Button.new()
		card.theme_type_variation = "FlatButton"
		card.focus_mode = Control.FOCUS_NONE
		card.custom_minimum_size = Vector2(260, 220)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color(col.r * 0.15, col.g * 0.1, col.b * 0.2 + 0.05, 0.97), col, 14, 2, 0))
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(fr)
		var cv := UI.vbox(8)
		cv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cv.offset_left = 14
		cv.offset_right = -14
		cv.offset_top = 16
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.add_child(cv)
		var rl := UI.label(bd["rar"], 14, col, 3)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(rl)
		var nl := UI.label(bd["name"], 22, Color.WHITE, 4)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(nl)
		var dl := UI.wrap_label(bd["desc"], 15, col.lightened(0.3))
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(dl)
		card.pressed.connect(func():
			if Game.rift_pick(key):
				Game.sfx("awakening")
				main.close_popup(v)
				main.toast("Blessing gained: " + str(bd["name"]), col)
				main.replace("rift"))
		UI.hover_fx(card, 1.04)
		h.add_child(card)
	UI.stagger(h, 0.08)


## A path of the next 10 floors: guardian floors are red diamonds, the current floor glows.
func _rift_map(start: int, best: int, alive: bool) -> Control:
	var first := maxi(1, start - 1)
	var m := Control.new()
	m.custom_minimum_size = Vector2(0, 92)
	var t0 := Time.get_ticks_msec()
	var lilac := Color("#d4b8ff")
	m.draw.connect(func():
		var t := float(Time.get_ticks_msec() - t0) / 1000.0
		var w := m.size.x
		var n := 10
		var step := (w - 40.0) / float(n - 1)
		var f := ThemeDB.fallback_font
		# a gently waving constellation line
		var pos: Array = []
		for i in n:
			pos.append(Vector2(20 + i * step, 40.0 + sin(i * 1.3) * 9.0))
		# faint background stars
		for k in 26:
			var sx := fmod(k * 97.31, w)
			var sy := fmod(k * 41.7, 20.0) + 2.0
			var tw := 0.25 + 0.25 * sin(t * 2.0 + k)
			m.draw_circle(Vector2(sx, sy), 1.1, Color(1, 1, 1, tw))
		for i in n - 1:
			var a: Vector2 = pos[i]
			var b: Vector2 = pos[i + 1]
			var lit := first + i < start
			if lit:
				m.draw_line(a, b, Color(lilac, 0.25), 7.0, true)
				m.draw_line(a, b, lilac, 2.5, true)
				# a spark travelling along cleared links
				var q := fmod(t * 0.6 + i * 0.37, 1.0)
				m.draw_circle(a.lerp(b, q), 2.5, Color(1, 1, 1, 0.9))
			else:
				var segs := 7
				for k in segs:
					if k % 2 == 0:
						m.draw_line(a.lerp(b, float(k) / segs), a.lerp(b, float(k + 1) / segs), Color(1, 1, 1, 0.18), 2.0, true)
		for i in n:
			var fl := first + i
			var c: Vector2 = pos[i]
			var boss := fl % 5 == 0
			var cur := alive and fl == start
			var past := fl < start
			var col := Color("#ff5c6c") if boss else lilac
			if cur:
				var pr := 18.0 + 3.0 * sin(t * 4.0)
				m.draw_circle(c, pr, Color(UI.GOLD, 0.18))
				m.draw_arc(c, pr + 2.0, t * 1.5, t * 1.5 + PI * 1.4, 24, Color(UI.GOLD, 0.8), 2.0, true)
			if boss:
				var r := 12.0
				var pts := PackedVector2Array()
				for k in 8:
					var ang := -PI / 2 + k * PI / 4
					pts.append(c + Vector2(cos(ang), sin(ang)) * (r if k % 2 == 0 else r * 0.45))
				if past or cur:
					m.draw_circle(c, 15.0, Color(col, 0.2))
				m.draw_colored_polygon(pts, col if past else Color(0.18, 0.05, 0.1))
				pts.append(pts[0])
				m.draw_polyline(pts, UI.GOLD if cur else col, 1.8, true)
			else:
				var r2 := 7.0
				var pts2 := PackedVector2Array()
				for k in 8:
					var ang2 := -PI / 2 + k * PI / 4
					pts2.append(c + Vector2(cos(ang2), sin(ang2)) * (r2 if k % 2 == 0 else r2 * 0.5))
				if past:
					m.draw_circle(c, 10.0, Color(lilac, 0.18))
				m.draw_colored_polygon(pts2, Color.WHITE if past else (UI.GOLD if cur else Color(0.14, 0.1, 0.22)))
				pts2.append(pts2[0])
				m.draw_polyline(pts2, UI.GOLD if cur else col, 1.5, true)
			m.draw_string(f, Vector2(c.x - 20, c.y + 32), str(fl), HORIZONTAL_ALIGNMENT_CENTER, 40, 12, UI.GOLD if cur else (col if boss else UI.MUTED))
			if fl == best and best > 0:
				m.draw_string(f, Vector2(c.x - 20, c.y - 20), "BEST", HORIZONTAL_ALIGNMENT_CENTER, 40, 10, UI.GREEN))
	var tk := Timer.new()
	tk.wait_time = 1.0 / 30.0
	tk.autostart = true
	tk.timeout.connect(m.queue_redraw)
	m.add_child(tk)
	return m

## Preview of the next guardian (variant hero) floor: its art in the variant's colors, fading into the card.
func _guardian_card(start: int) -> Control:
	var gf := start if start % 5 == 0 else start + (5 - start % 5)
	var fl := DB.rift_floor(gf, Game.day_key() / 7)
	var e: Dictionary = fl["enemies"][0]
	var variant := str(e.get("variant", ""))
	var red := Color("#ff5c6c")
	var box := Control.new()
	box.custom_minimum_size = Vector2(0, 128)
	box.clip_contents = true
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", UI.style(Color(0.12, 0.03, 0.07, 0.92), Color.TRANSPARENT, 12, 0, 0))
	box.add_child(bg)
	var glow := Control.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.draw.connect(func():
		var c := Vector2(glow.size.x - 90, glow.size.y * 0.5)
		for i in 7:
			glow.draw_circle(c, 110.0 - i * 15.0, Color(red, 0.05)))
	box.add_child(glow)
	var art := UI.tex_rect(DB.art(e["id"]), Vector2.ZERO, true)
	art.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	art.offset_left = -200
	art.offset_right = 0
	art.offset_top = -4
	art.offset_bottom = 270
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.corrupt(art, variant)
	box.add_child(art)
	var shade := Control.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(func():
		var sz := shade.size
		var dk := Color(0.12, 0.03, 0.07, 0.97)
		var cl := Color(0.12, 0.03, 0.07, 0.0)
		var x1 := sz.x - 260.0
		var x2 := sz.x - 120.0
		shade.draw_rect(Rect2(0, 0, x1, sz.y), dk)
		shade.draw_polygon(PackedVector2Array([Vector2(x1, 0), Vector2(x2, 0), Vector2(x2, sz.y), Vector2(x1, sz.y)]), PackedColorArray([dk, cl, cl, dk])))
	box.add_child(shade)
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, Color(red, 0.55), 12, 1, 0))
	box.add_child(frame)
	var v := UI.vbox(3)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_right = -170
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	var away := gf - start
	v.add_child(UI.label("NEXT GUARDIAN  •  FLOOR %d" % gf, 12, Color("#ff8a9a"), 2))
	v.add_child(UI.label("%s %s" % [variant.capitalize(), DB.name_of(e["id"])], 20, Color.WHITE, 4))
	v.add_child(UI.label("Lv.%d  •  %d foes  •  Power %s" % [int(fl["level"]) + 2, (fl["enemies"] as Array).size(), Game.fmt(Game.enemy_power(fl["enemies"]))], 12, UI.TEXT, 2))
	var chip := UI.styled_panel(Color(red, 0.18), Color(red, 0.7), 8, 1, 0)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.add_child(UI.margin(UI.label("THIS FLOOR!" if away == 0 else ("%d floor%s away" % [away, "" if away == 1 else "s"]), 11, Color("#ffb0b8"), 2), 8, 1, 8, 1))
	v.add_child(chip)
	return box
