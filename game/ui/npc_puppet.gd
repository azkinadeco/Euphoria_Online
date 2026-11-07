class_name NPCPuppet
extends TextureRect
## Animated shop NPC built from one illustration + pivot points (see npc_rig.gdshader).
## Idle: breathing, body sway, head drift, hair sway, random (double) blinks.
## Talking: lip flap synced to the voice clip length + small head nods.
## Touch zones: head / body / legs, each with its own voice line and reaction.

signal spoke(text: String)

var voice_id := "shop2"
var pivots: Dictionary = {}   # optional overrides of npc_rig.gdshader pivot uniforms (UV space)
var _m: ShaderMaterial
var _t := 0.0
var _blink_t := 2.0
var _blink := 0.0
var _talk_left := 0.0
var _head_extra := 0.0      # reaction offsets, eased back to 0
var _body_extra := 0.0
var _blush := 0.0
var _idle_t := 0.0
var _idle_next := 16.0

func _init(tex: Texture2D = null, voice: String = "shop2", pivot_overrides: Dictionary = {}) -> void:
	texture = tex
	voice_id = voice
	pivots = pivot_overrides
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _ready() -> void:
	_m = ShaderMaterial.new()
	_m.shader = load("res://game/ui/npc_rig.gdshader")
	if texture:
		_m.set_shader_parameter("aspect", float(texture.get_width()) / float(texture.get_height()))
	for k in pivots.keys():
		var val = pivots[k]
		if val is Array:
			val = PackedVector3Array(val)
		_m.set_shader_parameter(k, val)
	material = _m
	resized.connect(func(): pivot_offset = Vector2(size.x * 0.5, size.y))
	gui_input.connect(_on_input)

func _process(delta: float) -> void:
	_t += delta
	var calm := 0.35 if Game.reduce_fx() else 1.0
	# blink scheduler (sometimes a double blink)
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink = 1.0
		_blink_t = randf_range(2.2, 5.0) if randf() > 0.2 else 0.22
	_blink = maxf(0.0, _blink - delta * 7.0)
	var lid := sin(_blink * PI) if _blink > 0.0 else 0.0
	# talking
	var mo := 0.0
	if _talk_left > 0.0:
		_talk_left -= delta
		mo = clampf(0.45 + 0.55 * sin(_t * 19.0) * sin(_t * 7.3 + 1.0), 0.0, 1.0)
	_head_extra = lerpf(_head_extra, 0.0, delta * 3.0)
	_body_extra = lerpf(_body_extra, 0.0, delta * 2.5)
	_blush = maxf(0.0, _blush - delta * 0.35)
	var nod := sin(_t * 9.0) * 0.012 if _talk_left > 0.0 else 0.0
	_m.set_shader_parameter("head_angle", (sin(_t * 0.7) * 0.025 + sin(_t * 1.9) * 0.006) * calm + nod + _head_extra)
	_m.set_shader_parameter("body_angle", sin(_t * 0.5 + 0.8) * 0.012 * calm + _body_extra)
	_m.set_shader_parameter("breath", sin(_t * 1.6))
	_m.set_shader_parameter("hand_lift", sin(_t * 1.6 + 0.6))
	_m.set_shader_parameter("hair_phase", _t * 1.4)
	_m.set_shader_parameter("blink", lid)
	_m.set_shader_parameter("mouth_open", mo)
	_m.set_shader_parameter("blush", _blush)
	_m.set_shader_parameter("flame_time", _t)
	# idle chatter if the player hasn't interacted for a while
	_idle_t += delta
	if _idle_t > _idle_next:
		_idle_t = 0.0
		_idle_next = randf_range(18.0, 30.0)
		say("idle")

## Play a voice line from data/voice_lines.json (category) and animate the mouth for its length.
func say(cat: String) -> String:
	var text := Game.voice(voice_id, cat)
	var path := "res://audio/voice/%s_%s.wav" % [voice_id, cat]
	var dur := 1.6
	if ResourceLoader.exists(path):
		var st: AudioStream = load(path)
		dur = maxf(0.6, st.get_length())
	_talk_left = dur
	_idle_t = 0.0
	spoke.emit(text)
	return text

func react_happy() -> void:
	say("thanks")
	_head_extra = 0.08
	_blush = 1.0
	_hop(14.0)

func react_sad() -> void:
	say("poor")
	_head_extra = -0.06
	_body_extra = 0.02

func greet() -> void:
	say("greet")
	_head_extra = 0.05

func browse() -> void:
	say("browse")
	_head_extra = -0.04

func _hop(h: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - h, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

## Touch zones measured on the illustration: head (above the neck), body, legs.
func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	var r := _drawn_rect()
	if r.size.x <= 0.0:
		return
	var v: float = (e.position.y - r.position.y) / r.size.y
	if v < 0.2:
		say("tap_head")
		_head_extra = 0.12
		_blush = 0.8
	elif v < 0.56:
		say("tap_body")
		_blush = 1.0
		_body_extra = -0.04
		_hop(10.0)
	else:
		say("tap_legs")
		_body_extra = 0.05
		_head_extra = -0.07
	Game.sfx("ui_click")

## The area the texture actually occupies inside this rect (keep-aspect-centred).
func _drawn_rect() -> Rect2:
	if texture == null:
		return Rect2()
	var ts := Vector2(texture.get_width(), texture.get_height())
	var sc := minf(size.x / ts.x, size.y / ts.y)
	var ds := ts * sc
	return Rect2((size - ds) * 0.5, ds)
