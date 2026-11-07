extends SceneTree
## Dev tool: Boss Hunt win-rates per difficulty at several team levels.
const BONUS := 0.4
func _init() -> void:
	var team := [["fidelia",0,0],["shina",0,1],["lucidria",0,2],["rumi",2,1],["furu",1,1]]
	for lvl in [30, 50, 70, 80]:
		var line := "Lv%d:" % lvl
		for h in DB.HUNTS:
			for diff in 4:
				var wins := 0
				for t in 16:
					var allies := []
					for e in team:
						allies.append({"id": e[0], "cell": Vector2i(e[1], e[2]), "level": lvl, "star": mini(DB.RARITY_START_STAR[DB.rarity_of(e[0])] + lvl / 13, 6), "bonus": {"hp": BONUS * lvl / 80.0, "atk": BONUS * lvl / 80.0, "def": BONUS * lvl / 80.0}})
					var st := DB.hunt_stage(h["id"], diff)
					var sim := BattleSim.new()
					sim.setup(allies, st["enemies"], t + 1, st["mod"])
					if sim.run()["won"]:
						wins += 1
				line += " %s%d:%d%%" % [str(h["id"]).substr(0, 3), diff, wins * 100 / 16]
		print(line)
	quit()
