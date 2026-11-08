extends Screen
## Missions: tab cards + summary on the left, grouped mission list on the right.

var _list: VBoxContainer
var _side: VBoxContainer
var _tab := "DAILY"
var _t := 0.0
var _timer: Label

const TABS := {
	"DAILY": ["icon_quest", "#5fb8ff", "Resets every day at 00:00 (UTC+7)"],
	"WEEKLY": ["icon_pass", "#b98cff", "Bigger rewards for steady play"],
	"ACHIEVEMENTS": ["icon_codex", "#ffd479", "Milestones that never reset"],
	"COMMANDER ROAD": ["icon_crystal", "#7fe0b0", "Rewards every 5 Commander levels"],
}

func build() -> void:
	set_bg("lobby", 0.7)
	header("MISSIONS", ["gold", "gems"])
	_tab = str(params.get("tab", _tab))
	var b := body(76)
	var left := UI.panel()
	left.anchor_right = 0.29
	left.anchor_bottom = 1.0
	b.add_child(left)
	_side = UI.vbox(8)
	left.add_child(UI.scroll(_side))
	var right := Control.new()
	right.anchor_left = 0.3
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	b.add_child(right)
	_list = UI.vbox(8)
	var sc := UI.scroll(_list)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right.add_child(sc)
	_render()

func refresh() -> void:
	super.refresh()

func _process(delta: float) -> void:
	_t += delta
	if _t > 1.0:
		_t = 0.0
		_update_timer()

func _reset_in() -> int:
	match _tab:
		"DAILY": return (Game.day_key() + 1) * 86400 - 7 * 3600 - Game.now()
		"WEEKLY": return Game.weekly_ends_in()
	return -1

func _update_timer() -> void:
	if not is_instance_valid(_timer):
		return
	var s := _reset_in()
	if s < 0:
		_timer.text = ""
		return
	_timer.text = ("Resets in %dd %02dh %02dm" % [s / 86400, (s / 3600) % 24, (s / 60) % 60]) if s >= 86400 else ("Resets in %02dh %02dm %02ds" % [s / 3600, (s / 60) % 60, s % 60])

## [title, prog, target, give, state, claim, go] rows for a tab.
func _rows_of(tab: String) -> Array:
	var out: Array = []
	match tab:
		"WEEKLY":
			for q in DB.WEEKLY_QUESTS:
				var prog := mini(int(Game.s["weekly"]["progress"].get(q["id"], 0)), int(q["target"]))
				out.append([q["name"], prog, int(q["target"]), q["give"], Game.weekly_state(q), func(): return Game.claim_weekly(q), str(DB.QUEST_ROUTE.get(q["src"], ""))])
		"COMMANDER ROAD":
			var plv := int(Game.s["player"]["level"])
			for lv in DB.road_levels():
				var l2: int = lv
				out.append(["Reach Commander Lv.%d%s" % [l2, "  ★ GRAND" if l2 % 25 == 0 else ""], mini(plv, l2), l2, DB.road_reward(l2), Game.road_state(l2), func(): return Game.claim_road(l2), "road"])
		"DAILY":
			for q in DB.DAILY_QUESTS:
				var prog := mini(int(Game.s["quests"]["progress"].get(q["id"], 0)), int(q["target"]))
				out.append([q["name"], prog, int(q["target"]), q["give"], Game.quest_state(q), func(): return Game.claim_quest(q), str(DB.QUEST_ROUTE.get(q["id"], ""))])
		_:
			for a in DB.ACHIEVEMENTS:
				var prog := mini(Game.stat_value(a["stat"]), int(a["target"]))
				out.append([a["name"], prog, int(a["target"]), a["give"], Game.achievement_state(a), func(): return Game.claim_achievement(a), str(DB.QUEST_ROUTE.get(a["stat"], ""))])
	return out

func _render() -> void:
	for c in _side.get_children():
		c.queue_free()
	for c in _list.get_children():
		c.queue_free()
	# --- left: tab cards
	for t in TABS.keys():
		var key: String = t
		var rows := _rows_of(key)
		var done := rows.filter(func(r): return r[4] == "claimed").size()
		var ready := rows.filter(func(r): return r[4] == "ready").size()
		var col := Color(str(TABS[key][1]))
		var on := key == _tab
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 62)
		btn.tooltip_text = key
		btn.set_meta("tab", key)
		btn.pressed.connect(func(): Game.sfx("ui_click"); _tab = key; _render())
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.add_theme_stylebox_override("panel", UI.style(Color(col, 0.2) if on else Color(0.05, 0.03, 0.1, 0.7), col if on else Color(col, 0.3), 12, 2 if on else 1, 0))
		btn.add_child(fr)
		var h := UI.hbox(8)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 10
		h.offset_right = -10
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(h)
		var ic := UI.tex_rect(DB.icon(str(TABS[key][0])), Vector2(36, 36))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
		var tv := UI.vbox(2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tv)
		tv.add_child(UI.label(key, 14, Color.WHITE if on else UI.TEXT, 2))
		var pb := UI.bar(done, maxi(1, rows.size()), "GoldBar", 5)
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(pb)
		if ready > 0:
			var rp := UI.styled_panel(Color("#3a2a18"), UI.GOLD, 10, 1, 0)
			rp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rp.add_child(UI.label(" %d ! " % ready, 12, UI.GOLD, 2))
			h.add_child(rp)
			var pt := rp.create_tween().set_loops()
			pt.tween_property(rp, "modulate:a", 0.5, 0.7).set_trans(Tween.TRANS_SINE)
			pt.tween_property(rp, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		else:
			var cnt := UI.label("%d/%d" % [done, rows.size()], 12, UI.MUTED, 2)
			cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(cnt)
		_side.add_child(btn)
	# --- left: summary of the selected tab
	var rows := _rows_of(_tab)
	var col := Color(str(TABS[_tab][1]))
	var sp := UI.styled_panel(Color(0.04, 0.03, 0.09, 0.85), Color(col, 0.5), 12, 1, 10)
	_side.add_child(sp)
	var sv := UI.vbox(5)
	sp.add_child(sv)
	sv.add_child(UI.label(_tab, 17, col.lightened(0.3), 3))
	sv.add_child(UI.wrap_label(str(TABS[_tab][2]), 12, UI.MUTED))
	_timer = UI.label("", 13, Color.WHITE, 2)
	sv.add_child(_timer)
	_update_timer()
	if _tab == "COMMANDER ROAD":
		sv.add_child(UI.label("Commander Lv.%d" % int(Game.s["player"]["level"]), 14, Color.WHITE, 2))
	var ready_rows := rows.filter(func(r): return r[4] == "ready")
	var pend := {}
	for r in ready_rows:
		for k in (r[3] as Dictionary).keys():
			pend[k] = int(pend.get(k, 0)) + int(r[3][k])
	if pend.is_empty():
		sv.add_child(UI.label("Nothing to claim yet", 13, UI.MUTED, 2))
	else:
		sv.add_child(UI.label("READY TO CLAIM  (%d)" % ready_rows.size(), 13, UI.GOLD, 2))
		sv.add_child(UI.reward_row(pend, 26, 13))
	var any_ready := false
	for t in TABS.keys():
		if _rows_of(t).any(func(r): return r[4] == "ready"):
			any_ready = true
	var ca := UI.button("CLAIM ALL", _claim_all, "GoldButton" if any_ready else "", Vector2(0, 46))
	ca.disabled = not any_ready
	sv.add_child(ca)
	# --- right: grouped list (ready, in progress, completed)
	_rows = []
	for r in rows:
		_queue(r[0], r[1], r[2], r[3], r[4], r[5], r[6])
	var order := {"ready": 0, "progress": 1, "locked": 1, "claimed": 2}
	var heads := ["READY TO CLAIM", "IN PROGRESS", "COMPLETED"]
	var hcol := [UI.GOLD, Color("#9fd0ff"), UI.MUTED]
	for grp in [0, 1, 2]:
		var g: Array = _rows.filter(func(r): return int(order.get(r[4], 1)) == grp)
		if g.is_empty():
			continue
		var hh := UI.hbox(8)
		_list.add_child(hh)
		hh.add_child(UI.label("%s  •  %d" % [heads[grp], g.size()], 14, hcol[grp], 2))
		var ln := ColorRect.new()
		ln.color = Color(hcol[grp], 0.3)
		ln.custom_minimum_size = Vector2(0, 1)
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hh.add_child(ln)
		for r in g:
			_row(r[0], r[1], r[2], r[3], r[4], r[5], r[6])
	UI.stagger(_list)

var _rows: Array = []

func _queue(title: String, prog: int, target: int, give: Dictionary, state: String, claim: Callable, go: String = "") -> void:
	_rows.append([title, prog, target, give, state, claim, go])

## Icon shown on the left of a mission row, from the screen it leads to.
const ROUTE_ICON := {
	"story": "icon_story", "gacha": "icon_gacha", "heroes": "icon_skills", "lobby": "icon_afk", "arena": "icon_arena",
	"garden": "icon_garden", "messenger": "icon_messenger", "kitchen": "icon_kitchen", "guild": "icon_guild",
	"dungeon": "icon_dungeon", "quests": "icon_quest", "tower": "icon_tower", "pass": "icon_pass", "road": "icon_crystal",
}

func _row(title: String, prog: int, target: int, give: Dictionary, state: String, claim: Callable, go: String = "") -> void:
	var p: PanelContainer
	if state == "ready":
		p = UI.styled_panel(Color("#3a2a18"), UI.GOLD, 12, 2, 10.0)
	else:
		p = UI.panel("CardPanel")
	if state == "claimed":
		p.modulate = Color(1, 1, 1, 0.55)
	_list.add_child(p)
	var h := UI.hbox(14)
	p.add_child(h)
	var ring := UI.styled_panel(Color(0.06, 0.04, 0.12, 0.9), UI.GOLD if state == "ready" else Color("#6a5a9a"), 26, 2, 6.0)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.add_child(UI.tex_rect(DB.icon(ROUTE_ICON.get(go, "icon_quest")), Vector2(36, 36)))
	h.add_child(ring)
	if state == "ready":
		var tw := ring.create_tween().set_loops()
		tw.tween_property(ring, "modulate", Color(1.35, 1.25, 0.9), 0.6)
		tw.tween_property(ring, "modulate", Color.WHITE, 0.6)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(title, 18, Color.WHITE if state != "claimed" else UI.MUTED, 2))
	var br := UI.hbox(8)
	var bar := UI.bar(prog, target, "GoldBar", 10)
	bar.custom_minimum_size = Vector2(200, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	br.add_child(bar)
	br.add_child(UI.label("%d / %d" % [prog, target], 14, UI.MUTED))
	v.add_child(br)
	h.add_child(UI.reward_row(give, 30, 14))
	var can_go := state == "progress" and go != "" and go != "quests" and go != "road"
	var b := UI.button("CLAIMED" if state == "claimed" else ("CLAIM" if state == "ready" else ("GO ▶" if can_go else "IN PROGRESS")), func():
		if can_go:
			main.go(go)
			return
		if claim.call():
			main.show_rewards("MISSION COMPLETE", give)
		_render(), "GoldButton" if state == "ready" else "", Vector2(140, 46))
	b.disabled = state != "ready" and not can_go
	h.add_child(b)

func _claim_all() -> void:
	var total := {}
	var lists := [[DB.DAILY_QUESTS, 0], [DB.WEEKLY_QUESTS, 1], [DB.ACHIEVEMENTS, 2]]
	for l in lists:
		for q in l[0]:
			var ok: bool = Game.claim_quest(q) if l[1] == 0 else (Game.claim_weekly(q) if l[1] == 1 else Game.claim_achievement(q))
			if ok:
				for k in q["give"].keys():
					total[k] = int(total.get(k, 0)) + int(q["give"][k])
	for lv in DB.road_levels():
		if Game.claim_road(lv):
			var rr := DB.road_reward(lv)
			for k in rr.keys():
				total[k] = int(total.get(k, 0)) + int(rr[k])
	if total.is_empty():
		main.toast("Nothing to claim right now.")
	else:
		main.show_rewards("REWARDS CLAIMED", total)
	_render()
