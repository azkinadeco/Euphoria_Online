extends Screen
## Mailbox with attached rewards.

var _list: VBoxContainer

func build() -> void:
	set_bg("lobby", 0.7)
	var bar := header("MAILBOX", ["gold", "gems"])
	bar.add_child(UI.button("CLAIM ALL", _claim_all, "GoldButton", Vector2(170, 46)))
	var b := body(76)
	_list = UI.vbox(10)
	var sc := UI.scroll(_list)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(sc)
	_render()

func _render() -> void:
	for c in _list.get_children():
		c.queue_free()
	for m in DB.MAIL:
		var claimed: bool = Game.s["mail_claimed"].has(m["id"])
		var p := UI.panel("CardPanel")
		_list.add_child(p)
		var h := UI.hbox(14)
		p.add_child(h)
		h.add_child(UI.tex_rect(DB.icon("icon_mail"), Vector2(56, 56)))
		var v := UI.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(m["title"], 19, Color.WHITE if not claimed else UI.MUTED, 2))
		v.add_child(UI.wrap_label(m["body"], 14, UI.MUTED))
		v.add_child(UI.reward_row(m["give"], 28, 14))
		var mid: String = m["id"]
		var btn := UI.button("CLAIMED" if claimed else "CLAIM", func():
			var r := Game.claim_mail(mid)
			if not r.is_empty():
				main.show_rewards("MAIL REWARDS", r)
			_render(), "" if claimed else "GoldButton", Vector2(140, 48))
		btn.disabled = claimed
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(btn)
	UI.stagger(_list, 0.06)

func _claim_all() -> void:
	var total := {}
	for m in DB.MAIL:
		var r := Game.claim_mail(m["id"])
		for k in r.keys():
			total[k] = int(total.get(k, 0)) + int(r[k])
	if total.is_empty():
		main.toast("No new mail.")
	else:
		main.show_rewards("MAIL REWARDS", total)
	_render()
