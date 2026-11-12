class_name CharRig
extends Node
## Pivot-rig animator for hero AND enemy illustrations (like the shop keepers' NPCPuppet).
## UI.live attaches it to every live art: whenever the texture has a rig (DB.HERO_RIGS / ENEMY_RIGS)
## it swaps in char_rig.gdshader and plays a layered idle — breathing, body sway, head drift with the odd
## look-around, hair / tail / tentacle waves, glowing flames, random (double) blinks.
## Call react(ry) on a tap (0 = top of the art) for a flinch / nod / jolt.

var _rect: TextureRect
var _mat: ShaderMaterial
var _prev_mat: Material
var _last_tex: Texture2D
var _rig: Dictionary = {}
var _t := 0.0
var _seed := 0.0
var _blink_t := 1.5
var _blink := 0.0
var _eye_n := 0
var _eye_blink := PackedFloat32Array()   # extra eyes (index >= 2): own blink progress
var _eye_t := PackedFloat32Array()
var _look := 0.0          # slow "look around" target for the head
var _look_cur := 0.0
var _look_t := 3.0
var _head_kick := 0.0     # reaction offsets (decay to 0)
var _body_kick := 0.0
var _jolt := 0.0
var _flash := 0.0

static func attach(rect: TextureRect) -> CharRig:
	for c in rect.get_children():
		if c is CharRig:
			return c
	var r := CharRig.new()
	rect.add_child(r)
	return r

func _ready() -> void:
	_rect = get_parent() as TextureRect
	_seed = randf() * 10.0
	_check()

## UI.live installed a fresh material on the rect: re-apply the rig on top of it.
func refresh() -> void:
	if _rect != null:
		if _rect.material != _mat:
			_prev_mat = _rect.material
		_check()

func active() -> bool:
	return not _rig.is_empty() and _rect != null and _rect.material == _mat

func _check() -> void:
	_last_tex = _rect.texture
	var rig := DB.char_rig(_rect.texture) if bool(Game.s.get("settings", {}).get("live25d", true)) else {}
	if rig.is_empty():
		if _mat != null and _rect.material == _mat:
			_rect.material = _prev_mat
		_rig = {}
		return
	if _rect.material != _mat:
		# only take over plain / live-art materials — never a corrupt / mirror variant look
		var cur := _rect.material as ShaderMaterial
		if _rect.has_meta("corrupt_params") or _rect.material != null and (cur == null or cur.shader == null or not (cur.shader.resource_path.ends_with("live_art.gdshader") or cur.shader.resource_path.ends_with("live25d.gdshader"))):
			_rig = {}
			return
		_prev_mat = _rect.material
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://game/ui/char_rig.gdshader")
	_rig = rig
	var tex := _rect.texture
	_mat.set_shader_parameter("aspect", float(tex.get_width()) / float(tex.get_height()))
	var bone_a := PackedVector4Array()
	var bone_b := PackedVector4Array()
	for i in 10:
		var b: Array = (rig.get("bones", []) as Array)[i] if i < (rig.get("bones", []) as Array).size() else []
		if b.size() >= 7:
			bone_a.append(Vector4(b[0], b[1], b[2], b[3]))
			bone_b.append(Vector4(b[4], b[5], b[6], b[7] if b.size() > 7 else float(i) * 1.3))
		else:
			bone_a.append(Vector4.ZERO)
			bone_b.append(Vector4.ZERO)
	_mat.set_shader_parameter("bone_a", bone_a)
	_mat.set_shader_parameter("bone_b", bone_b)
	var glows := PackedVector3Array()
	for i in 6:
		var g: Array = (rig.get("glows", []) as Array)[i] if i < (rig.get("glows", []) as Array).size() else []
		glows.append(Vector3(g[0], g[1], g[2]) if g.size() == 3 else Vector3.ZERO)
	_mat.set_shader_parameter("glows", glows)
	var fl := PackedVector4Array()
	for i in 6:
		var f: Array = (rig.get("floats", []) as Array)[i] if i < (rig.get("floats", []) as Array).size() else []
		fl.append(Vector4(f[0], f[1], f[2], f[3]) if f.size() == 4 else Vector4.ZERO)
	_mat.set_shader_parameter("floats", fl)
	for k in ["neck", "hips", "chest", "head", "chest_w", "glow_color", "bone_wave", "head_band", "lash", "lid_close", "skin_hint"]:
		if rig.has(k):
			_mat.set_shader_parameter(k, rig[k])
	if not rig.has("skin_hint"):
		_mat.set_shader_parameter("skin_hint", Color(0, 0, 0, 0))
	_set_eyes(rig.get("eyes", []), float(tex.get_width()) / float(tex.get_height()))
	_rect.material = _mat

## eyes: [[corner x, y, other corner x, y, top-lid y, bottom-lid y], …] measured on the art (UV).
## The first two are the face; any more (eyes on tails, staffs, creatures) blink on their own timers.
## → centre, tilt and half-sizes in aspect-corrected units for the shader.
func _set_eyes(eyes: Array, aspect: float) -> void:
	var cen := PackedVector4Array()
	var rots := PackedFloat32Array()
	_eye_n = mini(eyes.size(), 8)
	_eye_blink.resize(8)
	_eye_t.resize(8)
	for i in 8:
		_eye_blink[i] = 0.0
		_eye_t[i] = randf_range(0.5, 4.0)
		var m: Array = eyes[i] if i < eyes.size() else []
		if m.size() < 6:
			cen.append(Vector4.ZERO)   # unused, or hidden by hair etc.
			rots.append(0.0)
			continue
		var a := Vector2(float(m[0]) * aspect, float(m[1]))
		var b := Vector2(float(m[2]) * aspect, float(m[3]))
		var axis := b - a
		if axis.x < 0.0:
			axis = -axis
		var c := Vector2((float(m[0]) + float(m[2])) * 0.5, (float(m[4]) + float(m[5])) * 0.5)
		var hh := (float(m[5]) - float(m[4])) * 0.5
		# a little margin: painted lashes and corners reach past the measured opening
		cen.append(Vector4(c.x, c.y, axis.length() * 0.5 * 1.12, hh * 1.1))
		rots.append(atan2(axis.y, axis.x))
	_mat.set_shader_parameter("skins", _eye_skins(cen, aspect))
	_mat.set_shader_parameter("eyes", cen)
	_mat.set_shader_parameter("eye_rots", rots)
	_mat.set_shader_parameter("eye_count", _eye_n)
	_mat.set_shader_parameter("blinks", PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0]))

static var _skin_cache: Dictionary = {}

## Face skin colour next to each eye, measured once per art on the CPU: pixels on the cheek below the
## eye, on the nose side (toward the other eye / head centre); the median-bright cluster wins, so hair
## strands and shadows crossing that area do not count. a = 0 when nothing reliable was found.
func _eye_skins(cen: PackedVector4Array, aspect: float) -> PackedVector4Array:
	var out := PackedVector4Array()
	out.resize(8)
	var tex := _rect.texture
	var key := tex.resource_path
	if _skin_cache.has(key):
		return _skin_cache[key]
	var img: Image = tex.get_image()
	if img == null:
		return out
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var hd: Vector3 = _rig.get("head", Vector3(0.5, 0.2, 0.06))
	for i in cen.size():
		var e := cen[i]
		if e.z <= 0.0:
			continue
		var other := Vector2(hd.x, hd.y)
		if i < 2 and cen.size() > 1 and cen[1 - i].z > 0.0:
			other = Vector2(cen[1 - i].x, cen[1 - i].y)
		var toward := signf(other.x - e.x)
		if absf(other.x - e.x) < 0.001:
			toward = 1.0
		var cols: Array = []
		for gy in 6:
			for gx in 6:
				var dy := e.w * (1.6 + float(gy) * 0.5)
				var dx := e.z * (-0.6 + float(gx) * 0.35) * toward
				var u := e.x + dx / aspect
				var v := e.y + dy
				if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
					continue
				var c := img.get_pixel(int(u * (w - 1)), int(v * (h - 1)))
				if c.a > 0.9:
					cols.append(c)
		if cols.size() < 6:
			continue
		cols.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
		var med: Color = cols[cols.size() / 2]
		var sum := Vector3.ZERO
		var n := 0
		for c in cols:
			var cc: Color = c
			if Vector3(cc.r - med.r, cc.g - med.g, cc.b - med.b).length() < 0.12:
				sum += Vector3(cc.r, cc.g, cc.b)
				n += 1
		if n > 0:
			sum /= float(n)
			out[i] = Vector4(sum.x, sum.y, sum.z, 1.0)
	# one face, one skin tone: when the two eyes disagree, the warmer / brighter (more skin-like)
	# measurement wins for both (the other one hit a shadow, a hair strand or face paint)
	if out[0].w > 0.0 and out[1].w > 0.0:
		var a0 := Vector3(out[0].x, out[0].y, out[0].z)
		var a1 := Vector3(out[1].x, out[1].y, out[1].z)
		if a0.distance_to(a1) > 0.12:
			var s0 := a0.dot(Vector3(0.3, 0.55, 0.15)) + 1.5 * (a0.x - a0.z)
			var s1 := a1.dot(Vector3(0.3, 0.55, 0.15)) + 1.5 * (a1.x - a1.z)
			if s0 >= s1:
				out[1] = out[0]
			else:
				out[0] = out[1]
	_skin_cache[key] = out
	return out

## Tap reaction: head = shy nod, body = flinch + sway, legs = startled hop of every bone.
func react(ry: float) -> void:
	if not active():
		return
	if ry < 0.3:
		_head_kick = 0.09 * (1.0 if randf() < 0.5 else -1.0)
		_blink = 1.0
	elif ry < 0.65:
		_body_kick = -0.035
		_head_kick = -0.05
		_jolt = 1.0
	else:
		_jolt = 1.4
		_body_kick = 0.03
	_flash = 0.14

## Eyelid curve over one blink (p 0→1, 0.24 s): snaps shut, holds a beat, eases open.
static func _lid(p: float) -> float:
	if p < 0.28:
		return ease(p / 0.28, 0.6)
	if p < 0.4:
		return 1.0
	return 1.0 - ease((p - 0.4) / 0.6, 0.5)

func _process(delta: float) -> void:
	if not is_instance_valid(_rect):
		return
	if _rect.texture != _last_tex:
		_check()
	if not active():
		return
	var calm := 0.4 if Game.reduce_fx() else 1.0
	_t += delta
	var t := _t + _seed
	var spd: float = float(_rig.get("speed", 1.0))
	# blink scheduler (sometimes a double blink)
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink = 1.0
		_blink_t = randf_range(2.4, 5.5) if randf() > 0.2 else 0.3
	_blink = maxf(0.0, _blink - delta / 0.24)
	# every few seconds she glances somewhere else, then settles
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = randf_range(3.5, 7.0)
		_look = randf_range(-1.0, 1.0) if randf() < 0.6 else 0.0
	_look_cur = lerpf(_look_cur, _look, clampf(delta * 1.8, 0.0, 1.0))
	_head_kick = lerpf(_head_kick, 0.0, clampf(delta * 3.2, 0.0, 1.0))
	_body_kick = lerpf(_body_kick, 0.0, clampf(delta * 2.6, 0.0, 1.0))
	_jolt = maxf(0.0, _jolt - delta * 1.6)
	_flash = maxf(0.0, _flash - delta * 0.6)
	var breath := sin(t * 1.55 * spd)
	var ha: float = float(_rig.get("head_amp", 1.0))
	var ba: float = float(_rig.get("body_amp", 1.0))
	_mat.set_shader_parameter("t", t * spd)
	_mat.set_shader_parameter("calm", calm)
	_mat.set_shader_parameter("breath", breath * calm)
	_mat.set_shader_parameter("bob", (sin(t * 1.55 * spd - 0.6) * 0.0018) * calm * float(_rig.get("bob", 1.0)))
	_mat.set_shader_parameter("head_angle", ((sin(t * 0.62) * 0.022 + sin(t * 1.7) * 0.005) * ha + _look_cur * 0.035 * ha) * calm + _head_kick)
	_mat.set_shader_parameter("body_angle", (sin(t * 0.45 + 0.8) * 0.011 + sin(t * 1.55 * spd) * 0.003) * ba * calm + _body_kick)
	if _eye_n > 0:
		var face := _lid(1.0 - _blink) if _blink > 0.0 else 0.0
		var bl := PackedFloat32Array()
		bl.resize(8)
		for i in _eye_n:
			if i < 2:
				bl[i] = face
				continue
			# extra eyes: each on its own rhythm (slower, lazier blinks)
			_eye_t[i] -= delta
			if _eye_t[i] <= 0.0:
				_eye_blink[i] = 1.0
				_eye_t[i] = randf_range(1.8, 6.5)
			_eye_blink[i] = maxf(0.0, _eye_blink[i] - delta / 0.34)
			bl[i] = _lid(1.0 - _eye_blink[i]) if _eye_blink[i] > 0.0 else 0.0
		_mat.set_shader_parameter("blinks", bl)
	_mat.set_shader_parameter("jolt", _jolt)
	_mat.set_shader_parameter("flash", _flash)
