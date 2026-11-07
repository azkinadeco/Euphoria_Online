extends SceneTree
const BONUS := 0.4   # typical endgame gear + awaken + collection bonus
## Dev tool: win-rate of a team across story stages at various levels.
func _init() -> void:
	var team := [["fidelia",0,0],["shina",0,1],["lucidria",0,2],["rumi",2,1],["furu",1,1]]
	for lvl in [70, 80, 90]:
		var line := "Lv%2d: " % lvl
		var idx := 35
		while idx < DB.stage_count():
			var wins := 0
			var rounds := 0
			for t in 20:
				var allies := []
				for e in team:
					var st: int = DB.RARITY_START_STAR[DB.rarity_of(e[0])] + (lvl / 13)
					allies.append({"id": e[0], "cell": Vector2i(e[1], e[2]), "level": lvl, "star": mini(st, 6), "bonus": {"hp": BONUS, "atk": BONUS, "def": BONUS}})
				var sim := BattleSim.new()
				sim.setup(allies, DB.stage(idx)["enemies"], t + 1, DB.stage(idx)["mod"])
				var r := sim.run()
				if r["won"]:
					wins += 1
				rounds += r["rounds"]
			line += "%s:%d%% " % [DB.stage_id(idx), wins * 5]
			idx += 6
		print(line)
	quit()
