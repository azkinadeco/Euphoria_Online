class_name PinchZoom
extends Node
## Two-finger pinch detector. Add as a child of any Control; it reads raw touch
## events (works on phones and the web build) and calls on_zoom(factor, centre)
## while two fingers move apart / together. Ctrl+wheel and trackpad pinch also work.
## active() is true while two fingers are down, so the owner can ignore taps/drags then.

var on_zoom: Callable
var _touches: Dictionary = {}   # index -> position
var _last_dist := 0.0
var _was_pinch_t := 0

func _init(cb: Callable) -> void:
	on_zoom = cb

func active() -> bool:
	return _touches.size() >= 2 or Time.get_ticks_msec() - _was_pinch_t < 250

func _input(e: InputEvent) -> void:
	var owner_c := get_parent() as Control
	if owner_c == null or not owner_c.is_visible_in_tree():
		return
	if e is InputEventScreenTouch:
		if e.pressed and owner_c.get_global_rect().has_point(e.position):
			_touches[e.index] = e.position
		else:
			_touches.erase(e.index)
		_last_dist = _dist()
	elif e is InputEventScreenDrag and _touches.has(e.index):
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var d := _dist()
			if _last_dist > 10.0 and d > 10.0:
				on_zoom.call(d / _last_dist, _centre())
			_last_dist = d
			_was_pinch_t = Time.get_ticks_msec()
			get_viewport().set_input_as_handled()
	elif e is InputEventMagnifyGesture and owner_c.get_global_rect().has_point(e.position):
		on_zoom.call(e.factor, e.position)
		_was_pinch_t = Time.get_ticks_msec()
	elif e is InputEventMouseButton and e.pressed and e.ctrl_pressed and owner_c.get_global_rect().has_point(e.position):
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			on_zoom.call(1.1, e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			on_zoom.call(1.0 / 1.1, e.position)

func _dist() -> float:
	var p: Array = _touches.values()
	return (p[0] as Vector2).distance_to(p[1]) if p.size() >= 2 else 0.0

func _centre() -> Vector2:
	var p: Array = _touches.values()
	return ((p[0] as Vector2) + (p[1] as Vector2)) * 0.5 if p.size() >= 2 else Vector2.ZERO
