extends Screen
## Summon: banners, pity, x1/x10, animated gate + card flip reveal.

var _banner_i := 0
var _art: TextureRect
var _info: VBoxContainer
var _list: VBoxContainer
var _btns: HBoxContainer
var _frames: Array = []     # special-event banner art (tap to animate, like a GIF)
var _frame_i := 0
var _bg_rect: TextureRect
var _reveal: Control

func build() -> void:
	_banner_i = int(params.get("banner", 0))
	set_bg(DB.BANNERS[_banner_i]["bg"], 0.35)
	_bg_rect = get_child(0) as TextureRect
	ambient(Color(1.0, 0.9, 0.6), 45)
	header("SUMMON", ["gems", "summon_ticket"])

	_list = UI.vbox(10)
	var lsc := UI.scroll(_list)
	lsc.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	lsc.offset_left = 16
	lsc.offset_right = 250
	lsc.offset_top = 84
	lsc.offset_bottom = -16
	add_child(lsc)

	_art = UI.tex_rect(null)
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.anchor_left = 0.2
	_art.anchor_right = 0.62
	_art.offset_top = 64
	add_child(_art)
	_art.resized.connect(func(): _art.pivot_offset = Vector2(_art.size.x * 0.5, _art.size.y))
	_art.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and _frames.size() > 1:
			UI.play_frames(_art, _frames))
	var tw := _art.create_tween().set_loops()
	tw.tween_property(_art, "scale", Vector2(1.006, 1.015), 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_art, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_SINE)

	var rp := UI.styled_panel(Color(0.05, 0.02, 0.1, 0.85), UI.GOLD_DARK, 16, 2, 18)
	rp.set_anchors_preset(Control.PRESET_FULL_RECT)
	rp.anchor_left = 0.62
	rp.offset_right = -16
	rp.offset_top = 84
	rp.offset_bottom = -130
	add_child(rp)
	_info = UI.vbox(8)
	rp.add_child(UI.scroll(_info))

	_btns = UI.hbox(12)
	_btns.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_btns.anchor_left = 0.3
	_btns.offset_right = -16
	_btns.offset_top = -112
	_btns.offset_bottom = -16
	_btns.alignment = BoxContainer.ALIGNMENT_END
	add_child(_btns)
	_render()
	tutorial("gacha")

func refresh() -> void:
	super.refresh()
	if not is_instance_valid(_reveal):
		_render_buttons()

func _render() -> void:
	var b: Dictionary = DB.BANNERS[_banner_i]
	_bg_rect.texture = DB.bg(b["bg"])
	for c in _list.get_children():
		c.queue_free()
	for i in DB.BANNERS.size():
		var bi: int = i
		var bd: Dictionary = DB.BANNERS[i]
		var btn := Button.new()
		btn.theme_type_variation = "TabButton"
		btn.toggle_mode = true
		btn.button_pressed = i == _banner_i
		btn.custom_minimum_size = Vector2(230, 86)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): Game.sfx("ui_click"); _banner_i = bi; _render())
		var h := UI.hbox(8)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 8
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(h)
		var fid: String = bd["featured"] if bd["featured"] != "" else "micca"
		var face := UI.face_rect(fid, Vector2(66, 66))
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(face)
		var v := UI.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(UI.label("RATE UP" if bd["featured"] != "" else "STANDARD", 12, Color("#ff9ad5") if bd["featured"] != "" else Color("#9fb4ff"), 3))
		var nl := UI.label(DB.name_of(fid) if bd["featured"] != "" else "All Heroes", 18, Color.WHITE, 3)
		v.add_child(nl)
		h.add_child(v)
		_list.add_child(btn)

	var fid2: String = b["featured"]
	_frames = b.get("img", [])
	_frame_i = 0
	_art.texture = DB.tex(_frames[0]) if not _frames.is_empty() else DB.art(fid2 if fid2 != "" else "micca", 0)
	for c in _info.get_children():
		c.queue_free()
	_info.add_child(UI.label(b["name"].to_upper(), 24, UI.GOLD, 5))
	if not bool(Game.s["gacha"].get("first10_done", false)):
		var fl := UI.label("★ FIRST 10x SUMMON: GUARANTEED SSR! ★", 15, UI.GOLD, 4)
		_info.add_child(fl)
		var ft := fl.create_tween().set_loops()
		ft.tween_property(fl, "modulate", Color(1.4, 1.3, 1.0), 0.6)
		ft.tween_property(fl, "modulate", Color.WHITE, 0.6)
	if fid2 != "":
		var r := UI.hbox(8)
		r.add_child(UI.rarity_tag("SSR", 15))
		r.add_child(UI.label(DB.name_of(fid2), 22, Color.WHITE, 4))
		_info.add_child(r)
		_info.add_child(UI.label(DB.title_of(fid2), 14, DB.theme_color(fid2).lightened(0.35), 3))
		_info.add_child(UI.wrap_label(DB.skill_of(fid2)["name"] + ": " + str(DB.skill_of(fid2).get("desc", "")), 13, UI.TEXT))
	_info.add_child(UI.wrap_label(b["desc"], 14, UI.MUTED))
	var rates := UI.hbox(6)
	_info.add_child(rates)
	for rt in [["SSR", "3%", Color("#ffc94a")], ["SR", "15%", Color("#c77dff")], ["R", "82%", Color("#5fa8ff")]]:
		var rp := UI.styled_panel(Color(rt[2], 0.15), Color(rt[2], 0.6), 8, 1, 4.0)
		rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rl := UI.label("%s  %s" % [rt[0], rt[1]], 13, rt[2], 2)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rp.add_child(rl)
		rates.add_child(rp)
	var meters := UI.styled_panel(Color(0, 0, 0, 0.35), Color(1, 1, 1, 0.1), 10, 1, 8.0)
	_info.add_child(meters)
	var mv := UI.vbox(6)
	meters.add_child(mv)
	var pity := int(Game.s["gacha"]["pity"])
	mv.add_child(_meter("PITY", "SSR guaranteed at %d" % DB.GACHA_PITY, pity, DB.GACHA_PITY, Color("#ffc94a")))
	if fid2 != "":
		var spk := Game.spark_points(b["id"])
		var sr := UI.hbox(8)
		var m := _meter("SPARK", "pick %s at %d" % [DB.name_of(fid2).split(" ")[0], DB.SPARK_COST], mini(spk, DB.SPARK_COST), DB.SPARK_COST, Color("#ff9ad5"))
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sr.add_child(m)
		var bid: String = b["id"]
		var xb := UI.button("EXCHANGE", func():
			var r := Game.spark_exchange(bid)
			if r.has("error"):
				main.toast(r["error"], UI.MUTED)
				return
			r["rarity"] = "SSR"
			_play_reveal([r]), "GoldButton" if spk >= DB.SPARK_COST else "", Vector2(104, 34))
		xb.add_theme_font_size_override("font_size", 12)
		xb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		xb.disabled = spk < DB.SPARK_COST
		sr.add_child(xb)
		if not xb.disabled:
			var tw := xb.create_tween().set_loops()
			tw.tween_property(xb, "modulate", Color(1.3, 1.2, 1.3), 0.5)
			tw.tween_property(xb, "modulate", Color.WHITE, 0.5)
		mv.add_child(sr)
	_info.add_child(UI.wrap_label("10x summon guarantees at least one SR. Duplicates turn into hero shards. Each pull on a rate-up banner gives 1 Summon Point — %d points = the featured hero." % DB.SPARK_COST, 12, UI.MUTED))
	var ir := UI.hbox(8)
	var rb := UI.button("RATES & HERO LIST", _show_rates, "", Vector2(0, 40))
	rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ir.add_child(rb)
	var hb := UI.button("HISTORY", _show_history, "", Vector2(0, 40))
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ir.add_child(hb)
	_info.add_child(ir)
	_render_buttons()

func _render_buttons() -> void:
	for c in _btns.get_children():
		c.queue_free()
	if Game.can_free_pull():
		_btns.add_child(_pull_btn("FREE DAILY\nSUMMON x1", 1, "free"))
	_btns.add_child(_pull_btn("SUMMON x1\n%s" % _price(1), 1, Game.pull_pay(1)))
	_btns.add_child(_pull_btn("SUMMON x10\n%s" % _price(10), 10, Game.pull_pay(10)))

func _price(count: int) -> String:
	var tk := mini(Game.amount("summon_ticket"), count)
	var gems := "%s Gems" % Game.fmt(DB.GACHA_COST * (count - tk))
	if tk == 0:
		return gems
	var tickets := "%d Ticket%s" % [tk, "" if tk == 1 else "s"]
	return tickets if tk == count else "%s + %s" % [tickets, gems]

func _pull_btn(text: String, count: int, pay: String) -> Button:
	var b := UI.button(text, func(): _pull(count, pay), "GoldButton" if count == 10 or pay == "free" else "", Vector2(230, 92))
	b.add_theme_font_size_override("font_size", 19)
	if pay != "free":
		b.icon = DB.icon("icon_ticket") if Game.amount("summon_ticket") >= count else DB.icon("icon_gem")
		b.add_theme_constant_override("icon_max_width", 34)
		if Game.amount("summon_ticket") < count and Game.amount("gems") < DB.GACHA_COST * (count - mini(Game.amount("summon_ticket"), count)):
			# can't afford: dim the button and use a red that reads on both gold and purple buttons
			var short_col := Color("#8c1d1d") if count == 10 else Color("#ff8a8a")
			for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(k, short_col)
			b.modulate = Color(0.82, 0.8, 0.85)
			b.tooltip_text = "Not enough Gems or Summon Tickets"
	else:
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "modulate", Color(1.2, 1.18, 1.1), 0.6)
		tw.tween_property(b, "modulate", Color.WHITE, 0.6)
	return b

## Label + count on one line, a coloured bar under it.
func _meter(title: String, sub: String, val: int, mx: int, col: Color) -> Control:
	var v := UI.vbox(3)
	var h := UI.hbox(6)
	v.add_child(h)
	h.add_child(UI.label(title, 13, col, 2))
	var sl := UI.label(sub, 11, UI.MUTED, 0)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sl)
	h.add_child(UI.label("%d / %d" % [val, mx], 13, Color.WHITE, 2))
	var bar := UI.bar(val, mx, "", 8)
	bar.add_theme_stylebox_override("fill", UI.style(col, Color.TRANSPARENT, 4, 0, 0))
	v.add_child(bar)
	return v

func _show_history() -> void:
	var v: VBoxContainer = main.popup("SUMMON HISTORY", 640)
	var hist: Array = Game.s["gacha"].get("history", [])
	var cnt := {"SSR": 0, "SR": 0, "R": 0}
	for h in hist:
		cnt[h["r"]] = int(cnt.get(h["r"], 0)) + 1
	v.add_child(UI.label("Last %d pulls  •  SSR %d  •  SR %d  •  R %d   (total pulls %d)" % [hist.size(), cnt["SSR"], cnt["SR"], cnt["R"], int(Game.s["gacha"]["total"])], 14, UI.MUTED))
	var list := UI.vbox(4)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 400)
	v.add_child(sc)
	if hist.is_empty():
		list.add_child(UI.label("No summons yet.", 15, UI.MUTED))
	for h in hist:
		var row := UI.hbox(10)
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[h["r"]], 6, 2, 1)
		fp.add_child(UI.face_rect(h["id"], Vector2(32, 32)))
		row.add_child(fp)
		var nl := UI.label("%s  %s" % [h["r"], DB.name_of(h["id"])], 15, DB.RARITY_COLOR[h["r"]].lightened(0.2), 2)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		row.add_child(UI.label(Time.get_datetime_string_from_unix_time(int(h["t"]) + 7 * 3600).replace("T", " ").substr(0, 16), 12, UI.MUTED))
		list.add_child(row)
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

func _show_rates() -> void:
	var v: VBoxContainer = main.popup("RATES", 720)
	v.add_child(UI.label("SSR 3%%  •  SR 15%%  •  R 82%%  •  Pity %d" % DB.GACHA_PITY, 16, UI.GOLD))
	for r in ["SSR", "SR", "R"]:
		var f := HFlowContainer.new()
		f.add_theme_constant_override("h_separation", 8)
		f.add_theme_constant_override("v_separation", 8)
		v.add_child(UI.label(r, 18, DB.RARITY_COLOR[r], 3))
		for id in DB.hero_ids():
			if DB.rarity_of(id) == r:
				f.add_child(HeroCard.new(id, Vector2(84, 108), {"show_level": false, "lazy": true}))
		v.add_child(f)
	var ok := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)

func _pull(count: int, pay: String) -> void:
	if is_instance_valid(_reveal):
		return
	var b: Dictionary = DB.BANNERS[_banner_i]
	var res := Game.pull(b["id"], count, pay)
	if res.has("error"):
		main.toast(res["error"], UI.RED)
		if pay != "ticket":
			main.toast("Get Gems from Missions, Mail, Story first clears and the Tower.", UI.MUTED)
		return
	_play_reveal(res["results"])

func on_back() -> bool:
	if is_instance_valid(_reveal):
		_reveal.queue_free()
		_render()
		return true
	return false

# ---------------------------------------------------------------- reveal

func _play_reveal(results: Array) -> void:
	_reveal = Control.new()
	_reveal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_reveal)
	var best := "R"
	for r in results:
		if r["rarity"] == "SSR":
			best = "SSR"
		elif r["rarity"] == "SR" and best == "R":
			best = "SR"
	var col: Color = DB.RARITY_COLOR[best]
	var dark := ColorRect.new()
	dark.color = Color(0.01, 0.0, 0.03, 0.97)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal.add_child(dark)
	var sky := UI.tex_rect(DB.bg("galaxy"), Vector2.ZERO, true)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.modulate = Color(0.45, 0.4, 0.6, 0.0)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal.add_child(sky)
	sky.create_tween().tween_property(sky, "modulate:a", 1.0, 0.6)
	var motes := FestivalFX.new("firefly", col.lightened(0.3), 40)
	_reveal.add_child(motes)

	# --- gate
	Game.sfx("gacha_gate")
	var circle := UI.tex_rect(DB.tex("res://art/vfx/vfx_magic_circle.png"), Vector2(520, 520))
	circle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	circle.offset_left = -260
	circle.offset_top = -260
	circle.offset_right = 260
	circle.offset_bottom = 260
	circle.pivot_offset = Vector2(260, 260)
	circle.modulate = Color(col.r, col.g, col.b, 0.0)
	circle.scale = Vector2(0.3, 0.3)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	circle.material = add
	_reveal.add_child(circle)
	var inner := UI.tex_rect(DB.tex("res://art/vfx/vfx_magic_circle.png"), Vector2(300, 300))
	inner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	inner.offset_left = -150
	inner.offset_top = -150
	inner.offset_right = 150
	inner.offset_bottom = 150
	inner.pivot_offset = Vector2(150, 150)
	inner.modulate = Color(1, 0.95, 0.85, 0.0)
	inner.material = add
	_reveal.add_child(inner)
	var itw := inner.create_tween().set_parallel(true)
	itw.tween_property(inner, "modulate:a", 0.8, 0.5).set_delay(0.3)
	itw.tween_property(inner, "rotation", -TAU, 1.6)
	var skip := [false]
	dark.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			skip[0] = true)
	var tw := circle.create_tween().set_parallel(true)
	tw.tween_property(circle, "modulate:a", 1.0, 0.4)
	tw.tween_property(circle, "scale", Vector2(1.2, 1.2), 1.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(circle, "rotation", TAU * 0.75, 1.5)
	for k in 14:
		if skip[0] or not is_inside_tree():
			break
		await get_tree().create_timer(0.1).timeout
	if not is_inside_tree() or not is_instance_valid(_reveal):
		return
	# rarity tell: light pillars rise (1 blue / 2 purple / 3 gold)
	if not skip[0]:
		var fxp := SkillFX.new()
		_reveal.add_child(fxp)
		var n_p: int = {"R": 1, "SR": 2, "SSR": 3}[best]
		var c0 := _reveal.size * Vector2(0.5, 0.62)
		for k in n_p:
			var off := (k - (n_p - 1) * 0.5) * 140.0
			fxp.pillar(c0 + Vector2(off, 0), col.lightened(0.2), 120.0, k * 0.18)
		fxp.wave(c0, col, 700.0)
		if best == "SSR":
			Game.sfx("battle/light")
			if not Game.reduce_fx():
				_reveal.create_tween().tween_property(_reveal, "position", Vector2(6, 0), 0.04).set_trans(Tween.TRANS_SINE)
		for k in 9:
			if skip[0] or not is_inside_tree():
				break
			await get_tree().create_timer(0.1).timeout
		if not is_inside_tree() or not is_instance_valid(_reveal):
			return
		_reveal.position = Vector2.ZERO
		get_tree().create_timer(1.5).timeout.connect(fxp.queue_free)
	var flash := ColorRect.new()
	flash.color = col.lightened(0.5) if not Game.reduce_fx() else Color(0, 0, 0, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal.add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, 0.5)
	circle.queue_free()
	inner.queue_free()
	motes.queue_free()

	# --- cards
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -90
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 5 if results.size() > 1 else 1
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	center.add_child(grid)
	var card_size := Vector2(150, 196) if results.size() > 1 else Vector2(240, 312)
	var holders: Array = []
	for r in results:
		var holder := Control.new()
		holder.custom_minimum_size = card_size
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(holder)
		var back := Panel.new()
		var rc: Color = DB.RARITY_COLOR[r["rarity"]]
		back.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, Color.TRANSPARENT, 12, 0, 0))
		back.size = card_size
		back.pivot_offset = card_size * 0.5
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var art_back := UI.tex_rect(DB.tex("res://art/ui/card_back.png"))
		art_back.stretch_mode = TextureRect.STRETCH_SCALE
		art_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		back.add_child(art_back)
		if r["rarity"] != "R":
			# rarity tell: SR cards pulse purple, SSR cards pulse gold before they turn
			var halo := Panel.new()
			halo.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, rc.lightened(0.2), 14, 4, 0, 18 if r["rarity"] == "SSR" else 10))
			(halo.get_theme_stylebox("panel") as StyleBoxFlat).shadow_color = Color(rc.r, rc.g, rc.b, 0.8)
			halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			halo.offset_left = -3
			halo.offset_top = -3
			halo.offset_right = 3
			halo.offset_bottom = 3
			halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			back.add_child(halo)
			var ht := halo.create_tween().set_loops()
			ht.tween_property(halo, "modulate:a", 0.35, 0.45).set_trans(Tween.TRANS_SINE)
			ht.tween_property(halo, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
		holder.add_child(back)
		back.scale = Vector2(0.2, 0.2)
		back.modulate.a = 0.0
		var dt := back.create_tween().set_parallel(true)
		dt.tween_property(back, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(holders.size() * 0.05)
		dt.tween_property(back, "modulate:a", 1.0, 0.2).set_delay(holders.size() * 0.05)
		holders.append(back)
	await get_tree().process_frame
	for i in results.size():
		if not is_inside_tree() or not is_instance_valid(_reveal):
			return
		var r: Dictionary = results[i]
		var back: Panel = holders[i]
		if r["rarity"] == "SSR" and not skip[0]:
			await _ssr_splash(r)
			if not is_inside_tree() or not is_instance_valid(_reveal):
				return
		var ft := back.create_tween()
		ft.tween_property(back, "scale:x", 0.0, 0.08 if skip[0] else 0.14)
		await ft.finished
		if not is_instance_valid(back):
			return
		for c in back.get_children():
			c.queue_free()
		back.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0))
		var card := HeroCard.new(r["id"], card_size, {"show_level": false, "owned": true})
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_child(card)
		var tag := UI.label("NEW!" if r["new"] else "+%d Shards" % r["shards"], 15, UI.GREEN if r["new"] else UI.GOLD, 5)
		tag.position = Vector2(0, card_size.y + 2)
		tag.size = Vector2(card_size.x, 20)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		back.add_child(tag)
		var ft2 := back.create_tween()
		ft2.tween_property(back, "scale:x", 1.0, 0.08 if skip[0] else 0.14)
		if r["rarity"] != "R":
			_card_shine(back, card_size, DB.RARITY_COLOR[r["rarity"]], r["rarity"] == "SSR")
		if r["rarity"] != "R":
			Game.sfx("star_up")
		if not skip[0]:
			await get_tree().create_timer(0.12).timeout

	var bar := UI.hbox(16)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_top = -86
	bar.offset_bottom = -24
	bar.offset_left = -300
	bar.offset_right = 300
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_reveal.add_child(bar)
	bar.add_child(UI.button("CLOSE", func():
		_reveal.queue_free()
		_render(), "", Vector2(200, 56)))
	var again_count := results.size()
	var pay := Game.pull_pay(again_count)
	bar.add_child(UI.button("SUMMON x%d AGAIN" % again_count, func():
		_reveal.queue_free()
		_reveal = null
		_pull(again_count, pay), "GoldButton", Vector2(260, 56)))

## Rotating rays behind SR/SSR cards + a sweeping shine across the card.
func _card_shine(back: Control, sz: Vector2, col: Color, big: bool) -> void:
	var rays := UI.tex_rect(DB.tex("res://art/vfx/vfx_magic_circle.png"))
	var s := sz.x * (1.9 if big else 1.5)
	rays.size = Vector2(s, s)
	rays.position = sz * 0.5 - rays.size * 0.5
	rays.pivot_offset = rays.size * 0.5
	rays.modulate = Color(col.r, col.g, col.b, 0.8)
	rays.show_behind_parent = true
	back.add_child(rays)
	back.move_child(rays, 0)
	var rt := rays.create_tween().set_loops()
	rt.tween_property(rays, "rotation", TAU, 5.0).from(0.0)
	var sweep := ColorRect.new()
	sweep.color = Color(1, 1, 1, 0.35)
	sweep.size = Vector2(sz.x * 0.25, sz.y * 1.4)
	sweep.rotation = 0.35
	sweep.position = Vector2(-sz.x * 0.4, -sz.y * 0.2)
	sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip := Control.new()
	clip.size = sz
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(clip)
	clip.add_child(sweep)
	var st := sweep.create_tween().set_loops()
	st.tween_property(sweep, "position:x", sz.x * 1.2, 0.9).from(-sz.x * 0.4).set_trans(Tween.TRANS_SINE)
	st.tween_interval(1.6 if big else 2.4)
	back.pivot_offset = sz * 0.5
	var pt := back.create_tween()
	pt.tween_interval(0.16)
	pt.tween_property(back, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
	pt.tween_property(back, "scale", Vector2.ONE, 0.2)

func _ssr_splash(r: Dictionary) -> void:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal.add_child(layer)
	var bg := UI.tex_rect(DB.bg("galaxy"), Vector2.ZERO, true)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.12, 0.0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	if ResourceLoader.exists("res://art/ui/rays.png"):
		var rays := TextureRect.new()
		rays.texture = load("res://art/ui/rays.png")
		rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rays.size = Vector2(1100, 1100)
		rays.pivot_offset = Vector2(550, 550)
		rays.position = Vector2(get_viewport_rect().size.x * 0.33 - 550, get_viewport_rect().size.y * 0.5 - 550)
		rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rm := CanvasItemMaterial.new()
		rm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rays.material = rm
		layer.add_child(rays)
		rays.create_tween().set_loops().tween_property(rays, "rotation", TAU, 24.0).from(0.0)
	var sparks := FestivalFX.new("firefly", Color("#ffe27a"), 46)
	layer.add_child(sparks)
	var art := UI.tex_rect(DB.art(r["id"], 0))
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 80
	art.offset_right = -420
	layer.add_child(art)
	UI.live(art, Color("#ffe6a3"))
	art.resized.connect(func(): art.pivot_offset = Vector2(art.size.x * 0.5, art.size.y * 0.4))
	art.scale = Vector2(1.35, 1.35)
	art.modulate.a = 0.0
	var at := art.create_tween().set_parallel(true)
	at.tween_property(art, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	at.tween_property(art, "modulate:a", 1.0, 0.35)
	var wf := ColorRect.new()
	wf.color = Color(1, 0.97, 0.85, 0.9) if not Game.reduce_fx() else Color(0, 0, 0, 0)
	wf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(wf)
	wf.create_tween().tween_property(wf, "modulate:a", 0.0, 0.45)
	var v := UI.vbox(6)
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	v.offset_left = -540
	v.offset_right = -60
	v.offset_top = -120
	v.offset_bottom = 120
	layer.add_child(v)
	var tag := UI.rarity_tag("SSR", 26)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(tag)
	var nm := UI.label(DB.name_of(r["id"]).to_upper(), 50, UI.GOLD, 10)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)
	# name slams in
	(func():
		nm.pivot_offset = nm.size * Vector2(0.0, 0.5)
		nm.scale = Vector2(1.8, 1.8)
		nm.create_tween().tween_property(nm, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.25)).call_deferred()
	v.add_child(UI.label(DB.title_of(r["id"]), 20, Color.WHITE, 5))
	v.add_child(UI.stars(DB.RARITY_START_STAR["SSR"], 34))
	v.add_child(UI.wrap_label("\"%s\"" % Game.voice(r["id"], "summon"), 18, Color("#ffe6a3")))
	if r["new"]:
		v.add_child(UI.label("NEW HERO!", 24, UI.GREEN, 6))
	UI.fade_in(v, 0.5, Vector2(60, 0))
	Game.sfx("awakening")
	var done := [false]
	layer.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			done[0] = true)
	for k in 40:
		if done[0] or not is_inside_tree():
			break
		await get_tree().create_timer(0.1).timeout
	if is_instance_valid(layer):
		layer.queue_free()
