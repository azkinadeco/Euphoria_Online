extends Screen
## Messenger: heroes text the Commander. Pick one of two replies; the one she likes best gives more Bond.

const HERO_BUBBLE := Color("#2a2140")
const ME_BUBBLE := Color("#6b3a86")

var _sel := ""
var _list: VBoxContainer
var _chat: VBoxContainer
var _chat_scroll: ScrollContainer
var _replies: VBoxContainer
var _title: VBoxContainer
var _busy := false

func build() -> void:
	set_bg("lobby", 0.7)
	ambient(Color(1.0, 0.8, 0.95), 18)
	header("MESSENGER", ["gems"])
	var b := body(76)

	var lp := UI.panel()
	lp.anchor_right = 0.34
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	lv.add_child(UI.label("CHATS", 15, UI.GOLD, 3))
	_list = UI.vbox(6)
	var ls := UI.scroll(_list)
	ls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(ls)

	var rp := UI.panel()
	rp.anchor_left = 0.36
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	_title = UI.vbox(2)
	rv.add_child(_title)
	_chat = UI.vbox(10)
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_scroll = UI.scroll(_chat)
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(_chat_scroll)
	_replies = UI.vbox(6)
	rv.add_child(_replies)

	var contacts := Game.msg_contacts()
	_sel = str(params.get("hero", ""))
	if not contacts.has(_sel):
		_sel = contacts[0] if not contacts.is_empty() else ""
	_render_list()
	_render_chat(true)
	tutorial("messenger")

func _render_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	var contacts := Game.msg_contacts()
	if contacts.is_empty():
		_list.add_child(UI.wrap_label("No messages yet. Your heroes will text you soon!", 14, UI.MUTED))
		return
	var pending := Game.msg_pending()
	for id in contacts:
		var hid: String = id
		var btn := Button.new()
		btn.theme_type_variation = "TabButton"
		btn.toggle_mode = true
		btn.button_pressed = hid == _sel
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 76)
		btn.pressed.connect(func():
			if _busy:
				return
			Game.sfx("ui_click")
			_sel = hid
			_render_list()
			_render_chat(true))
		var row := UI.hbox(10)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8
		row.offset_right = -8
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(row)
		var face := UI.tex_rect(DB.face(hid), Vector2(56, 56), true)
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(face)
		var tv := UI.vbox(2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tv)
		tv.add_child(UI.label(DB.name_of(hid), 16, Color.WHITE, 3))
		var pv := UI.label(_preview(hid), 12, UI.MUTED)
		pv.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		pv.custom_minimum_size.x = 60
		tv.add_child(pv)
		if pending.has(hid):
			var dot := UI.label("●", 18, UI.RED, 2)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(dot)
		_list.add_child(btn)
	UI.stagger(_list, 0.02)

func _preview(id: String) -> String:
	var p := Game.msg_pending()
	if p.has(id):
		var th := DB.msg_thread(id, str(p[id]))
		return str(th[0][-1]) if not th.is_empty() else "New message"
	var hist := Game.msg_log(id)
	if hist.is_empty():
		return ""
	var last: Array = hist[-1]
	return ("You: " if last[0] == "p" else "") + str(last[1])

func _render_chat(scroll_down: bool) -> void:
	for c in _title.get_children():
		c.queue_free()
	for c in _chat.get_children():
		c.queue_free()
	for c in _replies.get_children():
		c.queue_free()
	if _sel == "":
		_chat.add_child(UI.wrap_label("Every day a few heroes send you a message. Come back tomorrow!", 16, UI.MUTED))
		return
	var h := Game.hero(_sel)
	var tr := UI.hbox(10)
	_title.add_child(tr)
	tr.add_child(UI.label(DB.name_of(_sel), 22, UI.GOLD, 4))
	var bl := UI.label("♥ Bond Lv.%d" % int(h["bond"]), 15, Color("#ff8fb8"), 3)
	bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.add_child(bl)
	for line in Game.msg_log(_sel):
		_bubble(str(line[1]), line[0] == "p")
	var p := Game.msg_pending()
	if p.has(_sel):
		var th := DB.msg_thread(_sel, str(p[_sel]))
		if not th.is_empty():
			if not Game.msg_log(_sel).is_empty():
				_divider("NEW")
			var i := 0
			for line in th[0]:
				var bub := _bubble(str(line), false)
				bub.modulate.a = 0.0
				create_tween().tween_property(bub, "modulate:a", 1.0, 0.25).set_delay(0.15 + 0.35 * i)
				i += 1
			_replies.add_child(UI.label("REPLY", 13, UI.MUTED, 2))
			for k in 2:
				var choice: int = k
				var rb := UI.button(str(th[1][k]), func(): _reply(choice), "GoldButton" if k == 0 else "", Vector2(0, 50))
				rb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_replies.add_child(rb)
	elif Game.msg_log(_sel).is_empty():
		_chat.add_child(UI.wrap_label("No messages yet.", 15, UI.MUTED))
	else:
		_replies.add_child(UI.label("%s will text you again soon." % DB.name_of(_sel).split(" ")[0], 13, UI.MUTED, 2))
	if scroll_down:
		_scroll_bottom()

func _divider(text: String) -> void:
	var l := UI.label("— %s —" % text, 12, Color("#ff8fb8"), 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chat.add_child(l)

## One chat bubble: hero on the left with her face, the Commander on the right.
func _bubble(text: String, mine: bool) -> Control:
	var row := UI.hbox(8)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_stretch_ratio = 0.35
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mine:
		row.add_child(spacer)
	else:
		var f := UI.tex_rect(DB.face(_sel), Vector2(40, 40), true)
		f.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(f)
	var pc := UI.styled_panel(ME_BUBBLE if mine else HERO_BUBBLE, Color("#c98be8") if mine else Color("#4a3a6e"), 14, 1, 10.0)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UI.wrap_label(text, 15, Color.WHITE)
	if mine:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pc.add_child(l)
	row.add_child(pc)
	if not mine:
		row.add_child(spacer)
	_chat.add_child(row)
	return row

func _scroll_bottom() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_chat_scroll):
		_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)

func _reply(choice: int) -> void:
	if _busy:
		return
	var id := _sel
	var p := Game.msg_pending()
	if not p.has(id):
		return
	var th := DB.msg_thread(id, str(p[id]))
	var r := Game.msg_reply(id, choice)
	if r.is_empty():
		return
	_busy = true
	Game.sfx("ui_click")
	for c in _replies.get_children():
		c.queue_free()
	_bubble(str(th[1][choice]), true)
	var typing := _bubble("typing…", false)
	typing.modulate = Color(1, 1, 1, 0.6)
	_scroll_bottom()
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	typing.queue_free()
	_bubble(str(r["answer"]), false)
	_scroll_bottom()
	Game.sfx("star_up" if r["best"] else "buff")
	var msg := ("Perfect reply! " if r["best"] else "") + "+%d Bond ♥" % int(r["bond"])
	if int(r["gems"]) > 0:
		msg += "   +%d Gems" % int(r["gems"])
	main.toast(msg, Color("#ff8fb8") if r["best"] else UI.GOLD)
	_busy = false
	_render_list()
	_replies.add_child(UI.label("%s will text you again soon." % DB.name_of(id).split(" ")[0], 13, UI.MUTED, 2))
	_update_chips()
