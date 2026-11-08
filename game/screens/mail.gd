extends Screen
## Mailbox with attached rewards: inbox list on the left, the open letter on the right.

var _list: VBoxContainer
var _view: VBoxContainer
var _sel := ""
var _all_btn: Button
var _count_l: Label

## Per-mail flavour: [tag, tag colour, sender, icon, date]
const META := {
	"xmas_hyeonxa": ["EVENT", "#ff5a6e", "Euphoria Team", "icon_live_ops", "Nov 8"],
	"heroes_nov8": ["UPDATE", "#5fb8ff", "Euphoria Team", "icon_gacha", "Nov 8"],
	"skins_nov5": ["EVENT", "#ff6fae", "Lulu • Wardrobe", "item_skin_ticket", "Nov 5"],
	"nov2026": ["UPDATE", "#5fb8ff", "Euphoria Team", "icon_gacha", "Nov 1"],
	"welcome": ["GIFT", "#ffcf5a", "Euphoria Team", "icon_gem", "Day 1"],
	"patch_v2": ["UPDATE", "#5fb8ff", "Euphoria Team", "icon_live_ops", "Oct 20"],
	"bond_event": ["EVENT", "#ff6fae", "Festival Committee", "icon_heart", "Oct 14"],
}

func build() -> void:
	set_bg("lobby", 0.7)
	var bar := header("MAILBOX", ["gold", "gems"])
	_all_btn = UI.button("CLAIM ALL", _claim_all, "GoldButton", Vector2(190, 46))
	bar.add_child(_all_btn)
	var b := body(76)
	var lp := UI.panel()
	lp.anchor_right = 0.4
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	var top := UI.hbox(8)
	lv.add_child(top)
	top.add_child(UI.tex_rect(DB.icon("icon_mail"), Vector2(28, 28)))
	top.add_child(UI.label("INBOX", 17, UI.GOLD, 3))
	_count_l = UI.label("", 13, UI.MUTED, 2)
	_count_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_count_l)
	_list = UI.vbox(6)
	lv.add_child(UI.scroll(_list))
	lv.add_child(UI.label("Mail with gifts stays here until you claim it.", 11, UI.MUTED, 0))
	var rp := UI.styled_panel(Color(0.97, 0.94, 0.9, 0.97), Color("#d9b26a"), 14, 2, 22.0)
	rp.anchor_left = 0.42
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	_view = UI.vbox(10)
	rp.add_child(_view)
	_sel = str(params.get("mail", ""))
	if _sel == "":
		for m in DB.MAIL:
			if not _claimed(m["id"]):
				_sel = m["id"]
				break
		if _sel == "" and not DB.MAIL.is_empty():
			_sel = DB.MAIL[0]["id"]
	_render()
	UI.stagger(_list, 0.04)

func _claimed(id: String) -> bool:
	return Game.s["mail_claimed"].has(id)

func _meta(id: String) -> Array:
	return META.get(id, ["NOTICE", "#c9a6ff", "Euphoria Team", "icon_mail", ""])

func _render() -> void:
	for c in _list.get_children():
		c.queue_free()
	var unread := Game.mail_unclaimed()
	_count_l.text = "%d unclaimed  •  %d total" % [unread, DB.MAIL.size()]
	_all_btn.text = "CLAIM ALL (%d)" % unread if unread > 0 else "ALL CLAIMED"
	_all_btn.disabled = unread == 0
	for m in DB.MAIL:
		_list.add_child(_row(m))
	_render_view()

func _row(m: Dictionary) -> Control:
	var id: String = m["id"]
	var done := _claimed(id)
	var sel := id == _sel
	var mt := _meta(id)
	var btn := Button.new()
	btn.theme_type_variation = "FlatButton"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 72)
	var fr := PanelContainer.new()
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.add_theme_stylebox_override("panel", UI.style(Color(0.25, 0.18, 0.08, 0.9) if sel else (Color(0.1, 0.07, 0.16, 0.9) if not done else Color(0.06, 0.05, 0.09, 0.8)), UI.GOLD if sel else Color(1, 1, 1, 0.1), 10, 2 if sel else 1, 8))
	btn.add_child(fr)
	var h := UI.hbox(10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.add_child(h)
	var ic := UI.tex_rect(DB.icon(mt[3]), Vector2(44, 44))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if done:
		ic.modulate = Color(0.5, 0.5, 0.55)
	h.add_child(ic)
	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var t := UI.label(m["title"], 15, Color.WHITE if not done else UI.MUTED, 2)
	t.clip_text = true
	v.add_child(t)
	var sub := UI.hbox(6)
	v.add_child(sub)
	var tc := Color(mt[1])
	sub.add_child(UI.label(mt[0], 10, tc if not done else UI.MUTED, 1))
	sub.add_child(UI.label("%s  •  %s" % [mt[2], mt[4]], 11, UI.MUTED, 0))
	var right := UI.vbox(2)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right)
	if done:
		right.add_child(UI.label("✓", 16, UI.GREEN, 2))
	else:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.add_theme_stylebox_override("panel", UI.style(Color("#ff5c6c"), Color.TRANSPARENT, 5, 0, 0))
		right.add_child(dot)
		right.add_child(UI.label("🎁 %d" % (m["give"] as Dictionary).size(), 11, UI.GOLD, 0))
	btn.pressed.connect(func():
		Game.sfx("ui_click")
		_sel = id
		params["mail"] = id
		_render())
	UI.hover_fx(btn, 1.015)
	return btn

func _render_view() -> void:
	for c in _view.get_children():
		c.queue_free()
	var m: Dictionary = {}
	for x in DB.MAIL:
		if x["id"] == _sel:
			m = x
	if m.is_empty():
		_view.add_child(UI.label("No mail selected.", 16, Color("#5a4a3a")))
		return
	var ink := Color("#3a2a1e")
	var mt := _meta(_sel)
	var done := _claimed(_sel)
	var head := UI.hbox(10)
	_view.add_child(head)
	var tag := UI.styled_panel(Color(Color(mt[1]), 0.25), Color(mt[1]), 8, 1, 3.0)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_child(UI.label(" %s " % mt[0], 11, Color(mt[1]).darkened(0.35), 0))
	head.add_child(tag)
	var dl := UI.label(mt[4], 12, Color("#8a7660"), 0)
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(dl)
	var title := UI.wrap_label(m["title"], 24, ink)
	_view.add_child(title)
	var from := UI.hbox(8)
	from.add_child(UI.tex_rect(DB.icon(mt[3]), Vector2(26, 26)))
	from.add_child(UI.label("From: %s" % mt[2], 13, Color("#6a5640"), 0))
	_view.add_child(from)
	var line := ColorRect.new()
	line.color = Color("#d9b26a", 0.6)
	line.custom_minimum_size = Vector2(0, 2)
	_view.add_child(line)
	var body := UI.wrap_label("Dear Commander,\n\n" + str(m["body"]), 15, ink)
	_view.add_child(body)
	_view.add_child(UI.spacer(false))
	var att := UI.label("ATTACHMENTS", 13, Color("#a07a2a"), 0)
	_view.add_child(att)
	var gp := UI.styled_panel(Color(0.2, 0.13, 0.25, 0.92), Color("#d9b26a", 0.7), 12, 1, 10.0)
	_view.add_child(gp)
	var rr := UI.reward_row(m["give"], 44, 15)
	rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if done:
		gp.modulate = Color(0.6, 0.6, 0.62)
	gp.add_child(rr)
	var id: String = _sel
	if done:
		var cl := UI.label("✓  Rewards claimed", 16, Color("#3a9a5a"), 0)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_view.add_child(cl)
	else:
		var cb := UI.button("CLAIM REWARDS", func():
			var r := Game.claim_mail(id)
			if not r.is_empty():
				Game.sfx("star_up")
				main.show_rewards("MAIL REWARDS", r)
			_next_unclaimed()
			_render(), "GoldButton", Vector2(0, 54))
		_view.add_child(cb)
		var tw := cb.create_tween().set_loops()
		tw.tween_property(cb, "modulate", Color(1.15, 1.12, 1.05), 0.7)
		tw.tween_property(cb, "modulate", Color.WHITE, 0.7)
	_view.modulate.a = 0.0
	_view.create_tween().tween_property(_view, "modulate:a", 1.0, 0.2)

func _next_unclaimed() -> void:
	for m in DB.MAIL:
		if not _claimed(m["id"]):
			_sel = m["id"]
			params["mail"] = _sel
			return

func _claim_all() -> void:
	var total := {}
	for m in DB.MAIL:
		var r := Game.claim_mail(m["id"])
		for k in r.keys():
			total[k] = int(total.get(k, 0)) + int(r[k])
	if total.is_empty():
		main.toast("No new mail.")
	else:
		Game.sfx("star_up")
		main.show_rewards("MAIL REWARDS", total)
	_render()
