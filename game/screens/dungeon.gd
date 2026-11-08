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
	rp.add_child(UI.scroll(_right))
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
	_right.add_child(UI.label(d["name"].to_upper(), 24, UI.GOLD, 4))
	_right.add_child(UI.wrap_label(d["desc"] + " No energy needed. Failed attempts are refunded.", 14, UI.MUTED))
	if _sel == "gear":
		var ts: Dictionary = DB.GEAR_SETS[DB.armory_set(Game.day_key())]
		_right.add_child(UI.label("TODAY'S SET  ◆ %s  —  every clear drops one guaranteed piece" % ts["name"], 14, Color(str(ts["color"])), 2))
	for diff in DB.DUNGEON_LEVELS.size():
		var di: int = diff
		var st := DB.dungeon_stage(_sel, diff)
		var unlocked := Game.dungeon_unlocked(_sel, diff)
		var cleared := diff <= Game.dungeon_cleared(_sel)
		var ep := Game.enemy_power(st["enemies"])
		var ratio := float(Game.team_power()) / maxf(1.0, float(ep))
		var verdict := "FAVORED" if ratio >= 1.15 else ("EVEN" if ratio >= 0.9 else ("RISKY" if ratio >= 0.7 else "DEADLY"))
		var vcol: Color = UI.GREEN if ratio >= 1.15 else (UI.GOLD if ratio >= 0.9 else (Color("#ffa04a") if ratio >= 0.7 else UI.RED))
		var bc := Color(UI.GREEN, 0.5) if cleared else (Color(UI.GOLD, 0.6) if unlocked else Color(1, 1, 1, 0.1))
		var p := UI.styled_panel(Color(0.11, 0.08, 0.17, 0.92) if unlocked else Color(0.08, 0.07, 0.11, 0.85), bc, 12, 1, 8.0)
		_right.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		# difficulty medallion
		var med := Control.new()
		med.custom_minimum_size = Vector2(52, 52)
		med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var mcol: Color = UI.GREEN if cleared else (UI.GOLD if unlocked else UI.MUTED)
		med.draw.connect(func():
			var c := Vector2(26, 26)
			med.draw_circle(c, 24.0, Color(0.06, 0.04, 0.1))
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
		tr.add_child(UI.label("Power %s" % Game.fmt(ep), 13, UI.MUTED))
		if unlocked:
			var vp := UI.styled_panel(Color(vcol, 0.15), Color(vcol, 0.6), 8, 1, 5.0)
			vp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			vp.add_child(UI.label(verdict, 10, vcol, 1))
			vp.tooltip_text = "Your team power %s vs %s" % [Game.fmt(Game.team_power()), Game.fmt(ep)]
			tr.add_child(vp)
		v.add_child(tr)
		v.add_child(UI.reward_row(st["rewards"], 24, 13))
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
