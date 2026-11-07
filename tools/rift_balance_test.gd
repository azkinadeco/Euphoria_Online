extends SceneTree
## Dev tool: average floor reached in the Starlight Rift (random blessing picks) per team level.
func _init() -> void:
	var team := [["fidelia",0,0],["shina",0,1],["lucidria",0,2],["rumi",2,1],["furu",1,1]]
	var keys: Array = DB.BLESSINGS.keys()
	for lvl in [20, 40, 60, 80, 100]:
		var total := 0
		var best := 0
		for run in 6:
			var bonus := {"hp": 0.3 * lvl / 100.0, "atk": 0.3 * lvl / 100.0, "def": 0.3 * lvl / 100.0}
			var fl := 1
			while fl < 80:
				var allies := []
				for e in team:
					allies.append({"id": e[0], "cell": Vector2i(e[1], e[2]), "level": lvl, "star": mini(DB.RARITY_START_STAR[DB.rarity_of(e[0])] + lvl / 13, 6), "bonus": bonus.duplicate()})
				var sim := BattleSim.new()
				sim.setup(allies, DB.rift_floor(fl, 7)["enemies"], run * 100 + fl, {})
				if not sim.run()["won"]:
					break
				var b: Dictionary = DB.BLESSINGS[keys[(run * 7 + fl * 3) % keys.size()]]
				if not b.has("elem"):
					for k in b["bonus"].keys():
						bonus[k] = float(bonus.get(k, 0.0)) + float(b["bonus"][k])
				fl += 1
			total += fl - 1
			best = maxi(best, fl - 1)
		print("Lv%d: avg floor %.1f  best %d" % [lvl, total / 6.0, best])
	quit()
