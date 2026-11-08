extends Screen
## World Boss: a weekly rotating colossal boss. 3 attacks per day, damage adds up
## over the week for milestone rewards and an [AI] ranking (real players come with online mode).

var _right: VBoxContainer
var _tab := "rewards"

func build() -> void:
	_tab = str(params.get("tab", _tab))
	var wb := Game.wboss()
	set_bg(str(wb["bg"]), 0.5)
	ambient(Color(0.85, 0.5, 1.0), 26)
	header("WORLD BOSS", ["gold", "gems"])
	var b := body(76)

	# ---------------------------------------------------------------- left: the boss
	var lp := Panel.new()
	lp.add_theme_stylebox_override("panel", UI.style(Color(0.06, 0.02, 0.09, 0.92), Color("#b072ff"), 14, 2, 0))
	lp.anchor_right = 0.5
	lp.anchor_bottom = 1.0
	lp.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	b.add_child(lp)
	var bgt := UI.tex_rect(DB.bg(str(wb["bg"])), Vector2.ZERO, true)
	bgt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bgt.modulate = Color(0.45, 0.35, 0.5)
	lp.add_child(bgt)
	var art := UI.tex_rect(DB.art(wb["id"], 0))
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_top = 70
	art.offset_bottom = -172
	UI.corrupt(art)
	lp.add_child(art)
	var bob := art.create_tween().set_loops()
	bob.tween_property(art, "position:y", art.position.y - 8.0, 1.8).set_trans(Tween.TRANS_SINE)
	bob.tween_property(art, "position:y", art.position.y, 1.8).set_trans(Tween.TRANS_SINE)

	var top := UI.vbox(2)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_top = 12
	top.offset_right = -18
	lp.add_child(top)
	top.add_child(UI.label("THIS WEEK'S WORLD BOSS", 13, Color("#d48cff"), 3))
	top.add_child(UI.label(str(wb["name"]), 28, Color.WHITE, 6))
	var ends := UI.label("", 13, UI.MUTED, 3)
	top.add_child(ends)
	var secs := Game.weekly_ends_in()
	ends.text = "Ends in %dd %dh  •  New boss every week" % [secs / 86400, (secs / 3600) % 24]

	var bot := UI.vbox(8)
	bot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_left = 18
	bot.offset_right = -18
	bot.offset_top = -170
	bot.offset_bottom = -14
	lp.add_child(bot)
	var weak := UI.hbox(8)
	weak.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(str(wb["weak"]), "elem_light")), Vector2(28, 28)))
	weak.add_child(UI.label("WEAKNESS: %s heroes deal +30%% ATK" % wb["weak"], 15, DB.ELEMENT_COLOR.get(str(wb["weak"]), UI.GOLD), 3))
	bot.add_child(weak)
	var st: Dictionary = Game.s["wboss"]
	var chips := UI.hbox(6)
	bot.add_child(chips)
	for c in [["WEEKLY DMG", Game.fmt(st["total"]), UI.GOLD], ["BEST HIT", Game.fmt(st["best"]), Color("#ff9a7a")], ["RANK", "#%d" % Game.wboss_rank(), Color("#d48cff")]]:
		chips.add_child(_stat_chip(c[0], c[1], c[2]))
	var pips := UI.hbox(5)
	pips.size_flags_horizontal = Control.SIZE_SHRINK_END
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for k in DB.WB_TRIES:
		var on := k < int(st["tries"])
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.add_theme_stylebox_override("panel", UI.style(Color("#ffcf5a") if on else Color(1, 1, 1, 0.08), Color("#ffe9a8") if on else Color(1, 1, 1, 0.25), 7, 1, 0))
		pips.add_child(pip)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips.add_child(sp)
	chips.add_child(pips)
	var ab := UI.button("⚔ CHALLENGE  (%d/%d left today)" % [int(st["tries"]), DB.WB_TRIES], func(): main.go("formation", {"mode": "wboss"}), "GoldButton", Vector2(0, 58))
	ab.disabled = int(st["tries"]) <= 0
	bot.add_child(ab)
	if not ab.disabled:
		var pt := ab.create_tween().set_loops()
		pt.tween_property(ab, "modulate", Color(1.2, 1.15, 1.25), 0.7)
		pt.tween_property(ab, "modulate", Color.WHITE, 0.7)

	# ---------------------------------------------------------------- right: rewards / ranking
	var rp := UI.panel()
	rp.anchor_left = 0.52
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	var tabs := UI.hbox(8)
	rv.add_child(tabs)
	for t in [["rewards", "DAMAGE REWARDS"], ["rank", "RANKING [AI]"]]:
		var key: String = t[0]
		var tb := UI.button(t[1], func():
			main.replace("worldboss", {"tab": key}), "GoldButton" if _tab == key else "", Vector2(0, 42))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tb)
	_right = UI.vbox(8)
	rv.add_child(UI.scroll(_right))
	if _tab == "rewards":
		_render_rewards()
	else:
		_render_rank()
	UI.stagger(_right, 0.04)
	_offer_last_week()
	tutorial("worldboss")

func _render_rewards() -> void:
	var total := int(Game.s["wboss"]["total"])
	var n := DB.WB_MILESTONES.size()
	var got := 0
	var ready := 0
	var next_i := -1
	for i in n:
		var stt := Game.wboss_milestone_state(i)
		if stt == "claimed":
			got += 1
		elif stt == "ready":
			ready += 1
		elif next_i < 0:
			next_i = i
	# summary strip
	var sp := UI.styled_panel(Color(0.12, 0.05, 0.16, 0.92), Color("#b072ff", 0.6), 10, 1, 8.0)
	_right.add_child(sp)
	var sh := UI.hbox(10)
	sp.add_child(sh)
	sh.add_child(UI.tex_rect(DB.icon("icon_boss"), Vector2(34, 34)))
	var sv := UI.vbox(2)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sv)
	if next_i >= 0:
		var need := int(DB.WB_MILESTONES[next_i]["dmg"])
		sv.add_child(UI.label("%s more damage to Tier %s" % [Game.fmt(need - total), ROMAN[next_i]], 14, Color.WHITE, 2))
	else:
		sv.add_child(UI.label("Every tier reached this week!", 14, UI.GREEN, 2))
	sv.add_child(UI.label("%d / %d tiers claimed%s" % [got, n, ("   •   %d ready" % ready) if ready > 0 else ""], 12, UI.GREEN if ready > 0 else UI.MUTED, 2))
	var track := _tier_track(total)
	sv.add_child(track)
	for i in n:
		var m: Dictionary = DB.WB_MILESTONES[i]
		var state := Game.wboss_milestone_state(i)
		var need := int(m["dmg"])
		var done := state == "claimed"
		var bc := UI.GREEN if state == "ready" else (Color(1, 1, 1, 0.1) if done else Color("#b072ff", 0.35))
		var p := UI.styled_panel(Color(0.1, 0.05, 0.15, 0.9) if not done else Color(0.06, 0.05, 0.09, 0.8), bc, 12, 2 if state == "ready" else 1, 8.0)
		_right.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		var med := Control.new()
		med.custom_minimum_size = Vector2(46, 46)
		med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var mc: Color = UI.GREEN if state != "locked" else (Color("#ff8a5c") if i == next_i else Color("#b072ff"))
		var txt: String = "✓" if done else ROMAN[i]
		med.draw.connect(func():
			var c := Vector2(23, 23)
			var pts := PackedVector2Array()
			for k in 6:
				pts.append(c + Vector2.from_angle(PI / 6.0 + k * TAU / 6.0) * 21.0)
			med.draw_colored_polygon(pts, Color(mc, 0.18))
			pts.append(pts[0])
			med.draw_polyline(pts, mc, 2.0, true)
			med.draw_string(ThemeDB.fallback_font, Vector2(0, 29), txt, HORIZONTAL_ALIGNMENT_CENTER, 46, 15, mc))
		h.add_child(med)
		var col := UI.vbox(3)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		var tl := UI.hbox(6)
		col.add_child(tl)
		tl.add_child(UI.label("Deal %s damage" % Game.fmt(need), 15, Color.WHITE if not done else UI.MUTED, 2))
		if i == next_i:
			tl.add_child(_pill("NEXT", Color("#ff8a5c")))
		var rr := UI.reward_row(m["give"], 26, 12)
		rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(rr)
		if state == "locked":
			var pb := UI.bar(mini(total, need), need, "", 6)
			pb.add_theme_stylebox_override("fill", UI.style(Color("#ff8a5c") if i == next_i else Color("#b072ff"), Color.TRANSPARENT, 3, 0, 0))
			col.add_child(pb)
		if done:
			var cl := UI.label("CLAIMED", 12, UI.GREEN, 2)
			cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(cl)
		elif state == "ready":
			var idx := i
			var cb := UI.button("CLAIM", func():
				var r := Game.claim_wboss_milestone(idx)
				if not r.is_empty():
					main.show_rewards("WORLD BOSS REWARD", r)
					main.replace("worldboss"), "GoldButton", Vector2(100, 42))
			cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(cb)
			var tw := cb.create_tween().set_loops()
			tw.tween_property(cb, "modulate", Color(1.25, 1.25, 1.25), 0.5)
			tw.tween_property(cb, "modulate", Color.WHITE, 0.5)
		else:
			var ll := UI.label("%d%%" % int(100.0 * float(mini(total, need)) / float(need)), 13, UI.MUTED, 2)
			ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ll.custom_minimum_size.x = 48
			ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			h.add_child(ll)

const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

## One bar split into tiers: each segment fills toward its milestone.
func _tier_track(total: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 12)
	c.draw.connect(func():
		var n := DB.WB_MILESTONES.size()
		var w := c.size.x
		var gap := 4.0
		var sw := (w - gap * (n - 1)) / float(n)
		var prev := 0
		for i in n:
			var need := int(DB.WB_MILESTONES[i]["dmg"])
			var f := clampf(float(total - prev) / float(maxi(1, need - prev)), 0.0, 1.0)
			var x := i * (sw + gap)
			c.draw_rect(Rect2(x, 3, sw, 6), Color(1, 1, 1, 0.08))
			if f > 0.0:
				c.draw_rect(Rect2(x, 3, sw * f, 6), UI.GREEN if f >= 1.0 else Color("#ff8a5c"))
			prev = need)
	return c

func _pill(t: String, col: Color) -> Control:
	var p := UI.styled_panel(Color(col, 0.2), col, 8, 1, 2)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := UI.label(t, 10, col, 0)
	p.add_child(l)
	l.add_theme_constant_override("margin_left", 6)
	return p

func _stat_chip(title: String, val: String, col: Color) -> Control:
	var p := UI.styled_panel(Color(0, 0, 0, 0.55), Color(col, 0.5), 8, 1, 4.0)
	var v := UI.vbox(0)
	p.add_child(v)
	v.add_child(UI.label(title, 10, UI.MUTED, 2))
	v.add_child(UI.label(val, 16, col, 3))
	p.custom_minimum_size.x = 96
	return p

const RANK_TIERS := [[1, "600 Gems + 3 Tickets"], [3, "400 Gems + 2 Tickets"], [10, "250 Gems + 1 Ticket"], [99, "100 Gems"]]

func _render_rank() -> void:
	var board := Game.wboss_board()
	var my := Game.wboss_rank()
	# podium for the top 3
	var pod := UI.hbox(8)
	_right.add_child(pod)
	for k in [1, 0, 2]:
		if k >= board.size():
			continue
		pod.add_child(UI.podium(board[k], k, Game.fmt(board[k]["dmg"])))
	# my reward tier
	var tier_txt := ""
	for t in RANK_TIERS:
		if my <= int(t[0]):
			tier_txt = t[1]
			break
	var mp := UI.styled_panel(Color(0.2, 0.15, 0.05, 0.9), UI.GOLD, 10, 1, 8.0)
	_right.add_child(mp)
	var mh := UI.hbox(8)
	mp.add_child(mh)
	mh.add_child(UI.tex_rect(DB.icon("icon_gem"), Vector2(26, 26)))
	var ml := UI.wrap_label("You are #%d — this week's reward: %s" % [my, tier_txt], 13, UI.GOLD)
	ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(ml)
	for i in board.size():
		if i < 3:
			continue
		var e: Dictionary = board[i]
		var me: bool = e["me"]
		var p := UI.styled_panel(Color(0.2, 0.15, 0.05, 0.9) if me else Color(0.08, 0.06, 0.14, 0.85), UI.GOLD if me else Color("#3d3160"), 8, 2 if me else 1, 6)
		_right.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		var rl := UI.label("#%d" % (i + 1), 17, UI.GOLD if me else (Color("#c9a6ff") if i < 10 else UI.MUTED), 3)
		rl.custom_minimum_size = Vector2(44, 0)
		h.add_child(rl)
		h.add_child(UI.tex_rect(DB.face(e["hero"]), Vector2(34, 34), true))
		var nl := UI.label(e["name"], 15, Color.WHITE, 2)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nl)
		h.add_child(UI.label(Game.fmt(e["dmg"]), 15, UI.GOLD, 2))
	_right.add_child(UI.wrap_label("Simulated rivals for now — real players arrive with online mode.", 11, UI.MUTED))

func _offer_last_week() -> void:
	if bool(Game.s["wboss"].get("rank_claimed", true)):
		return
	var rk := int(Game.s["wboss"]["last_rank"])
	var r := Game.claim_wboss_rank()
	if not r.is_empty():
		main.show_rewards("LAST WEEK: RANK #%d" % rk, r)
