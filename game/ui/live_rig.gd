class_name LiveRig
extends Node
## Attached by UI.live to a hero TextureRect. Whenever the art shown has a 2.5D rig
## (DB.LIVE_RIGS: depth map + pivots), it swaps in live25d.gdshader and drives the tilt:
## the illustration leans toward the pointer / finger, with a slow idle orbit otherwise.

var _rect: TextureRect
var _live_mat: Material
var _rig_mat: ShaderMaterial
var _last_tex: Texture2D
var _tilt := Vector2.ZERO
var _t := 0.0

func _ready() -> void:
	_rect = get_parent() as TextureRect
	_live_mat = _rect.material
	_check()

## UI.live calls this when it installs a fresh live material on the same rect.
func set_live(m: Material) -> void:
	_live_mat = m
	_check()

func _check() -> void:
	_last_tex = _rect.texture
	var cfg: Dictionary = DB.live_rig(_rect.texture) if bool(Game.s.get("settings", {}).get("live25d", true)) else {}
	if cfg.is_empty():
		# only undo our own rig — never touch a foreign material (corrupt / mirror variants etc.)
		if _rig_mat != null and _rect.material == _rig_mat:
			_rect.material = _live_mat
		return
	if _rect.material != _live_mat and _rect.material != _rig_mat:
		return
	if _rig_mat == null:
		_rig_mat = ShaderMaterial.new()
		_rig_mat.shader = load("res://game/ui/live25d.gdshader")
	_rig_mat.set_shader_parameter("depth_tex", load(str(cfg["depth"])))
	_rig_mat.set_shader_parameter("aspect", float(_rect.texture.get_width()) / float(_rect.texture.get_height()))
	_rig_mat.set_shader_parameter("calm", 0.35 if Game.reduce_fx() else 1.0)
	_rig_mat.set_shader_parameter("generic", false)
	_rig_mat.set_shader_parameter("strength", 0.018)
	_rig_mat.set_shader_parameter("hue_shift", 0.72)
	_rig_mat.set_shader_parameter("desat", 0.0)
	_rig_mat.set_shader_parameter("variant_glow", Color(0.75, 0.2, 1.0))
	var cp: Dictionary = _rect.get_meta("corrupt_params", {})
	_rig_mat.set_shader_parameter("corrupt_on", not cp.is_empty())
	for ck in cp.keys():
		if cp[ck] != null:
			_rig_mat.set_shader_parameter(ck, cp[ck])
	for key in cfg.keys():
		if key != "depth":
			_rig_mat.set_shader_parameter(key, cfg[key])
	_rect.material = _rig_mat

func _process(delta: float) -> void:
	if not is_instance_valid(_rect):
		return
	if _rect.texture != _last_tex:
		_check()
	if _rect.material != _rig_mat or _rig_mat == null:
		return
	_t += delta
	# target: pointer relative to the art centre, else a slow figure-eight orbit
	var r := _rect.get_global_rect()
	var target := Vector2(sin(_t * 0.45) * 0.55, sin(_t * 0.9) * 0.25)
	var mp := _rect.get_global_mouse_position()
	if r.grow(r.size.x * 0.5).has_point(mp) and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not (OS.has_feature("mobile") or OS.has_feature("web_ios") or OS.has_feature("web_android"))):
		target = ((mp - r.get_center()) / (r.size * 0.5)).clamp(Vector2(-1, -1), Vector2(1, 1))
	_tilt = _tilt.lerp(target, clampf(delta * 3.0, 0.0, 1.0))
	_rig_mat.set_shader_parameter("tilt", _tilt)
