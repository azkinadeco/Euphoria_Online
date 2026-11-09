extends Screen
## Expeditions: send idle heroes on timed missions for rewards + Bond EXP.

const BANNER := {"herb": "forest", "patrol": "outland", "ruins": "asgard", "hunt": "dragonfire", "rift": "blackhole"}

var _list: VBoxContainer
var _summary: HBoxContainer
var _timers: Array = []   # {eid, label, bar, done}
var _t := 0.0
var _plan := {}

func build() -> void:
	set_bg("world", 0.55)
	ambient(Color(0.8, 1.0, 0.9), 20)
	header("EXPEDITION", ["gold", "gems"])
	var b := body(76)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	_summary = UI.hbox(10)
	v.add_child(_summary)
	_list = UI.vbox(10)
	var sc := UI.scroll(_list)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	_render()
	tutorial("expedition")

func _process(delta: float) -> void:
	_t += delta
	if _t < 1.0:
		return
	_t = 0.0
	var need_render := false
	for tm in _timers:
		var left := Game.expedition_left(tm["eid"])
		if not is_instance_valid(tm["label"]):
			continue
		if left == 0 and not tm["done"]:
			need_render = true
		tm["label"].text = _fmt_time(left)
		tm["bar"].value = float(Game.expedition_def(tm["eid"])["hours"]) * 3600.0 - left
	if need_render:
		_render()

func _fmt_time(s: int) -> String:
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]

func _render() -> void:
	_timers.clear()
	_plan = Game.expedition_plan()
	_render_summary()
	for c in _list.get_children():
		c.queue_free()
	for d in DB.EXPEDITIONS:
		_list.add_child(_card(d))
	UI.stagger(_list, 0.05)

## Top strip: how many missions are running / ready, heroes out, CLAIM ALL.
func _render_summary() -> void:
	for c in _summary.get_children():
		c.queue_free()
	var running: int = Game.s["expeditions"].size()
	var ready := Game.expeditions_ready()
	var out := Game.heroes_on_expedition().size()
	_summary.add_child(_stat("ACTIVE", "%d / %d" % [running, DB.EXPEDITIONS.size()], Color("#7fd8ff")))
	_summary.add_child(_stat("READY", str(ready), UI.GREEN if ready > 0 else UI.MUTED))
	_summary.add_child(_stat("HEROES OUT", str(out), UI.GOLD))
	var tip := UI.wrap_label("Heroes on expeditions can still fight. Every finished expedition gives +10 Bond EXP to each hero sent.", 12, UI.MUTED)
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_summary.add_child(tip)
	var idle := _plan.size()
	if idle > 0:
		var sa := UI.button("SEND ALL (%d)" % idle, func():
			var n := Game.send_all_expeditions()
			if n > 0:
				Game.sfx("battle/dash")
				main.toast("%d expedition%s started!" % [n, "" if n == 1 else "s"], UI.GREEN)
			_render(), "" if ready > 0 else "GoldButton", Vector2(160, 48))
		sa.tooltip_text = "Send idle heroes on every open expedition (lowest levels that qualify first)."
		_summary.add_child(sa)
	if ready > 0:
		var cb := UI.button("CLAIM ALL (%d)" % ready, _claim_all, "GoldButton", Vector2(170, 48))
		UI.add_badge(cb, ready)
		_summary.add_child(cb)

func _stat(title: String, value: String, col: Color) -> Control:
	var p := UI.styled_panel(Color(0.1, 0.08, 0.16, 0.85), Color(col, 0.4), 10, 1, 10.0)
	p.custom_minimum_size = Vector2(110, 0)
	var v := UI.vbox(0)
	p.add_child(v)
	v.add_child(UI.label(title, 11, UI.MUTED, 1))
	v.add_child(UI.label(value, 20, col, 2))
	return p

func _claim_all() -> void:
	var total := {}
	for d in DB.EXPEDITIONS:
		var eid: String = d["id"]
		if Game.expedition_left(eid) == 0:
			var r := Game.claim_expedition(eid)
			for k in r.keys():
				total[k] = int(total.get(k, 0)) + int(r[k])
	if not total.is_empty():
		Game.sfx("star_up")
		main.show_rewards("EXPEDITIONS COMPLETE", total)
	_render()

func _best_level() -> int:
	var best := 0
	for id in Game.s["heroes"].keys():
		best = maxi(best, int(Game.hero(id)["level"]))
	return best

func _card(d: Dictionary) -> Control:
	var eid: String = d["id"]
	var left := Game.expedition_left(eid)
	var running := left > 0
	var done := left == 0
	var can_lv := _best_level() >= int(d["min_level"])
	var border := UI.GREEN if done else (Color("#7fd8ff") if running else Color(UI.GOLD, 0.35))
	var p := UI.styled_panel(Color(0.11, 0.08, 0.17, 0.92), border, 12, 2 if done else 1, 8.0)
	var h := UI.hbox(14)
	p.add_child(h)

	# --- banner with the mission's scenery
	var ban := Control.new()
	ban.custom_minimum_size = Vector2(210, 104)
	ban.clip_contents = true
	var img := UI.tex_rect(DB.bg(BANNER.get(eid, "world")), Vector2.ZERO, true)
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not can_lv:
		img.modulate = Color(0.3, 0.3, 0.36)
	ban.add_child(img)
	var shade := Control.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(func():
		var sz := shade.size
		if not can_lv:
			shade.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.03, 0.1, 0.55))
		for i in 10:
			var a := 0.07 * i
			shade.draw_rect(Rect2(0, sz.y * (0.4 + i * 0.06), sz.x, sz.y * 0.06 + 1), Color(0, 0, 0, a)))
	ban.add_child(shade)
	var dur := UI.styled_panel(Color(0, 0, 0, 0.6), Color(1, 1, 1, 0.25), 8, 1, 6.0)
	dur.position = Vector2(6, 6)
	dur.add_child(UI.label("%dh" % int(d["hours"]), 13, Color.WHITE, 2))
	ban.add_child(dur)
	var sent0: Array = Game.s["expeditions"][eid]["heroes"] if Game.s["expeditions"].has(eid) else []
	if running and not sent0.is_empty():
		ban.add_child(_marchers(sent0, float(d["hours"]) * 3600.0, left))
	var st_txt := "COMPLETE" if done else ("IN PROGRESS" if running else ("AVAILABLE" if can_lv else "LOCKED"))
	var st_col := UI.GREEN if done else (Color("#7fd8ff") if running else (UI.GOLD if can_lv else UI.MUTED))
	var stl := UI.label(st_txt, 12, st_col, 3)
	stl.position = Vector2(8, 80)
	ban.add_child(stl)
	h.add_child(ban)

	# --- info
	var info := UI.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(info)
	var tr := UI.hbox(10)
	tr.add_child(UI.label(d["name"], 19, Color.WHITE, 2))
	var req := UI.label("Hero Lv.%d+" % int(d["min_level"]), 12, UI.MUTED if can_lv else UI.RED, 1)
	req.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.add_child(req)
	info.add_child(tr)

	# hero slots: faces when running, empty rings otherwise
	var slots := UI.hbox(6)
	var sent: Array = sent0
	var plan: Array = [] if running or done else _plan.get(eid, [])
	for i in int(d["heroes"]):
		if i < plan.size():
			var pp := UI.styled_panel(Color.BLACK, Color(UI.GOLD, 0.45), 8, 1, 1)
			var pf := UI.tex_rect(DB.face(plan[i]), Vector2(36, 36), true)
			pf.modulate = Color(1, 1, 1, 0.55)
			pp.add_child(pf)
			pp.tooltip_text = "Suggested: %s (Lv.%d)" % [DB.name_of(plan[i]), int(Game.hero(plan[i])["level"])]
			pp.mouse_filter = Control.MOUSE_FILTER_PASS
			slots.add_child(pp)
		elif i < sent.size():
			var fp := UI.styled_panel(Color.BLACK, UI.GREEN if done else Color("#7fd8ff"), 8, 2, 1)
			var face := UI.tex_rect(DB.face(sent[i]), Vector2(36, 36), true)
			fp.add_child(face)
			fp.tooltip_text = DB.name_of(sent[i])
			slots.add_child(fp)
		else:
			var e := Control.new()
			e.custom_minimum_size = Vector2(40, 40)
			e.draw.connect(func():
				e.draw_arc(Vector2(20, 20), 17.0, 0.0, TAU, 32, Color(1, 1, 1, 0.3), 1.5, true)
				e.draw_string(ThemeDB.fallback_font, Vector2(0, 26), "+", HORIZONTAL_ALIGNMENT_CENTER, 40, 18, Color(1, 1, 1, 0.35)))
			slots.add_child(e)
	var bond := UI.label("+10 Bond each", 12, Color("#ff8fb8"), 1)
	bond.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slots.add_child(bond)
	info.add_child(slots)

	if running or done:
		var total := float(d["hours"]) * 3600.0
		var bar := UI.bar(total - left, total, "GoldBar", 10)
		info.add_child(bar)
		var row := UI.hbox(8)
		var tl := UI.label(_fmt_time(left) if running else "Ready to claim!", 13, Color.WHITE if running else UI.GREEN, 2)
		row.add_child(tl)
		var rr := UI.reward_row(d["give"], 22, 12)
		rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(rr)
		info.add_child(row)
		_timers.append({"eid": eid, "label": tl, "bar": bar, "done": done})
	else:
		info.add_child(UI.reward_row(d["give"], 26, 13))

	# --- action
	if done:
		var cb := UI.button("CLAIM", func():
			var r := Game.claim_expedition(eid)
			if not r.is_empty():
				Game.sfx("star_up")
				main.show_rewards("EXPEDITION COMPLETE", r)
			_render(), "GoldButton", Vector2(130, 48))
		cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(cb)
		var pt := cb.create_tween().set_loops()
		pt.tween_property(cb, "modulate", Color(1.25, 1.25, 1.25), 0.5)
		pt.tween_property(cb, "modulate", Color.WHITE, 0.5)
	elif running:
		var fb := UI.button("FINISH\n%d Gems" % Game.finish_now_cost(eid), func():
			var r := Game.claim_expedition(eid, true)
			if r.is_empty():
				main.toast("Not enough Gems.", UI.RED)
			else:
				main.show_rewards("EXPEDITION COMPLETE", r)
			_render(), "", Vector2(130, 56))
		fb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(fb)
	else:
		var av := UI.vbox(4)
		av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(av)
		var sb := UI.button("SEND", func(): _pick(eid), "GoldButton", Vector2(130, 48))
		if not plan.is_empty():
			var qb := UI.button("QUICK SEND", func():
				if Game.start_expedition(eid, plan) == "":
					Game.sfx("battle/dash")
				_render(), "", Vector2(130, 34))
			qb.add_theme_font_size_override("font_size", 13)
			qb.tooltip_text = "Send the suggested heroes"
			av.add_child(qb)
		if not can_lv:
			sb.disabled = true
			sb.tooltip_text = "Needs a hero at Lv.%d or higher." % int(d["min_level"])
		av.add_child(sb)
	return p

func _pick(eid: String) -> void:
	var d := Game.expedition_def(eid)
	var v: VBoxContainer = main.popup("SEND TO: %s" % d["name"], 780)
	v.add_child(UI.label("Choose %d hero(es), Lv.%d or higher." % [d["heroes"], d["min_level"]], 15, UI.MUTED))
	var sel: Array = []
	var busy := Game.heroes_on_expedition()
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 360)
	v.add_child(sc)
	var ids: Array = Game.s["heroes"].keys()
	ids.sort_custom(func(a, b): return int(Game.hero(a)["level"]) > int(Game.hero(b)["level"]))
	for id in ids:
		var hid: String = id
		var card := HeroCard.new(hid, Vector2(108, 136), {"skin": true})
		var ok_lv := int(Game.hero(hid)["level"]) >= int(d["min_level"])
		if busy.has(hid) or not ok_lv:
			card.disabled = true
			card.modulate = Color(0.4, 0.4, 0.45)
		card.pressed.connect(func():
			if sel.has(hid):
				sel.erase(hid)
			elif sel.size() < int(d["heroes"]):
				sel.append(hid)
			card.set_selected(sel.has(hid)))
		g.add_child(card)
	var ab := UI.button("AUTO SELECT", func():
		sel.clear()
		for c in g.get_children():
			c.set_selected(false)
		for c in g.get_children():
			if sel.size() >= int(d["heroes"]):
				break
			if not c.disabled:
				sel.append(c.hero_id)
				c.set_selected(true), "", Vector2(180, 46))
	var go := UI.button("START", func():
		var err := Game.start_expedition(eid, sel)
		if err != "":
			main.toast(err, UI.RED)
			return
		Game.sfx("battle/dash")
		main.close_popup(v)
		_render(), "GoldButton", Vector2(180, 46))
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(ab)
	row.add_child(go)
	v.add_child(row)


## The sent heroes' chibis walking across the mission banner; their progress follows the timer.
func _marchers(ids: Array, total: float, left: int) -> Control:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prog := clampf((total - left) / maxf(1.0, total), 0.0, 1.0)
	for i in ids.size():
		var hid: String = ids[i]
		var spr := UI.tex_rect(DB.sprite(hid, int(Game.hero(hid).get("star", 1)), int(Game.hero(hid).get("skin", -1))), Vector2(46, 46), true)
		spr.size = Vector2(46, 46)
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var x0 := 8.0 + prog * 110.0 + (ids.size() - 1 - i) * 30.0
		spr.position = Vector2(x0, 34.0)
		layer.add_child(spr)
		# little walking bob, offset per hero
		var tw := spr.create_tween().set_loops()
		tw.tween_interval(0.12 * i)
		tw.tween_property(spr, "position:y", 30.0, 0.25).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spr, "position:y", 34.0, 0.25).set_trans(Tween.TRANS_SINE)
	return layer
