extends Screen
## Season Pass: 30 levels, free + premium reward tracks.

var _track: HBoxContainer
var _info: VBoxContainer
var _scroll: ScrollContainer

func build() -> void:
	set_bg("galaxy", 0.5)
	var bar := header("SEASON PASS", ["gems"])
	bar.add_child(UI.button("CLAIM ALL", func():
		var r := Game.claim_all_pass()
		if r.is_empty():
			main.toast("Nothing to claim yet. Play stages, dungeons and missions to earn Pass EXP!")
		else:
			main.show_rewards("PASS REWARDS", r)
		_render(), "GoldButton", Vector2(170, 46)))
	var b := body(76)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var top := UI.panel()
	v.add_child(top)
	_info = UI.vbox(6)
	top.add_child(_info)
	var mid := UI.hbox(10)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(mid)
	var tp := UI.panel()
	tp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(tp)
	var row := UI.hbox(8)
	tp.add_child(row)
	var labels := UI.vbox(0)
	labels.custom_minimum_size = Vector2(92, 0)
	labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(labels)
	labels.add_child(_track_label("FREE", Color("#9fd0ff"), CELL_H))
	labels.add_child(_track_label("", UI.MUTED, NODE_H))
	labels.add_child(_track_label("PREMIUM", UI.GOLD, CELL_H))
	_track = UI.hbox(6)
	_track.alignment = BoxContainer.ALIGNMENT_CENTER
	_scroll = UI.scroll(_track, true)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(_scroll)
	_prize = UI.styled_panel(Color(0.22, 0.13, 0.05, 0.95), UI.GOLD, 14, 2, 12.0)
	_prize.custom_minimum_size = Vector2(220, 0)
	mid.add_child(_prize)
	_render()
	_scroll_to_current.call_deferred()

const CELL_H := 128
const NODE_H := 46
const COL_W := 112

var _prize: PanelContainer

func _track_label(t: String, col: Color, h: int) -> Label:
	var l := UI.label(t, 15, col, 3)
	l.custom_minimum_size = Vector2(0, h)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

## Scroll to the first unclaimed reward that is ready, else to the current level.
func _scroll_to_current() -> void:
	var lv := Game.pass_level()
	var target := lv
	for i in range(1, lv + 1):
		if not Game.s["pass"]["free"].has(i) or (bool(Game.s["pass"]["premium"]) and not Game.s["pass"]["prem"].has(i)):
			target = i
			break
	_scroll.scroll_horizontal = maxi(0, (target - 1) * (COL_W + 6))

func _render() -> void:
	for c in _info.get_children():
		c.queue_free()
	var lv := Game.pass_level()
	var prem := bool(Game.s["pass"]["premium"])
	var h := UI.hbox(14)
	_info.add_child(h)
	# level ring
	var into := int(Game.s["pass"]["exp"]) - lv * DB.PASS_EXP_PER_LV
	var frac := 1.0 if lv >= DB.PASS_LEVELS else float(into) / float(DB.PASS_EXP_PER_LV)
	var ring := Control.new()
	ring.custom_minimum_size = Vector2(76, 76)
	ring.draw.connect(func():
		var c := Vector2(38, 38)
		ring.draw_circle(c, 36.0, Color(0.08, 0.05, 0.14))
		ring.draw_arc(c, 32.0, 0.0, TAU, 48, Color(1, 1, 1, 0.1), 6.0, true)
		if frac > 0.0:
			ring.draw_arc(c, 32.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 48, UI.GOLD, 6.0, true)
		var f := ThemeDB.fallback_font
		ring.draw_string(f, Vector2(0, 30), "PASS", HORIZONTAL_ALIGNMENT_CENTER, 76, 11, UI.MUTED)
		ring.draw_string(f, Vector2(0, 54), str(lv), HORIZONTAL_ALIGNMENT_CENTER, 76, 24, Color.WHITE))
	h.add_child(ring)
	var tv := UI.vbox(3)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	var tr := UI.hbox(10)
	tr.add_child(UI.label("CURRENT SEASON", 20, UI.GOLD, 4))
	var days := maxi(0, Game.pass_ends_in()) / 86400
	var dp := UI.styled_panel(Color(0, 0, 0, 0.4), Color(1, 1, 1, 0.2), 8, 1, 6.0)
	dp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dp.add_child(UI.label("Ends in %d days" % days, 12, UI.TEXT, 1))
	tr.add_child(dp)
	var ready := Game.pass_claimable()
	if ready > 0:
		var rl := UI.label("• %d reward%s ready" % [ready, "" if ready == 1 else "s"], 13, UI.GREEN, 2)
		rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.add_child(rl)
	tv.add_child(tr)
	if lv < DB.PASS_LEVELS:
		tv.add_child(UI.bar(into, DB.PASS_EXP_PER_LV, "GoldBar", 10))
		tv.add_child(UI.label("%d / %d EXP to Lv.%d" % [into, DB.PASS_EXP_PER_LV, lv + 1], 12, UI.MUTED))
	var src := UI.hbox(6)
	for e in [["Stages", 15], ["Dungeon/Arena", 25], ["Guild/AFK", 20], ["Summon", 10], ["Missions", 60]]:
		var cp := UI.styled_panel(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.14), 8, 1, 5.0)
		cp.add_child(UI.label("%s +%d" % [e[0], e[1]], 11, UI.TEXT, 1))
		src.add_child(cp)
	tv.add_child(src)
	if prem:
		var pa := UI.styled_panel(Color(UI.GREEN, 0.1), UI.GREEN, 10, 2, 12.0)
		pa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pa.add_child(UI.label("PREMIUM ACTIVE ✔", 16, UI.GREEN, 3))
		h.add_child(pa)
	else:
		var ub := UI.button("UNLOCK PREMIUM\n%d Gems" % DB.PASS_PRICE, func():
			main.confirm("Unlock the Premium track for %d Gems? All premium rewards up to your current level become claimable." % DB.PASS_PRICE, func():
				var err := Game.buy_premium_pass()
				if err != "":
					main.toast(err, UI.RED)
				else:
					Game.sfx("awakening")
					main.toast("Premium Pass unlocked!", UI.GOLD)
				_render(), "UNLOCK"), "GoldButton", Vector2(220, 70))
		ub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ub)
		var tw := ub.create_tween().set_loops()
		tw.tween_property(ub, "modulate", Color(1.15, 1.15, 1.15), 0.9)
		tw.tween_property(ub, "modulate", Color.WHITE, 0.9)

	for c in _track.get_children():
		c.queue_free()
	for i in range(1, DB.PASS_LEVELS + 1):
		var col := UI.vbox(0)
		col.custom_minimum_size = Vector2(COL_W, 0)
		col.add_child(_cell(i, false))
		col.add_child(_node(i, lv))
		col.add_child(_cell(i, true))
		_track.add_child(col)
	UI.stagger(_track, 0.02)
	_render_prize(lv, prem)

## Level node on the centre line: lit up to the current level, milestones are diamonds.
func _node(i: int, lv: int) -> Control:
	var n := Control.new()
	n.custom_minimum_size = Vector2(COL_W, NODE_H)
	var lit_l := i <= lv
	var lit_r := i < lv
	var mile := i % 5 == 0
	n.draw.connect(func():
		var w := n.size.x
		var y := n.size.y * 0.5
		var on := UI.GOLD
		var off := Color(1, 1, 1, 0.15)
		n.draw_line(Vector2(-3, y), Vector2(w * 0.5, y), on if lit_l else off, 4.0)
		n.draw_line(Vector2(w * 0.5, y), Vector2(w + 3, y), on if lit_r else off, 4.0)
		var c := Vector2(w * 0.5, y)
		var r := 17.0 if mile else 14.0
		if mile:
			var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
			n.draw_colored_polygon(pts, on if lit_l else Color(0.15, 0.1, 0.22))
			pts.append(pts[0])
			n.draw_polyline(pts, on.lightened(0.3) if lit_l else Color(1, 1, 1, 0.3), 2.0, true)
		else:
			n.draw_circle(c, r, on if lit_l else Color(0.15, 0.1, 0.22))
			n.draw_arc(c, r, 0.0, TAU, 32, on.lightened(0.3) if lit_l else Color(1, 1, 1, 0.3), 2.0, true)
		n.draw_string(ThemeDB.fallback_font, c + Vector2(-20, 5), str(i), HORIZONTAL_ALIGNMENT_CENTER, 40, 13, Color(0.15, 0.08, 0.02) if lit_l else UI.MUTED))
	return n

func _render_prize(lv: int, prem: bool) -> void:
	for c in _prize.get_children():
		c.queue_free()
	var v := UI.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_prize.add_child(v)
	var t := UI.label("GRAND PRIZE", 16, UI.GOLD, 4)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s2 := UI.label("Premium • Lv.%d" % DB.PASS_LEVELS, 12, UI.MUTED, 1)
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s2)
	var r := DB.pass_reward(DB.PASS_LEVELS, true)
	var keys := r.keys()
	var big := UI.tex_rect(Game.reward_icon(keys[0]), Vector2(0, 110))
	v.add_child(big)
	UI.breathe(big, 0.04, 2.6)
	for k in keys:
		var nl := UI.label("%s x%d" % [DB.ITEMS[k]["name"] if DB.ITEMS.has(k) else str(k).capitalize(), int(r[k])], 13, Color.WHITE, 2)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nl)
	var left := DB.PASS_LEVELS - lv
	var st := UI.label(("%d levels to go" % left) if left > 0 else ("Reached!" if prem else "Unlock Premium to claim"), 12, UI.GREEN if left <= 0 else UI.MUTED, 1)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	v.add_child(UI.button("VIEW", func():
		var tw := _scroll.create_tween()
		tw.tween_property(_scroll, "scroll_horizontal", int(_scroll.get_h_scroll_bar().max_value), 0.6).set_trans(Tween.TRANS_SINE), "", Vector2(0, 36)))

func _cell(lv: int, premium: bool) -> Control:
	var r := DB.pass_reward(lv, premium)
	var key := "prem" if premium else "free"
	var claimed: bool = Game.s["pass"][key].has(lv)
	var reached := lv <= Game.pass_level()
	var owned := not premium or bool(Game.s["pass"]["premium"])
	var unlocked := reached and owned
	var mile := lv % 5 == 0
	var ready := unlocked and not claimed
	var base := Color(0.1, 0.06, 0.18, 0.95) if not premium else Color(0.2, 0.12, 0.05, 0.95)
	if mile:
		base = base.lightened(0.06)
	var border := UI.GREEN if ready else (UI.GOLD if premium or mile else Color("#5b7bd0"))
	var btn := Button.new()
	btn.theme_type_variation = "FlatButton"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(COL_W, CELL_H)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UI.style(base, border, 10, 3 if ready or mile else 1, 0))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_top = 4
	p.offset_bottom = -4
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(p)
	var v := UI.vbox(2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(v)
	var isz := 40.0 if r.size() == 1 else 30.0
	for k in r.keys():
		var ic := UI.tex_rect(Game.reward_icon(k), Vector2(0, isz))
		if claimed or not owned:
			ic.modulate = Color(1, 1, 1, 0.35)
		v.add_child(ic)
		var al := UI.label("x" + Game.fmt(int(r[k])), 12, Color.WHITE if not claimed else UI.MUTED, 3)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(al)
	var txt := "✔ CLAIMED" if claimed else ("CLAIM!" if unlocked else ("LOCKED" if premium and not owned else ""))
	if txt != "":
		var st := UI.label(txt, 11, UI.GREEN if ready or claimed else UI.MUTED, 3)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(st)
	if mile and not claimed:
		var star := UI.label("★", 14, UI.GOLD, 3)
		star.position = Vector2(8, 6)
		btn.add_child(star)
	if ready:
		var tw := btn.create_tween().set_loops()
		tw.tween_property(p, "self_modulate", Color(1.3, 1.3, 1.3), 0.6)
		tw.tween_property(p, "self_modulate", Color.WHITE, 0.6)
	var tip: Array = []
	for k in r.keys():
		tip.append("%s x%s" % [DB.ITEMS[k]["name"] if DB.ITEMS.has(k) else str(k).capitalize(), Game.fmt(int(r[k]))])
	btn.tooltip_text = "Lv.%d %s: %s" % [lv, "Premium" if premium else "Free", ", ".join(tip)]
	btn.pressed.connect(func():
		var got := Game.claim_pass(lv, premium)
		if not got.is_empty():
			Game.sfx("star_up")
			main.show_rewards("PASS Lv.%d" % lv, got)
			_render()
		elif premium and not bool(Game.s["pass"]["premium"]):
			main.toast("Unlock Premium to claim this reward.", UI.GOLD))
	return btn
