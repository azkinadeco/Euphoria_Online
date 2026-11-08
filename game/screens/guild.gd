extends Screen
## Guild: join/create, check-in, donations (guild level = stat buff),
## shared raid boss, members ranking and guild shop.

var _tab := "MEMBERS"
var _right: VBoxContainer

func build() -> void:
	set_bg("boss" if Game.in_guild() else "asgard", 0.6)
	header("GUILD", ["gold", "guild_coin"])
	if Game.in_guild():
		_build_hall()
	else:
		_build_lobby()
	tutorial("guild")

func refresh() -> void:
	super.refresh()

# ---------------------------------------------------------------- not joined

const GUILD_CAP := 30

func _build_lobby() -> void:
	var b := body(76)
	# ---- left: why join + create
	var lp := UI.panel()
	lp.anchor_right = 0.36
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(10)
	lp.add_child(UI.scroll(lv))
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_child(UI.label("WHY JOIN A GUILD?", 16, UI.GOLD, 3))
	lv.add_child(_perk(DB.icon("icon_boss"), "Guild Raid", "Fight a shared Raid Boss with your guildmates.", Color("#ff7a5c")))
	lv.add_child(_perk(Game.reward_icon("guild_coin"), "Guild Coins", "Earn coins from check-ins and raids. Spend them in the Guild Shop.", UI.GOLD))
	lv.add_child(_perk(DB.icon("icon_awakening"), "Team Power", "Every guild level above 1 gives +1% ATK & HP to all your heroes.", UI.GREEN))
	lv.add_child(UI.wrap_label("Guilds are offline for now, with AI members. Real guilds arrive with online mode.", 12, Color("#9fd0ff")))

	var cp := UI.styled_panel(Color(0.12, 0.09, 0.18, 0.9), Color(UI.GOLD, 0.4), 12, 1, 10.0)
	lv.add_child(cp)
	var cv := UI.vbox(8)
	cp.add_child(cv)
	cv.add_child(UI.label("FOUND YOUR OWN", 14, UI.GOLD, 2))
	cv.add_child(UI.wrap_label("Start at Lv.1 and grow it yourself.", 12, UI.MUTED))
	var le := LineEdit.new()
	le.placeholder_text = "New guild name"
	le.max_length = 20
	le.custom_minimum_size = Vector2(0, 44)
	cv.add_child(le)
	var cb := UI.button("CREATE  (300 Gems)", func():
		var err := Game.create_guild(le.text)
		if err != "":
			main.toast(err, UI.RED)
		else:
			main.replace("guild"), "", Vector2(0, 44))
	cb.disabled = Game.amount("gems") < 300
	if cb.disabled:
		cb.tooltip_text = "Needs 300 Gems."
	cv.add_child(cb)

	# ---- right: recommended guilds
	var rp := UI.panel()
	rp.anchor_left = 0.38
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(10)
	rp.add_child(rv)
	rv.add_child(UI.label("RECOMMENDED GUILDS", 16, UI.GOLD, 3))
	var list := UI.vbox(10)
	var sc := UI.scroll(list)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(sc)
	for g in DB.GUILDS:
		list.add_child(_guild_card(g))
	UI.stagger(list, 0.06)

func _perk(tex: Texture2D, title: String, text: String, col: Color) -> Control:
	var p := UI.styled_panel(Color(col, 0.08), Color(col, 0.35), 10, 1, 8.0)
	var h := UI.hbox(10)
	p.add_child(h)
	var ic := UI.tex_rect(tex, Vector2(40, 40))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(title, 14, col, 2))
	v.add_child(UI.wrap_label(text, 12, UI.TEXT))
	h.add_child(v)
	return p

## Shield emblem in the guild colour with its initial.
func _emblem(col: Color, initial: String) -> Control:
	var e := Control.new()
	e.custom_minimum_size = Vector2(72, 80)
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	e.draw.connect(func():
		var w := 64.0
		var o := Vector2(4, 4)
		var pts := PackedVector2Array([o + Vector2(0, 6), o + Vector2(w * 0.5, 0), o + Vector2(w, 6), o + Vector2(w, 38), o + Vector2(w * 0.5, 72), o + Vector2(0, 38)])
		e.draw_colored_polygon(pts, col.darkened(0.55))
		var inner := PackedVector2Array()
		var c := o + Vector2(w * 0.5, 34)
		for pt in pts:
			inner.append(c + (pt - c) * 0.8)
		e.draw_colored_polygon(inner, col.darkened(0.25))
		var closed := pts.duplicate()
		closed.append(pts[0])
		e.draw_polyline(closed, col.lightened(0.3), 2.5, true)
		e.draw_string(ThemeDB.fallback_font, o + Vector2(0, 46), initial, HORIZONTAL_ALIGNMENT_CENTER, w, 30, Color.WHITE))
	return e

func _guild_card(g: Dictionary) -> Control:
	var col := Color(str(g.get("color", "#ffd479")))
	var glv := int(g["lv"])
	var members := int(g.get("members", 20))
	var p := UI.styled_panel(Color(0.11, 0.08, 0.17, 0.92), Color(col, 0.55), 12, 1, 10.0)
	var h := UI.hbox(14)
	p.add_child(h)
	h.add_child(_emblem(col, str(g["name"]).substr(0, 1)))

	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	var tr := UI.hbox(8)
	tr.add_child(UI.label(g["name"], 19, Color.WHITE, 2))
	var lvp := UI.styled_panel(Color(col, 0.2), col, 8, 1, 6.0)
	lvp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lvp.add_child(UI.label("Lv.%d" % glv, 12, col.lightened(0.3), 1))
	tr.add_child(lvp)
	for t in g.get("tags", []):
		var tp := UI.styled_panel(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.2), 8, 1, 5.0)
		tp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tp.add_child(UI.label(str(t), 10, UI.MUTED, 1))
		tr.add_child(tp)
	v.add_child(tr)
	v.add_child(UI.label(g["desc"], 13, UI.MUTED))

	var stats := UI.hbox(16)
	stats.add_child(_mini_stat("MEMBERS", "%d / %d" % [members, GUILD_CAP], UI.TEXT))
	stats.add_child(_mini_stat("BONUS", "+%d%% ATK & HP" % (glv - 1), UI.GREEN))
	var act := float(g.get("activity", 0.5))
	var av := UI.vbox(2)
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_child(UI.label("ACTIVITY", 10, UI.MUTED, 1))
	var ab := UI.bar(act * 100.0, 100.0, "", 8)
	var fill := UI.style(col, Color.TRANSPARENT, 4, 0, 0)
	ab.add_theme_stylebox_override("fill", fill)
	ab.custom_minimum_size.x = 90
	ab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.add_child(ab)
	stats.add_child(av)
	v.add_child(stats)

	var jb := UI.button("JOIN", func():
		Game.join_guild(g["name"], glv)
		Game.sfx("star_up")
		main.replace("guild"), "GoldButton", Vector2(120, 48))
	jb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(jb)
	return p

func _mini_stat(title: String, value: String, col: Color) -> Control:
	var v := UI.vbox(0)
	v.add_child(UI.label(title, 10, UI.MUTED, 1))
	v.add_child(UI.label(value, 14, col, 2))
	return v

# ---------------------------------------------------------------- guild hall

func _build_hall() -> void:
	var gd: Dictionary = Game.s["guild"]
	var b := body(76)

	# left: guild info
	var lp := UI.panel()
	lp.anchor_right = 0.28
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	var col := UI.GOLD
	for g in DB.GUILDS:
		if g["name"] == gd["joined"]:
			col = Color(str(g.get("color", "#ffd479")))
	var top := UI.hbox(8)
	top.add_child(_emblem(col, str(gd["joined"]).substr(0, 1)))
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm := UI.label(str(gd["joined"]), 18, UI.GOLD, 3)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(nm)
	tv.add_child(UI.label("Lv.%d / %d" % [gd["level"], DB.GUILD_MAX_LV], 14, Color.WHITE, 2))
	top.add_child(tv)
	lv.add_child(top)
	if int(gd["level"]) < DB.GUILD_MAX_LV:
		lv.add_child(UI.bar(gd["exp"], Game.guild_exp_needed(), "GoldBar", 10))
		var er := UI.hbox(4)
		var el := UI.label("%d / %d EXP" % [gd["exp"], Game.guild_exp_needed()], 12, UI.MUTED)
		el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		er.add_child(el)
		er.add_child(UI.label("next: +%d%%" % (int(Game.guild_bonus() * 100) + 1), 12, UI.GREEN))
		lv.add_child(er)
	var bp := UI.styled_panel(Color(UI.GREEN, 0.08), Color(UI.GREEN, 0.35), 10, 1, 8.0)
	var bl := UI.label("Guild buff: +%d%% ATK & HP" % int(Game.guild_bonus() * 100), 14, UI.GREEN, 2)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bp.add_child(bl)
	lv.add_child(bp)

	lv.add_child(UI.label("TODAY", 13, UI.GOLD, 2))
	var checked: bool = int(gd["checkin_day"]) == Game.day_key()
	lv.add_child(_task("Check-in", "+50 coins, +40 EXP", checked, "", func():
		var r := Game.guild_checkin()
		if not r.is_empty():
			main.show_rewards("CHECK-IN", r, func(): main.replace("guild")), "CLAIM"))
	var dn: int = int(gd["donates"]) if int(gd["donate_day"]) == Game.day_key() else 0
	lv.add_child(_task("Donate  %d/3" % dn, "10k Gold: +30 coins each", dn >= 3, "", func():
		var err := Game.guild_donate()
		if err != "":
			main.toast(err, UI.RED)
		else:
			Game.sfx("star_up")
			main.toast("+30 Guild Coins, +60 Guild EXP", UI.GREEN)
			main.replace("guild"), "GIVE"))
	var tries := int(gd["raid_tries"])
	lv.add_child(_task("Raid  %d/3 left" % tries, "Hit Ygg-Naar for coins", tries <= 0, "", Callable(), ""))
	lv.add_child(UI.spacer(false))
	lv.add_child(UI.button("LEAVE GUILD", func():
		main.confirm("Leave %s? Your guild buff will be lost." % gd["joined"], func():
			Game.leave_guild()
			main.replace("guild"), "LEAVE"), "", Vector2(0, 38)))

	# center: raid
	var mp := UI.styled_panel(Color(0.08, 0.02, 0.06, 1.0), Color("#ff5c6c"), 14, 2, 0)
	mp.anchor_left = 0.3
	mp.anchor_right = 0.64
	mp.anchor_bottom = 1.0
	mp.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	b.add_child(mp)
	var rbg := UI.tex_rect(DB.bg("boss"), Vector2.ZERO, true)
	rbg.modulate = Color(0.6, 0.5, 0.55)
	mp.add_child(rbg)
	var rv := UI.vbox(6)
	mp.add_child(UI.margin(rv, 16, 14, 16, 14))
	rv.add_child(UI.label("GUILD RAID", 14, Color("#ff8a9a"), 3))
	rv.add_child(UI.label("Ygg-Naar  Lv.%d" % gd["raid_lv"], 26, Color.WHITE, 6))
	var boss := UI.tex_rect(DB.art("ygg_naar", mini(int(gd["raid_lv"]) - 1, 3)))
	boss.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(boss)
	UI.live(boss, Color(1.0, 0.6, 0.65))
	var mx := DB.raid_max_hp(int(gd["raid_lv"]))
	var hpbar := UI.bar(maxi(0, gd["raid_hp"]), mx, "EnemyHpBar", 16)
	rv.add_child(hpbar)
	rv.add_child(UI.label("HP %s / %s" % [Game.fmt(maxi(0, gd["raid_hp"])), Game.fmt(mx)], 14, Color.WHITE, 4))
	rv.add_child(UI.label("Your best: %s   •   Attempts %d/3" % [Game.fmt(gd["raid_best"]), gd["raid_tries"]], 14, UI.GOLD, 4))
	var ab := UI.button("⚔ ATTACK RAID BOSS", func(): main.go("formation", {"mode": "raid"}), "GoldButton", Vector2(0, 54))
	ab.disabled = int(gd["raid_tries"]) <= 0
	rv.add_child(ab)

	# right: members / shop
	var rp := UI.panel()
	rp.anchor_left = 0.66
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rr := UI.vbox(8)
	rp.add_child(rr)
	var tabs := UI.hbox(6)
	rr.add_child(tabs)
	for t in ["MEMBERS", "SHOP"]:
		var key: String = t
		var tb := UI.button(t, func(): _tab = key; _render_right(), "TabButton", Vector2(0, 40))
		tb.toggle_mode = true
		tb.set_meta("key", key)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tb)
	_right = UI.vbox(6)
	rr.add_child(UI.scroll(_right))
	_render_right()

func _render_right() -> void:
	for tb in find_children("*", "Button", true, false):
		if tb.has_meta("key"):
			tb.button_pressed = tb.get_meta("key") == _tab
	for c in _right.get_children():
		c.queue_free()
	if _tab == "MEMBERS":
		var rank := 1
		for m in Game.guild_members():
			var h := UI.hbox(8)
			h.add_child(UI.label("#%d" % rank, 15, UI.GOLD, 2))
			var fp := UI.styled_panel(Color.BLACK, Color("#6b4a7e"), 6, 1, 1)
			fp.add_child(UI.tex_rect(DB.face(m["hero"]), Vector2(36, 36), true))
			h.add_child(fp)
			var v := UI.vbox(0)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(UI.label("%s  Lv.%d" % [m["name"], m["level"]], 14, UI.GREEN if str(m["name"]).ends_with("(You)") else Color.WHITE))
			v.add_child(UI.label("%s%s • Raid dmg %s" % [m["role"], "" if str(m["name"]).ends_with("(You)") else " [AI]", Game.fmt(m["dmg"])], 12, UI.MUTED))
			h.add_child(v)
			_right.add_child(h)
			rank += 1
	else:
		for item in DB.SHOP:
			if item["cur"] != "guild_coin":
				continue
			var it: Dictionary = item
			var p := UI.panel("CardPanel")
			_right.add_child(p)
			var h2 := UI.hbox(8)
			p.add_child(h2)
			h2.add_child(UI.tex_rect(Game.reward_icon(it["give"].keys()[0]), Vector2(40, 40)))
			var v2 := UI.vbox(0)
			v2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v2.add_child(UI.label(it["name"], 14, Color.WHITE))
			v2.add_child(UI.label("Left today %d/%d" % [int(it["limit"]) - Game.shop_bought(it["id"]), it["limit"]], 11, UI.MUTED))
			h2.add_child(v2)
			var b := UI.button(str(it["price"]), func():
				var err := Game.buy(it)
				if err != "":
					main.toast(err, UI.RED)
				else:
					Game.sfx("star_up")
					main.toast("Purchased %s" % it["name"], UI.GREEN)
				_render_right(), "GoldButton", Vector2(80, 40))
			b.disabled = Game.shop_bought(it["id"]) >= int(it["limit"])
			h2.add_child(b)


## A daily guild task row: tick when done, otherwise an action button (if any).
func _task(title: String, sub: String, done: bool, _unused: String, cb: Callable, btn: String) -> Control:
	var p := UI.styled_panel(Color(0.1, 0.08, 0.16, 0.85), Color(UI.GREEN, 0.4) if done else Color(1, 1, 1, 0.12), 10, 1, 8.0)
	var h := UI.hbox(8)
	p.add_child(h)
	var mark := UI.label("✔" if done else "•", 18, UI.GREEN if done else UI.GOLD, 2)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.custom_minimum_size.x = 18
	h.add_child(mark)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tl := UI.label(title, 14, UI.MUTED if done else Color.WHITE, 2)
	v.add_child(tl)
	var sl := UI.label(sub, 11, UI.MUTED)
	sl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sl.custom_minimum_size.x = 60
	v.add_child(sl)
	h.add_child(v)
	if not done and btn != "":
		var b := UI.button(btn, cb, "GoldButton", Vector2(88, 38))
		b.add_theme_font_size_override("font_size", 13)
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "modulate", Color(1.2, 1.2, 1.2), 0.6)
		tw.tween_property(b, "modulate", Color.WHITE, 0.6)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
	return p
