extends Control
## Studio logo intro (ONIX Studio), shown once when the game starts: after the download and the engine's
## boot splash (which shows the same picture, so there is no jump), before the title screen.
## The logo fades in with a short opening sound (audio/ui/studio_open.wav), a band of light crosses it,
## then it fades to the title. Tap to skip.

const BG := Color(9.0 / 255.0, 9.0 / 255.0, 13.0 / 255.0)   # the flat colour the logo picture is built on
signal finished

var _done := false
var _age := 0.0

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# same framing as the boot splash: the whole 16:9 picture fitted inside the window
	var logo := TextureRect.new()
	logo.texture = load("res://art/brand/onix_intro.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	var m := ShaderMaterial.new()
	m.shader = load("res://game/ui/studio_intro.gdshader")
	logo.material = m
	var calm: bool = Game.reduce_fx()
	logo.resized.connect(func(): logo.pivot_offset = logo.size * 0.5)
	logo.pivot_offset = get_viewport_rect().size * 0.5
	# web: the logo appears after the "tap to enter" (fades in). Desktop: the boot splash already shows the
	# same picture, so it is simply there.
	logo.modulate.a = 0.0 if OS.has_feature("web") else 1.0
	# On the web the logo waits for the "tap to enter" on the download page: that tap is what lets the
	# browser play sound and go full screen, and nothing should happen behind the loading screen.
	if OS.has_feature("web"):
		while not _web_entered():
			await get_tree().process_frame
	var tw := create_tween()
	tw.tween_property(logo, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_callback(func(): Game.sfx("ui/studio_open"))
	tw.tween_interval(0.05)
	if not calm:
		tw.tween_method(func(v: float): m.set_shader_parameter("sweep", v), -0.3, 1.3, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(logo, "scale", Vector2(1.035, 1.035), 1.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.9)
	else:
		tw.tween_interval(1.6)
	tw.tween_callback(_finish)

func _web_entered() -> bool:
	return bool(JavaScriptBridge.eval("!!window.__eoEntered", true))

func _process(delta: float) -> void:
	_age += delta

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _age > 0.3:
		_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		finished.emit()
		queue_free())
