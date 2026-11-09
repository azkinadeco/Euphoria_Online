extends Screen
## Daily Dungeons: Gold / EXP / Gear with 5 difficulties and 3 attempts per day.

var _sel := "gold"
var _list: VBoxContainer
var _right: VBoxContainer
var _bg_rect: TextureRect

func build() -> void:
	_sel = str(params.get("dungeon", "gold"))
	set_bg(DB.dungeon_def(_sel)["bg"], 0.5)
	_bg_rect = get_child(0) as TextureRect
	header("DAILY DUNGEON", ["gold", "gems", "hero_exp"])
	var b := body(76)
	_list = UI.vbox(10)
	_list.anchor_right = 0.3
	_list.anchor_bottom = 1.0
	b.add_child(_list)
	var rp := UI.panel()
	rp.anchor_left = 0.32
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	_right = UI.vbox(8)
	var sc := UI.scroll(_right)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rp.add_child(sc)
	_render()
	tutorial("dungeon")

func refresh() -> void:
	super.refresh()

func _render() -> void:
	_bg_rect.texture = DB.bg(DB.dungeon_def(_sel)["bg"])
	params["dungeon"] = _sel
	for c in _list.get_children():
		c.queue_free()
	for d in DB.DUNGEONS:
		_list.add_child(_tile(d))
	UI.stagger(_list, 0.06)

	for c in _right.get_children():
		c.queue_free()
	var d: Dictionary = DB.dungeon_def(_sel)
	_right.add_child(_banner(d))
	# the tier to play next: the highest unlocked one, or the best cleared one when all are done
	var rec := mini(Game.dungeon_cleared(_sel) + 1, DB.DUNGEON_LEVELS.size() - 1)
	for diff in DB.DUNGEON_LEVELS.size():
		var di: int = diff
		var st := DB.dungeon_stage(_sel, diff)
		var unlocked := Game.dungeon_unlocked(_sel, diff)
		var cleared := diff <= Game.dungeon_cleared(_sel)
		var ep := Game.enemy_power(st["enemies"])
		var ratio := float(Game.team_power()) / maxf(1.0, float(ep))
		var verdict := "FAVORED" if ratio >= 1.15 else ("EVEN" if ratio >= 0.9 else ("RISKY" if ratio >= 0.7 else "DEADLY"))
		var vcol: Color = UI.GREEN if ratio >= 1.15 else (UI.GOLD if ratio >= 0.9 else (Color("#ffa04a") if ratio >= 0.7 else UI.RED))
		var is_rec := diff == rec and unlocked
		var bc := Color(UI.GOLD, 0.95) if is_rec else (Color(UI.GREEN, 0.5) if cleared else (Color(UI.GOLD, 0.6) if unlocked else Color(1, 1, 1, 0.1)))
		var p := UI.styled_panel(Color(0.16, 0.11, 0.2, 0.95) if is_rec else (Color(0.11, 0.08, 0.17, 0.92) if unlocked else Color(0.08, 0.07, 0.11, 0.85)), bc, 12, 2 if is_rec else 1, 8.0)
		_right.add_child(p)
		if is_rec:
			var pulse := p.create_tween().set_loops()
			pulse.tween_property(p, "self_modulate", Color(1.15, 1.08, 0.9), 0.8).set_trans(Tween.TRANS_SINE)
			pulse.tween_property(p, "self_modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)
		var h := UI.hbox(12)
		p.add_child(h)
		# difficulty medallion
		var med := Control.new()
		med.custom_minimum_size = Vector2(52, 52)
		med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var mcol: Color = UI.GOLD if is_rec else (UI.GREEN if cleared else (UI.GOLD if unlocked else UI.MUTED))
		med.draw.connect(func():
			var c := Vector2(26, 26)
			med.draw_circle(c, 24.0, Color(0.06, 0.04, 0.1))
			if is_rec:
				med.draw_circle(c, 24.0, Color(UI.GOLD, 0.22))
				med.draw_arc(c, 25.5, 0.0, TAU, 40, Color(UI.GOLD, 0.45), 1.5, true)
			med.draw_arc(c, 23.0, 0.0, TAU, 40, mcol, 2.0, true)
			med.draw_string(ThemeDB.fallback_font, Vector2(0, 33), "✔" if cleared else str(di + 1), HORIZONTAL_ALIGNMENT_CENTER, 52, 20, mcol))
		h.add_child(med)
		var fv := UI.hbox(3)
		fv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for e in st["enemies"].slice(0, 3):
			var fp := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if e.get("boss", false) else Color("#6b4a7e"), 6, 2, 1)
			var ft := UI.tex_rect(DB.face(e["id"]), Vector2(40, 40), true)
			if not unlocked:
				ft.modulate = Color(0.3, 0.3, 0.35)
			fp.add_child(ft)
			fp.tooltip_text = DB.name_of(e["id"])
			fv.add_child(fp)
		h.add_child(fv)
		var v := UI.vbox(3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tr := UI.hbox(8)
		tr.add_child(UI.label("Enemy Lv.%d" % st["level"], 15, Color.WHITE if unlocked else UI.MUTED, 2))
		tr.add_child(UI.label("⚔ %s" % Game.fmt(ep), 13, UI.MUTED))
		if unlocked:
			var vp := UI.styled_panel(Color(vcol, 0.15), Color(vcol, 0.6), 8, 1, 5.0)
			vp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			vp.add_child(UI.label(verdict, 10, vcol, 1))
			vp.tooltip_text = "Your team power %s vs %s" % [Game.fmt(Game.team_power()), Game.fmt(ep)]
			tr.add_child(vp)
		v.add_child(tr)
		var rr := UI.hbox(10)
		var rw := UI.reward_row(st["rewards"], 24, 13)
		rw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rr.add_child(rw)
		if unlocked:
			var mine := Game.team_power()
			var cmp := UI.bar(mine, mine + ep, "", 6)
			cmp.custom_minimum_size = Vector2(90, 6)
			cmp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cmp.add_theme_stylebox_override("fill", UI.style(Color("#6fd3ff"), Color.TRANSPARENT, 3, 0, 0))
			cmp.add_theme_stylebox_override("background", UI.style(Color(vcol, 0.55), Color.TRANSPARENT, 3, 0, 0))
			cmp.tooltip_text = "Blue = your team power %s, colored = enemy power %s" % [Game.fmt(mine), Game.fmt(ep)]
			cmp.mouse_filter = Control.MOUSE_FILTER_PASS
			rr.add_child(cmp)
		v.add_child(rr)
		h.add_child(v)
		if not unlocked:
			var ll := UI.label("Clear Lv.%d first" % diff, 13, UI.MUTED)
			ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(ll)
			continue
		var bb := UI.button("BATTLE", func(): main.go("formation", {"mode": "dungeon", "dungeon": _sel, "diff": di}), "GoldButton", Vector2(110, 44))
		bb.disabled = Game.dungeon_tries(_sel) <= 0
		h.add_child(bb)
		var sb := UI.button("SWEEP", func():
			var r := Game.sweep_dungeon(_sel, di)
			if r.has("error"):
				main.toast(r["error"], UI.RED)
			else:
				main.show_rewards("SWEEP COMPLETE", r)
			_render(), "", Vector2(96, 44))
		sb.disabled = not cleared or Game.dungeon_tries(_sel) <= 0
		h.add_child(sb)


## Dungeon picker tile: scenery banner, icon, name, reward type and attempt pips.
func _tile(d: Dictionary) -> Control:
	var did: String = d["id"]
	var on := did == _sel
	var tries := Game.dungeon_tries(did)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 110)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.clip_contents = true
	var sb := UI.style(Color(0, 0, 0, 0), UI.GOLD if on else Color(1, 1, 1, 0.15), 12, 3 if on else 1, 0)
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, sb)
	btn.pressed.connect(func(): Game.sfx("ui_click"); _sel = did; _render())
	var img := UI.tex_rect(DB.bg(d["bg"]), Vector2.ZERO, true)
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.modulate = Color(1, 1, 1) if on else Color(0.55, 0.55, 0.62)
	btn.add_child(img)
	var shade := Control.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(func():
		var sz := shade.size
		var dk := Color(0.04, 0.02, 0.08, 0.88)
		var cl := Color(0.04, 0.02, 0.08, 0.1)
		shade.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(sz.x, 0), sz, Vector2(0, sz.y)]), PackedColorArray([dk, cl, cl, dk])))
	btn.add_child(shade)
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", sb)
	frame.z_index = 1
	var h := UI.hbox(10)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(h)
	var ic := UI.tex_rect(DB.icon(d["icon"]), Vector2(54, 54))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := UI.vbox(2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UI.label(d["name"], 18, UI.GOLD if on else Color.WHITE, 3))
	var kind := {"gold": "Gold", "exp": "Hero EXP & Potions", "gear": "Gear & Chests"}
	v.add_child(UI.label(str(kind.get(did, "")), 12, UI.TEXT, 2))
	var pr := UI.hbox(6)
	var pips := Control.new()
	pips.custom_minimum_size = Vector2(DB.DUNGEON_TRIES * 14, 14)
	pips.draw.connect(func():
		for i in DB.DUNGEON_TRIES:
			var c := Vector2(6 + i * 14, 7)
			if i < tries:
				pips.draw_circle(c, 5.0, UI.GREEN)
			else:
				pips.draw_arc(c, 4.5, 0.0, TAU, 16, Color(1, 1, 1, 0.3), 1.5, true))
	pr.add_child(pips)
	var best := Game.dungeon_cleared(did)
	pr.add_child(UI.label("Best Lv.%d" % (best + 1) if best >= 0 else "Not cleared", 11, UI.MUTED, 1))
	v.add_child(pr)
	h.add_child(v)
	btn.add_child(frame)
	return btn


## Header banner: the dungeon's guardian (its boss) on the right, name, blurb, attempts and best clear.
func _banner(d: Dictionary) -> Control:
	var did: String = d["id"]
	var boss: String = d["pool"][-1]
	var acc: Color = {"gold": Color("#ffd479"), "exp": Color("#8fd8ff"), "gear": Color("#ff8a5c")}.get(did, UI.GOLD)
	var box := Control.new()
	box.custom_minimum_size = Vector2(0, 150)
	box.clip_contents = true
	var bg := UI.tex_rect(DB.bg(d["bg"]), Vector2.ZERO, true)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.55, 0.5, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bg)
	# guardian art, anchored right, cut at the waist
	var gclip := Control.new()
	gclip.clip_contents = true
	gclip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gclip.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	gclip.offset_left = -260
	box.add_child(gclip)
	var glow := Control.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.draw.connect(func():
		var c := Vector2(glow.size.x * 0.55, glow.size.y * 0.55)
		for i in 6:
			glow.draw_circle(c, 120.0 - i * 18.0, Color(acc, 0.05)))
	gclip.add_child(glow)
	var art := UI.tex_rect(DB.art(boss), Vector2.ZERO, true)
	art.position = Vector2(20, -6)
	art.size = Vector2(240, 330)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gclip.add_child(art)
	var bob := art.create_tween().set_loops()
	bob.tween_property(art, "position:y", 2.0, 1.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(art, "position:y", -6.0, 1.6).set_trans(Tween.TRANS_SINE)
	# left-to-right shade so the text stays readable
	var shade := Control.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(func():
		var sz := shade.size
		var dk := Color(0.05, 0.02, 0.09, 0.95)
		var mid := Color(0.05, 0.02, 0.09, 0.55)
		var cl := Color(0.05, 0.02, 0.09, 0.0)
		var x1 := sz.x * 0.42
		var x2 := sz.x - 200.0
		shade.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(x1, 0), Vector2(x1, sz.y), Vector2(0, sz.y)]), PackedColorArray([dk, mid, mid, dk]))
		shade.draw_polygon(PackedVector2Array([Vector2(x1, 0), Vector2(x2, 0), Vector2(x2, sz.y), Vector2(x1, sz.y)]), PackedColorArray([mid, cl, cl, mid]))
		shade.draw_rect(Rect2(0, sz.y - 3, sz.x, 3), Color(acc, 0.8)))
	box.add_child(shade)
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, Color(acc, 0.6), 12, 1, 0))
	box.add_child(frame)
	var v := UI.vbox(4)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_right = -230
	v.offset_top = 12
	v.offset_bottom = -12
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	var th := UI.hbox(8)
	th.add_child(UI.tex_rect(DB.icon(d["icon"]), Vector2(30, 30)))
	th.add_child(UI.label(str(d["name"]).to_upper(), 24, acc, 4))
	v.add_child(th)
	v.add_child(UI.wrap_label(str(d["desc"]) + " No energy needed. Failed attempts are refunded.", 13, UI.TEXT))
	if did == "gear":
		var ts: Dictionary = DB.GEAR_SETS[DB.armory_set(Game.day_key())]
		v.add_child(UI.label("TODAY'S SET  ◆ %s  —  every clear drops one piece" % ts["name"], 13, Color(str(ts["color"])), 2))
	var info := UI.hbox(14)
	v.add_child(info)
	var tries := Game.dungeon_tries(did)
	var tchip := UI.styled_panel(Color(0, 0, 0, 0.45), Color(UI.GREEN if tries > 0 else UI.RED, 0.6), 10, 1, 0)
	var tl := UI.hbox(6)
	tchip.add_child(UI.margin(tl, 10, 3, 10, 3))
	tl.add_child(UI.label("ATTEMPTS", 11, UI.MUTED, 1))
	for i in DB.DUNGEON_TRIES:
		var pip := UI.styled_panel(UI.GREEN if i < tries else Color(1, 1, 1, 0.08), Color(UI.GREEN, 0.7), 4, 1, 0)
		pip.custom_minimum_size = Vector2(14, 14)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tl.add_child(pip)
	info.add_child(tchip)
	var best := Game.dungeon_cleared(did)
	var bchip := UI.styled_panel(Color(0, 0, 0, 0.45), Color(acc, 0.5), 10, 1, 0)
	bchip.add_child(UI.margin(UI.label(("BEST  Lv.%d / %d" % [best + 1, DB.DUNGEON_LEVELS.size()]) if best >= 0 else "BEST  —", 12, acc, 2), 10, 3, 10, 3))
	info.add_child(bchip)
	var gname := UI.label("GUARDIAN  •  " + DB.name_of(boss), 11, Color(1, 1, 1, 0.75), 2)
	gname.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	gname.offset_left = -240
	gname.offset_top = -26
	gname.offset_right = -12
	gname.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(gname)
	return box
