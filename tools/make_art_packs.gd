extends SceneTree
## Writes the deferred art packs planned by tools/make_art_packs.py (builds/art_packs_plan.json).
## Usage: Godot --headless --path . -s res://tools/make_art_packs.gd

func _init() -> void:
	var plan: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://builds/art_packs_plan.json"))
	if not (plan is Dictionary):
		push_error("make_art_packs: run tools/make_art_packs.py first")
		quit(1)
		return
	var out_dir := ProjectSettings.globalize_path("res://" + str(plan["out_dir"]))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var n := 0
	for p in plan["packs"]:
		var pk := PCKPacker.new()
		var path := out_dir.path_join(str(p["file"]))
		if pk.pck_start(path) != OK:
			push_error("make_art_packs: cannot write " + path)
			quit(1)
			return
		for pair in p["pairs"]:
			if pk.add_file(str(pair[0]), str(pair[1])) != OK:
				push_error("make_art_packs: cannot add " + str(pair[1]))
				quit(1)
				return
		pk.flush()
		n += 1
	print("make_art_packs: wrote %d packs to %s" % [n, out_dir])
	quit(0)
