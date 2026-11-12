extends SceneTree
## Dev tool: blink check for a pivot rig — eye close-ups at blink 0 / 0.5 / 1 (+ a head-turn panel).
## Godot --path . -s res://tools/rig_face.gd -- <out.png> <hero or enemy id> [art index]
var frame := 0
var rigs: Array = []
const STATES := [0.0, 0.5, 1.0, 0.0]

func _process(_d: float) -> bool:
	frame += 1
	var args := OS.get_cmdline_user_args()
	if frame == 2:
		var g: Node = load("res://game/core/game.gd").new()
		g.name = "Game"
		root.add_child(g)
		var dbs = load("res://game/core/db.gd")
		var tex: Texture2D = load(args[1]) if args[1].begins_with("res://") else dbs.art(args[1], int(args[2]) if args.size() > 2 else 0)
		var rg: Dictionary = dbs.char_rig(tex)
		var a := float(tex.get_width()) / tex.get_height()
		var pts: Array = []
		for e in rg.get("eyes", []):
			if (e as Array).size() >= 6:
				pts.append(Vector2(e[0], e[1]))
				pts.append(Vector2(e[2], e[3]))
		var h: Vector3 = rg["head"]
		var c := Vector2(h.x, h.y)
		var span := 0.06
		if not pts.is_empty():
			var mn: Vector2 = pts[0]
			var mx: Vector2 = pts[0]
			for p in pts:
				mn = mn.min(p)
				mx = mx.max(p)
			c = (mn + mx) * 0.5
			span = maxf((mx.x - mn.x) * a, 0.03)
		var hpx := 300.0 / span          # eyes span ~300 px
		var sz := Vector2(hpx * a, hpx)
		for i in 4:
			var clip := Control.new()
			clip.clip_contents = true
			clip.position = Vector2((i % 2) * 640, (i / 2) * 360)
			clip.size = Vector2(636, 356)
			root.add_child(clip)
			var r := TextureRect.new()
			r.texture = tex
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_SCALE
			r.size = sz
			r.position = Vector2(318, 178) - c * sz
			clip.add_child(r)
			var rig = load("res://game/ui/char_rig.gd").new()
			r.add_child(rig)
			rigs.append(rig)
			if i == 0:
				# debug: measured eye corners / lids as dots on the untouched panel
				var ov := Control.new()
				ov.size = sz
				r.add_child(ov)
				var eyes: Array = rg.get("eyes", [])
				ov.set_meta("eyes", eyes)
				ov.draw.connect(_dots.bind(ov, sz))
	if frame == 6:
		for i in rigs.size():
			rigs[i].set_process(false)
			var bl := PackedFloat32Array([STATES[i], STATES[i], STATES[i], STATES[i], STATES[i], STATES[i], STATES[i], STATES[i]])
			rigs[i]._mat.set_shader_parameter("blinks", bl)
			rigs[i]._mat.set_shader_parameter("head_angle", 0.06 if i == 3 else 0.0)
			rigs[i]._mat.set_shader_parameter("body_angle", 0.0)
			rigs[i]._mat.set_shader_parameter("breath", 0.0)
			rigs[i]._mat.set_shader_parameter("bob", 0.0)
	if frame == 12:
		RenderingServer.force_draw(false)
		root.get_viewport().get_texture().get_image().save_png(args[0])
		quit(0)
	return false

func _dots(ov: Control, sz: Vector2) -> void:
	for e in ov.get_meta("eyes"):
		if (e as Array).size() >= 6:
			var cx := (float(e[0]) + float(e[2])) * 0.5
			for p in [Vector2(e[0], e[1]), Vector2(e[2], e[3]), Vector2(cx, e[4]), Vector2(cx, e[5])]:
				ov.draw_circle(p * sz, 3.0, Color(1, 0, 0))
