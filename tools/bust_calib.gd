extends SceneTree
## Writes the head measures used by DB.bust_tex for every hero outfit art to /tmp/bust_cal.txt:
## id|art index|w|h|eye span|eye cx|eye cy|rig head x,y,r|face_focus x,y,z   (all UV except w/h)
## Usage: Godot --headless --path . -s res://tools/bust_calib.gd

var G: Node

func _process(_d: float) -> bool:
	if G != null:
		return false
	G = load("res://game/core/game.gd").new()
	G.persist = false
	root.add_child(G)
	G.name = "Game"
	G.s = G.new_state()
	var f := FileAccess.open("/tmp/bust_cal.txt", FileAccess.WRITE)
	for id in DB.hero_ids():
		var arts: Array = DB.art_list(id)
		for i in arts.size():
			var t: Texture2D = DB.tex(str(arts[i]))
			if t == null:
				continue
			var r: Dictionary = DB.char_rig(t)
			var eyes: Array = r.get("eyes", [])
			var hv: Variant = r.get("head", [])
			var head: Array = [hv.x, hv.y, hv.z] if hv is Vector3 else (hv as Array)
			var ff := DB.face_focus(t)
			var span := -1.0
			var ex := -1.0
			var ey := -1.0
			if eyes.size() >= 2:
				var xs: Array = []
				var ys: Array = []
				for e in eyes:
					var ea: Array = Array(e) if not (e is Array) else e
					if ea.size() < 4:
						continue
					xs.append(float(ea[0]))
					xs.append(float(ea[2]))
					ys.append(float(ea[1]))
					ys.append(float(ea[3]))
				if xs.is_empty():
					continue
				span = float(xs.max()) - float(xs.min())
				ex = (float(xs.max()) + float(xs.min())) * 0.5
				ey = (float(ys.max()) + float(ys.min())) * 0.5
			var hs: Array = head.map(func(v): return "%.4f" % float(v))
			f.store_line("%s|%d|%s|%d|%d|%.4f|%.4f|%.4f|%s|%.4f|%.4f|%.4f" % [id, i, str(arts[i]), t.get_width(), t.get_height(), span, ex, ey, ",".join(hs), ff.x, ff.y, ff.z])
		f.flush()
	f = null
	print("bust_calib: done")
	quit(0)
	return true
