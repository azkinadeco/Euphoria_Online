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

func _build_go(b: Control) -> void:
	# ---- left: spots
	var lp := UI.panel()
	lp.anchor_right = 0.3
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(6)
	lp.add_child(UI.scroll(lv))
	lv.add_child(UI.label("DATE SPOTS", 15, UI.GOLD, 3))
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
		var nl := UI.label(str(sp["name"]) if open else "Clear %d stages" % int(sp["req"]), 13, Color.WHITE if open else UI.MUTED, 4)
		nl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		nl.offset_top = -24
		nl.offset_left = 8
		fr.add_child(nl)
		btn.pressed.connect(func():
			if not open:
				main.toast("Locked — clear %d story stages." % int(sp["req"]), UI.MUTED)
				return
			main.replace("date", {"tab": "go", "hero": _hero, "spot": key}))
		lv.add_child(btn)
	# ---- centre: the hero
	if _hero == "":
		var l := UI.wrap_label("Reach Bond Lv.%d with any hero to go on a date. Gifts, Daily Talks and the Private Room raise Bond." % DB.DATE_BOND, 18, Color.WHITE)
		l.anchor_left = 0.34
		l.anchor_right = 0.96
		l.anchor_top = 0.35
		b.add_child(l)
		return
	var art := UI.tex_rect(DB.art(_hero, int(Game.hero(_hero).get("skin", 0))))
	art.anchor_left = 0.3
	art.anchor_right = 0.66
	art.anchor_bottom = 1.0
	art.offset_top = 10
	UI.live(art, DB.theme_color(_hero).lightened(0.5))
	b.add_child(art)
	UI.fade_in(art, 0.4, Vector2(0, 20))
	# ---- right: plan
	var rp := UI.panel()
	rp.anchor_left = 0.67
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var v := UI.vbox(10)
	rp.add_child(v)
	var sp2 := DB.date_spot(_spot)
	v.add_child(UI.label("TODAY'S PLAN", 13, Color("#ff8fb8"), 3))
	v.add_child(UI.wrap_label(str(sp2["name"]), 20, Color.WHITE))
	var hr := UI.hbox(8)
	hr.add_child(UI.tex_rect(DB.face(_hero), Vector2(48, 48), true))
	var hv := UI.vbox(0)
	hv.add_child(UI.label(DB.name_of(_hero), 18, Color.WHITE, 3))
	hv.add_child(UI.label("Bond Lv.%d" % int(Game.hero(_hero)["bond"]), 13, Color("#ff8fb8"), 2))
	hr.add_child(hv)
	v.add_child(hr)
	v.add_child(UI.button("CHANGE PARTNER", _pick_hero, "", Vector2(0, 42)))
	v.add_child(UI.wrap_label("Answer the way she'd like best. A Perfect Date gives the most Bond and a golden photo frame.", 12, UI.MUTED))
	v.add_child(UI.spacer(false))
	var left := Game.dates_left()
	var go := UI.button("♥ START DATE  (%d / %d today)" % [left, DB.DATE_PER_DAY], _start, "GoldButton", Vector2(0, 56))
	go.disabled = left <= 0
	v.add_child(go)

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
	v.add_child(UI.label("+%d bonus Bond  •  Date Photo saved to your album" % int(res["bonus"]), 14, Color("#ff8fb8"), 3))
	v.add_child(UI.reward_row(res["reward"], 32, 14))
	v.add_child(UI.button("WONDERFUL", func():
		main.close_popup(v)
		main.replace("date", {"tab": "go", "hero": _hero, "spot": _spot}), "GoldButton", Vector2(0, 48)))

func _build_album(b: Control) -> void:
	var album := Game.date_album()
	if album.is_empty():
		var l := UI.label("No photos yet — go on your first date!", 20, UI.MUTED, 3)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		b.add_child(l)
		return
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	var sc := UI.scroll(UI.margin(g, 6, 6, 6, 6))
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(sc)
	for e in album:
		var entry: Dictionary = e
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		var ph := _photo(entry, 360)
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.custom_minimum_size = ph.custom_minimum_size
		btn.add_child(ph)
		btn.pressed.connect(func():
			var v: VBoxContainer = main.popup(str(DB.date_spot(entry["spot"])["name"]), 900)
			v.add_child(_photo(entry, 840)))
		g.add_child(btn)
	UI.stagger(g, 0.03)
