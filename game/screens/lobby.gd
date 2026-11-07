extends Screen
## Home lobby: interactive main hero (Sakura Oath style), banners, story & AFK.

var _hero_art: TextureRect
var _bubble: PanelContainer
var _bubble_label: Label
var _afk_label: Label
var _lv_label: Label
var _exp_bar: ProgressBar
var _power_label: Label
var _badges: Dictionary = {}
var _energy_timer: Label
var _t := 0.0
var _holder: Control
var _bg: TextureRect
var _fx: SkillFX
var _parallax := Vector2.ZERO
var _idle_t := 8.0
var _busy := false
var _route_btn: Dictionary = {}
var _ring: Control
var _ring_val := 0.0
var _carousel: PanelContainer
var _slides: Array = []
var _slide_i := 0
var _slide_t := 0.0
var _dots: HBoxContainer
var _pointer: Control
var _pointer_target: Control

func build() -> void:
	set_bg(str(Game.s.get("lobby_bg", "lobby")), 0.18)
	ambient(Color(0.85, 0.7, 1.0), 40)
	var fest := Game.festival()
	if not fest.is_empty():
		var ffx := FestivalFX.new(str(fest["fx"]), Color(str(fest["color"])), 26)
		add_child(ffx)
		move_child(ffx, mini(3, get_child_count() - 1))
	var hid: String = Game.s["lobby_hero"]

	_bg = get_child(0) as TextureRect
	_bg.resized.connect(func(): _bg.pivot_offset = _bg.size * 0.5)
	_bg.scale = Vector2(1.05, 1.05)
	_time_of_day()
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	# --- main hero art
	var lskin := int(Game.hero(hid).get("skin", 0))
	var lpose := DB.lobby_art(hid) if lskin == 0 else null
	_hero_art = UI.tex_rect(lpose if lpose else DB.art(hid, lskin))
	_hero_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hero_art.anchor_left = 0.08
	_hero_art.anchor_right = 0.56
	_hero_art.anchor_top = 0.06
	_hero_art.anchor_bottom = 1.0
	_hero_art.offset_bottom = -70
	_holder.add_child(_hero_art)
	UI.live(_hero_art, DB.theme_color(hid).lightened(0.5))
	if params.has("swipe"):
		# arrived by swiping: slide in from the side the finger came from
		var sdir := float(params["swipe"])
		_hero_art.modulate.a = 0.0
		(func():
			var x0 := _hero_art.position.x
			_hero_art.position.x = x0 + sdir * 160.0
			var st := _hero_art.create_tween().set_parallel(true)
			st.tween_property(_hero_art, "position:x", x0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			st.tween_property(_hero_art, "modulate:a", 1.0, 0.25)).call_deferred()
		params.erase("swipe")
	if lskin > 0 and lskin == DB.special_index(hid):
		# special skin showcase: golden sparkles around the secretary
		var sp := FestivalFX.new("firefly", Color("#ffd479"), 24)
		sp.anchor_left = 0.08
		sp.anchor_right = 0.56
		sp.anchor_bottom = 1.0
		sp.offset_bottom = -70
		_holder.add_child(sp)
	_fx = SkillFX.new()
	_fx.z_index = 5
	add_child(_fx)
	_hero_art.resized.connect(func(): _hero_art.pivot_offset = Vector2(_hero_art.size.x * 0.5, _hero_art.size.y))
	var tw := _hero_art.create_tween().set_loops()
	tw.tween_property(_hero_art, "scale", Vector2(1.006, 1.016), 1.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_hero_art, "scale", Vector2.ONE, 1.7).set_trans(Tween.TRANS_SINE)
	var tap := Button.new()
	tap.theme_type_variation = "FlatButton"
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.anchor_left = 0.2
	tap.anchor_right = 0.46
	tap.anchor_top = 0.12
	tap.anchor_bottom = 0.7
	tap.focus_mode = Control.FOCUS_NONE
	tap.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tap.gui_input.connect(func(e): _gesture(e, tap))
	# hero action row: all secretary actions in one aligned strip
	# compact pills, drawn ABOVE the touch area so they are always clickable
	var acts := UI.hbox(5)
	acts.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	acts.anchor_left = 0.08
	acts.anchor_right = 0.56
	acts.offset_top = -196
	acts.offset_bottom = -168
	acts.alignment = BoxContainer.ALIGNMENT_CENTER
	acts.modulate.a = 0.85
	var tk := _pill("♥ TALK", func(): main.talk(Game.s["lobby_hero"]), Color("#ff8fb8"))
	var ob := _pill("OUTFIT", _next_outfit, Color.WHITE)
	var sc := _pill("SCENE", _pick_scene, Color.WHITE)
	var fb := _pill("FORTUNE" + (" ✦" if Game.fortune_ready() else ""), _open_fortune, UI.GOLD if Game.fortune_ready() else Color.WHITE)
	for btn in [tk, ob, sc, fb]:
		acts.add_child(btn)
	if Game.secretary_ready() and not params.get("intro", false):
		_add_moment_heart()
	add_child(tap)
	add_child(acts)
	# tamed Companion sits beside the secretary (tap = line + daily head-pat)
	if Game.companion() != "":
		var cam := CompanionCameo.new(Game.companion(), true)
		cam.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		cam.anchor_left = 0.43
		cam.anchor_right = 0.43
		cam.offset_left = 0
		cam.offset_right = 120
		cam.offset_top = -360
		cam.offset_bottom = -206
		cam.said.connect(func(txt: String): _say(txt, Game.companion()))
		add_child(cam)

	# speech bubble
	_bubble = UI.styled_panel(Color(1, 1, 1, 0.94), DB.theme_color(hid), 18, 3, 14)
	_bubble.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_bubble.anchor_left = 0.34
	_bubble.anchor_top = 0.2
	_bubble.anchor_right = 0.34
	_bubble.offset_right = 300
	_bubble.custom_minimum_size = Vector2(300, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_label = UI.wrap_label("", 16, Color("#2a1a3a"))
	_bubble.add_child(_bubble_label)
	_bubble.visible = false
	add_child(_bubble)

	_build_top_bar()
	_build_left_menu()
	_build_right_cards()
	_build_bottom_nav()
	_build_goal()
	move_child(_bubble, -1)
	refresh()
	if not params.get("intro", false):
		var hid0: String = Game.s["lobby_hero"]
		get_tree().create_timer(0.4).timeout.connect(func():
			if is_inside_tree():
				_say(Game.voice(hid0, "greet")))

func _build_top_bar() -> void:
	var hid: String = Game.s["lobby_hero"]
	var p := UI.styled_panel(Color(0.05, 0.03, 0.1, 0.82), UI.GOLD_DARK, 14, 2, 10)
	p.position = Vector2(14, 10)
	p.custom_minimum_size = Vector2(330, 0)
	add_child(p)
	var h := UI.hbox(10)
	p.add_child(h)
	var av := UI.styled_panel(Color.BLACK, UI.GOLD, 32, 2, 2)
	av.custom_minimum_size = Vector2(64, 64)
	av.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	av.add_child(UI.tex_rect(DB.face(Game.avatar_id()), Vector2(60, 60), true))
	av.mouse_filter = Control.MOUSE_FILTER_STOP
	av.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	av.tooltip_text = "Commander Profile"
	av.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			Game.sfx("ui_click")
			_open_profile())
	h.add_child(av)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nm := UI.hbox(8)
	nm.add_child(UI.label(str(Game.s["player"]["name"]), 19, Color.WHITE, 3))
	_lv_label = UI.label("", 16, UI.GOLD, 3)
	nm.add_child(_lv_label)
	v.add_child(nm)
	v.add_child(UI.label(Game.title_name(), 12, Color("#ff9ad5"), 3))
	_exp_bar = UI.bar(0, 1, "GoldBar", 8)
	v.add_child(_exp_bar)
	_power_label = UI.label("", 15, Color("#ffb86b"), 3)
	v.add_child(_power_label)
	# daily progress ring (tap = Missions)
	_ring = Control.new()
	_ring.custom_minimum_size = Vector2(62, 62)
	_ring.mouse_filter = Control.MOUSE_FILTER_STOP
	_ring.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ring.tooltip_text = "Today's board"
	_ring.draw.connect(_draw_ring)
	_ring.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			Game.sfx("ui_click")
			main.show_daily_board())
	h.add_child(_ring)

	var chips := UI.hbox(8)
	chips.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	chips.offset_left = -560
	chips.offset_right = -14
	chips.offset_top = 14
	chips.alignment = BoxContainer.ALIGNMENT_END
	chips.add_child(_chip("gold"))
	chips.add_child(_chip("gems"))
	chips.add_child(_chip("energy"))
	add_child(chips)
	_energy_timer = UI.label("", 12, UI.MUTED, 3)
	_energy_timer.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_energy_timer.offset_left = -170
	_energy_timer.offset_right = -20
	_energy_timer.offset_top = 60
	_energy_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_energy_timer)

func _build_left_menu() -> void:
	var v := UI.vbox(0)
	v.position = Vector2(14, 120)
	add_child(v)
	var avail := get_viewport_rect().size.y - 120 - 96
	var icon_sz := clampf(avail / 5.6 - 24.0, 24.0, 46.0)
	var menu := [["icon_mail", "Mail", "mail"], ["icon_quest", "Missions", "quests"], ["icon_messenger", "Chats", "messenger"], ["icon_ticket", "Login", "login"], ["icon_codex", "Notices", "news"]]
	for e in menu:
		var route: String = e[2]
		var b := UI.icon_button(DB.icon(e[0]), e[1], func():
			if route == "login":
				main.show_login_calendar()
			elif route == "news":
				main.show_news()
				refresh()
			else:
				main.go(route), icon_sz)
		v.add_child(b)
		if not Game.feature_unlocked(route):
			b.modulate = Color(0.45, 0.45, 0.5)
			b.tooltip_text = "Unlocks at Lv.%d" % Game.feature_req(route)
		_badges[route] = b
		_route_btn[route] = b

func _build_right_cards() -> void:
	var col := UI.vbox(12)
	col.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	col.offset_left = -470
	col.offset_right = -16
	col.offset_top = 92
	col.offset_bottom = -100
	add_child(col)

	# Rotating banner carousel (gacha banners, event, pass, black market)
	_carousel = UI.styled_panel(Color(0.12, 0.05, 0.2, 1.0), DB.RARITY_COLOR["SSR"], 14, 2, 0)
	_carousel.custom_minimum_size = Vector2(0, 130)
	_carousel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_carousel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	col.add_child(_carousel)
	_slides = []
	var shown := 0
	for b in DB.BANNERS:
		if b["featured"] == "" or (shown >= 3 and not b.has("img")):
			continue
		shown += 1
		var sl := {"tag": "SPECIAL EVENT" if b.has("img") else "LIMITED BANNER", "tag_col": Color("#ffb86b") if b.has("img") else Color("#ff9ad5"),
			"title": DB.name_of(b["featured"]).to_upper(), "sub": DB.title_of(b["featured"]),
			"bg": b["bg"], "art": b["featured"], "btn": "SUMMON", "route": "gacha", "params": {"banner": DB.BANNERS.find(b)}}
		if b.has("img"):
			sl["img"] = b["img"]
		_slides.append(sl)
	if Game.feature_unlocked("event"):
		_slides.append({"tag": "LIMITED EVENT", "tag_col": Color("#9fe3ff"), "title": DB.EVENT["name"].to_upper(), "sub": "Earn Event Tokens • %s shards" % DB.name_of(DB.EVENT["featured"]),
		"bg": DB.EVENT["bg"], "art": DB.EVENT["featured"], "btn": "JOIN", "route": "event", "params": {}})
	var fest := Game.festival()
	if not fest.is_empty() and Game.feature_unlocked("festival"):
		_slides.append({"tag": "SEASONAL FESTIVAL", "tag_col": Color(str(fest["color"])), "title": str(fest["name"]).to_upper(), "sub": "Lantern Charms • %s & %s" % [DB.name_of(fest["featured"][0]).split(" ")[0], DB.name_of(fest["featured"][1]).split(" ")[0]],
			"bg": fest["bg"], "art": fest["featured"][0], "btn": "VISIT", "route": "festival", "params": {}})
	_slides.append({"tag": "WARDROBE", "tag_col": Color("#ffd479"), "title": "SPECIAL SKINS", "sub": "%d exclusive outfits • +10%% ATK & HP while worn" % DB.SPECIAL_SKINS.size(),
		"bg": "blackmarket", "art": "ninger", "img": ["res://art/characters/heroes/ninger/char/ninger_char_special.png"], "btn": "WARDROBE", "route": "wardrobe", "params": {}})
	if Game.feature_unlocked("pass"):
		_slides.append({"tag": "SEASON PASS", "tag_col": Color("#c77dff"), "title": "PASS Lv.%d / %d" % [Game.pass_level(), DB.PASS_LEVELS], "sub": "Free + Premium rewards • Oath Ring at Lv.30",
		"bg": "galaxy", "art": "micca", "btn": "OPEN", "route": "pass", "params": {}})
	_slides.append({"tag": "BLACK MARKET", "tag_col": UI.GOLD, "title": "DAILY DEALS", "sub": "Rare goods up to 50% off • Lulu (Night Shift)",
		"bg": "hell", "npc": "res://art/npc/shopkeeper_2.png", "btn": "SHOP", "route": "shop", "params": {"tab": "market"}})
	_dots = UI.hbox(6)
	_show_slide(0)

	# Story card
	var sidx := Game.story_progress()
	var st := DB.stage(sidx)
	var sp := UI.styled_panel(Color(0.05, 0.04, 0.1, 1.0), Color("#6f8cff"), 14, 2, 0)
	sp.custom_minimum_size = Vector2(0, 96)
	sp.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	col.add_child(sp)
	var sbg := UI.tex_rect(DB.bg(st["bg"]), Vector2.ZERO, true)
	sbg.modulate = Color(1, 1, 1, 0.5)
	sp.add_child(sbg)
	var sh := UI.hbox(12)
	sp.add_child(UI.margin(sh, 16, 10, 16, 10))
	sh.add_child(UI.tex_rect(DB.icon("icon_story"), Vector2(64, 64)))
	var sv := UI.vbox(2)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sv)
	sv.add_child(UI.label("STORY • CHAPTER %d" % (int(st["chapter"]) + 1), 13, Color("#9fb4ff"), 3))
	sv.add_child(UI.label("Stage %s" % st["id"], 26, Color.WHITE, 5))
	sv.add_child(UI.label(DB.CHAPTERS[st["chapter"]]["name"], 14, UI.GOLD, 3))
	var go_b := UI.button("ENTER ▶", func(): main.go("story"), "GoldButton", Vector2(120, 48))
	go_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sh.add_child(go_b)

	# AFK card
	var ap := UI.styled_panel(Color(0.05, 0.04, 0.1, 0.9), Color("#6be0a0"), 14, 2, 12)
	col.add_child(ap)
	var ah := UI.hbox(12)
	ap.add_child(ah)
	ah.add_child(UI.tex_rect(DB.icon("icon_afk"), Vector2(56, 56)))
	var av := UI.vbox(0)
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ah.add_child(av)
	av.add_child(UI.label("AFK REWARDS", 14, Color("#6be0a0"), 3))
	_afk_label = UI.label("", 15, Color.WHITE, 3)
	av.add_child(_afk_label)
	var claim := UI.button("CLAIM", _claim_afk, "", Vector2(110, 44))
	_route_btn[""] = claim
	claim.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ah.add_child(claim)

func _build_bottom_nav() -> void:
	var bar := PanelContainer.new()
	var nav_sb := UI.tex_box("navbar.png", 0, 6, 6, UI.style(Color(0.04, 0.02, 0.08, 0.9), UI.GOLD_DARK, 0, 0, 6))
	if nav_sb is StyleBoxTexture:
		(nav_sb as StyleBoxTexture).content_margin_top = 14
	bar.add_theme_stylebox_override("panel", nav_sb)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -100
	add_child(bar)
	var h := UI.hbox(0)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(h)
	for e in [["icon_codex", "Heroes", "heroes"], ["icon_formation", "Formation", "formation"], ["icon_story", "Story", "story"],
			["icon_gacha", "Summon", "gacha"], ["icon_settings", "Menu", "menu"]]:
		var route: String = e[2]
		var b := UI.icon_button(DB.icon(e[0]), e[1], func():
			if route == "menu":
				_open_menu()
			else:
				main.go(route), 52)
		b.custom_minimum_size = Vector2(150, 80)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(b)
		if route == "story" and ResourceLoader.exists("res://art/ui/medallion.png"):
			# raised glowing medallion behind the main action
			var md := TextureRect.new()
			md.texture = load("res://art/ui/medallion.png")
			md.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			md.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			md.mouse_filter = Control.MOUSE_FILTER_IGNORE
			md.show_behind_parent = true
			md.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			md.offset_left = -58
			md.offset_right = 58
			md.offset_top = -40
			md.offset_bottom = 76
			b.add_child(md)
			var pulse := md.create_tween().set_loops()
			pulse.tween_property(md, "modulate", Color(1.15, 1.1, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
			pulse.tween_property(md, "modulate", Color.WHITE, 1.2).set_trans(Tween.TRANS_SINE)
		_route_btn[route] = b
		_badges[route] = b

## Grid of secondary features, with lock levels and badges.
func _open_menu() -> void:
	var v: VBoxContainer = main.popup("MENU", 1060)
	var body := UI.vbox(10)
	var sc := UI.scroll(body)
	sc.custom_minimum_size = Vector2(0, minf(520.0, get_viewport_rect().size.y - 190.0))
	v.add_child(sc)
	var info := {}
	for f in DB.MENU_FEATURES:
		info[f[0]] = f
	for sec in DB.MENU_SECTIONS:
		var head := UI.hbox(8)
		var bar := ColorRect.new()
		bar.color = UI.GOLD
		bar.custom_minimum_size = Vector2(4, 22)
		head.add_child(bar)
		head.add_child(UI.label(str(sec[0]), 16, UI.GOLD, 3))
		body.add_child(head)
		var g := GridContainer.new()
		g.columns = 6
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 10)
		body.add_child(g)
		for route in sec[1]:
			if info.has(route):
				g.add_child(_menu_tile(info[route], v))
	var c := UI.button("CLOSE", func(): main.close_popup(v), "", Vector2(160, 44))
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)

func _menu_tile(f: Array, v: Control) -> Button:
	var route: String = f[0]
	var open := Game.feature_unlocked(route)
	var b := Button.new()
	b.theme_type_variation = "TabButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(158, 96)
	var vb := UI.vbox(2)
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var ic := UI.tex_rect(DB.icon(f[1]), Vector2(0, 46))
	vb.add_child(ic)
	var l := UI.label(f[2], 14, Color.WHITE if open else UI.MUTED, 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	if not open:
		ic.modulate = Color(0.3, 0.3, 0.35)
		var lk := UI.label("Lv.%d" % Game.feature_req(route), 11, UI.MUTED, 2)
		lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lk)
	b.pressed.connect(func():
		Game.sfx("ui_click")
		if open:
			main.close_popup(v)
		main.go(route))
	UI.hover_fx(b, 1.05)
	var n := Game.feature_badge(route)
	if n > 0:
		UI.add_badge(b, n)
	return b

var _goal_box: PanelContainer
var _goal_label: Label
var _goal_tag: Label
var _goal_go: Button

func _build_goal() -> void:
	_goal_box = UI.styled_panel(Color(0.05, 0.03, 0.1, 0.88), UI.GREEN, 20, 2, 10)
	_goal_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_goal_box.anchor_left = 0.12
	_goal_box.anchor_right = 0.12
	_goal_box.offset_top = -150
	_goal_box.offset_bottom = -104
	_goal_box.offset_right = 520
	add_child(_goal_box)
	var h := UI.hbox(10)
	_goal_box.add_child(h)
	_goal_tag = UI.label("NEXT ▶", 14, UI.GREEN, 3)
	h.add_child(_goal_tag)
	_goal_label = UI.label("", 15, Color.WHITE, 3)
	_goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_goal_label.clip_text = true
	h.add_child(_goal_label)
	_goal_go = UI.button("GO", func():
		var g := Game.next_goal()
		if g.get("ready", false):
			_claim_step()
		elif str(g.get("route", "")) == "":
			_claim_afk()
		else:
			main.go(g["route"], g.get("params", {})), "GoldButton", Vector2(64, 32))
	_goal_go.add_theme_font_size_override("font_size", 14)
	h.add_child(_goal_go)
	var tw := _goal_box.create_tween().set_loops()
	tw.tween_property(_goal_box, "modulate", Color(1.15, 1.15, 1.15), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_goal_box, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)

func refresh() -> void:
	super.refresh()
	if is_instance_valid(_goal_label):
		var g := Game.next_goal()
		_goal_label.text = str(g["text"])
		_goal_tag.text = str(g.get("tag", "NEXT")) + " ▶"
		_goal_go.text = "CLAIM" if g.get("ready", false) else "GO"
	_update_pointer()
	var p: Dictionary = Game.s["player"]
	_lv_label.text = "Lv.%d" % int(p["level"])
	_exp_bar.max_value = Game.player_exp_needed()
	_exp_bar.value = int(p["exp"])
	_power_label.text = "⚔ Team Power %s" % Game.fmt(Game.team_power())
	if is_instance_valid(_ring):
		var d := _daily_done()
		var target := float(d[0]) / float(maxi(1, d[1]))
		var rt := _ring.create_tween()
		rt.tween_method(func(x: float): _ring_val = x; _ring.queue_redraw(), _ring_val, target, 0.8).set_trans(Tween.TRANS_CUBIC)
	for r in ["mail", "quests", "messenger", "login", "event", "heroes", "news", "festival"]:
		_set_badge(r, Game.feature_badge(r))
	# MENU shows how many features have something to do (not the sum of everything)
	var menu_n := 0
	for f in DB.MENU_FEATURES:
		if Game.feature_badge(f[0]) > 0:
			menu_n += 1
	_set_badge("menu", menu_n)
	_update_afk()

func _set_badge(route: String, n: int) -> void:
	var b: Control = _badges.get(route)
	if b == null:
		return
	for c in b.get_children():
		if c is Panel:
			c.queue_free()
	if n > 0:
		UI.add_badge(b, n)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := get_viewport_rect().size * 0.5
		_parallax = (event.position - c) / c

func _process(delta: float) -> void:
	if is_instance_valid(_pointer) and is_instance_valid(_pointer_target):
		_place_pointer()
	# parallax: hero drifts with the pointer, background moves the other way
	if is_instance_valid(_holder):
		_holder.position = _holder.position.lerp(_parallax * Vector2(14, 8), minf(1.0, delta * 4.0))
		_bg.position = _bg.position.lerp(-_parallax * Vector2(10, 6), minf(1.0, delta * 4.0))
	if not _slides.is_empty():
		_slide_t += delta
		if _slide_t > 5.0:
			_show_slide(_slide_i + 1)
	_idle_t -= delta
	if _idle_t <= 0.0:
		_idle_t = randf_range(7.0, 12.0)
		_idle_action()
	_t += delta
	if _t >= 1.0:
		_t = 0.0
		_update_afk()
		var nxt := Game.energy_next_in()
		_energy_timer.text = "" if nxt == 0 else "+1 energy in %d:%02d" % [nxt / 60, nxt % 60]

func _update_afk() -> void:
	var a := Game.afk_pending()
	var secs: int = a["secs"]
	_afk_label.text = "%02d:%02d:%02d  •  %s Gold  •  %s EXP" % [secs / 3600, (secs / 60) % 60, secs % 60, Game.fmt(a["gold"]), Game.fmt(a["hero_exp"])]

func _claim_step() -> void:
	var r := Game.claim_first_step()
	if r.is_empty():
		return
	Game.sfx("star_up")
	var finished := Game.first_step().is_empty()
	main.show_rewards("FIRST STEPS COMPLETE!" if finished else "STEP COMPLETE", r, refresh)

func _claim_afk() -> void:
	var r := Game.claim_afk()
	if r.is_empty():
		main.toast("Rewards are still accumulating. Come back in a minute!")
		return
	main.show_rewards("AFK REWARDS", r)

## Tutorial pointer for new players: bounces over the button the guide suggests.
func _update_pointer() -> void:
	if int(Game.s["player"]["level"]) >= 8:
		if is_instance_valid(_pointer):
			_pointer.queue_free()
		return
	var g := Game.next_goal()
	var route := str(g.get("route", ""))
	_pointer_target = _goal_go if g.get("ready", false) else _route_btn.get(route)
	if _pointer_target == null and route == "hero_detail":
		_pointer_target = _route_btn.get("heroes")
	if _pointer_target == null and route != "":
		_pointer_target = _route_btn.get("menu")
	if not is_instance_valid(_pointer):
		_pointer = Control.new()
		_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pointer.z_index = 0
		add_child(_pointer)
		var ring := Panel.new()
		ring.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, UI.GOLD, 40, 3, 0))
		ring.size = Vector2(80, 80)
		ring.position = Vector2(-40, -40)
		ring.pivot_offset = Vector2(40, 40)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pointer.add_child(ring)
		var rt := ring.create_tween().set_loops().set_parallel(true)
		rt.tween_property(ring, "scale", Vector2(1.35, 1.35), 0.9).from(Vector2(0.7, 0.7))
		rt.tween_property(ring, "modulate:a", 0.0, 0.9).from(1.0)
		var arrow := UI.label("▼", 40, UI.GOLD, 8)
		arrow.size = Vector2(60, 50)
		arrow.position = Vector2(-30, -95)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pointer.add_child(arrow)
		var at := arrow.create_tween().set_loops()
		at.tween_property(arrow, "position:y", -80.0, 0.35).set_trans(Tween.TRANS_SINE)
		at.tween_property(arrow, "position:y", -95.0, 0.35).set_trans(Tween.TRANS_SINE)
	_pointer.visible = is_instance_valid(_pointer_target) and _pointer_target.is_visible_in_tree()
	if _pointer.visible:
		_place_pointer.call_deferred()

func _place_pointer() -> void:
	if is_instance_valid(_pointer) and is_instance_valid(_pointer_target):
		var r := _pointer_target.get_global_rect()
		_pointer.visible = r.size.x > 4.0
		_pointer.position = r.get_center() - get_global_rect().position

func _show_slide(i: int) -> void:
	_slide_i = (i + _slides.size()) % _slides.size()
	_slide_t = 0.0
	for c in _carousel.get_children():
		c.queue_free()
	var sd: Dictionary = _slides[_slide_i]
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_carousel.add_child(root)
	var bart := UI.tex_rect(DB.bg(sd["bg"]), Vector2.ZERO, true)
	bart.modulate = Color(1, 1, 1, 0.55)
	bart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bart)
	var art_tex: Texture2D = DB.tex(sd["npc"]) if sd.has("npc") else (DB.tex(sd["img"][0]) if sd.has("img") else DB.cutin(sd["art"]))
	var bhero := UI.tex_rect(art_tex)
	bhero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bhero.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	bhero.offset_left = -230
	root.add_child(bhero)
	if sd.has("img"):
		# special-event art: tap to open the big view (and play its frames)
		bhero.mouse_filter = Control.MOUSE_FILTER_STOP
		bhero.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var frames: Array = sd["img"]
		var prm2: Dictionary = sd["params"]
		var route2: String = sd["route"]
		bhero.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_event_banner_view(frames, prm2, route2, str(sd["tag"])))
		if frames.size() > 1:
			var hint := UI.label("TAP ▶", 12, Color("#ffd479"), 4)
			hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			hint.offset_left = -64
			hint.offset_top = -24
			root.add_child(hint)
	bhero.modulate.a = 0.0
	bhero.create_tween().tween_property(bhero, "modulate:a", 1.0, 0.4)
	var bv := UI.vbox(4)
	bv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bv.offset_left = 16
	bv.offset_top = 12
	bv.offset_right = -16
	bv.offset_bottom = -12
	root.add_child(bv)
	bv.add_child(UI.label(sd["tag"], 13, sd["tag_col"], 3))
	var tl := UI.label(sd["title"], 26, UI.GOLD, 6)
	bv.add_child(tl)
	bv.add_child(UI.label(sd["sub"], 13, Color.WHITE, 3))
	bv.add_child(UI.spacer(false))
	var bottom := UI.hbox(8)
	bv.add_child(bottom)
	var route: String = sd["route"]
	var prm: Dictionary = sd["params"]
	bottom.add_child(UI.button(sd["btn"], func(): main.go(route, prm), "GoldButton", Vector2(150, 44)))
	bottom.add_child(UI.spacer())
	var nav := UI.hbox(4)
	nav.add_child(UI.button("◀", func(): _show_slide(_slide_i - 1), "FlatButton", Vector2(30, 30)))
	for k in _slides.size():
		var d := Panel.new()
		d.custom_minimum_size = Vector2(9, 9)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.add_theme_stylebox_override("panel", UI.style(UI.GOLD if k == _slide_i else Color(1, 1, 1, 0.35), Color.TRANSPARENT, 5, 0, 0))
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nav.add_child(d)
	nav.add_child(UI.button("▶", func(): _show_slide(_slide_i + 1), "FlatButton", Vector2(30, 30)))
	bottom.add_child(nav)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bv.modulate.a = 0.0
	bv.create_tween().tween_property(bv, "modulate:a", 1.0, 0.3)

func _daily_done() -> Array:
	var done := 0
	for q in DB.DAILY_QUESTS:
		if Game.quest_state(q) != "progress":
			done += 1
	return [done, DB.DAILY_QUESTS.size()]

func _draw_ring() -> void:
	var c := _ring.size * 0.5
	var r := minf(c.x, c.y) - 5.0
	var d := _daily_done()
	_ring.draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.12), 6.0, true)
	var frac := clampf(_ring_val, 0.0, 1.0)
	if frac > 0.0:
		_ring.draw_arc(c, r, -PI / 2, -PI / 2 + TAU * frac, 48, UI.GREEN if frac >= 1.0 else UI.GOLD, 6.0, true)
	var f := _ring.get_theme_default_font()
	var txt := "%d/%d" % [d[0], d[1]]
	_ring.draw_string(f, c + Vector2(-20, 6), txt, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color.WHITE)
	_ring.draw_string(f, c + Vector2(-20, 20), "TODAY", HORIZONTAL_ALIGNMENT_CENTER, 40, 9, UI.MUTED)

## Lighting that follows the device clock (WIB): dawn gold, day clear, dusk orange, night blue + stars.
func _time_of_day() -> void:
	var hr: int = int(Time.get_datetime_dict_from_system()["hour"])
	var tint := Color(0, 0, 0, 0)
	var rays := true
	var stars := false
	if hr >= 5 and hr < 9:
		tint = Color(1.0, 0.75, 0.4, 0.14)
	elif hr >= 9 and hr < 16:
		tint = Color(1.0, 1.0, 0.9, 0.04)
	elif hr >= 16 and hr < 19:
		tint = Color(1.0, 0.45, 0.25, 0.2)
	else:
		tint = Color(0.1, 0.15, 0.45, 0.32)
		rays = false
		stars = true
	var tr := ColorRect.new()
	tr.color = tint
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	move_child(tr, 3)
	if rays:
		var rl := Control.new()
		rl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rl.material = m
		add_child(rl)
		move_child(rl, 4)
		for i in 4:
			var ray := TextureRect.new()
			var g := Gradient.new()
			g.set_color(0, Color(tint.r, tint.g, tint.b * 0.8, 0.22))
			g.set_color(1, Color(1, 1, 1, 0.0))
			var gt := GradientTexture2D.new()
			gt.gradient = g
			gt.fill_from = Vector2(0.5, 0)
			gt.fill_to = Vector2(0.5, 1)
			ray.texture = gt
			ray.stretch_mode = TextureRect.STRETCH_SCALE
			ray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ray.size = Vector2(90 + i * 30, 900)
			ray.position = Vector2(180 + i * 170, -120)
			ray.rotation = -0.45
			ray.pivot_offset = Vector2(ray.size.x * 0.5, 0)
			ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rl.add_child(ray)
			var tw := ray.create_tween().set_loops()
			tw.tween_property(ray, "modulate:a", 0.35, randf_range(2.5, 4.0)).set_trans(Tween.TRANS_SINE)
			tw.tween_property(ray, "modulate:a", 1.0, randf_range(2.5, 4.0)).set_trans(Tween.TRANS_SINE)
			var sw := ray.create_tween().set_loops()
			sw.tween_property(ray, "rotation", -0.38, randf_range(4.0, 6.0)).set_trans(Tween.TRANS_SINE)
			sw.tween_property(ray, "rotation", -0.5, randf_range(4.0, 6.0)).set_trans(Tween.TRANS_SINE)
	if stars:
		var a := AmbientFX.new(Color(0.8, 0.9, 1.0), 50)
		add_child(a)
		move_child(a, 4)

func _hero_center() -> Vector2:
	return _hero_art.get_global_rect().get_center() - get_global_rect().position

func _idle_action() -> void:
	if _busy:
		return
	var lh: String = Game.s["lobby_hero"]
	if int(Game.hero(lh).get("bond", 1)) >= 3 and randf() < 0.3 and not _bubble.visible:
		_say(DB.voice(lh, "bond" if randf() < 0.5 else "greet")["en"])
	match randi() % 3:
		0:
			var tw := _hero_art.create_tween()
			tw.tween_property(_hero_art, "position:y", _hero_art.position.y - 10, 0.15).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(_hero_art, "position:y", _hero_art.position.y, 0.25).set_trans(Tween.TRANS_BOUNCE)
		1:
			var tw2 := _hero_art.create_tween()
			tw2.tween_property(_hero_art, "rotation", 0.012, 0.6).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(_hero_art, "rotation", -0.012, 1.0).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(_hero_art, "rotation", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
		_:
			_fx.aura(_hero_center() + Vector2(0, _hero_art.size.y * 0.25), DB.theme_color(Game.s["lobby_hero"]).lightened(0.3), 140.0)

## Sakura Oath style touch zones: head pat, shy body poke, startled legs.
func _on_hero_touch(ry: float, at: Vector2) -> void:
	if _busy:
		return
	_busy = true
	var hid: String = Game.s["lobby_hero"]
	var h := Game.hero(hid)
	Game.tap_hero(hid)   # bond exp + daily quest
	var zone := "head" if ry < 0.28 else ("body" if ry < 0.62 else "legs")
	if DB.lobby_art(hid) == null or int(h.get("skin", 0)) > 0:
		UI.flash_expression(_hero_art, DB.alt_art(hid, int(h.get("skin", 0))))
	var tcol: Color = {"head": Color("#ff8fb8"), "body": Color("#ff6f9a"), "legs": Color("#ffd479")}[zone]
	_fx.wave(at, tcol, 120.0)
	_fx.impact("LIGHT", at, tcol, 50.0)
	var line := ""
	var base_y := _hero_art.position.y
	var tw := _hero_art.create_tween()
	match zone:
		"head":
			line = Game.voice(hid, "bond" if int(h.get("bond", 1)) >= 3 else "greet")
			tw.tween_property(_hero_art, "scale", Vector2(1.02, 0.97), 0.12).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(_hero_art, "scale", Vector2(0.99, 1.02), 0.12)
			tw.tween_property(_hero_art, "scale", Vector2.ONE, 0.15)
			_heart_burst()
			_float_mark(at, "♥ pat pat", Color("#ff8fb8"))
		"body":
			line = Game.voice(hid, "tap")
			for i in 3:
				tw.tween_property(_hero_art, "rotation", 0.02, 0.06)
				tw.tween_property(_hero_art, "rotation", -0.02, 0.06)
			tw.tween_property(_hero_art, "rotation", 0.0, 0.06)
			var mt := _hero_art.create_tween()
			mt.tween_property(_hero_art, "self_modulate", Color(1.15, 0.85, 0.92), 0.15)
			mt.tween_property(_hero_art, "self_modulate", Color.WHITE, 0.6)
			_float_mark(at, "///", Color("#ff6f9a"))
		_:
			line = Game.voice(hid, "tap")
			tw.tween_property(_hero_art, "position:y", base_y - 34, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(_hero_art, "position:y", base_y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			_float_mark(_hero_center() - Vector2(0, _hero_art.size.y * 0.42), "!", Color("#ffd479"), 56)
	tw.tween_callback(func(): _busy = false)
	Game.sfx("ui_click")
	_say(line)

# ---------------------------------------------------------------- touch gestures
## tap = touch zones (head/body/legs) • rub the head = head-pat • long-press = close-up
## • swipe left/right = switch secretary
var _g_down := false
var _g_start := Vector2.ZERO
var _g_t0 := 0
var _g_rub := 0.0
var _g_moved := false
var _g_hold_fired := false
var _g_pat_t := 0
var _g_tap: Control

## Small translucent pill button for the secretary actions.
func _pill(text: String, cb: Callable, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 28)
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", col)
	b.add_theme_color_override("font_hover_color", col.lightened(0.3))
	for st in ["normal", "hover", "pressed"]:
		var sb := UI.style(Color(0.05, 0.03, 0.1, 0.55 if st == "normal" else 0.8), Color(col, 0.55), 14, 1, 0)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(func():
		Game.sfx("ui_click")
		cb.call())
	return b

func _gesture(e: InputEvent, tap: Control) -> void:
	_g_tap = tap
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_g_down = true
			_g_start = e.position
			_g_t0 = Time.get_ticks_msec()
			_g_rub = 0.0
			_g_moved = false
			_g_hold_fired = false
			get_tree().create_timer(0.75).timeout.connect(func():
				if _g_down and not _g_moved and not _g_hold_fired and is_instance_valid(_g_tap):
					_g_hold_fired = true
					_close_up())
		elif _g_down:
			_g_down = false
			var d: Vector2 = e.position - _g_start
			var dt := Time.get_ticks_msec() - _g_t0
			if _g_hold_fired:
				return
			if absf(d.x) > 110.0 and absf(d.x) > absf(d.y) * 1.5 and dt < 600 and _g_rub < 300.0:
				_switch_secretary(-1 if d.x > 0 else 1)
			elif _g_rub < 60.0:
				_on_hero_touch(e.position.y / maxf(1.0, tap.size.y), tap.get_global_rect().position + e.position - get_global_rect().position)
	elif e is InputEventMouseMotion and _g_down:
		var r: Vector2 = e.relative
		if (e.position - _g_start).length() > 14.0:
			_g_moved = true
		# rubbing on the head zone (upper 28%) → continuous head-pat
		if e.position.y / maxf(1.0, tap.size.y) < 0.3:
			_g_rub += r.length()
			if _g_rub > 60.0:
				_head_pat(tap.get_global_rect().position + e.position - get_global_rect().position)

func _head_pat(at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - _g_pat_t < 140:
		return
	_g_pat_t = now
	_float_mark(at + Vector2(randf_range(-30, 30), -10), "♥", Color("#ff8fb8"), 30)
	# she leans into the hand
	var lean := _hero_art.create_tween()
	lean.tween_property(_hero_art, "rotation", 0.02 if randf() < 0.5 else -0.02, 0.12).set_trans(Tween.TRANS_SINE)
	lean.tween_property(_hero_art, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	var hid: String = Game.s["lobby_hero"]
	if _g_rub > 520.0 and not has_meta("pat_spoke"):
		set_meta("pat_spoke", true)
		Game.tap_hero(hid)
		Game.add_bond(hid, 6)
		_say(Game.voice(hid, "bond"))
		_heart_burst()
		var mt := _hero_art.create_tween()
		mt.tween_property(_hero_art, "self_modulate", Color(1.12, 0.92, 0.96), 0.2)
		mt.tween_property(_hero_art, "self_modulate", Color.WHITE, 1.2)
		get_tree().create_timer(4.0).timeout.connect(_clear_pat)

func _clear_pat() -> void:
	if has_meta("pat_spoke"):
		remove_meta("pat_spoke")

## Long-press: the camera pushes in for a close-up, then eases back.
func _close_up() -> void:
	var hid: String = Game.s["lobby_hero"]
	Game.sfx("ui_click")
	_say(Game.voice(hid, "greet"))
	# zoom the holder (the art itself runs a looping breathing tween on its scale)
	var head := _hero_art.position + Vector2(_hero_art.size.x * 0.5, _hero_art.size.y * 0.2)
	_holder.pivot_offset = head
	var tw := _holder.create_tween()
	tw.tween_property(_holder, "scale", Vector2(1.6, 1.6), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(_holder, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_CUBIC)

## Swipe: next/previous owned hero becomes the secretary (gallery-style slide).
func _switch_secretary(dir: int) -> void:
	var ids: Array = Game.s["heroes"].keys()
	if ids.size() < 2:
		return
	var i := ids.find(Game.s["lobby_hero"])
	Game.s["lobby_hero"] = ids[posmod(i + dir, ids.size())]
	Game.mark_dirty()
	Game.sfx("ui_click")
	var tw := _hero_art.create_tween().set_parallel(true)
	tw.tween_property(_hero_art, "position:x", _hero_art.position.x - dir * 160.0, 0.18).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_hero_art, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(func(): main.replace("lobby", {"swipe": dir}))

func _float_mark(at: Vector2, text: String, col: Color, size: int = 26) -> void:
	var l := UI.label(text, size, col, 6)
	l.size = Vector2(200, size + 10)
	l.position = at - Vector2(100, size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 20
	add_child(l)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.5, 0.5)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(l, "position:y", l.position.y - 50, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)

var _prof_tab := "titles"

func _open_profile() -> void:
	var v: VBoxContainer = main.popup("COMMANDER PROFILE", 980)
	var h := UI.hbox(18)
	v.add_child(h)
	# ---- left: identity + stats
	var left := UI.vbox(8)
	left.custom_minimum_size = Vector2(360, 0)
	h.add_child(left)
	var top := UI.hbox(12)
	left.add_child(top)
	var av := UI.styled_panel(Color.BLACK, UI.GOLD, 60, 3, 2)
	av.custom_minimum_size = Vector2(112, 112)
	av.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	av.add_child(UI.tex_rect(DB.face(Game.avatar_id()), Vector2(108, 108), true))
	top.add_child(av)
	var idv := UI.vbox(4)
	top.add_child(idv)
	idv.add_child(UI.label(str(Game.s["player"]["name"]), 24, Color.WHITE, 4))
	idv.add_child(UI.label(Game.title_name(), 15, Color("#ff9ad5"), 3))
	idv.add_child(UI.label("Commander Lv.%d" % int(Game.s["player"]["level"]), 15, UI.GOLD, 3))
	var rn := UI.hbox(6)
	left.add_child(rn)
	var le := LineEdit.new()
	le.placeholder_text = "New name (2-14)"
	le.max_length = 14
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(0, 40)
	rn.add_child(le)
	rn.add_child(UI.button("RENAME", func():
		var err := Game.rename(le.text)
		if err != "":
			main.toast(err, UI.RED)
			return
		main.close_popup(v)
		main.replace("lobby"), "", Vector2(110, 40)))
	var best_tower := int(Game.s["tower"]["floor"]) - 1
	var stats := [["Heroes", "%d / %d" % [Game.s["heroes"].size(), DB.HEROES.size()]], ["Team Power", Game.fmt(Game.team_power())],
		["Story", "%d / %d stages" % [Game.stages_cleared(), DB.stage_count()]], ["Tower", "Floor %d" % maxi(0, best_tower)],
		["Arena", "%d RP" % int(Game.s["arena"]["rp"])], ["Summons", Game.fmt(int(Game.s["gacha"]["total"]))],
		["Oaths", str(Game.s["heroes"].values().filter(func(x): return bool(x["oath"])).size())],
		["Titles", "%d / %d" % [DB.TITLES.filter(func(t): return Game.title_unlocked(t["id"])).size(), DB.TITLES.size()]]]
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 4)
	left.add_child(g)
	for st in stats:
		g.add_child(UI.label(st[0], 14, UI.MUTED))
		g.add_child(UI.label(str(st[1]), 15, Color.WHITE, 2))
	# ---- right: titles / avatar picker
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	var tabs := UI.hbox(8)
	right.add_child(tabs)
	for tdef in [["titles", "TITLES"], ["avatar", "AVATAR"]]:
		var key: String = tdef[0]
		var tb := UI.button(tdef[1], func():
			_prof_tab = key
			main.close_popup(v)
			_open_profile(), "GoldButton" if _prof_tab == key else "", Vector2(0, 40))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tb)
	var box := UI.vbox(6)
	var sc := UI.scroll(box)
	sc.custom_minimum_size = Vector2(0, 380)
	right.add_child(sc)
	if _prof_tab == "titles":
		var cur := str(Game.s["player"].get("title", "rookie"))
		for t in DB.TITLES:
			var tid: String = t["id"]
			var open := Game.title_unlocked(tid)
			var b := UI.button("", func():
				if not open:
					main.toast("Locked: " + str(t["desc"]), UI.MUTED)
					return
				Game.set_title(tid)
				main.close_popup(v)
				main.replace("lobby"), "", Vector2(0, 52))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text = ("✓ " if tid == cur else "") + str(t["name"]) + "   —   " + str(t["desc"])
			b.add_theme_font_size_override("font_size", 14)
			if open:
				b.add_theme_color_override("font_color", UI.GOLD if tid == cur else Color.WHITE)
			else:
				b.modulate = Color(0.55, 0.55, 0.6)
			box.add_child(b)
	else:
		var ag := GridContainer.new()
		ag.columns = 6
		ag.add_theme_constant_override("h_separation", 8)
		ag.add_theme_constant_override("v_separation", 8)
		box.add_child(ag)
		for id in Game.s["heroes"].keys():
			var hid: String = id
			var card := HeroCard.new(hid, Vector2(80, 100), {"skin": true, "show_level": false})
			card.set_selected(hid == Game.avatar_id())
			card.pressed.connect(func():
				Game.set_avatar(hid)
				main.close_popup(v)
				main.replace("lobby"))
			ag.add_child(card)

## Hairly the fortune teller (animated pivot-rig NPC): one tarot card per day.
func _open_fortune() -> void:
	var v: VBoxContainer = main.popup("HAIRLY'S FORTUNE", 900)
	var h := UI.hbox(16)
	v.add_child(h)
	var npc := NPCPuppet.new(DB.tex("res://art/npc/hairly_lobby.png"), "hairly", DB.HAIRLY_PIVOTS)
	npc.custom_minimum_size = Vector2(300, 520)
	h.add_child(npc)
	var rv := UI.vbox(10)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(rv)
	var bubble := UI.styled_panel(Color(1, 1, 1, 0.95), Color("#b072ff"), 14, 1, 12)
	var bl := UI.wrap_label("...", 15, Color("#2a1a3a"))
	bubble.add_child(bl)
	rv.add_child(bubble)
	npc.spoke.connect(func(text): bl.text = "Hairly: " + text)
	var card := UI.styled_panel(Color(0.12, 0.06, 0.2, 0.95), UI.GOLD, 14, 2, 16)
	card.custom_minimum_size = Vector2(0, 220)
	rv.add_child(card)
	var cv := UI.vbox(8)
	card.add_child(cv)
	if Game.fortune_ready():
		cv.add_child(UI.label("A card waits, face down...", 18, Color("#d4b8ff"), 3))
		var drawb := UI.button("✦ DRAW TODAY'S CARD", func():
			var f := Game.fortune_draw()
			if f.is_empty():
				return
			npc.say("browse")
			for c in cv.get_children():
				c.queue_free()
			var cn := UI.label(str(f["card"]), 30, UI.GOLD, 6)
			cv.add_child(cn)
			UI.pop(cn, 0.4)
			cv.add_child(UI.wrap_label(str(f["text"]), 16, Color.WHITE))
			cv.add_child(UI.reward_row(f["give"], 36, 15))
			main.toast("Fortune gift received!", Color("#d4b8ff")), "GoldButton", Vector2(0, 54))
		cv.add_child(drawb)
		npc.greet.call_deferred()
	else:
		cv.add_child(UI.label("Today's card: " + str(Game.s.get("fortune_card", "?")), 22, UI.GOLD, 4))
		cv.add_child(UI.wrap_label("Come back tomorrow for a new reading.", 15, UI.MUTED))
		npc.react_sad.call_deferred()
	rv.add_child(UI.wrap_label("Tap Hairly's crown, body or legs... if you dare.", 12, UI.MUTED))

## Pulsing heart near the lobby hero: today's Secretary Moment.
func _add_moment_heart() -> void:
	var hb := Button.new()
	hb.theme_type_variation = "FlatButton"
	hb.focus_mode = Control.FOCUS_NONE
	hb.icon = DB.icon("icon_heart")
	hb.expand_icon = true
	hb.custom_minimum_size = Vector2(64, 64)
	hb.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hb.anchor_left = 0.13
	hb.anchor_right = 0.13
	hb.anchor_top = 0.4
	hb.anchor_bottom = 0.4
	hb.offset_right = 64
	hb.offset_bottom = 64
	hb.tooltip_text = "Today's moment"
	add_child(hb)
	hb.pivot_offset = Vector2(32, 32)
	var pt := hb.create_tween().set_loops()
	pt.tween_property(hb, "scale", Vector2(1.18, 1.18), 0.5).set_trans(Tween.TRANS_SINE)
	pt.parallel().tween_property(hb, "position:y", hb.position.y - 6, 0.5).set_trans(Tween.TRANS_SINE)
	pt.tween_property(hb, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	pt.parallel().tween_property(hb, "position:y", hb.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	var tag := UI.label("!", 22, Color("#ff8fb8"), 5)
	tag.position = Vector2(44, -6)
	hb.add_child(tag)
	hb.pressed.connect(func():
		var m := Game.secretary_moment()
		hb.queue_free()
		if m.is_empty():
			return
		Game.sfx("ui_click")
		main.dialogue(m["lines"], func():
			main.show_rewards("A MOMENT WITH %s" % DB.name_of(m["hero"]).split(" ")[0].to_upper(), m["give"]), "lobby", false, m["hero"], "%s_moment" % m["hero"]))

## Big view of a special-event banner. Multi-frame art (Bunny) animates 1→2→3 on every tap.
func _event_banner_view(frames: Array, prm: Dictionary, route: String = "gacha", title: String = "SPECIAL EVENT") -> void:
	var v: VBoxContainer = main.popup(title, 560)
	var img := UI.tex_rect(DB.tex(frames[0]))
	img.custom_minimum_size = Vector2(500, minf(470.0, get_viewport_rect().size.y - 250.0))
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	img.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	v.add_child(img)
	if frames.size() > 1:
		img.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				Game.sfx("ui_click")
				UI.play_frames(img, frames))
		v.add_child(UI.label("Tap the art to animate it!", 13, UI.MUTED))
		UI.play_frames.call_deferred(img, frames)
	v.add_child(UI.button("SUMMON NOW" if route == "gacha" else "OPEN %s" % title, func():
		main.close_popup(v)
		main.go(route, prm), "GoldButton", Vector2(0, 50)))

func _pick_scene() -> void:
	var v: VBoxContainer = main.popup("LOBBY SCENE", 820)
	v.add_child(UI.wrap_label("New scenes unlock as you clear story chapters.", 14, UI.MUTED))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	var cur := str(Game.s.get("lobby_bg", "lobby"))
	for sc in DB.LOBBY_SCENES:
		var key: String = sc["key"]
		var open := Game.scene_unlocked(sc)
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(186, 130)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color.BLACK, UI.GOLD if key == cur else Color("#4a3a6e"), 10, 3 if key == cur else 1, 0))
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(fr)
		var th := UI.tex_rect(DB.bg(key), Vector2.ZERO, true)
		th.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if not open:
			th.modulate = Color(0.25, 0.25, 0.3)
		fr.add_child(th)
		var l := UI.label(sc["name"] if open else "Clear %d stages" % sc["req"], 13, Color.WHITE if open else UI.MUTED, 4)
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		l.offset_top = -24
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fr.add_child(l)
		b.pressed.connect(func():
			if not open:
				main.toast("Locked — clear %d story stages." % sc["req"], UI.MUTED)
				return
			Game.sfx("ui_click")
			Game.s["lobby_bg"] = key
			Game.mark_dirty()
			main.close_popup(v)
			main.replace("lobby"))
		UI.hover_fx(b, 1.04)
		g.add_child(b)
	UI.stagger(g, 0.03)

func _next_outfit() -> void:
	var hid: String = Game.s["lobby_hero"]
	var n := DB.art_list(hid).size()
	var cur := int(Game.hero(hid).get("skin", 0))
	for i in range(1, n + 1):
		var k := (cur + i) % n
		if Game.skin_unlocked(hid, k):
			if k == cur:
				main.toast("Unlock more outfits via Star Up, Bond, Oath or the Outfits tab.", UI.MUTED)
				return
			Game.set_skin(hid, k)
			var tw := _hero_art.create_tween()
			tw.tween_property(_hero_art, "modulate:a", 0.0, 0.15)
			tw.tween_callback(func(): _hero_art.texture = DB.art(hid, k))
			tw.tween_property(_hero_art, "modulate:a", 1.0, 0.25)
			_fx.aura(_hero_center(), UI.GOLD, 180.0)
			Game.sfx("star_up")
			return

func _on_hero_tap() -> void:
	var hid: String = Game.s["lobby_hero"]
	var line := Game.tap_hero(hid)
	Game.sfx("ui_click")
	_say(line)
	var tw := _hero_art.create_tween()
	tw.tween_property(_hero_art, "position:y", _hero_art.position.y - 14, 0.12).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_hero_art, "position:y", _hero_art.position.y, 0.2).set_trans(Tween.TRANS_BOUNCE)
	_heart_burst()

func _say(text: String, who: String = "") -> void:
	_bubble_label.text = "%s\n%s" % [DB.name_of(who if who != "" else Game.s["lobby_hero"]), text]
	_bubble.visible = true
	UI.pop(_bubble, 0.25)
	if _bubble.has_meta("tw"):
		var old: Tween = _bubble.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	var tw := _bubble.create_tween()
	tw.tween_interval(3.5)
	tw.tween_callback(func(): _bubble.visible = false)
	_bubble.set_meta("tw", tw)

func _heart_burst() -> void:
	for i in 5:
		var h := UI.tex_rect(DB.icon("icon_heart"), Vector2(30, 30))
		h.size = Vector2(30, 30)
		var base := _hero_art.position + Vector2(_hero_art.size.x * 0.5, _hero_art.size.y * 0.3)
		h.position = base + Vector2(randf_range(-80, 80), randf_range(-20, 40))
		add_child(h)
		var tw := h.create_tween().set_parallel(true)
		tw.tween_property(h, "position:y", h.position.y - randf_range(80, 150), 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(h, "modulate:a", 0.0, 0.9).set_delay(0.3)
		tw.chain().tween_callback(h.queue_free)
