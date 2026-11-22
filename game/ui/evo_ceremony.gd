extends Control
## Full-screen moment when a hero enters a new Evolution tier (Azure / Crimson / Violet / Abyss):
## dark veil, the hero's art lit in the tier colour, light rings bursting out, the tier name and its six
## stars lighting up one by one (Abyss: black stars with the black-flame aura). Tap to close.
## main.overlay.add_child(EvoCeremony.new(id, tier)). Preloaded, no class_name.

signal finished

var hero_id := ""
var tier := 1
var _t := 0.0
var _col := Color.WHITE
var _done := false

func _init(id: String = "", evo_tier: int = 1) -> void:
	hero_id = id
	tier = clampi(evo_tier, 1, DB.MAX_EVO)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("popup", true)
	set_meta("no_back", true)
	_col = DB.evo_color(tier) if tier < DB.MAX_EVO else Color("#9b4dff")
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.0, 0.03, 0.92)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var rings := Control.new()
	rings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rings.draw.connect(func():
		var c := rings.size * Vector2(0.5, 0.45)
		for i in 4:
			var ph := fmod(_t * 0.55 + i * 0.25, 1.0)
			rings.draw_arc(c, 60.0 + ph * rings.size.x * 0.55, 0, TAU, 72, Color(_col, (1.0 - ph) * 0.55), 3.0 + 6.0 * (1.0 - ph), true)
		for i in 14:
			var a := TAU * i / 14.0 + _t * 0.3
			var r0 := 90.0
			var r1 := r0 + rings.size.y * (0.35 + 0.1 * sin(_t * 2.0 + i))
			rings.draw_line(c + Vector2(cos(a), sin(a)) * r0, c + Vector2(cos(a), sin(a)) * r1, Color(_col, 0.12), 6.0))
	rings.set_process(true)
	add_child(rings)
	var art := UI.tex_rect(DB.art(hero_id, int(Game.hero(hero_id).get("skin", 0))))
	art.anchor_left = 0.25
	art.anchor_right = 0.75
	art.anchor_top = 0.05
	art.anchor_bottom = 0.78
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(_col.r * 0.6 + 0.6, _col.g * 0.6 + 0.6, _col.b * 0.6 + 0.6, 0.0)
	add_child(art)
	var tw := art.create_tween()
	tw.tween_property(art, "modulate:a", 1.0, 0.6)
	tw.parallel().tween_property(art, "scale", Vector2.ONE, 0.9).from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	art.resized.connect(func(): art.pivot_offset = art.size * 0.5)
	var title := UI.label("%s EVOLUTION" % DB.evo_name(tier).to_upper(), 40, _col.lightened(0.35), 8)
	title.add_theme_color_override("font_outline_color", _col.darkened(0.7))
	title.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	title.anchor_top = 0.78
	title.anchor_bottom = 0.78
	title.offset_left = -400
	title.offset_right = 400
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate.a = 0.0
	add_child(title)
	var tt := title.create_tween()
	tt.tween_interval(0.5)
	tt.tween_property(title, "modulate:a", 1.0, 0.35)
	var sub := UI.label("%s  •  every Evolution star +%s%% HP / ATK / DEF" % [DB.name_of(hero_id), str(DB.EVO_STEP_STAT * 100)], 16, Color.WHITE, 4)
	sub.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sub.anchor_top = 0.86
	sub.anchor_bottom = 0.86
	sub.offset_left = -400
	sub.offset_right = 400
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	# the six stars of the new tier light up one after another (first one filled = Evo star 1)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.anchor_top = 0.71
	row.anchor_bottom = 0.71
	row.offset_left = -300
	row.offset_right = 300
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for i in DB.EVO_STARS:
		var st := UI.rank_stars(DB.MAX_STAR, tier, 1 if i == 0 else 0, 34, true) if i == 0 else UI.label("☆", 34, Color(_col, 0.55), 4)
		st.modulate.a = 0.0
		row.add_child(st)
		var sw := st.create_tween()
		sw.tween_interval(0.9 + i * 0.12)
		sw.tween_property(st, "modulate:a", 1.0, 0.2)
	var hint := UI.label("tap to continue", 13, UI.MUTED, 2)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -40
	hint.offset_left = -200
	hint.offset_right = 200
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	Game.sfx("awakening")
	Game.voice(hero_id, "bond")

func _process(delta: float) -> void:
	_t += delta
	for c in get_children():
		if c is Control and c.draw.get_connections().size() > 0:
			c.queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and _t > 0.8 and not _done:
		_done = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func():
			finished.emit()
			queue_free())
