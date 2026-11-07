extends Screen
## World Boss: a weekly rotating colossal boss. 3 attacks per day, damage adds up
## over the week for milestone rewards and an [AI] ranking (real players come with online mode).

var _right: VBoxContainer
var _tab := "rewards"

func build() -> void:
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
	art.offset_bottom = -150
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
	bot.offset_top = -146
	bot.offset_bottom = -14
	lp.add_child(bot)
	var weak := UI.hbox(8)
	weak.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(str(wb["weak"]), "elem_light")), Vector2(28, 28)))
	weak.add_child(UI.label("WEAKNESS: %s heroes deal +30%% ATK" % wb["weak"], 15, DB.ELEMENT_COLOR.get(str(wb["weak"]), UI.GOLD), 3))
	bot.add_child(weak)
	var st: Dictionary = Game.s["wboss"]
	bot.add_child(UI.label("Weekly damage %s   •   Best hit %s   •   Rank #%d" % [Game.fmt(st["total"]), Game.fmt(st["best"]), Game.wboss_rank()], 14, UI.GOLD, 3))
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
			_tab = key
			main.replace("worldboss"), "GoldButton" if _tab == key else "", Vector2(0, 42))
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
	for i in DB.WB_MILESTONES.size():
		var m: Dictionary = DB.WB_MILESTONES[i]
		var state := Game.wboss_milestone_state(i)
		var p := UI.panel("CardPanel")
		_right.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		var col := UI.vbox(4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		col.add_child(UI.label("Deal %s damage" % Game.fmt(m["dmg"]), 15, Color.WHITE if state != "claimed" else UI.MUTED, 2))
		col.add_child(UI.bar(mini(total, int(m["dmg"])), int(m["dmg"]), "GoldBar", 8))
		col.add_child(UI.reward_row(m["give"], 28, 12))
		if state == "claimed":
			h.add_child(UI.label("✓ CLAIMED", 14, UI.GREEN, 2))
		else:
			var idx := i
			var cb := UI.button("CLAIM", func():
				var r := Game.claim_wboss_milestone(idx)
				if not r.is_empty():
					main.show_rewards("WORLD BOSS REWARD", r)
					main.replace("worldboss"), "GoldButton" if state == "ready" else "", Vector2(110, 46))
			cb.disabled = state != "ready"
			h.add_child(cb)

func _render_rank() -> void:
	_right.add_child(UI.wrap_label("Simulated rivals for now — real players arrive with online mode. Weekly rank rewards: #1 600 Gems + 3 Tickets • Top 3 400 + 2 • Top 10 250 + 1 • others 100 Gems.", 13, UI.MUTED))
	var board := Game.wboss_board()
	for i in board.size():
		var e: Dictionary = board[i]
		var me: bool = e["me"]
		var p := UI.styled_panel(Color(0.2, 0.15, 0.05, 0.9) if me else Color(0.08, 0.06, 0.14, 0.85), UI.GOLD if me else Color("#3d3160"), 8, 2 if me else 1, 6)
		_right.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		var rc := UI.GOLD if i == 0 else (Color("#d8d8e8") if i == 1 else (Color("#e0a070") if i == 2 else UI.MUTED))
		var rl := UI.label("#%d" % (i + 1), 18, rc, 3)
		rl.custom_minimum_size = Vector2(48, 0)
		h.add_child(rl)
		h.add_child(UI.tex_rect(DB.face(e["hero"]), Vector2(36, 36), true))
		var nl := UI.label(e["name"], 15, Color.WHITE, 2)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nl)
		h.add_child(UI.label(Game.fmt(e["dmg"]), 15, UI.GOLD, 2))

func _offer_last_week() -> void:
	if bool(Game.s["wboss"].get("rank_claimed", true)):
		return
	var rk := int(Game.s["wboss"]["last_rank"])
	var r := Game.claim_wboss_rank()
	if not r.is_empty():
		main.show_rewards("LAST WEEK: RANK #%d" % rk, r)
