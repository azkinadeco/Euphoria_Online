extends Screen
## PvP arena vs AI-controlled player teams (asynchronous, Brown Dust style).

var _list: VBoxContainer
var _info: VBoxContainer
var _foot: PanelContainer
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
	var sc := UI.scroll(_list)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(sc)
	_foot = UI.styled_panel(Color(0.05, 0.03, 0.1, 0.92), Color(UI.GOLD, 0.35), 12, 1, 8)
	rv.add_child(_foot)
	_render()
	var pend: Dictionary = Game.s["arena"].get("pending", {})
	if not pend.is_empty():
		var tier_name := str(Game.s["arena"].get("last_tier", ""))
		main.show_rewards("SEASON REWARD • %s" % tier_name, Game.claim_arena_season())
	tutorial("arena")

const TIER_COL := {"LEGEND": Color("#ff8af0"), "DIAMOND": Color("#7fe3ff"), "PLATINUM": Color("#b8f0d8"),
	"GOLD": Color("#ffd27a"), "SILVER": Color("#d0d4e4"), "BRONZE": Color("#d8945a")}

## Season ladder: progress to the next tier, then every tier with its season reward.
func _render_ladder(rp: int) -> void:
	var cur := DB.arena_tier(rp)
	var idx := DB.ARENA_TIERS.find(cur)
	_info.add_child(UI.label("SEASON TIERS  •  reward at season end", 13, UI.GOLD, 2))
	if idx > 0:
		var nx: Dictionary = DB.ARENA_TIERS[idx - 1]
		var lo := int(cur["rp"])
		var hi := int(nx["rp"])
		var pb := UI.bar(rp - lo, hi - lo, "", 8)
		pb.add_theme_stylebox_override("fill", UI.style(TIER_COL[nx["name"]], Color.TRANSPARENT, 4, 0, 0))
		_info.add_child(pb)
		_info.add_child(UI.label("%d RP to %s" % [hi - rp, nx["name"]], 12, TIER_COL[nx["name"]]))
	var box := UI.vbox(3)
	_info.add_child(box)
	for t in DB.ARENA_TIERS:
		var here: bool = t == cur
		var col: Color = TIER_COL[t["name"]]
		var p := UI.styled_panel(Color(col.r * 0.25, col.g * 0.2, col.b * 0.3, 0.9) if here else Color(0.08, 0.05, 0.14, 0.6), col if here else Color(1, 1, 1, 0.08), 8, 2 if here else 1, 3)
		box.add_child(p)
		var h := UI.hbox(6)
		p.add_child(h)
		var dot := UI.label("◆", 13, col, 2)
		h.add_child(dot)
		var nl := UI.label(t["name"], 13, col if here or rp >= int(t["rp"]) else UI.MUTED, 2)
		nl.custom_minimum_size.x = 84
		h.add_child(nl)
		var rl := UI.label("%d+" % int(t["rp"]) if int(t["rp"]) > 0 else "—", 11, UI.MUTED)
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(rl)
		h.add_child(UI.tex_rect(DB.icon("icon_gem"), Vector2(18, 18)))
		var gl := UI.label(str(int(t["give"].get("gems", 0))), 12, Color.WHITE, 2)
		gl.custom_minimum_size.x = 34
		h.add_child(gl)
		var th := UI.hbox(2)
		th.custom_minimum_size.x = 42
		if t["give"].has("summon_ticket"):
			th.add_child(UI.tex_rect(DB.icon("icon_ticket"), Vector2(18, 18)))
			th.add_child(UI.label("x%d" % int(t["give"]["summon_ticket"]), 12, Color.WHITE, 2))
		h.add_child(th)
		p.tooltip_text = "Season reward: " + ", ".join(t["give"].keys().map(func(k): return "%s x%d" % [DB.ITEMS[k]["name"] if DB.ITEMS.has(k) else str(k).capitalize(), int(t["give"][k])]))
		if here:
			var tw := p.create_tween().set_loops()
			tw.tween_property(p, "self_modulate", Color(1.2, 1.2, 1.2), 1.0).set_trans(Tween.TRANS_SINE)
			tw.tween_property(p, "self_modulate", Color.WHITE, 1.0).set_trans(Tween.TRANS_SINE)

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
	_info.add_child(UI.label("Season ends in %dd %02dh" % [se / 86400, (se / 3600) % 24], 13, Color("#9fd0ff")))
	_info.add_child(UI.label("Tickets today: %d / %d" % [int(a["tickets"]), Game.ARENA_TICKETS], 17, UI.GREEN if int(a["tickets"]) > 0 else UI.RED, 3))
	_info.add_child(UI.label("Wins %d  •  Losses %d  •  Power %s" % [int(a["wins"]), int(a["losses"]), Game.fmt(Game.team_power())], 14, UI.MUTED))
	var btns := UI.hbox(8)
	_info.add_child(btns)
	var sb := UI.button("ARENA SHOP", func(): main.go("shop", {"tab": "arena_coin"}), "GoldButton", Vector2(0, 44))
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(sb)
	var wl := UI.label("Win +24 RP, 60 coins  •  Lose -12 RP", 12, UI.MUTED)
	wl.tooltip_text = "Practice season: rivals are AI commanders until online PvP launches.\nWin: +24 RP, 60 Arena Coins, 3,000 Gold. Lose: -12 RP, 15 Arena Coins. Spend coins on Oath Rings and Universal Shards in the Arena Shop."
	wl.mouse_filter = Control.MOUSE_FILTER_PASS
	_info.add_child(wl)
	_render_ladder(int(a["rp"]))

	for tb in find_children("*", "Button", true, false):
		if tb.has_meta("key"):
			tb.button_pressed = tb.get_meta("key") == _tab
	for c in _list.get_children():
		c.queue_free()
	if _tab == "RANKING":
		_foot.visible = false
		_render_ranking()
		return
	_foot.visible = true
	_render_foot()
	var opps := Game.arena_opponents()
	for i in opps.size():
		_list.add_child(_opp_card(opps[i], i, int(a["tickets"]) > 0))
	UI.stagger(_list, 0.06)

## Difficulty from the power ratio (rival / you).
func _difficulty(opp_power: int) -> Array:
	var r := float(opp_power) / float(maxi(1, Game.team_power()))
	if r < 0.9:
		return ["EASY", UI.GREEN]
	if r < 1.15:
		return ["EVEN", UI.GOLD]
	return ["HARD", Color("#ff6b7f")]

## One challenger: leader portrait, name + tier, power vs yours, team faces, win rewards, BATTLE.
func _opp_card(o: Dictionary, oi: int, can_fight: bool) -> Control:
	var team: Array = o["team"]
	var lead: Dictionary = team[0]
	var best := -1
	for u in team:
		var pw := DB.power_of(DB.stats_for(u["id"], int(u["level"]), int(u["star"])))
		if pw > best:
			best = pw
			lead = u
	var tier := _tier(int(o["rp"]))
	var tcol: Color = TIER_COL.get(tier, UI.GOLD)
	var diff := _difficulty(int(o["power"]))
	var dcol: Color = diff[1]
	var lcol: Color = DB.ELEMENT_COLOR.get(DB.element_of(lead["id"]), UI.GOLD)
	var card := UI.styled_panel(Color(0.07, 0.04, 0.12, 0.94), Color(dcol, 0.45), 14, 1, 0)
	card.custom_minimum_size = Vector2(0, 112)
	var h := UI.hbox(12)
	card.add_child(UI.margin(h, 0, 0, 12, 0))
	# leader portrait: upper body of the strongest rival, fading into the card
	var clip := Control.new()
	clip.clip_contents = true
	clip.custom_minimum_size = Vector2(100, 112)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(clip)
	var glow := ColorRect.new()
	glow.color = Color(lcol, 0.22)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(glow)
	var art := UI.tex_rect(DB.art(lead["id"]), Vector2.ZERO, true)
	art.position = Vector2(0, 2)
	art.size = Vector2(100, 210)
	clip.add_child(art)
	var fade := TextureRect.new()
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(0.07, 0.04, 0.12, 0.0))
	gr.set_color(1, Color(0.07, 0.04, 0.12, 0.95))
	gt.gradient = gr
	gt.fill_from = Vector2(0.55, 0)
	gt.fill_to = Vector2(1, 0)
	fade.texture = gt
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fade)
	var stripe := ColorRect.new()
	stripe.color = tcol
	stripe.anchor_bottom = 1.0
	stripe.offset_right = 4
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(stripe)
	# name, tier, power comparison
	var v := UI.vbox(3)
	v.custom_minimum_size = Vector2(176, 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var nh := UI.hbox(6)
	v.add_child(nh)
	nh.add_child(UI.label(str(o["name"]), 18, Color.WHITE, 3))
	var ai := UI.styled_panel(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.2), 5, 1, 0)
	ai.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ai.add_child(UI.margin(UI.label("AI", 9, UI.MUTED, 1), 4, 0, 4, 0))
	nh.add_child(ai)
	var th := UI.hbox(6)
	v.add_child(th)
	var tchip := UI.styled_panel(Color(tcol, 0.16), Color(tcol, 0.7), 8, 1, 2)
	tchip.add_child(UI.margin(UI.label("◆ " + tier, 11, tcol, 2), 6, 0, 6, 0))
	th.add_child(tchip)
	th.add_child(UI.label("%d RP" % int(o["rp"]), 12, UI.TEXT, 1))
	var mine := Game.team_power()
	var ph := UI.hbox(6)
	v.add_child(ph)
	ph.add_child(UI.label("⚔ " + Game.fmt(o["power"]), 15, dcol.lightened(0.15), 2))
	ph.add_child(UI.label("vs " + Game.fmt(mine), 11, UI.MUTED, 1))
	var cmp := UI.bar(mine, mine + int(o["power"]), "", 6)
	cmp.custom_minimum_size.x = 168
	cmp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cmp.add_theme_stylebox_override("fill", UI.style(Color("#6fd3ff"), Color.TRANSPARENT, 3, 0, 0))
	cmp.add_theme_stylebox_override("background", UI.style(Color(dcol, 0.55), Color.TRANSPARENT, 3, 0, 0))
	cmp.tooltip_text = "Blue = your team power, colored = rival power"
	cmp.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(cmp)
	# team faces
	var tv := UI.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(tv)
	tv.add_child(UI.label("TEAM  •  Lv.%d" % int(lead["level"]), 11, UI.MUTED, 1))
	var faces := UI.hbox(4)
	tv.add_child(faces)
	for u in team:
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(u["id"])], 7, 2 if u == lead else 1, 1)
		fp.tooltip_text = "%s  •  %s  •  %d★" % [DB.name_of(u["id"]), DB.element_of(u["id"]).capitalize(), int(u["star"])]
		fp.mouse_filter = Control.MOUSE_FILTER_PASS
		var fc := Control.new()
		fc.custom_minimum_size = Vector2(40, 40)
		fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fp.add_child(fc)
		var ft := UI.face_rect(u["id"], Vector2(40, 40))
		ft.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fc.add_child(ft)
		var el := UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(DB.element_of(u["id"]), "elem_light")), Vector2(14, 14))
		el.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		el.offset_left = -14
		el.offset_top = -14
		fc.add_child(el)
		faces.add_child(fp)
	# difficulty, win rewards, battle
	var rv := UI.vbox(5)
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(rv)
	var dh := UI.hbox(6)
	dh.alignment = BoxContainer.ALIGNMENT_END
	rv.add_child(dh)
	var dchip := UI.styled_panel(Color(dcol, 0.18), dcol, 8, 1, 2)
	dchip.add_child(UI.margin(UI.label(diff[0], 12, dcol, 2), 8, 0, 8, 0))
	dh.add_child(dchip)
	var wr := UI.hbox(4)
	wr.alignment = BoxContainer.ALIGNMENT_END
	wr.tooltip_text = "Win: +24 RP, 60 Arena Coins, 3,000 Gold\nLose: -12 RP, 15 Arena Coins"
	wr.mouse_filter = Control.MOUSE_FILTER_PASS
	rv.add_child(wr)
	wr.add_child(UI.label("+24 RP", 12, UI.GREEN, 2))
	wr.add_child(UI.tex_rect(DB.icon("icon_arena"), Vector2(18, 18)))
	wr.add_child(UI.label("60", 12, Color.WHITE, 2))
	wr.add_child(UI.tex_rect(DB.icon("icon_gold"), Vector2(18, 18)))
	wr.add_child(UI.label("3K", 12, Color.WHITE, 2))
	var btn := UI.button("BATTLE", func(): main.go("formation", {"mode": "arena", "opp": oi}), "GoldButton", Vector2(124, 44))
	btn.disabled = not can_fight
	if not can_fight:
		btn.tooltip_text = "No tickets left today"
	else:
		UI.hover_fx(btn)
	rv.add_child(btn)
	return card

## Footer: your current team, its power and the tickets left, with a shortcut to Formation.
func _render_foot() -> void:
	for c in _foot.get_children():
		c.queue_free()
	var a: Dictionary = Game.s["arena"]
	var h := UI.hbox(10)
	_foot.add_child(h)
	var lv := UI.vbox(0)
	lv.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(lv)
	lv.add_child(UI.label("YOUR TEAM", 13, UI.GOLD, 2))
	lv.add_child(UI.label("⚔ " + Game.fmt(Game.team_power()), 16, Color("#6fd3ff"), 2))
	var faces := UI.hbox(4)
	faces.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(faces)
	for e in Game.formation():
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(e[0])], 7, 1, 1)
		fp.add_child(UI.face_rect(e[0], Vector2(34, 34), int(Game.hero(e[0]).get("skin", 0))))
		faces.add_child(fp)
	h.add_child(UI.spacer())
	var tk := int(a["tickets"])
	var tv := UI.vbox(2)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(tv)
	var tl := UI.label("TICKETS", 11, UI.MUTED, 1)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tv.add_child(tl)
	var pips := UI.hbox(3)
	pips.alignment = BoxContainer.ALIGNMENT_END
	tv.add_child(pips)
	for i in Game.ARENA_TICKETS:
		var pip := UI.styled_panel(UI.GOLD if i < tk else Color(1, 1, 1, 0.1), Color(UI.GOLD, 0.6), 4, 1, 0)
		pip.custom_minimum_size = Vector2(14, 14)
		pips.add_child(pip)
	h.add_child(UI.button("FORMATION", func(): main.go("formation"), "", Vector2(124, 40)))

## Ranking: podium for the top 3, then the list with tier chips; your row is highlighted.
func _render_ranking() -> void:
	var board: Array = Game.arena_leaderboard()
	var pod := UI.hbox(8)
	_list.add_child(pod)
	for k in [1, 0, 2]:
		if k < board.size():
			pod.add_child(UI.podium(board[k], k, "%d RP" % int(board[k]["rp"])))
	for i in range(3, board.size()):
		var e: Dictionary = board[i]
		var me: bool = e["me"]
		var tier := _tier(int(e["rp"]))
		var tcol: Color = TIER_COL.get(tier, UI.GOLD)
		var row := UI.styled_panel(Color(0.25, 0.18, 0.05, 0.95) if me else Color(0.08, 0.05, 0.14, 0.9), UI.GOLD if me else Color("#3a2f55"), 8, 2 if me else 1, 5)
		var rh := UI.hbox(10)
		row.add_child(rh)
		var rl := UI.label("#%d" % (i + 1), 17, Color.WHITE, 3)
		rl.custom_minimum_size = Vector2(46, 0)
		rh.add_child(rl)
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(e["hero"])], 6, 1, 1)
		fp.add_child(UI.face_rect(e["hero"], Vector2(34, 34)))
		rh.add_child(fp)
		var nl := UI.label(str(e["name"]) + ("  (You)" if me else ""), 16, UI.GREEN if me else Color.WHITE, 2)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(nl)
		var tchip := UI.styled_panel(Color(tcol, 0.14), Color(tcol, 0.6), 8, 1, 1)
		tchip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tchip.add_child(UI.margin(UI.label("◆ " + tier, 11, tcol, 2), 6, 0, 6, 0))
		rh.add_child(tchip)
		var rp := UI.label("%d RP" % int(e["rp"]), 16, UI.GOLD, 2)
		rp.custom_minimum_size.x = 90
		rp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rh.add_child(rp)
		_list.add_child(row)
	UI.stagger(_list, 0.02)
