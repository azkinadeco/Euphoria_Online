extends Screen
## PvP arena vs AI-controlled player teams (asynchronous, Brown Dust style).

var _list: VBoxContainer
var _info: VBoxContainer
var _tab := "CHALLENGERS"

func build() -> void:
	set_bg("ice", 0.55)
	header("ARENA", ["gems", "arena_coin"])
	var b := body(76)
	var lp := UI.panel()
	lp.anchor_right = 0.32
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	_info = UI.vbox(10)
	lp.add_child(UI.scroll(_info))
	var rp := UI.panel()
	rp.anchor_left = 0.34
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(10)
	rp.add_child(rv)
	var hh := UI.hbox(10)
	rv.add_child(hh)
	for tn in ["CHALLENGERS", "RANKING"]:
		var tk: String = tn
		var tb := UI.button(tn, func(): _tab = tk; _render(), "TabButton", Vector2(150, 40))
		tb.toggle_mode = true
		tb.set_meta("key", tn)
		hh.add_child(tb)
	hh.add_child(UI.spacer())
	hh.add_child(UI.button("REFRESH", func():
		Game.s["arena"]["refresh"] = int(Game.s["arena"]["refresh"]) + 1
		Game.mark_dirty()
		_render(), "", Vector2(140, 40)))
	_list = UI.vbox(8)
	rv.add_child(UI.scroll(_list))
	_render()
	var pend: Dictionary = Game.s["arena"].get("pending", {})
	if not pend.is_empty():
		var tier_name := str(Game.s["arena"].get("last_tier", ""))
		main.show_rewards("SEASON REWARD • %s" % tier_name, Game.claim_arena_season())
	tutorial("arena")

func _tier(rp: int) -> String:
	return str(DB.arena_tier(rp)["name"])

func _render() -> void:
	var a: Dictionary = Game.s["arena"]
	for c in _info.get_children():
		c.queue_free()
	var top := UI.hbox(10)
	_info.add_child(top)
	var ic := UI.tex_rect(DB.icon("icon_arena"), Vector2(64, 64))
	top.add_child(ic)
	var tv := UI.vbox(0)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tv)
	tv.add_child(UI.label(_tier(int(a["rp"])), 28, UI.GOLD, 6))
	tv.add_child(UI.label("%d RP" % int(a["rp"]), 18, Color.WHITE, 3))
	var se := maxi(0, Game.arena_season_ends_in())
	var nt := DB.arena_tier(int(a["rp"]))
	_info.add_child(UI.label("Season ends in %dd %02dh  •  reward (%s):" % [se / 86400, (se / 3600) % 24, nt["name"]], 13, Color("#9fd0ff")))
	_info.add_child(UI.reward_row(nt["give"], 24, 13))
	_info.add_child(UI.label("Tickets today: %d / %d" % [int(a["tickets"]), Game.ARENA_TICKETS], 17, UI.GREEN if int(a["tickets"]) > 0 else UI.RED, 3))
	_info.add_child(UI.label("Wins %d  •  Losses %d  •  Power %s" % [int(a["wins"]), int(a["losses"]), Game.fmt(Game.team_power())], 14, UI.MUTED))
	var btns := UI.hbox(8)
	_info.add_child(btns)
	var sb := UI.button("ARENA SHOP", func(): main.go("shop", {"tab": "arena_coin"}), "GoldButton", Vector2(0, 44))
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(sb)
	var fb := UI.button("FORMATION", func(): main.go("formation"), "", Vector2(0, 44))
	fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(fb)
	_info.add_child(UI.wrap_label("Win: +24 RP, 60 Arena Coins, 3,000 Gold. Lose: -12 RP, 15 Arena Coins. Spend coins on Oath Rings and Universal Shards in the Arena Shop.", 12, UI.MUTED))
	_info.add_child(UI.wrap_label("Practice season: rivals are AI commanders until online PvP launches.", 12, Color("#9fd0ff")))

	for tb in find_children("*", "Button", true, false):
		if tb.has_meta("key"):
			tb.button_pressed = tb.get_meta("key") == _tab
	for c in _list.get_children():
		c.queue_free()
	if _tab == "RANKING":
		var rank := 1
		for e in Game.arena_leaderboard():
			var row := UI.styled_panel(Color(0.25, 0.18, 0.05, 0.95) if e["me"] else Color(0.08, 0.05, 0.14, 0.9), UI.GOLD if e["me"] else Color("#3a2f55"), 8, 2 if e["me"] else 1, 6)
			var rh := UI.hbox(10)
			row.add_child(rh)
			var rl := UI.label("#%d" % rank, 18, UI.GOLD if rank <= 3 else Color.WHITE, 3)
			rl.custom_minimum_size = Vector2(50, 0)
			rh.add_child(rl)
			var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(e["hero"])], 6, 1, 1)
			fp.add_child(UI.tex_rect(DB.face(e["hero"]), Vector2(34, 34), true))
			rh.add_child(fp)
			var nl := UI.label(str(e["name"]) + ("  (You)" if e["me"] else "  [AI]"), 16, UI.GREEN if e["me"] else Color.WHITE, 2)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rh.add_child(nl)
			rh.add_child(UI.label(_tier(int(e["rp"])), 13, UI.MUTED))
			rh.add_child(UI.label("%d RP" % int(e["rp"]), 16, UI.GOLD, 2))
			_list.add_child(row)
			rank += 1
		UI.stagger(_list, 0.02)
		return
	var opps := Game.arena_opponents()
	for i in opps.size():
		var o: Dictionary = opps[i]
		var oi: int = i
		var p := UI.panel("CardPanel")
		_list.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		var v := UI.vbox(2)
		v.custom_minimum_size = Vector2(190, 0)
		v.add_child(UI.label(str(o["name"]) + "  [AI]", 18, Color.WHITE, 2))
		v.add_child(UI.label("%s • %d RP" % [_tier(int(o["rp"])), int(o["rp"])], 13, UI.GOLD))
		var pc := UI.GREEN if Game.team_power() >= int(o["power"]) else Color("#ff8a9a")
		v.add_child(UI.label("Power %s" % Game.fmt(o["power"]), 14, pc))
		h.add_child(v)
		var faces := UI.hbox(4)
		faces.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for u in o["team"]:
			var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(u["id"])], 6, 2, 1)
			fp.add_child(UI.tex_rect(DB.face(u["id"]), Vector2(50, 50), true))
			faces.add_child(fp)
		h.add_child(faces)
		var btn := UI.button("BATTLE", func(): main.go("formation", {"mode": "arena", "opp": oi}), "GoldButton", Vector2(120, 50))
		btn.disabled = int(a["tickets"]) <= 0
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(btn)
	UI.stagger(_list, 0.06)
