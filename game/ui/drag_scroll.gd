class_name DragScroll
extends ScrollContainer
## Phone-gallery style scrolling: drag ANYWHERE inside the list (even on buttons and cards)
## and it scrolls, with momentum after release. A small tap still presses buttons normally.
##
## How it works: input is watched in _input (before the GUI). Once the finger moves past
## DRAG_START px along the scroll axis, every button under the finger is reset (so its
## press is cancelled and it will NOT fire on release), and from then on motion scrolls the list.
## DRAG_START is below Godot's drag-and-drop threshold (10 px) so scrolling wins on the scroll
## axis, while drags on the other axis (e.g. pulling a hero card onto the board) still work.

const DRAG_START := 8.0
const FRICTION := 5.0          # momentum decay per second
var _down := false
var _dragging := false
var _start := Vector2.ZERO
var _vel := Vector2.ZERO
var _last_t := 0

func _ready() -> void:
	set_process(false)

func _vertical() -> bool:
	return vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED

func _horizontal() -> bool:
	return horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED

## Ignore presses when a popup/dialogue that does not contain this list is on top.
func _blocked() -> bool:
	var main := get_tree().root.get_node_or_null("Main")
	if main == null or not ("overlay" in main):
		return false
	var ov: Control = main.overlay
	for i in range(ov.get_child_count() - 1, -1, -1):
		var c := ov.get_child(i)
		if c is Control and (c as Control).visible and (c.has_meta("popup") or c.has_method("_show_log")):
			return not c.is_ancestor_of(self)
	return false

func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			if get_global_rect().has_point(e.position) and not _blocked():
				_down = true
				_dragging = false
				_start = e.position
				_vel = Vector2.ZERO
				set_process(false)
		else:
			# the release always reaches the GUI (keeps Godot's mouse focus consistent);
			# buttons were already reset when the drag began, so nothing fires
			if _dragging:
				set_process(_vel.length() > 30.0)
			_down = false
			_dragging = false
	elif e is InputEventMouseMotion and _down:
		var d: Vector2 = e.position - _start
		if not _dragging:
			var along_v := _vertical() and absf(d.y) > DRAG_START and absf(d.y) >= absf(d.x)
			var along_h := _horizontal() and absf(d.x) > DRAG_START and absf(d.x) > absf(d.y)
			if not (along_v or along_h):
				if absf(d.x) > DRAG_START * 2.0 or absf(d.y) > DRAG_START * 2.0:
					_down = false     # wrong-axis drag (e.g. drag & drop a hero) — leave it alone
				return
			_dragging = true
			_last_t = Time.get_ticks_msec()
			_cancel_presses(_start)
		var r: Vector2 = e.relative
		if _vertical():
			scroll_vertical -= int(r.y)
		if _horizontal():
			scroll_horizontal -= int(r.x)
		var now := Time.get_ticks_msec()
		var dt := maxf(0.001, float(now - _last_t) / 1000.0)
		_last_t = now
		_vel = _vel.lerp(r / dt, 0.4)
		get_viewport().set_input_as_handled()

## Reset every button under the finger: toggling `disabled` clears BaseButton's
## press_attempt / pressing_inside state, so the coming release does not trigger it.
func _cancel_presses(at: Vector2) -> void:
	for b in find_children("*", "BaseButton", true, false):
		var btn := b as BaseButton
		if btn.is_visible_in_tree() and btn.get_global_rect().has_point(at):
			var was := btn.disabled
			btn.disabled = true
			btn.disabled = was

## Momentum after release.
func _process(delta: float) -> void:
	if _down:
		return
	_vel = _vel * maxf(0.0, 1.0 - FRICTION * delta)
	if _vertical():
		scroll_vertical -= int(_vel.y * delta)
	if _horizontal():
		scroll_horizontal -= int(_vel.x * delta)
	if _vel.length() < 20.0:
		set_process(false)
