extends Screen
## Guild: join/create, check-in, donations (guild level = stat buff),
## shared raid boss, members ranking and guild shop.

var _tab := "MEMBERS"
var _right: VBoxContainer

const GuildBaseView = preload("res://game/ui/guild_base_view.gd")
var _view: Control

func build() -> void:
	var hall: bool = params.get("hall", false)
	set_bg(("boss" if hall else "blackmarket") if Game.in_guild() else "asgard", 0.6 if hall or not Game.in_guild() else 0.8)
	header("GUILD HALL" if hall else ("GUILD BASE" if Game.in_guild() else "GUILD"), ["gold", "guild_coin"])
	if Game.in_guild():
		if hall:
			_build_hall()
		else:
			_build_base()
			tutorial("guild_base")
	else:
		_build_lobby()
	tutorial("guild")

# ---------------------------------------------------------------- guild base (isometric hall with members' chibis)

func _guild_color() -> Color:
	for g in DB.GUILDS:
		if g["name"] == Game.s["guild"]["joined"]:
			return Color(str(g.get("color", "#ffd479")))
	return UI.GOLD

func _guild_activity() -> float:
	for g in DB.GUILDS:
		if g["name"] == Game.s["guild"]["joined"]:
			return float(g.get("activity", 0.7))
	return 0.7

## Members online right now (simulated until online mode: a stable pick per hour, guild activity decides how many).
func _online_members() -> Array:
	var hour := int(Game.now() / 3600)
	var act := _guild_activity()
	var out: Array = []
	for m in Game.guild_members():
		if str(m["name"]).ends_with("(You)"):
			continue
		if absi(hash(str(m["name"]) + str(hour))) % 100 < int(act * 100.0):
			out.append(m)
	return out.slice(0, 10)

func _build_base() -> void:
	var gd: Dictionary = Game.s["guild"]
	var b := body(76, 8)
	_view = GuildBaseView.new()
	_view.guild_color = _guild_color()
	_view.guild_initial = str(gd["joined"]).substr(0, 1)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(_view)
	var online := _online_members()
	_view.set_members.call_deferred(online, str(Game.s["lobby_hero"]), str(Game.s["player"]["name"]))
	_view.station.connect(_on_station)
	_view.member.connect(_member_popup)
	_view.badge.call_deferred("board", int(gd["checkin_day"]) != Game.day_key())
	_view.badge.call_deferred("raid", int(gd["raid_tries"]) > 0)
	# HUD: guild card (top left)
	var info := UI.styled_panel(Color(0.06, 0.03, 0.1, 0.86), Color(_guild_color(), 0.7), 12, 1, 10)
	# bottom left: the empty corner under the floor (top left covers the notice board)
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	info.offset_left = 14
	info.offset_bottom = -10
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(info)
	var iv := UI.vbox(4)
	info.add_child(iv)
	var top := UI.hbox(8)
	top.add_child(_emblem(_guild_color(), str(gd["joined"]).substr(0, 1)))
	var tv := UI.vbox(0)
	tv.add_child(UI.label(str(gd["joined"]), 17, UI.GOLD, 3))
	tv.add_child(UI.label("Lv.%d   •   buff +%d%% ATK & HP" % [int(gd["level"]), int(Game.guild_bonus() * 100)], 13, UI.GREEN, 2))
	top.add_child(tv)
	iv.add_child(top)
	iv.add_child(UI.label("● ONLINE  %d / %d   (AI members until online mode)" % [online.size() + 1, Game.guild_members().size()], 12, Color("#9fe3ff"), 2))
	iv.add_child(UI.label("Tap the floor to walk  •  tap a sign to use it", 12, UI.MUTED, 2))
	# HUD: buttons (bottom right)
	var row := UI.hbox(8)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_right = -14
	row.offset_bottom = -10
	b.add_child(row)
	row.add_child(UI.button("MEMBERS", func(): main.go("guild", {"hall": true, "tab": "MEMBERS"}), "", Vector2(140, 46)))
	row.add_child(UI.button("GUILD HALL", func(): main.go("guild", {"hall": true}), "GoldButton", Vector2(170, 46)))

func _on_station(key: String) -> void:
	match key:
		"raid": _raid_popup()
		"board": _board_popup()
		"shop": main.go("guild", {"hall": true, "tab": "SHOP"})
		"tech": main.go("guild", {"hall": true, "tab": "TECH"})
		"members": main.go("guild", {"hall": true, "tab": "MEMBERS"})

func _raid_popup() -> void:
	var gd: Dictionary = Game.s["guild"]
	var v: VBoxContainer = main.popup("GUILD RAID", 560)
	var row := UI.hbox(14)
	v.add_child(row)
	var boss := UI.tex_rect(DB.art("ygg_naar", mini(int(gd["raid_lv"]) - 1, 3)), Vector2(150, 170))
	row.add_child(boss)
	var tv := UI.vbox(6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tv)
	tv.add_child(UI.label("Ygg-Naar  Lv.%d" % int(gd["raid_lv"]), 22, Color.WHITE, 4))
	var mx := DB.raid_max_hp(int(gd["raid_lv"]))
	tv.add_child(UI.bar(maxi(0, int(gd["raid_hp"])), mx, "EnemyHpBar", 14))
	tv.add_child(UI.label("HP %s / %s" % [Game.fmt(maxi(0, int(gd["raid_hp"]))), Game.fmt(mx)], 14, Color.WHITE, 2))
	tv.add_child(UI.label("Your best: %s   •   Attempts %d/3" % [Game.fmt(int(gd["raid_best"])), int(gd["raid_tries"])], 14, UI.GOLD, 2))
	tv.add_child(UI.wrap_label("Every guildmate's damage counts. Defeat it to raise its level and the rewards.", 13, UI.MUTED))
	var br := UI.hbox(10)
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(br)
	var ab := UI.button("⚔ ATTACK", func():
		main.close_popup(v)
		main.go("formation", {"mode": "raid"}), "GoldButton", Vector2(200, 48))
	ab.disabled = int(gd["raid_tries"]) <= 0
	br.add_child(ab)
	br.add_child(UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(130, 48)))

func _board_popup() -> void:
	var gd: Dictionary = Game.s["guild"]
	var v: VBoxContainer = main.popup("NOTICE BOARD", 560)
	v.add_child(UI.wrap_label("Daily guild tasks. Check-in and donations raise the guild level (+1% ATK & HP for everyone per level).", 13, UI.MUTED))
	var checked: bool = int(gd["checkin_day"]) == Game.day_key()
	v.add_child(_task("Check-in", "+50 coins, +40 EXP", checked, "", func():
		var r := Game.guild_checkin()
		main.close_popup(v)
		if not r.is_empty():
			main.show_rewards("CHECK-IN", r, func(): main.replace("guild")), "CLAIM"))
	var dn: int = int(gd["donates"]) if int(gd["donate_day"]) == Game.day_key() else 0
	v.add_child(_task("Donate  %d/3" % dn, "10k Gold: +30 coins each", dn >= 3, "", func():
		var err := Game.guild_donate()
		if err != "":
			main.toast(err, UI.RED)
		else:
			Game.sfx("star_up")
			main.toast("+30 Guild Coins, +60 Guild EXP", UI.GREEN)
		main.close_popup(v)
		_board_popup(), "GIVE"))
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(140, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

func _member_popup(m: Dictionary) -> void:
	var you := bool(m.get("you", false))
	var v: VBoxContainer = main.popup("COMMANDER", 520)
	var row := UI.hbox(14)
	v.add_child(row)
	row.add_child(UI.avatar(str(m["hero"]), 92, _guild_color(), 2))
	var tv := UI.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tv)
	tv.add_child(UI.label(str(m["name"]).replace(" (You)", "") + ("  (You)" if you else "  [AI]"), 20, UI.GOLD if you else Color.WHITE, 3))
	if you:
		tv.add_child(UI.label("Lv.%d   •   partner %s" % [int(Game.s["player"]["level"]), DB.name_of(str(m["hero"]))], 14, UI.TEXT, 2))
		tv.add_child(UI.wrap_label("Your main hero is the Lobby partner. Change it in Hero Detail > LOBBY PARTNER.", 13, UI.MUTED))
	else:
		tv.add_child(UI.label("Lv.%d   •   %s   •   main hero %s" % [int(m["level"]), str(m["role"]), DB.name_of(str(m["hero"]))], 14, UI.TEXT, 2))
		tv.add_child(UI.label("Raid damage %s" % Game.fmt(int(m["dmg"])), 14, Color("#ff8a9a"), 2))
	var br := UI.hbox(10)
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(br)
	if not you:
		br.add_child(UI.button("WAVE", func():
			main.close_popup(v)
			Game.sfx("ui_click")
			main.toast("You waved at %s!" % str(m["name"]), Color("#ff8fb8")), "GoldButton", Vector2(150, 46)))
	br.add_child(UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(130, 46)))

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
	lv.add_child(_perk(Game.reward_icon("guild_coin"), "Guild Coins", "Earn coins from check-ins and raids. Spend them in the Guild Shop and on Guild Tech.", UI.GOLD))
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
	_tab = str(params.get("tab", _tab))
	for t in ["MEMBERS", "SHOP", "TECH"]:
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
			h.add_child(UI.avatar(str(m["hero"]), 38, Color("#8a6aae"), 1))   # member avatar (full-body sprite)
			var v := UI.vbox(0)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(UI.label("%s  Lv.%d" % [m["name"], m["level"]], 14, UI.GREEN if str(m["name"]).ends_with("(You)") else Color.WHITE))
			v.add_child(UI.label("%s%s • Raid dmg %s" % [m["role"], "" if str(m["name"]).ends_with("(You)") else " [AI]", Game.fmt(m["dmg"])], 12, UI.MUTED))
			h.add_child(v)
			_right.add_child(h)
			rank += 1
	elif _tab == "TECH":
		_right.add_child(UI.wrap_label("Permanent bonuses for every hero. A tech can't be higher than your Guild level (Lv.%d). Bonuses work while you are in a guild." % int(Game.s["guild"]["level"]), 12, UI.MUTED))
		for t in DB.GUILD_TECH:
			var tech: Dictionary = t
			var tid: String = tech["id"]
			var lv := Game.guild_tech_lv(tid)
			var col := Color(str(tech["color"]))
			var block := Game.guild_tech_block(tid)
			var p := UI.styled_panel(Color(0.08, 0.05, 0.14, 0.92), Color(col, 0.6), 10, 1, 8)
			_right.add_child(p)
			var h := UI.hbox(8)
			p.add_child(h)
			var ic := UI.tex_rect(DB.icon(str(tech["icon"])), Vector2(38, 38))
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(ic)
			var v := UI.vbox(2)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(v)
			v.add_child(UI.label("%s  Lv.%d" % [tech["name"], lv], 14, Color.WHITE, 2))
			var now_pct := float(tech["per"]) * lv * 100.0
			var nxt := "" if lv >= DB.GUILD_TECH_MAX else "  →  +%.1f%%" % (float(tech["per"]) * (lv + 1) * 100.0)
			v.add_child(UI.label("%s +%.1f%%%s" % [str(tech["stat"]).to_upper(), now_pct, nxt], 12, col.lightened(0.2), 2))
			var pb := UI.bar(lv, DB.GUILD_TECH_MAX, "", 5)
			pb.add_theme_stylebox_override("fill", UI.style(col, Color.TRANSPARENT, 3, 0, 0))
			v.add_child(pb)
			if lv >= DB.GUILD_TECH_MAX:
				var ml := UI.label("MAX", 14, UI.GOLD, 2)
				ml.custom_minimum_size.x = 80
				ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ml.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h.add_child(ml)
			else:
				var ub := UI.button(str(DB.guild_tech_cost(lv)), func():
					var err := Game.upgrade_guild_tech(tid)
					if err != "":
						main.toast(err, UI.RED)
					else:
						Game.sfx("star_up")
						main.toast("%s is now Lv.%d" % [tech["name"], Game.guild_tech_lv(tid)], UI.GREEN)
					_render_right(), "GoldButton" if block == "" else "", Vector2(80, 40))
				ub.icon = DB.icon("icon_guild")
				ub.add_theme_constant_override("icon_max_width", 20)
				ub.set_meta("tech", tid)
				ub.tooltip_text = block if block != "" else "Upgrade"
				ub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				if block != "":
					ub.modulate = Color(0.75, 0.75, 0.8)
				h.add_child(ub)
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
