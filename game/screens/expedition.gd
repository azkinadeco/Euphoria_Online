extends Screen
## Expeditions: send idle heroes on timed missions for rewards + Bond EXP.

var _list: VBoxContainer
var _timers: Array = []   # {eid, label, bar}
var _t := 0.0

func build() -> void:
	set_bg("world", 0.55)
	ambient(Color(0.8, 1.0, 0.9), 20)
	header("EXPEDITION", ["gold", "gems"])
	var b := body(76)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	v.add_child(UI.wrap_label("Send heroes on missions while you're away. They can still fight in battles. Each completed expedition gives +10 Bond EXP to every hero sent.", 14, UI.MUTED))
	_list = UI.vbox(10)
	v.add_child(UI.scroll(_list))
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
	for c in _list.get_children():
		c.queue_free()
	for d in DB.EXPEDITIONS:
		var eid: String = d["id"]
		var p := UI.panel("CardPanel")
		_list.add_child(p)
		var h := UI.hbox(14)
		p.add_child(h)
		var info := UI.vbox(2)
		info.custom_minimum_size = Vector2(280, 0)
		info.add_child(UI.label(d["name"], 19, Color.WHITE, 2))
		info.add_child(UI.label("%dh  •  %d hero(es)  •  Lv.%d+" % [d["hours"], d["heroes"], d["min_level"]], 13, UI.MUTED))
		info.add_child(UI.reward_row(d["give"], 26, 13))
		h.add_child(info)
		var mid := UI.vbox(4)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(mid)
		var left := Game.expedition_left(eid)
		if left < 0:
			mid.add_child(UI.label("Available", 15, UI.GREEN))
			h.add_child(UI.button("SEND", func(): _pick(eid), "GoldButton", Vector2(130, 48)))
		else:
			var faces := UI.hbox(4)
			for hid in Game.s["expeditions"][eid]["heroes"]:
				var fp := UI.styled_panel(Color.BLACK, UI.GREEN, 6, 2, 1)
				fp.add_child(UI.tex_rect(DB.face(hid), Vector2(40, 40), true))
				faces.add_child(fp)
			mid.add_child(faces)
			var bar := UI.bar(float(d["hours"]) * 3600.0 - left, float(d["hours"]) * 3600.0, "GoldBar", 10)
			mid.add_child(bar)
			var tl := UI.label(_fmt_time(left), 14, Color.WHITE, 2)
			mid.add_child(tl)
			_timers.append({"eid": eid, "label": tl, "bar": bar, "done": left == 0})
			if left == 0:
				var cb := UI.button("CLAIM", func():
					var r := Game.claim_expedition(eid)
					if not r.is_empty():
						main.show_rewards("EXPEDITION COMPLETE", r)
					_render(), "GoldButton", Vector2(130, 48))
				h.add_child(cb)
				var pt := cb.create_tween().set_loops()
				pt.tween_property(cb, "modulate", Color(1.25, 1.25, 1.25), 0.5)
				pt.tween_property(cb, "modulate", Color.WHITE, 0.5)
			else:
				h.add_child(UI.button("FINISH\n%d Gems" % Game.finish_now_cost(eid), func():
					var r := Game.claim_expedition(eid, true)
					if r.is_empty():
						main.toast("Not enough Gems.", UI.RED)
					else:
						main.show_rewards("EXPEDITION COMPLETE", r)
					_render(), "", Vector2(130, 56)))
	UI.stagger(_list, 0.06)

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
