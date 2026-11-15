class_name SummonFX
extends Control
## The summon gate animation (replaces a thin line-art circle): energy specks spiral into a glowing core
## inside rune rings; the core takes the colour of the best rarity in the pull (the "tell"), rays open up,
## then everything bursts into a shock ring and a shower of sparks.
##   var fx := SummonFX.new(); add_child(fx); fx.charge(); ... fx.tell(col, tier); ... fx.burst()

const NEUTRAL := Color(0.72, 0.78, 1.0)

var _mat: ShaderMaterial
var _rect: ColorRect
var _t := 0.0
var _spin := 0.0
var _spin_speed := 0.6
var _specks: Array = []     # inward: {a, r, sp, w, col_k}
var _sparks: Array = []     # outward: {p, v, life, age, w}
var _col := NEUTRAL
var _inflow := 0.0          # 0..1 how many specks are flying in
var _tier := 0              # 0 R, 1 SR, 2 SSR
var _calm := false

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_calm = Game.reduce_fx()
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://game/ui/summon_core.gdshader")
	_mat.set_shader_parameter("tint", NEUTRAL)
	_rect.material = _mat
	add_child(_rect)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add
	for i in 90:
		_specks.append(_new_speck(true))
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	if _mat != null and size.y > 1.0:
		_mat.set_shader_parameter("aspect", size.x / size.y)

func _new_speck(anywhere: bool) -> Dictionary:
	return {"a": randf() * TAU, "r": randf_range(0.25, 1.0) if anywhere else randf_range(0.8, 1.05),
		"sp": randf_range(0.35, 0.8), "w": randf_range(1.2, 3.2), "k": randf()}

## Phase 1: the gate wakes up and starts pulling energy in.
func charge(dur: float = 1.3) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("power", v), 0.0, 0.55, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("rings", v), 0.0, 1.0, dur * 0.6)
	tw.tween_property(self, "_inflow", 1.0, dur * 0.5)
	tw.tween_property(self, "_spin_speed", 1.6, dur)

## Phase 2: the core shows what is coming. tier 0 = R, 1 = SR, 2 = SSR.
func tell(col: Color, tier: int, dur: float = 0.9) -> void:
	_tier = tier
	var from := _col
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float):
		_col = from.lerp(col, v)
		_mat.set_shader_parameter("tint", _col), 0.0, 1.0, dur * 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("power", v), 0.55, 0.8 + tier * 0.22, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("rays", v), 0.0, 0.25 + tier * 0.38, dur)
	tw.tween_property(self, "_spin_speed", 2.6 + tier * 1.4, dur)
	if tier >= 2:
		_mat.set_shader_parameter("hot", Color(1.0, 0.97, 0.82))

## Phase 3: release. Returns after `dur`; the node frees itself.
func burst(dur: float = 0.7) -> void:
	_inflow = 0.0
	var n := 60 + _tier * 50
	if _calm:
		n = 24
	for i in n:
		var ang := randf() * TAU
		var spd := randf_range(0.35, 1.25) * (1.0 + _tier * 0.25)
		_sparks.append({"p": Vector2.ZERO, "v": Vector2(cos(ang), sin(ang)) * spd, "life": randf_range(0.45, 1.0), "age": 0.0, "w": randf_range(1.5, 4.0)})
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("burst", v), 0.001, 1.0, dur).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("power", v), 1.4, 0.0, dur * 0.8)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("rings", v), 1.0, 0.0, dur * 0.35)
	tw.tween_method(func(v: float): _mat.set_shader_parameter("rays", v), 1.0, 0.0, dur * 0.7)
	tw.chain().tween_interval(0.5)
	tw.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	_t += delta
	_spin += delta * _spin_speed
	if _mat != null:
		_mat.set_shader_parameter("spin", _spin)
	for s in _specks:
		# spiral inward: faster and tighter near the core
		s["r"] = float(s["r"]) - delta * float(s["sp"]) * (0.35 + (1.0 - float(s["r"])) * 0.9) * (0.4 + _inflow)
		s["a"] = float(s["a"]) + delta * (0.8 + (1.0 - float(s["r"])) * 3.0)
		if float(s["r"]) < 0.02:
			var ns := _new_speck(false)
			for key in ns.keys():
				s[key] = ns[key]
	for sp in _sparks:
		sp["age"] = float(sp["age"]) + delta
		sp["p"] = (sp["p"] as Vector2) + (sp["v"] as Vector2) * delta
		sp["v"] = (sp["v"] as Vector2) * (1.0 - delta * 1.4)
	_sparks = _sparks.filter(func(q): return float(q["age"]) < float(q["life"]))
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var unit := size.y * 0.5
	if _inflow > 0.01:
		var shown := int(_specks.size() * _inflow * (0.4 if _calm else 1.0))
		for i in shown:
			var s: Dictionary = _specks[i]
			var r := float(s["r"])
			var a := float(s["a"])
			var p := c + Vector2(cos(a), sin(a) * 0.9) * r * unit
			# a short tail pointing back along the spiral
			var p2 := c + Vector2(cos(a - 0.16), sin(a - 0.16) * 0.9) * (r + 0.035) * unit
			var fade := clampf((1.0 - r) * 1.6, 0.0, 1.0) * clampf(r * 9.0, 0.0, 1.0)
			var col := _col.lerp(Color.WHITE, float(s["k"]) * 0.6)
			draw_line(p2, p, Color(col, 0.35 * fade), float(s["w"]) * 0.8, true)
			draw_circle(p, float(s["w"]) * 0.9, Color(col, 0.9 * fade))
	for sp in _sparks:
		var k := 1.0 - float(sp["age"]) / float(sp["life"])
		var p := c + (sp["p"] as Vector2) * unit
		var tail := p - (sp["v"] as Vector2) * unit * 0.07
		var col2 := _col.lerp(Color.WHITE, 0.55)
		draw_line(tail, p, Color(col2, 0.5 * k), float(sp["w"]) * k, true)
		draw_circle(p, float(sp["w"]) * 0.8 * k, Color(col2, k))
