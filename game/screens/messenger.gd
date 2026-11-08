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
	var tip := UI.styled_panel(Color("#ff8fb8", 0.08), Color("#ff8fb8", 0.35), 10, 1, 8.0)
	tip.add_child(UI.wrap_label("♥ Pick the reply she likes best for a Perfect Reply: extra Bond, sometimes Gems.", 12, Color("#ffc0d8")))
	lv.add_child(tip)

	var rp := UI.panel()
	rp.anchor_left = 0.36
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	_title = UI.vbox(2)
	var tb := UI.styled_panel(Color(0.08, 0.05, 0.13, 0.9), Color(1, 1, 1, 0.1), 12, 1, 8.0)
	tb.add_child(_title)
	rv.add_child(tb)
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
		var face := _avatar(hid, 54, pending.has(hid))
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
			var pill := UI.styled_panel(UI.RED, UI.RED, 10, 0, 6.0)
			pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pill.add_child(UI.label("NEW", 10, Color.WHITE, 1))
			row.add_child(pill)
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
	_stamp_i = 0
	if _sel == "":
		_chat.add_child(UI.wrap_label("Every day a few heroes send you a message. Come back tomorrow!", 16, UI.MUTED))
		return
	var h := Game.hero(_sel)
	var tr := UI.hbox(10)
	_title.add_child(tr)
	tr.add_child(_avatar(_sel, 46, true))
	var nv := UI.vbox(0)
	nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(UI.label(DB.name_of(_sel), 20, UI.GOLD, 3))
	nv.add_child(UI.label("● Online", 12, UI.GREEN, 1))
	tr.add_child(nv)
	var bp := UI.styled_panel(Color("#ff8fb8", 0.12), Color("#ff8fb8", 0.5), 10, 1, 8.0)
	bp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bp.add_child(UI.label("♥ Bond Lv.%d" % int(h["bond"]), 14, Color("#ff8fb8"), 2))
	tr.add_child(bp)
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
## Short lines hug their text; long ones wrap at ~65% of the chat width.
func _bubble(text: String, mine: bool) -> Control:
	var row := UI.hbox(8)
	if mine:
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(sp)
	else:
		var f := _avatar(_sel, 38, false)
		f.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(f)
	var col := UI.vbox(2)
	var pc := PanelContainer.new()
	var sb := UI.style(ME_BUBBLE if mine else HERO_BUBBLE, Color("#c98be8") if mine else Color("#4a3a6e"), 14, 1, 12.0)
	# speech-bubble tail corner
	if mine:
		sb.corner_radius_top_right = 3
	else:
		sb.corner_radius_top_left = 3
	pc.add_theme_stylebox_override("panel", sb)
	var l := UI.label(text, 15, Color.WHITE)
	var cw := _chat_scroll.size.x if is_instance_valid(_chat_scroll) else 0.0
	if cw < 200.0:
		cw = get_viewport_rect().size.x * 0.6
	var max_w := maxf(220.0, cw * 0.62)
	if l.get_minimum_size().x > max_w:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = max_w
	pc.add_child(l)
	col.add_child(pc)
	var ts := UI.label(_stamp(), 10, UI.MUTED)
	if mine:
		ts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ts.text += "  ✓✓"
	col.add_child(ts)
	row.add_child(col)
	_chat.add_child(row)
	return row

var _stamp_i := 0

## Fake but steady evening timestamps so the thread reads like a phone chat.
func _stamp() -> String:
	_stamp_i += 1
	var m := 21 * 60 + 4 + _stamp_i * 2
	return "%02d:%02d" % [(m / 60) % 24, m % 60]

## Round face with an optional green "online" dot.
func _avatar(id: String, sz: int, online: bool) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(sz, sz)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip := Panel.new()
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_theme_stylebox_override("panel", UI.style(Color.BLACK, Color("#c98be8"), sz / 2, 2, 0))
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(clip)
	var f := UI.tex_rect(DB.face(id), Vector2.ZERO, true)
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_child(f)
	if online:
		var d := Control.new()
		d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.draw.connect(func():
			var c := Vector2(sz - 7, sz - 7)
			d.draw_circle(c, 7.0, Color(0.08, 0.05, 0.13))
			d.draw_circle(c, 5.0, UI.GREEN))
		holder.add_child(d)
	return holder

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
	var typing := _bubble("•  •  •", false)
	typing.modulate = Color(1, 1, 1, 0.7)
	var ttw := typing.create_tween().set_loops()
	ttw.tween_property(typing, "modulate:a", 0.35, 0.3)
	ttw.tween_property(typing, "modulate:a", 0.8, 0.3)
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
