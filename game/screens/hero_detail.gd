extends Screen
## Hero detail: art showcase, stats & skill range, upgrades, outfits, bond/oath.

var id := ""
var _tab := "INFO"
var _art: TextureRect
var _panel_box: VBoxContainer
var _tabs: Array = []
var _name_box: VBoxContainer
var _holder: Control

func build() -> void:
	id = str(params.get("id", Game.s["lobby_hero"]))
	_tab = str(params.get("tab", "INFO")) if Game.owns(id) else "INFO"
	set_bg("lobby", 0.7)
	var tint := ColorRect.new()
	tint.color = Color(DB.theme_color(id), 0.12)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	ambient(DB.theme_color(id).lightened(0.4), 30)
	header("HERO")

	# art
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	_art = UI.tex_rect(null)
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.anchor_right = 0.55
	_art.offset_top = 70
	_art.offset_left = 30
	_holder.add_child(_art)
	_art.resized.connect(func(): _art.pivot_offset = Vector2(_art.size.x * 0.5, _art.size.y))
	UI.live(_art, DB.theme_color(id).lightened(0.5))
	_art.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.gui_input.connect(_gesture)
	_pinch = PinchZoom.new(func(f: float, c: Vector2): _pinch_zoom(f, c))
	_art.add_child(_pinch)
	var tw := _art.create_tween().set_loops()
	tw.tween_property(_art, "scale", Vector2(1.005, 1.014), 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_art, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_SINE)

	_name_box = UI.vbox(2)
	_name_box.position = Vector2(30, 80)
	add_child(_name_box)

	# full-screen viewer
	var zb := UI.zoom_button(_open_viewer)
	zb.anchor_left = 0.55
	zb.anchor_right = 0.55
	zb.offset_left = -76
	zb.offset_right = -18
	zb.offset_top = 84
	zb.offset_bottom = 142
	add_child(zb)

	# prev / next
	var list: Array = params.get("list", [])
	_list = list
	if params.has("swipe"):
		var sd := int(params["swipe"])
		(func():
			var x0 := _art.position.x
			_art.position.x = x0 + sd * 180.0
			_art.create_tween().tween_property(_art, "position:x", x0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)).call_deferred()
	if list.size() > 1:
		var i := list.find(id)
		var prev_b := UI.button("◀", func(): main.replace("hero_detail", {"id": list[(i - 1 + list.size()) % list.size()], "list": list, "tab": _tab}), "", Vector2(52, 64))
		prev_b.anchor_top = 0.5
		prev_b.anchor_bottom = 0.5
		prev_b.offset_left = 14
		prev_b.offset_top = -10
		add_child(prev_b)
		var next_b := UI.button("▶", func(): main.replace("hero_detail", {"id": list[(i + 1) % list.size()], "list": list, "tab": _tab}), "", Vector2(52, 64))
		next_b.anchor_left = 0.55
		next_b.anchor_right = 0.55
		next_b.anchor_top = 0.5
		next_b.anchor_bottom = 0.5
		next_b.offset_left = -64
		next_b.offset_top = -10
		add_child(next_b)

	# right panel
	var rp := UI.panel()
	rp.set_anchors_preset(Control.PRESET_FULL_RECT)
	rp.anchor_left = 0.56
	rp.offset_left = 0
	rp.offset_right = -16
	rp.offset_top = 76
	rp.offset_bottom = -16
	add_child(rp)
	var rv := UI.vbox(10)
	rp.add_child(rv)
	var tabs := UI.hbox(6)
	rv.add_child(tabs)
	var tab_names := ["INFO", "UPGRADE", "GEAR", "OUTFITS", "BOND"] if Game.owns(id) else ["INFO"]
	for t in tab_names:
		var tn: String = t
		var b := UI.button(t, func(): _tab = tn; _render(), "TabButton", Vector2(0, 42))
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_tabs.append(b)
	_panel_box = UI.vbox(10)
	rv.add_child(UI.scroll(_panel_box))
	_render()
	if Game.owns(id):
		tutorial("hero_detail")

func refresh() -> void:
	super.refresh()

func _render() -> void:
	var h := Game.hero(id)
	var new_tex := DB.art(id, int(h.get("skin", 0)))
	if _art.texture != new_tex:
		_art.texture = new_tex
		_art.modulate.a = 0.0
		var at := _art.create_tween().set_parallel(true)
		at.tween_property(_art, "modulate:a", 1.0, 0.3)
		at.tween_property(_art, "position:x", _art.position.x, 0.35).from(_art.position.x - 40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for c in _name_box.get_children():
		c.queue_free()
	var top := UI.hbox(8)
	top.add_child(UI.rarity_tag(DB.rarity_of(id), 16))
	top.add_child(UI.element_tag(DB.element_of(id), 15))
	top.add_child(UI.label(DB.role_of(id), 15, UI.MUTED, 3))
	var ri := DB.role_info(id)
	var rc := Color(str(ri[1]))
	var rchip := UI.styled_panel(Color(rc, 0.18), Color(rc, 0.8), 8, 1, 0)
	rchip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rchip.add_child(UI.margin(UI.label(str(ri[0]), 12, rc.lightened(0.2), 2), 7, 1, 7, 1))
	rchip.tooltip_text = str(ri[2])
	rchip.mouse_filter = Control.MOUSE_FILTER_PASS
	top.add_child(rchip)
	_name_box.add_child(top)
	_name_box.add_child(UI.label(DB.name_of(id), 44, Color.WHITE, 8))
	_name_box.add_child(UI.label(DB.title_of(id), 16, DB.theme_color(id).lightened(0.4), 4))
	var star_n: int = int(h.get("star", DB.RARITY_START_STAR[DB.rarity_of(id)]))
	var srow := UI.hbox(8)
	srow.add_child(UI.stars(star_n, 24, DB.MAX_STAR))
	if int(h.get("awaken", 0)) > 0:
		srow.add_child(UI.label("A%d" % int(h["awaken"]), 22, Color("#ffcf4a"), 5))
	_name_box.add_child(srow)
	if h.get("oath", false):
		_name_box.add_child(UI.label("♥ OATH SWORN", 16, Color("#ff8fb8"), 4))
	for t in _tabs:
		t.button_pressed = t.text == _tab
	for c in _panel_box.get_children():
		c.queue_free()
	match _tab:
		"UPGRADE": _render_upgrade()
		"GEAR": _render_gear()
		"OUTFITS": _render_outfits()
		"BOND": _render_bond()
		_: _render_info()

func _stat_row(parent: Control, name: String, value: String, extra: String = "") -> void:
	var r := UI.hbox(8)
	var n := UI.label(name, 16, UI.MUTED)
	n.custom_minimum_size = Vector2(90, 0)
	r.add_child(n)
	r.add_child(UI.label(value, 18, Color.WHITE, 2))
	if extra != "":
		r.add_child(UI.label(extra, 15, UI.GREEN))
	parent.add_child(r)

## Small drawn stat glyph in a tinted circle: heart (HP), sword (ATK), shield (DEF), heart+ring (bond).
func _stat_icon(kind: String, col: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(24, 24)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var o := Vector2(12, 12)
		c.draw_circle(o, 11.5, Color(col, 0.18))
		c.draw_arc(o, 11.0, 0, TAU, 32, Color(col, 0.7), 1.2, true)
		if kind == "hp" or kind == "bond":
			c.draw_circle(o + Vector2(-2.6, -1.5), 3.2, col)
			c.draw_circle(o + Vector2(2.6, -1.5), 3.2, col)
			c.draw_colored_polygon(PackedVector2Array([o + Vector2(-5.6, -0.6), o + Vector2(5.6, -0.6), o + Vector2(0, 6)]), col)
		elif kind == "atk":
			c.draw_line(o + Vector2(-5, 5), o + Vector2(5, -5), col, 2.4, true)
			c.draw_line(o + Vector2(-6, 2), o + Vector2(-2, 6), col, 2.0, true)
			c.draw_colored_polygon(PackedVector2Array([o + Vector2(4, -6), o + Vector2(6.5, -6.5), o + Vector2(6, -4)]), col)
		else:
			c.draw_colored_polygon(PackedVector2Array([o + Vector2(-5.5, -5.5), o + Vector2(5.5, -5.5), o + Vector2(5, 1), o + Vector2(0, 6.5), o + Vector2(-5, 1)]), col)
			c.draw_line(o + Vector2(0, -4.5), o + Vector2(0, 4.5), Color(0, 0, 0, 0.35), 1.2))
	return c

## Stat row: icon, name, value and a bar against the best hero at the same level/star.
func _stat_bar(parent: Control, kind: String, name: String, value: int, best: int, col: Color) -> void:
	var r := UI.hbox(8)
	parent.add_child(r)
	r.add_child(_stat_icon(kind, col))
	var n := UI.label(name, 15, UI.MUTED)
	n.custom_minimum_size = Vector2(52, 0)
	r.add_child(n)
	var vl := UI.label(Game.fmt(value), 17, Color.WHITE, 2)
	vl.custom_minimum_size = Vector2(84, 0)
	r.add_child(vl)
	var ratio := clampf(float(value) / float(maxi(1, best)), 0.0, 1.0)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.tooltip_text = "%d%% of the strongest hero's %s at this level and star" % [int(ratio * 100.0), name]
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.draw.connect(func():
		var w := bar.size.x
		bar.draw_rect(Rect2(0, 2, w, 6), Color(1, 1, 1, 0.08))
		bar.draw_rect(Rect2(0, 2, w * ratio, 6), Color(col, 0.85))
		bar.draw_rect(Rect2(0, 2, w * ratio, 2), Color(1, 1, 1, 0.25))
		for k in [0.25, 0.5, 0.75]:
			bar.draw_line(Vector2(w * k, 2), Vector2(w * k, 8), Color(0, 0, 0, 0.35), 1.0))
	r.add_child(bar)
	var rk := "S" if ratio >= 0.95 else ("A" if ratio >= 0.82 else ("B" if ratio >= 0.68 else "C"))
	var rc: Color = UI.GOLD if rk == "S" else (Color("#d48cff") if rk == "A" else (Color("#7fb8ff") if rk == "B" else UI.MUTED))
	var rl := UI.label(rk, 15, rc, 3)
	rl.custom_minimum_size = Vector2(16, 0)
	r.add_child(rl)

func _render_info() -> void:
	var h := Game.hero(id)
	var st := Game.hero_stats(id)
	var box := UI.panel("CardPanel")
	_panel_box.add_child(box)
	var v := UI.vbox(6)
	box.add_child(v)
	var hlv := int(h.get("level", 1))
	var star := int(h.get("star", 1))
	# header: power on the left, level pill on the right
	var i_hh := UI.hbox(10)
	v.add_child(i_hh)
	var i_pv := UI.vbox(0)
	i_pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	i_hh.add_child(i_pv)
	i_pv.add_child(UI.label("POWER" if Game.owns(id) else "BASE POWER", 11, UI.MUTED, 1))
	i_pv.add_child(UI.label(Game.fmt(DB.power_of(st)), 26, UI.GOLD, 4))
	if Game.owns(id):
		var i_cap := Game.hero_cap(id)
		var i_lp := UI.styled_panel(Color(0, 0, 0, 0.35), Color(UI.GOLD, 0.5), 10, 1, 0)
		i_lp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var i_lpv := UI.vbox(2)
		i_lp.add_child(UI.margin(i_lpv, 10, 4, 10, 6))
		i_lpv.add_child(UI.label("Lv.%d / %d" % [hlv, i_cap], 15, Color.WHITE, 2))
		var i_lb := UI.bar(hlv, i_cap, "GoldBar", 5)
		i_lb.custom_minimum_size = Vector2(110, 5)
		i_lpv.add_child(i_lb)
		i_hh.add_child(i_lp)
	else:
		i_hh.add_child(UI.label("Not recruited", 13, UI.MUTED))
	# i_best stat among all heroes at this level/star, for the comparison bars
	var i_best := {"hp": 1, "atk": 1, "def": 1}
	for i_hid in DB.HEROES.keys():
		var i_o := DB.stats_for(i_hid, hlv, star)
		for i_k in i_best.keys():
			i_best[i_k] = maxi(int(i_best[i_k]), int(i_o[i_k]))
	_stat_bar(v, "hp", "HP", int(st["hp"]), int(i_best["hp"]), Color("#6be0a0"))
	_stat_bar(v, "atk", "ATK", int(st["atk"]), int(i_best["atk"]), Color("#ff7a6b"))
	_stat_bar(v, "def", "DEF", int(st["def"]), int(i_best["def"]), Color("#7fb8ff"))
	if Game.owns(id):
		var i_br := UI.hbox(8)
		v.add_child(i_br)
		i_br.add_child(_stat_icon("bond", Color("#ff8fb8")))
		var i_bn := UI.label("Bond", 15, UI.MUTED)
		i_bn.custom_minimum_size = Vector2(52, 0)
		i_br.add_child(i_bn)
		i_br.add_child(UI.label("Lv.%d" % h["bond"], 16, Color.WHITE, 2))
		i_br.add_child(UI.label("+%d%% stats" % ((h["bond"] - 1) * 2 + (10 if h["oath"] else 0)), 14, UI.GREEN))
		if h.get("oath", false):
			i_br.add_child(UI.label("💍 OATH", 13, Color("#ff8fb8"), 2))

	var sk := DB.skill_of(id)
	var sb := UI.panel("CardPanel")
	_panel_box.add_child(sb)
	var sh := UI.hbox(14)
	sb.add_child(sh)
	var sv := UI.vbox(4)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sv)
	var sk_head := UI.hbox(6)
	sk_head.add_child(UI.tex_rect(DB.icon("icon_skill_ultimate"), Vector2(28, 28)))
	sk_head.add_child(UI.label(sk["name"], 20, UI.GOLD, 3))
	sv.add_child(sk_head)
	sv.add_child(UI.label("Range: " + DB.shape_label(sk) + ("   •   Skill Lv.%d" % int(Game.hero(id)["skill_lv"]) if Game.owns(id) else ""), 14, Color("#9fd0ff")))
	sv.add_child(UI.wrap_label(sk.get("desc", ""), 15, UI.TEXT))
	sh.add_child(ShapePreview.new(sk, Vector2(100, 100)))

	var vp := UI.panel("CardPanel")
	_panel_box.add_child(vp)
	var vv := UI.vbox(6)
	vp.add_child(vv)
	vv.add_child(UI.label("♪ VOICE", 16, UI.GOLD, 3))
	var vf := HFlowContainer.new()
	vf.add_theme_constant_override("h_separation", 6)
	vf.add_theme_constant_override("v_separation", 6)
	vv.add_child(vf)
	var sub := UI.wrap_label("", 13, UI.TEXT)
	for c in [["greet", "Greeting", 0], ["tap", "Touch", 0], ["skill", "Skill", 0], ["win", "Victory", 0], ["summon", "Summon", 0], ["bond", "Affection", 5]]:
		var cat: String = c[0]
		var need: int = c[2]
		var locked: bool = need > 0 and int(Game.hero(id).get("bond", 0)) < need
		var vb := UI.button(c[1] if not locked else "%s (Bond %d)" % [c[1], need], func():
			sub.text = "\"%s\"" % Game.voice(id, cat), "", Vector2(0, 36))
		vb.add_theme_font_size_override("font_size", 13)
		vb.disabled = locked
		vf.add_child(vb)
	vv.add_child(sub)

	var pf := DB.profile(id)
	if not pf.is_empty():
		var prp := UI.panel("CardPanel")
		_panel_box.add_child(prp)
		var prv := UI.vbox(2)
		prp.add_child(prv)
		var bd: String = str(pf.get("birthday", ""))
		var is_bd := Game.birthday_heroes().has(id)
		prv.add_child(UI.label("PROFILE" + ("   ♥ HAPPY BIRTHDAY! ♥" if is_bd else ""), 16, Color("#ff8fb8") if is_bd else UI.GOLD, 3))
		for row in [["Birthday", _fmt_bday(bd)], ["Height", "%s cm" % str(pf.get("height", "?"))], ["Likes", pf.get("likes", "")], ["Dislikes", pf.get("dislikes", "")], ["Hobby", pf.get("hobby", "")], ["CV", pf.get("cv", "TBA")]]:
			var rh := UI.hbox(8)
			var k := UI.label(row[0], 13, UI.MUTED)
			k.custom_minimum_size = Vector2(80, 0)
			rh.add_child(k)
			var vl := UI.wrap_label(str(row[1]), 13, UI.TEXT)
			rh.add_child(vl)
			prv.add_child(rh)
	if Game.owns(id):
		var tp := UI.panel("CardPanel")
		_panel_box.add_child(tp)
		var tv := UI.vbox(6)
		tp.add_child(tv)
		tv.add_child(UI.label("HERO TRIAL  •  Face your own Mirror", 16, Color("#d48cff"), 3))
		tv.add_child(UI.wrap_label("%s must be deployed and survive. Foes of her weak element join the fight. First clears give her shards." % DB.name_of(id).split(" ")[0], 12, UI.MUTED))
		var trow := UI.hbox(6)
		tv.add_child(trow)
		for ti in DB.TRIAL_TIERS.size():
			var tier: int = ti
			var done := Game.trial_cleared(id) >= tier
			var open := Game.trial_open(id, tier)
			var tbn := UI.button(("✓ " if done else "") + str(DB.TRIAL_TIERS[tier]["name"]) + "\nLv.%d" % int(DB.TRIAL_TIERS[tier]["lv"]), func():
				main.go("formation", {"mode": "trial", "hero": id, "tier": tier}), "GoldButton" if open and not done else "", Vector2(0, 54))
			tbn.add_theme_font_size_override("font_size", 13)
			tbn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tbn.disabled = not open
			trow.add_child(tbn)
	var lks := DB.links_of(id)
	if not lks.is_empty():
		var lp := UI.panel("CardPanel")
		_panel_box.add_child(lp)
		var lv := UI.vbox(4)
		lp.add_child(lv)
		lv.add_child(UI.label("STORY LINKS", 16, Color("#ffb8d6"), 3))
		for l in lks:
			var lh := UI.hbox(6)
			for hid in l["heroes"]:
				if hid != id:
					lh.add_child(UI.tex_rect(DB.face(hid), Vector2(30, 30), true))
			lh.add_child(UI.label("%s  •  %s" % [l["name"], DB.link_bonus_text(l)], 13, UI.TEXT))
			lv.add_child(lh)
	var pk := DB.passive_of(id)
	if pk != "":
		var pp := UI.panel("CardPanel")
		_panel_box.add_child(pp)
		var pv := UI.vbox(2)
		pp.add_child(pv)
		var ph := UI.hbox(6)
		ph.add_child(UI.tex_rect(DB.icon("icon_skill_passive"), Vector2(26, 26)))
		ph.add_child(UI.label("PASSIVE  " + str(DB.PASSIVES[pk]["name"]), 17, Color("#9fd0ff"), 3))
		pv.add_child(ph)
		pv.add_child(UI.wrap_label(str(DB.PASSIVES[pk]["desc"]), 14, UI.TEXT))
	var tip := UI.wrap_label("Brown Dust rule: a hero aims at the enemy in the SAME ROW. Place her on the row of the enemy you want to hit. Action order = deploy order.", 13, UI.MUTED)
	_panel_box.add_child(tip)

	if Game.owns(id):
		var row := UI.hbox(10)
		_panel_box.add_child(row)
		var lb := UI.button("♥ Set as Lobby Hero", func():
			Game.s["lobby_hero"] = id
			Game.mark_dirty()
			main.toast("%s is now your lobby partner!" % DB.name_of(id), Color("#ff8fb8")), "", Vector2(0, 46))
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lb)
		var fb := UI.button("Formation", func(): main.go("formation"), "", Vector2(0, 46))
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(fb)
	else:
		var need: int = Game.RECRUIT_SHARDS[DB.rarity_of(id)]
		var have: int = int(Game.s["shards"].get(id, 0))
		_panel_box.add_child(UI.label("Shards %d / %d" % [have, need], 16, UI.GOLD))
		_panel_box.add_child(UI.bar(have, need, "GoldBar", 10))
		var rb := UI.button("RECRUIT WITH SHARDS", func():
			var err := Game.recruit_with_shards(id)
			if err != "":
				main.toast(err, UI.RED)
			else:
				Game.sfx("awakening")
				main.toast("%s joined your team!" % DB.name_of(id))
				main.replace("hero_detail", params), "GoldButton", Vector2(0, 52))
		rb.disabled = have < need
		_panel_box.add_child(rb)
		_panel_box.add_child(UI.button("Go to Summon", func(): main.go("gacha"), "", Vector2(0, 46)))

var _touch_busy := false

func _fmt_bday(s: String) -> String:
	var parts := s.split("-")
	if parts.size() != 2:
		return s
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %d" % [months[clampi(int(parts[0]) - 1, 0, 11)], int(parts[1])]
var _fxn: SkillFX

var _list: Array = []
var _pinch: PinchZoom
var _hz := 1.0

## Pinch zoom on the hero art (zooms the holder around the fingers); pinch back out to reset.
func _pinch_zoom(f: float, centre: Vector2) -> void:
	var nz := clampf(_hz * f, 1.0, 3.0)
	if nz <= 1.01:
		_hz = 1.0
		_holder.scale = Vector2.ONE
		_holder.position = Vector2.ZERO
		return
	var local := centre - get_global_rect().position
	# keep the point under the fingers fixed
	var p0 := (local - _holder.position) / _hz
	_hz = nz
	_holder.scale = Vector2(_hz, _hz)
	_holder.pivot_offset = Vector2.ZERO
	_holder.position = local - p0 * _hz

var _g_down := false
var _g_start := Vector2.ZERO
var _g_t0 := 0
var _g_rub := 0.0
var _g_moved := false
var _g_hold := false
var _g_pat_t := 0
var _g_spoke := false

## Gestures on the art, like the lobby: tap = react, rub the head = head-pat,
## long-press = close-up, horizontal swipe = previous / next hero in the list.
func _gesture(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_pinch_zoom(1.1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1, _art.get_global_rect().position + e.position)
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_g_down = true
			_g_start = e.position
			_g_t0 = Time.get_ticks_msec()
			_g_rub = 0.0
			_g_moved = false
			_g_hold = false
			get_tree().create_timer(0.75).timeout.connect(func():
				if _g_down and not _g_moved and not _g_hold and is_inside_tree() and Game.owns(id) and _hz <= 1.01 and not _pinch.active():
					_g_hold = true
					_close_up())
		elif _g_down:
			_g_down = false
			if _g_hold:
				return
			var d: Vector2 = e.position - _g_start
			var dt := Time.get_ticks_msec() - _g_t0
			if _pinch.active():
				return
			if _hz > 1.01:
				if not _g_moved and Game.owns(id):
					_touch_art(e.position.y / maxf(1.0, _art.size.y))
				return
			if absf(d.x) > 110.0 and absf(d.x) > absf(d.y) * 1.5 and dt < 600 and _g_rub < 300.0:
				_swipe(-1 if d.x > 0 else 1)
			elif _g_rub < 60.0 and Game.owns(id):
				_touch_art(e.position.y / maxf(1.0, _art.size.y))
	elif e is InputEventMouseMotion and _g_down:
		if (e.position - _g_start).length() > 14.0:
			_g_moved = true
		if _pinch.active():
			return
		if _hz > 1.01:
			_holder.position += (e.relative as Vector2) * _hz
			return
		if Game.owns(id) and e.position.y / maxf(1.0, _art.size.y) < 0.3:
			_g_rub += (e.relative as Vector2).length()
			if _g_rub > 60.0:
				_head_pat(_art.position + e.position)

func _swipe(dir: int) -> void:
	if _list.size() < 2:
		return
	var i := _list.find(id)
	Game.sfx("ui_click")
	var nid: String = _list[posmod(i + dir, _list.size())]
	var tw := _art.create_tween().set_parallel(true)
	tw.tween_property(_art, "position:x", _art.position.x - dir * 160.0, 0.16).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_art, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(func(): main.replace("hero_detail", {"id": nid, "list": _list, "tab": _tab, "swipe": dir}))

func _head_pat(at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - _g_pat_t < 140:
		return
	_g_pat_t = now
	var l := UI.label("♥", 30, Color("#ff8fb8"), 6)
	l.position = at + Vector2(randf_range(-40, 20), -30)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 20
	add_child(l)
	var lt := l.create_tween().set_parallel(true)
	lt.tween_property(l, "position:y", l.position.y - 60, 0.9)
	lt.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.4)
	lt.chain().tween_callback(l.queue_free)
	var lean := _art.create_tween()
	lean.tween_property(_art, "rotation", 0.018 if randf() < 0.5 else -0.018, 0.12).set_trans(Tween.TRANS_SINE)
	lean.tween_property(_art, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	if _g_rub > 520.0 and not _g_spoke:
		_g_spoke = true
		Game.tap_hero(id)
		Game.add_bond(id, 6)
		UI.flash_expression(_art, DB.alt_art(id, int(Game.hero(id).get("skin", 0))))
		main.toast("%s: \"%s\"" % [DB.name_of(id), Game.voice(id, "bond")], Color("#ff8fb8"))
		_gift_hearts()
		get_tree().create_timer(4.0).timeout.connect(func(): _g_spoke = false)

func _close_up() -> void:
	if _hz > 1.01:
		return
	Game.sfx("ui_click")
	main.toast("%s: \"%s\"" % [DB.name_of(id), Game.voice(id, "greet")], Color("#ff8fb8"))
	_holder.pivot_offset = _art.position + Vector2(_art.size.x * 0.5, _art.size.y * 0.2)
	var tw := _holder.create_tween()
	tw.tween_property(_holder, "scale", Vector2(1.6, 1.6), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(_holder, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_CUBIC)

func _open_viewer() -> void:
	var allowed: Array = [0]
	if Game.owns(id):
		allowed = []
		for i in DB.art_list(id).size():
			if Game.skin_unlocked(id, i):
				allowed.append(i)
	ArtViewer.open(main, id, int(Game.hero(id).get("skin", 0)) if Game.owns(id) else 0, allowed)

func _ceremony(after: Callable) -> void:
	var oc := OathCeremony.new(id)
	main.overlay.add_child(oc)
	if after.is_valid():
		oc.finished.connect(after)

## Tap the hero art: head = affection, body = shy, legs = startled (with voice).
func _touch_art(ry: float) -> void:
	if _touch_busy:
		return
	_touch_busy = true
	var cat := "bond" if ry < 0.3 and int(Game.hero(id)["bond"]) >= 3 else ("greet" if ry < 0.3 else "tap")
	var line := Game.voice(id, cat)
	Game.tap_hero(id)
	CharRig.attach(_art).react(ry)
	UI.flash_expression(_art, DB.alt_art(id, int(Game.hero(id).get("skin", 0))))
	var tw := _art.create_tween()
	if ry < 0.3:
		tw.tween_property(_art, "scale", Vector2(1.02, 0.975), 0.12)
		tw.tween_property(_art, "scale", Vector2.ONE, 0.18)
	elif ry < 0.62:
		for i in 3:
			tw.tween_property(_art, "rotation", 0.02, 0.06)
			tw.tween_property(_art, "rotation", -0.02, 0.06)
		tw.tween_property(_art, "rotation", 0.0, 0.06)
	else:
		var y0 := _art.position.y
		tw.tween_property(_art, "position:y", y0 - 30, 0.14).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_art, "position:y", y0, 0.3).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_callback(func(): _touch_busy = false)
	main.toast("%s: \"%s\"" % [DB.name_of(id), line], Color("#ff8fb8"))

func _render_upgrade() -> void:
	var h := Game.hero(id)
	# --- Level
	var lp := UI.panel("CardPanel")
	_panel_box.add_child(lp)
	var lv := UI.vbox(6)
	lp.add_child(lv)
	var cap := Game.hero_cap(id)
	lv.add_child(UI.label("LEVEL  %d / %d" % [h["level"], cap] + ("   LB%d" % int(h.get("lb", 0)) if int(h.get("lb", 0)) > 0 else ""), 20, UI.GOLD, 3))
	lv.add_child(UI.bar(h["level"], cap, "GoldBar", 10))
	var cur := Game.hero_stats(id)
	if h["level"] < cap:
		var nxt := DB.stats_for(id, h["level"] + 1, h["star"], h["bond"], h["oath"])
		lv.add_child(UI.label("Next: HP +%d  ATK +%d  DEF +%d" % [nxt["hp"] - cur["hp"], nxt["atk"] - cur["atk"], nxt["def"] - cur["def"]], 14, UI.GREEN))
		var cost := UI.hbox(12)
		cost.add_child(UI.tex_rect(DB.icon("icon_crystal"), Vector2(26, 26)))
		cost.add_child(UI.label("%s EXP (have %s)" % [Game.fmt(DB.exp_to_next(h["level"])), Game.fmt(Game.amount("hero_exp"))], 15))
		cost.add_child(UI.tex_rect(DB.icon("icon_gold"), Vector2(26, 26)))
		cost.add_child(UI.label("%s" % Game.fmt(DB.gold_to_next(h["level"])), 15))
		lv.add_child(cost)
	var btns := UI.hbox(10)
	lv.add_child(btns)
	for n in [1, 5, 99]:
		var times: int = n
		var b := UI.button("LEVEL UP" if n == 1 else ("+5" if n == 5 else "MAX"), func(): _do_level(times), "GoldButton" if n == 1 else "", Vector2(0, 48))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btns.add_child(b)
	var exp_pots := Game.amount("exp_potion")
	if exp_pots > 0:
		lv.add_child(UI.button("Use %d EXP Potion(s) → +%s Hero EXP" % [exp_pots, Game.fmt(exp_pots * 1000)], func(): Game.use_item("exp_potion", exp_pots); _render(), "", Vector2(0, 42)))

	# --- Skill
	var kp := UI.panel("CardPanel")
	_panel_box.add_child(kp)
	var kv := UI.vbox(6)
	kp.add_child(kv)
	var slv := int(h["skill_lv"])
	var kh := UI.hbox(8)
	kh.add_child(UI.tex_rect(DB.icon("icon_skill_ultimate"), Vector2(28, 28)))
	kh.add_child(UI.label("SKILL  %s  Lv.%d / %d" % [DB.skill_of(id)["name"], slv, DB.MAX_SKILL_LV], 18, UI.GOLD, 3))
	kv.add_child(kh)
	kv.add_child(UI.bar(slv, DB.MAX_SKILL_LV, "GoldBar", 8))
	if slv < DB.MAX_SKILL_LV:
		var kc := Game.skill_up_cost(id)
		kv.add_child(UI.label("Next: skill power %d%% → %d%%   •   Skill Book %d/%d   •   Gold %s" % [100 + 12 * (slv - 1), 100 + 12 * slv, Game.amount("skill_book"), kc["skill_book"], Game.fmt(kc["gold"])], 13, UI.TEXT))
		var kb := UI.button("SKILL UP", func():
			var err := Game.skill_up(id)
			if err != "":
				main.toast(err, UI.RED)
			else:
				Game.sfx("battle/buff")
				main.toast("%s Lv.%d!" % [DB.skill_of(id)["name"], Game.hero(id)["skill_lv"]], UI.GREEN)
				_upgrade_fx("SKILL UP!", Color("#9fd0ff"), DB.element_of(id))
			_render(), "GoldButton", Vector2(0, 44))
		kb.disabled = Game.amount("skill_book") < int(kc["skill_book"])
		kv.add_child(kb)
	else:
		kv.add_child(UI.label("Skill mastered! (+48% power)", 14, UI.GREEN))

	# --- Star
	var sp := UI.panel("CardPanel")
	_panel_box.add_child(sp)
	var sv := UI.vbox(6)
	sp.add_child(sv)
	var sh := UI.hbox(10)
	sh.add_child(UI.label("STAR UP", 20, UI.GOLD, 3))
	sh.add_child(UI.stars(h["star"], 20, DB.MAX_STAR))
	sv.add_child(sh)
	if h["star"] >= DB.MAX_STAR:
		sv.add_child(UI.label("Maximum stars reached!", 16, UI.GREEN))
	else:
		var c := Game.star_up_cost(id)
		var own := int(Game.s["shards"].get(id, 0))
		var uni := Game.amount("star_stone")
		sv.add_child(UI.label("Shards %d (+%d universal) / %d   •   Gold %s" % [own, uni, c["shards"], Game.fmt(c["gold"])], 15))
		sv.add_child(UI.bar(own + uni, c["shards"], "", 10))
		sv.add_child(UI.wrap_label("+14%% all stats, level cap → %d, unlocks a new outfit. 5★ upgrades the battle sprite to its evolved form." % DB.level_cap(h["star"] + 1), 13, UI.MUTED))
		var b2 := UI.button("STAR UP ★", _do_star, "GoldButton", Vector2(0, 50))
		b2.disabled = own + uni < c["shards"]
		sv.add_child(b2)
		sv.add_child(UI.wrap_label("Get shards from duplicate summons, story drops and the Arena Shop.", 12, UI.MUTED))

	# --- Awakening (after max stars)
	var ap := UI.panel("CardPanel")
	_panel_box.add_child(ap)
	var av := UI.vbox(6)
	ap.add_child(av)
	var aw := int(h.get("awaken", 0))
	var ah := UI.hbox(8)
	ah.add_child(UI.tex_rect(DB.icon("icon_awakening"), Vector2(30, 30)))
	ah.add_child(UI.label("AWAKENING  A%d / %d" % [aw, DB.MAX_AWAKEN], 18, Color("#ffcf4a"), 3))
	av.add_child(ah)
	av.add_child(UI.bar(aw, DB.MAX_AWAKEN, "GoldBar", 8))
	av.add_child(UI.wrap_label("Each level: +6% HP/ATK/DEF.  A3: skill power +1 level.  A5: golden aura in battle.", 12, UI.MUTED))
	if aw < DB.MAX_AWAKEN:
		var ac := Game.awaken_cost(id)
		av.add_child(UI.label("Cost: %d shards (have %d + %d universal) • %s Gold" % [ac["shards"], int(Game.s["shards"].get(id, 0)), Game.amount("star_stone"), Game.fmt(ac["gold"])], 13, UI.TEXT))
		var block := Game.awaken_block(id)
		var abtn := UI.button("AWAKEN ✦" if block == "" else block, func():
			var err := Game.awaken(id)
			if err != "":
				main.toast(err, UI.RED)
				return
			Game.sfx("awakening")
			Game.voice(id, "bond")
			_upgrade_fx("AWAKENED!", Color("#ffcf4a"), "FIRE")
			_celebrate("✦ AWAKENING A%d ✦" % Game.hero(id)["awaken"], "%s's power surges! (+6%% all stats)" % DB.name_of(id))
			_render(), "GoldButton", Vector2(0, 48))
		abtn.disabled = block != ""
		av.add_child(abtn)
	# --- Limit Break (6★ at level cap → cap +5, up to Lv.100)
	if int(h["star"]) >= DB.MAX_STAR:
		tutorial("limit_break")
		var lbp := UI.panel("CardPanel")
		_panel_box.add_child(lbp)
		var lbv := UI.vbox(6)
		lbp.add_child(lbv)
		var lb := int(h.get("lb", 0))
		var lh := UI.hbox(8)
		lh.add_child(UI.tex_rect(DB.icon("icon_shards"), Vector2(30, 30)))
		lh.add_child(UI.label("LIMIT BREAK  %d / %d" % [lb, DB.MAX_LB], 18, Color("#7ff6ff"), 3))
		lbv.add_child(lh)
		lbv.add_child(UI.bar(lb, DB.MAX_LB, "GoldBar", 8))
		lbv.add_child(UI.wrap_label("Raise the level cap by +%d (max Lv.%d). Hunt Cores come from Boss Hunt." % [DB.LB_STEP, DB.level_cap(DB.MAX_STAR, DB.MAX_LB)], 12, UI.MUTED))
		if lb < DB.MAX_LB:
			var lc := DB.lb_cost(lb)
			lbv.add_child(UI.label("Cost: %d Hunt Cores (have %d) • %d shards • %s Gold" % [lc["hunt_core"], Game.amount("hunt_core"), lc["shards"], Game.fmt(lc["gold"])], 13, UI.TEXT))
			var lblock := Game.limit_break_block(id)
			var lbb := UI.button("LIMIT BREAK  →  Lv.%d" % (Game.hero_cap(id) + DB.LB_STEP) if lblock == "" else lblock, func():
				var err := Game.limit_break(id)
				if err != "":
					main.toast(err, UI.RED)
					return
				Game.sfx("awakening")
				Game.voice(id, "bond")
				_upgrade_fx("LIMIT BREAK!", Color("#7ff6ff"), "LIGHTNING")
				_celebrate("✦ LIMIT BREAK %d ✦" % int(Game.hero(id)["lb"]), "%s can now reach Lv.%d!" % [DB.name_of(id), Game.hero_cap(id)])
				_render(), "GoldButton", Vector2(0, 48))
			lbb.disabled = lblock != ""
			lbv.add_child(lbb)

func _do_level(times: int) -> void:
	var n := Game.level_up(id, times)
	if n == 0:
		main.toast(Game.level_up_block_reason(id), UI.RED)
		return
	Game.sfx("star_up")
	main.toast("%s reached Lv.%d!" % [DB.name_of(id), Game.hero(id)["level"]], UI.GREEN)
	_upgrade_fx("LEVEL UP!  Lv.%d" % Game.hero(id)["level"], UI.GREEN, "LIGHT")
	_render()

func _do_star() -> void:
	var err := Game.star_up(id)
	if err != "":
		main.toast(err, UI.RED)
		return
	Game.sfx("awakening")
	_upgrade_fx("★ STAR UP ★", UI.GOLD, "LIGHT")
	_celebrate("★ STAR UP ★", "%s is now %d★!" % [DB.name_of(id), Game.hero(id)["star"]])
	_render()

## Upgrade feedback on the hero art: element burst, rising sparkles, big pop text, hop.
func _upgrade_fx(text: String, col: Color, elem: String = "LIGHT") -> void:
	if not is_instance_valid(_fxn):
		_fxn = SkillFX.new()
		_fxn.z_index = 30
		add_child(_fxn)
	var c := _art.get_global_rect().get_center() - get_global_rect().position
	_fxn.impact(elem, c + Vector2(0, _art.size.y * 0.15), col, 160.0)
	_fxn.wave(c, col, 420.0)
	_fxn.aura(c + Vector2(0, _art.size.y * 0.35), col, 220.0)
	var l := UI.label(text, 40, col.lightened(0.3), 10)
	l.size = Vector2(600, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = c - Vector2(300, 60)
	l.pivot_offset = Vector2(300, 30)
	l.z_index = 31
	add_child(l)
	l.scale = Vector2(0.4, 0.4)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2(1.1, 1.1), 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(l, "scale", Vector2.ONE, 0.1)
	tw.tween_property(l, "position:y", l.position.y - 70, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tw.tween_callback(l.queue_free)
	var y0 := _art.position.y
	var ht := _art.create_tween()
	ht.tween_property(_art, "position:y", y0 - 18, 0.14).set_trans(Tween.TRANS_QUAD)
	ht.tween_property(_art, "position:y", y0, 0.3).set_trans(Tween.TRANS_BOUNCE)
	var mt := _art.create_tween()
	mt.tween_property(_art, "self_modulate", Color(1.5, 1.5, 1.5), 0.1)
	mt.tween_property(_art, "self_modulate", Color.WHITE, 0.4)

## Hearts float up from the hero when she receives a gift.
func _gift_hearts() -> void:
	var c := _art.get_global_rect().get_center() - get_global_rect().position
	for i in 10:
		var h := UI.tex_rect(DB.icon("icon_heart"), Vector2(30, 30))
		h.size = Vector2(30, 30)
		h.z_index = 30
		h.position = c + Vector2(randf_range(-140, 140), randf_range(-40, 120))
		add_child(h)
		h.scale = Vector2(0.3, 0.3)
		h.pivot_offset = Vector2(15, 15)
		var tw := h.create_tween().set_parallel(true)
		tw.tween_property(h, "scale", Vector2(randf_range(0.8, 1.3), randf_range(0.8, 1.3)), 0.25).set_delay(i * 0.04).set_trans(Tween.TRANS_BACK)
		tw.tween_property(h, "position:y", h.position.y - randf_range(120, 220), 1.2).set_delay(i * 0.04).set_trans(Tween.TRANS_SINE)
		tw.tween_property(h, "modulate:a", 0.0, 0.6).set_delay(0.7 + i * 0.04)
		tw.chain().tween_callback(h.queue_free)
	var mt := _art.create_tween()
	mt.tween_property(_art, "self_modulate", Color(1.2, 0.9, 1.0), 0.2)
	mt.tween_property(_art, "self_modulate", Color.WHITE, 0.6)

func _celebrate(title: String, sub: String) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0.9, 0.6, 0.7)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, 0.7)
	var v: VBoxContainer = main.popup(title, 520)
	var art := UI.tex_rect(DB.art(id, int(Game.hero(id)["skin"])), Vector2(0, 340))
	v.add_child(art)
	UI.live(art, DB.theme_color(id).lightened(0.5))
	var l := UI.label(sub, 20, Color.WHITE, 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var ok := UI.button("OK", func(): main.close_popup(v), "GoldButton", Vector2(180, 48))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)

func _render_gear() -> void:
	var b := Game.stat_bonus(id)
	var top := UI.hbox(10)
	_panel_box.add_child(top)
	var crit_txt := "   Crit +%.1f%%" % (b["crit"] * 100) if float(b["crit"]) > 0.0 else ""
	var bl := UI.label("Bonus  HP +%.1f%%   ATK +%.1f%%   DEF +%.1f%%%s" % [b["hp"] * 100, b["atk"] * 100, b["def"] * 100, crit_txt], 15, UI.GREEN, 2)
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(bl)
	var acts := UI.hbox(10)
	_panel_box.add_child(acts)
	var aeb := UI.button("AUTO EQUIP", func():
		var n := Game.auto_equip(id)
		main.toast("Equipped %d item(s)." % n if n > 0 else "No better free equipment.", UI.GREEN if n > 0 else UI.MUTED)
		_render(), "GoldButton", Vector2(0, 42))
	aeb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acts.add_child(aeb)
	var wsb := UI.button("WEAR SET", _pick_set, "", Vector2(0, 42))
	wsb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acts.add_child(wsb)
	if Game.guild_bonus() > 0.0:
		_panel_box.add_child(UI.label("Includes guild buff +%d%% ATK/HP" % int(Game.guild_bonus() * 100), 12, UI.MUTED))
	for slot in DB.GEAR_SLOTS:
		var sl: String = slot
		var g := Game.gear_on(id, slot)
		var p := UI.panel("CardPanel")
		_panel_box.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		var rc: Color = DB.RARITY_COLOR.get(g.get("rarity", ""), Color("#4a3a6e"))
		var ip := UI.styled_panel(Color(0, 0, 0, 0.6), rc, 10, 2, 4)
		var ic := UI.tex_rect(DB.icon(DB.GEAR[slot]["icon"]), Vector2(56, 56))
		if g.is_empty():
			ic.modulate = Color(1, 1, 1, 0.3)
		ip.add_child(ic)
		h.add_child(ip)
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(slot.to_upper(), 12, UI.MUTED))
		if g.is_empty():
			v.add_child(UI.label("Empty", 17, UI.MUTED))
		else:
			v.add_child(UI.label("%s  [%s]" % [DB.gear_name(g), g["rarity"]], 17, rc.lightened(0.3), 2))
			v.add_child(UI.label(DB.gear_desc(g), 13, UI.GREEN))
			v.add_child(UI.label(DB.gear_subs_desc(g), 12, UI.SUB_STAT))
			var gsd: Dictionary = DB.GEAR_SETS[DB.gear_set(g)]
			v.add_child(UI.label("◆ " + str(gsd["name"]), 12, Color(str(gsd["color"])), 2))
		var bv := UI.vbox(4)
		h.add_child(bv)
		bv.add_child(UI.button("CHANGE", func(): _pick_gear(sl), "", Vector2(120, 36)))
		if not g.is_empty():
			var uid: int = g["uid"]
			var eb := UI.button("+%d  %s G" % [int(g["lv"]) + 1, Game.fmt(DB.gear_enhance_cost(g))] if int(g["lv"]) < DB.GEAR_MAX_LV else "MAX +10", func():
				var err := Game.enhance_gear(uid)
				if err != "":
					main.toast(err, UI.RED)
				else:
					Game.sfx("star_up")
					if not Game.last_sub_up.is_empty():
						main.toast("Substat upgraded: " + DB.gear_sub_text(Game.last_sub_up), UI.SUB_STAT)
				_render(), "GoldButton", Vector2(120, 36))
			eb.disabled = int(g["lv"]) >= DB.GEAR_MAX_LV
			bv.add_child(eb)
	# --- set bonuses
	var sc := Game.gear_set_counts(id)
	var spn := UI.panel("CardPanel")
	_panel_box.add_child(spn)
	var sv0 := UI.vbox(4)
	spn.add_child(sv0)
	sv0.add_child(UI.label("SET BONUS", 16, UI.GOLD, 3))
	if sc.is_empty():
		sv0.add_child(UI.wrap_label("Wear 2 or 3 pieces of the same set for a bonus.", 12, UI.MUTED))
	for sid in sc.keys():
		var sd: Dictionary = DB.GEAR_SETS[sid]
		var n := int(sc[sid])
		var scol := Color(str(sd["color"]))
		sv0.add_child(UI.label("◆ %s  (%d/3)" % [sd["name"], n], 14, scol, 2))
		sv0.add_child(UI.label("   2: %s" % sd["two_text"], 12, UI.GREEN if n >= 2 else UI.MUTED, 1))
		sv0.add_child(UI.label("   3: %s" % sd["three_text"], 12, UI.GREEN if n >= 3 else UI.MUTED, 1))
	_panel_box.add_child(UI.wrap_label("Equipment drops from story stages (bosses always), the Tower, Gear Chests in the Shop, Guild Raids and events.", 12, UI.MUTED))
	# --- runes
	var rp := UI.panel("CardPanel")
	_panel_box.add_child(rp)
	var rv := UI.vbox(6)
	rp.add_child(rv)
	var rh := UI.hbox(8)
	rh.add_child(UI.label("RUNES", 18, UI.GOLD, 3))
	rh.add_child(UI.label("Crit +%.1f%%" % (float(b.get("crit", 0.0)) * 100.0), 14, Color("#ffd479")))
	rh.add_child(UI.spacer())
	rh.add_child(UI.button("AUTO", func():
		var n := Game.auto_runes(id)
		main.toast("Equipped %d rune(s)." % n if n > 0 else "No better free runes.", UI.GREEN if n > 0 else UI.MUTED)
		_render(), "", Vector2(90, 36)))
	rv.add_child(rh)
	var slots := UI.hbox(8)
	rv.add_child(slots)
	for si in DB.RUNE_SLOTS:
		var slot: int = si
		var r := Game.rune_on(id, slot)
		var sb := Button.new()
		sb.theme_type_variation = "TabButton"
		sb.focus_mode = Control.FOCUS_NONE
		sb.custom_minimum_size = Vector2(0, 76)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col: Color = DB.RUNES[r["type"]]["color"] if not r.is_empty() else Color("#4a3a6e")
		sb.add_theme_stylebox_override("normal", UI.style(Color(0.08, 0.05, 0.14, 1.0), col, 10, 2, 6))
		var sv := UI.vbox(0)
		sv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sv.alignment = BoxContainer.ALIGNMENT_CENTER
		sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sb.add_child(sv)
		var gem := _rune_gem(col, 0 if r.is_empty() else int(r["tier"]))
		gem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sv.add_child(gem)
		var sl := UI.label("Empty" if r.is_empty() else "+%.1f%% %s" % [DB.rune_value(r) * 100, str(DB.RUNES[r["type"]]["stat"]).to_upper()], 12, Color.WHITE if not r.is_empty() else UI.MUTED, 2)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_child(sl)
		sb.pressed.connect(func(): _pick_rune(slot))
		UI.hover_fx(sb)
		slots.add_child(sb)
	rv.add_child(UI.wrap_label("Runes drop from the Arena, Tower guardians and Daily Dungeons. Fuse 3 of the same rune in the Bag to upgrade its tier.", 12, UI.MUTED))

## Small diamond gem drawing for a rune (tier = number of pips).
func _rune_gem(col: Color, tier: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(40, 40)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := Vector2(20, 18)
		var pts := PackedVector2Array([m + Vector2(0, -15), m + Vector2(13, 0), m + Vector2(0, 15), m + Vector2(-13, 0)])
		c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.85 if tier > 0 else 0.15))
		var cl := pts.duplicate()
		cl.append(pts[0])
		c.draw_polyline(cl, Color(1, 1, 1, 0.7), 1.5, true)
		for i in tier:
			c.draw_circle(Vector2(20 - (tier - 1) * 4 + i * 8, 38), 2.5, UI.GOLD))
	return c

func _pick_rune(slot: int) -> void:
	var v: VBoxContainer = main.popup("RUNE SLOT %d" % (slot + 1), 620)
	var items: Array = Game.s["runes"].duplicate()
	items.sort_custom(func(a, b): return DB.rune_value(a) > DB.rune_value(b))
	var list := UI.vbox(6)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, mini(420, maxi(80, items.size() * 56)))
	v.add_child(sc)
	if items.is_empty():
		list.add_child(UI.wrap_label("You have no runes yet. Win Arena battles or open Rune Pouches (Shop).", 15, UI.MUTED))
	for r in items:
		var rr: Dictionary = r
		var h := UI.hbox(10)
		list.add_child(h)
		h.add_child(_rune_gem(DB.RUNES[rr["type"]]["color"], int(rr["tier"])))
		var iv := UI.vbox(0)
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		iv.add_child(UI.label(DB.rune_label(rr), 15, Color.WHITE))
		var owner := str(rr["owner"])
		iv.add_child(UI.label("on %s" % DB.name_of(owner) if owner != "" else "free", 12, UI.MUTED))
		h.add_child(iv)
		var mine := owner == id and int(rr["slot"]) == slot
		h.add_child(UI.button("REMOVE" if mine else "EQUIP", func():
			if mine:
				Game.unequip_rune(rr["uid"])
			else:
				Game.equip_rune(rr["uid"], id, slot)
			main.close_popup(v)
			_render(), "" if mine else "GoldButton", Vector2(110, 40)))
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

## One tap to dress the hero in a whole set (free pieces only, never from teammates).
func _pick_set() -> void:
	var v: VBoxContainer = main.popup("WEAR A SET", 680)
	for s0 in DB.GEAR_SET_IDS:
		var sid: String = s0
		var sd: Dictionary = DB.GEAR_SETS[sid]
		var n: int = Game.set_stock(id, sid).size()
		var h := UI.hbox(10)
		v.add_child(h)
		var iv := UI.vbox(0)
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		iv.add_child(UI.label("◆ %s  (%d/3 ready)" % [sd["name"], n], 15, Color(str(sd["color"])), 2))
		iv.add_child(UI.label("2: %s   •   3: %s" % [sd["two_text"], sd["three_text"]], 12, UI.MUTED))
		h.add_child(iv)
		var wb := UI.button("WEAR", func():
			var c := Game.auto_equip_set(id, sid)
			main.toast("Equipped %d piece(s) of %s." % [c, sd["name"]] if c > 0 else "Already wearing it.", UI.GREEN if c > 0 else UI.MUTED)
			main.close_popup(v)
			_render(), "GoldButton", Vector2(100, 40))
		wb.disabled = n == 0
		h.add_child(wb)
	var f := UI.hbox(10)
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(f)
	f.add_child(UI.button("OPEN FORGE", func(): main.go("forge"), "", Vector2(160, 44)))
	f.add_child(UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44)))

func _pick_gear(slot: String) -> void:
	var v: VBoxContainer = main.popup(slot.to_upper(), 620)
	var worn := Game.gear_set_counts(id)
	var here := Game.gear_on(id, slot)
	if not here.is_empty():
		worn[DB.gear_set(here)] = int(worn[DB.gear_set(here)]) - 1
	var items: Array = []
	for g in Game.s["gear"]:
		if g["slot"] == slot:
			items.append(g)
	items.sort_custom(func(a, b): return DB.gear_score(a) > DB.gear_score(b))
	if items.is_empty():
		v.add_child(UI.wrap_label("You don't own any %s yet." % slot, 15, UI.MUTED))
	var list := UI.vbox(6)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, mini(420, maxi(80, items.size() * 64)))
	v.add_child(sc)
	for g in items:
		var gg: Dictionary = g
		var h := UI.hbox(10)
		list.add_child(h)
		var rc: Color = DB.RARITY_COLOR[gg["rarity"]]
		h.add_child(UI.tex_rect(DB.icon(DB.GEAR[slot]["icon"]), Vector2(44, 44)))
		var iv := UI.vbox(0)
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var with_set := int(worn.get(DB.gear_set(gg), 0)) + 1
		iv.add_child(UI.label("%s [%s]  ◆ %s%s" % [DB.gear_name(gg), gg["rarity"], DB.GEAR_SETS[DB.gear_set(gg)]["name"], "  ★ %d/3" % with_set if with_set >= 2 else ""], 15, rc.lightened(0.3)))
		var owner := str(gg["owner"])
		iv.add_child(UI.label(DB.gear_desc(gg) + ("   • on %s" % DB.name_of(owner) if owner != "" else ""), 12, UI.MUTED))
		iv.add_child(UI.label(DB.gear_subs_desc(gg), 12, UI.SUB_STAT))
		h.add_child(iv)
		var is_mine := owner == id
		h.add_child(UI.button("REMOVE" if is_mine else "EQUIP", func():
			if is_mine:
				Game.unequip(gg["uid"])
			else:
				Game.equip(gg["uid"], id)
			main.close_popup(v)
			_render(), "" if is_mine else "GoldButton", Vector2(110, 40)))
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

func _render_outfits() -> void:
	var arts := DB.art_list(id)
	_panel_box.add_child(UI.wrap_label("Outfits unlock through Star Up, Bond levels and the Oath. Each outfit tier also grants +2% ATK & HP while worn (max +10%).", 14, UI.MUTED))
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	_panel_box.add_child(g)
	for i in arts.size():
		var idx: int = i
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		# cells share the panel width; a fixed width pushed the third column off-screen
		b.custom_minimum_size = Vector2(0, 200)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		var fr := Panel.new()
		var eq := int(Game.hero(id)["skin"]) == i
		fr.add_theme_stylebox_override("panel", UI.style(Color(0.04, 0.03, 0.08, 1.0), UI.GOLD if eq else Color("#4a3a6e"), 10, 3 if eq else 1, 0))
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		b.add_child(fr)
		var t := UI.tex_rect(DB.tex(arts[i]), Vector2.ZERO, true)
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_child(t)
		var cap := UI.label("", 13, Color.WHITE, 4)
		cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		cap.offset_top = -24
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fr.add_child(cap)
		if Game.skin_unlocked(id, i):
			cap.text = ("EQUIPPED" if eq else "Outfit %d" % (i + 1)) + ("  +%d%%" % int(DB.outfit_bonus(i) * 100) if i > 0 else "")
			b.pressed.connect(func():
				Game.sfx("ui_click")
				Game.set_skin(id, idx)
				_render()
				_upgrade_fx("OUTFIT CHANGE", Color("#ff8fb8"), "LIGHT"))
		else:
			t.modulate = Color(0.15, 0.15, 0.2)
			cap.text = "LOCKED • " + Game.skin_lock_label(id, i)
			if i == DB.special_index(id):
				var is_ev := DB.EVENT_SKINS.has(id) and str(DB.EVENT.get("skin", "")) == id
				var wb := UI.button("EVENT ▶" if is_ev else "WARDROBE ▶", func(): main.go("event" if is_ev else "wardrobe", {"hero": id}), "GoldButton", Vector2(0, 30))
				wb.add_theme_font_size_override("font_size", 12)
				wb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
				wb.offset_left = -52
				wb.offset_right = 52
				wb.offset_top = -16
				wb.offset_bottom = 16
				fr.add_child(wb)
				fr.mouse_filter = Control.MOUSE_FILTER_PASS
				g.add_child(b)
				continue
			var ib := UI.button("UNLOCK %d💎" % DB.costume_price(i), func():
				main.confirm("Unlock outfit %d of %s now for %d Gems?" % [idx + 1, DB.name_of(id), DB.costume_price(idx)], func():
					var err := Game.buy_costume(id, idx)
					if err != "":
						main.toast(err, UI.RED)
					else:
						Game.sfx("awakening")
						Game.set_skin(id, idx)
						main.toast("New outfit unlocked!", Color("#ff8fb8"))
					_render(), "UNLOCK"), "GoldButton", Vector2(0, 30))
			ib.text = "UNLOCK\n%d Gems" % DB.costume_price(i)
			ib.add_theme_font_size_override("font_size", 12)
			ib.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			ib.offset_left = -52
			ib.offset_right = 52
			ib.offset_top = -24
			ib.offset_bottom = 24
			fr.add_child(ib)
			fr.mouse_filter = Control.MOUSE_FILTER_PASS
		g.add_child(b)

func _read_memory(ep: int) -> void:
	main.dialogue(DB.bond_story(id, ep), func():
		var r := Game.read_bond_story(id, ep)
		if not r.is_empty():
			main.show_rewards("MEMORY UNLOCKED", r)
		_render(), "lobby", false, id if ep == 2 else "", "%s_3" % id)

func _render_bond() -> void:
	var h := Game.hero(id)
	var bp := UI.panel("CardPanel")
	_panel_box.add_child(bp)
	var v := UI.vbox(6)
	bp.add_child(v)
	var hh := UI.hbox(8)
	hh.add_child(UI.tex_rect(DB.icon("icon_heart"), Vector2(36, 36)))
	hh.add_child(UI.label("BOND Lv.%d / %d" % [h["bond"], DB.MAX_BOND], 22, Color("#ff8fb8"), 3))
	v.add_child(hh)
	if h["bond"] < DB.MAX_BOND:
		v.add_child(UI.bar(h["bond_exp"], DB.bond_to_next(h["bond"]), "", 12))
		v.add_child(UI.label("%d / %d EXP" % [h["bond_exp"], DB.bond_to_next(h["bond"])], 13, UI.MUTED))
	v.add_child(UI.wrap_label("Each Bond level gives +2% all stats. Tap her in the lobby (5×/day) or give gifts.", 13, UI.MUTED))

	var tp := UI.panel("CardPanel")
	_panel_box.add_child(tp)
	var th := UI.hbox(10)
	tp.add_child(th)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label("DAILY TALK", 18, UI.GOLD, 3))
	tv.add_child(UI.wrap_label("Chat with %s — answers she likes give more Bond. Talks left today: %d" % [DB.name_of(id), Game.talks_left()], 13, UI.TEXT))
	th.add_child(tv)
	var tb := UI.button("TALK ♥", func():
		main.talk(id)
		get_tree().create_timer(0.3).timeout.connect(func(): if is_inside_tree(): _render()), "GoldButton", Vector2(120, 46))
	tb.disabled = Game.talks_left() <= 0
	th.add_child(tb)

	var mp := UI.panel("CardPanel")
	_panel_box.add_child(mp)
	var mv := UI.vbox(6)
	mp.add_child(mv)
	mv.add_child(UI.label("MEMORIES", 18, UI.GOLD, 3))
	for ep in DB.BOND_STORY_REQ.size():
		var e: int = ep
		var r := UI.hbox(10)
		mv.add_child(r)
		var unlocked := Game.bond_story_unlocked(id, ep)
		var read := Game.bond_story_read(id, ep)
		var nv := UI.vbox(0)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_child(UI.label("Ep.%d  %s" % [ep + 1, DB.bond_story_title(id, ep)], 16, Color.WHITE if unlocked else UI.MUTED, 2))
		nv.add_child(UI.label("Unlocks at Bond Lv.%d" % DB.BOND_STORY_REQ[ep] if not unlocked else ("Read again" if read else "NEW! First read: " + Game.reward_text(DB.BOND_STORY_REWARDS[ep])), 12, UI.GREEN if unlocked and not read else UI.MUTED))
		r.add_child(nv)
		var b := UI.button("READ" if unlocked else "LOCKED", func(): _read_memory(e), "GoldButton" if unlocked and not read else "", Vector2(100, 40))
		b.disabled = not unlocked
		r.add_child(b)

	var gp := UI.panel("CardPanel")
	_panel_box.add_child(gp)
	# gifts are the main Bond action (and a First Steps goal): keep them right under the bar
	_panel_box.move_child(gp, bp.get_index() + 1)
	var gv := UI.vbox(8)
	gp.add_child(gv)
	gv.add_child(UI.label("GIVE A GIFT", 18, UI.GOLD, 3))
	var fav := DB.fav_gift(id)
	gv.add_child(UI.label("♥ Favourite: %s (x2 Bond EXP)" % DB.ITEMS[fav]["name"], 14, Color("#ff8fb8"), 2))
	for item_id in DB.GIFTS + DB.DISH_GIFTS:
		var it: Dictionary = DB.ITEMS[item_id]
		var iid: String = item_id
		var r := UI.hbox(10)
		r.add_child(UI.tex_rect(DB.icon(it["icon"]), Vector2(44, 44)))
		var nv := UI.vbox(0)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_child(UI.label("%s  x%d" % [it["name"], Game.amount(item_id)], 16))
		var is_fav: bool = item_id == fav
		nv.add_child(UI.label("+%d Bond EXP%s" % [int(it["bond"]) * (2 if is_fav else 1), "  ♥ FAVOURITE" if is_fav else ""], 13, Color("#ff8fb8") if is_fav else UI.GREEN))
		r.add_child(nv)
		var b := UI.button("GIVE", func():
			var err := Game.give_gift(id, iid)
			if err != "":
				main.toast(err, UI.RED)
			else:
				main.toast("\"%s\"" % Game.voice(id, "bond"), Color("#ff8fb8"))
				_gift_hearts()
			_render(), "", Vector2(100, 44))
		b.disabled = Game.amount(item_id) <= 0 or h["bond"] >= DB.MAX_BOND
		r.add_child(b)
		gv.add_child(r)

	var op := UI.panel("CardPanel")
	_panel_box.add_child(op)
	var ov := UI.vbox(8)
	op.add_child(ov)
	var oh := UI.hbox(8)
	oh.add_child(UI.tex_rect(DB.icon("item_oath_ring"), Vector2(44, 44)))
	oh.add_child(UI.label("OATH CEREMONY", 18, UI.GOLD, 3))
	ov.add_child(oh)
	if h["oath"]:
		ov.add_child(UI.label("You have sworn an eternal Oath with %s. ♥" % DB.name_of(id), 15, Color("#ff8fb8")))
		ov.add_child(UI.label("Bound on %s" % Game.oath_date(id), 13, Color("#ffe6a3"), 2))
		ov.add_child(UI.button("♥ REPLAY CEREMONY", func(): _ceremony(Callable()), "", Vector2(0, 42)))
	else:
		ov.add_child(UI.wrap_label("Requires Bond Lv.10 and an Oath Ring (Arena Shop). Grants +10% all stats and unlocks a special outfit.", 13, UI.MUTED))
		var ob := UI.button("SWEAR OATH (Rings: %d)" % Game.amount("oath_ring"), func():
			var err := Game.swear_oath(id)
			if err != "":
				main.toast(err, UI.RED)
				return
			_render()
			_ceremony(func(): main.dialogue([[id, DB.VOICE["oath"][0]], [id, DB.voice(id, "bond")["en"]]], Callable(), "", false, id, "%s_oath" % id)), "GoldButton", Vector2(0, 50))
		ob.disabled = h["bond"] < DB.MAX_BOND or Game.amount("oath_ring") <= 0
		ov.add_child(ob)
