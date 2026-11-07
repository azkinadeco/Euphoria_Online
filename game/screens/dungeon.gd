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
		var did: String = d["id"]
		var btn := Button.new()
		btn.theme_type_variation = "TabButton"
		btn.toggle_mode = true
		btn.button_pressed = did == _sel
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 92)
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): Game.sfx("ui_click"); _sel = did; _render())
		var h := UI.hbox(10)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 10
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(h)
		var ic := UI.tex_rect(DB.icon(d["icon"]), Vector2(56, 56))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
		var v := UI.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(UI.label(d["name"], 18, Color.WHITE, 3))
		var tries := Game.dungeon_tries(did)
		v.add_child(UI.label("Attempts %d/%d" % [tries, DB.DUNGEON_TRIES], 13, UI.GREEN if tries > 0 else UI.MUTED, 2))
		h.add_child(v)
		_list.add_child(btn)
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
		var p := UI.panel("CardPanel")
		_right.add_child(p)
		var h := UI.hbox(12)
		p.add_child(h)
		var fv := UI.hbox(3)
		for e in st["enemies"].slice(0, 3):
			var fp := UI.styled_panel(Color.BLACK, Color("#ff5c6c") if e.get("boss", false) else Color("#6b4a7e"), 6, 2, 1)
			fp.add_child(UI.tex_rect(DB.face(e["id"]), Vector2(40, 40), true))
			fv.add_child(fp)
		h.add_child(fv)
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label("Level %d  •  Enemy Lv.%d  •  Power %s%s" % [diff + 1, st["level"], Game.fmt(Game.enemy_power(st["enemies"])), "  ✔" if cleared else ""], 15, Color.WHITE if unlocked else UI.MUTED, 2))
		v.add_child(UI.reward_row(st["rewards"], 24, 13))
		h.add_child(v)
		if not unlocked:
			h.add_child(UI.label("Clear Lv.%d first" % diff, 13, UI.MUTED))
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
