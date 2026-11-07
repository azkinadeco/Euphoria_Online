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

func _build_lobby() -> void:
	var b := body(76)
	var v := UI.vbox(12)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	v.add_child(UI.label("JOIN A GUILD", 24, UI.GOLD, 4))
	v.add_child(UI.label("Offline guilds with AI members — real guilds arrive with online mode.", 14, Color("#9fd0ff"), 2))
	v.add_child(UI.wrap_label("Guild members share a Raid Boss, earn Guild Coins and every guild level grants +1% ATK & HP to all your heroes.", 15, UI.TEXT))
	for g in DB.GUILDS:
		var gi: Dictionary = g
		var p := UI.panel("CardPanel")
		v.add_child(p)
		var h := UI.hbox(14)
		p.add_child(h)
		h.add_child(UI.tex_rect(DB.icon("icon_guild"), Vector2(56, 56)))
		var gv := UI.vbox(2)
		gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gv.add_child(UI.label("%s   Lv.%d" % [gi["name"], gi["lv"]], 19, Color.WHITE, 2))
		gv.add_child(UI.label(gi["desc"], 14, UI.MUTED))
		h.add_child(gv)
		h.add_child(UI.button("JOIN", func():
			Game.join_guild(gi["name"], int(gi["lv"]))
			main.replace("guild"), "GoldButton", Vector2(120, 48)))
	var cp := UI.panel("CardPanel")
	v.add_child(cp)
	var ch := UI.hbox(12)
	cp.add_child(ch)
	var le := LineEdit.new()
	le.placeholder_text = "New guild name"
	le.max_length = 20
	le.custom_minimum_size = Vector2(0, 46)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(le)
	ch.add_child(UI.button("CREATE (300 Gems)", func():
		var err := Game.create_guild(le.text)
		if err != "":
			main.toast(err, UI.RED)
		else:
			main.replace("guild"), "", Vector2(220, 46)))

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
	lv.add_child(UI.tex_rect(DB.icon("icon_guild"), Vector2(0, 70)))
	var nm := UI.label(str(gd["joined"]), 22, UI.GOLD, 4)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(nm)
	lv.add_child(UI.label("Guild Lv.%d / %d" % [gd["level"], DB.GUILD_MAX_LV], 16, Color.WHITE, 2))
	if int(gd["level"]) < DB.GUILD_MAX_LV:
		lv.add_child(UI.bar(gd["exp"], Game.guild_exp_needed(), "GoldBar", 10))
		lv.add_child(UI.label("%d / %d EXP" % [gd["exp"], Game.guild_exp_needed()], 12, UI.MUTED))
	lv.add_child(UI.label("Buff: +%d%% ATK & HP" % int(Game.guild_bonus() * 100), 15, UI.GREEN, 2))
	var checked: bool = int(gd["checkin_day"]) == Game.day_key()
	var cb := UI.button("CHECKED IN ✔" if checked else "DAILY CHECK-IN", func():
		var r := Game.guild_checkin()
		if not r.is_empty():
			main.show_rewards("CHECK-IN", r, func(): main.replace("guild")), "GoldButton", Vector2(0, 48))
	cb.disabled = checked
	lv.add_child(cb)
	var dn: int = int(gd["donates"]) if int(gd["donate_day"]) == Game.day_key() else 0
	var db := UI.button("DONATE 10,000 Gold (%d/3)" % dn, func():
		var err := Game.guild_donate()
		if err != "":
			main.toast(err, UI.RED)
		else:
			Game.sfx("star_up")
			main.toast("+30 Guild Coins, +60 Guild EXP", UI.GREEN)
			main.replace("guild"), "", Vector2(0, 46))
	db.disabled = dn >= 3
	lv.add_child(db)
	lv.add_child(UI.spacer(false))
	lv.add_child(UI.button("LEAVE GUILD", func():
		main.confirm("Leave %s? Your guild buff will be lost." % gd["joined"], func():
			Game.leave_guild()
			main.replace("guild"), "LEAVE"), "", Vector2(0, 40)))

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
