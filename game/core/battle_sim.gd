class_name BattleSim
extends RefCounted
## Brown Dust style auto-battle.
## Both sides stand on a 3x3 grid (col 0 = front line). Units act in their
## deployment order, alternating sides: Ally#1, Enemy#1, Ally#2, Enemy#2 ...
## Every action is a skill with a fixed aim + area shape, so the battle is
## decided by WHERE and in WHAT ORDER the player deploys heroes.
## The whole fight is simulated up-front into a list of events which the
## battle screen then plays back with animation.

const DMG_SCALE := 4.0
const HEAL_SCALE := 3.0
const BASE_CRIT := 0.1
const CRIT_MULT := 1.6

var rng := RandomNumberGenerator.new()
var units: Array = []   # Array[Dictionary]
var events: Array = []

## team entries: {id, cell:Vector2i, level, star, bond?, oath?, boss?}
var modifier: Dictionary = {}
## Commander tactic for the ally side: {"id": String, "lv": int} (empty = none).
var tactic: Dictionary = {}
var _tactic_used := false
## Tamed Companion assist for the ally side: {"id": enemy id, "bond": int} (empty = none).
var companion: Dictionary = {}
var synergies := [{}, {}]

func setup(allies: Array, enemies: Array, seed_value: int = 0, stage_mod: Dictionary = {}) -> void:
	rng.seed = seed_value if seed_value != 0 else randi()
	units.clear()
	events.clear()
	modifier = stage_mod
	var i := 0
	for a in allies:
		units.append(_make_unit(a, 0, i))
		i += 1
	i = 0
	for e in enemies:
		units.append(_make_unit(e, 1, i))
		i += 1
	for side in 2:
		var ids: Array = side_units(side, false).map(func(u): return u["id"])
		var syn := DB.synergy(ids)
		synergies[side] = syn
		if float(syn["bonus"]) > 0.0:
			for u in side_units(side, false):
				if DB.ELEMENT_GROUP.get(u["elem"], "") == syn["element"]:
					u["atk"] = int(u["atk"] * (1.0 + float(syn["bonus"])))
					u["hp"] = int(u["hp"] * (1.0 + float(syn["bonus"])))
					u["max_hp"] = u["hp"]
	# Bastion (3 pieces): start the battle shielded
	for u in units:
		if (u["sets"] as Array).has("aegis"):
			u["shield"] = maxi(int(u["shield"]), int(u["max_hp"] * 0.15))
			events.append({"t": "status", "uid": u["uid"], "kind": "SHIELD"})
	if not modifier.is_empty():
		for u in units:
			if DB.ELEMENT_GROUP.get(u["elem"], "") == str(modifier.get("elem", "")):
				u["atk"] = int(u["atk"] * (1.0 + float(modifier.get("atk", 0.0))))
				u["def"] = int(u["def"] * (1.0 + float(modifier.get("def", 0.0))))

func _make_unit(d: Dictionary, side: int, order: int) -> Dictionary:
	var id: String = d["id"]
	var star: int = int(d.get("star", DB.RARITY_START_STAR.get(DB.rarity_of(id), 1)))
	var st := DB.stats_for(id, int(d.get("level", 1)), star, int(d.get("bond", 1)), bool(d.get("oath", false)))
	var b: Dictionary = d.get("bonus", {})
	if not b.is_empty():
		st = {"hp": int(st["hp"] * (1.0 + float(b.get("hp", 0.0)))), "atk": int(st["atk"] * (1.0 + float(b.get("atk", 0.0)))), "def": int(st["def"] * (1.0 + float(b.get("def", 0.0))))}
	var boss: bool = bool(d.get("boss", false))
	if bool(d.get("raid", false)):
		st["hp"] = 999999999
	if boss:
		st["hp"] = int(st["hp"] * float(d.get("hp_mult", 3.5)))
		st["atk"] = int(st["atk"] * float(d.get("atk_mult", 1.3)))
		st["def"] = int(st["def"] * 1.2)
	return {
		"uid": units.size(), "side": side, "id": id, "cell": d["cell"], "order": order,
		"hp": st["hp"], "max_hp": st["hp"], "atk": st["atk"], "def": st["def"],
		"elem": DB.element_of(id), "skill": DB.skill_at(DB.skill_of(id), int(d.get("skill_lv", 1)) + (1 if int(d.get("awaken", 0)) >= 3 else 0)), "skill_lv": int(d.get("skill_lv", 1)), "boss": boss, "star": star,
		"level": int(d.get("level", 1)), "alive": true, "stun": 0, "shield": 0,
		"burns": [], "atk_up": 0.0, "atk_up_r": 0, "def_down": 0.0, "def_down_r": 0,
		"taunt": 0, "silence": 0, "heal_block": 0, "revive_used": false, "elite": bool(d.get("elite", false)), "mirror": bool(d.get("mirror", false)), "variant": str(d.get("variant", "")),
		"passive": DB.passive_of(id), "rage": 0.0, "enraged": false, "crit_bonus": float(b.get("crit", 0.0)), "awaken": int(d.get("awaken", 0)),
		"sets": (b.get("sets", []) as Array).duplicate(),
	}

func side_units(side: int, alive_only: bool = true) -> Array:
	var out: Array = []
	for u in units:
		if u["side"] == side and (u["alive"] or not alive_only):
			out.append(u)
	return out

func unit_at(side: int, cell: Vector2i) -> Dictionary:
	for u in units:
		if u["side"] == side and u["alive"] and u["cell"] == cell:
			return u
	return {}

## Run the whole battle. Returns summary dictionary.
func run() -> Dictionary:
	var rounds_played := 0
	var result := ""
	for r in range(1, DB.MAX_ROUNDS + 1):
		rounds_played = r
		events.append({"t": "round", "n": r})
		_tactic_round(r)
		_companion_round(r)
		result = _check_end()
		if result != "":
			break
		var a_list := side_units(0, false)
		var e_list := side_units(1, false)
		var n := maxi(a_list.size(), e_list.size())
		for i in n:
			for lst in [a_list, e_list]:
				if i < lst.size():
					var u: Dictionary = lst[i]
					if u["alive"]:
						_act(u)
						_tactic_react()
						result = _check_end()
						if result != "":
							break
			if result != "":
				break
		if result != "":
			break
		_end_of_round()
		result = _check_end()
		if result != "":
			break
	if result == "":
		result = "timeout"
	var won := result == "win"
	var deaths := 0
	for u in side_units(0, false):
		if not u["alive"]:
			deaths += 1
	var stars := 0
	if won:
		stars = 1 + (1 if deaths == 0 else 0) + (1 if rounds_played <= 3 else 0)
	events.append({"t": "end", "won": won, "reason": result, "stars": stars})
	return {"won": won, "stars": stars, "rounds": rounds_played, "deaths": deaths, "reason": result}

func _check_end() -> String:
	if side_units(1).is_empty():
		return "win"
	if side_units(0).is_empty():
		return "lose"
	return ""

func _end_of_round() -> void:
	# Tidecaller (3 pieces): recover 6% HP every round
	for u in units:
		if u["alive"] and (u["sets"] as Array).has("tidal") and u["hp"] < u["max_hp"]:
			_heal(u, int(u["max_hp"] * 0.06))
	for u in units:
		if not u["alive"]:
			continue
		var keep: Array = []
		for b in u["burns"]:
			if not u["alive"]:
				break
			var dmg: int = int(b["dmg"])
			_apply_damage(u, dmg)
			events.append({"t": "dot", "uid": u["uid"], "dmg": dmg, "hp": u["hp"], "dead": not u["alive"]})
			if int(b["rounds"]) > 1:
				keep.append({"dmg": b["dmg"], "rounds": int(b["rounds"]) - 1})
		if u["burns"].size() > 0 and keep.is_empty() and u["alive"]:
			events.append({"t": "status_end", "uid": u["uid"], "kind": "BURN"})
		u["burns"] = keep
		if not u["alive"]:
			continue
		if u["atk_up_r"] > 0:
			u["atk_up_r"] -= 1
			if u["atk_up_r"] == 0:
				u["atk_up"] = 0.0
				events.append({"t": "status_end", "uid": u["uid"], "kind": "ATK ▲"})
		if u["taunt"] > 0:
			u["taunt"] -= 1
			if u["taunt"] == 0:
				events.append({"t": "status_end", "uid": u["uid"], "kind": "TAUNT"})
		if u["heal_block"] > 0:
			u["heal_block"] -= 1
			if u["heal_block"] == 0:
				events.append({"t": "status_end", "uid": u["uid"], "kind": "HEAL ▼"})
		if u["def_down_r"] > 0:
			u["def_down_r"] -= 1
			if u["def_down_r"] == 0:
				u["def_down"] = 0.0
				events.append({"t": "status_end", "uid": u["uid"], "kind": "DEF ▼"})
		if u["passive"] == "RAGE" and u["rage"] < 0.4:
			u["rage"] = minf(0.4, u["rage"] + 0.08)
			events.append({"t": "passive", "uid": u["uid"], "kind": "RAGE", "text": "RAGE +%d%%" % int(u["rage"] * 100)})
		if u["passive"] == "GRACE":
			var allies := side_units(u["side"])
			allies.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
			if not allies.is_empty() and allies[0]["hp"] < allies[0]["max_hp"]:
				var t: Dictionary = allies[0]
				events.append({"t": "passive", "uid": u["uid"], "kind": "GRACE", "text": "GRACE"})
				_heal(t, int(u["max_hp"] * 0.06))

## Find the aimed cell on the opposing side.
func _aim(u: Dictionary, aim: String) -> Dictionary:
	var foes := side_units(1 - u["side"])
	if foes.is_empty():
		return {}
	# Taunt: single-target style aims are pulled to the taunting unit
	if aim in ["front", "back"]:
		for f in foes:
			if int(f["taunt"]) > 0:
				return f
	if aim == "lowest":
		foes.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
		return foes[0]
	var row: int = u["cell"].y
	var rows := [row, row - 1, row + 1, row - 2, row + 2]
	for r in rows:
		var in_row: Array = []
		for f in foes:
			if f["cell"].y == r:
				in_row.append(f)
		if in_row.is_empty():
			continue
		in_row.sort_custom(func(a, b): return a["cell"].x < b["cell"].x)
		return in_row[-1] if aim == "back" else in_row[0]
	return foes[0]

func _act(u: Dictionary) -> void:
	if u["stun"] > 0:
		u["stun"] = 0
		events.append({"t": "stunned", "uid": u["uid"]})
		return
	var sk: Dictionary = u["skill"]
	if u["silence"] > 0:
		# silenced: a weak basic attack instead of the skill
		u["silence"] = 0
		events.append({"t": "status_end", "uid": u["uid"], "kind": "SILENCE"})
		sk = {"name": "Basic Attack (Silenced)", "aim": "front", "shape": "single", "mult": 0.6}
	if sk.has("taunt"):
		u["taunt"] = int(sk["taunt"])
	var aim: String = sk.get("aim", "front")
	if aim == "ally_all":
		var allies := side_units(u["side"])
		events.append({"t": "act", "uid": u["uid"], "skill": sk["name"], "cells": allies.map(func(a): return a["cell"]), "target_side": u["side"]})
		for a in allies:
			_heal(a, int(u["atk"] * float(sk.get("heal", 0.8)) * HEAL_SCALE * rng.randf_range(0.95, 1.05)))
			if sk.has("cleanse"):
				_cleanse(a)
		if sk.has("revive") and not u["revive_used"]:
			for a in side_units(u["side"], false):
				if not a["alive"]:
					u["revive_used"] = true
					a["alive"] = true
					a["hp"] = int(a["max_hp"] * float(sk["revive"]))
					a["burns"] = []
					a["stun"] = 0
					events.append({"t": "revive", "uid": a["uid"], "hp": a["hp"]})
					break
		return
	var target := _aim(u, aim)
	if target.is_empty():
		return
	var cells := DB.shape_cells(sk.get("shape", "single"), target["cell"])
	var foe_side: int = 1 - u["side"]
	events.append({"t": "act", "uid": u["uid"], "skill": sk["name"], "cells": cells, "target_side": foe_side, "target": target["uid"]})
	var dealt_total := 0
	for c in cells:
		var v := unit_at(foe_side, c)
		if v.is_empty():
			continue
		var crit_chance := BASE_CRIT + float(sk.get("crit_bonus", 0.0)) + (0.2 if u["passive"] == "PRECISION" else 0.0) + float(u["crit_bonus"])
		var crit := rng.randf() < crit_chance
		var em := DB.element_mult(u["elem"], v["elem"])
		var atk := float(u["atk"]) * (1.0 + float(u["atk_up"]) + float(u["rage"]))
		var def := float(v["def"]) * (1.0 - float(v["def_down"]))
		if u["passive"] == "ARCANE":
			def *= 0.75
		var dmg := atk * float(sk.get("mult", 1.0)) * (1.0 - def / (def + atk * 1.5)) * DMG_SCALE
		dmg *= em * rng.randf_range(0.92, 1.08)
		if crit:
			dmg *= 1.9 if u["passive"] == "PRECISION" else CRIT_MULT
			if (u["sets"] as Array).has("swift"):
				dmg *= 1.3
		if u["passive"] == "HUNTER" and v["cell"].x > 0:
			dmg *= 1.2
		if v["passive"] == "GUARD":
			dmg *= 0.85
		if sk.has("execute") and float(v["hp"]) / v["max_hp"] < 0.35:
			dmg *= 1.0 + float(sk["execute"])
		var d := maxi(1, int(dmg))
		var had_shield: bool = v["shield"] > 0
		var absorbed := _apply_damage(v, d)
		dealt_total += d
		events.append({"t": "hit", "src": u["uid"], "uid": v["uid"], "dmg": d, "crit": crit, "em": em, "hp": v["hp"], "dead": not v["alive"], "absorbed": absorbed})
		if had_shield and v["shield"] <= 0 and v["alive"]:
			events.append({"t": "status_end", "uid": v["uid"], "kind": "SHIELD"})
		if v["boss"] and v["alive"] and not v["enraged"] and float(v["hp"]) / v["max_hp"] < 0.5:
			v["enraged"] = true
			v["atk"] = int(v["atk"] * 1.3)
			v["def_down"] = 0.0
			events.append({"t": "enrage", "uid": v["uid"]})
		if v["alive"]:
			if sk.has("stun") and rng.randf() < float(sk["stun"]):
				v["stun"] = 1
				events.append({"t": "status", "uid": v["uid"], "kind": "STUN"})
			if sk.has("burn"):
				v["burns"].append({"dmg": int(u["atk"] * float(sk["burn"]) * 2.0), "rounds": 2})
				events.append({"t": "status", "uid": v["uid"], "kind": "BURN"})
			elif (u["sets"] as Array).has("inferno"):
				v["burns"].append({"dmg": int(u["atk"] * 0.3), "rounds": 2})
				events.append({"t": "status", "uid": v["uid"], "kind": "BURN"})
			if sk.has("def_down"):
				v["def_down"] = float(sk["def_down"])
				v["def_down_r"] = 2
				events.append({"t": "status", "uid": v["uid"], "kind": "DEF ▼"})
			if sk.has("silence") and rng.randf() < float(sk["silence"]):
				v["silence"] = 1
				events.append({"t": "status", "uid": v["uid"], "kind": "SILENCE"})
			if sk.has("heal_block"):
				v["heal_block"] = 2
				events.append({"t": "status", "uid": v["uid"], "kind": "HEAL ▼"})
	if sk.has("drain") and dealt_total > 0 and u["alive"]:
		_heal(u, int(dealt_total * float(sk["drain"])))
	if (u["sets"] as Array).has("vampire") and dealt_total > 0 and u["alive"] and u["hp"] < u["max_hp"]:
		_heal(u, int(dealt_total * 0.12))
	if sk.has("taunt") and u["alive"]:
		events.append({"t": "status", "uid": u["uid"], "kind": "TAUNT"})
	if sk.has("shield_self") and u["alive"]:
		u["shield"] = int(u["max_hp"] * float(sk["shield_self"]))
		events.append({"t": "status", "uid": u["uid"], "kind": "SHIELD"})
	if sk.has("team_atk"):
		for a in side_units(u["side"]):
			a["atk_up"] = float(sk["team_atk"])
			a["atk_up_r"] = 2
			events.append({"t": "status", "uid": a["uid"], "kind": "ATK ▲"})

# ---------------------------------------------------------------- companion assist
## Round 2: the Companion strikes every enemy for (45% + 5%/Bond) of the team's average ATK
## and applies her own skill's effect (burn / DEF down / stun / silence).
func _companion_round(r: int) -> void:
	if companion.is_empty() or r != 2:
		return
	var cid := str(companion["id"])
	var bond := int(companion.get("bond", 1))
	var sk: Dictionary = DB.ENEMIES.get(cid, {}).get("skill", {})
	var allies := side_units(0)
	if allies.is_empty():
		return
	var avg := 0.0
	for a in allies:
		avg += float(a["atk"])
	avg /= float(allies.size())
	var mult := 0.45 + 0.05 * bond
	var fx: Array = []
	for e in side_units(1):
		var d := int(avg * mult * rng.randf_range(0.95, 1.05))
		_apply_damage(e, d)
		var f := {"uid": e["uid"], "kind": "dmg", "amt": d, "hp": e["hp"], "dead": not e["alive"]}
		if e["alive"]:
			if sk.has("burn"):
				e["burns"].append({"dmg": int(avg * float(sk["burn"]) * 1.5), "rounds": 2})
				f["status"] = "BURN"
			elif sk.has("def_down"):
				e["def_down"] = maxf(float(e["def_down"]), float(sk["def_down"]))
				e["def_down_r"] = 2
				f["status"] = "DEF ▼"
			elif sk.has("stun") and rng.randf() < float(sk["stun"]) * 0.6:
				e["stun"] = 1
				f["status"] = "STUN"
			elif sk.has("silence") and rng.randf() < float(sk["silence"]):
				e["silence"] = 1
				f["status"] = "SILENCE"
		fx.append(f)
	events.append({"t": "companion", "id": cid, "name": str(sk.get("name", "Assist")), "fx": fx})

# ---------------------------------------------------------------- commander tactics
func _tactic_round(r: int) -> void:
	if tactic.is_empty() or _tactic_used:
		return
	var id := str(tactic["id"])
	if (id == "barrage" and r == 1) or (id == "rally" and r == 2) or (id == "mend" and r == 3):
		_fire_tactic(id)

func _tactic_react() -> void:
	if tactic.is_empty() or _tactic_used:
		return
	var id := str(tactic["id"])
	if id == "aegis":
		for a in side_units(0):
			if float(a["hp"]) < float(a["max_hp"]) * 0.4:
				_fire_tactic(id)
				return
	elif id == "second_wind":
		for a in side_units(0, false):
			if not a["alive"]:
				_fire_tactic(id)
				return

func _fire_tactic(id: String) -> void:
	_tactic_used = true
	var v := DB.tactic_value(id, int(tactic.get("lv", 1)))
	var fx: Array = []
	match id:
		"rally":
			for a in side_units(0):
				a["atk_up"] = maxf(float(a["atk_up"]), v)
				a["atk_up_r"] = 2
				fx.append({"uid": a["uid"], "kind": "atk"})
		"mend":
			for a in side_units(0):
				var before: int = a["hp"]
				if int(a["heal_block"]) <= 0:
					a["hp"] = mini(a["max_hp"], a["hp"] + int(a["max_hp"] * v))
				a["burns"] = []
				a["stun"] = 0
				a["def_down"] = 0.0
				a["def_down_r"] = 0
				a["silence"] = 0
				a["heal_block"] = 0
				fx.append({"uid": a["uid"], "kind": "heal", "amt": a["hp"] - before, "hp": a["hp"]})
		"barrage":
			var allies := side_units(0)
			var avg := 0.0
			for a in allies:
				avg += float(a["atk"])
			avg /= maxf(1.0, float(allies.size()))
			for e in side_units(1):
				var d := int(avg * v * rng.randf_range(0.95, 1.05))
				_apply_damage(e, d)
				fx.append({"uid": e["uid"], "kind": "dmg", "amt": d, "hp": e["hp"], "dead": not e["alive"]})
		"aegis":
			for a in side_units(0):
				a["shield"] = maxi(int(a["shield"]), int(a["max_hp"] * v))
				fx.append({"uid": a["uid"], "kind": "shield"})
		"second_wind":
			for a in side_units(0, false):
				if not a["alive"]:
					a["alive"] = true
					a["hp"] = int(a["max_hp"] * v)
					a["burns"] = []
					a["stun"] = 0
					fx.append({"uid": a["uid"], "kind": "revive", "hp": a["hp"]})
					break
	events.append({"t": "tactic", "id": id, "name": DB.tactic_def(id)["name"], "fx": fx})

func _heal(t: Dictionary, amt: int) -> void:
	if not t["alive"]:
		return
	if int(t["heal_block"]) > 0:
		events.append({"t": "heal", "uid": t["uid"], "amt": 0, "hp": t["hp"], "blocked": true})
		return
	t["hp"] = mini(t["max_hp"], t["hp"] + amt)
	events.append({"t": "heal", "uid": t["uid"], "amt": amt, "hp": t["hp"]})

func _cleanse(t: Dictionary) -> void:
	var had: bool = t["burns"].size() > 0 or int(t["stun"]) > 0 or float(t["def_down"]) > 0.0 or int(t["silence"]) > 0 or int(t["heal_block"]) > 0
	t["burns"] = []
	t["stun"] = 0
	t["def_down"] = 0.0
	t["def_down_r"] = 0
	t["silence"] = 0
	t["heal_block"] = 0
	if had:
		events.append({"t": "cleanse", "uid": t["uid"]})

func _apply_damage(v: Dictionary, d: int) -> int:
	var absorbed := 0
	if v["shield"] > 0:
		absorbed = mini(v["shield"], d)
		v["shield"] -= absorbed
	v["hp"] = maxi(0, v["hp"] - (d - absorbed))
	if v["hp"] <= 0:
		v["alive"] = false
	return absorbed
