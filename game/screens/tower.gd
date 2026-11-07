extends Screen
## Tower of Trials: endless floors with rising difficulty and first-clear gems.

func build() -> void:
	set_bg("galaxy", 0.45)
	header("TOWER OF TRIALS", ["gold", "gems"])
	var cur := int(Game.s["tower"]["floor"])
	var b := body(76)
	var lp := UI.panel()
	lp.anchor_right = 0.4
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var floors := UI.vbox(8)
	lp.add_child(UI.scroll(floors))
	for f in range(cur + 4, maxi(0, cur - 6), -1):
		var p := UI.styled_panel(Color(0.1, 0.06, 0.18, 0.9) if f != cur else Color(0.3, 0.2, 0.05, 0.95), UI.GOLD if f == cur else Color("#4a3a6e"), 10, 2 if f == cur else 1, 12)
		var h := UI.hbox(10)
		p.add_child(h)
		h.add_child(UI.tex_rect(DB.icon("icon_tower" if f % 5 != 0 else "icon_boss"), Vector2(40, 40)))
		h.add_child(UI.label("FLOOR %d" % f, 20, Color.WHITE if f >= cur else UI.MUTED, 3))
		h.add_child(UI.spacer())
		h.add_child(UI.label("CLEARED" if f < cur else ("CURRENT" if f == cur else ("BOSS" if f % 5 == 0 else "")), 14, UI.GREEN if f < cur else UI.GOLD, 3))
		floors.add_child(p)

	var rp := UI.panel()
	rp.anchor_left = 0.42
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var v := UI.vbox(10)
	rp.add_child(v)
	var t := DB.tower_floor(cur)
	v.add_child(UI.label("FLOOR %d%s" % [cur, "  •  GUARDIAN" if cur % 5 == 0 else ""], 28, UI.GOLD, 5))
	v.add_child(UI.label("Enemy level %d  •  Power %s  •  Your team %s" % [t["level"], Game.fmt(Game.enemy_power(t["enemies"])), Game.fmt(Game.team_power())], 15, UI.MUTED))
	var ef := HFlowContainer.new()
	ef.add_theme_constant_override("h_separation", 8)
	for e in t["enemies"]:
		var fp := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if e.get("boss", false) else Color("#6b4a7e"), 8, 2, 1)
		fp.add_child(UI.tex_rect(DB.face(e["id"]), Vector2(72, 72), true))
		ef.add_child(fp)
	v.add_child(ef)
	v.add_child(UI.label("FIRST CLEAR REWARD", 15, UI.GOLD, 3))
	var r := {"gems": t["gems"], "gold": t["gold"]}
	for k in t["items"].keys():
		r[k] = t["items"][k]
	v.add_child(UI.reward_row(r, 36, 16))
	v.add_child(UI.wrap_label("No energy cost. Each floor can only be cleared once. Every 5th floor has a Guardian and bonus Summon Ticket.", 14, UI.MUTED))
	v.add_child(UI.spacer(false))
	v.add_child(UI.button("⚔ CHALLENGE FLOOR %d" % cur, func(): main.go("formation", {"mode": "tower", "floor": cur}), "GoldButton", Vector2(0, 60)))
