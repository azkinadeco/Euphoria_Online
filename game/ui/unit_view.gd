class_name UnitView
extends Control
## Chibi unit standing on a grid tile: shadow, sprite, order badge, HP bar.

var unit_id := ""
var enemy := false
var sprite: TextureRect
var hp_bar: ProgressBar
var badge: Label
var name_label: Label
var status_label: Label
var _idle: Tween
var trail: ProgressBar
var status_row: HBoxContainer
var arrow: Label
var statuses: Array = []
var _shadow: TextureRect
static var _shadow_cache: Texture2D

static func _shadow_tex() -> Texture2D:
	if _shadow_cache == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0.6))
		g.set_color(1, Color(0, 0, 0, 0.0))
		g.add_point(0.55, Color(0, 0, 0, 0.32))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		_shadow_cache = gt
	return _shadow_cache
const STATUS_STYLE := {"BURN": ["B", Color("#ff7a3d")], "STUN": ["Z", Color("#ffd84a")], "SHIELD": ["S", Color("#5fb8ff")],
	"ATK ▲": ["A", Color("#ff5c6c")], "DEF ▼": ["D", Color("#b072ff")], "TAUNT": ["T", Color("#ff9f43")],
	"SILENCE": ["X", Color("#9aa3b8")], "HEAL ▼": ["H", Color("#7a2a3a")]}

func _init(id: String = "", is_enemy: bool = false, tex: Texture2D = null, sz: Vector2 = Vector2(120, 140), order: int = -1, show_hp: bool = true, boss: bool = false) -> void:
	unit_id = id
	enemy = is_enemy
	custom_minimum_size = sz
	size = sz
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = Vector2(sz.x * 0.5, sz.y)

	# soft radial contact shadow (darker core, feathered edge)
	var shadow := TextureRect.new()
	shadow.texture = _shadow_tex()
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.size = Vector2(sz.x * 0.78, sz.y * 0.16)
	shadow.position = Vector2(sz.x * 0.11, sz.y * 0.86)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)
	_shadow = shadow

	sprite = TextureRect.new()
	sprite.texture = tex
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = sz
	sprite.flip_h = is_enemy
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.pivot_offset = Vector2(sz.x * 0.5, sz.y)
	add_child(sprite)
	if boss:
		sprite.modulate = Color(1.15, 0.95, 0.95)

	if show_hp:
		trail = UI.bar(1, 1, "", 9)
		trail.size = Vector2(sz.x * 0.7, 9)
		trail.position = Vector2(sz.x * 0.15, sz.y + 2)
		trail.add_theme_stylebox_override("fill", UI.style(Color(1, 1, 1, 0.85), Color.TRANSPARENT, 3, 0, 0))
		trail.add_theme_stylebox_override("background", UI.style(Color(0, 0, 0, 0.7), Color(0, 0, 0, 0.9), 3, 1, 0))
		add_child(trail)
		hp_bar = UI.bar(1, 1, "EnemyHpBar" if is_enemy else "HpBar", 9)
		hp_bar.size = Vector2(sz.x * 0.7, 9)
		hp_bar.position = Vector2(sz.x * 0.15, sz.y + 2)
		hp_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
		add_child(hp_bar)
		status_row = HBoxContainer.new()
		status_row.add_theme_constant_override("separation", 2)
		status_row.position = Vector2(sz.x * 0.15, sz.y + 13)
		status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(status_row)
	arrow = UI.label("▼", 22, UI.GOLD, 5)
	arrow.size = Vector2(sz.x, 24)
	arrow.position = Vector2(0, -6)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.visible = false
	add_child(arrow)
	var at := arrow.create_tween().set_loops()
	at.tween_property(arrow, "position:y", -16.0, 0.35).set_trans(Tween.TRANS_SINE)
	at.tween_property(arrow, "position:y", -6.0, 0.35).set_trans(Tween.TRANS_SINE)

	if order >= 0:
		var bp := Panel.new()
		bp.add_theme_stylebox_override("panel", UI.style(Color("#ff5c6c") if is_enemy else UI.GOLD, Color(0, 0, 0, 0.8), 13, 2, 0))
		bp.size = Vector2(26, 26)
		bp.position = Vector2(4 if not is_enemy else sz.x - 30, sz.y * 0.62)
		bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bp)
		badge = UI.label(str(order + 1), 15, Color("#1a0d00") if not is_enemy else Color.WHITE)
		badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bp.add_child(badge)

	status_label = UI.label("", 13, Color("#ffd479"), 4)
	status_label.size = Vector2(sz.x, 18)
	status_label.position = Vector2(0, sz.y * 0.05)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

func start_idle() -> void:
	if _idle:
		_idle.kill()
	_idle = sprite.create_tween().set_loops()
	var d := randf_range(0.9, 1.2)
	_idle.tween_property(sprite, "scale", Vector2(1.02, 0.975), d).set_trans(Tween.TRANS_SINE)
	_idle.tween_property(sprite, "scale", Vector2(0.99, 1.02), d).set_trans(Tween.TRANS_SINE)

func set_hp(v: int, mx: int) -> void:
	if hp_bar:
		hp_bar.max_value = mx
		trail.max_value = mx
		var tw := hp_bar.create_tween()
		tw.tween_property(hp_bar, "value", float(v), 0.2)
		var tt := trail.create_tween()
		if float(v) >= trail.value:
			trail.value = v
		else:
			tt.tween_interval(0.35)
			tt.tween_property(trail, "value", float(v), 0.45).set_trans(Tween.TRANS_QUAD)

func snap_hp(v: int) -> void:
	if hp_bar:
		hp_bar.value = v
		trail.value = v

func add_status(kind: String) -> void:
	if not statuses.has(kind) and STATUS_STYLE.has(kind):
		statuses.append(kind)
		_draw_status()

func remove_status(kind: String) -> void:
	if statuses.has(kind):
		statuses.erase(kind)
		_draw_status()

func _draw_status() -> void:
	if status_row == null:
		return
	for c in status_row.get_children():
		c.queue_free()
	for k in statuses:
		var st: Array = STATUS_STYLE[k]
		var p := Panel.new()
		p.custom_minimum_size = Vector2(16, 16)
		p.add_theme_stylebox_override("panel", UI.style(st[1], Color(0, 0, 0, 0.8), 8, 1, 0))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := UI.label(st[0], 10, Color("#1a0d00"))
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		status_row.add_child(p)
		p.pivot_offset = Vector2(8, 8)
		p.scale = Vector2(0.2, 0.2)
		p.create_tween().tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func flash(color: Color = Color(3, 3, 3)) -> void:
	var tw := sprite.create_tween()
	sprite.self_modulate = color
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.25)

func revive_anim() -> void:
	if has_meta("dead"):
		remove_meta("dead")
	if sprite.material is ShaderMaterial and str((sprite.material as ShaderMaterial).shader.resource_path).ends_with("dissolve.gdshader"):
		sprite.material = null
	if hp_bar:
		hp_bar.modulate.a = 1.0
	if trail:
		trail.modulate.a = 1.0
	modulate = Color.WHITE
	modulate.a = 0.0
	sprite.rotation = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.4)
	start_idle()

## Burn-away dissolve in the killer's element colour (falls back to a fade with Reduce Effects).
func die(edge: Color = Color(1.0, 0.55, 0.2)) -> void:
	set_meta("dead", true)
	if _idle:
		_idle.kill()
	arrow.visible = false
	statuses.clear()
	_draw_status()
	if Game.reduce_fx():
		var ft := create_tween()
		ft.tween_property(self, "modulate:a", 0.0, 0.5)
		return
	var m := ShaderMaterial.new()
	m.shader = load("res://game/ui/dissolve.gdshader")
	m.set_shader_parameter("edge_color", edge)
	sprite.material = m
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(x: float): m.set_shader_parameter("progress", x), 0.0, 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "position:y", sprite.position.y - size.y * 0.06, 0.9)
	if hp_bar:
		tw.tween_property(hp_bar, "modulate:a", 0.0, 0.3)
	if trail:
		tw.tween_property(trail, "modulate:a", 0.0, 0.3)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.1)

## Anticipation before an attack: quick crouch (squash) then spring.
func wind_up(dur: float = 0.12) -> void:
	var tw := sprite.create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.08, 0.88), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", Vector2(0.95, 1.07), dur * 0.7).set_trans(Tween.TRANS_BACK)
