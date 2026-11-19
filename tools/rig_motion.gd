extends SceneTree
## Dev tool: how much a rigged art moves. Renders the CharRig at 8 moments over 4 s and saves them as one strip;
## prints the mean pixel change per region (head / body / outer) vs the first frame.
## Godot --path . -s res://tools/rig_motion.gd -- <out.png> <res://art path>
var frame := 0
var rigs: Array = []
const N := 8

func _process(_d: float) -> bool:
	frame += 1
	var args := OS.get_cmdline_user_args()
	if frame == 2:
		var g: Node = load("res://game/core/game.gd").new()
		g.name = "Game"
		g.set("persist", false)
		root.add_child(g)
		var bg := ColorRect.new()
		bg.color = Color(0.16, 0.14, 0.22)
		bg.size = Vector2(1600, 600)
		root.add_child(bg)
		var tex: Texture2D = load(args[1])
		for i in N:
			var r := TextureRect.new()
			r.texture = tex
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.position = Vector2(i * 200, 0)
			r.size = Vector2(200, 600)
			root.add_child(r)
			var rig = load("res://game/ui/char_rig.gd").new()
			r.add_child(rig)
			rigs.append(rig)
	if frame == 5:
		for i in rigs.size():
			rigs[i]._t = float(i) * 0.5 + 0.01
			rigs[i]._blink = 0.0
			rigs[i].set_process(false)
	if frame == 10:
		RenderingServer.force_draw(false)
		root.get_viewport().get_texture().get_image().save_png(args[0])
		quit(0)
	return false
