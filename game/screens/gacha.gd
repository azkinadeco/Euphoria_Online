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
	# the featured hero's own realm when she has one, else the banner's map
	var feat_bg := str(b.get("featured", ""))
	_bg_rect.texture = DB.bg(DB.hero_bg_key(feat_bg) if feat_bg != "" and DB.has_hero_bg(feat_bg) else str(b["bg"]))
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
		var fid: String = bd["featured"] if bd["featured"] != "" else ("rumi" if bd.has("tiers") else "cthollia")
		var face := UI.face_rect(fid, Vector2(66, 66))
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(face)
		var v := UI.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var kind := "RATE UP" if bd["featured"] != "" else ("NORMAL  •  GOLD" if bd.has("tiers") else "STANDARD")
		v.add_child(UI.label(kind, 12, Color("#ff9ad5") if bd["featured"] != "" else (UI.GOLD if bd.has("tiers") else Color("#9fb4ff")), 3))
		var nl := UI.label(DB.name_of(fid) if bd["featured"] != "" else ("N to SSR heroes" if bd.has("tiers") else "All Heroes"), 18, Color.WHITE, 3)
		v.add_child(nl)
		h.add_child(v)
		_list.add_child(btn)

	var fid2: String = b["featured"]
	_frames = b.get("img", [])
	_frame_i = 0
	_art.texture = DB.tex(_frames[0]) if not _frames.is_empty() else DB.art(fid2 if fid2 != "" else ("rumi" if b.has("tiers") else "cthollia"), 0)
	for c in _info.get_children():
		c.queue_free()
	_info.add_child(UI.label(b["name"].to_upper(), 24, UI.GOLD, 5))
	if not bool(Game.s["gacha"].get("first10_done", false)) and not b.has("tiers"):
		var fl := UI.label("★ FIRST 10x SUMMON: GUARANTEED %s+! ★" % DB.FIRST10_RARITY, 15, UI.GOLD, 4)
		_info.add_child(fl)
		var ft := fl.create_tween().set_loops()
		ft.tween_property(fl, "modulate", Color(1.4, 1.3, 1.0), 0.6)
		ft.tween_property(fl, "modulate", Color.WHITE, 0.6)
	if fid2 != "":
		var r := UI.hbox(8)
		r.add_child(UI.rarity_tag(DB.rarity_of(fid2), 15))
		r.add_child(UI.label(DB.name_of(fid2), 22, Color.WHITE, 4))
		_info.add_child(r)
		_info.add_child(UI.label(DB.title_of(fid2), 14, DB.theme_color(fid2).lightened(0.35), 3))
		_info.add_child(UI.wrap_label(DB.skill_of(fid2)["name"] + ": " + str(DB.skill_of(fid2).get("desc", "")), 13, UI.TEXT))
	_info.add_child(UI.wrap_label(b["desc"], 14, UI.MUTED))
	# the banner's own drop rates, rarest first (wraps on narrow screens)
	var rates := HFlowContainer.new()
	rates.add_theme_constant_override("h_separation", 5)
	rates.add_theme_constant_override("v_separation", 5)
	_info.add_child(rates)
	var rt_map := DB.gacha_rates(b.get("tiers", []))
	var order: Array = DB.RARITY_ORDER.duplicate()
	order.reverse()
	for r0 in order:
		if not rt_map.has(r0):
			continue
		var rcol: Color = DB.RARITY_COLOR[r0]
		var rp := UI.styled_panel(Color(rcol, 0.15), Color(rcol, 0.6), 8, 1, 4.0)
		var rl := UI.label("%s %s" % [r0, rate_text(float(rt_map[r0]))], 12, rcol.lightened(0.15), 2)
		rp.add_child(rl)
		rates.add_child(rp)
	var meters := UI.styled_panel(Color(0, 0, 0, 0.35), Color(1, 1, 1, 0.1), 10, 1, 8.0)
	_info.add_child(meters)
	var mv := UI.vbox(6)
	meters.add_child(mv)
	var pity := int(Game.s["gacha"]["pity"])
	if not b.has("tiers"):
		mv.add_child(_meter("PITY", "%s+ guaranteed at %d" % [DB.PITY_RARITY, DB.GACHA_PITY], pity, DB.GACHA_PITY, DB.RARITY_COLOR[DB.PITY_RARITY]))
	if b.has("tiers"):
		mv.add_child(UI.wrap_label("Paid with Gold: %s per summon. No pity or Summon Points on this banner." % Game.fmt(int(b.get("cost", 6000))), 12, UI.MUTED))
	elif fid2 != "":
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
			r["rarity"] = DB.rarity_of(str(r.get("id", fid2)))
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
	else:
		mv.add_child(_wish_row())
	if b.has("tiers"):
		_info.add_child(UI.wrap_label("10x summon guarantees at least one SR. Duplicates turn into hero shards.", 12, UI.MUTED))
	else:
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
	if Game.can_free_pull() and not DB.BANNERS[_banner_i].has("tiers"):
		_btns.add_child(_pull_btn("FREE DAILY\nSUMMON x1", 1, "free"))
	var bid0: String = DB.BANNERS[_banner_i]["id"]
	_btns.add_child(_pull_btn("SUMMON x1\n%s" % _price(1), 1, Game.pull_pay(1, bid0)))
	_btns.add_child(_pull_btn("SUMMON x10\n%s" % _price(10), 10, Game.pull_pay(10, bid0)))

## A drop rate as text: 30%, 0.1%, 0.0001%.
static func rate_text(r: float) -> String:
	var t := "%.4f" % (r * 100.0)
	t = t.rstrip("0").rstrip(".")
	return t + "%"

func _price(count: int) -> String:
	var bnr: Dictionary = DB.BANNERS[_banner_i]
	if str(bnr.get("cur", "")) == "gold":
		return "%s Gold" % Game.fmt(int(bnr.get("cost", 6000)) * count)
	var tk := mini(Game.amount("summon_ticket"), count)
	var gems := "%s Gems" % Game.fmt(DB.GACHA_COST * (count - tk))
	if tk == 0:
		return gems
	var tickets := "%d Ticket%s" % [tk, "" if tk == 1 else "s"]
	return tickets if tk == count else "%s + %s" % [tickets, gems]

func _pull_btn(text: String, count: int, pay: String) -> Button:
	var b := UI.button(text, func(): _pull(count, pay), "GoldButton" if count == 10 or pay == "free" else "", Vector2(216, 92))
	b.add_theme_font_size_override("font_size", 19)
	if pay == "gold":
		b.icon = DB.icon("icon_gold")
		b.add_theme_constant_override("icon_max_width", 34)
		if Game.amount("gold") < int(DB.BANNERS[_banner_i].get("cost", 6000)) * count:
			b.modulate = Color(0.82, 0.8, 0.85)
			b.tooltip_text = "Not enough Gold"
	elif pay != "free":
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

## Standard banner: the wishlist slots + EDIT.
func _wish_row() -> Control:
	var w := Game.wishlist()
	var v := UI.vbox(4)
	var h := UI.hbox(6)
	v.add_child(h)
	h.add_child(UI.label("WISHLIST", 13, Color("#ff9ad5"), 2))
	var sl := UI.label("%d%% of pulls of a pick's rarity become your picks" % int(DB.WISH_RATE * 100), 11, UI.MUTED, 0)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sl)
	var r := UI.hbox(8)
	v.add_child(r)
	for i in DB.WISH_MAX:
		var slot := UI.styled_panel(Color(0, 0, 0, 0.5), Color("#ff9ad5") if i < w.size() else Color(1, 1, 1, 0.2), 8, 2 if i < w.size() else 1, 2)
		slot.custom_minimum_size = Vector2(50, 50)
		if i < w.size():
			slot.add_child(UI.face_rect(str(w[i]), Vector2(44, 44)))
			slot.tooltip_text = DB.name_of(str(w[i]))
		else:
			var pl := UI.label("+", 22, Color(1, 1, 1, 0.35), 0)
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(pl)
		r.add_child(slot)
	r.add_child(UI.spacer())
	var eb := UI.button("EDIT WISHLIST", _show_wishlist, "GoldButton" if w.is_empty() else "", Vector2(140, 38))
	eb.add_theme_font_size_override("font_size", 12)
	eb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(eb)
	return v

func _show_wishlist() -> void:
	var v: VBoxContainer = main.popup("WISHLIST", 760)
	var head := UI.label("", 14, UI.GOLD, 2)
	v.add_child(head)
	v.add_child(UI.wrap_label("Pick up to %d heroes of SSR rarity or higher. On the Standard Summon, %d%% of your pulls of a picked hero's rarity become one of your picks of that rarity. Heroes you already own still count: duplicates become shards." % [DB.WISH_MAX, int(DB.WISH_RATE * 100)], 13, UI.MUTED))
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 8)
	f.add_theme_constant_override("v_separation", 8)
	var sc := UI.scroll(f)
	sc.custom_minimum_size = Vector2(0, 360)
	v.add_child(sc)
	var cards := {}
	var sync := func():
		var w := Game.wishlist()
		head.text = "Chosen %d / %d" % [w.size(), DB.WISH_MAX]
		for id in cards.keys():
			(cards[id] as HeroCard).set_selected(w.has(id))
			(cards[id] as HeroCard).get_node("wish").visible = w.has(id)
	for id in DB.hero_ids():
		if not DB.rarity_at_least(id, DB.WISH_MIN_RARITY):
			continue
		var hid: String = id
		var card := HeroCard.new(hid, Vector2(96, 124), {"show_level": false, "lazy": true})
		if not Game.owns(hid):
			card.tooltip_text = "Not recruited yet"
		card.pressed.connect(func():
			var err := Game.toggle_wish(hid)
			if err != "":
				main.toast(err, UI.RED)
				return
			Game.sfx("ui_click")
			sync.call())
		var tag := UI.styled_panel(Color("#c2185b"), Color("#ffd0e4"), 8, 1, 2)
		tag.name = "wish"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.position = Vector2(14, 50)
		tag.custom_minimum_size = Vector2(68, 0)
		var tgl := UI.label("♥ WISH", 12, Color.WHITE, 2)
		tgl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(tgl)
		card.add_child(tag)
		cards[hid] = card
		f.add_child(card)
	sync.call()
	var ok := UI.button("DONE", func():
		main.close_popup(v)
		_render(), "GoldButton", Vector2(180, 46))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)

func _show_history() -> void:
	var v: VBoxContainer = main.popup("SUMMON HISTORY", 640)
	var hist: Array = Game.s["gacha"].get("history", [])
	var cnt := {}
	for h in hist:
		cnt[h["r"]] = int(cnt.get(h["r"], 0)) + 1
	var parts: Array = []
	var ordr: Array = DB.RARITY_ORDER.duplicate()
	ordr.reverse()
	for r1 in ordr:
		if cnt.has(r1):
			parts.append("%s %d" % [r1, int(cnt[r1])])
	v.add_child(UI.wrap_label("Last %d pulls  •  %s   (total pulls %d)" % [hist.size(), "  •  ".join(parts) if not parts.is_empty() else "-", int(Game.s["gacha"]["total"])], 14, UI.MUTED))
	var list := UI.vbox(4)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 400)
	v.add_child(sc)
	if hist.is_empty():
		list.add_child(UI.label("No summons yet.", 15, UI.MUTED))
	for h in hist:
		var row := UI.hbox(10)
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR.get(h["r"], UI.ACCENT), 6, 2, 1)
		fp.add_child(UI.face_rect(h["id"], Vector2(32, 32)))
		row.add_child(fp)
		var nl := UI.label("%s  %s" % [h["r"], DB.name_of(h["id"])], 15, (DB.RARITY_COLOR.get(h["r"], UI.ACCENT) as Color).lightened(0.2), 2)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		row.add_child(UI.label(Time.get_datetime_string_from_unix_time(int(h["t"]) + 7 * 3600).replace("T", " ").substr(0, 16), 12, UI.MUTED))
		list.add_child(row)
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

func _show_rates() -> void:
	var v: VBoxContainer = main.popup("RATES", 720)
	var bnr: Dictionary = DB.BANNERS[_banner_i]
	var rt_map := DB.gacha_rates(bnr.get("tiers", []))
	if not bnr.has("tiers"):
		v.add_child(UI.wrap_label("Pity: %s or better guaranteed within %d summons. The %s rate includes the share of tiers that have no heroes yet." % [DB.PITY_RARITY, DB.GACHA_PITY, DB.RARITY_ORDER[0]], 13, UI.MUTED))
	var order2: Array = DB.RARITY_ORDER.duplicate()
	order2.reverse()
	for r in order2:
		var ids: Array = DB.hero_ids().filter(func(h): return DB.rarity_of(h) == r)
		if bnr.has("tiers") and not (bnr["tiers"] as Array).has(r):
			continue
		var hr := UI.hbox(8)
		hr.add_child(UI.rarity_tag(r, 15))
		hr.add_child(UI.rarity_text(r, 15))
		var rl2 := UI.label(rate_text(float(rt_map[r])) if rt_map.has(r) else "no heroes yet", 15, Color.WHITE if rt_map.has(r) else UI.MUTED, 2)
		rl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hr.add_child(rl2)
		v.add_child(hr)
		if ids.is_empty():
			continue
		var f := HFlowContainer.new()
		f.add_theme_constant_override("h_separation", 8)
		f.add_theme_constant_override("v_separation", 8)
		for id in ids:
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

## Reveal intensity of a rarity: 0 = N / R, 1 = SR, 2 = SSR and above (gold rays, splash).
static func _tier(r: String) -> int:
	var k := DB.rarity_rank(r)
	return 2 if k >= DB.rarity_rank("SSR") else (1 if k == DB.rarity_rank("SR") else 0)

func _play_reveal(results: Array) -> void:
	_reveal = Control.new()
	_reveal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_reveal)
	var best := "N"
	for r in results:
		if DB.rarity_rank(r["rarity"]) > DB.rarity_rank(best):
			best = r["rarity"]
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

	# --- gate: charge -> rarity tell -> burst (game/ui/summon_fx.gd)
	Game.sfx("gacha_gate")
	var gate := SummonFX.new()
	_reveal.add_child(gate)
	var skip := [false]
	dark.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			skip[0] = true)
	var tier: int = _tier(best)
	gate.charge(1.2)
	for k in 12:
		if skip[0] or not is_inside_tree():
			break
		await get_tree().create_timer(0.1).timeout
	if not is_inside_tree() or not is_instance_valid(_reveal):
		return
	# the tell: the core takes the colour of the best card (blue / purple / gold) and the rays open
	if not skip[0]:
		gate.tell(col.lightened(0.15), tier, 0.9)
		if _tier(best) == 2:
			Game.sfx("battle/light")
			if not Game.reduce_fx():
				var sh := _reveal.create_tween().set_loops(6)
				sh.tween_property(_reveal, "position", Vector2(5, -3), 0.05)
				sh.tween_property(_reveal, "position", Vector2(-4, 3), 0.05)
				sh.tween_property(_reveal, "position", Vector2.ZERO, 0.05)
		for k in 9:
			if skip[0] or not is_inside_tree():
				break
			await get_tree().create_timer(0.1).timeout
		if not is_inside_tree() or not is_instance_valid(_reveal):
			return
		_reveal.position = Vector2.ZERO
	gate.burst(0.7)
	Game.haptic([30, 60, 120][_tier(best)])
	Game.sfx("star_up" if _tier(best) == 2 else "ui_click")
	var flash := ColorRect.new()
	flash.color = col.lightened(0.5) if not Game.reduce_fx() else Color(0, 0, 0, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal.add_child(flash)
	flash.modulate.a = 0.75
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, 0.55)
	motes.queue_free()
	# let the shock ring open before the cards land
	await get_tree().create_timer(0.28).timeout
	if not is_inside_tree() or not is_instance_valid(_reveal):
		return

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
		if _tier(r["rarity"]) > 0:
			# rarity tell: SR cards pulse purple, SSR cards pulse gold before they turn
			var halo := Panel.new()
			halo.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, rc.lightened(0.2), 14, 4, 0, 18 if _tier(r["rarity"]) == 2 else 10))
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
		holders.append(back)
	await get_tree().process_frame
	# each card is delivered by a streak of light from the gate, in the colour of its rarity; it lands, the
	# card pops out of the impact
	var travel := 0.0 if skip[0] or Game.reduce_fx() else 0.26
	for i in holders.size():
		var hb: Panel = holders[i]
		var delay: float = i * (0.02 if skip[0] else 0.06)
		if travel > 0.0:
			_comet(_reveal.size * 0.5, hb.get_global_rect().get_center() - _reveal.get_global_rect().position, (DB.RARITY_COLOR[results[i]["rarity"]] as Color).lightened(0.25), delay, travel)
		var dt := hb.create_tween().set_parallel(true)
		dt.tween_property(hb, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay + travel)
		dt.tween_property(hb, "modulate:a", 1.0, 0.18).set_delay(delay + travel)
	if travel > 0.0:
		await get_tree().create_timer(travel + holders.size() * 0.06 + 0.15).timeout
		if not is_inside_tree() or not is_instance_valid(_reveal):
			return
	for i in results.size():
		if not is_inside_tree() or not is_instance_valid(_reveal):
			return
		var r: Dictionary = results[i]
		var back: Panel = holders[i]
		if _tier(r["rarity"]) == 2 and not skip[0]:
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
		# tap a revealed card to look at her full art
		var rid: String = r["id"]
		back.mouse_filter = Control.MOUSE_FILTER_STOP
		back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		back.tooltip_text = "View " + DB.name_of(rid)
		back.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(_reveal) and _reveal.has_meta("done"):
				Game.sfx("ui_click")
				ArtViewer.open(main, rid, 0, [0]))
		var tag := UI.label("NEW!" if r["new"] else "+%d Shards" % r["shards"], 15, UI.GREEN if r["new"] else UI.GOLD, 5)
		tag.position = Vector2(0, card_size.y + 2)
		tag.size = Vector2(card_size.x, 20)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		back.add_child(tag)
		var ft2 := back.create_tween()
		ft2.tween_property(back, "scale:x", 1.0, 0.08 if skip[0] else 0.14)
		if _tier(r["rarity"]) > 0:
			_card_shine(back, card_size, DB.RARITY_COLOR[r["rarity"]], _tier(r["rarity"]) == 2)
		if _tier(r["rarity"]) > 0:
			Game.sfx("star_up")
		if not skip[0]:
			await get_tree().create_timer(0.12).timeout

	_reveal.set_meta("done", true)   # all cards turned: they can be tapped now
	var hint := UI.label("Tap a card to view her art", 13, UI.MUTED, 2)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -104
	hint.offset_bottom = -86
	hint.offset_left = -200
	hint.offset_right = 200
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal.add_child(hint)
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
	var pay := Game.pull_pay(again_count, str(DB.BANNERS[_banner_i]["id"]))
	bar.add_child(UI.button("SUMMON x%d AGAIN" % again_count, func():
		_reveal.queue_free()
		_reveal = null
		_pull(again_count, pay), "GoldButton", Vector2(260, 56)))

## A streak of light flying along a shallow arc from `from` to `to`, with a tapering tail and a small flash
## where it lands.
func _comet(from: Vector2, to: Vector2, col: Color, delay: float, dur: float) -> void:
	var line := Line2D.new()
	line.width = 9.0
	var wc := Curve.new()
	wc.add_point(Vector2(0, 0.0))
	wc.add_point(Vector2(1, 1.0))
	line.width_curve = wc
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.set_color(1, Color(col.lightened(0.5), 1.0))
	line.gradient = g
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	line.material = add
	_reveal.add_child(line)
	var mid := (from + to) * 0.5 + Vector2((to.y - from.y) * 0.35, -(to.x - from.x) * 0.2 - 40.0)
	var at := func(t: float) -> Vector2:
		return from.lerp(mid, t).lerp(mid.lerp(to, t), t)
	var tw := line.create_tween()
	tw.tween_interval(delay)
	tw.tween_method(func(p: float):
		var pts := PackedVector2Array()
		for k in 9:
			pts.append(at.call(clampf(p - 0.34 + k * 0.0425, 0.0, 1.0)))
		line.points = pts, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		var fl := Panel.new()
		fl.add_theme_stylebox_override("panel", UI.style(Color(col.lightened(0.6), 0.9), Color.TRANSPARENT, 40, 0, 0, 24))
		(fl.get_theme_stylebox("panel") as StyleBoxFlat).shadow_color = Color(col, 0.8)
		fl.size = Vector2(46, 46)
		fl.position = to - Vector2(23, 23)
		fl.pivot_offset = Vector2(23, 23)
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fl.material = add
		_reveal.add_child(fl)
		var ftw := fl.create_tween().set_parallel(true)
		ftw.tween_property(fl, "scale", Vector2(3.0, 3.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ftw.tween_property(fl, "modulate:a", 0.0, 0.25)
		ftw.chain().tween_callback(fl.queue_free))
	tw.tween_property(line, "modulate:a", 0.0, 0.12)
	tw.tween_callback(line.queue_free)

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
	# she arrives in front of her own realm when she has one
	var own_bg: bool = DB.has_hero_bg(str(r["id"]))
	var bg := UI.tex_rect(DB.bg(DB.hero_bg_key(str(r["id"])) if own_bg else "galaxy"), Vector2.ZERO, true)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.03, 0.1, 0.4) if own_bg else Color(0.2, 0.12, 0.0, 0.45)
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
	var tag := UI.rarity_tag(DB.rarity_of(str(r["id"])), 26)
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
	v.add_child(UI.stars(DB.RARITY_START_STAR[DB.rarity_of(str(r["id"]))], 34))
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
