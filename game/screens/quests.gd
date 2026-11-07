extends Screen
## Daily missions + achievements.

var _list: VBoxContainer
var _tab := "DAILY"

func build() -> void:
	set_bg("lobby", 0.7)
	header("MISSIONS", ["gold", "gems"])
	var b := body(76)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var tabs := UI.hbox(8)
	v.add_child(tabs)
	for t in ["DAILY", "WEEKLY", "ACHIEVEMENTS", "COMMANDER ROAD"]:
		var key: String = t
		var tb := UI.button(t, func(): _tab = key; _render(), "TabButton", Vector2(190, 42))
		if t == "COMMANDER ROAD" and Game.road_ready() > 0:
			UI.add_badge(tb, Game.road_ready())
		tb.toggle_mode = true
		tb.set_meta("key", key)
		tabs.add_child(tb)
	tabs.add_child(UI.spacer())
	tabs.add_child(UI.button("CLAIM ALL", _claim_all, "GoldButton", Vector2(180, 42)))
	_list = UI.vbox(8)
	v.add_child(UI.scroll(_list))
	_render()

func refresh() -> void:
	super.refresh()

func _render() -> void:
	for tb in find_children("*", "Button", true, false):
		if tb.has_meta("key"):
			tb.button_pressed = tb.get_meta("key") == _tab
	for c in _list.get_children():
		c.queue_free()
	if _tab == "WEEKLY":
		var we := maxi(0, Game.weekly_ends_in())
		_list.add_child(UI.label("Resets in %dd %02dh — bigger rewards for steady play" % [we / 86400, (we / 3600) % 24], 14, Color("#9fd0ff"), 2))
		for q in DB.WEEKLY_QUESTS:
			var prog := mini(int(Game.s["weekly"]["progress"].get(q["id"], 0)), int(q["target"]))
			_row(q["name"], prog, int(q["target"]), q["give"], Game.weekly_state(q), func(): return Game.claim_weekly(q), str(DB.QUEST_ROUTE.get(q["src"], "")))
	elif _tab == "COMMANDER ROAD":
		var plv := int(Game.s["player"]["level"])
		_list.add_child(UI.label("Commander Lv.%d — rewards for every 5 levels, grand rewards every 25." % plv, 14, Color("#9fd0ff"), 2))
		for lv in DB.road_levels():
			var l2: int = lv
			_row("Reach Commander Lv.%d%s" % [l2, "  ★ GRAND" if l2 % 25 == 0 else ""], mini(plv, l2), l2, DB.road_reward(l2), Game.road_state(l2), func(): return Game.claim_road(l2))
	elif _tab == "DAILY":
		for q in DB.DAILY_QUESTS:
			var prog := mini(int(Game.s["quests"]["progress"].get(q["id"], 0)), int(q["target"]))
			_row(q["name"], prog, int(q["target"]), q["give"], Game.quest_state(q), func(): return Game.claim_quest(q), str(DB.QUEST_ROUTE.get(q["id"], "")))
	else:
		for a in DB.ACHIEVEMENTS:
			var prog := mini(Game.stat_value(a["stat"]), int(a["target"]))
			_row(a["name"], prog, int(a["target"]), a["give"], Game.achievement_state(a), func(): return Game.claim_achievement(a), str(DB.QUEST_ROUTE.get(a["stat"], "")))
	UI.stagger(_list)

func _row(title: String, prog: int, target: int, give: Dictionary, state: String, claim: Callable, go: String = "") -> void:
	var p := UI.panel("CardPanel")
	_list.add_child(p)
	var h := UI.hbox(14)
	p.add_child(h)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(title, 18, Color.WHITE if state != "claimed" else UI.MUTED, 2))
	var br := UI.hbox(8)
	var bar := UI.bar(prog, target, "GoldBar", 10)
	bar.custom_minimum_size = Vector2(260, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	br.add_child(bar)
	br.add_child(UI.label("%d / %d" % [prog, target], 14, UI.MUTED))
	v.add_child(br)
	h.add_child(UI.reward_row(give, 30, 14))
	var can_go := state == "progress" and go != "" and go != "quests"
	var b := UI.button("CLAIMED" if state == "claimed" else ("CLAIM" if state == "ready" else ("GO ▶" if can_go else "IN PROGRESS")), func():
		if can_go:
			main.go(go)
			return
		if claim.call():
			main.show_rewards("MISSION COMPLETE", give)
		_render(), "GoldButton" if state == "ready" else "", Vector2(150, 46))
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
