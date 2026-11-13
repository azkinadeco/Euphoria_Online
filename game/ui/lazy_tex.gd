extends Node
## Fills its parent TextureRect a moment after the screen appears, instead of freezing the screen open
## while every full-body art loads (face crops / thumbnails need the whole art). All pending fills share
## one ~8 ms budget per frame (at least one per frame), in tree order = roughly display order. The texture
## is exactly the one the caller would have set; it just fades in over 0.18 s.
## Use through UI.tex_rect_lazy() / UI.face_rect(). Not a class_name (headless runs need no import).

const BUDGET_US := 8000
static var _frame := -1
static var _used := 0

var loader: Callable

func _process(_d: float) -> void:
	var f := Engine.get_process_frames()
	if f != _frame:
		_frame = f
		_used = 0
	elif _used > BUDGET_US:
		return
	var t0 := Time.get_ticks_usec()
	var tr := get_parent() as TextureRect
	if tr:
		tr.texture = loader.call()
		var a := tr.modulate.a
		tr.modulate.a = 0.0
		tr.create_tween().tween_property(tr, "modulate:a", a, 0.18)
	_used += Time.get_ticks_usec() - t0
	queue_free()
