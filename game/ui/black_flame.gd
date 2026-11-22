extends Control
## Black-flame aura behind Abyss (Evolution tier 4) stars (game/ui/black_flame.gdshader: noise flames that
## rise from each star, near-black violet with a glowing rim). Fills its parent; one ColorRect, GPU only.
## Used by UI.rank_stars. Preloaded, no class_name.

static var _shader: Shader
var stars := 6

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader == null:
		_shader = load("res://game/ui/black_flame.gdshader")
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("stars", float(stars))
	m.set_shader_parameter("seed", randf() * 20.0)
	m.set_shader_parameter("speed", 0.0 if Game.reduce_fx() else 1.0)
	r.material = m
	add_child(r)
