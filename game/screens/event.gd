extends Screen
## Limited-time event: hero showcase + limited skin reward on the left, stages / exchange / story on the right.

var _right: VBoxContainer
var _tab := "STAGES"
var _timer: Label
var _tokens: Label
var _skin_box: VBoxContainer
var _t := 0.0
var _col := Color("#4ab3ff")

## Event story: prologue on the first visit of this event period, epilogue after its boss falls.
func _event_story() -> void:
	var ev: Dictionary = Game.s["event"]
	var last: int = (DB.EVENT["stages"] as Array).size() - 1
	if not bool(ev.get("intro_seen", false)) and DB.EVENT.has("intro"):
		ev["intro_seen"] = true
		Game.mark_dirty()
		main.dialogue(DB.EVENT["intro"], Callable(), str(DB.EVENT["bg"]))
	elif Game.event_stars(last) > 0 and not bool(ev.get("outro_seen", false)) and DB.EVENT.has("outro"):
		ev["outro_seen"] = true
		Game.mark_dirty()
		main.dialogue(DB.EVENT["outro"], Callable(), str(DB.EVENT["bg"]))

func build() -> void:
	var fid: String = DB.EVENT["featured"]
	_col = Color(str(DB.EVENT.get("color", "#4ab3ff")))
	set_bg(DB.EVENT["bg"], 0.45)
	if DB.EVENT.has("fx"):
		add_child(FestivalFX.new(str(DB.EVENT["fx"]), Color.WHITE, 40))
	header("EVENT", ["energy", "festival_token"])
	if str(params.get("tab", "")) != "":
		_tab = str(params["tab"])

	# --- left: featured art with a coloured glow
	var glow := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.6)
	gt.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(_col, 0.45))
	gr.set_color(1, Color(_col, 0.0))
	gt.gradient = gr
	glow.texture = gt
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.anchor_right = 0.4
	glow.offset_top = 120
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var tex: Texture2D = DB.tex(str(DB.EVENT["art"])) if DB.EVENT.has("art") else DB.art(fid, 1)
	var art := UI.tex_rect(tex)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_right = 0.4
	art.offset_top = 150
	art.offset_bottom = -150 if DB.EVENT.has("skin") else 0
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	UI.live(art, _col.lightened(0.5))
	UI.fade_in(art, 0.5, Vector2(-40, 0))

	# title card
	var ip := UI.styled_panel(Color(0.04, 0.03, 0.1, 0.88), Color(_col, 0.8), 14, 1, 12)
	ip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ip.anchor_right = 0.4
	ip.offset_left = 16
	ip.offset_right = -12
	ip.offset_top = 80
	add_child(ip)
	var info := UI.vbox(2)
	ip.add_child(info)
	var tr := UI.hbox(8)
	info.add_child(tr)
	var tag := UI.styled_panel(Color(_col, 0.25), _col, 8, 1, 0)
	tag.add_child(UI.label("  LIMITED EVENT  ", 12, Color.WHITE, 2))
	tr.add_child(tag)
	_timer = UI.label("", 13, _col.lightened(0.45), 3)
	tr.add_child(_timer)
	info.add_child(UI.label(str(DB.EVENT["name"]).to_upper(), 28, UI.GOLD, 6))
	var cleared := 0
	var stars := 0
	for i in (DB.EVENT["stages"] as Array).size():
		stars += Game.event_stars(i)
		cleared += 1 if Game.event_stars(i) > 0 else 0
	var n_st: int = (DB.EVENT["stages"] as Array).size()
	var pr := UI.hbox(10)
	info.add_child(pr)
	pr.add_child(UI.label("Stages %d/%d   ★ %d/%d" % [cleared, n_st, stars, n_st * 3], 13, Color.WHITE, 2))
	var pb := UI.bar(stars, n_st * 3, "GoldBar", 6)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pr.add_child(pb)

	# limited skin showcase (events that award one)
	if DB.EVENT.has("skin"):
		var sp := UI.styled_panel(Color(0.05, 0.02, 0.06, 0.9), Color(_col, 0.9), 14, 2, 10)
		sp.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		sp.anchor_right = 0.4
		sp.offset_left = 16
		sp.offset_right = -12
		sp.offset_bottom = -16
		sp.grow_vertical = Control.GROW_DIRECTION_BEGIN
		add_child(sp)
		_skin_box = UI.vbox(4)
		sp.add_child(_skin_box)
		var shine := sp.create_tween().set_loops()
		shine.tween_property(sp, "self_modulate", Color(1.25, 1.1, 1.15), 1.2).set_trans(Tween.TRANS_SINE)
		shine.tween_property(sp, "self_modulate", Color.WHITE, 1.2).set_trans(Tween.TRANS_SINE)
		_render_skin()

	# --- right: tabs
	var rp := UI.panel()
	rp.set_anchors_preset(Control.PRESET_FULL_RECT)
	rp.anchor_left = 0.4
	rp.offset_right = -16
	rp.offset_top = 80
	rp.offset_bottom = -16
	add_child(rp)
	var rv := UI.vbox(10)
	rp.add_child(rv)
	var tabs := UI.hbox(8)
	rv.add_child(tabs)
	for t in ["STAGES", "EXCHANGE", "STORY"]:
		var key: String = t
		var b := UI.button(t, func(): _tab = key; _render(), "TabButton", Vector2(140, 42))
		b.toggle_mode = true
		b.set_meta("key", key)
		tabs.add_child(b)
	tabs.add_child(UI.spacer())
	var tk := UI.hbox(4)
	tk.add_child(UI.tex_rect(DB.icon("icon_live_ops"), Vector2(26, 26)))
	_tokens = UI.label("", 17, UI.GOLD, 3)
	tk.add_child(_tokens)
	tabs.add_child(tk)
	_right = UI.vbox(8)
	rv.add_child(UI.scroll(_right))
	_render()
	_update_timer()
	_event_story.call_deferred()

## Bottom-left card: the limited skin, its price and how close the player is.
func _render_skin() -> void:
	if not is_instance_valid(_skin_box):
		return
	for c in _skin_box.get_children():
		c.queue_free()
	var hid: String = DB.EVENT["skin"]
	var si := DB.special_index(hid)
	var item: Dictionary = {}
	for it in DB.EVENT["shop"]:
		if (it["give"] as Dictionary).has("skin:" + hid):
			item = it
	var have := (Game.s["skins_bought"].get(hid, []) as Array).has(si)
	var h := UI.hbox(10)
	_skin_box.add_child(h)
	var fr := UI.styled_panel(Color.BLACK, _col, 34, 2, 2)
	fr.add_child(UI.tex_rect(DB.face(hid, si), Vector2(64, 64), true))
	fr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(fr)
	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("✦ LIMITED SKIN  •  %s" % DB.name_of(hid), 12, _col.lightened(0.35), 2))
	v.add_child(UI.label(str(DB.SPECIAL_SKINS.get(hid, "Special Skin")), 20, Color.WHITE, 4))
	v.add_child(UI.label("+10% ATK & HP while worn  •  new battle sprite", 11, UI.MUTED, 2))
	if have:
		var row := UI.hbox(8)
		_skin_box.add_child(row)
		var ok := UI.label("✓ OWNED", 15, UI.GREEN, 3)
		ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ok)
		if Game.owns(hid):
			var eq := int(Game.hero(hid).get("skin", 0)) == si
			var wb := UI.button("WEARING" if eq else "WEAR NOW", func():
				Game.set_skin(hid, si)
				Game.sfx("star_up")
				main.toast("%s is wearing %s!" % [DB.name_of(hid), DB.SPECIAL_SKINS[hid]], Color("#ff8fb8"))
				_render_skin(), "" if eq else "GoldButton", Vector2(130, 38))
			wb.disabled = eq
			row.add_child(wb)
		else:
			row.add_child(UI.label("Recruit %s to wear it" % DB.name_of(hid), 12, Color("#ff8a9a"), 2))
		return
	if item.is_empty():
		return
	var price := int(item["price"])
	var cur := Game.amount("festival_token")
	var bar := UI.bar(mini(cur, price), price, "GoldBar", 8)
	_skin_box.add_child(bar)
	var row2 := UI.hbox(8)
	_skin_box.add_child(row2)
	var st := UI.label(("%s / %s Tokens" % [Game.fmt(cur), Game.fmt(price)]) if cur < price else "Ready to exchange!", 13, UI.GOLD if cur >= price else UI.TEXT, 2)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(st)
	var gb := UI.button("CLAIM" if cur >= price else "VIEW", func():
		if cur >= price:
			_buy(item)
		else:
			_tab = "EXCHANGE"
			_render(), "GoldButton" if cur >= price else "", Vector2(110, 38))
	row2.add_child(gb)

func _process(delta: float) -> void:
	_t += delta
	if _t > 1.0:
		_t = 0.0
		_update_timer()

func _update_timer() -> void:
	var s := maxi(0, Game.event_ends_in())
	_timer.text = "Ends in %dd %02dh %02dm" % [s / 86400, (s / 3600) % 24, (s / 60) % 60]

func refresh() -> void:
	super.refresh()

func _render() -> void:
	for b in find_children("*", "Button", true, false):
		if b.has_meta("key"):
			b.button_pressed = b.get_meta("key") == _tab
	for c in _right.get_children():
		c.queue_free()
	_tokens.text = Game.fmt(Game.amount("festival_token"))
	match _tab:
		"STAGES":
			_right.add_child(UI.wrap_label(DB.EVENT["desc"], 14, UI.MUTED))
			for i in DB.EVENT["stages"].size():
				_stage_row(i)
		"EXCHANGE":
			_right.add_child(UI.wrap_label("Event Tokens drop from event stages (more for ★). Unspent tokens carry over, but the items leave with the event.", 13, UI.MUTED))
			for item in DB.EVENT["shop"]:
				_shop_row(item)
		_:
			_story_tab()
	UI.stagger(_right, 0.05)
	_render_skin()

func _stage_row(i: int) -> void:
	var st := DB.event_stage(i)
	var stars := Game.event_stars(i)
	var unlocked := i == 0 or Game.event_stars(i - 1) > 0
	var boss := st.has("boss") or (st["enemies"] as Array).any(func(e): return e.get("boss", false))
	var bc: Color = Color("#ff5c6c") if boss else _col
	var p := UI.styled_panel(Color(bc.darkened(0.85), 0.92), Color(bc, 0.75 if unlocked else 0.25), 12, 2 if boss else 1, 10)
	if not unlocked:
		p.modulate = Color(1, 1, 1, 0.6)
	_right.add_child(p)
	var h := UI.hbox(12)
	p.add_child(h)
	var num := UI.label("%d" % (i + 1), 30, bc.lightened(0.3) if unlocked else UI.MUTED, 5)
	num.custom_minimum_size = Vector2(30, 0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(num)
	var faces := UI.hbox(3)
	for e in st["enemies"].slice(0, 3):
		var fp := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if e.get("boss", false) else Color(bc, 0.6), 6, 2, 1)
		fp.add_child(UI.tex_rect(DB.face(e["id"]), Vector2(44, 44), true))
		faces.add_child(fp)
	h.add_child(faces)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nr := UI.hbox(6)
	v.add_child(nr)
	nr.add_child(UI.label(str(st["name"]), 18, Color.WHITE if unlocked else UI.MUTED, 2))
	if boss:
		var bt := UI.styled_panel(Color(1, 0.36, 0.42, 0.25), Color("#ff5c6c"), 6, 1, 0)
		bt.add_child(UI.label(" BOSS ", 11, Color.WHITE, 2))
		bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nr.add_child(bt)
	var sr := UI.hbox(8)
	v.add_child(sr)
	sr.add_child(UI.label("★".repeat(stars) + "☆".repeat(3 - stars), 15, UI.GOLD, 2))
	sr.add_child(UI.label("Lv.%d  •  Power %s" % [st["level"], Game.fmt(Game.enemy_power(st["enemies"]))], 12, UI.MUTED))
	var rw := {"festival_token": st["tokens"]}
	if stars == 0:
		rw["gems"] = st["first_gems"]
	v.add_child(UI.reward_row(rw, 22, 13))
	h.add_child(v)
	var idx: int = i
	var b := UI.button("BATTLE" if unlocked else "LOCKED", func(): main.go("formation", {"mode": "event", "stage": idx}), "GoldButton" if unlocked else "", Vector2(116, 48))
	b.disabled = not unlocked
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)

func _shop_row(item: Dictionary) -> void:
	var it := item
	var k: String = it["give"].keys()[0]
	var is_skin := k.begins_with("skin:")
	var left := int(it["limit"]) - Game.event_bought(it["id"])
	if is_skin and (Game.s["skins_bought"].get(k.substr(5), []) as Array).has(DB.special_index(k.substr(5))):
		left = 0
	var col: Color = _col if is_skin else Color(1, 1, 1, 0.2)
	var p := UI.styled_panel(Color(col.darkened(0.8), 0.9) if is_skin else Color(0.06, 0.04, 0.1, 0.85), col, 12, 2 if is_skin else 1, 10)
	_right.add_child(p)
	var h := UI.hbox(12)
	p.add_child(h)
	var sz := Vector2(72, 72) if is_skin else Vector2(52, 52)
	h.add_child(UI.tex_rect(Game.reward_icon(k), sz, k.begins_with("shard:") or is_skin))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_skin:
		v.add_child(UI.label("✦ LIMITED SKIN", 12, _col.lightened(0.35), 2))
	v.add_child(UI.label(it["name"], 19 if is_skin else 17, Color.WHITE, 2))
	v.add_child(UI.label("Sold out" if left <= 0 else "Left: %d / %d" % [left, it["limit"]], 12, UI.MUTED))
	h.add_child(v)
	var b := UI.button("OWNED" if is_skin and left <= 0 else ("%s Tokens" % Game.fmt(it["price"])), func(): _buy(it), "GoldButton", Vector2(150, 46))
	b.icon = DB.icon("icon_live_ops")
	b.add_theme_constant_override("icon_max_width", 22)
	b.disabled = left <= 0
	if Game.amount("festival_token") < int(it["price"]) and left > 0:
		b.add_theme_color_override("font_color", Color("#ff7a7a"))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)

func _buy(it: Dictionary) -> void:
	var err := Game.buy_event(it)
	if err != "":
		main.toast(err.replace("Moon Tokens", "Event Tokens"), UI.RED)
		return
	var k: String = it["give"].keys()[0]
	if k.begins_with("skin:"):
		var hid := k.substr(5)
		Game.sfx("awakening")
		if Game.owns(hid):
			Game.set_skin(hid, DB.special_index(hid))
		main.toast("New skin: %s!" % DB.SPECIAL_SKINS.get(hid, "Special"), Color("#ff8fb8"))
		ArtViewer.open(main, hid, DB.special_index(hid), [DB.special_index(hid)])
	else:
		Game.sfx("star_up")
		main.toast("Exchanged: %s" % it["name"], UI.GREEN)
	_render()

## Replay the event prologue / epilogue.
func _story_tab() -> void:
	var last: int = (DB.EVENT["stages"] as Array).size() - 1
	for part in [["PROLOGUE", "intro", true], ["EPILOGUE", "outro", Game.event_stars(last) > 0]]:
		if not DB.EVENT.has(part[1]):
			continue
		var key: String = part[1]
		var open: bool = part[2]
		var p := UI.styled_panel(Color(0.06, 0.04, 0.1, 0.85), Color(_col, 0.6 if open else 0.2), 12, 1, 12)
		_right.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		var lines: Array = DB.EVENT[key]
		h.add_child(UI.tex_rect(DB.face(str(lines[0][0])), Vector2(56, 56), true))
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(str(part[0]), 17, UI.GOLD if open else UI.MUTED, 3))
		v.add_child(UI.wrap_label(("\"%s\"" % str(lines[0][1])) if open else "Clear the final stage to unlock.", 13, UI.TEXT if open else UI.MUTED))
		var b := UI.button("▶ PLAY" if open else "LOCKED", func(): main.dialogue(DB.EVENT[key], Callable(), str(DB.EVENT["bg"])), "", Vector2(110, 44))
		b.disabled = not open
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
