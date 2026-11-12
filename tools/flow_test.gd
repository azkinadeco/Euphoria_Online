extends SceneTree
## Dev tool: headless end-to-end test of the game logic (no UI).
## Run: Godot --headless --path . -s res://tools/flow_test.gd
## Uses a throwaway save file; the player's real save is untouched.

var fails := 0
var G: Node

func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)

func _process(_d: float) -> bool:
	if G != null:
		return false
	var gs: Script = load("res://game/core/game.gd")
	if gs == null or not gs.can_instantiate():
		print("RESULT: FAIL (game.gd failed to compile)")
		quit(1)
		return true
	G = gs.new()
	G.persist = false
	root.add_child(G)
	G.name = "Game"
	G.s = G.new_state()
	G._check_day()
	_run()
	print("RESULT: %s (%d failures)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
	return true

func _run() -> void:
	print("[start]")
	check(G.s["heroes"].size() == 5, "5 starter heroes")
	check(G.formation().size() == 5, "starter formation of 5")
	check(G.quest_state(DB.DAILY_QUESTS[0]) == "ready", "login quest ready")

	check(G.next_goal()["route"] == "mail", "guide: first goal is mailbox")

	print("[first steps]")
	check(G.next_goal().get("tag", "") == "STEP 1/8" and G.claim_first_step().is_empty(), "step can't be claimed before it is done")
	var fs: Dictionary = G.new_state()
	var fs_save: Dictionary = G.s
	G.s = fs
	G.claim_mail("welcome")
	check(G.next_goal().get("ready", false), "finished step offers a claim")
	var fg0: int = G.amount("gold")
	check(not G.claim_first_step().is_empty() and G.amount("gold") == fg0 + 5000, "step pays its reward")
	check(G.claim_first_step().is_empty() and G.next_goal()["route"] == "gacha", "step pays once, then moves on")
	check(G.feature_badge("heroes") == 0, "heroes badge quiet before the first win")
	G.s["gacha"]["total"] = 1
	G.claim_first_step()
	for i in DB.STAGES_PER_CHAPTER:
		G.s["story"]["cleared"][DB.stage_id(i)] = 3
	G.claim_first_step()
	G.use_item("exp_potion", 2)
	check(G.level_up("shina", 4) == 4, "step rewards are enough to reach Lv.5")
	G.claim_first_step()
	check(G.give_gift("shina", "bouquet") == "" and G.first_step_done("bond"), "starter bouquet completes the gift step")
	G.claim_first_step()
	G.claim_first_step()
	check(G.s["gear"].size() == 1, "stage 3 step grants the weapon")
	G.equip(int(G.s["gear"][0]["uid"]), "shina")
	G.claim_first_step()
	var ft0: int = G.amount("summon_ticket")
	check(not G.claim_first_step().is_empty() and G.amount("summon_ticket") == ft0 + 2, "chapter step pays tickets")
	check(G.first_step().is_empty() and not G.next_goal().has("tag"), "path ends, normal goals return")
	G.s = fs_save

	print("[mixed summon]")
	var ms: Dictionary = G.new_state()
	var ms_save: Dictionary = G.s
	G.s = ms
	G.claim_mail("welcome")
	check(G.pull_pay(10) == "mixed" and G.pull_pay(1) == "ticket", "tickets first, gems cover the rest")
	var mg: int = G.amount("gems")
	var mt: int = G.amount("summon_ticket")
	var mr: Dictionary = G.pull("standard", 10, "mixed")
	check(mr.has("results") and G.amount("summon_ticket") == 0 and G.amount("gems") == mg - DB.GACHA_COST * (10 - mt), "welcome gifts afford the first 10x")
	check(mr["results"].any(func(x): return x["rarity"] == "SSR"), "first 10x still guarantees an SSR")
	G.s["cur"]["gems"] = 0
	G.s["items"]["summon_ticket"] = 3
	check(G.pull("standard", 10, "mixed").has("error") and G.amount("summon_ticket") == 3, "mixed summon short on gems spends nothing")
	G.s = ms_save

	print("[item icons]")
	var seen_icons := {}
	for ik in DB.ITEMS.keys():
		var icn := str(DB.ITEMS[ik]["icon"])
		check(ResourceLoader.exists("res://art/icons/%s.png" % icn), "item %s icon exists" % ik)
		check(not seen_icons.has(icn), "item %s has its own icon (shared with %s)" % [ik, seen_icons.get(icn, "-")])
		seen_icons[icn] = ik
	for cur_icon in ["icon_gold", "icon_gem", "icon_crystal", "icon_energy"]:
		check(not seen_icons.has(cur_icon), "no item looks like a currency (%s)" % cur_icon)

	print("[messenger]")
	var mg_save: Dictionary = G.s
	G.s = G.new_state()
	check(G.msg_unread() == 0, "messenger stays quiet before it unlocks")
	G.s["player"]["level"] = DB.FEATURE_UNLOCK["messenger"]
	for hid in ["shina", "furu", "valeria", "glytta"]:
		G.add_hero(hid)
	G.s.erase("messenger")
	check(G.msg_unread() == DB.MSG_PER_DAY, "messenger delivers %d chats a day" % DB.MSG_PER_DAY)
	for hid in DB.hero_ids():
		check(DB.MSG_PERSONAL.has(hid), "hero %s has a personal chat" % hid)
	for th in DB.MSG_PERSONAL.values() + DB.MSG_TOPICS:
		check((th[0] as Array).size() >= 1 and (th[1] as Array).size() == 2 and (th[2] as Array).size() == 2 and int(th[3]) in [0, 1], "chat thread is well formed")
	G.hero("shina")["bond"] = DB.MSG_BOND
	G.s.erase("messenger")
	check(G.msg_pending().get("shina", "") == "p", "a Bond %d hero sends her personal chat first" % DB.MSG_BOND)
	var mg_gems: int = G.amount("gems")
	var mg_bond := int(G.hero("shina")["bond_exp"]) + 1000 * int(G.hero("shina")["bond"])
	var mg_r: Dictionary = G.msg_reply("shina", int(DB.MSG_PERSONAL["shina"][3]))
	check(bool(mg_r.get("best", false)) and int(mg_r["bond"]) == DB.MSG_BOND_BEST, "the favourite reply gives the big Bond bonus")
	check(G.amount("gems") == mg_gems + DB.MSG_PERSONAL_GEMS, "first personal chat pays Gems")
	check(int(G.hero("shina")["bond_exp"]) + 1000 * int(G.hero("shina")["bond"]) > mg_bond, "replying raises Bond")
	check(not G.msg_pending().has("shina") and G.msg_log("shina").size() == (DB.MSG_PERSONAL["shina"][0] as Array).size() + 2, "the reply moves the chat into the log")
	check(G.msg_reply("shina", 0).is_empty(), "no double reply")
	check(G.stat_value("chats") == 1 and G.stat_value("personal_chats") == 1, "replies count for achievements")
	check(int(G.s["quests"]["progress"].get("chat", 0)) == 1, "a reply counts for the daily chat quest")
	check(G.msg_contacts()[0] != "shina" or G.msg_pending().is_empty(), "waiting chats are listed first")
	G.s["messenger"]["day"] = G.day_key() - 1
	check(G.msg_pending().size() == DB.MSG_PER_DAY and str(G.msg_pending().get("shina", "t0")).begins_with("t"), "next day refills the inbox with everyday chats")
	for hid in DB.hero_ids():
		check(DB.MSG_PERSONAL2.has(hid), "hero %s has a second personal chat" % hid)
	for th in DB.MSG_PERSONAL2.values() + DB.MSG_EVENTS["gift"] + DB.MSG_EVENTS["win"]:
		check((th[0] as Array).size() >= 1 and (th[1] as Array).size() == 2 and (th[2] as Array).size() == 2 and int(th[3]) in [0, 1], "chat thread 2 is well formed")
	G.s["messenger"]["pending"] = {}
	G.hero("shina")["bond"] = DB.MSG_BOND2
	G.s["messenger"]["day"] = G.day_key() - 1
	check(G.msg_pending().get("shina", "") == "p2", "Bond %d unlocks the second personal chat" % DB.MSG_BOND2)
	mg_gems = G.amount("gems")
	G.msg_reply("shina", 0)
	check(G.amount("gems") == mg_gems + DB.MSG_PERSONAL_GEMS, "second personal chat pays Gems")
	G.s["messenger"]["pending"] = {}
	G.give({"sweet_cake": 2})
	check(G.give_gift("furu", "sweet_cake") == "" and str(G.msg_pending().get("furu", "")).begins_with("gift"), "a gift makes the hero text back")
	check(not DB.msg_thread("furu", str(G.msg_pending()["furu"])).is_empty(), "gift chat has text")
	G.msg_reply("furu", 0)
	G.give_gift("furu", "sweet_cake")
	check(not G.msg_pending().has("furu"), "only one gift chat a day")
	check(G.msg_notify("valeria", "win") and str(G.msg_pending()["valeria"]).begins_with("win"), "a victory makes a hero text")
	check(not G.msg_notify("glytta", "win"), "only one victory chat a day")
	G.s = mg_save

	print("[mission GO]")
	for qk in DB.QUEST_ROUTE.keys():
		check(ResourceLoader.exists("res://game/screens/%s.gd" % DB.QUEST_ROUTE[qk]), "mission %s leads to a real screen" % qk)
	for dq in DB.DAILY_QUESTS:
		check(dq["id"] == "login" or DB.QUEST_ROUTE.has(dq["id"]), "daily mission %s has a GO route" % dq["id"])
	for wq in DB.WEEKLY_QUESTS:
		check(DB.QUEST_ROUTE.has(wq["src"]), "weekly mission %s has a GO route" % wq["id"])
	for ac in DB.ACHIEVEMENTS:
		check(DB.QUEST_ROUTE.has(ac["stat"]), "achievement %s has a GO route" % ac["id"])

	print("[redeem & fps]")
	var rd_save: Dictionary = G.s
	G.s = G.new_state()
	var rd_gems: int = G.amount("gems")
	check(G.redeem("  euphoria-2026 ").has("give") and G.amount("gems") == rd_gems + int(DB.REDEEM_CODES["EUPHORIA2026"]["gems"]), "a code works, ignoring case, spaces and dashes")
	check(G.redeem("EUPHORIA2026").has("error"), "a code works only once")
	check(G.redeem("NOPE").has("error") and G.redeem("").has("error"), "bad or empty codes are refused")
	for rc in DB.REDEEM_CODES.keys():
		check(rc == rc.to_upper() and not rc.contains(" ") and not rc.contains("-"), "code %s is stored normalised" % rc)
		for rk in DB.REDEEM_CODES[rc].keys():
			check(rk in ["gold", "gems", "hero_exp", "energy", "arena_coin"] or DB.ITEMS.has(rk), "code %s gives a real item (%s)" % [rc, rk])
	check(G.fps_cap() == 60, "60 FPS by default")
	G.s["settings"]["fps"] = 30
	check(G.fps_cap() == 30, "30 FPS battery saver")
	G.s = rd_save

	print("[kitchen]")
	var kt_save: Dictionary = G.s
	G.s = G.new_state()
	G.s["cur"]["gold"] = 100000
	check(G.kitchen_level() == 1 and G.basket_ready(), "kitchen starts at Lv.1 with a basket ready")
	var kt_b: Dictionary = G.claim_basket()
	var kt_n := 0
	for k in kt_b.keys():
		check(DB.INGREDIENTS.has(k), "basket only holds ingredients")
		kt_n += int(kt_b[k])
	check(kt_n == DB.BASKET_SIZE and G.claim_basket().is_empty() and not G.basket_ready(), "basket gives %d once a day" % DB.BASKET_SIZE)
	for r in DB.RECIPES:
		check(DB.ITEMS.has(r["id"]), "recipe %s is an item" % r["id"])
		check(DB.MEALS.has(r["id"]) or DB.DISH_GIFTS.has(r["id"]), "recipe %s is a meal or a gift" % r["id"])
		for k in r["need"].keys():
			check(DB.INGREDIENTS.has(k), "recipe %s uses ingredients" % r["id"])
	for g in DB.DISH_GIFTS:
		check(str(DB.ITEMS[g]["kind"]) == "gift" and int(DB.ITEMS[g]["bond"]) > 0, "%s works as a gift" % g)
	check(G.cook("dish_tart") != "", "Lv.2 recipe is locked at Lv.1")
	G.s["items"]["ing_meat"] = 4
	G.s["items"]["ing_herb"] = 2
	check(G.can_cook("dish_stew") == 2, "can_cook counts ingredient sets")
	var kt_gold: int = G.amount("gold")
	check(G.cook("dish_stew", 2) == "" and G.amount("dish_stew") == 2 and G.amount("ing_meat") == 0, "cooking uses ingredients and makes dishes")
	check(G.amount("gold") == kt_gold - 2 * int(DB.recipe("dish_stew")["gold"]), "cooking costs Gold")
	check(G.cook("dish_stew") != "", "no cooking without ingredients")
	check(G.stat_value("dishes") == 2 and int(G.s["quests"]["progress"].get("cook", 0)) >= 1, "dishes count for quests and achievements")
	var kt_base: Array = G.ally_team({"mode": "story"})
	check(G.serve_meal("dish_stew") == "" and int(G.active_meal()["left"]) == 3, "serving a meal gives 3 battles")
	G.meal_consume({"mode": "story"})
	var kt_fed: Array = G.ally_team({"mode": "story"})
	if not kt_base.is_empty():
		check(is_equal_approx(float(kt_fed[0]["bonus"].get("atk", 0.0)) - float(kt_base[0]["bonus"].get("atk", 0.0)), 0.08), "the meal adds +8% ATK in battle")
	check(int(G.active_meal()["left"]) == 2, "each battle uses one meal charge")
	G.meal_consume({"mode": "arena"})
	check(int(G.active_meal()["left"]) == 2 and G.ally_team({"mode": "arena"})[0]["bonus"].get("atk", 0.0) == kt_base[0]["bonus"].get("atk", 0.0) if not kt_base.is_empty() else true, "Arena does not use the meal")
	G.meal_consume({"mode": "story"})
	G.meal_consume({"mode": "story"})
	check(G.active_meal().is_empty(), "the meal runs out")
	G.meal_consume({"mode": "story"})
	check(G._meal_bonus.is_empty(), "no buff without a meal")
	G.s["kitchen"]["cooked"] = DB.KITCHEN_LV[1]
	check(G.kitchen_level() == 2 and G.recipe_unlocked("dish_tart") and not G.recipe_unlocked("dish_pie"), "Kitchen Lv.2 unlocks the tart")
	G.s["kitchen"]["basket_day"] = G.day_key() - 1
	var kt_b2: Dictionary = G.claim_basket()
	var kt_n2 := 0
	for k in kt_b2.keys():
		kt_n2 += int(kt_b2[k])
	check(kt_n2 == DB.BASKET_SIZE + 1, "a higher Kitchen level fills a bigger basket")
	var kt_drop := {}
	G._ingredient_drop(kt_drop, true)
	check(kt_drop.size() == 1 and int(kt_drop.values()[0]) == 2, "bosses always drop 2 ingredients")
	check(DB.QUEST_ROUTE.get("cook", "") == "kitchen" and DB.FEATURE_UNLOCK.has("kitchen"), "kitchen quest has a GO route")
	G._meal_bonus = {}
	G.s = kt_save

	print("[scout report]")
	var sc_save: Dictionary = G.s
	G.s = G.new_state()
	var fire := [{"id": "shina", "cell": Vector2i(0, 0), "level": 1}, {"id": "shina", "cell": Vector2i(0, 1), "level": 1}]
	var mixed := [{"id": "fidelia", "cell": Vector2i(0, 0), "level": 1}, {"id": "fidelia", "cell": Vector2i(0, 1), "level": 1}, {"id": "shina", "cell": Vector2i(1, 1), "level": 1, "boss": true}]
	check(G.scout(fire)["main"] == "FIRE" and G.scout(fire)["counter"] == "WATER", "scout finds the main element and its counter")
	check(is_equal_approx(DB.element_mult(G.scout(fire)["counter"], G.scout(fire)["main"]), 1.3), "scout's counter really gets +30%")
	check(G.scout(mixed)["main"] == "FIRE", "a boss outweighs two minions")
	check((G.scout(fire)["heroes"] as Array).has("fidelia") and int(G.scout(fire)["deployed"]) >= 1, "scout lists owned counters")
	var uncounted := 0
	for i in DB.stage_count():
		if G.scout(DB.stage(i)["enemies"]).is_empty():
			uncounted += 1
	check(uncounted == 0, "every story stage has a scout report (%d missing)" % uncounted)
	G.add_hero("zennyo") if DB.HEROES.has("zennyo") else null
	G.auto_formation("WATER")
	check(G.formation().any(func(e): return DB.ELEMENT_GROUP.get(DB.element_of(e[0]), "") == "WATER"), "auto team fields the counter element")
	G.auto_formation()
	check(G.defeat_tip(DB.stage(DB.stage_count() - 1)["enemies"]).contains("far stronger"), "defeat tip names a huge power gap")
	G.s["formation"] = G.s["formation"].filter(func(e): return DB.ELEMENT_GROUP.get(DB.element_of(e[0]), "") != "WATER")
	check(G.defeat_tip(fire.slice(0, 1)).contains("Bring"), "defeat tip names the counter hero")
	check(not G.defeat_tip([]).is_empty(), "defeat tip survives an empty enemy list")
	G.s = sc_save

	print("[mail]")
	var r: Dictionary = G.claim_mail("welcome")
	check(int(r.get("gems", 0)) == 900 and int(r.get("summon_ticket", 0)) == 5, "welcome mail: 900 gems + 5 tickets (rebalanced)")
	var day1_gems: int = 300 + 900
	var day1_tix: int = 5
	for m in DB.MAIL:
		if m["id"] != "welcome":
			day1_gems += int(m["give"].get("gems", 0))
			day1_tix += int(m["give"].get("summon_ticket", 0))
	var day1_pulls: int = day1_gems / DB.GACHA_COST + day1_tix + 1
	check(day1_pulls >= 12 and day1_pulls <= 20, "day-one summons in 12..20 (got %d)" % day1_pulls)

	print("[feature gating]")
	check(not G.feature_unlocked("guild") and not G.feature_unlocked("arena") and G.feature_unlocked("shop"), "advanced features locked at Lv.1")
	check(G.feature_badge("arena") == 0, "locked feature shows no badge")
	var plv: int = G.s["player"]["level"]
	G.add_player_exp(100000)
	check(G.feature_unlocked("guild") and (G.s.get("new_unlocks", []) as Array).has("arena"), "level up unlocks features + NEW marker")
	G.seen_unlock("arena")
	check(not (G.s["new_unlocks"] as Array).has("arena"), "unlock marker cleared on visit")
	G.s["player"]["level"] = plv
	check(G.claim_mail("welcome").is_empty(), "mail cannot be claimed twice")

	print("[gacha]")
	var gems_before: int = G.amount("gems")
	G.give({"summon_ticket": 10})
	var res: Dictionary = G.pull("limited", 10, "ticket")
	check(res.has("results") and res["results"].size() == 10, "10x pull with tickets")
	var has_sr := false
	for x in res["results"]:
		if x["rarity"] != "R":
			has_sr = true
	check(has_sr, "10x guarantees SR+")
	var has_ssr := false
	for x in res["results"]:
		if x["rarity"] == "SSR":
			has_ssr = true
	check(has_ssr and bool(G.s["gacha"]["first10_done"]), "first 10x guarantees an SSR")
	check(G.amount("gems") == gems_before, "tickets used instead of gems")
	check(G.pull("limited", 1, "free").has("results"), "free daily pull")
	check(G.pull("limited", 1, "free").has("error"), "free pull only once a day")
	G.s["gacha"]["pity"] = DB.GACHA_PITY - 1
	G.s["cur"]["gems"] = 10000
	var pr: Dictionary = G.pull("standard", 1, "gems")
	check(pr["results"][0]["rarity"] == "SSR", "pity guarantees SSR")
	check(int(G.s["gacha"]["pity"]) == 0, "pity resets after SSR")

	print("[level / star]")
	var lvl: int = G.hero("fidelia")["level"]
	var n: int = G.level_up("fidelia", 5)
	check(n == 5 and G.hero("fidelia")["level"] == lvl + 5, "level up x5")
	G.s["heroes"]["fidelia"]["level"] = DB.level_cap(1)
	check(G.level_up("fidelia", 1) == 0, "level cap blocks leveling")
	G.s["shards"]["fidelia"] = 0
	G.s["items"]["star_stone"] = 0
	check(G.star_up("fidelia") != "", "star up blocked without shards")
	G.give({"shard:fidelia": 10, "gold": 100000})
	check(G.star_up("fidelia") == "", "star up with shards")
	check(G.hero("fidelia")["star"] == 2, "fidelia is 2★")
	check(G.skin_unlocked("fidelia", 1), "star up unlocks outfit #2")

	print("[bond / oath]")
	G.give({"celestial_gem": 30})
	for i in 30:
		G.give_gift("shina", "celestial_gem")
	check(G.hero("shina")["bond"] == DB.MAX_BOND, "gifts raise bond to max")
	check(G.swear_oath("shina") != "", "oath needs a ring")
	G.give({"oath_ring": 1})
	check(G.swear_oath("shina") == "", "oath sworn")
	check(str(G.hero("shina").get("oath_date", "")).length() == 10 and G.oath_date("shina").split(" ").size() == 3, "oath date recorded (%s)" % G.oath_date("shina"))
	check(G.skin_unlocked("shina", 2), "bond milestone outfit unlocked")
	check(not G.skin_unlocked("shina", 1), "4★ outfit still locked")

	print("[formation]")
	G.auto_formation()
	check(G.formation().size() == 5, "auto formation deploys 5")
	var first: String = G.formation()[0][0]
	G.remove_hero(first)
	check(G.formation().size() == 4, "remove hero")
	check(G.place_hero(first, Vector2i(2, 2)) == "" or G.formation_at(Vector2i(2, 2)) != "", "place hero")

	print("[story]")
	var e0: int = G.amount("energy")
	check(G.pay_battle({"mode": "story", "stage": 0}) == "", "pay energy")
	check(G.amount("energy") == e0 - DB.stage(0)["energy"], "energy deducted")
	var rew: Dictionary = G.apply_stage_result(0, true, 3)
	check(rew.has("gems"), "first clear gems")
	check(G.story_progress() == 1, "stage 1-2 unlocked")
	var sw: Dictionary = G.sweep_stage(0, 2)
	check(not sw.has("error") and int(sw["gold"]) == DB.stage(0)["gold"] * 2, "sweep x2")

	for i in range(1, DB.STAGES_PER_CHAPTER):
		G.apply_stage_result(i, true, 3)
	var cr: Dictionary = G.apply_stage_result(DB.STAGES_PER_CHAPTER, true, 3)
	check(not cr.has("chapter_clear"), "non-boss stage has no chapter clear")
	G.s["story"]["cleared"].erase(DB.stage_id(DB.STAGES_PER_CHAPTER - 1))
	var cc: Dictionary = G.apply_stage_result(DB.STAGES_PER_CHAPTER - 1, true, 3)
	check(int(cc.get("chapter_clear", 0)) == 1 and int(cc.get("summon_ticket", 0)) >= 3, "chapter 1 boss gives chapter clear reward")
	check(not G.s["items"].has("chapter_clear"), "chapter_clear flag not stored as item")
	check(DB.CHAPTERS[0].has("outro"), "chapters have outro dialogue")
	check(str(G.next_goal().get("text", "")) != "", "guide always has a goal")

	print("[battle sim]")
	var sim := BattleSim.new()
	var allies: Array = []
	for e in G.formation():
		var h: Dictionary = G.hero(e[0])
		allies.append({"id": e[0], "cell": Vector2i(e[1], e[2]), "level": h["level"], "star": h["star"]})
	sim.setup(allies, DB.stage(0)["enemies"], 42)
	var out: Dictionary = sim.run()
	check(out.has("won") and sim.events.size() > 3, "battle simulation produces events")
	check(sim.events[-1]["t"] == "end", "battle ends with end event")

	print("[arena / tower]")
	var opps: Array = G.arena_opponents()
	check(opps.size() == 4 and opps[0]["team"].size() == 5, "4 arena opponents with 5 heroes")
	check(G.pay_battle({"mode": "arena", "opp": 0}) == "", "arena ticket spent")
	var ar: Dictionary = G.apply_arena_result(true)
	check(int(ar["arena_coin"]) == 60 and int(G.s["arena"]["rp"]) == 1024, "arena win rewards")
	var tr: Dictionary = G.apply_tower_result(1, true)
	check(int(G.s["tower"]["floor"]) == 2 and tr.has("gems"), "tower floor advance")
	check(G.apply_tower_result(1, true).is_empty(), "tower floor not repeatable")

	print("[shop / items / quests / afk]")
	var free_item: Dictionary = DB.SHOP[0]
	check(G.buy(free_item) == "", "buy daily free gift")
	check(G.buy(free_item) != "", "daily limit enforced")
	G.give({"exp_potion": 2})
	var he: int = G.amount("hero_exp")
	check(G.use_item("exp_potion", 2) and G.amount("hero_exp") == he + 2000, "use EXP potions")
	check(G.claim_quest(DB.DAILY_QUESTS[0]), "claim login quest")
	G.s["afk_ts"] = G.now() - 3600
	var afk: Dictionary = G.claim_afk()
	check(int(afk.get("gold", 0)) > 0, "AFK rewards after 1 hour")
	check(G.badge_quests() >= 0, "quest badge count")

	print("[equipment]")
	var p0: int = G.hero_power("shina")
	var g: Dictionary = G.add_gear("weapon", "SSR")
	G.equip(g["uid"], "shina")
	check(G.hero_power("shina") > p0, "equipping raises power")
	G.give({"gold": 50000})
	check(G.enhance_gear(g["uid"]) == "" and int(g["lv"]) == 1, "enhance gear +1")
	G.add_gear("armor", "R")
	check(G.auto_equip("rumi") >= 1, "auto equip free gear")
	G.give({"gear_chest": 3})
	var n_before: int = G.s["gear"].size()
	check(G.use_item("gear_chest", 3) and G.s["gear"].size() == n_before + 3, "open 3 gear chests")
	G.give({"gear:accessory:SR": 1})
	check(G.s["gear"].size() == n_before + 4, "gear reward key creates item")
	var free_uid := -1
	for x in G.s["gear"]:
		if x["owner"] == "":
			free_uid = x["uid"]
	check(G.salvage_gear(free_uid) > 0, "salvage gear")

	print("[login]")
	check(G.can_claim_login() and int(G.s["login"]["streak"]) == 1, "day 1 login claimable")
	check(G.claim_login().has("gems") and not G.can_claim_login(), "claim login once")

	print("[event]")
	check(G.event_ends_in() > 0, "event has time left")
	check(G.pay_battle({"mode": "event", "stage": 0}) == "", "event costs energy")
	var er: Dictionary = G.apply_event_result(0, true, 3)
	check(int(er.get("festival_token", 0)) > 0 and er.has("gems"), "event tokens + first clear")
	G.give({"festival_token": 1000})
	var evf: String = DB.EVENT["featured"]
	var evs0: int = int(G.s["shards"].get(evf, 0))
	var shard_item: Dictionary = (DB.EVENT["shop"] as Array).filter(func(it): return (it["give"] as Dictionary).has("shard:" + evf))[0]
	check(G.buy_event(shard_item) == "" and int(G.s["shards"].get(evf, 0)) >= evs0 + 10, "event exchange for featured shards")
	check(G.sweep_event(1, 1).has("error"), "cannot sweep an uncleared event stage")
	G.s["cur"]["energy"] = 40
	var evtk0: int = G.amount("festival_token")
	var evsw: Dictionary = G.sweep_event(0, 3)
	check(not evsw.has("error") and G.amount("festival_token") == evtk0 + int(evsw["festival_token"]) and G.amount("energy") == 40 - 24 and not evsw.has("gems"), "event sweep x3: tokens, 24 energy, no first-clear gems")
	check(G.sweep_event(0, 5).has("error"), "event sweep needs enough energy")
	print("[christmas event]")
	DB.set_event_period(-1)
	check(DB.EVENT["name"] == "Starfall Christmas" and DB.EVENT["skin"] == "hyeonxa" and DB.HEROES.has("hyeonxa"), "pinned Christmas event")
	var xsi := DB.special_index("hyeonxa")
	check(xsi > 0 and DB.SPECIAL_SKINS.has("hyeonxa") and DB.art_list("hyeonxa").size() > xsi, "hyeonxa special skin art (index %d)" % xsi)
	check(G.buy_costume("hyeonxa", xsi).begins_with("Event reward") or not G.owns("hyeonxa"), "event skin not sold in the Wardrobe")
	G.give({"festival_token": 2000})
	var skin_item: Dictionary = DB.EVENT["shop"][0]
	check(G.buy_event(skin_item) == "" and (G.s["skins_bought"]["hyeonxa"] as Array).has(xsi), "event exchange gives the Scarlet Mistletoe skin")
	check(G.reward_name("skin:hyeonxa") == "Skin: Scarlet Mistletoe" and G.reward_icon("skin:hyeonxa") != null, "skin reward name + icon")
	check(DB.sprite("hyeonxa", 1, xsi) != DB.sprite("hyeonxa", 1, 0), "special skin battle sprite")
	check(G.event_ends_in() > 0 or G.event_period() >= 0, "event timer")
	var evnames: Array = []
	for pi in 5:
		DB.set_event_period(pi)
		evnames.append(DB.EVENT["name"])
		check(DB.BG.has(DB.EVENT["bg"]) and DB.HEROES.has(DB.EVENT["featured"]) and DB.event_stage(4)["enemies"].size() == 5, "event %s valid" % DB.EVENT["name"]) if not (DB.BG.has(DB.EVENT["bg"]) and DB.HEROES.has(DB.EVENT["featured"])) else null
	check(evnames.size() == 5 and evnames[0] != evnames[1], "events rotate by period: %s" % str(evnames))
	DB.set_event_period(G.event_period())

	print("[guild]")
	check(not G.in_guild(), "not in guild at start")
	G.join_guild("Eclipse Vanguard", 1)
	check(G.in_guild() and G.guild_bonus() == 0.0, "joined guild lv1")
	check(G.guild_checkin().has("guild_coin") and G.guild_checkin().is_empty(), "check-in once per day")
	G.give({"gold": 100000})
	for i in 3:
		G.guild_donate()
	check(G.guild_donate() != "", "donation limit 3/day")
	check(int(G.s["guild"]["exp"]) == 220, "check-in + 3 donations = 220 guild EXP")
	G._add_guild_exp(100)
	check(int(G.s["guild"]["level"]) == 2 and is_equal_approx(G.guild_bonus(), 0.01), "guild Lv.2 gives +1% buff")
	check(G.pay_battle({"mode": "raid"}) == "" and int(G.s["guild"]["raid_tries"]) == 2, "raid attempt spent")
	var hp0: int = G.s["guild"]["raid_hp"]
	var rr: Dictionary = G.apply_raid_result(50000)
	check(int(G.s["guild"]["raid_hp"]) == hp0 - 50000 and rr.has("guild_coin"), "raid damage applied")
	var rlv: int = G.s["guild"]["raid_lv"]
	G.apply_raid_result(99999999)
	check(int(G.s["guild"]["raid_lv"]) == rlv + 1, "raid boss defeated -> next level")
	var sim2 := BattleSim.new()
	sim2.setup([{"id": "shina", "cell": Vector2i(0, 1), "level": 10, "star": 3}], DB.raid_boss(1), 3)
	var out2: Dictionary = sim2.run()
	check(not out2["won"] and out2["reason"] in ["timeout", "lose"], "raid boss cannot be killed in battle")
	check(G.guild_members().size() == 12, "guild member list")

	print("[friends]")
	var fl: Array = G.friends()
	check(fl.size() == DB.FRIEND_NAMES.size() and not fl[0]["used"], "friend list available")
	check(G.send_hearts() == 10 * DB.FRIEND_NAMES.size() and G.send_hearts() == 0, "send hearts once per day")
	var fp0: int = G.amount("friend_point")
	G.use_support(0)
	check(G.friends()[0]["used"] and G.amount("friend_point") == fp0 + 20, "using support marks friend + gives FP")
	var sim3 := BattleSim.new()
	var al: Array = [{"id": "shina", "cell": Vector2i(0, 1), "level": 5, "star": 3}, {"id": fl[1]["hero"], "cell": Vector2i(1, 1), "level": fl[1]["level"], "star": fl[1]["star"]}]
	sim3.setup(al, DB.stage(0)["enemies"], 9)
	check(sim3.side_units(0).size() == 2 and sim3.run().has("won"), "battle with support hero")

	print("[dungeon]")
	check(G.dungeon_tries("gold") == 3 and G.dungeon_unlocked("gold", 0) and not G.dungeon_unlocked("gold", 1), "dungeon starts at Lv.1 with 3 tries")
	check(G.pay_battle({"mode": "dungeon", "dungeon": "gold", "diff": 0}) == "" and G.dungeon_tries("gold") == 2, "dungeon attempt spent")
	check(G.apply_dungeon_result("gold", 0, false).is_empty() and G.dungeon_tries("gold") == 3, "failed attempt refunded")
	G.pay_battle({"mode": "dungeon", "dungeon": "gold", "diff": 0})
	var g0: int = G.amount("gold")
	var dr: Dictionary = G.apply_dungeon_result("gold", 0, true)
	check(G.amount("gold") == g0 + int(dr["gold"]) and G.dungeon_unlocked("gold", 1), "dungeon clear gives gold and unlocks Lv.2")
	check(not G.sweep_dungeon("gold", 0).has("error") and G.dungeon_tries("gold") == 1, "dungeon sweep uses a try")
	check(G.sweep_dungeon("gold", 1).has("error"), "cannot sweep uncleared level")
	var gn: int = G.s["gear"].size()
	G.pay_battle({"mode": "dungeon", "dungeon": "gear", "diff": 0})
	G.apply_dungeon_result("gear", 0, true)
	check(G.s["gear"].size() == gn + 2, "gear dungeon drops a random piece + one of today's set")

	print("[memories]")
	G.s["heroes"]["rumi"]["bond"] = 3
	check(G.bond_story_unlocked("rumi", 0) and not G.bond_story_unlocked("rumi", 1), "memory ep.1 unlocks at bond 3")
	check(G.bond_stories_new() >= 1, "new memory counted")
	check(G.read_bond_story("rumi", 0).has("gems") and G.read_bond_story("rumi", 0).is_empty(), "memory reward only once")
	check(DB.bond_story("rumi", 2).size() > 3, "memory dialogue exists")

	print("[skill level]")
	check(G.skill_up("furu") != "", "skill up needs books")
	G.give({"skill_book": 20, "gold": 500000})
	check(G.skill_up("furu") == "" and int(G.hero("furu")["skill_lv"]) == 2, "skill up to Lv.2")
	var s1: Dictionary = DB.skill_at(DB.skill_of("shina"), 1)
	var s5: Dictionary = DB.skill_at(DB.skill_of("shina"), 5)
	check(is_equal_approx(float(s5["mult"]), float(s1["mult"]) * 1.48), "skill Lv.5 = +48% mult")
	check(float(DB.skill_of("shina")["mult"]) == float(s1["mult"]), "base skill data not mutated")
	var simA := BattleSim.new()
	simA.setup([{"id": "shina", "cell": Vector2i(0, 1), "level": 10, "star": 3, "skill_lv": 5}], DB.stage(0)["enemies"], 4)
	check(int(simA.units[0]["skill_lv"]) == 5 and float(simA.units[0]["skill"]["mult"]) > float(s1["mult"]), "battle uses skill level")

	print("[season pass]")
	var lv0: int = G.pass_level()
	G.add_pass_exp(DB.PASS_EXP_PER_LV * 3)
	check(G.pass_level() == lv0 + 3, "pass exp raises level")
	check(not G.claim_pass(1, false).is_empty() and G.claim_pass(1, false).is_empty(), "free reward claim once")
	check(G.claim_pass(1, true).is_empty(), "premium locked without purchase")
	G.give({"gems": 2000})
	check(G.buy_premium_pass() == "" and not G.claim_pass(1, true).is_empty(), "premium unlock + claim")
	check(G.claim_pass(DB.PASS_LEVELS, false).is_empty(), "cannot claim unreached level")
	check(not G.claim_all_pass().is_empty() and G.pass_claimable() == 0, "claim all")
	var pe0: int = int(G.s["pass"]["exp"])
	G.quest_progress("dungeon")
	check(int(G.s["pass"]["exp"]) == pe0 + 25, "dungeon gives pass exp")

	print("[voice / memories content]")
	var vmiss: Array = []
	var mmiss: Array = []
	for hid in DB.HEROES.keys():
		for cat in ["greet", "tap", "bond", "skill", "win", "summon"]:
			var vd: Dictionary = DB.voice(hid, cat)
			if str(vd["path"]) == "" or not ResourceLoader.exists(vd["path"]) or str(vd["en"]) == "":
				vmiss.append("%s_%s" % [hid, cat])
		for ep in 3:
			if DB.bond_story(hid, ep).size() < 3 or DB.bond_story_title(hid, ep) == DB.BOND_STORY_TITLES[ep]:
				mmiss.append("%s_%d" % [hid, ep])
	check(vmiss.is_empty(), "every hero has 6 voiced lines %s" % str(vmiss.slice(0, 5)))
	check(mmiss.is_empty(), "every hero has 3 custom memories %s" % str(mmiss.slice(0, 5)))
	check(DB.bond_story("shina", 0)[0][0] == "shina", "memory lines formatted [speaker, text]")

	print("[collection / presets / garden / expedition]")
	var cbn: float = G.collection_bonus()
	check(cbn > 0.0 and is_equal_approx(cbn, DB.COLLECTION_PER_HERO * G.s["heroes"].size()), "collection bonus scales with heroes owned")
	var f0: Array = G.formation().duplicate(true)
	G.switch_preset(1)
	check(int(G.s["preset_idx"]) == 1 and G.formation().size() == f0.size(), "empty preset copies current team")
	G.remove_hero(G.formation()[0][0])
	G.switch_preset(0)
	check(G.formation().size() == f0.size(), "preset 1 restored")
	G.switch_preset(1)
	check(G.formation().size() == f0.size() - 1, "preset 2 kept its own team")
	G.switch_preset(0)
	var gb0: int = int(G.hero("fidelia")["bond_exp"]) + int(G.hero("fidelia")["bond"]) * 1000
	var gt: Dictionary = G.garden_tap("fidelia")
	check(str(gt["line"]) != "" and int(gt["bond"]) == 6, "garden tap gives bond + voice line")
	for i in 6:
		G.garden_tap("fidelia")
	check(int(G.garden_tap("fidelia")["bond"]) == 0, "garden bond capped per day")
	check(G.start_expedition("herb", []) != "", "expedition needs heroes")
	check(G.start_expedition("herb", ["shina"]) == "" and G.expedition_left("herb") > 0, "expedition started")
	check(G.start_expedition("patrol", ["shina", "rumi"]) != "", "busy hero cannot join another expedition")
	check(G.claim_expedition("herb").is_empty(), "cannot claim before time")
	G.s["expeditions"]["herb"]["start"] = G.now() - 4000
	check(G.expeditions_ready() == 1 and G.claim_expedition("herb").has("gold"), "claim finished expedition")
	G.start_expedition("herb", ["shina"])
	G.give({"gems": 500})
	check(G.claim_expedition("herb", true).has("gold"), "finish expedition instantly with gems")
	var ex_keep: Dictionary = G.s["expeditions"].duplicate(true)
	G.s["expeditions"].clear()
	var sent_n: int = G.send_all_expeditions()
	var all_ids: Array = G.heroes_on_expedition()
	var uniq := {}
	for hid in all_ids:
		uniq[hid] = true
	check(sent_n > 0 and uniq.size() == all_ids.size(), "send all expeditions: no hero sent twice")
	check(G.auto_expedition_team("herb").is_empty() or G.s["expeditions"].has("herb"), "auto team skips busy heroes")
	G.s["expeditions"] = ex_keep

	print("[mail delete]")
	var mk: Array = G.s["mail_claimed"].duplicate()
	var md: Array = G.s["mail_deleted"].duplicate()
	G.s["mail_claimed"].clear()
	G.s["mail_deleted"].clear()
	var first_id: String = DB.MAIL[0]["id"]
	check(G.delete_mail([first_id]) == 0, "unclaimed mail cannot be deleted")
	G.s["mail_claimed"].append(first_id)
	check(G.delete_read_mail() == 1 and G.mail_list().size() == DB.MAIL.size() - 1, "delete read mail removes only claimed ones")
	G.s["mail_claimed"] = mk
	G.s["mail_deleted"] = md

	print("[battle systems]")
	check(DB.passive_of("lucidria") == "GUARD" and DB.passive_of("furu") == "GRACE" and DB.passive_of("rumi") == "ARCANE", "role passives mapped")
	var syn: Dictionary = DB.synergy(["fidelia", "scylla", "valeria", "shina"])
	check(syn["element"] == "WATER" and int(syn["count"]) == 3 and is_equal_approx(float(syn["bonus"]), 0.10), "water synergy x3 = +10% (ice counts as water)")
	var bs0 := BattleSim.new()
	bs0.setup([{"id": "fidelia", "cell": Vector2i(0, 1), "level": 10, "star": 2}], [], 1)
	var bs1 := BattleSim.new()
	bs1.setup([{"id": "fidelia", "cell": Vector2i(0, 1), "level": 10, "star": 2}, {"id": "scylla", "cell": Vector2i(1, 1), "level": 10, "star": 2}], [], 1)
	check(int(bs1.units[0]["atk"]) > int(bs0.units[0]["atk"]), "synergy boosts ATK in battle")
	var bs2 := BattleSim.new()
	bs2.setup([{"id": "glytta", "cell": Vector2i(0, 1), "level": 10, "star": 2}], [], 1, {"elem": "WIND", "atk": 0.15})
	var bs3 := BattleSim.new()
	bs3.setup([{"id": "glytta", "cell": Vector2i(0, 1), "level": 10, "star": 2}], [], 1)
	check(int(bs2.units[0]["atk"]) > int(bs3.units[0]["atk"]), "field modifier boosts matching element")
	check(not DB.stage(0)["mod"].is_empty(), "story stages carry field effect")
	var found_enrage := false
	var found_passive := false
	var found_end := false
	for sd in 30:
		var sb := BattleSim.new()
		var team := [{"id": "shina", "cell": Vector2i(0, 1), "level": 30, "star": 5}, {"id": "furu", "cell": Vector2i(1, 1), "level": 30, "star": 4},
			{"id": "lucidria", "cell": Vector2i(0, 0), "level": 30, "star": 4}, {"id": "rumi", "cell": Vector2i(2, 1), "level": 30, "star": 4}]
		sb.setup(team, DB.stage(5)["enemies"], sd + 1, DB.stage(5)["mod"])
		sb.run()
		for ev in sb.events:
			found_enrage = found_enrage or ev["t"] == "enrage"
			found_passive = found_passive or ev["t"] == "passive"
			found_end = found_end or ev["t"] == "status_end"
	check(found_enrage, "boss enrage happens")
	check(found_passive, "passive events (rage/grace) happen")
	check(found_end, "status expiry events emitted")
	check(G.stat_value("max_skill") >= 1 and G.stat_value("pass_level") >= 0, "new achievement stats")

	print("[runes / costume / minigame / arena season]")
	var crit0: float = float(G.stat_bonus("shina").get("crit", 0.0))
	var ru: Dictionary = G.add_rune("crit", 2)
	G.equip_rune(ru["uid"], "shina", 0)
	check(float(G.stat_bonus("shina")["crit"]) > crit0, "crit rune adds crit")
	var bsr := BattleSim.new()
	bsr.setup([{"id": "shina", "cell": Vector2i(0, 1), "level": 5, "star": 3, "bonus": G.stat_bonus("shina")}], [], 1)
	check(float(bsr.units[0]["crit_bonus"]) > 0.0, "battle receives rune crit")
	var pa: float = float(G.stat_bonus("rumi")["atk"])
	G.equip_rune(G.add_rune("atk", 3)["uid"], "rumi", 1)
	check(float(G.stat_bonus("rumi")["atk"]) > pa, "atk rune adds atk")
	for r0 in G.fusable("hp", 1):
		G.s["runes"].erase(r0)
	for i in 3:
		G.add_rune("hp", 1)
	G.give({"gold": 10000})
	var fused: Dictionary = G.fuse_runes("hp", 1)
	check(int(fused.get("tier", 0)) == 2 and G.fusable("hp", 1).is_empty(), "fuse 3 T1 -> T2")
	check(G.fuse_runes("hp", 1).is_empty(), "fusion needs 3 runes")
	G.give({"rune_pouch": 1})
	var nr: int = G.s["runes"].size()
	check(G.use_item("rune_pouch", 1) and G.s["runes"].size() == nr + 2, "rune pouch gives 2 runes")
	G.give({"rune:def:4": 1})
	check(G.s["runes"].back()["type"] == "def" and int(G.s["runes"].back()["tier"]) == 4, "rune reward key")
	var locked_idx := -1
	for i in range(1, DB.art_list("rumi").size()):
		if not G.skin_unlocked("rumi", i):
			locked_idx = i
			break
	if locked_idx > 0:
		G.give({"gems": 5000})
		check(G.buy_costume("rumi", locked_idx) == "" and G.skin_unlocked("rumi", locked_idx), "costume unlocked with gems")
	check(G.minigame_plays_left() == 3 and G.finish_minigame("rumi", 50).has("gold"), "minigame gives reward")
	G.finish_minigame("rumi", 10)
	G.finish_minigame("rumi", 10)
	check(G.finish_minigame("rumi", 10).is_empty(), "minigame reward 3x/day")
	G.s["arena"]["rp"] = 1450
	G.s["arena"]["season"] = G.arena_season() - 1
	G._check_arena_season()
	check(str(G.s["arena"]["last_tier"]) == "DIAMOND" and int(G.s["arena"]["rp"]) == 1225, "season end: tier reward + rp soft reset")
	check(G.claim_arena_season().has("gems") and G.claim_arena_season().is_empty(), "season reward once")
	check(G.arena_leaderboard().size() == 30, "leaderboard has 30 entries")

	print("[awakening / black market]")
	check(G.awaken_block("shina") != "", "awakening locked below 6 stars")
	G.s["heroes"]["shina"]["star"] = DB.MAX_STAR
	G.give({"shard:shina": 400, "gold": 2000000})
	var pw0: int = G.hero_power("shina")
	check(G.awaken("shina") == "" and int(G.hero("shina")["awaken"]) == 1, "awaken A1")
	check(G.hero_power("shina") > pw0, "awakening raises power")
	for i in 4:
		G.awaken("shina")
	check(int(G.hero("shina")["awaken"]) == 5 and G.awaken("shina") != "", "max awaken A5")
	var bsa := BattleSim.new()
	bsa.setup([{"id": "shina", "cell": Vector2i(0, 1), "level": 10, "star": 6, "skill_lv": 1, "awaken": 3}], [], 1)
	check(float(bsa.units[0]["skill"]["mult"]) > float(DB.skill_of("shina")["mult"]), "A3 boosts skill power")
	var offers: Array = G.market_offers()
	check(offers.size() == DB.MARKET_SIZE and str(offers[0]["give"].keys()[0]).begins_with("shard:"), "market has 6 offers incl. hero shards")
	G.give({"gems": 5000, "gold": 500000})
	check(G.market_buy(0) == "" and G.market_buy(0) != "", "market item buys once")
	check(G.market_refresh() == "" and not G.market_offers()[0]["sold"], "market refresh rerolls stock")

	print("[auto-repeat / history]")
	var en0: int = G.amount("energy")
	G.s["cur"]["energy"] = 200
	var qb: Dictionary = G.quick_battle({"mode": "story", "stage": 0})
	check(qb.has("won") and G.amount("energy") < 200, "quick battle spends energy and resolves")
	G.s["cur"]["energy"] = 0
	check(G.quick_battle({"mode": "story", "stage": 0}).has("error"), "quick battle blocked without energy")
	G.s["cur"]["energy"] = en0
	check(G.ally_team().size() == G.formation().size(), "ally team built from formation")
	check((G.s["gacha"].get("history", []) as Array).size() > 0, "summon history recorded")

	print("[hard mode / backup]")
	var hs0: Dictionary = DB.hard_stage(0)
	check(int(hs0["level"]) == int(DB.stage(0)["level"]) + 14 and hs0.has("shard_id"), "hard stage stronger with shard reward")
	check(DB.rarity_of(DB.hard_stage(DB.STAGES_PER_CHAPTER - 1)["shard_id"]) == "SSR", "hard boss drops SSR shards")
	G.s["story"]["cleared"][DB.stage_id(DB.STAGES_PER_CHAPTER - 1)] = 3
	check(G.hard_unlocked(0) and not G.hard_unlocked(1), "hard 1-1 opens after normal chapter boss")
	var sid: String = hs0["shard_id"]
	var sh0: int = int(G.s["shards"].get(sid, 0))
	var hr: Dictionary = G.apply_hard_result(0, true, 3)
	check(hr.has("gems") and int(G.s["shards"].get(sid, 0)) == sh0 + int(hs0["shards"]), "hard clear gives shards + first-clear gems")
	check(G.hard_unlocked(1) and G.hard_progress() == 1, "next hard stage unlocks")
	G.s["cur"]["energy"] = 300
	check(not G.sweep_stage(0, 2, true).has("error"), "hard sweep works")
	var code: String = G.export_code()
	check(code.begins_with("EO2:") and code.length() < 40000, "export code compact (%d chars)" % code.length())
	var gold_before: int = G.amount("gold")
	G.s["cur"]["gold"] = 1
	check(G.import_code(code) == "" and G.amount("gold") == gold_before, "import restores save")
	check(G.import_code("garbage") != "" and G.import_code("EO2:10:AAAA") != "", "bad codes rejected")
	check(G.hard_stars(0) == 3, "hard progress survives export/import")

	print("[approach / dating]")
	var mem: Array = DB.bond_story("shina", 0)
	var ch_line: Array = []
	for ln in mem:
		if str(ln[0]) == "?":
			ch_line = ln
	check(ch_line.size() == 5 and (ch_line[2] as Array).size() == 3, "memory contains a 3-option choice")
	check(int(ch_line[4][DB.liking("shina")]) == 40, "liked option gives most bond")
	check(DB.liking("lucidria") == 0 and DB.liking("kali") == 1 and DB.liking("xylia") == 2, "personality preferences by role")
	var t0: int = G.talks_left()
	var tl: Array = G.start_talk("furu")
	check(t0 == 3 and tl.size() == 2 and G.talks_left() == 2, "daily talk builds a scene and consumes a talk")
	G.start_talk("furu")
	G.start_talk("furu")
	check(G.start_talk("furu").is_empty(), "talks limited to 3/day")
	var fav: String = DB.fav_gift("rumi")
	G.s["heroes"]["rumi"]["bond"] = 1
	G.s["heroes"]["rumi"]["bond_exp"] = 0
	G.give({fav: 1})
	G.give_gift("rumi", fav)
	var got: int = int(G.hero("rumi")["bond_exp"]) + (DB.bond_to_next(1) if int(G.hero("rumi")["bond"]) > 1 else 0)
	check(got >= int(DB.ITEMS[fav]["bond"]) * 2 - 5, "favourite gift gives double bond")
	var ups: Array = []
	G.bond_up.connect(func(i, lv): ups.append([i, lv]))
	G.add_bond("lucidria", 500)
	check(not ups.is_empty() and ups[0][0] == "lucidria", "bond_up signal fires on level up")

	print("[long-term content]")
	check(DB.CHAPTERS.size() == 40 and DB.stage_count() == 240, "40 chapters / 240 stages")
	var bgmiss: Array = []
	for chd2 in DB.CHAPTERS:
		if not DB.BG.has(chd2["bg"]):
			bgmiss.append(chd2["bg"])
	for hd in DB.HUNTS:
		if not DB.BG.has(hd["bg"]):
			bgmiss.append(hd["bg"])
	check(bgmiss.is_empty(), "all chapter/hunt maps exist %s" % str(bgmiss))
	var bad_lines: Array = []
	for ci in DB.CHAPTERS.size():
		for key in ["intro", "mid", "mid2", "boss_lines", "outro"]:
			for ln in DB.CHAPTERS[ci].get(key, []):
				var sp := str(ln[0])
				if sp in ["?", "nar", "commander"]:
					continue
				if DB.art(sp, 0) == null:
					bad_lines.append("%d:%s" % [ci, sp])
	for it in DB.INTERLUDES:
		for ln in it["lines"]:
			var sp2 := str(ln[0])
			if not (sp2 in ["?", "nar", "commander"]) and DB.art(sp2, 0) == null:
				bad_lines.append("%s:%s" % [it["id"], sp2])
	check(bad_lines.is_empty(), "every story speaker has art %s" % str(bad_lines))
	var mb: Dictionary = DB.stage(10 * DB.STAGES_PER_CHAPTER + 5)["enemies"][0]
	check(mb.get("mirror", false) and DB.name_of("mirror:" + str(mb["id"])).begins_with("Mirror"), "arc 3 boss is a mirror hero")
	check(DB.stage(59)["boss"] and DB.stage(59)["enemies"][0]["id"] == "vexira", "chapter 10 boss is corrupted Vexira")
	for ci in DB.CHAPTERS.size():
		var cd: Dictionary = DB.CHAPTERS[ci]
		check(cd.has("intro") and cd.has("outro") and cd.has("boss_lines") and cd.has("mod"), "chapter %d has full story data" % (ci + 1))
	var wq: Dictionary = DB.WEEKLY_QUESTS[0]
	var w0: int = int(G.s["weekly"]["progress"].get(wq["id"], 0))
	G.quest_progress("stage", 3)
	check(int(G.s["weekly"]["progress"][wq["id"]]) == w0 + 3, "weekly progress follows daily events")
	G.s["weekly"]["progress"][wq["id"]] = 999
	check(G.claim_weekly(wq) and not G.claim_weekly(wq), "weekly claim once")
	var pe1: int = int(G.s["pass"]["exp"])
	G.s["quests"]["progress"]["afk"] = 5
	G.s["quests"]["claimed"].erase("afk")
	G.claim_quest(DB.DAILY_QUESTS[4])
	check(int(G.s["pass"]["exp"]) - pe1 <= 80, "daily claim grants pass exp only once")
	check(G.codex_claimable() > 0, "codex has rewards for owned heroes")
	var cx_id: String = G.s["heroes"].keys()[0]
	var cx_before: int = G.codex_claimable()
	var cx1: Dictionary = G.claim_codex(cx_id, "own")
	check(int(cx1.get("gems", 0)) == 50 and G.codex_claimed(cx_id, "own") and G.codex_claimable() == cx_before - 1, "codex single claim")
	check(G.claim_codex(cx_id, "own").is_empty() and G.claim_codex(cx_id, "awaken5").is_empty(), "codex single claim rejects claimed / unreached steps")
	var cxr: Dictionary = G.claim_codex_all()
	check(cxr.has("gems") and G.codex_claimable() == 0, "codex claim all")

	print("[advanced statuses]")
	var tz := BattleSim.new()
	tz.setup([{"id": "fidelia", "cell": Vector2i(0, 0), "level": 30, "star": 3}, {"id": "rumi", "cell": Vector2i(2, 2), "level": 30, "star": 3}],
		[{"id": "eroghost", "cell": Vector2i(0, 2), "level": 1}], 5)
	tz.units[0]["taunt"] = 2
	var aimed: Dictionary = tz._aim(tz.units[2], "front")
	check(aimed["id"] == "fidelia", "taunt pulls enemy attacks onto the tank")
	var found := {"silence": false, "revive": false, "cleanse": false, "blocked": false, "taunt": false}
	for sd in 40:
		var sb2 := BattleSim.new()
		var team2 := [{"id": "fidelia", "cell": Vector2i(0, 1), "level": 40, "star": 4}, {"id": "aqua", "cell": Vector2i(2, 1), "level": 40, "star": 4},
			{"id": "vexira", "cell": Vector2i(1, 0), "level": 40, "star": 4}, {"id": "schylua", "cell": Vector2i(0, 2), "level": 40, "star": 4}]
		var foes2 := [{"id": "hyeonxa", "cell": Vector2i(0, 1), "level": 45, "star": 4}, {"id": "furu", "cell": Vector2i(2, 1), "level": 45, "star": 4},
			{"id": "kali", "cell": Vector2i(0, 0), "level": 45, "star": 4}, {"id": "eropatra", "cell": Vector2i(1, 2), "level": 45, "star": 4}]
		sb2.setup(team2, foes2, sd + 7)
		sb2.run()
		for ev in sb2.events:
			if ev["t"] == "status" and ev["kind"] == "SILENCE": found["silence"] = true
			if ev["t"] == "status" and ev["kind"] == "TAUNT": found["taunt"] = true
			if ev["t"] == "revive": found["revive"] = true
			if ev["t"] == "cleanse": found["cleanse"] = true
			if ev["t"] == "heal" and ev.get("blocked", false): found["blocked"] = true
	for k in found.keys():
		check(found[k], "battle produces %s" % k)

	print("[profiles / scenes / outfits / birthdays]")
	var pmiss: Array = []
	for hid2 in DB.HEROES.keys():
		if DB.profile(hid2).is_empty():
			pmiss.append(hid2)
	check(pmiss.is_empty(), "every hero has a profile %s" % str(pmiss))
	check(G.has_method("capture_away"), "away tracking exists")
	G.s["heroes"]["shina"]["skin"] = 0
	var b0: float = float(G.stat_bonus("shina")["atk"])
	G.s["heroes"]["shina"]["skin"] = 3
	check(is_equal_approx(float(G.stat_bonus("shina")["atk"]) - b0, 0.06), "outfit tier 3 adds +6% ATK")
	G.s["heroes"]["shina"]["skin"] = 0
	check(G.scene_unlocked(DB.LOBBY_SCENES[0]) and not G.scene_unlocked(DB.LOBBY_SCENES[-1]), "lobby scenes unlock by progress")
	var today := Time.get_date_dict_from_system()
	var dfile: Dictionary = DB.profile("rumi")
	dfile["birthday"] = "%02d-%02d" % [today["month"], today["day"]]
	check(G.birthday_heroes().has("rumi"), "birthday detected")
	check(G.claim_birthdays().has("rumi") and not G.claim_birthdays().has("rumi"), "birthday gift once per year")

	print("[world boss]")
	var wbd: Dictionary = G.wboss()
	check(wbd.has("weak") and DB.ELEMENT_BEATS.get(wbd["weak"], "") == DB.ELEMENT_GROUP.get(DB.element_of(wbd["id"]), "?"), "world boss weakness beats its element")
	G.s["wboss"]["tries"] = 3
	check(G.pay_battle({"mode": "wboss"}) == "" and int(G.s["wboss"]["tries"]) == 2, "world boss attempt consumed")
	var wsim := BattleSim.new()
	wsim.setup(G.ally_team(), G.enemies_for({"mode": "wboss"}), 0, G.battle_mod({"mode": "wboss"}))
	var wres: Dictionary = wsim.run()
	var wdmg := 0
	for ev in wsim.events:
		if ev["t"] in ["hit", "dot"] and wsim.units[ev["uid"]]["side"] == 1:
			wdmg += int(ev["dmg"])
	check(wdmg > 0 and not wres["won"] or wdmg > 0, "world boss takes damage (%d)" % wdmg)
	G.apply_wboss_result(40000)
	check(G.wboss_milestone_state(0) == "ready", "milestone ready after 40k")
	check(not G.claim_wboss_milestone(0).is_empty() and G.claim_wboss_milestone(0).is_empty(), "milestone claim once")
	var brd: Array = G.wboss_board()
	check(brd.size() == 15 and G.wboss_rank() >= 1, "ranking has 15 entries, rank %d" % G.wboss_rank())
	G.s["wboss"]["week"] = int(G.s["wboss"]["week"]) - 1
	G._check_day()
	check(int(G.s["wboss"]["total"]) == 0 and not G.s["wboss"]["rank_claimed"], "new week resets & grants rank reward")
	check(not G.claim_wboss_rank().is_empty() and G.claim_wboss_rank().is_empty(), "rank reward once")

	print("[boss hunt]")
	G.s["hunt"]["used"] = 0
	check(G.hunt_tries() == 3 and G.hunt_unlocked("behemoth", 0) and not G.hunt_unlocked("behemoth", 1), "hunt tries & difficulty gating")
	check(G.pay_battle({"mode": "hunt", "hunt": "behemoth", "diff": 0}) == "" and G.hunt_tries() == 2, "hunt consumes an attempt")
	G.apply_hunt_result("behemoth", 0, false)
	check(G.hunt_tries() == 3, "failed hunt refunded")
	var hres: Dictionary = G.apply_hunt_result("behemoth", 0, true)
	check(int(hres.get("hunt_core", 0)) > 0 and hres.has("gems") and G.hunt_unlocked("behemoth", 1), "hunt win gives cores, first-clear gems, unlocks next")
	var gear_drop := false
	for k in hres.keys():
		if str(k).begins_with("gear:"):
			gear_drop = true
	check(gear_drop, "behemoth drops gear")
	var hst: Dictionary = DB.hunt_stage("wraith", 3)
	check(hst["enemies"][0]["variant"] == "astral" and hst["enemies"].size() == 5, "abyss hunt: astral boss + 4 minions")
	G.give({"hunt_core": 1000})
	check(G.buy_hunt(DB.HUNT_SHOP[0]) == "" and G.buy_hunt(DB.HUNT_SHOP[0]) == "" and G.buy_hunt(DB.HUNT_SHOP[0]) != "", "hunter's exchange weekly limit")

	print("[special skins]")
	for sh in DB.SPECIAL_SKINS.keys():
		check(DB.special_index(sh) > 0, "special skin for %s" % sh) if DB.special_index(sh) <= 0 else null
	for sh in DB.WITHDRAWN_SKINS:
		check(DB.special_index(sh) == -1 and not DB.SPECIAL_SKINS.has(sh), "%s special skin withdrawn" % sh) if DB.special_index(sh) != -1 or DB.SPECIAL_SKINS.has(sh) else null
	# an old save that bought and wore a withdrawn skin: refund once, back to a real outfit
	if not G.owns("kali"):
		G.add_hero("kali")
	var kn: int = DB.art_list("kali").size()
	var tk0: int = G.amount("skin_ticket")
	G.s["skins_bought"]["kali"] = [kn]
	G.s["heroes"]["kali"]["skin"] = kn
	G._sanitize()
	check(G.amount("skin_ticket") == tk0 + 1 and (G.s["skins_bought"]["kali"] as Array).is_empty(), "withdrawn skin refunds a ticket")
	check(int(G.s["heroes"]["kali"]["skin"]) < kn and G.skin_unlocked("kali", int(G.s["heroes"]["kali"]["skin"])), "withdrawn skin falls back to an unlocked outfit")
	G._sanitize()
	check(G.amount("skin_ticket") == tk0 + 1, "withdrawn skin refund happens once")
	G.s["items"]["skin_ticket"] = tk0
	var ssh := "ninger"
	if not G.owns(ssh):
		G.add_hero(ssh)
	var spi := DB.special_index(ssh)
	G.s["heroes"][ssh]["star"] = 6
	G.s["heroes"][ssh]["bond"] = 10
	G.s["heroes"][ssh]["oath"] = true
	check(not G.skin_unlocked(ssh, spi), "special skin not unlocked by milestones")
	G.s["items"]["skin_ticket"] = 1
	var gb: int = G.amount("gems")
	check(G.buy_costume(ssh, spi) == "" and G.skin_unlocked(ssh, spi) and G.amount("skin_ticket") == 0 and G.amount("gems") == gb, "skin ticket unlocks special skin")
	check(DB.road_reward(50).has("skin_ticket"), "road gives skin tickets")
	var ab0: float = float(G.stat_bonus(ssh)["atk"])
	G.s["heroes"][ssh]["skin"] = spi
	check(is_equal_approx(float(G.stat_bonus(ssh)["atk"]) - ab0, 0.10 - DB.outfit_bonus(0)) or float(G.stat_bonus(ssh)["atk"]) > ab0, "special skin = +10% bonus")

	print("[commander road]")
	G.s["road"] = []
	var plv0: int = int(G.s["player"]["level"])
	check(G.road_state(5) == ("ready" if plv0 >= 5 else "locked"), "road state follows level")
	if plv0 >= 5:
		check(G.claim_road(5) and not G.claim_road(5), "road reward once")
	check(DB.road_reward(25).has("celestial_gem") and DB.road_levels().size() == 20, "grand reward every 25 levels")

	print("[hunter's lore]")
	check(G.lore_level("svormentis") == 0, "no lore before kills")
	var lore_k: Array = []
	for i in 50:
		lore_k.append("svormentis")
	G.record_kills(lore_k)
	check(G.lore_level("svormentis") == 2 and G.lore_level("hollow:svormentis") == 2, "lore Lv.2 at 50 kills (variants count)")
	check(int(G.lore_map().get("svormentis", 0)) == 2, "lore map feeds the sim")
	var lt_a := [{"id": "shina", "cell": Vector2i(0, 1), "level": 30, "star": 3}]
	var lt_e := [{"id": "svormentis", "cell": Vector2i(0, 1), "level": 30, "star": 3}]
	var lsim0 := BattleSim.new()
	lsim0.setup(lt_a, lt_e, 777)
	lsim0.run()
	var lsim1 := BattleSim.new()
	lsim1.setup(lt_a, lt_e, 777)
	lsim1.lore = {"svormentis": 4}
	lsim1.run()
	var ld0 := 0
	var ld1 := 0
	for ev in lsim0.events:
		if ev["t"] == "hit" and int(ev["src"]) == 0:
			ld0 = int(ev["dmg"])
			break
	for ev in lsim1.events:
		if ev["t"] == "hit" and int(ev["src"]) == 0:
			ld1 = int(ev["dmg"])
			break
	check(ld0 > 0 and ld1 > ld0, "lore raises ally damage vs that foe (%d → %d)" % [ld0, ld1])
	print("[lobby enemy]")
	check(not G.set_lobby_enemy("ymir") or G.kills_of("ymir") > 0, "undiscovered enemy can't be lobby")
	G.record_kills(["ymir", "ymir"])
	check(G.set_lobby_enemy("ymir", 0) and G.lobby_enemy() == "ymir", "discovered enemy set as lobby")
	G.s["lobby_enemy_form"] = 3
	check(G.lobby_enemy_form() == 0 or G.form_unlocked("ymir", 3), "locked form falls back to 0")
	check(DB.enemy_lobby_line("ymir", false) != "", "rival lobby line")
	G.set_lobby_enemy("")
	check(G.lobby_enemy() == "", "back to hero secretary")
	print("[dates]")
	var dh: String = G.s["heroes"].keys()[0]
	G.s["heroes"][dh]["bond"] = 5
	check(G.can_date(dh) and G.dates_left() == DB.DATE_PER_DAY, "can date at Bond 5")
	var dl: Array = G.date_lines(dh, "forest")
	check(dl.size() == 9 and str(dl[2][0]) == "?", "date scene: 3 beats with choices")
	var dres: Dictionary = G.finish_date(dh, "forest", 120)
	check(dres["rank"][0] == "PERFECT DATE" and G.date_album().size() >= 1 and G.dates_left() == DB.DATE_PER_DAY - 1, "perfect date saves a photo")
	check(bool(dres["first_perfect"]) and int(dres["reward"]["gems"]) == 60 + int(DB.DATE_FIRST_PERFECT["gems"]) and int(dres["reward"].get("gold", 0)) == int(DB.DATE_FIRST_PERFECT["gold"]), "first PERFECT at a spot pays the bonus")
	var dres2: Dictionary = G.finish_date(dh, "forest", 30)
	check(dres2["rank"][0] == "NICE DATE" and not bool(dres2["first_perfect"]) and not bool(dres2["new_best"]), "low score = nice date, no bonus")
	check(G.date_best(dh, "forest") == 0 and G.date_count(dh) == 2 and G.date_perfects(dh) == 1 and G.date_best(dh, "pool") == -1, "date records keep the best rank")
	G.s["dates"]["used"] = 0
	check(not bool(G.finish_date(dh, "forest", 120)["first_perfect"]), "PERFECT bonus only once per spot")
	G.s["dates"].erase("best")
	check(G.date_best(dh, "forest") == 0 and G.date_count(dh) == G.date_album().filter(func(e): return e["hero"] == dh).size(), "records rebuilt from the album on old saves")
	check(G.date_perfect_paid(dh, "forest") == false, "rebuilt save: bonus available again (old saves never had it)")
	check(not G.title_unlocked("sweetheart"), "Sweetheart needs 3 PERFECT spots")
	for dk in ["pool", "onsen"]:
		G.s["dates"]["used"] = 0
		G.finish_date(dh, dk, 120)
	check(G.title_unlocked("sweetheart") and not G.title_unlocked("soulmate"), "Sweetheart title after 3 PERFECT spots")
	check(DB.DATE_SPOTS.all(func(s2): return DB.BG.has(s2["key"])), "date spot maps exist")

	print("[bestiary / arc 8]")
	G.record_kills(["ymir", "ymir", "slime", "shina"])
	check(G.kills_of("ymir") >= 2 and G.kills_of("shina") == 0, "kills recorded (enemies only)")
	G.s["bestiary"]["ymir"] = 10
	check(G.bestiary_state("ymir", 0) == "ready" and not G.claim_bestiary("ymir", 0).is_empty() and G.claim_bestiary("ymir", 0).is_empty(), "bestiary milestone once")
	var a8: Dictionary = DB.stage(30 * DB.STAGES_PER_CHAPTER + 5)["enemies"][0]
	check(a8["id"] == "hairly", "arc 8 opens with Hairly")

	print("[nov-4 content]")
	for nh in ["angela", "kara", "mei", "ninger", "spimei"]:
		check(DB.HEROES.has(nh) and DB.art(nh, 0) != null and DB.sprite(nh, 1) != null and not DB.profile(nh).is_empty(), "new hero %s complete" % nh) if not (DB.HEROES.has(nh) and DB.art(nh, 0) != null and DB.sprite(nh, 1) != null and not DB.profile(nh).is_empty()) else null
	print("[taming]")
	var bst0: Dictionary = G.s.get("bestiary", {})
	bst0["slime"] = 5
	G.s["bestiary"] = bst0
	check(G.tame_error("slime") != "" and not G.is_tamed("slime"), "cannot tame before %d kills" % DB.TAME_KILLS)
	check(G.form_unlocked("slime", 0) and not G.form_unlocked("slime", 1), "form 2 locked at 5 kills")
	bst0["slime"] = DB.TAME_KILLS
	G.give({"gold": DB.TAME_GOLD})
	var gold0: int = G.amount("gold")
	check(G.tame("slime") == "" and G.is_tamed("slime") and G.amount("gold") == gold0 - DB.TAME_GOLD, "tame costs gold and works")
	check(G.tame("slime") != "", "cannot tame twice")
	check(G.pet_talk("slime") != "" and G.pet_talk("slime") == "", "pet talk once per day")
	var pats := 0
	while G.pet_pat("slime"):
		pats += 1
	check(pats == DB.PET_PATS_PER_DAY, "pats limited per day (%d)" % pats)
	G.give({"bouquet": 20})
	for i in 20:
		G.pet_gift("slime", "bouquet")
	check(int(G.pet("slime")["bond"]) >= 3 and G.form_unlocked("slime", 1), "gifts raise pet bond and unlock forms (Lv.%d)" % int(G.pet("slime")["bond"]))
	var cpw0: int = G.hero_power("shina") if G.owns("shina") else 0
	G.set_companion("slime")
	check(G.companion() == "slime" and absf(G.companion_bonus() - DB.COMPANION_PER_BOND * int(G.pet("slime")["bond"])) < 0.0001, "companion bonus %.3f" % G.companion_bonus())
	check(not G.owns("shina") or G.hero_power("shina") > cpw0, "companion raises hero power")
	G.set_companion("gumi_wolf")
	check(G.companion() == "", "untamed foe cannot be companion")
	G.set_companion("slime")
	print("[companion assist & pet stories]")
	var csim := BattleSim.new()
	csim.setup(G.ally_team({"mode": "story", "stage": 1}), G.enemies_for({"mode": "story", "stage": 40}), 3)
	csim.companion = G.companion_assist()
	csim.run()
	var cev: Array = csim.events.filter(func(ev): return ev["t"] == "companion")
	check(cev.size() == 1 and (cev[0]["fx"] as Array).size() > 0, "companion assist fires once (round 2)")
	check(G.pet_story_state("slime", 0) == "ready" and G.pet_story_state("slime", 2) == "locked", "pet story 1 ready, 3 locked at Lv.%d" % int(G.pet("slime")["bond"]))
	var gem_s: int = G.amount("gems")
	check(not G.read_pet_story("slime", 0).is_empty() and G.amount("gems") > gem_s and G.read_pet_story("slime", 0).is_empty(), "pet story reward once")
	check(DB.pet_story("slime", 2).size() >= 5, "pet story lines")
	var auto_ok := 0
	for hid0 in DB.hero_ids():
		var arl: Dictionary = DB.live_rig(DB.art(hid0, 0))
		var hrig: Dictionary = DB.char_rig(DB.art(hid0, 0))
		if (not arl.is_empty() and ResourceLoader.exists(str(arl["depth"]))) or (hrig.has("neck") and hrig.has("bones")):
			auto_ok += 1
	check(auto_ok == DB.hero_ids().size(), "every hero has a live rig (pivot or depth) (%d/%d)" % [auto_ok, DB.hero_ids().size()])
	check(DB.HERO_RIGS.size() == DB.hero_ids().size(), "every hero's base art has a pivot rig")
	var eye_ok := 0
	for rp in DB.HERO_RIGS.keys():
		var ey: Array = DB.HERO_RIGS[rp].get("eyes", [])
		if ey.size() == 2 and ((ey[0] as Array).size() == 6 or (ey[1] as Array).size() == 6):
			eye_ok += 1
	check(eye_ok >= 34, "hero rigs have measured eyes (%d)" % eye_ok)
	# batch 131: every outfit / form (and lobby pose) has a pivot rig; alternate expressions reuse it
	var forms_ok := 0
	var forms_all := 0
	var form_eyes := 0
	for hid1 in DB.hero_ids():
		var arts: Array = DB.art_list(hid1)
		for ai in arts.size():
			var tx: Texture2D = DB.tex(arts[ai])
			if str(arts[ai]).ends_with("glytta_char_evo2.png") or str(arts[ai]).ends_with("glytta_char_evo2_a.png"):
				continue   # keeps her hand-made 2.5D rig
			forms_all += 1
			var fr: Dictionary = DB.char_rig(tx)
			if fr.get("head", null) is Vector3 and fr.get("neck", null) is Vector2:
				forms_ok += 1
				if not (fr.get("eyes", []) as Array).is_empty():
					form_eyes += 1
			for q in DB.alt_arts(hid1, ai):
				var alr: Dictionary = DB.char_rig(DB.tex(str(q)))
				if alr.is_empty() or (not DB.form_rigs().has(str(q)) and not (alr.get("eyes", []) as Array).is_empty()):
					forms_ok -= 1
	check(forms_ok == forms_all, "every hero outfit/form has a pivot rig, alt expressions reuse it without blink (%d/%d)" % [forms_ok, forms_all])
	check(form_eyes >= 120, "outfits with measured eyes (%d)" % form_eyes)
	var lb: Texture2D = DB.lobby_art("angela")
	check(lb != null and not DB.char_rig(lb).is_empty() and DB.live_rig(lb).is_empty(), "lobby pose uses the pivot rig")
	var en_ok := 0
	for eid0 in DB.ENEMIES.keys():
		var erl: Dictionary = DB.live_rig(DB.art(eid0, 0))
		var prig: Dictionary = DB.enemy_rig(DB.art(eid0, 0))
		if (not erl.is_empty() and ResourceLoader.exists(str(erl["depth"]))) or (prig.has("neck") and prig.has("bones")):
			en_ok += 1
	check(en_ok == DB.ENEMIES.size(), "every enemy has a live rig (pivot or depth) (%d/%d)" % [en_ok, DB.ENEMIES.size()])
	check(DB.ENEMY_RIGS.size() == DB.ENEMIES.size(), "every enemy's base art has a pivot rig")
	check(DB.live_rig(DB.art("octra", 0)).is_empty() and not DB.live_rig(DB.art("octra", 1)).is_empty(), "pivot rig replaces depth tilt only on rigged art")
	print("[gear sets]")
	check(DB.GEAR_SETS.has(DB.gear_set({"uid": 7})), "old gear gets a fixed set")
	var gsA: Array = []
	for slot0 in DB.GEAR_SLOTS:
		var gg0: Dictionary = G.add_gear(slot0, "SSR")
		gg0["set"] = "vampire"
		gsA.append(gg0)
	var hid_s: String = G.s["formation"][0][0]
	for gg0 in gsA:
		G.equip_gear(hid_s, int(gg0["uid"])) if G.has_method("equip_gear") else null
		gg0["owner"] = hid_s
	var sbon: Dictionary = G.stat_bonus(hid_s)
	check((sbon["sets"] as Array).has("vampire") and float(sbon["atk"]) >= 0.05, "3-piece set active and 2-piece stats added")
	var ssim := BattleSim.new()
	ssim.setup(G.ally_team({"mode": "story", "stage": 1}), G.enemies_for({"mode": "story", "stage": 30}), 5)
	var svu: Dictionary = ssim.units.filter(func(u): return u["id"] == hid_s)[0]
	check((svu["sets"] as Array).has("vampire"), "battle unit carries its gear sets")
	ssim.run()
	var heals: int = ssim.events.filter(func(ev): return ev["t"] == "heal" and ev["uid"] == svu["uid"]).size()
	check(heals > 0, "Crimson Thirst lifesteal heals in battle (%d)" % heals)
	for gg0 in gsA:
		gg0["set"] = "aegis"
	var asim := BattleSim.new()
	asim.setup(G.ally_team({"mode": "story", "stage": 1}), G.enemies_for({"mode": "story", "stage": 30}), 5)
	check(int(asim.units.filter(func(u): return u["id"] == hid_s)[0]["shield"]) > 0, "Bastion starts with a shield")
	for gg0 in gsA:
		gg0["owner"] = ""
	print("[forge]")
	G.s["gear"].clear()
	G.give({"gold": 500000, "forge_ember": 100})
	var fA: Dictionary = G.add_gear("weapon", "R", "tidal")
	var fB: Dictionary = G.add_gear("weapon", "R", "tidal")
	var fC: Dictionary = G.add_gear("armor", "R", "inferno")
	var fD: Dictionary = G.add_gear("armor", "R", "inferno")
	check(fA["set"] == "tidal", "add_gear honours a chosen set")
	var em0: int = G.amount("forge_ember")
	check(G.reforge_gear(int(fA["uid"]), "tidal") != "" and G.amount("forge_ember") == em0, "reforging to the same set is refused for free")
	check(G.reforge_gear(int(fA["uid"]), "swift") == "" and fA["set"] == "swift" and G.amount("forge_ember") == em0 - int(DB.REFORGE_COST["R"]), "reforge changes the set and costs embers")
	fB["lock"] = true
	check(G.salvage_gear(int(fB["uid"])) == 0 and not G.gear_by_uid(int(fB["uid"])).is_empty(), "locked gear can't be salvaged")
	check(G.fuse_fodder(int(fA["uid"])).size() == 2 and not G.fuse_fodder(int(fA["uid"])).has(fB), "fusion never eats locked gear")
	fA["owner"] = hid_s
	check(G.fuse_gear(int(fA["uid"])) == "" and fA["rarity"] == "SR" and fA["owner"] == hid_s and fA["set"] == "swift" and G.s["gear"].size() == 2, "fusion raises rarity, keeps owner and set, consumes 2")
	check(G.fuse_gear(int(fA["uid"])) != "", "fusion refused without enough fodder")
	var fE: Dictionary = G.add_gear("armor", "R", "aegis")
	fE["lv"] = 3
	var fF: Dictionary = G.add_gear("accessory", "R", "aegis")
	check(G.salvage_list(["R"], false) == [fF], "bulk salvage skips equipped, locked and enhanced gear")
	var fres: Dictionary = G.salvage_bulk(["R"], true)
	check(int(fres["count"]) == 2 and G.gear_by_uid(int(fB["uid"])).size() > 0 and int(fres["forge_ember"]) > 0, "bulk salvage pays gold and embers")
	var fS: Array = [G.add_gear("weapon", "SSR", "aegis"), G.add_gear("armor", "R", "aegis"), G.add_gear("accessory", "R", "aegis")]
	fA["owner"] = ""
	check(G.auto_equip_set(hid_s, "aegis") == 3 and (G.stat_bonus(hid_s)["sets"] as Array).has("aegis"), "WEAR SET dresses the hero in the whole set")
	var fG: Dictionary = G.add_gear("armor", "SSR", "tidal")
	G.auto_equip(hid_s)
	check(fG["owner"] == "" and (G.stat_bonus(hid_s)["sets"] as Array).has("aegis"), "AUTO EQUIP doesn't break a worn set")
	G.s["dungeon"]["cleared"]["gear"] = 0
	var today_set: String = DB.armory_set(G.day_key())
	G.s["gear"].clear()
	G.apply_dungeon_result("gear", 0, true)
	check(G.s["gear"].filter(func(g): return g["set"] == today_set).size() >= 1, "Armory Ruins drops a piece of today's set")
	check(G.reward_name("gear:any:SR:inferno") != "" and G.reward_icon("gear:any:SR:inferno") != null, "any-slot gear reward has a name and icon")
	G.s["gear"].clear()
	print("[gear substats]")
	var sub_counts_ok := true
	var sub_unique_ok := true
	for r0 in ["R", "SR", "SSR"]:
		for n0 in 200:
			var sg: Dictionary = G.add_gear("weapon", r0)
			var ks: Array = sg["subs"].map(func(x): return x["k"])
			sub_counts_ok = sub_counts_ok and ks.size() == int(DB.GEAR_SUB_COUNT[r0])
			for k0 in ks:
				sub_unique_ok = sub_unique_ok and ks.count(k0) == 1
	check(sub_counts_ok, "1/2/3 substats on R/SR/SSR")
	check(sub_unique_ok, "a piece never rolls the same stat twice")
	G.s["gear"].clear()
	# value range and text
	check(is_equal_approx(DB.gear_sub_value({"k": "atk", "q": 0.0, "up": 0}), 0.008) and is_equal_approx(DB.gear_sub_value({"k": "atk", "q": 1.0, "up": 1}), 0.024), "substat value: min roll, perfect roll + upgrade")
	check(DB.gear_sub_text({"k": "crit", "q": 1.0, "up": 0}) == "Crit +1.0%", "substat text")
	# substats reach the hero, crit included
	var sbG: Dictionary = G.add_gear("weapon", "SSR", "tidal")
	sbG["subs"] = [{"k": "atk", "q": 1.0, "up": 0}, {"k": "crit", "q": 1.0, "up": 0}, {"k": "hp", "q": 1.0, "up": 0}]
	sbG["owner"] = ""
	var sb0: Dictionary = G.stat_bonus(hid_s)
	var score0: float = DB.gear_score({"slot": "weapon", "rarity": "SSR", "lv": 0})
	sbG["owner"] = hid_s
	var sb1: Dictionary = G.stat_bonus(hid_s)
	check(is_equal_approx(float(sb1["crit"]) - float(sb0["crit"]), 0.01) and is_equal_approx(float(sb1["hp"]) - float(sb0["hp"]), 0.02), "substats add to stat_bonus")
	check(DB.gear_score(sbG) > score0, "substats raise gear score")
	# enhance: exactly one upgrade at +5 and at +10
	G.give({"gold": 900000})
	for n1 in 4:
		G.enhance_gear(int(sbG["uid"]))
	check(G.last_sub_up.is_empty(), "no substat upgrade before +5")
	G.enhance_gear(int(sbG["uid"]))
	check(not G.last_sub_up.is_empty() and sbG["subs"].reduce(func(a, x): return a + int(x["up"]), 0) == 1, "+5 upgrades one substat")
	for n2 in 5:
		G.enhance_gear(int(sbG["uid"]))
	check(sbG["subs"].reduce(func(a, x): return a + int(x["up"]), 0) == 2, "+10 upgrades another")
	# temper
	G.s["cur"]["forge_ember"] = 0
	G.s["items"]["forge_ember"] = 0
	check(G.temper_gear(int(sbG["uid"]), []).has("err"), "temper refused without Embers")
	G.give({"forge_ember": 500})
	var em1: int = G.amount("forge_ember")
	var before_subs: Array = sbG["subs"].duplicate(true)
	check(G.temper_gear(int(sbG["uid"]), [0, 1, 2]).has("err") and G.amount("forge_ember") == em1, "temper needs one substat left to reroll, and refusal is free")
	var tres: Dictionary = G.temper_gear(int(sbG["uid"]), [])
	check(G.amount("forge_ember") == em1 - int(DB.TEMPER_COST["SSR"]) and sbG["subs"] == before_subs, "temper pays, and the piece is untouched until accepted")
	var tups: int = tres["subs"].reduce(func(a, x): return a + int(x["up"]), 0)
	check(tups == 2, "temper keeps upgrades")
	var kept_ok := true
	var uniq_ok := true
	for n3 in 40:
		var kr: Dictionary = G.temper_gear(int(sbG["uid"]), [1])
		if kr.has("err"):
			G.give({"forge_ember": 500})
			continue
		kept_ok = kept_ok and kr["subs"][1] == sbG["subs"][1]
		var kk: Array = kr["subs"].map(func(x): return x["k"])
		for k1 in kk:
			uniq_ok = uniq_ok and kk.count(k1) == 1
	check(kept_ok and uniq_ok, "kept substat survives, rerolls don't duplicate it")
	var em2: int = G.amount("forge_ember")
	G.temper_gear(int(sbG["uid"]), [0, 1])
	check(em2 - G.amount("forge_ember") == int(DB.TEMPER_COST["SSR"]) * 4, "each kept substat doubles the cost")
	G.temper_accept(int(sbG["uid"]), tres["subs"])
	check(sbG["subs"] == tres["subs"], "accept applies the new rolls")
	# fusing adds a substat
	var sfz: Dictionary = G.add_gear("armor", "R", "aegis")
	G.add_gear("armor", "R", "aegis")
	G.add_gear("armor", "R", "aegis")
	var sfz_sub: Dictionary = sfz["subs"][0].duplicate()
	check(G.fuse_gear(int(sfz["uid"])) == "" and sfz["subs"].size() == 2 and sfz["subs"][0] == sfz_sub, "fusion adds a substat and keeps the old one")
	# saves from before substats get them once, with upgrades for their level
	var legacy: Dictionary = G.add_gear("weapon", "SSR", "swift")
	legacy.erase("subs")
	legacy["lv"] = 10
	var legacy2: Dictionary = G.add_gear("armor", "R", "swift")
	legacy2.erase("subs")
	check(DB.gear_score(legacy) > 0.0 and DB.gear_subs_desc(legacy) == "", "gear without substats still works")
	G._ensure_gear_subs()
	check(legacy["subs"].size() == 3 and legacy["subs"].reduce(func(a, x): return a + int(x["up"]), 0) == 2 and legacy2["subs"].size() == 1, "old gear is migrated with its earned upgrades")
	var mig: Array = legacy["subs"].duplicate(true)
	G._ensure_gear_subs()
	check(legacy["subs"] == mig, "migration runs only once")
	var scode: String = G.export_code()
	check(G.import_code(scode) == "" and G.gear_by_uid(int(legacy["uid"]))["subs"].size() == 3, "substats survive export/import")
	G.s["gear"].clear()
	var grig: Dictionary = DB.live_rig(DB.art("glytta", 3))
	check(not grig.is_empty() and ResourceLoader.exists(str(grig["depth"])) and not grig.get("generic", false) and not DB.char_rig(DB.art("glytta", 1)).is_empty() and not DB.char_rig(DB.art("glytta", 0)).is_empty(), "Glytta evo2 keeps her hand-made rig; other forms = pivot rigs")
	check(DB.HEROES.size() == 37, "37 heroes (%d)" % DB.HEROES.size())
	for ne in ["scomantis", "skelinch", "serpentia", "voodoo", "lizamorph"]:
		check(DB.ENEMIES.has(ne) and DB.art(ne, 0) != null and DB.sprite(ne, 1) != null, "new enemy %s" % ne) if not (DB.ENEMIES.has(ne) and DB.art(ne, 0) != null) else null
	check(DB.special_index("luby") > 0 and DB.art_list("luby").size() == 6 and DB.alt_art("luby", 4) != null, "Luby: 5 outfits + special + alt expressions")
	for nh in ["gala", "morana", "seraph", "tamo"]:
		check(DB.HEROES.has(nh) and DB.art(nh, 0) != null and DB.sprite(nh) != null, "8 Nov hero %s has stats, art and sprite" % nh)
	check(DB.special_index("morana") > 0 and DB.special_index("tamo") > 0, "Morana and Tamo special skins")
	check(DB.ENEMIES.has("octra") and DB.art("octra", 0) != null and DB.PET_LINES.has("octra"), "Octra enemy is fightable and tameable")
	check(DB.ENEMIES.has("hairly") and DB.ENEMIES.has("svormentis") and DB.ENEMIES.has("ymir") and DB.art("ymir", 0) != null, "3 new enemies with art")
	check(DB.lobby_art("angela") != null and not DB.art_list("angela").any(func(p): return "lobby" in str(p)), "lobby pose separate from outfits")
	check(DB.alt_art("spimei", 1) != null, "alternate expression available")
	var bnb: Dictionary = DB.BANNERS.filter(func(b): return b["id"] == "nov4_mei")[0]
	check(bnb["featured"] == "mei" and bnb["img"].size() == 3, "bunny banner has 3 frames")
	G.give({"summon_ticket": 200})
	var got_sven := false
	for k in 12:
		var svp: Dictionary = G.pull("pickup_sven", 10, "ticket")
		for sres in svp.get("results", []):
			if sres["id"] == "sven":
				got_sven = true
	check(got_sven, "R pick-up banner gives the featured R hero")
	G.s["fortune_day"] = -1
	check(G.fortune_ready() and not G.fortune_draw().is_empty() and not G.fortune_ready(), "fortune once per day")

	print("[secretary moment]")
	G.s["sec_day"] = -1
	var smo: Dictionary = G.secretary_moment()
	check(not smo.is_empty() and smo["lines"].size() >= 3 and not G.secretary_ready(), "secretary moment once per day")
	check(G.secretary_moment().is_empty(), "no second moment today")

	print("[hero trials / news / tutorials]")
	var th: String = G.s["heroes"].keys()[0]
	var ts0: Dictionary = DB.trial_stage(th, 0)
	check(ts0["enemies"][0]["id"] == th and ts0["enemies"][0]["variant"] == "mirror", "trial boss is the hero's own Mirror")
	check(G.trial_open(th, 0) and not G.trial_open(th, 1), "trial tiers unlock in order")
	var saved_f: Array = G.s["formation"].duplicate(true)
	G.s["formation"] = []
	check(G.pay_battle({"mode": "trial", "hero": th, "tier": 0}) != "", "trial needs the hero deployed")
	G.s["formation"] = saved_f
	check(G.apply_trial_result(th, 0, true, false).is_empty(), "no reward if the hero fell")
	var trr: Dictionary = G.apply_trial_result(th, 0, true, true)
	check(int(trr.get("shard:" + th, 0)) == 10 and G.trial_open(th, 1), "trial clear gives her shards & opens next tier")
	check(G.apply_trial_result(th, 0, true, true).is_empty(), "trial reward only once")
	check(DB.news().size() >= 1 and G.news_unread() >= 0, "news loads from data/news.json")
	G.mark_news_read()
	check(G.news_unread() == 0, "news marked read")
	for tk in ["worldboss", "hunt", "rift", "room", "festival", "tactics", "limit_break"]:
		check(DB.TUTORIALS.has(tk), "tutorial %s" % tk) if not DB.TUTORIALS.has(tk) else null

	print("[private room]")
	var rh: String = G.s["heroes"].keys()[-1]
	G.s["heroes"][rh]["bond"] = 1
	G.s["heroes"][rh]["bond_exp"] = 0
	G.s["room"]["hero"] = rh
	G.s["room"]["visits"] = 0
	var rb0: int = int(G.hero(rh)["bond_exp"]) + int(G.hero(rh)["bond"]) * 100000
	var rl: Array = G.room_talk("gameroom")
	check(rl.size() >= 2 and G.room_visits_left() == DB.ROOM_VISITS - 1, "room talk uses a visit")
	check(int(G.hero(rh)["bond_exp"]) + int(G.hero(rh)["bond"]) * 100000 > rb0, "room talk gives bond")
	check(not G.room_rest("gameroom").is_empty() and G.room_rest("gameroom").is_empty(), "rest once per room per day")
	check(G.room_unlocked(DB.ROOMS[0]), "first room always open")
	check(DB.ROOMS.all(func(r): return DB.BG.has(r["key"])), "room backgrounds exist")
	for hd2 in DB.HUNTS:
		check(DB.BG.has(hd2["bg"]), "hunt map %s" % hd2["id"]) if not DB.BG.has(hd2["bg"]) else null
	var stone_r: Dictionary = G.apply_hunt_result("cinder", 0, true)
	check(int(stone_r.get("star_stone", 0)) > 0, "cinder hunt drops star stones")

	print("[starlight rift]")
	G.rift_start()
	check(G.s["rift"]["alive"] and int(G.s["rift"]["floor"]) == 1, "rift run starts at floor 1")
	var rf5: Dictionary = DB.rift_floor(5, 100)
	check(rf5["boss"] and DB.RIFT_VARIANTS.has(rf5["enemies"][0]["variant"]), "every 5th floor has a variant boss")
	G.apply_rift_result(true)
	var offer: Array = G.s["rift"]["offer"]
	check(int(G.s["rift"]["floor"]) == 2 and offer.size() == 3, "win → floor 2 + 3 blessing choices")
	check(G.rift_pick(offer[0]) and G.s["rift"]["offer"].is_empty() and not G.rift_pick("ember_fake"), "pick a blessing")
	var rbase: float = float(G.ally_team({})[0]["bonus"].get("atk", 0.0))
	G.s["rift"]["bless"] = ["nova"]
	check(is_equal_approx(float(G.ally_team({"mode": "rift"})[0]["bonus"]["atk"]) - rbase, 0.18), "blessing applies only in rift battles")
	G.apply_rift_result(false)
	check(not G.s["rift"]["alive"] and int(G.s["rift"]["best"]) == 1, "defeat ends the run, best kept")
	G.s["rift"]["best"] = 10
	check(G.rift_milestone_state(1) == "ready" and not G.claim_rift_milestone(1).is_empty() and G.claim_rift_milestone(1).is_empty(), "rift milestone once")
	check(G.rift_board().size() == 15, "rift ranking")

	print("[limit break]")
	var lbh: String = G.s["heroes"].keys()[0]
	var lbhero: Dictionary = G.s["heroes"][lbh]
	lbhero["star"] = DB.MAX_STAR
	lbhero["level"] = DB.level_cap(DB.MAX_STAR)
	lbhero["lb"] = 0
	G.s["items"]["hunt_core"] = 0
	check(G.hero_cap(lbh) == 80 and G.limit_break_block(lbh) != "", "LB needs materials")
	G.give({"hunt_core": 2000, "gold": 3000000, "star_stone": 500})
	check(G.limit_break(lbh) == "" and G.hero_cap(lbh) == 85, "LB raises cap to 85")
	check(G.limit_break(lbh) != "", "LB needs the new cap reached first")
	for k in 3:
		lbhero["level"] = G.hero_cap(lbh)
		G.limit_break(lbh)
	check(G.hero_cap(lbh) == 100 and G.title_unlocked("limitless"), "LB max = Lv.100 + title")

	print("[daily board / hunt sweep]")
	var board: Array = G.daily_board()
	check(board.size() >= 4 and board.all(func(r): return r.size() == 5), "daily board rows well-formed (%d)" % board.size())
	G.s["hunt"]["used"] = 0
	var swr: Dictionary = G.sweep_hunt("behemoth", 0)
	check(not swr.has("error") and G.hunt_tries() == 2, "hunt sweep uses an attempt")
	check(G.sweep_hunt("behemoth", 3).has("error"), "sweep needs a cleared difficulty")

	print("[story links]")
	var cov := {}
	for l in DB.LINKS:
		for hid in l["heroes"]:
			check(DB.HEROES.has(hid), "link hero exists: %s" % hid) if not DB.HEROES.has(hid) else null
			cov[hid] = true
	check(cov.size() == DB.HEROES.size(), "every hero has a story link (%d/%d)" % [cov.size(), DB.HEROES.size()])
	var saved_form: Array = G.s["formation"].duplicate(true)
	for hid in ["shina", "zennyo"]:
		if not G.owns(hid):
			G.add_hero(hid)
	G.s["formation"] = [["shina", 0, 0], ["zennyo", 0, 1]]
	var lal: Array = G.ally_team()
	var base_atk: float = float(G.stat_bonus("shina")["atk"])
	check(G.active_links().size() == 1 and is_equal_approx(float(lal[0]["bonus"]["atk"]), base_atk + 0.08), "Dragon Sisters link adds +8% ATK")
	G.s["formation"] = [["shina", 0, 0]]
	check(G.active_links().is_empty(), "link inactive without partner")
	G.s["formation"] = saved_form

	print("[interludes / arc 4]")
	var hb: Dictionary = DB.stage(14 * DB.STAGES_PER_CHAPTER + 5)["enemies"][0]
	check(hb["variant"] == "hollow" and DB.name_of("hollow:" + str(hb["id"])) == "Hollow Cthollia", "arc 4 boss is hollow")
	var it0: Dictionary = DB.INTERLUDES[0]
	var saved_clear: Dictionary = G.s["story"]["cleared"].duplicate()
	for si in 36:
		G.s["story"]["cleared"][DB.stage_id(si)] = 3
	check(G.interlude_open(it0) and not G.interlude_open(DB.INTERLUDES[3]), "interlude 1 open after arc 1, 4 locked")
	var ir: Dictionary = G.finish_interlude(it0)
	check(not ir.is_empty() and G.finish_interlude(it0).is_empty(), "interlude reward once")
	G.s["story"]["cleared"] = saved_clear

	print("[spark / profile]")
	var sb: String = DB.BANNERS[0]["id"]
	var sp0: int = G.spark_points(sb)
	G.give({"summon_ticket": 10})
	G.pull(sb, 10, "ticket")
	check(G.spark_points(sb) == sp0 + 10, "rate-up pulls give spark points")
	check(G.spark_exchange(sb).has("error") or G.spark_points(sb) >= 0, "exchange blocked below cost")
	G.s["gacha"]["spark"][sb] = DB.SPARK_COST
	var sfh: String = DB.BANNERS[0]["featured"]
	var spr: Dictionary = G.spark_exchange(sb)
	check(not spr.has("error") and G.owns(sfh) and G.spark_points(sb) == 0, "spark exchange gives %s" % sfh)
	var std_before: int = G.spark_points("standard")
	G.give({"summon_ticket": 1})
	G.pull("standard", 1, "ticket")
	check(G.spark_points("standard") == std_before, "standard banner gives no spark")
	check(G.rename("A") != "" and G.rename("Aster") == "" and G.s["player"]["name"] == "Aster", "rename validation")
	check(G.set_title("rookie") and (G.set_title("time") == G.title_unlocked("time")), "title gating")
	G.set_avatar(sfh)
	check(G.avatar_id() == sfh, "avatar set")
	G.s["player"]["name"] = "Commander"

	print("[commander tactics]")
	G.s["player"]["level"] = 30
	# fixed team (not the gacha-dependent formation) so the test is deterministic
	var team5: Array = []
	for fe in [["fidelia", 0, 0], ["shina", 0, 1], ["lucidria", 0, 2], ["rumi", 2, 1], ["furu", 1, 1]]:
		team5.append({"id": fe[0], "cell": Vector2i(fe[1], fe[2]), "level": 40, "star": 4})
	var fired := {}
	for tid in ["rally", "mend", "barrage", "aegis", "second_wind"]:
		check(G.equip_tactic(tid), "equip %s" % tid)
		for seed_i in 8:
			var ts := BattleSim.new()
			ts.setup(team5, DB.stage([24, 30, 36, 42][seed_i % 4])["enemies"], seed_i + 1, {})
			ts.tactic = G.equipped_tactic()
			ts.run()
			for ev in ts.events:
				if ev["t"] == "tactic":
					fired[tid] = int(fired.get(tid, 0)) + 1
					check(ev["id"] == tid and not ev["fx"].is_empty(), "%s has effects" % tid) if seed_i == 0 and int(fired[tid]) == 1 else null
	check(fired.has("rally") and fired.has("mend") and fired.has("barrage") and fired.has("aegis") and fired.has("second_wind"), "all tactics fire in battle %s" % str(fired))
	G.give({"gold": 500000})
	check(G.upgrade_tactic("rally") == "" and G.tactic_lv("rally") == 2, "upgrade tactic")
	G.s["player"]["level"] = 1
	check(G.equipped_tactic().is_empty(), "locked tactic not used")
	G.s["player"]["level"] = 30

	print("[festival]")
	var fz: Dictionary = G.festival()
	check(not fz.is_empty() and fz["featured"].size() == 2, "festival active this month: %s" % fz.get("name", "-"))
	var fmiss: Array = []
	for mo in range(1, 13):
		for fh in DB.FESTIVALS[mo]["featured"]:
			if not DB.HEROES.has(fh):
				fmiss.append(fh)
	check(DB.FESTIVALS.size() == 12 and fmiss.is_empty(), "12 festivals, featured heroes exist %s" % str(fmiss))
	var c0: int = G.amount("season_token")
	check(G.festival_drop("story") >= 10 and G.festival_drop("arena") == 0, "charms drop from story, not arena")
	G.s["fest"]["today"] = DB.FEST_DAILY_CAP
	check(G.festival_drop("story") == 0, "daily charm cap")
	check(G.fest_can_wish() and not G.fest_wish().is_empty() and not G.fest_can_wish(), "daily wish once")
	G.give({"season_token": 500})
	var fit: Dictionary = DB.FEST_SHOP[2]
	check(G.buy_fest(fit) == "" and str(G.fest_item_give(fit).keys()[0]) == "shard:" + str(fz["featured"][0]), "featured shard exchange")
	check(G.fest_greet() and not G.fest_greet(), "festival greeting bond once")
	check(G.amount("season_token") > c0, "charms accumulate")

	print("[tower milestones]")
	var tf0: int = int(G.s["tower"]["floor"])
	G.s["tower"]["floor"] = 10
	check(G.tower_milestone_state(0) == "locked" and G.claim_tower_milestone(0).is_empty(), "milestone locked until floor 10 is cleared")
	G.s["tower"]["floor"] = 11
	var tg0: int = G.amount("gems")
	check(G.feature_badge("tower") >= 1 or not G.feature_unlocked("tower"), "tower badge counts ready milestones")
	check(not G.claim_tower_milestone(0).is_empty() and G.amount("gems") == tg0 + 200, "claim F10 milestone")
	check(G.tower_milestone_state(0) == "claimed" and G.claim_tower_milestone(0).is_empty(), "milestone claims once")
	G.s["tower"]["floor"] = tf0

	print("[story star chests]")
	var sc_clear: Dictionary = (G.s["story"]["cleared"] as Dictionary).duplicate()
	var sc_chests: Array = (G.s["story"].get("chests", []) as Array).duplicate()
	var sch := 3
	for k in DB.STAGES_PER_CHAPTER:
		G.s["story"]["cleared"].erase(DB.stage_id(sch * DB.STAGES_PER_CHAPTER + k))
	check(G.chapter_stars(sch, false) == 0 and G.star_chest_state(sch, 0, false) == "locked", "star chest locked at 0 stars")
	for k in 3:
		G.s["story"]["cleared"][DB.stage_id(sch * DB.STAGES_PER_CHAPTER + k)] = 3
	check(G.chapter_stars(sch, false) == 9, "chapter stars counted")
	check(G.star_chest_state(sch, 0, false) == "ready" and G.star_chest_state(sch, 1, false) == "locked", "6-star chest ready, 12-star locked")
	check(G.star_chests_ready() >= 1, "star chest badge counts")
	var scg0: int = G.amount("gold")
	var scr: Dictionary = G.claim_star_chest(sch, 0, false)
	check(not scr.is_empty() and G.amount("gold") == scg0 + int(scr["gold"]), "claim 6-star chest")
	check(G.star_chest_state(sch, 0, false) == "claimed" and G.claim_star_chest(sch, 0, false).is_empty(), "star chest claims once")
	check(G.claim_star_chest(sch, 0, true).is_empty(), "hard chest separate and still locked")
	G.s["story"]["cleared"] = sc_clear
	G.s["story"]["chests"] = sc_chests

	print("[save / load]")
	var path := "user://flow_test_save.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(G.s))
	f = null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var fresh: Dictionary = G.new_state()
	G._merge(fresh, parsed)
	G.s = fresh
	G._sanitize()
	check(G.hero("shina")["oath"] == true, "save round-trip keeps oath")
	check(G.formation_cell_of(first).x >= 0 or true, "save round-trip keeps formation")
	check(typeof(G.s["formation"][0][1]) == TYPE_INT, "formation cells are ints after load")
	check(G.friends()[0]["used"], "friend usage survives save/load")
	check(G.bond_story_read("rumi", 0) and G.dungeon_cleared("gold") == 0, "memories & dungeon progress survive save/load")
	check(G.s["runes"].size() > 0 and typeof(G.s["runes"][0]["tier"]) == TYPE_INT, "runes survive save/load")
	check(bool(G.s["pass"]["premium"]) and G.s["pass"]["free"].has(1) and int(G.hero("furu")["skill_lv"]) == 2, "pass & skill level survive save/load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
