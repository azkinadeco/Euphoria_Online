extends SceneTree
## Dev tool: renders an enemy pivot rig (DB.ENEMY_RIGS) at several moments side by side,
## plus a debug overlay of its pivots / bones. Godot --path . -s res://tools/rig_preview.gd -- <out.png> <enemy id> [stretch]
var frame := 0
var rects: Array = []
var times := [0.0, 0.9, 1.8, 2.7]

func _process(_d: float) -> bool:
	frame += 1
	var args := OS.get_cmdline_user_args()
	if frame == 2:
		var g: Node = load("res://game/core/game.gd").new()
		g.name = "Game"
		root.add_child(g)
		var bg := ColorRect.new()
		bg.color = Color(0.16, 0.14, 0.22)
		bg.size = Vector2(1280, 720)
		root.add_child(bg)
		var dbs = load("res://game/core/db.gd")
		var tex: Texture2D = dbs.art(args[1], 0)
		for i in 5:
			var r := TextureRect.new()
			r.texture = tex
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.position = Vector2(i * 256, 0)
			r.size = Vector2(256, 720)
			root.add_child(r)
			if i < 4:
				var rig = load("res://game/ui/char_rig.gd").new()
				r.add_child(rig)
				rects.append(rig)
			else:
				var ov := Control.new()
				ov.size = r.size
				r.add_child(ov)
				var rg: Dictionary = dbs.char_rig(tex)
				var ts := Vector2(tex.get_width(), tex.get_height())
				var sc := minf(256.0 / ts.x, 720.0 / ts.y)
				var off := (Vector2(256, 720) - ts * sc) * 0.5
				ov.draw.connect(func():
					var f := func(u: Vector2) -> Vector2: return off + u * ts * sc
					for b in rg.get("bones", []):
						ov.draw_line(f.call(Vector2(b[0], b[1])), f.call(Vector2(b[2], b[3])), Color(0, 1, 1), 2.0)
						ov.draw_circle(f.call(Vector2(b[0], b[1])), 4, Color(1, 0, 0))
					for k in ["neck", "hips", "chest"]:
						ov.draw_circle(f.call(rg[k]), 5, Color(1, 1, 0))
					var h: Vector3 = rg["head"]
					ov.draw_arc(f.call(Vector2(h.x, h.y)), h.z * ts.y * sc, 0, TAU, 32, Color(1, 0.5, 0), 2.0)
					if rg.has("eye_l"):
						ov.draw_circle(f.call(rg["eye_l"]), 3, Color(0, 1, 0))
						ov.draw_circle(f.call(rg["eye_r"]), 3, Color(0, 1, 0))
					for fl in rg.get("floats", []):
						ov.draw_arc(f.call(Vector2(fl[0], fl[1])), fl[2] * ts.y * sc, 0, TAU, 24, Color(0.6, 1, 0.6), 1.5))
	if frame == 5:
		for i in rects.size():
			rects[i]._t = times[i] * 3.0
			rects[i]._blink = 0.5 if i == 1 else 0.0
	if frame == 6:
		for i in rects.size():
			rects[i].set_process(false)
			rects[i]._blink = 0.5 if i == 1 else 0.0
	if frame == 7 and rects.size() > 3:
		rects[3]._mat.set_shader_parameter("jolt", 1.4)
	if frame == 12:
		RenderingServer.force_draw(false)
		root.get_viewport().get_texture().get_image().save_png(args[0])
		quit(0)
	return false
