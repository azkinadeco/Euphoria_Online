class_name CompanionCameo
extends Control
## The tamed Companion as a small bobbing chibi with a name tag.
## interactive = true (lobby): tap → she says a line; tapping uses a daily head-pat (+Bond).

signal said(text: String)

var pet_id := ""
var interactive := false
var _spr: TextureRect
var _t := 0.0

func _init(id: String, can_touch: bool = false) -> void:
	pet_id = id
	interactive = can_touch
	mouse_filter = Control.MOUSE_FILTER_STOP if can_touch else Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	var sh := Panel.new()
	sh.add_theme_stylebox_override("panel", UI.style(Color(0, 0, 0, 0.35), Color.TRANSPARENT, 40, 0, 0))
	sh.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sh.offset_top = -26
	sh.offset_bottom = -12
	sh.offset_left = 18
	sh.offset_right = -18
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sh)
	_spr = UI.tex_rect(DB.sprite(pet_id, 1))
	_spr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spr.offset_bottom = -18
	_spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_spr)
	_spr.resized.connect(func(): _spr.pivot_offset = Vector2(_spr.size.x * 0.5, _spr.size.y))
	var tag := UI.label("★ " + DB.name_of(pet_id), 11, Color("#ffb8d6"), 4)
	tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tag.offset_top = -18
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)
	if interactive:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gui_input.connect(_on_input)

func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_spr):
		_spr.position.y = -absf(sin(_t * 2.2)) * 6.0
		_spr.scale = Vector2(1.0 + sin(_t * 4.4) * 0.015, 1.0 - sin(_t * 4.4) * 0.015)

## Small celebratory hop (battle start / victory).
func cheer() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - 26, 0.14).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position:y", position.y, 0.3).set_trans(Tween.TRANS_BOUNCE)

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	cheer()
	var line := DB.pet_line(pet_id, 1 + randi() % 3)
	if Game.pet_pat(pet_id):
		Game.sfx("star_up")
		line = DB.pet_line(pet_id, 3)
		var h := UI.label("♥", 30, Color("#ff8fb8"), 6)
		h.position = Vector2(size.x * 0.4, 0)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h)
		var ht := h.create_tween().set_parallel(true)
		ht.tween_property(h, "position:y", -60.0, 0.9)
		ht.tween_property(h, "modulate:a", 0.0, 0.5).set_delay(0.4)
		ht.chain().tween_callback(h.queue_free)
	else:
		Game.sfx("ui_click")
	said.emit(line)
