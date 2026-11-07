extends Screen
## Boss Hunt: four colossal targets on the star maps, 4 difficulties each, 3 hunts per day.
## params: {"hunt": id} to pre-select, {"shop": true} for the Hunter's Exchange (Night Market).

var _sel := "behemoth"
var _diff := 0
var _list: VBoxContainer
var _detail: Control
var _bg_rect: TextureRect
var _foot: VBoxContainer

func build() -> void:
	if bool(params.get("shop", false)):
		_build_shop()
		return
	_sel = str(params.get("hunt", "behemoth"))
	_diff = clampi(int(params.get("diff", Game.hunt_cleared(_sel) + 1)), 0, DB.HUNT_DIFFS.size() - 1)
	set_bg(DB.hunt_def(_sel)["bg"], 0.45)
	_bg_rect = get_child(0) as TextureRect
	ambient(Color(1.0, 0.9, 0.6), 24)
	header("BOSS HUNT", ["gold", "gems"])
	var b := body(76)
	var lcol := UI.vbox(8)
	lcol.anchor_right = 0.27
	lcol.anchor_bottom = 1.0
	b.add_child(lcol)
	_list = UI.vbox(6)
	var lsc := UI.scroll(_list)
	lsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lcol.add_child(lsc)
	_foot = UI.vbox(4)
	lcol.add_child(_foot)
	_detail = Control.new()
	_detail.anchor_left = 0.29
	_detail.anchor_right = 1.0
	_detail.anchor_bottom = 1.0
	b.add_child(_detail)
	_render()
	tutorial("hunt")

func _render() -> void:
	params["hunt"] = _sel
	params["diff"] = _diff
	_bg_rect.texture = DB.bg(DB.hunt_def(_sel)["bg"])
	for c in _list.get_children():
		c.queue_free()
	for c in _foot.get_children():
		c.queue_free()
	for c in _detail.get_children():
		c.queue_free()
	# ---------------------------------------------------------------- target list
	for h in DB.HUNTS:
		var hid: String = h["id"]
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 76)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color.BLACK, UI.GOLD if hid == _sel else Color("#4a3a6e"), 12, 3 if hid == _sel else 1, 0))
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(fr)
		var th := UI.tex_rect(DB.bg(h["bg"]), Vector2.ZERO, true)
		th.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		th.modulate = Color(0.7, 0.7, 0.75) if hid == _sel else Color(0.4, 0.4, 0.45)
		fr.add_child(th)
		var face := UI.tex_rect(DB.face(h["boss"]), Vector2(60, 60), true)
		face.position = Vector2(8, 8)
		face.size = Vector2(60, 60)
		UI.corrupt(face, "astral")
		fr.add_child(face)
		var nm := UI.label(h["name"], 15, Color.WHITE, 4)
		nm.position = Vector2(76, 8)
		nm.size = Vector2(240, 22)
		fr.add_child(nm)
		var cl := Game.hunt_cleared(hid)
		var sub := UI.label("Best: %s" % (DB.HUNT_DIFFS[cl] if cl >= 0 else "—"), 12, UI.GOLD, 3)
		sub.position = Vector2(76, 30)
		fr.add_child(sub)
		var focus := UI.label(_focus_text(str(h["focus"])), 12, Color("#9fd0ff"), 3)
		focus.position = Vector2(76, 50)
		fr.add_child(focus)
		btn.pressed.connect(func():
			Game.sfx("ui_click")
			_sel = hid
			_diff = clampi(Game.hunt_cleared(hid) + 1, 0, DB.HUNT_DIFFS.size() - 1)
			_render())
		UI.hover_fx(btn, 1.02)
		_list.add_child(btn)
	var xb := UI.button("HUNTER'S EXCHANGE ▶", func(): main.go("hunt", {"shop": true}), "GoldButton", Vector2(0, 50))
	_foot.add_child(xb)
	_foot.add_child(UI.label("Hunt Cores: %s" % Game.fmt(Game.amount("hunt_core")), 14, UI.GOLD, 3))
	# ---------------------------------------------------------------- detail
	var h := DB.hunt_def(_sel)
	var st := DB.hunt_stage(_sel, _diff)
	var art := UI.tex_rect(DB.art(h["boss"], mini(_diff, 3)))
	art.anchor_right = 0.55
	art.anchor_bottom = 1.0
	art.offset_bottom = -10
	UI.corrupt(art, "astral")
	_detail.add_child(art)
	var bob := art.create_tween().set_loops()
	bob.tween_property(art, "position:y", -10.0, 2.0).set_trans(Tween.TRANS_SINE)
	bob.tween_property(art, "position:y", 0.0, 2.0).set_trans(Tween.TRANS_SINE)
	UI.fade_in(art, 0.4, Vector2(-30, 0))
	var rp := UI.panel()
	rp.anchor_left = 0.5
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	_detail.add_child(rp)
	var v := UI.vbox(8)
	rp.add_child(UI.scroll(v))
	v.add_child(UI.label("ASTRAL TARGET", 13, Color("#ffe27a"), 3))
	v.add_child(UI.label(h["name"], 24, Color.WHITE, 5))
	v.add_child(UI.wrap_label(h["desc"], 13, UI.MUTED))
	var wk := UI.hbox(6)
	var weak := DB.hunt_weak(_sel)
	wk.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(weak, "elem_light")), Vector2(24, 24)))
	wk.add_child(UI.label("Weakness: %s heroes +30%% ATK" % weak, 14, DB.ELEMENT_COLOR.get(weak, UI.GOLD), 3))
	v.add_child(wk)
	var dt := UI.hbox(6)
	v.add_child(dt)
	for i in DB.HUNT_DIFFS.size():
		var di: int = i
		var open := Game.hunt_unlocked(_sel, di)
		var db := UI.button(DB.HUNT_DIFFS[di] if open else "LOCKED", func():
			_diff = di
			_render(), "TabButton", Vector2(0, 38))
		db.toggle_mode = true
		db.button_pressed = di == _diff
		db.disabled = not open
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		db.add_theme_font_size_override("font_size", 12)
		dt.add_child(db)
	var ep := Game.enemy_power(st["enemies"])
	var tp := Game.team_power()
	v.add_child(UI.label("Lv.%d  •  Enemy Power %s  •  Your Team %s" % [st["level"], Game.fmt(ep), Game.fmt(tp)], 14, UI.GREEN if tp >= ep else Color("#ff8a9a"), 3))
	v.add_child(UI.label("REWARDS", 14, UI.GOLD, 3))
	v.add_child(UI.reward_row(st["rewards"], 34, 13))
	v.add_child(UI.label("+ " + _focus_text(str(h["focus"])), 13, Color("#9fd0ff")))
	if _diff > Game.hunt_cleared(_sel):
		v.add_child(UI.label("First clear: +%d Gems" % int(st["first_gems"]), 13, UI.GREEN))
	var go := UI.button("⚔ HUNT  (%d / %d today)" % [Game.hunt_tries(), DB.HUNT_TRIES], func():
		main.go("formation", {"mode": "hunt", "hunt": _sel, "diff": _diff}), "GoldButton", Vector2(0, 56))
	go.disabled = Game.hunt_tries() <= 0
	if _diff <= Game.hunt_cleared(_sel):
		var row := UI.hbox(8)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(go)
		var sw := UI.button("SWEEP", func():
			var r := Game.sweep_hunt(_sel, _diff)
			if r.has("error"):
				main.toast(r["error"], UI.RED)
				return
			Game.sfx("ui_click")
			main.show_rewards("HUNT SWEPT", r, func(): _render()), "", Vector2(120, 56))
		sw.disabled = go.disabled
		row.add_child(sw)
		v.add_child(row)
	else:
		v.add_child(go)
	v.add_child(UI.wrap_label("Failed hunts don't use up an attempt. Clear a difficulty to unlock the next one.", 12, UI.MUTED))

func _focus_text(f: String) -> String:
	match f:
		"gear": return "Equipment (SSR chance)"
		"rune": return "Runes (Tier 2-3)"
		"shard": return "Hero Shards"
		"gold": return "Gold, Hero EXP, Potions"
		"stone": return "Star Stones (universal shards)"
		"core": return "Extra Hunt Cores"
	return ""

# ---------------------------------------------------------------- Hunter's Exchange (Night Market)
func _build_shop() -> void:
	set_bg("blackmarket", 0.35)
	ambient(Color(0.8, 0.5, 1.0), 20)
	header("BOSS HUNT", ["gold", "gems"])
	var b := body(76)
	var keeper := NPCPuppet.new(DB.tex("res://art/npc/store_lulu.png"), "shop2")
	keeper.anchor_right = 0.3
	keeper.anchor_bottom = 1.0
	keeper.offset_top = 30
	b.add_child(keeper)
	UI.fade_in(keeper, 0.5, Vector2(-30, 0))
	var bub := UI.styled_panel(Color(1, 1, 1, 0.95), Color("#c9a0ff"), 14, 1, 10)
	bub.anchor_right = 0.3
	bub.offset_left = 8
	bub.offset_right = -8
	var bl := UI.wrap_label("Lulu: Trophies from the stars, hm? Bring me Hunt Cores and I'll find you something... special~", 13, Color("#2a1a3a"))
	bub.add_child(bl)
	b.add_child(bub)
	keeper.spoke.connect(func(text): bl.text = "Lulu: " + text)
	keeper.greet.call_deferred()
	var rp := UI.panel()
	rp.anchor_left = 0.32
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var v := UI.vbox(8)
	rp.add_child(v)
	var hh := UI.hbox(8)
	hh.add_child(UI.tex_rect(DB.icon("icon_shards"), Vector2(30, 30)))
	hh.add_child(UI.label("HUNTER'S EXCHANGE  •  Hunt Cores: %s" % Game.fmt(Game.amount("hunt_core")), 18, UI.GOLD, 3))
	v.add_child(hh)
	v.add_child(UI.label("Stock resets every week.", 12, UI.MUTED))
	var list := UI.vbox(8)
	v.add_child(UI.scroll(list))
	for it in DB.HUNT_SHOP:
		var item: Dictionary = it
		var left_n: int = int(item["limit"]) - Game.hunt_bought(item["id"])
		var p := UI.panel("CardPanel")
		list.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		h.add_child(UI.reward_row(item["give"], 40, 13))
		var info := UI.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UI.label(item["name"], 15, Color.WHITE, 2))
		info.add_child(UI.label("%d left this week" % left_n, 12, UI.MUTED))
		h.add_child(info)
		var bb := UI.button("%d ◆" % int(item["price"]), func():
			var err := Game.buy_hunt(item)
			if err != "":
				main.toast(err, UI.RED)
				return
			Game.sfx("ui_click")
			main.show_rewards("EXCHANGED", item["give"])
			main.replace("hunt", {"shop": true}), "GoldButton", Vector2(110, 44))
		bb.disabled = left_n <= 0
		h.add_child(bb)
	UI.stagger(list, 0.03)
