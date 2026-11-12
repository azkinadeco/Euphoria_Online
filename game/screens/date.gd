extends Screen
## Dates: pick a hero (Bond 3+) and a spot, play a short scene with 3 choices,
## get a rank (Perfect / Sweet / Nice) and a Date Photo saved in the album.

var _tab := "go"
var _hero := ""
var _spot := "forest"

func build() -> void:
	_tab = str(params.get("tab", "go"))
	_hero = str(params.get("hero", ""))
	if _hero == "" or not Game.can_date(_hero):
		_hero = _best_hero()
	_spot = str(params.get("spot", "forest"))
	set_bg(_spot, 0.45)
	ambient(Color(1.0, 0.8, 0.9), 26)
	var bar := header("DATE", ["gems"])
	for t in [["go", "GO ON A DATE"], ["album", "DATE ALBUM (%d)" % Game.date_album().size()]]:
		var key: String = t[0]
		var tb := UI.button(t[1], func(): main.replace("date", {"tab": key, "hero": _hero, "spot": _spot}), "TabButton", Vector2(0, 42))
		tb.toggle_mode = true
		tb.button_pressed = key == _tab
		bar.add_child(tb)
		bar.move_child(tb, 4 + int(key == "album"))
	var b := body(76)
	if _tab == "album":
		_build_album(b)
	else:
		_build_go(b)
	tutorial("date")

func _best_hero() -> String:
	var best := ""
	for id in Game.s["heroes"].keys():
		if Game.can_date(id) and (best == "" or int(Game.hero(id)["bond"]) > int(Game.hero(best)["bond"])):
			best = id
	return best

const RANK_SHORT := ["PERFECT", "SWEET", "NICE"]

func _rank_col(ri: int) -> Color:
	return Color(str(DB.DATE_RANKS[clampi(ri, 0, 2)][2]))

func _build_go(b: Control) -> void:
	# ---- left: spots (with the best rank reached with the current partner)
	var lp := UI.panel()
	lp.anchor_right = 0.3
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(6)
	lp.add_child(UI.scroll(lv))
	var lh := UI.hbox(6)
	lv.add_child(lh)
	var lt := UI.label("DATE SPOTS", 15, UI.GOLD, 3)
	lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lh.add_child(lt)
	if _hero != "":
		lh.add_child(UI.label("✦ %d / %d PERFECT" % [Game.date_perfects(_hero), DB.DATE_SPOTS.size()], 12, Color("#ffd479"), 2))
	for sp in DB.DATE_SPOTS:
		var key: String = sp["key"]
		var open := Game.date_spot_open(sp)
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 70)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color.BLACK, UI.GOLD if key == _spot else Color("#4a3a6e"), 10, 3 if key == _spot else 1, 0))
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(fr)
		var th := UI.tex_rect(DB.bg(key), Vector2.ZERO, true)
		th.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		th.modulate = Color(0.8, 0.8, 0.85) if open else Color(0.25, 0.25, 0.3)
		fr.add_child(th)
		var nl := UI.label(str(sp["name"]) if open else "🔒  %s  •  %d / %d stages" % [str(sp["name"]).split(" ")[0], mini(Game.stages_cleared(), int(sp["req"])), int(sp["req"])], 13, Color.WHITE if open else UI.MUTED, 4)
		nl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		nl.offset_top = -24
		nl.offset_left = 8
		fr.add_child(nl)
		if open and _hero != "":
			var ri := Game.date_best(_hero, key)
			var bc: Color = _rank_col(ri) if ri >= 0 else Color("#b8b0d0")
			var badge := UI.styled_panel(Color(0.05, 0.02, 0.08, 0.85), Color(bc, 0.9), 8, 1, 0)
			badge.add_child(UI.label((" ✦ %s " % RANK_SHORT[ri]) if ri >= 0 else " NEW ", 11, bc, 2))
			badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			badge.offset_left = -6
			badge.offset_right = -6
			badge.offset_top = 6
			badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fr.add_child(badge)
		btn.pressed.connect(func():
			if not open:
				main.toast("Locked — clear %d story stages." % int(sp["req"]), UI.MUTED)
				return
			main.replace("date", {"tab": "go", "hero": _hero, "spot": key}))
		lv.add_child(btn)
	# ---- centre: the hero + invitation bubble + name plate
	if _hero == "":
		_build_no_partner(b)
		return
	var tc := DB.theme_color(_hero)
	var art := UI.tex_rect(DB.art(_hero, int(Game.hero(_hero).get("skin", 0))))
	art.anchor_left = 0.3
	art.anchor_right = 0.66
	art.anchor_bottom = 1.0
	art.offset_top = 10
	UI.live(art, tc.lightened(0.5))
	b.add_child(art)
	UI.fade_in(art, 0.4, Vector2(0, 20))
	var info: Array = DB.DATE_SPOT_INFO.get(_spot, ["", "Shall we go somewhere together?"])
	var bwrap := CenterContainer.new()
	bwrap.anchor_left = 0.3
	bwrap.anchor_right = 0.66
	bwrap.offset_top = 4
	bwrap.offset_bottom = 84
	bwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bwrap)
	var bub := UI.styled_panel(Color(1, 0.97, 0.99, 0.95), Color(tc.lightened(0.2), 0.9), 16, 2, 10)
	bub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bl := UI.wrap_label("\u201c%s\u201d" % str(info[1]), 14, Color(0.2, 0.1, 0.22))
	bl.custom_minimum_size = Vector2(300, 0)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bub.add_child(bl)
	bwrap.add_child(bub)
	UI.fade_in(bub, 0.4, Vector2(0, -10))
	var fl := bub.create_tween().set_loops()
	fl.tween_property(bub, "position:y", 2.0, 1.6).as_relative().set_trans(Tween.TRANS_SINE)
	fl.tween_property(bub, "position:y", -2.0, 1.6).as_relative().set_trans(Tween.TRANS_SINE)
	var np := UI.vbox(0)
	np.anchor_left = 0.31
	np.anchor_right = 0.65
	np.anchor_top = 1.0
	np.anchor_bottom = 1.0
	np.offset_top = -62
	np.offset_bottom = -6
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(np)
	var tt := UI.label(DB.title_of(_hero).to_upper(), 11, tc.lightened(0.55), 4)
	tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	np.add_child(tt)
	var nm := UI.label(DB.name_of(_hero), 26, Color.WHITE, 7)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_color_override("font_outline_color", tc.darkened(0.55))
	np.add_child(nm)

	# ---- right: plan
	var rp := UI.panel()
	rp.anchor_left = 0.67
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var v := UI.vbox(8)
	rp.add_child(UI.scroll(v))
	var sp2 := DB.date_spot(_spot)
	v.add_child(UI.label("TODAY'S PLAN", 12, Color("#ff8fb8"), 3))
	v.add_child(UI.wrap_label(str(sp2["name"]), 19, Color.WHITE))
	if str(info[0]) != "":
		v.add_child(UI.wrap_label(str(info[0]), 12, UI.MUTED))
	# partner card
	var h := Game.hero(_hero)
	var pc := UI.styled_panel(Color(tc.darkened(0.8), 0.85), Color(tc, 0.7), 12, 1, 8)
	v.add_child(pc)
	var pv := UI.vbox(4)
	pc.add_child(pv)
	var hr := UI.hbox(8)
	pv.add_child(hr)
	var fp := UI.styled_panel(Color.BLACK, tc, 8, 2, 1)
	fp.add_child(UI.tex_rect(DB.face(_hero), Vector2(46, 46), true))
	fp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hr.add_child(fp)
	var hv := UI.vbox(1)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(hv)
	hv.add_child(UI.label(DB.name_of(_hero), 17, Color.WHITE, 3))
	var dc := Game.date_count(_hero)
	hv.add_child(UI.label("♥ Bond Lv.%d  •  %d date%s" % [int(h["bond"]), dc, "" if dc == 1 else "s"], 12, Color("#ff8fb8"), 2))
	var chg := UI.button("CHANGE", _pick_hero, "", Vector2(86, 36))
	chg.add_theme_font_size_override("font_size", 13)
	chg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hr.add_child(chg)
	if int(h["bond"]) < DB.MAX_BOND:
		pv.add_child(UI.bar(int(h["bond_exp"]), DB.bond_to_next(int(h["bond"])), "", 6))
	# personality hint (learned after the first date with her)
	var style: Array = DB.DATE_STYLE[DB.liking(_hero)]
	var tip := UI.hbox(6)
	pv.add_child(tip)
	if Game.date_count(_hero) > 0:
		tip.add_child(UI.label("💡 %s" % str(style[0]), 12, UI.GOLD, 2))
		var tl := UI.wrap_label("She loves %s." % str(style[1]), 12, UI.TEXT)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tip.add_child(tl)
	else:
		var tl2 := UI.wrap_label("💡 Go on a first date to learn what she likes.", 12, UI.MUTED)
		tl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tip.add_child(tl2)
	# rank rewards
	v.add_child(UI.label("RESULTS", 12, UI.MUTED, 2))
	var best := Game.date_best(_hero, _spot)
	for ri in 3:
		var rk: Array = DB.DATE_RANKS[ri]
		var col := _rank_col(ri)
		var row := UI.hbox(6)
		v.add_child(row)
		var rl := UI.label(("✦ " if best == ri else "") + str(rk[0]), 13, col, 2)
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(rl)
		var bonus: int = [40, 20, 0][ri]
		row.add_child(UI.label("+%d Bond" % bonus, 12, Color("#ff8fb8"), 1))
		row.add_child(UI.reward_row({"gems": 20 + bonus}, 18, 12))
	if not Game.date_perfect_paid(_hero, _spot):
		var fpp := UI.styled_panel(Color(1, 0.83, 0.47, 0.12), Color(1, 0.83, 0.47, 0.6), 8, 1, 6)
		v.add_child(fpp)
		var fh := UI.hbox(6)
		fpp.add_child(fh)
		fh.add_child(UI.label("FIRST PERFECT HERE", 11, Color("#ffd479"), 2))
		fh.add_child(UI.spacer())
		fh.add_child(UI.reward_row(DB.DATE_FIRST_PERFECT, 18, 12))
	v.add_child(UI.spacer(false))
	# daily hearts + start
	var left := Game.dates_left()
	var dh := UI.hbox(4)
	dh.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(dh)
	dh.add_child(UI.label("TODAY", 12, UI.MUTED, 2))
	for k in DB.DATE_PER_DAY:
		dh.add_child(UI.label("♥" if k < left else "♡", 20, Color("#ff6f9f") if k < left else UI.MUTED, 2))
	var go := UI.button("♥ START DATE" if left > 0 else "COME BACK TOMORROW", _start, "GoldButton", Vector2(0, 52))
	go.disabled = left <= 0
	v.add_child(go)
	if left > 0:
		var pulse := go.create_tween().set_loops()
		pulse.tween_property(go, "modulate", Color(1.15, 1.08, 1.1), 0.8).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(go, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)

func _pick_hero() -> void:
	var v: VBoxContainer = main.popup("CHOOSE YOUR PARTNER", 820)
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 420)
	v.add_child(sc)
	var ids: Array = Game.s["heroes"].keys()
	ids.sort_custom(func(a, c): return int(Game.hero(a)["bond"]) > int(Game.hero(c)["bond"]))
	for id in ids:
		var hid: String = id
		var card := HeroCard.new(hid, Vector2(108, 136), {"skin": true, "show_level": false, "badge": int(Game.hero(hid)["bond"])})
		if not Game.can_date(hid):
			card.modulate = Color(0.4, 0.4, 0.45)
		card.set_selected(hid == _hero)
		card.pressed.connect(func():
			if not Game.can_date(hid):
				main.toast("Bond Lv.%d needed for a date." % DB.DATE_BOND, UI.MUTED)
				return
			main.close_popup(v)
			main.replace("date", {"tab": "go", "hero": hid, "spot": _spot}))
		g.add_child(card)

func _start() -> void:
	if Game.dates_left() <= 0:
		return
	var hid := _hero
	var key := _spot
	var score := [0]
	var vn: VNDialogue = main.dialogue(Game.date_lines(hid, key), func():
		var res: Dictionary = Game.finish_date(hid, key, int(score[0]))
		_show_photo({"hero": hid, "spot": key, "rank": res["rank"][0]}, res), key)
	vn.chose.connect(func(_i, bond): score[0] = int(score[0]) + int(bond))

## Date Photo: location + hero, framed by rank.
func _photo(entry: Dictionary, w: float) -> Control:
	var col := Color("#9fd0ff")
	for r in DB.DATE_RANKS:
		if r[0] == entry["rank"]:
			col = Color(str(r[2]))
	var fr := Panel.new()
	fr.custom_minimum_size = Vector2(w, w * 0.62)
	fr.add_theme_stylebox_override("panel", UI.style(Color.WHITE, col, 6, 6, 0, 6))
	fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var bgt := UI.tex_rect(DB.bg(entry["spot"]), Vector2.ZERO, true)
	bgt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bgt.offset_left = 6
	bgt.offset_top = 6
	bgt.offset_right = -6
	bgt.offset_bottom = -6
	fr.add_child(bgt)
	var h := UI.tex_rect(DB.cutin(entry["hero"]))
	h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.anchor_left = 0.35
	h.offset_top = 6
	h.offset_right = -6
	h.offset_bottom = -6
	fr.add_child(h)
	var l := UI.label("%s  •  %s" % [DB.name_of(entry["hero"]).split(" ")[0], entry["rank"]], 12 if w < 300 else 16, col, 4)
	l.position = Vector2(12, 10)
	fr.add_child(l)
	return fr

func _show_photo(entry: Dictionary, res: Dictionary) -> void:
	var v: VBoxContainer = main.popup(str(res["rank"][0]), 640)
	Game.sfx("star_up")
	var ph := _photo(entry, 580)
	v.add_child(ph)
	UI.pop(ph, 0.4)
	if bool(res.get("first_perfect", false)) or bool(res.get("new_best", false)):
		var tag := UI.styled_panel(Color(1, 0.83, 0.47, 0.18), Color("#ffd479"), 10, 1, 6)
		var tl := UI.label("✦ FIRST PERFECT AT THIS SPOT! ✦" if bool(res.get("first_perfect", false)) else "✦ NEW BEST AT THIS SPOT ✦", 15, Color("#ffd479"), 3)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(tl)
		v.add_child(tag)
		UI.pop(tag, 0.5)
	v.add_child(UI.label("+%d bonus Bond  •  Date Photo saved to your album" % int(res["bonus"]), 14, Color("#ff8fb8"), 3))
	v.add_child(UI.reward_row(res["reward"], 32, 14))
	v.add_child(UI.button("WONDERFUL", func():
		main.close_popup(v)
		main.replace("date", {"tab": "go", "hero": _hero, "spot": _spot}), "GoldButton", Vector2(0, 48)))

var _album_hero := ""

func _build_album(b: Control) -> void:
	_album_hero = str(params.get("album_hero", ""))
	var album := Game.date_album()
	if album.is_empty():
		var l := UI.label("No photos yet — go on your first date!", 20, UI.MUTED, 3)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		b.add_child(l)
		return
	var root := UI.vbox(8)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(root)
	# filter chips: ALL + every hero with photos
	var heroes: Array = []
	var perfect := 0
	for e in album:
		if not heroes.has(e["hero"]):
			heroes.append(e["hero"])
		if str(e["rank"]) == "PERFECT DATE":
			perfect += 1
	var top := UI.hbox(6)
	root.add_child(top)
	var chips := UI.hbox(6)
	var csc := UI.scroll(chips, true)
	csc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	csc.custom_minimum_size = Vector2(0, 52)
	top.add_child(csc)
	var all_b := UI.button("ALL", func(): main.replace("date", {"tab": "album", "hero": _hero, "spot": _spot}), "TabButton", Vector2(70, 46))
	all_b.toggle_mode = true
	all_b.button_pressed = _album_hero == ""
	chips.add_child(all_b)
	for hid in heroes:
		var id: String = hid
		var cb := UI.button(DB.name_of(id).split(" ")[0], func(): main.replace("date", {"tab": "album", "hero": _hero, "spot": _spot, "album_hero": id}), "TabButton", Vector2(0, 46))
		cb.add_theme_font_size_override("font_size", 13)
		cb.toggle_mode = true
		cb.button_pressed = _album_hero == id
		chips.add_child(cb)
	var sum := UI.label("%d photos  •  ✦ %d Perfect" % [album.size(), perfect], 13, UI.GOLD, 2)
	sum.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(sum)
	# per-hero spot collection strip
	if _album_hero != "":
		var cs := UI.styled_panel(Color(0.06, 0.03, 0.1, 0.8), Color(DB.theme_color(_album_hero), 0.6), 10, 1, 6)
		root.add_child(cs)
		var ch := UI.hbox(8)
		cs.add_child(ch)
		ch.add_child(UI.label("%s's spots" % DB.name_of(_album_hero).split(" ")[0], 13, Color.WHITE, 2))
		for sp in DB.DATE_SPOTS:
			var ri := Game.date_best(_album_hero, str(sp["key"]))
			var col: Color = _rank_col(ri) if ri >= 0 else Color(1, 1, 1, 0.25)
			var sb := UI.styled_panel(Color(col, 0.12), col, 8, 1, 4)
			sb.add_child(UI.label("%s %s" % [str(sp["name"]).split(" ")[0] if str(sp["key"]) != "forest" else "Picnic", RANK_SHORT[ri] if ri >= 0 else "—"], 11, col if ri >= 0 else UI.MUTED, 1))
			ch.add_child(sb)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	var sc := UI.scroll(UI.margin(g, 6, 6, 6, 6))
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sc)
	for e in album:
		var entry: Dictionary = e
		if _album_hero != "" and str(entry["hero"]) != _album_hero:
			continue
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		var ph := _photo(entry, 360)
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.custom_minimum_size = ph.custom_minimum_size
		btn.add_child(ph)
		btn.pressed.connect(func():
			var v: VBoxContainer = main.popup(str(DB.date_spot(entry["spot"])["name"]), 900)
			v.add_child(_photo(entry, 840))
			var age := Game.day_key() - int(entry.get("day", Game.day_key()))
			v.add_child(UI.label("%s  •  %s" % [DB.name_of(entry["hero"]), "today" if age <= 0 else ("%d day%s ago" % [age, "" if age == 1 else "s"])], 14, UI.MUTED, 2)))
		g.add_child(btn)
	UI.stagger(g, 0.03)

## Empty state: nobody is at Bond 3 yet — show who's closest and how to get there.
func _build_no_partner(b: Control) -> void:
	var p := UI.styled_panel(Color(0.1, 0.05, 0.12, 0.9), Color("#ff8fb8", 0.6), 16, 1, 18.0)
	p.anchor_left = 0.33
	p.anchor_right = 0.97
	p.anchor_top = 0.04
	b.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var top := UI.hbox(12)
	v.add_child(top)
	var heart := UI.label("♥", 44, Color("#ff6fae"), 4)
	heart.pivot_offset = Vector2(16, 28)
	top.add_child(heart)
	var tw := heart.create_tween().set_loops()
	tw.tween_property(heart, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(heart, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	tv.add_child(UI.label("NO DATE PARTNER YET", 22, Color.WHITE, 4))
	tv.add_child(UI.wrap_label("Reach Bond Lv.%d with any hero to ask her out. Here's who is closest:" % DB.DATE_BOND, 14, Color("#ffc2dc")))
	# closest heroes by bond progress
	var need_total := 0
	for lv in range(1, DB.DATE_BOND):
		need_total += DB.bond_to_next(lv)
	var ids: Array = Game.s["heroes"].keys()
	var prog := {}
	for id in ids:
		var h := Game.hero(id)
		var have := int(h["bond_exp"])
		for lv in range(1, int(h["bond"])):
			have += DB.bond_to_next(lv)
		prog[id] = have
	ids.sort_custom(func(a, c): return int(prog[a]) > int(prog[c]))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	for k in mini(4, ids.size()):
		var hid: String = ids[k]
		var h := Game.hero(hid)
		var row := UI.styled_panel(Color(0, 0, 0, 0.35), Color(DB.theme_color(hid), 0.5), 12, 1, 8.0)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(row)
		var rh := UI.hbox(10)
		row.add_child(rh)
		rh.add_child(UI.tex_rect(DB.face(hid), Vector2(52, 52), true))
		var rv := UI.vbox(3)
		rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(rv)
		var nr := UI.hbox(6)
		rv.add_child(nr)
		var nl := UI.label(DB.name_of(hid), 15, Color.WHITE, 2)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.clip_text = true
		nr.add_child(nl)
		nr.add_child(UI.label("Bond Lv.%d" % int(h["bond"]), 12, Color("#ff8fb8"), 2))
		var bar := UI.bar(mini(int(prog[hid]), need_total), need_total, "", 8)
		bar.add_theme_stylebox_override("fill", UI.style(Color("#ff6fae"), Color.TRANSPARENT, 4, 0, 0))
		rv.add_child(bar)
		rv.add_child(UI.label("%d%% to a date" % int(100.0 * mini(int(prog[hid]), need_total) / maxf(1.0, need_total)), 11, UI.MUTED, 0))
		var gb := UI.button("GIFT", func(): main.go("hero_detail", {"id": hid, "tab": "BOND"}), "", Vector2(72, 40))
		gb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rh.add_child(gb)
	v.add_child(UI.label("WAYS TO RAISE BOND", 14, UI.GOLD, 3))
	var ways := UI.hbox(8)
	v.add_child(ways)
	for w in [["icon_heart", "Gifts", "Favourite gift = more Bond", "room"], ["icon_messenger", "Daily Talks", "Reply to her messages", "messenger"], ["icon_room", "Private Room", "Spend time together", "room"], ["icon_kitchen", "Kitchen", "Cook gift dishes", "kitchen"]]:
		var key: String = w[3]
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 104)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fr := PanelContainer.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.add_theme_stylebox_override("panel", UI.style(Color(1, 0.45, 0.7, 0.08), Color("#ff8fb8", 0.4), 12, 1, 6))
		btn.add_child(fr)
		var wv := UI.vbox(2)
		wv.alignment = BoxContainer.ALIGNMENT_CENTER
		wv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.add_child(wv)
		var ic := UI.tex_rect(DB.icon(w[0]), Vector2(34, 34))
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		wv.add_child(ic)
		for t in [[w[1], 14, Color.WHITE, 2], [w[2], 10, UI.MUTED, 0]]:
			var l := UI.label(t[0], t[1], t[2], t[3])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			wv.add_child(l)
		btn.pressed.connect(func(): main.go(key))
		UI.hover_fx(btn, 1.03)
		ways.add_child(btn)
	var tip := UI.styled_panel(Color(0, 0, 0, 0.3), Color(1, 1, 1, 0.08), 10, 1, 8.0)
	tip.add_child(UI.wrap_label("On a date: pick the answer she'd like best. A Perfect Date gives the most Bond and a golden photo for your Date Album.", 12, UI.MUTED))
	v.add_child(tip)
	UI.stagger(g, 0.05)
