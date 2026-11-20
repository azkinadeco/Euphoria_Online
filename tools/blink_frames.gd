extends SceneTree
## Dev tool: blink frames. Each row = one art (up to 4), columns = blink 0 / 0.25 / 0.5 / 0.75 / 1.
## Godot --path . --resolution 1600x900 -s res://tools/blink_sheet.gd -- <out.png> <res://art path> [more paths ...]
## (up to 8 arts; arts without measured eyes show "NO BLINK")
var frame := 0
var rigs: Array = []
const W := 256
const H := 180
const LV := [0.0, 0.25, 0.5, 0.75, 1.0]

func _process(_d: float) -> bool:
	frame += 1
	var args := OS.get_cmdline_user_args()
	if frame == 2:
		var g: Node = load("res://game/core/game.gd").new()
		g.name = "Game"
		g.set("persist", false)
		root.add_child(g)
		var bg := ColorRect.new()
		bg.color = Color(0.1, 0.1, 0.12)
		bg.size = Vector2(1280, 720)
		root.add_child(bg)
		var dbs = load("res://game/core/db.gd")
		var paths: Array = args.slice(1, 5)
		for n in paths.size():
			var tex: Texture2D = load(paths[n])
			var rg: Dictionary = dbs.char_rig(tex)
			var a := float(tex.get_width()) / tex.get_height()
			var pts: Array = []
			for e in rg.get("eyes", []):
				if (e as Array).size() >= 6:
					pts.append(Vector2(e[0], e[1]))
					pts.append(Vector2(e[2], e[3]))
			var h: Vector3 = rg.get("head", Vector3(0.5, 0.15, 0.05))
			var c := Vector2(h.x, h.y)
			var span := h.z * 1.6
			if not pts.is_empty():
				var mn: Vector2 = pts[0]
				var mx: Vector2 = pts[0]
				for p in pts:
					mn = mn.min(p)
					mx = mx.max(p)
				c = (mn + mx) * 0.5
				span = maxf((mx.x - mn.x) * a, 0.03)
			var hpx := 170.0 / span * float(OS.get_environment("ZOOM") if OS.get_environment("ZOOM") != "" else "1")
			var sz := Vector2(hpx * a, hpx)
			for k in LV.size():
				var clip := Control.new()
				clip.clip_contents = true
				clip.position = Vector2(k * W, n * H)
				clip.size = Vector2(W - 4, H - 4)
				root.add_child(clip)
				var r := TextureRect.new()
				r.texture = tex
				r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				r.stretch_mode = TextureRect.STRETCH_SCALE
				r.size = sz
				r.position = Vector2(W, H) * 0.5 - c * sz
				clip.add_child(r)
				var rig = load("res://game/ui/char_rig.gd").new()
				r.add_child(rig)
				rig.set_meta("closed", LV[k])
				rigs.append(rig)
				var lb := Label.new()
				lb.text = str(paths[n]).get_file().get_basename() + ("" if not pts.is_empty() else "  NO BLINK")
				lb.add_theme_font_size_override("font_size", 13)
				lb.add_theme_color_override("font_color", Color(0, 1, 1) if not pts.is_empty() else Color(1, 0.4, 0.4))
				lb.add_theme_color_override("font_outline_color", Color.BLACK)
				lb.add_theme_constant_override("outline_size", 4)
				lb.position = Vector2(4, 2)
				clip.add_child(lb)
	if frame == 6:
		for rig in rigs:
			rig.set_process(false)
			var v: float = rig.get_meta("closed")
			if rig._mat == null:
				continue
			rig._mat.set_shader_parameter("blinks", PackedFloat32Array([v, v, v, v, v, v, v, v]))
			for k in ["head_angle", "body_angle", "breath", "bob"]:
				rig._mat.set_shader_parameter(k, 0.0)
	if frame == 12:
		RenderingServer.force_draw(false)
		root.get_viewport().get_texture().get_image().save_png(args[0])
		quit(0)
	return false
