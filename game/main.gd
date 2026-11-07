extends Control
## Root of Euphoria Online v2: screen router + overlay layer.

const SCREENS := {
	"lobby": preload("res://game/screens/lobby.gd"),
	"heroes": preload("res://game/screens/heroes.gd"),
	"hero_detail": preload("res://game/screens/hero_detail.gd"),
	"formation": preload("res://game/screens/formation.gd"),
	"story": preload("res://game/screens/story.gd"),
	"battle": preload("res://game/screens/battle.gd"),
	"gacha": preload("res://game/screens/gacha.gd"),
	"shop": preload("res://game/screens/shop.gd"),
	"bag": preload("res://game/screens/bag.gd"),
	"quests": preload("res://game/screens/quests.gd"),
	"mail": preload("res://game/screens/mail.gd"),
	"arena": preload("res://game/screens/arena.gd"),
	"tower": preload("res://game/screens/tower.gd"),
	"settings": preload("res://game/screens/settings.gd"),
	"event": preload("res://game/screens/event.gd"),
	"guild": preload("res://game/screens/guild.gd"),
	"friends": preload("res://game/screens/friends.gd"),
	"title": preload("res://game/screens/title.gd"),
	"dungeon": preload("res://game/screens/dungeon.gd"),
	"pass": preload("res://game/screens/pass.gd"),
	"garden": preload("res://game/screens/garden.gd"),
	"gallery": preload("res://game/screens/gallery.gd"),
	"expedition": preload("res://game/screens/expedition.gd"),
	"minigame": preload("res://game/screens/minigame.gd"),
	"worldboss": preload("res://game/screens/worldboss.gd"),
	"festival": preload("res://game/screens/festival.gd"),
	"hunt": preload("res://game/screens/hunt.gd"),
	"rift": preload("res://game/screens/rift.gd"),
	"room": preload("res://game/screens/room.gd"),
	"bestiary": preload("res://game/screens/bestiary.gd"),
	"date": preload("res://game/screens/date.gd"),
	"wardrobe": preload("res://game/screens/wardrobe.gd"),
	"photo": preload("res://game/screens/photo.gd"),
	"forge": preload("res://game/screens/forge.gd"),
	"messenger": preload("res://game/screens/messenger.gd"),
}

const BGM := {"story": "bgm_story", "formation": "bgm_story", "event": "bgm_story", "dungeon": "bgm_story", "tower": "bgm_story",
	"arena": "bgm_story", "guild": "bgm_story", "worldboss": "bgm_story", "hunt": "bgm_story", "rift": "bgm_story", "room": "bgm_lobby", "date": "bgm_lobby", "photo": "bgm_lobby", "messenger": "bgm_lobby", "gacha": "bgm_gacha", "title": "bgm_lobby"}

var host: Control
var overlay: Control
var current: Screen
var current_name := ""
var history: Array = []
var _toast_box: VBoxContainer
var _going_back := false

func _ready() -> void:
	theme = UI.theme()
	Game.apply_ui_scale()
	Game.apply_fps()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bgc := ColorRect.new()
	bgc.color = Color("#07040d")
	bgc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bgc)
	host = Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_toast_box = UI.vbox(6)
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_box.offset_top = 80
	_toast_box.offset_left = -360
	_toast_box.offset_right = 360
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.z_index = 100
	overlay.add_child(_toast_box)
	Game.changed.connect(_on_changed)
	Game.bond_up.connect(_on_bond_up)
	Game.toast.connect(toast)
	get_tree().set_auto_accept_quit(false)
	Game.play_bgm()
	go("title", {}, false)

## Called by the title screen.
func enter_game() -> void:
	var first_time: bool = not Game.s.get("intro_seen", false)
	go("lobby", {"intro": first_time}, false)
	if first_time:
		Game.s["intro_seen"] = true
		Game.save_game()
		dialogue([
			["furu", "Commander, you've finally awakened! The Eclipse is swallowing Euphoria."],
			["shina", "We're the last Oath Knights. Grab the supplies in your Mailbox and let's go!"],
		])
	else:
		var after_welcome := func():
			var bd := Game.claim_birthdays()
			if not bd.is_empty():
				var hid: String = bd[0]
				dialogue([[hid, "Commander... you remembered? Today is my birthday!"], [hid, DB.voice(hid, "bond")["en"]]], func():
					show_rewards("HAPPY BIRTHDAY, %s!" % DB.name_of(hid).to_upper(), {"celestial_gem": 1, "gems": 100}, func():
						if Game.can_claim_login():
							show_login_calendar()), "", false, hid, "%s_bday" % hid)
			elif Game.can_claim_login():
				show_login_calendar()
		if Game.away_secs >= 3600:
			_welcome_back(after_welcome)
		else:
			after_welcome.call()

## Notice board (data/news.json): tabs of news on the left, the selected notice on the right.
func show_news(sel: int = 0) -> void:
	var items := DB.news()
	if items.is_empty():
		return
	var seen: Array = Game.s.get("news_seen", [])
	var v := popup("NOTICES", 1000)
	var h := UI.hbox(14)
	v.add_child(h)
	var lv := UI.vbox(6)
	lv.custom_minimum_size = Vector2(300, 0)
	h.add_child(lv)
	var tag_col := {"UPDATE": Color("#9fd0ff"), "NEW": Color("#ff8fb8"), "EVENT": Color("#ffd479"), "INFO": Color("#b8b0d0")}
	for i in items.size():
		var it: Dictionary = items[i]
		var idx := i
		var b := UI.button("", func():
			close_popup(v)
			show_news(idx), "TabButton", Vector2(0, 52))
		b.toggle_mode = true
		b.button_pressed = i == sel
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "  [%s] %s%s" % [it.get("tag", "INFO"), it["title"], "  •NEW" if not seen.has(it["id"]) else ""]
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", tag_col.get(it.get("tag", "INFO"), Color.WHITE))
		b.clip_text = true
		lv.add_child(b)
	var it2: Dictionary = items[clampi(sel, 0, items.size() - 1)]
	var rv := UI.vbox(8)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(rv)
	var banner := Panel.new()
	banner.custom_minimum_size = Vector2(0, 200)
	banner.add_theme_stylebox_override("panel", UI.style(Color.BLACK, UI.GOLD_DARK, 12, 1, 0))
	banner.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	rv.add_child(banner)
	var bt := UI.tex_rect(DB.bg(str(it2.get("bg", "lobby"))), Vector2.ZERO, true)
	bt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.add_child(bt)
	var tl := UI.label(it2["title"], 26, Color.WHITE, 6)
	tl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tl.offset_top = -44
	tl.offset_left = 14
	banner.add_child(tl)
	rv.add_child(UI.label("%s   •   %s" % [it2.get("tag", "INFO"), it2.get("date", "")], 13, tag_col.get(it2.get("tag", "INFO"), UI.MUTED), 3))
	var body := UI.wrap_label(str(it2.get("body", "")), 16, UI.TEXT)
	var sc := UI.scroll(body)
	sc.custom_minimum_size = Vector2(0, 170)
	rv.add_child(sc)
	Game.mark_news_read()

## Daily Board: one place listing everything left to do today, each with a GO button.
func show_daily_board() -> void:
	var v := popup("TODAY'S BOARD", 760)
	var rows := Game.daily_board()
	var left := rows.filter(func(r): return int(r[4]) > 0).size()
	v.add_child(UI.label("%d activities still waiting today  •  resets at 07:00" % left if left > 0 else "All done for today — great work, Commander!", 14, UI.GOLD if left > 0 else UI.GREEN, 3))
	var list := UI.vbox(6)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 430)
	v.add_child(sc)
	for r in rows:
		var row: Array = r
		var todo: bool = int(row[4]) > 0
		var p := UI.styled_panel(Color(0.1, 0.07, 0.18, 0.92) if todo else Color(0.05, 0.04, 0.08, 0.7), UI.GOLD_DARK if todo else Color("#2c2444"), 10, 1, 8)
		list.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		var ic := UI.tex_rect(DB.icon(row[1]), Vector2(34, 34))
		if not todo:
			ic.modulate = Color(0.5, 0.5, 0.55)
		h.add_child(ic)
		var t := UI.label(row[2], 16, Color.WHITE if todo else UI.MUTED, 2)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		h.add_child(UI.label(row[3], 14, UI.GOLD if todo else UI.MUTED, 2))
		if not todo:
			h.add_child(UI.label("✓", 18, UI.GREEN, 2))
			continue
		var route: String = row[0]
		var label := "CLAIM" if route in ["afk", "login"] else "GO"
		h.add_child(UI.button(label, func(): _board_go(route, v), "GoldButton", Vector2(96, 38)))
	UI.stagger(list, 0.02)

func _board_go(route: String, v: Control) -> void:
	close_popup(v)
	match route:
		"afk":
			var ar := Game.claim_afk()
			if not ar.is_empty():
				show_rewards("AFK REWARDS", ar)
		"login":
			show_login_calendar()
		"heroes":
			go("hero_detail", {"id": Game.s["lobby_hero"]})
		_:
			go(route)

## "Welcome back" summary after being away for an hour or more (Sakura Oath style).
func _welcome_back(done: Callable) -> void:
	var hid: String = Game.s["lobby_hero"]
	var v := popup("WELCOME BACK, COMMANDER", 760)
	var h := UI.hbox(16)
	v.add_child(h)
	var art := UI.tex_rect(DB.face(hid, int(Game.hero(hid).get("skin", 0))), Vector2(180, 220), true)
	h.add_child(art)
	var col := UI.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var a := Game.away_secs
	var away_txt := ("%dd %dh" % [a / 86400, (a / 3600) % 24]) if a >= 86400 else ("%dh %dm" % [a / 3600, (a / 60) % 60])
	col.add_child(UI.label("You were away for %s." % away_txt, 18, Color.WHITE, 3))
	col.add_child(UI.wrap_label("\"%s\"" % Game.voice(hid, "greet"), 16, Color("#ffe6a3")))
	var afk := Game.afk_pending()
	col.add_child(UI.label("AFK rewards waiting: %s Gold • %s Hero EXP" % [Game.fmt(afk["gold"]), Game.fmt(afk["hero_exp"])], 15, UI.GREEN))
	col.add_child(UI.label("Energy: %d / %d" % [Game.amount("energy"), Game.energy_max()], 15, Color("#ffb86b")))
	if Game.expeditions_ready() > 0:
		col.add_child(UI.label("%d expedition(s) completed!" % Game.expeditions_ready(), 15, Color("#9fd0ff")))
	if Game.badge_quests() > 0:
		col.add_child(UI.label("%d mission reward(s) ready to claim" % Game.badge_quests(), 15, UI.GOLD))
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("CLAIM AFK", func():
		var r := Game.claim_afk()
		close_popup(v)
		if r.is_empty():
			done.call()
		else:
			show_rewards("AFK REWARDS", r, done), "GoldButton", Vector2(200, 50)))
	row.add_child(UI.button("LATER", func(): close_popup(v); done.call(), "", Vector2(140, 50)))

func _on_changed() -> void:
	if is_instance_valid(current):
		current.refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Game.save_game()
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()

# ================================================================ routing

func go(name: String, params: Dictionary = {}, push: bool = true) -> void:
	if not SCREENS.has(name):
		toast("Coming soon: %s" % name)
		return
	if not Game.feature_unlocked(name):
		toast("%s unlocks at Player Lv.%d. Clear more story stages to level up!" % [name.capitalize(), Game.feature_req(name)], UI.MUTED)
		return
	Game.seen_unlock(name)
	_close_all_popups()
	if push and current_name != "":
		history.append({"name": current_name, "params": current.params if is_instance_valid(current) else {}})
		if history.size() > 20:
			history.pop_front()
	var scr: Screen = SCREENS[name].new()
	scr.main = self
	scr.params = params
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var old := current
	current = scr
	current_name = name
	host.add_child(scr)
	if name != "battle":
		Game.play_bgm(BGM.get(name, "bgm_lobby"))
	scr.build()
	scr.modulate.a = 0.0
	var dir := -1.0 if _going_back else 1.0
	scr.position.x = 60.0 * dir
	var tw := scr.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(scr, "modulate:a", 1.0, 0.25)
	tw.tween_property(scr, "position:x", 0.0, 0.3)
	_going_back = false
	if is_instance_valid(old):
		old.mouse_filter = Control.MOUSE_FILTER_IGNORE
		old.set_process(false)
		# tween owned by Main so it still runs even if the old screen stops processing
		var ot := create_tween().set_parallel(true)
		ot.tween_property(old, "modulate:a", 0.0, 0.15)
		ot.tween_property(old, "position:x", -40.0 * dir, 0.15)
		ot.chain().tween_callback(old.queue_free)

## Replace the current screen without pushing history (e.g. battle → result → next battle).
func replace(name: String, params: Dictionary = {}) -> void:
	go(name, params, false)

func back() -> void:
	if _close_top_popup():
		return
	if is_instance_valid(current) and current.on_back():
		return
	if history.is_empty():
		if current_name != "lobby":
			go("lobby", {}, false)
		return
	var h: Dictionary = history.pop_back()
	_going_back = true
	go(h["name"], h["params"], false)

func home() -> void:
	history.clear()
	go("lobby", {}, false)

# ================================================================ overlays

func toast(text: String, color: Color = UI.GOLD) -> void:
	var p := UI.styled_panel(Color(0.05, 0.03, 0.1, 0.94), color, 22, 2, 14)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 17, Color.WHITE, 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	_toast_box.add_child(p)
	while _toast_box.get_child_count() > 3:
		var old_t := _toast_box.get_child(0)
		_toast_box.remove_child(old_t)
		old_t.queue_free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.18)
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(p.queue_free)

## Modal popup. Returns the content VBox to fill.
func popup(title: String, width: float = 560.0, closable: bool = true) -> VBoxContainer:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.set_meta("popup", true)
	overlay.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	if closable:
		dim.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed:
				close_popup(layer))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var p := PanelContainer.new()
	p.theme_type_variation = "OrnatePanel"
	p.custom_minimum_size = Vector2(width, 0)
	center.add_child(p)
	var v := UI.vbox(12)
	p.add_child(v)
	if title != "":
		var rp := PanelContainer.new()
		rp.theme_type_variation = "RibbonPanel"
		rp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rp.custom_minimum_size = Vector2(minf(width * 0.62, 520.0), 0)
		var t := UI.label(title, 22, Color("#ffe9b0"), 6)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rp.add_child(t)
		v.add_child(rp)
	v.set_meta("layer", layer)
	UI.pop(p)
	return v

func close_popup(layer_or_box: Node) -> void:
	var layer: Node = layer_or_box
	if layer_or_box.has_meta("layer"):
		layer = layer_or_box.get_meta("layer")
	if is_instance_valid(layer):
		layer.queue_free()

func _close_top_popup() -> bool:
	for i in range(overlay.get_child_count() - 1, -1, -1):
		var c := overlay.get_child(i)
		if c.has_meta("popup") and not c.is_queued_for_deletion():
			if c.has_meta("no_back"):
				return true
			c.queue_free()
			return true
	return false

func _close_all_popups() -> void:
	for c in overlay.get_children():
		if c.has_meta("popup"):
			c.queue_free()

var _fly_src: Array = []

## Reward icons fly from the popup to the currency bar at the top-right.
func _fly_icons() -> void:
	var dest := Vector2(get_viewport_rect().size.x - 240, 40)
	var k := 0
	for ic in _fly_src:
		if not is_instance_valid(ic) or not ic.is_visible_in_tree():
			continue
		var f := UI.tex_rect(ic.texture, Vector2(56, 56))
		f.size = Vector2(56, 56)
		f.position = ic.get_global_rect().position
		f.z_index = 200
		f.pivot_offset = Vector2(28, 28)
		overlay.add_child(f)
		var start := f.position
		var mid := (start + dest) * 0.5 + Vector2(0, -120)
		var tw := f.create_tween()
		tw.tween_interval(k * 0.06)
		tw.tween_method(func(p: float):
			f.position = start.lerp(mid, p).lerp(mid.lerp(dest, p), p), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(f, "scale", Vector2(0.5, 0.5), 0.55)
		tw.tween_callback(f.queue_free)
		k += 1
	if k > 0:
		get_tree().create_timer(0.6).timeout.connect(func(): Game.sfx("ui_click"))
	_fly_src.clear()

func show_rewards(title: String, rewards: Dictionary, after: Callable = Callable()) -> void:
	_fly_src.clear()
	Game.sfx("star_up")
	var v := popup(title, 560)
	if rewards.is_empty():
		v.add_child(UI.wrap_label("Nothing to collect yet.", 16))
	else:
		var row := HFlowContainer.new()
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("h_separation", 12)
		row.add_theme_constant_override("v_separation", 12)
		v.add_child(row)
		for k in rewards.keys():
			var cell := Control.new()
			cell.custom_minimum_size = Vector2(96, 110)
			row.add_child(cell)
			var shine := UI.tex_rect(DB.tex("res://art/vfx/vfx_magic_circle.png"), Vector2(96, 96))
			shine.size = Vector2(96, 96)
			shine.pivot_offset = Vector2(48, 48)
			shine.modulate = Color(1, 0.85, 0.4, 0.45)
			cell.add_child(shine)
			var st := shine.create_tween().set_loops()
			st.tween_property(shine, "rotation", TAU, 6.0).from(0.0)
			var ic := UI.tex_rect(Game.reward_icon(k), Vector2(64, 64), str(k).begins_with("shard:"))
			_fly_src.append(ic)
			ic.position = Vector2(16, 12)
			ic.size = Vector2(64, 64)
			cell.add_child(ic)
			var l := UI.label("x" + Game.fmt(int(rewards[k])), 16, UI.GOLD, 4)
			l.position = Vector2(0, 84)
			l.size = Vector2(96, 22)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(l)
			cell.tooltip_text = Game.reward_name(k)
		UI.stagger(row, 0.08)
	var ok := UI.button("OK", func():
		_fly_icons()
		close_popup(v)
		if after.is_valid():
			after.call(), "GoldButton", Vector2(200, 50))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)

func show_login_calendar() -> void:
	var v := popup("7-DAY LOGIN BONUS", 900)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var streak := int(Game.s["login"]["streak"])
	var can := Game.can_claim_login()
	for i in 7:
		var done := i < streak - 1 or (i == streak - 1 and not can)
		var today := i == streak - 1 and can
		var col := UI.GOLD if today else (UI.GREEN if done else Color("#4a3a6e"))
		var p := UI.styled_panel(Color(0.1, 0.06, 0.18, 1.0), col, 10, 3 if today else 1, 8)
		p.custom_minimum_size = Vector2(112, 150)
		var dv := UI.vbox(4)
		p.add_child(dv)
		var dl := UI.label("DAY %d" % (i + 1), 15, col, 3)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dv.add_child(dl)
		var rw: Dictionary = DB.LOGIN_REWARDS[i]
		for k in rw.keys():
			var ic := UI.tex_rect(Game.reward_icon(k), Vector2(0, 40))
			if done:
				ic.modulate = Color(1, 1, 1, 0.35)
			dv.add_child(ic)
			var al := UI.label("x" + Game.fmt(int(rw[k])), 13, Color.WHITE, 3)
			al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dv.add_child(al)
		if done:
			var cl := UI.label("CLAIMED", 12, UI.GREEN, 3)
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dv.add_child(cl)
		row.add_child(p)
	var b := UI.button("CLAIM DAY %d" % streak if can else "COME BACK TOMORROW", func():
		var r := Game.claim_login()
		close_popup(v)
		if not r.is_empty():
			show_rewards("DAY %d REWARD" % streak, r), "GoldButton", Vector2(300, 52))
	b.disabled = not can
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)

func confirm(text: String, yes: Callable, yes_text: String = "Confirm") -> void:
	var v := popup("Confirm", 500)
	var l := UI.wrap_label(text, 17, UI.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var h := UI.hbox(14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.button("Cancel", func(): close_popup(v), "", Vector2(160, 48)))
	h.add_child(UI.button(yes_text, func():
		close_popup(v)
		yes.call(), "GoldButton", Vector2(160, 48)))
	v.add_child(h)

## Visual-novel cutscene. lines = [[speaker_id, text], ...]; bg = DB.BG key (optional).
func dialogue(lines: Array, done: Callable = Callable(), bg: String = "", compact: bool = false, cg_hero: String = "", cg_key: String = "") -> VNDialogue:
	var vn := VNDialogue.new(lines, bg)
	vn.compact = compact
	vn.cg_hero = cg_hero
	vn.cg_key = cg_key
	overlay.add_child(vn)
	if done.is_valid():
		vn.finished.connect(done)
	# any choice inside the dialogue gives Bond to the hero who asked
	vn.chose.connect(func(_i, bond):
		for ln in lines:
			if str(ln[0]) == "?":
				Game.add_bond(str(ln[1]), bond)
				break)
	return vn

## Talk with a hero (3 per day): short VN scene with a personality-based choice.
func talk(id: String) -> void:
	var lines := Game.start_talk(id)
	if lines.is_empty():
		toast("No talks left today. Come back tomorrow!", UI.MUTED)
		return
	dialogue(lines)

# ---------------------------------------------------------------- bond level up celebration
var _bond_queue: Array = []

func _on_bond_up(id: String, lv: int) -> void:
	_bond_queue.append([id, lv])
	if _bond_queue.size() == 1:
		_next_bond_celebration.call_deferred()

func _vn_active() -> bool:
	for c in overlay.get_children():
		if c is VNDialogue and not c.is_queued_for_deletion():
			return true
	return false

func _next_bond_celebration() -> void:
	if _bond_queue.is_empty():
		return
	if _vn_active():
		get_tree().create_timer(0.5).timeout.connect(_next_bond_celebration)
		return
	var e: Array = _bond_queue[0]
	var id: String = e[0]
	var lv: int = e[1]
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.set_meta("popup", true)
	overlay.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.02, 0.15, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var fx := SkillFX.new()
	layer.add_child(fx)
	var art := UI.tex_rect(DB.art(id, int(Game.hero(id).get("skin", 0))))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_right = 0.55
	art.offset_top = 20
	layer.add_child(art)
	UI.fade_in(art, 0.5, Vector2(-60, 0))
	var v := UI.vbox(8)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.anchor_left = 0.5
	v.offset_right = -40
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(v)
	var t1 := UI.label("♥ BOND UP ♥", 26, Color("#ff8fb8"), 6)
	v.add_child(t1)
	var t2 := UI.label("%s  Lv.%d" % [DB.name_of(id), lv], 50, Color.WHITE, 10)
	v.add_child(t2)
	UI.pop(t2, 0.5)
	var unlocks: Array = ["+2% all stats"]
	for k in DB.BOND_STORY_REQ.size():
		if int(DB.BOND_STORY_REQ[k]) == lv:
			unlocks.append("New Memory: \"%s\"" % DB.bond_story_title(id, k))
	if lv == 5:
		unlocks.append("Affection voice line")
	if lv in [4, 7, 10]:
		unlocks.append("New outfit may be unlocked")
	if lv == DB.MAX_BOND:
		unlocks.append("Oath Ceremony available!")
	for u in unlocks:
		v.add_child(UI.label("✦ " + str(u), 18, UI.GOLD, 4))
	var q := UI.wrap_label("\"%s\"" % Game.voice(id, "bond"), 18, Color("#ffe6a3"))
	v.add_child(q)
	var hint := UI.label("Tap to continue", 14, UI.MUTED)
	v.add_child(hint)
	UI.stagger(v, 0.12)
	Game.sfx("awakening")
	var c := get_viewport_rect().size * Vector2(0.3, 0.5)
	fx.wave(c, Color("#ff8fb8"), 600.0)
	fx.aura(c, Color("#ff8fb8"), 260.0)
	for i in 16:
		var h := UI.tex_rect(DB.icon("icon_heart"), Vector2(34, 34))
		h.size = Vector2(34, 34)
		h.position = Vector2(randf() * get_viewport_rect().size.x, get_viewport_rect().size.y + 20)
		layer.add_child(h)
		var tw := h.create_tween().set_parallel(true)
		tw.tween_property(h, "position:y", -60.0, randf_range(2.0, 3.5)).set_delay(randf() * 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(h, "position:x", h.position.x + randf_range(-80, 80), 3.0)
	layer.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			layer.queue_free()
			_bond_queue.pop_front()
			_next_bond_celebration())
