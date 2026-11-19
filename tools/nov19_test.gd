extends SceneTree
## Checks the 19 Nov 2026 heroes and costume skins: art, sprites, rigs, voice, and battles where each
## new hero fights and uses her skill. Godot --headless --path . -s res://tools/nov19_test.gd
const NEW := ["aura", "fuji", "kyra", "sharas", "toka", "tora", "tsundae", "vila", "yumi"]
const SKINS := ["angela", "mei", "eropatra", "rubby"]
var fails := 0

func check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1

func _process(_d: float) -> bool:
	var G: Node = load("res://game/core/game.gd").new()
	G.name = "Game"
	G.set("persist", false)
	root.add_child(G)
	var DB = load("res://game/core/db.gd")
	for id in NEW:
		var arts: Array = DB.art_list(id)
		check(arts.size() >= 3, "%s has %d outfits" % [id, arts.size()])
		for i in arts.size():
			var t: Texture2D = DB.art(id, i)
			check(t != null and t.get_width() > 100, "%s outfit %d loads" % [id, i])
			check(not DB.char_rig(t).is_empty(), "%s outfit %d pivot rig" % [id, i])
			for q in DB.alt_arts(id, i):
				check(not DB.char_rig(DB.tex(str(q))).is_empty(), "%s alt %s rig" % [id, str(q).get_file()])
		check(DB.sprite(id, 1) != null and DB.sprite(id, 5) != null, "%s sprites 1★/5★" % id)
		check(DB.face(id) != null, "%s face crop" % id)
		check(str(DB.voice(id, "greet")["en"]) != "", "%s voice" % id)
		check(DB.has_method("skill_of") and not DB.skill_of(id).is_empty(), "%s skill" % id)
	for id in SKINS:
		var si: int = DB.special_index(id)
		check(si >= 0, "%s special skin index %d" % [id, si])
		var t: Texture2D = DB.art(id, si)
		check(t != null and t.resource_path.contains("_special"), "%s skin art" % id)
		check(not DB.char_rig(t).is_empty(), "%s skin rig" % id)
		check(DB.alt_arts(id, si).size() >= 3, "%s skin poses %d" % [id, DB.alt_arts(id, si).size()])
		for q in DB.alt_arts(id, si):
			check(not DB.char_rig(DB.tex(str(q))).is_empty(), "%s skin pose %s rig" % [id, str(q).get_file()])
		var s1: Texture2D = DB.sprite(id, 1, si)
		var s5: Texture2D = DB.sprite(id, 5, si)
		check(s1 != null and s1.resource_path.contains("_special"), "%s skin sprite" % id)
		if id != "mei":
			check(s5 != null and s5.resource_path != s1.resource_path, "%s evolved skin sprite at 5★" % id)
		check(DB.SPECIAL_SKINS.has(id), "%s skin name %s" % [id, DB.SPECIAL_SKINS.get(id, "")])
	# battles: new heroes in two teams of 5 against a story stage, every skill must fire
	var used := {}
	for team in [NEW.slice(0, 5), NEW.slice(4, 9)]:
		for id in team:
			if not G.owns(id):
				G.add_hero(id)
			G.hero(id)["level"] = 60
		for e in G.formation().duplicate():
			G.remove_hero(e[0])
		var cells := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 0), Vector2i(1, 2)]
		for i in team.size():
			check(G.place_hero(team[i], cells[i]) == "", "place %s" % team[i])
		for run in 4:
			var sim = load("res://game/core/battle_sim.gd").new()
			sim.setup(G.ally_team(), G.enemies_for({"mode": "story", "stage": 20 + run * 6}), 0, G.battle_mod({"mode": "story", "stage": 20 + run * 6}))
			var res: Dictionary = sim.run()
			for ev in sim.events:
				if str(ev["t"]) == "act" and int(sim.units[ev["uid"]]["side"]) == 0:
					used[str(sim.units[ev["uid"]]["id"])] = true
			check(res.has("won") and sim.events[-1]["t"] == "end", "battle %d (%s) won=%s" % [run, ",".join(team), str(res.get("won"))])
	for id in NEW:
		check(used.has(id), "%s used her skill in battle" % id)
	print("RESULT: %s (%d failures)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(0 if fails == 0 else 1)
	return true
