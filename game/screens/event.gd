extends Screen
## Limited-time event: festival stages + token exchange.

var _right: VBoxContainer
var _tab := "STAGES"
var _timer: Label
var _t := 0.0

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
	set_bg(DB.EVENT["bg"], 0.45)
	header("EVENT", ["energy", "festival_token"])
	var fid: String = DB.EVENT["featured"]

	var art := UI.tex_rect(DB.art(fid, 1))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.anchor_right = 0.4
	art.offset_top = 170
	add_child(art)
	UI.live(art, DB.theme_color(fid).lightened(0.5))
	UI.fade_in(art, 0.5, Vector2(-40, 0))

	var ip := UI.styled_panel(Color(0.04, 0.03, 0.1, 0.88), Color("#4ab3ff"), 12, 1, 12)
	ip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ip.anchor_right = 0.4
	ip.offset_left = 16
	ip.offset_right = -12
	ip.offset_top = 76
	add_child(ip)
	var info := UI.vbox(2)
	ip.add_child(info)
	info.add_child(UI.label("LIMITED EVENT", 14, Color("#9fe3ff"), 3))
	info.add_child(UI.label(DB.EVENT["name"].to_upper(), 30, UI.GOLD, 6))
	_timer = UI.label("", 15, Color.WHITE, 4)
	info.add_child(_timer)
	_event_story.call_deferred()

	var rp := UI.panel()
	rp.set_anchors_preset(Control.PRESET_FULL_RECT)
	rp.anchor_left = 0.4
	rp.offset_right = -16
	rp.offset_top = 76
	rp.offset_bottom = -16
	add_child(rp)
	var rv := UI.vbox(10)
	rp.add_child(rv)
	var tabs := UI.hbox(8)
	rv.add_child(tabs)
	for t in ["STAGES", "EXCHANGE"]:
		var key: String = t
		var b := UI.button(t, func(): _tab = key; _render(), "TabButton", Vector2(170, 42))
		b.toggle_mode = true
		b.set_meta("key", key)
		tabs.add_child(b)
	tabs.add_child(UI.spacer())
	_right = UI.vbox(8)
	rv.add_child(UI.scroll(_right))
	_render()
	_update_timer()

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
	if _tab == "STAGES":
		_right.add_child(UI.wrap_label(DB.EVENT["desc"], 14, UI.MUTED))
		for i in DB.EVENT["stages"].size():
			_stage_row(i)
	else:
		_right.add_child(UI.label("You have %s Moon Tokens" % Game.fmt(Game.amount("festival_token")), 17, UI.GOLD, 3))
		for item in DB.EVENT["shop"]:
			_shop_row(item)
	UI.stagger(_right, 0.05)

func _stage_row(i: int) -> void:
	var st := DB.event_stage(i)
	var stars := Game.event_stars(i)
	var unlocked := i == 0 or Game.event_stars(i - 1) > 0
	var p := UI.panel("CardPanel")
	_right.add_child(p)
	var h := UI.hbox(12)
	p.add_child(h)
	var faces := UI.hbox(3)
	for e in st["enemies"].slice(0, 3):
		var fp := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if e.get("boss", false) else Color("#4a7ab0"), 6, 2, 1)
		fp.add_child(UI.tex_rect(DB.face(e["id"]), Vector2(44, 44), true))
		faces.add_child(fp)
	h.add_child(faces)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label("EX-%d  %s" % [i + 1, st["name"]], 18, Color.WHITE if unlocked else UI.MUTED, 2))
	v.add_child(UI.label("Lv.%d  •  Power %s  •  %s" % [st["level"], Game.fmt(Game.enemy_power(st["enemies"])), "★".repeat(stars) + "☆".repeat(3 - stars)], 13, UI.GOLD))
	var rw := {"festival_token": st["tokens"]}
	if stars == 0:
		rw["gems"] = st["first_gems"]
	v.add_child(UI.reward_row(rw, 22, 13))
	h.add_child(v)
	var idx: int = i
	var b := UI.button("BATTLE" if unlocked else "LOCKED", func(): main.go("formation", {"mode": "event", "stage": idx}), "GoldButton", Vector2(120, 50))
	b.disabled = not unlocked
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)

func _shop_row(item: Dictionary) -> void:
	var it := item
	var p := UI.panel("CardPanel")
	_right.add_child(p)
	var h := UI.hbox(12)
	p.add_child(h)
	var k: String = it["give"].keys()[0]
	h.add_child(UI.tex_rect(Game.reward_icon(k), Vector2(52, 52), k.begins_with("shard:")))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(it["name"], 17, Color.WHITE, 2))
	var left := int(it["limit"]) - Game.event_bought(it["id"])
	v.add_child(UI.label("Left: %d / %d" % [left, it["limit"]], 12, UI.MUTED))
	h.add_child(v)
	var b := UI.button("%s Tokens" % Game.fmt(it["price"]), func():
		var err := Game.buy_event(it)
		if err != "":
			main.toast(err, UI.RED)
		else:
			Game.sfx("star_up")
			main.toast("Exchanged: %s" % it["name"], UI.GREEN)
		_render(), "GoldButton", Vector2(150, 46))
	b.disabled = left <= 0
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
