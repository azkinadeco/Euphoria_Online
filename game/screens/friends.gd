extends Screen
## Friends: send hearts for Friend Points, browse friends' support heroes.

var _filter := "ALL"
var _grid: GridContainer

const STATUS := ["Online", "Online", "In battle", "5m ago", "1h ago", "3h ago"]

func build() -> void:
	_filter = str(params.get("filter", "ALL"))
	set_bg("forest", 0.6)
	var bar := header("FRIENDS", ["friend_point"])
	bar.add_child(UI.button("FRIEND SHOP", func(): main.go("shop", {"tab": "friend_point"}), "", Vector2(160, 46)))
	var b := body(76)
	var list := Game.friends()

	# ---------------------------------------------------------------- left: you + hearts
	var lp := UI.panel()
	lp.anchor_right = 0.3
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(10)
	lp.add_child(lv)
	var me := UI.hbox(10)
	lv.add_child(me)
	me.add_child(_avatar(str(Game.s["lobby_hero"]), 60, Color("#ffcf5a"), true))
	var mv := UI.vbox(1)
	mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	me.add_child(mv)
	mv.add_child(UI.label(str(Game.s["player"]["name"]), 19, Color.WHITE, 2))
	mv.add_child(UI.label("Player Lv.%d" % int(Game.s["player"]["level"]), 13, UI.GOLD, 2))
	mv.add_child(UI.label("ID  %08d" % (absi(hash(str(Game.s["player"]["name"]))) % 100000000), 12, UI.MUTED, 0))

	var avail := 0
	for f in list:
		if not f["used"]:
			avail += 1
	var stats := UI.hbox(6)
	lv.add_child(stats)
	for c in [["FRIENDS", "%d/30" % list.size(), Color("#9fd0ff")], ["SUPPORTS", "%d left" % avail, UI.GREEN], ["POINTS", Game.fmt(Game.s["cur"].get("friend_point", 0)), Color("#ff8fc7")]]:
		var sp := UI.styled_panel(Color(0, 0, 0, 0.4), Color(c[2], 0.45), 8, 1, 5.0)
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sv := UI.vbox(0)
		sp.add_child(sv)
		var t1 := UI.label(c[0], 10, UI.MUTED, 0)
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_child(t1)
		var t2 := UI.label(c[1], 15, c[2], 2)
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_child(t2)
		stats.add_child(sp)

	# hearts box
	var sent: bool = bool(Game.s["friends"]["hearts_sent"])
	var hp := UI.styled_panel(Color(0.3, 0.06, 0.18, 0.75) if not sent else Color(0.08, 0.06, 0.12, 0.7), Color("#ff6fae") if not sent else Color(1, 1, 1, 0.12), 12, 2 if not sent else 1, 10.0)
	lv.add_child(hp)
	var hv := UI.vbox(6)
	hp.add_child(hv)
	var hh := UI.hbox(8)
	hv.add_child(hh)
	var heart := UI.label("♥", 30, Color("#ff6fae") if not sent else UI.MUTED, 3)
	hh.add_child(heart)
	var ht := UI.vbox(0)
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(ht)
	ht.add_child(UI.label("DAILY HEARTS", 15, Color.WHITE, 2))
	ht.add_child(UI.label("+%d Friend Points" % (10 * list.size()) if not sent else "Sent today — back tomorrow", 12, Color("#ffb3d6") if not sent else UI.MUTED, 0))
	var hb := UI.button("♥ SEND TO ALL" if not sent else "SENT ✔", func():
		var fp := Game.send_hearts()
		if fp > 0:
			Game.sfx("star_up")
			main.show_rewards("HEARTS SENT", {"friend_point": fp}, func(): main.replace("friends", {"filter": _filter})), "GoldButton" if not sent else "", Vector2(0, 46))
	hb.disabled = sent
	hv.add_child(hb)
	if not sent:
		var tw := heart.create_tween().set_loops()
		tw.tween_property(heart, "scale", Vector2(1.18, 1.18), 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(heart, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
		heart.pivot_offset = Vector2(12, 20)

	# how it works
	lv.add_child(UI.label("HOW FRIENDS HELP", 13, UI.GOLD, 2))
	for st in [["icon_formation", "+ FRIEND SUPPORT in Battle Prep", "Borrow a hero in Story, Event & Tower"], ["icon_heart", "+20 points per support", "Each friend helps once per day"], ["icon_shop", "Spend in the Friend Shop", "Tickets, gold and upgrade mats"]]:
		var r := UI.hbox(8)
		var ic := UI.tex_rect(DB.icon(st[0]), Vector2(26, 26))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(ic)
		var rv := UI.vbox(0)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(rv)
		rv.add_child(UI.label(st[1], 13, Color.WHITE, 0))
		rv.add_child(UI.label(st[2], 11, UI.MUTED, 0))
		lv.add_child(r)
	var note := UI.wrap_label("AI friends for now — real friends arrive with online mode.", 11, Color("#9fd0ff"))
	lv.add_child(note)

	# ---------------------------------------------------------------- right: friend list
	var rp := Control.new()
	rp.anchor_left = 0.315
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv2 := UI.vbox(8)
	rv2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rp.add_child(rv2)
	var tabs := UI.hbox(8)
	rv2.add_child(tabs)
	for t in [["ALL", "ALL  %d" % list.size()], ["AVAILABLE", "AVAILABLE  %d" % avail], ["USED", "USED TODAY  %d" % (list.size() - avail)]]:
		var key: String = t[0]
		var tb := UI.button(t[1], func(): main.replace("friends", {"filter": key}), "GoldButton" if _filter == key else "", Vector2(0, 40))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tb)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	var sc := UI.scroll(_grid)
	rv2.add_child(sc)
	_grid.columns = 2
	sc.resized.connect(_fit_cols.bind(sc))
	var shown := 0
	# available first
	var sorted := list.duplicate()
	sorted.sort_custom(func(a, c): return int(a["used"]) < int(c["used"]) if a["used"] != c["used"] else int(a["idx"]) < int(c["idx"]))
	for f in sorted:
		if _filter == "AVAILABLE" and f["used"]:
			continue
		if _filter == "USED" and not f["used"]:
			continue
		_grid.add_child(_card(f, sent))
		shown += 1
	if shown == 0:
		var el := UI.label("No supports used yet today." if _filter == "USED" else "Every friend has helped today — they're back tomorrow!", 14, UI.MUTED, 2)
		_grid.add_child(el)
	UI.stagger(_grid, 0.04)

func _card(f: Dictionary, sent: bool) -> Control:
	var used: bool = f["used"]
	var r := DB.rarity_of(str(f["hero"]))
	var rc: Color = DB.RARITY_COLOR.get(r, Color("#3d3160"))
	var p := UI.styled_panel(Color(0.09, 0.06, 0.15, 0.92) if not used else Color(0.06, 0.05, 0.09, 0.85), Color(rc, 0.55) if not used else Color(1, 1, 1, 0.1), 12, 1, 8.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(10)
	p.add_child(h)
	var hc := HeroCard.new(f["hero"], Vector2(84, 108), {"owned": true, "show_level": false})
	if used:
		hc.modulate = Color(0.55, 0.55, 0.6)
	h.add_child(hc)
	var v := UI.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(_avatar(str(DB.HEROES.keys()[(int(f["idx"]) * 7 + 3) % DB.HEROES.size()]), 28, Color("#9fd0ff"), false))
	var nm := UI.label(str(f["name"]), 18, Color.WHITE if not used else UI.MUTED, 2)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	top.add_child(nm)
	top.add_child(UI.label("♥" if sent else "♡", 18, Color("#ff6fae") if sent else UI.MUTED, 2))
	var stt: String = STATUS[int(f["idx"]) % STATUS.size()]
	var online := stt == "Online" or stt == "In battle"
	var sl := UI.hbox(6)
	v.add_child(sl)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(9, 9)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.add_theme_stylebox_override("panel", UI.style(UI.GREEN if online else UI.MUTED, Color.TRANSPARENT, 5, 0, 0))
	sl.add_child(dot)
	sl.add_child(UI.label("%s  •  Player Lv.%d" % [stt, int(f["player_level"])], 12, UI.GREEN if online else UI.MUTED, 0))
	v.add_child(UI.label(DB.name_of(f["hero"]), 15, UI.GOLD, 2))
	v.add_child(UI.label("Lv.%d  %s" % [f["level"], "★".repeat(f["star"])], 13, Color("#ffd98a"), 2))
	var pill := UI.styled_panel(Color(UI.GREEN, 0.18) if not used else Color(1, 1, 1, 0.06), UI.GREEN if not used else Color(1, 1, 1, 0.15), 8, 1, 3.0)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.add_child(UI.label("  SUPPORT READY  " if not used else "  HELPED TODAY  ", 11, UI.GREEN if not used else UI.MUTED, 0))
	v.add_child(pill)
	p.tooltip_text = "Pick %s's %s from + FRIEND SUPPORT in Battle Prep." % [f["name"], DB.name_of(f["hero"])]
	return p

## Round portrait with a coloured ring.
func _avatar(hid: String, sz: int, ring: Color, glow: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(sz, sz)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var clip := Panel.new()
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	clip.add_theme_stylebox_override("panel", UI.style(Color.WHITE, Color.TRANSPARENT, sz / 2, 0, 0))
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(clip)
	var t := UI.tex_rect(DB.face(hid), Vector2.ZERO, true)
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_child(t)
	var ring_p := Panel.new()
	ring_p.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, ring, sz / 2, 2 if glow else 1, 0))
	ring_p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(ring_p)
	return c

func _fit_cols(sc: Control) -> void:
	if is_instance_valid(_grid):
		_grid.columns = maxi(1, int(sc.size.x / 360.0))
