extends Screen
## Season Pass: 30 levels, free + premium reward tracks.

var _track: HBoxContainer
var _info: VBoxContainer
var _scroll: ScrollContainer

func build() -> void:
	set_bg("galaxy", 0.5)
	var bar := header("SEASON PASS", ["gems"])
	bar.add_child(UI.button("CLAIM ALL", func():
		var r := Game.claim_all_pass()
		if r.is_empty():
			main.toast("Nothing to claim yet. Play stages, dungeons and missions to earn Pass EXP!")
		else:
			main.show_rewards("PASS REWARDS", r)
		_render(), "GoldButton", Vector2(170, 46)))
	var b := body(76)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var top := UI.panel()
	v.add_child(top)
	_info = UI.vbox(6)
	top.add_child(_info)
	var tp := UI.panel()
	tp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(tp)
	var row := UI.hbox(10)
	tp.add_child(row)
	var labels := UI.vbox(10)
	labels.custom_minimum_size = Vector2(110, 0)
	row.add_child(labels)
	labels.add_child(UI.spacer(false))
	var fl := UI.label("FREE", 18, Color("#9fd0ff"), 3)
	fl.custom_minimum_size = Vector2(0, 120)
	fl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	labels.add_child(fl)
	var pl := UI.label("PREMIUM", 18, UI.GOLD, 3)
	pl.custom_minimum_size = Vector2(0, 120)
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	labels.add_child(pl)
	labels.add_child(UI.spacer(false))
	_track = UI.hbox(8)
	_scroll = UI.scroll(_track, true)
	row.add_child(_scroll)
	_render()
	_scroll_to_current.call_deferred()

func _scroll_to_current() -> void:
	_scroll.scroll_horizontal = maxi(0, (Game.pass_level() - 2) * 128)

func _render() -> void:
	for c in _info.get_children():
		c.queue_free()
	var lv := Game.pass_level()
	var h := UI.hbox(14)
	_info.add_child(h)
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	tv.add_child(UI.label("CURRENT SEASON  •  PASS Lv.%d / %d" % [lv, DB.PASS_LEVELS], 22, UI.GOLD, 4))
	var into := int(Game.s["pass"]["exp"]) - lv * DB.PASS_EXP_PER_LV
	if lv < DB.PASS_LEVELS:
		tv.add_child(UI.bar(into, DB.PASS_EXP_PER_LV, "GoldBar", 10))
		tv.add_child(UI.label("%d / %d EXP to next level   •   Ends in %d days" % [into, DB.PASS_EXP_PER_LV, maxi(0, Game.pass_ends_in()) / 86400], 13, UI.MUTED))
	tv.add_child(UI.label("Earn Pass EXP: stages +15, dungeons/arena +25, guild/AFK +20, summons +10, missions +60", 12, UI.MUTED))
	if bool(Game.s["pass"]["premium"]):
		h.add_child(UI.label("PREMIUM ACTIVE ✔", 18, UI.GREEN, 3))
	else:
		h.add_child(UI.button("UNLOCK PREMIUM\n%d Gems" % DB.PASS_PRICE, func():
			main.confirm("Unlock the Premium track for %d Gems? All premium rewards up to your current level become claimable." % DB.PASS_PRICE, func():
				var err := Game.buy_premium_pass()
				if err != "":
					main.toast(err, UI.RED)
				else:
					Game.sfx("awakening")
					main.toast("Premium Pass unlocked!", UI.GOLD)
				_render(), "UNLOCK"), "GoldButton", Vector2(220, 70)))

	for c in _track.get_children():
		c.queue_free()
	for i in range(1, DB.PASS_LEVELS + 1):
		var col := UI.vbox(10)
		col.custom_minimum_size = Vector2(120, 0)
		var ll := UI.label("Lv.%d" % i, 15, UI.GOLD if i <= lv else UI.MUTED, 3)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(ll)
		col.add_child(_cell(i, false))
		col.add_child(_cell(i, true))
		_track.add_child(col)
	UI.stagger(_track, 0.02)

func _cell(lv: int, premium: bool) -> Control:
	var r := DB.pass_reward(lv, premium)
	var key := "prem" if premium else "free"
	var claimed: bool = Game.s["pass"][key].has(lv)
	var reached := lv <= Game.pass_level()
	var unlocked := reached and (not premium or bool(Game.s["pass"]["premium"]))
	var border := UI.GREEN if unlocked and not claimed else (UI.GOLD if premium else Color("#5b7bd0"))
	var btn := Button.new()
	btn.theme_type_variation = "FlatButton"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(120, 120)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UI.style(Color(0.1, 0.06, 0.18, 0.95) if not premium else Color(0.2, 0.12, 0.05, 0.95), border, 10, 3 if unlocked and not claimed else 1, 0))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(p)
	var v := UI.vbox(2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(v)
	for k in r.keys():
		var ic := UI.tex_rect(Game.reward_icon(k), Vector2(0, 34))
		if claimed:
			ic.modulate = Color(1, 1, 1, 0.3)
		v.add_child(ic)
		var al := UI.label("x" + Game.fmt(int(r[k])), 12, Color.WHITE, 3)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(al)
	var st := UI.label("CLAIMED" if claimed else ("CLAIM!" if unlocked else ("LOCKED" if premium and reached else "")), 11, UI.GREEN if unlocked else UI.MUTED, 3)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	btn.pressed.connect(func():
		var got := Game.claim_pass(lv, premium)
		if not got.is_empty():
			Game.sfx("star_up")
			main.show_rewards("PASS Lv.%d" % lv, got)
			_render()
		elif premium and not bool(Game.s["pass"]["premium"]):
			main.toast("Unlock Premium to claim this reward.", UI.GOLD))
	return btn
