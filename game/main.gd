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
	"dismantle": preload("res://game/screens/dismantle.gd"),
	"messenger": preload("res://game/screens/messenger.gd"),
	"kitchen": preload("res://game/screens/kitchen.gd"),
	"training": preload("res://game/screens/training.gd"),
}

const BGM := {"story": "bgm_story", "formation": "bgm_story", "event": "bgm_story", "dungeon": "bgm_story", "tower": "bgm_story",
	"arena": "bgm_story", "guild": "bgm_story", "worldboss": "bgm_story", "hunt": "bgm_story", "rift": "bgm_story", "training": "bgm_story", "room": "bgm_lobby", "date": "bgm_lobby", "photo": "bgm_lobby", "messenger": "bgm_lobby", "kitchen": "bgm_lobby", "gacha": "bgm_gacha", "title": ""}

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
	go("title", {}, false)   # no music yet: the title and the studio logo are quiet (see BGM["title"])
	# studio logo first (ONIX Studio), then the title screen that is already waiting underneath
	if not get_tree().root.has_meta("no_intro"):
		add_child(StudioIntro.new())

## Called by the title screen.
func enter_game() -> void:
	var first_time: bool = not Game.s.get("intro_seen", false)
	go("lobby", {"intro": first_time}, false)
	if first_time:
		Game.s["intro_seen"] = true
		Game.s["promo_day"] = Game.day_key()   # no shop offer on the very first day
		Game.save_game()
		dialogue([
			["furu", "Commander, you've finally awakened! The Eclipse is swallowing Euphoria."],
			["shina", "We're the last Oath Knights. Grab the supplies in your Mailbox and let's go!"],
		], func(): show_how_to_play(_startup_popups))
	else:
		var after_welcome := func():
			var bd := Game.claim_birthdays()
			if not bd.is_empty():
				var hid: String = bd[0]
				dialogue([[hid, "Commander... you remembered? Today is my birthday!"], [hid, DB.voice(hid, "bond")["en"]]], func():
					show_rewards("HAPPY BIRTHDAY, %s!" % DB.name_of(hid).to_upper(), {"celestial_gem": 1, "gems": 100}, func():
						_startup_popups()), "", false, hid, "%s_bday" % hid)
			else:
				_startup_popups()
		if Game.away_secs >= 3600:
			_welcome_back(after_welcome)
		else:
			after_welcome.call()

## The illustrated How to Play guide (first launch, and Settings → HOW TO PLAY).
func show_how_to_play(done: Callable = Callable()) -> void:
	var g := HowToPlay.new()
	overlay.add_child(g)
	if done.is_valid():
		g.finished.connect(done)

## Start-of-session popups, one after another: daily login calendar, then the new-skin offer (once a day).
func _startup_popups() -> void:
	if Game.restored_from != "":
		toast("Your save file was damaged. Restored the backup from %s." % Game.restored_from, UI.RED)
		Game.restored_from = ""
	_when_clear(func():
		if Game.can_claim_login():
			show_login_calendar()
		_when_clear(func():
			if int(Game.s.get("promo_day", -1)) != Game.day_key():
				show_skin_promo()))

var _rating_waiting := false
const RATING_TAGS := ["Love the characters", "Fun battles", "Want more story", "Too much text", "Confusing menus",
	"Battles too hard", "Battles too easy", "Too much grinding", "Slow / laggy", "Hard to read on phone"]

## Playtest quick rating (queued by Game.Tele.queue_rating at chapter 1/3/6 clear, shown back in the lobby).
func show_rating() -> void:
	_rating_waiting = false
	var key := Game.Tele.rating_due()
	if key == "":
		return
	var v: VBoxContainer = popup("QUICK FEEDBACK", 680, false)
	v.add_child(UI.wrap_label("Thanks for playing this test build! How do you like Euphoria so far?", 15, Color.WHITE))
	var stars := UI.hbox(8)
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stars)
	var picked := [0]
	var star_btns: Array = []
	var tags: Array = []
	# built before the stars: GDScript lambdas capture variables by value, so it must exist already
	var send := UI.button("SEND", func():
		Game.Tele.rating_done(key, int(picked[0]), tags)
		close_popup(v)
		toast("Thank you! Your feedback is in the playtest log.", UI.GREEN), "GoldButton", Vector2(170, 46))
	send.disabled = true
	for i in 5:
		var b := UI.button("★", Callable(), "", Vector2(64, 56))
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(func():
			picked[0] = i + 1
			for k in star_btns.size():
				(star_btns[k] as Button).add_theme_color_override("font_color", UI.GOLD if k <= i else UI.MUTED)
			send.disabled = false
			Game.sfx("ui_click"))
		b.add_theme_color_override("font_color", UI.MUTED)
		star_btns.append(b)
		stars.add_child(b)
	v.add_child(UI.label("Anything that stood out? (optional, tap all that apply)", 13, UI.MUTED, 0))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for tg in RATING_TAGS:
		var c := UI.button(tg, Callable(), "TabButton", Vector2(0, 38))
		c.toggle_mode = true
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_theme_font_size_override("font_size", 14)
		c.toggled.connect(func(on):
			if on:
				tags.append(tg)
			else:
				tags.erase(tg))
		grid.add_child(c)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(send)
	row.add_child(UI.button("WRITE MORE", func():
		Game.Tele.rating_done(key, int(picked[0]), tags)
		close_popup(v)
		show_feedback(), "", Vector2(170, 46)))
	row.add_child(UI.button("NOT NOW", func():
		Game.Tele.rating_done(key, 0, [])
		close_popup(v), "", Vector2(140, 46)))

## Settings / reminder: download or copy the playtest log so the tester can send it to the developer.
func show_send_log() -> void:
	Game.Tele.flush()
	var text := Game.Tele.export_text()
	var fname := Game.Tele.file_name()
	var v: VBoxContainer = popup("SEND PLAYTEST LOG", 640)
	v.add_child(UI.wrap_label("Download the file (or copy the text) and send it to the developer by chat or e-mail. Thank you!", 14, UI.MUTED))
	var sm := Game.Tele.summary()
	v.add_child(UI.label("%s  •  %d events  •  %.0f KB   (newest first, times in UTC)" % [fname, sm["events"], text.length() / 1024.0], 12, Color("#b8c8ff"), 0))
	var te := TextEdit.new()
	te.text = Game.Tele.preview()
	te.editable = false
	te.custom_minimum_size = Vector2(0, 260)
	te.add_theme_font_size_override("font_size", 14)
	v.add_child(te)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("DOWNLOAD", func():
		if OS.has_feature("web"):
			JavaScriptBridge.download_buffer(text.to_utf8_buffer(), fname, "application/json")
		else:
			var path := "user://" + fname
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f:
				f.store_string(text)
				f = null
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))
		Game.Tele.mark_sent()
		toast("Playtest log saved: %s" % fname, UI.GREEN), "GoldButton", Vector2(170, 46)))
	row.add_child(UI.button("COPY TEXT", func():
		DisplayServer.clipboard_set(text)
		Game.Tele.mark_sent()
		toast("Playtest log copied!", UI.GREEN), "", Vector2(170, 46)))
	row.add_child(UI.button("CLOSE", func(): close_popup(v), "", Vector2(140, 46)))

## Day 2+ of a playtest: ask once in a while for the log (Game.Tele.send_reminder_due).
func show_send_reminder() -> void:
	_rating_waiting = false
	Game.Tele.mark_reminded()
	var sm := Game.Tele.summary()
	var v: VBoxContainer = popup("THANK YOU FOR TESTING!", 600)
	v.add_child(UI.wrap_label("You have played on %d different days. Could you send us your playtest log? It takes 10 seconds and helps us fix what matters most." % int(sm["days"]), 15, Color.WHITE))
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("SEND LOG", func():
		close_popup(v)
		show_send_log(), "GoldButton", Vector2(170, 46)))
	row.add_child(UI.button("WRITE FEEDBACK", func():
		close_popup(v)
		show_feedback(), "", Vector2(200, 46)))
	row.add_child(UI.button("LATER", func(): close_popup(v), "", Vector2(130, 46)))

## In-game asset download: evolution / later-stage hero art comes after the first (small) download.
## Shows progress, the last error and RETRY (Settings > HD ART, or tap a "Loading HD" note).
func show_art_download() -> void:
	var ap = Game.art_pack
	var v: VBoxContainer = popup("DOWNLOAD HD ART", 560)
	v.add_child(UI.wrap_label("Evolved and later-stage hero art downloads in the background while you play, so the first start stays small. It is kept on this device: the next visit does not download it again.", 14, UI.MUTED))
	var bar := UI.bar(0, 1, "GoldBar", 14)
	v.add_child(bar)
	var st := UI.label("", 15, Color.WHITE, 2)
	v.add_child(st)
	var er := UI.wrap_label("", 13, UI.RED)
	v.add_child(er)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("RETRY", func():
		if is_instance_valid(ap):
			ap.restart()
		toast("Downloading HD art...", UI.GOLD), "GoldButton", Vector2(160, 46)))
	row.add_child(UI.button("CLOSE", func(): close_popup(v), "", Vector2(140, 46)))
	var upd := func():
		if not is_instance_valid(ap) or ap.progress().y == 0:
			st.text = "All hero art is already included in this build."
			bar.max_value = 1
			bar.value = 1
			return
		var pr: Vector2i = ap.progress()
		bar.max_value = pr.y
		bar.value = pr.x
		st.text = ("HD ART READY  •  %d / %d packs" % [pr.x, pr.y]) if pr.x >= pr.y else "%d / %d packs  •  %.1f / %.1f MB" % [pr.x, pr.y, ap.bytes_done / 1e6, ap.bytes_total / 1e6]
		er.text = ("Last problem: %s" % ap.last_error) if str(ap.last_error) != "" and pr.x < pr.y else ""
	upd.call()
	var tm := Timer.new()
	tm.wait_time = 0.5
	tm.autostart = true
	v.add_child(tm)
	tm.timeout.connect(upd)

## Free-text playtest feedback; saved into the playtest log (sent along with SEND LOG).
func show_feedback() -> void:
	var v: VBoxContainer = popup("WRITE FEEDBACK", 680)
	v.add_child(UI.wrap_label("What did you like? What was confusing, boring or broken? Where did you want to stop playing? Please don't write personal information (name, phone, e-mail).", 14, UI.MUTED))
	var te := TextEdit.new()
	te.placeholder_text = "Type here..."
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.custom_minimum_size = Vector2(0, 220)
	te.add_theme_font_size_override("font_size", 16)
	v.add_child(te)
	var cnt := UI.label("0 / 1000", 12, UI.MUTED, 0)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(cnt)
	te.text_changed.connect(func():
		if te.text.length() > 1000:
			te.text = te.text.substr(0, 1000)
			te.set_caret_column(te.text.length())
		cnt.text = "%d / 1000" % te.text.length())
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("SAVE", func():
		var txt := te.text.strip_edges()
		if txt == "":
			toast("Write something first.", UI.MUTED)
			return
		Game.Tele.feedback(txt, current_name)
		close_popup(v)
		toast("Saved! It is sent with your playtest log (Settings > PLAYTEST DATA > SEND LOG).", UI.GREEN), "GoldButton", Vector2(170, 46)))
	row.add_child(UI.button("CANCEL", func(): close_popup(v), "", Vector2(150, 46)))
	te.grab_focus.call_deferred()

## Run `cb` once no dialogue or popup is on screen (polls every 0.4 s).
func _when_clear(cb: Callable) -> void:
	var busy := _vn_active()
	for c in overlay.get_children():
		if c.has_meta("popup") and not c.is_queued_for_deletion():
			busy = true
	if busy or current_name != "lobby":
		get_tree().create_timer(0.4).timeout.connect(func(): _when_clear(cb))
		return
	cb.call()

## The skin on offer: a gem-buyable special skin the player does not own yet (rotates daily).
func promo_skin() -> String:
	var ids: Array = DB.SPECIAL_SKINS.keys().filter(func(h): return DB.special_index(h) >= 0 and not DB.EVENT_SKINS.has(h) and not Game.skin_unlocked(h, DB.special_index(h)))
	if ids.is_empty():
		return ""
	return ids[Game.day_key() % ids.size()]

## Full-screen "NEW SKIN" offer: the skin's art, its name and bonus, GET IT (→ Wardrobe) or close.
func show_skin_promo() -> void:
	var hid := promo_skin()
	if hid == "":
		return
	Game.s["promo_day"] = Game.day_key()
	Game.mark_dirty()
	var idx := DB.special_index(hid)
	var col := DB.theme_color(hid)
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.set_meta("popup", true)
	overlay.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var card := Control.new()
	card.custom_minimum_size = Vector2(minf(980.0, get_viewport().get_visible_rect().size.x - 40.0), minf(560.0, get_viewport().get_visible_rect().size.y - 40.0))
	card.clip_contents = true
	center.add_child(card)
	var bg := UI.tex_rect(DB.bg("blackmarket"), Vector2.ZERO, true)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.55, 0.45, 0.6)
	card.add_child(bg)
	var glow := Control.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.draw.connect(func():
		var c := Vector2(glow.size.x * 0.3, glow.size.y * 0.5)
		for i in 9:
			glow.draw_circle(c, 300.0 - i * 30.0, Color(col, 0.05))
		var dk := Color(0.04, 0.02, 0.08, 0.92)
		var cl := Color(0.04, 0.02, 0.08, 0.0)
		var x0 := glow.size.x * 0.45
		glow.draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(glow.size.x, 0), glow.size, Vector2(x0, glow.size.y)]), PackedColorArray([cl, dk, dk, cl])))
	card.add_child(glow)
	var art := UI.tex_rect(DB.art(hid, idx))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_right = 0.58
	art.offset_top = 10
	art.offset_bottom = 30
	card.add_child(art)
	UI.live(art, col.lightened(0.4))
	UI.fade_in(art, 0.45, Vector2(-40, 0))
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, UI.GOLD, 16, 2, 0))
	card.add_child(frame)
	var v := UI.vbox(8)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.anchor_left = 0.55
	v.offset_right = -30
	v.offset_top = 40
	v.offset_bottom = -30
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var tag := UI.styled_panel(Color("#ff4d8d"), Color.TRANSPARENT, 8, 0, 0)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tag.add_child(UI.margin(UI.label("✦ NEW SKIN ✦", 13, Color.WHITE, 2), 10, 3, 10, 3))
	v.add_child(tag)
	var nm := UI.label(str(DB.SPECIAL_SKINS[hid]).to_upper(), 36, UI.GOLD, 0)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.add_theme_color_override("font_outline_color", col.darkened(0.8))
	nm.add_theme_constant_override("outline_size", 10)
	v.add_child(nm)
	v.add_child(UI.label(DB.name_of(hid) + "  •  " + DB.title_of(hid), 15, Color.WHITE, 3))
	var perks := UI.vbox(4)
	for t in ["Exclusive full outfit + battle look", "+10% ATK & HP while worn", "Special scene with %s" % DB.name_of(hid).split(" ")[0]]:
		perks.add_child(UI.label("✔  " + t, 14, Color("#ffe6a3"), 2))
	v.add_child(perks)
	var price := UI.hbox(8)
	price.add_child(UI.tex_rect(DB.icon("icon_gem"), Vector2(28, 28)))
	price.add_child(UI.label(Game.fmt(DB.SPECIAL_PRICE), 26, Color.WHITE, 4))
	price.add_child(UI.label("or 1 Skin Ticket", 13, UI.MUTED, 2))
	v.add_child(price)
	var bt := UI.hbox(10)
	v.add_child(bt)
	var get_b := UI.button("GET IT ▶", func():
		close_popup(layer)
		go("wardrobe", {"hero": hid}), "GoldButton", Vector2(200, 54))
	bt.add_child(get_b)
	var pt := get_b.create_tween().set_loops()
	pt.tween_property(get_b, "modulate", Color(1.2, 1.15, 1.05), 0.6)
	pt.tween_property(get_b, "modulate", Color.WHITE, 0.6)
	bt.add_child(UI.button("LATER", func(): close_popup(layer), "", Vector2(120, 54)))
	var x := UI.button("✕", func(): close_popup(layer), "", Vector2(46, 46))
	x.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	x.offset_left = -58
	x.offset_top = 12
	x.offset_right = -12
	x.offset_bottom = 58
	card.add_child(x)
	card.modulate.a = 0.0
	card.scale = Vector2(0.94, 0.94)
	card.pivot_offset = card.custom_minimum_size * 0.5
	var tw := card.create_tween().set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	tw.tween_property(card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lv.add_child(b)
	# the list scrolls on its own next to the article (it used to grow the popup far past the screen)
	h.remove_child(lv)
	var lsc := UI.scroll(lv)
	lsc.size_flags_horizontal = Control.SIZE_FILL
	lsc.custom_minimum_size = Vector2(312, 0)
	h.add_child(lsc)
	var sel_i := clampi(sel, 0, items.size() - 1)
	(func():
		if is_instance_valid(lsc) and sel_i > 4:
			lsc.scroll_vertical = int(maxf(0.0, sel_i * 58.0 - 116.0))).call_deferred()
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
	var top := UI.hbox(8)
	v.add_child(top)
	var tl := UI.label("%d activities still waiting today  •  resets at 07:00" % left if left > 0 else "All done for today — great work, Commander!", 14, UI.GOLD if left > 0 else UI.GREEN, 3)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	top.add_child(UI.button("SCHEDULE ▶", func():
		close_popup(v)
		show_schedule(), "", Vector2(150, 36)))
	# one-tap collection of everything that needs no playing
	var col := Game.collectables()
	var cp := UI.styled_panel(Color("#3a2a18") if not col.is_empty() else Color(0.05, 0.04, 0.08, 0.7), UI.GOLD if not col.is_empty() else Color("#2c2444"), 12, 1, 8)
	v.add_child(cp)
	var ch := UI.hbox(10)
	cp.add_child(ch)
	var names: Array = col.map(func(c): return str(c[0]) + (" ×%d" % int(c[1]) if int(c[1]) > 1 else ""))
	var cl := UI.wrap_label("Ready now:  " + ", ".join(names) if not col.is_empty() else "Nothing to collect right now. AFK rewards, mail and mission rewards will show up here.", 13, Color.WHITE if not col.is_empty() else UI.MUTED)
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(cl)
	var cb := UI.button("✦ COLLECT ALL", func(): _collect_all(v), "GoldButton" if not col.is_empty() else "", Vector2(190, 46))
	cb.disabled = col.is_empty()
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ch.add_child(cb)
	var list := UI.vbox(6)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 370)
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
		if route == "dungeon" and Game.dungeon_sweeps_ready() > 0:
			h.add_child(UI.button("SWEEP %d" % Game.dungeon_sweeps_ready(), func():
				var res := Game.sweep_all_dungeons()
				close_popup(v)
				Game.sfx("star_up")
				show_rewards("SWEPT %d RUNS" % int(res["runs"]), res["rewards"], show_daily_board), "", Vector2(110, 38)))
		var label := "CLAIM" if route in ["afk", "login"] else "GO"
		h.add_child(UI.button(label, func(): _board_go(route, v), "GoldButton", Vector2(96, 38)))
	UI.stagger(list, 0.02)

## Calendar of everything on a timer (events, seasons, resets) and the next hero birthdays.
func show_schedule() -> void:
	var v := popup("SCHEDULE", 820)
	var top := UI.hbox(8)
	v.add_child(top)
	var tl := UI.label("What is running, and for how long", 14, UI.GOLD, 3)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	top.add_child(UI.button("◀ TODAY", func():
		close_popup(v)
		show_daily_board(), "", Vector2(150, 36)))
	var list := UI.vbox(6)
	var sc := UI.scroll(list)
	sc.custom_minimum_size = Vector2(0, 350)
	v.add_child(sc)
	var chips: Array = []
	for e in Game.schedule():
		var row: Dictionary = e
		var col := Color(str(row["color"]))
		var p := UI.styled_panel(Color(0.08, 0.06, 0.15, 0.92), Color(col, 0.55), 10, 1, 8)
		list.add_child(p)
		var h := UI.hbox(10)
		p.add_child(h)
		var ic := UI.tex_rect(DB.icon(str(row["icon"])), Vector2(36, 36))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
		var tv := UI.vbox(1)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tv)
		tv.add_child(UI.label(str(row["name"]), 16, Color.WHITE, 2))
		tv.add_child(UI.wrap_label(str(row["note"]), 12, UI.MUTED))
		var cp := UI.styled_panel(Color(0, 0, 0, 0.45), Color(col, 0.7), 8, 1, 6)
		cp.custom_minimum_size = Vector2(108, 0)
		cp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var cl := UI.label("", 14, col.lightened(0.35), 2)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cp.add_child(cl)
		h.add_child(cp)
		chips.append([cl, Game.now() + int(row["left"])])
		var route := str(row["route"])
		var gb := UI.button("GO", func():
			close_popup(v)
			go(route), "", Vector2(70, 38))
		gb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(gb)
	# birthdays
	var bds := Game.upcoming_birthdays(4)
	if not bds.is_empty():
		v.add_child(UI.label("✦ UPCOMING BIRTHDAYS", 14, Color("#ff9ad5"), 2))
		var bh := UI.hbox(8)
		v.add_child(bh)
		for bd in bds:
			var b: Dictionary = bd
			var own := Game.owns(str(b["id"]))
			var bp := UI.styled_panel(Color(0.12, 0.05, 0.14, 0.92), Color("#ff9ad5", 0.6 if own else 0.25), 10, 1, 6)
			bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bp.tooltip_text = "Her present arrives on her birthday" if own else "Recruit her to celebrate together"
			bh.add_child(bp)
			var bx := UI.hbox(8)
			bp.add_child(bx)
			var fr := UI.avatar(str(b["id"]), 46, Color("#ff8fb8") if own else Color(1, 1, 1, 0.2), 1)
			if not own:
				fr.modulate = Color(0.5, 0.5, 0.55)
			bx.add_child(fr)
			var bv := UI.vbox(0)
			bx.add_child(bv)
			bv.add_child(UI.label(DB.name_of(str(b["id"])).split(" ")[0], 14, Color.WHITE if own else UI.MUTED, 2))
			var dd := int(b["days"])
			bv.add_child(UI.label("TODAY!" if dd == 0 else ("Tomorrow" if dd == 1 else "in %d days" % dd), 12, UI.GOLD if dd <= 1 else Color("#ff9ad5"), 2))
	var tick := func():
		for c in chips:
			var left: int = int(c[1]) - Game.now()
			(c[0] as Label).text = Game.left_text(left)
			(c[0] as Label).add_theme_color_override("font_color", Color("#ff8a8a") if left < 86400 else Color.WHITE)
	tick.call()
	var tm := Timer.new()
	tm.wait_time = 1.0
	tm.autostart = true
	tm.timeout.connect(tick)
	v.add_child(tm)
	UI.stagger(list, 0.02)

func _collect_all(v: Control) -> void:
	var res := Game.collect_all()
	close_popup(v)
	if (res["done"] as Array).is_empty():
		toast("Nothing to collect right now.")
		return
	Game.sfx("star_up")
	var after := func():
		toast("Collected: " + ", ".join(res["done"]), UI.GREEN)
		if current and current.has_method("refresh"):
			current.refresh()
	if (res["rewards"] as Dictionary).is_empty():
		after.call()
	else:
		show_rewards("ALL COLLECTED", res["rewards"], after)

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
	var art := UI.tex_rect(DB.bust(hid, int(Game.hero(hid).get("skin", 0))), Vector2(180, 220), true)
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
	if Game.defence_new() > 0:
		var held: int = Game.defence_log().slice(0, Game.defence_new()).filter(func(e): return bool(e["held"])).size()
		col.add_child(UI.label("Arena: %d attack(s) on your team — %d held, %d lost" % [Game.defence_new(), held, Game.defence_new() - held], 15, Color("#ff9a5a")))
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

const TapFX = preload("res://game/ui/tap_fx.gd")
const StudioIntro = preload("res://game/ui/studio_intro.gd")
var _tap_fx: Control

## Every tap leaves a small spark where the finger landed (cosmetic; input is not consumed).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not Game.reduce_fx():
		if _tap_fx == null or not is_instance_valid(_tap_fx):
			_tap_fx = TapFX.new()
			add_child(_tap_fx)
		_tap_fx.burst(_tap_fx.get_global_transform().affine_inverse() * (event as InputEventMouseButton).global_position)

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
	Game.tele("scr", {"n": name})
	if name == "lobby" and not _rating_waiting and Game.Tele.rating_due() != "":
		_rating_waiting = true
		_when_clear(show_rating)
	elif name == "lobby" and not _rating_waiting and Game.Tele.send_reminder_due():
		_rating_waiting = true
		_when_clear(show_send_reminder)
	_close_all_popups()
	if push and current_name != "":
		history.append({"name": current_name, "params": current.params if is_instance_valid(current) else {}})
		if history.size() > 20:
			history.pop_front()
	Game.set_meta("screen_t", Time.get_ticks_msec())
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
		var song := str(BGM.get(name, "bgm_lobby"))
		if song == "":
			Game.stop_bgm()
		else:
			Game.play_bgm(song)
	scr.build()
	scr.modulate.a = 0.0
	var dir := -1.0 if _going_back else 1.0
	scr.position.x = 60.0 * dir
	_going_back = false
	if is_instance_valid(old):
		old.mouse_filter = Control.MOUSE_FILTER_IGNORE
		old.set_process(false)
	# Start both slides one frame later. Building a big screen takes a long frame, and a tween started in
	# that frame gets the whole build time as its first step: most of the slide happened at once (a jump).
	_start_transition.call_deferred(scr, old, dir)

func _start_transition(scr: Control, old: Control, dir: float) -> void:
	await get_tree().process_frame
	if is_instance_valid(scr):
		var tw := scr.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(scr, "modulate:a", 1.0, 0.25)
		tw.tween_property(scr, "position:x", 0.0, 0.3)
	if is_instance_valid(old):
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

## Toasts with the same lead text (e.g. several "PLAYER LEVEL UP! Lv.x" in a row) merge into one.
static func _toast_group(text: String) -> String:
	var rx := RegEx.create_from_string("^[^0-9]*")
	var m := rx.search(text)
	return m.get_string() if m else text

func toast(text: String, color: Color = UI.GOLD) -> void:
	if color == UI.RED:
		Game.sfx("ui/error")   # "not enough", "locked", "can't do that"
		Game.haptic(28)
	var grp := _toast_group(text)
	# "NEW FEATURE UNLOCKED: A!" + "...: B!" → one toast listing both
	var join := grp == text and text.find(": ") > 0
	if join:
		grp = text.substr(0, text.find(": ") + 2)
	if grp.length() >= 8:
		for old_p in _toast_box.get_children():
			if old_p.has_meta("grp") and old_p.get_meta("grp") == grp and not old_p.is_queued_for_deletion():
				if join:
					var prev: String = old_p.get_meta("text")
					text = prev.trim_suffix("!") + ", " + text.substr(grp.length())
				_toast_box.remove_child(old_p)
				old_p.queue_free()
	var p := UI.styled_panel(Color(0.05, 0.03, 0.1, 0.94), color, 22, 2, 14)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	var gl := UI.styled_panel(Color(color.r, color.g, color.b, 0.22), color, 15, 1, 0)
	gl.custom_minimum_size = Vector2(30, 30)
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gt := UI.label(_toast_glyph(text, color), 17, color.lightened(0.45), 2)
	gt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gl.add_child(gt)
	row.add_child(gl)
	var l := UI.label(text, 17, Color.WHITE, 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 120
	row.add_child(l)
	var bal := Control.new()
	bal.custom_minimum_size = Vector2(30, 0)
	bal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bal)
	p.set_meta("grp", grp)
	p.set_meta("text", text)
	_toast_box.add_child(p)
	while _toast_box.get_child_count() > 3:
		var old_t := _toast_box.get_child(0)
		_toast_box.remove_child(old_t)
		old_t.queue_free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	if Game.reduce_fx():
		tw.tween_property(p, "modulate:a", 1.0, 0.18)
	else:
		UI.shine(p, 9.0, 0.45, color.lightened(0.5), 22)
		# drop in with a little overshoot (scale only: the VBox owns position)
		p.resized.connect(func(): p.pivot_offset = Vector2(p.size.x * 0.5, 0))
		p.scale = Vector2(0.86, 0.6)
		tw.set_parallel(true)
		tw.tween_property(p, "modulate:a", 1.0, 0.16)
		tw.tween_property(p, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(gl, "rotation", TAU, 0.5).from(-0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		gl.resized.connect(func(): gl.pivot_offset = gl.size * 0.5)
		tw.set_parallel(false)
		if color == UI.RED:
			# "no": a quick head-shake (rotation only - the VBox owns the position)
			var shk := p.create_tween()
			shk.tween_interval(0.12)
			for ang in [0.035, -0.03, 0.022, -0.014, 0.0]:
				shk.tween_property(p, "rotation", ang, 0.05).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	if not Game.reduce_fx():
		tw.parallel().tween_property(p, "scale", Vector2(0.94, 0.8), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(p.queue_free)

## Small leading glyph for a toast, picked from its text/colour.
func _toast_glyph(text: String, color: Color) -> String:
	var u := text.to_upper()
	if u.contains("UNLOCKS AT") or u.contains("LOCKED"):
		return "✕"
	if u.contains("UNLOCK") or u.contains("NEW "):
		return "✦"
	if u.contains("LEVEL") or u.contains("LV.") or u.contains("RANK"):
		return "▲"
	if u.contains("NOT ENOUGH") or u.contains("NEED") or u.contains("FULL") or u.contains("CAN'T") or u.contains("CANNOT"):
		return "!"
	if u.contains("SAVED") or u.contains("CLAIM") or u.contains("COMPLETE") or u.contains("CLEAR"):
		return "✓"
	if color.is_equal_approx(UI.MUTED):
		return "•"
	return "★"

## Modal popup. Returns the content VBox to fill.
## One-shot timer owned by `owner`: never fires after the owner is gone.
static func _owned_timer(owner: Node, delay: float, cb: Callable) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = delay
	t.timeout.connect(func():
		cb.call()
		t.queue_free())
	owner.add_child(t)
	t.start()

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
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.18)
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
	layer.set_meta("panel", p)
	UI.pop(p)
	if closable:
		# a visible close button in the corner (tapping outside also closes; not everyone knows that)
		var xb := Button.new()
		xb.text = "✕"
		xb.focus_mode = Control.FOCUS_NONE
		xb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		xb.custom_minimum_size = Vector2(40, 40)
		xb.size = Vector2(40, 40)
		xb.add_theme_font_size_override("font_size", 18)
		xb.add_theme_color_override("font_color", Color("#ffe9b0"))
		for st in ["normal", "hover", "pressed"]:
			xb.add_theme_stylebox_override(st, UI.style(Color(0.12, 0.06, 0.2, 0.95 if st != "hover" else 1.0), Color(UI.GOLD, 0.7 if st == "normal" else 1.0), 20, 2, 0))
		xb.tooltip_text = "Close"
		xb.pressed.connect(func(): close_popup(layer))
		layer.add_child(xb)
		var place := func():
			if is_instance_valid(xb) and is_instance_valid(p):
				var r := p.get_global_rect()
				var vr := get_viewport_rect().size
				xb.global_position = Vector2(minf(r.end.x - 26, vr.x - 44), maxf(r.position.y - 14, 4.0))
				xb.scale = p.scale
				xb.modulate.a = p.modulate.a
		p.item_rect_changed.connect(place)
		# follow the panel only while its pop-in animation runs, then stay put (no endless timer)
		var follow := layer.create_tween()   # stops when the popup is freed
		follow.tween_method(func(_v: float): place.call(), 0.0, 1.0, 0.45)
		place.call_deferred()
	Game.sfx("ui/open")
	# Safety net: a popup taller than the screen (long lists, big UI size) had its lower rows and its
	# CLOSE button below the edge with no way to reach them. Its content scrolls instead.
	var head := 1 if title != "" else 0
	var fit := func():
		if is_instance_valid(p) and not layer.has_meta("closing"):
			var room: float = layer.size.y - 20.0
			if room > 200.0 and p.get_combined_minimum_size().y > room:
				UI.fit_tall(p, head, room)
	# after the first layout (see UI.fit_tall), then twice more while the content settles (no endless timer)
	for fd in [0.08, 0.4, 1.0]:
		_owned_timer(layer, fd, fit)   # dies with the popup (a tree timer called into a freed popup)
	p.minimum_size_changed.connect(fit)
	return v

## Fade the dim and shrink the panel away, then free the layer. The layer stops counting as a popup at once.
func _dismiss(layer: Node) -> void:
	if not is_instance_valid(layer) or layer.is_queued_for_deletion() or layer.has_meta("closing"):
		return
	if not (layer is Control) or Game.reduce_fx():
		layer.queue_free()
		return
	var lc := layer as Control
	if lc.has_meta("popup"):
		Game.sfx("ui/close")
	lc.set_meta("closing", true)
	if lc.has_meta("popup"):
		lc.remove_meta("popup")
	# nothing inside may be clicked twice while it fades
	lc.propagate_call("set_mouse_filter", [Control.MOUSE_FILTER_IGNORE])
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(lc, "modulate:a", 0.0, 0.16)
	var p = lc.get_meta("panel", null)
	if p is Control and is_instance_valid(p):
		(p as Control).pivot_offset = (p as Control).size * 0.5
		tw.tween_property(p, "scale", Vector2(0.9, 0.9), 0.16)
	tw.chain().tween_callback(lc.queue_free)

func close_popup(layer_or_box: Node) -> void:
	var layer: Node = layer_or_box
	if layer_or_box.has_meta("layer"):
		layer = layer_or_box.get_meta("layer")
	if is_instance_valid(layer):
		_dismiss(layer)

func _close_top_popup() -> bool:
	for i in range(overlay.get_child_count() - 1, -1, -1):
		var c := overlay.get_child(i)
		if c.has_meta("popup") and not c.is_queued_for_deletion():
			if c.has_meta("no_back"):
				return true
			_dismiss(c)
			return true
	return false

func _close_all_popups() -> void:
	for c in overlay.get_children():
		if c.has_meta("popup"):
			c.queue_free()

var _fly_src: Array = []
const BurstFx := preload("res://game/ui/burst_fx.gd")

## A few icons arc from `from` (global position) up to the currency bar: what you just got "goes in".
func fly_from(textures: Array, from: Vector2) -> void:
	if Game.reduce_fx():
		return
	var dest := Vector2(get_viewport_rect().size.x - 240, 40)
	var k := 0
	for tex in textures.slice(0, 4):
		var f := UI.tex_rect(tex, Vector2(48, 48))
		f.size = Vector2(48, 48)
		f.position = from - Vector2(24, 24) + Vector2(k * 18 - 18, 0)
		f.z_index = 200
		f.pivot_offset = Vector2(24, 24)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(f)
		var start := f.position
		var mid := (start + dest) * 0.5 + Vector2(0, -140)
		f.scale = Vector2(0.4, 0.4)
		var tw := f.create_tween()
		tw.tween_interval(k * 0.07)
		tw.tween_property(f, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK)
		tw.tween_method(func(p: float):
			f.position = start.lerp(mid, p).lerp(mid.lerp(dest, p), p), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(f, "scale", Vector2(0.45, 0.45), 0.5)
		tw.tween_callback(f.queue_free)
		k += 1

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
	Game.sfx("ui/reward")   # a chime of its own (star_up stays for level and star gains)
	Game.haptic(18)
	var v := popup(title, 560)
	if rewards.is_empty():
		v.add_child(UI.wrap_label("Nothing to collect yet.", 16))
	else:
		var row := HFlowContainer.new()
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("h_separation", 12)
		row.add_theme_constant_override("v_separation", 12)
		v.add_child(row)
		var idx := 0
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
			# icon drops in with a bounce, then a sparkle burst in the reward's tint
			var rare := _reward_tint(str(k))
			shine.modulate = Color(rare.r, rare.g, rare.b, 0.5)
			var delay := 0.12 + idx * 0.08
			ic.pivot_offset = Vector2(32, 32)
			ic.position.y = -26.0
			ic.scale = Vector2(0.7, 1.25)
			var dt := ic.create_tween()
			dt.tween_interval(delay)
			dt.tween_property(ic, "position:y", 12.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			dt.parallel().tween_property(ic, "scale", Vector2.ONE, 0.28)
			dt.tween_property(ic, "scale", Vector2(1.18, 0.84), 0.06)
			dt.tween_property(ic, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			BurstFx.spawn(cell, Vector2(48, 44), rare, 58.0, delay + 0.28)
			idx += 1
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

## Burst / halo tint for a reward key: premium currencies glow brighter and pinker.
func _reward_tint(k: String) -> Color:
	if k.begins_with("shard:") or k.begins_with("skin") or k in ["celestial_gem", "oath_ring", "summon_ticket", "ticket"]:
		return Color(1.0, 0.55, 0.95)
	if k in ["gems", "gem"]:
		return Color(0.55, 0.9, 1.0)
	if k.contains("exp") or k.contains("potion"):
		return Color(0.6, 1.0, 0.6)
	return Color(1.0, 0.85, 0.4)

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
	dialogue(lines, Callable(), DB.hero_bg_key(id) if DB.has_hero_bg(id) else "")

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
	var unlocks: Array = ["+2% all stats"] + DB.bond_unlocks(id, lv)
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

## An enemy's card: who she is, her skill and what beats her (stage panel, Battle Prep board).
func foe_info(e: Dictionary) -> void:
	var eid: String = str(e["id"])
	var bid := DB.base_id(eid)
	var v: VBoxContainer = popup("", 520)
	var h := UI.hbox(14)
	v.add_child(h)
	h.add_child(UI.avatar(bid, 96, Color("#ff5c6c") if e.get("boss", false) else Color("#6b4a7e"), 2))
	var tv := UI.vbox(3)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	var nm := (str(e.get("variant", "")).capitalize() + " " if e.get("mirror", false) else "") + DB.name_of(eid)
	tv.add_child(UI.label(nm + ("   BOSS" if e.get("boss", false) else ""), 20, Color.WHITE, 3))
	if DB.title_of(bid) != "":
		tv.add_child(UI.label(DB.title_of(bid), 12, UI.MUTED, 2))
	var row := UI.hbox(6)
	tv.add_child(row)
	row.add_child(UI.element_tag(DB.element_of(bid), 14))
	row.add_child(UI.label(DB.role_of(bid), 14, UI.MUTED, 2))
	tv.add_child(UI.label("Lv.%d" % int(e.get("level", 1)), 13, UI.GOLD, 2))
	var sk := DB.skill_of(bid)
	var sp := UI.styled_panel(Color(0, 0, 0, 0.35), Color(UI.GOLD, 0.35), 10, 1, 10)
	var sv := UI.vbox(4)
	sp.add_child(sv)
	sv.add_child(UI.label("SKILL  •  " + str(sk.get("name", "")), 14, UI.GOLD, 2))
	sv.add_child(UI.wrap_label(str(sk.get("desc", "")), 13, UI.TEXT))
	v.add_child(sp)
	var weak := ""
	var grp: String = DB.ELEMENT_GROUP.get(DB.element_of(bid), DB.element_of(bid))
	for k in DB.ELEMENT_BEATS.keys():
		if str(DB.ELEMENT_BEATS[k]) == grp:
			weak = str(k)
	if weak != "":
		v.add_child(UI.label("Bring %s heroes: +30%% damage against her." % weak, 13, UI.GREEN, 2))
