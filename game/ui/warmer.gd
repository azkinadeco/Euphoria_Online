extends Node
## Background warm-up: runs one job per frame while the player is not touching the screen, so the next
## screen's heavy textures are already loaded when it opens. `source` returns [[key, Callable], ...]; it is
## re-read every frame (the list may change, e.g. the team being edited) and each key runs only once.

var source: Callable
var delay := 0.5
var _done := {}

func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	if Input.is_anything_pressed():
		return
	for job in source.call():
		if not _done.has(job[0]):
			_done[job[0]] = true
			(job[1] as Callable).call()
			return
	set_process(false)
	# the list can grow later (team edited): look again now and then
	get_tree().create_timer(0.5, false).timeout.connect(func():
		if is_inside_tree():
			set_process(true))
