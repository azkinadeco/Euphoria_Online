extends Screen
## CG Gallery: every outfit art of every hero. Unlocked ones open a
## full-screen viewer with zoom (wheel / pinch / buttons) and drag-to-pan.

var _list: VBoxContainer
var _count: Label
var _entries: Array = []   # current hero album: {id, idx, unlocked}
var _album: Control
var _viewer: Control
var _view_tex: TextureRect
var _view_i := 0
var _zoom := 1.0
var _drag := false
var _pinch: PinchZoom

## One light card per hero (portrait only), grouped by tier SSR → SR → R.
## Tapping a hero opens her album with every outfit / evolution; unlocked ones open the viewer.
func build() -> void:
	set_bg("lobby", 0.72)
	ambient(Color(1.0, 0.85, 1.0), 25)
	var bar := header("GALLERY", [])
	_count = UI.label("", 16, UI.GOLD, 3)
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_count)
	var b := body(76)
	_list = UI.vbox(10)
	var sc := UI.scroll(UI.margin(_list, 4, 4, 4, 4))
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(sc)
	var total := 0
	var open := 0
	for id in DB.hero_ids():
		var n := DB.art_list(id).size()
		total += n
		open += _unlocked_count(id)
	_count.text = "  %d / %d unlocked" % [open, total]
	for tier in ["SSR", "SR", "R"]:
		var ids: Array = DB.hero_ids().filter(func(h): return DB.rarity_of(h) == tier)
		if ids.is_empty():
			continue
		var hd := UI.hbox(8)
		hd.add_child(UI.rarity_tag(tier, 18))
		hd.add_child(UI.label("%s HEROES  •  %d" % [tier, ids.size()], 16, DB.RARITY_COLOR[tier], 3))
		_list.add_child(hd)
		var g := GridContainer.new()
		g.columns = 6
		g.add_theme_constant_override("h_separation", 12)
		g.add_theme_constant_override("v_separation", 12)
		_list.add_child(g)
		sc.resized.connect(func(): g.columns = clampi(int((sc.size.x - 12) / 176.0), 3, 6))
		for id in ids:
			g.add_child(_hero_card(id))
	UI.stagger(_list, 0.02, 20)

func _unlocked_count(id: String) -> int:
	if not Game.owns(id):
		return 0
	var c := 0
	for i in DB.art_list(id).size():
		if Game.skin_unlocked(id, i):
			c += 1
	return c

func _hero_card(id: String) -> Control:
	var owned := Game.owns(id)
	var n := DB.art_list(id).size()
	var un := _unlocked_count(id)
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(164, 214)
	var fr := Panel.new()
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rc: Color = DB.RARITY_COLOR[DB.rarity_of(id)]
	fr.add_theme_stylebox_override("panel", UI.style(Color(0.04, 0.03, 0.08, 1.0), rc if owned else Color("#3a2f55"), 10, 2, 0))
	fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(fr)
	var t := UI.tex_rect(DB.portrait(id), Vector2.ZERO, true)
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.offset_bottom = -40
	if not owned:
		t.modulate = Color(0.08, 0.07, 0.12)
	fr.add_child(t)
	var cap := UI.vbox(0)
	cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cap.offset_top = -40
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.add_child(cap)
	var nm := UI.label(DB.name_of(id) if owned else "???", 14, Color.WHITE, 3)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(nm)
	var cl := UI.label("%d / %d outfits" % [un, n], 11, UI.GREEN if un == n and n > 0 else UI.MUTED, 2)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(cl)
	# progress bar
	var pb := ColorRect.new()
	pb.color = rc
	pb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pb.offset_top = -3
	pb.offset_right = 164.0 * (float(un) / maxf(1.0, float(n)))
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.add_child(pb)
	UI.hover_fx(b, 1.04)
	b.pressed.connect(func():
		Game.sfx("ui_click")
		_open_album(id))
	return b

func _close_viewer() -> void:
	var id: String = _entries[_view_i]["id"] if not _entries.is_empty() else ""
	if is_instance_valid(_viewer):
		_viewer.queue_free()
	if id != "":
		_open_album(id)

# ---------------------------------------------------------------- album

func _open_album(id: String) -> void:
	_entries.clear()
	var arts := DB.art_list(id)
	for i in arts.size():
		_entries.append({"id": id, "idx": i, "unlocked": Game.owns(id) and Game.skin_unlocked(id, i)})
	var v: VBoxContainer = main.popup("%s  •  ALBUM" % DB.name_of(id).to_upper(), 1080)
	_album = v
	v.add_child(UI.label("%s  —  %d / %d unlocked. Tap an outfit to view it full-screen (pinch to zoom)." % [DB.title_of(id), _unlocked_count(id), arts.size()], 13, UI.MUTED, 2))
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	var sc := UI.scroll(g)
	sc.custom_minimum_size = Vector2(0, 470)
	v.add_child(sc)
	for k in _entries.size():
		g.add_child(_thumb(k))
	UI.stagger(g, 0.03)

func _thumb(k: int) -> Control:
	var e: Dictionary = _entries[k]
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(186, 236)
	var fr := Panel.new()
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fr.add_theme_stylebox_override("panel", UI.style(Color(0.04, 0.03, 0.08, 1.0), UI.GOLD if e["unlocked"] else Color("#3a2f55"), 10, 2, 0))
	fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(fr)
	var t := UI.tex_rect(DB.art(e["id"], e["idx"]), Vector2.ZERO, false)
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.offset_bottom = -24
	fr.add_child(t)
	var label := _outfit_label(e["id"], e["idx"])
	var cap := UI.label(label, 12, Color.WHITE, 4)
	cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cap.offset_top = -22
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fr.add_child(cap)
	if e["unlocked"]:
		UI.hover_fx(b, 1.05)
		b.pressed.connect(func(): Game.sfx("ui_click"); _open(k))
	else:
		t.modulate = Color(0.05, 0.05, 0.08)
		var lk := UI.label("🔒", 40, Color(1, 1, 1, 0.35), 0)
		lk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fr.add_child(lk)
		if Game.owns(e["id"]):
			cap.text = Game.skin_lock_label(e["id"], e["idx"])
			cap.add_theme_font_size_override("font_size", 11)
	return b

## "Stage 2", "Evolution 1", "Special Skin" from the outfit index.
func _outfit_label(id: String, idx: int) -> String:
	if idx == DB.special_index(id):
		return "✦ " + str(DB.SPECIAL_SKINS.get(id, "Special Skin"))
	var p: String = DB.art_list(id)[idx]
	var b := p.get_file().get_basename()
	var m := RegEx.create_from_string("(stage|evo)(\\d+)").search(b)
	if m:
		return ("Stage %s" if m.get_string(1) == "stage" else "Evolution %s") % m.get_string(2)
	return "Outfit %d" % (idx + 1)

# ---------------------------------------------------------------- viewer

func on_back() -> bool:
	if is_instance_valid(_viewer):
		_close_viewer()
		return true
	return false

func _open(k: int) -> void:
	_view_i = k
	if is_instance_valid(_album):
		main.close_popup(_album)
	_viewer = Control.new()
	_viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewer.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewer.clip_contents = true
	add_child(_viewer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(bg)
	_view_tex = UI.tex_rect(null)
	_view_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewer.add_child(_view_tex)
	UI.live(_view_tex, Color(1, 0.9, 1), 0.6)
	_viewer.gui_input.connect(_viewer_input)
	_viewer.z_index = 50
	_pinch = PinchZoom.new(func(f: float, _c: Vector2): _set_zoom(_zoom * f))
	_viewer.add_child(_pinch)
	var bar := UI.hbox(10)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -70
	bar.offset_bottom = -14
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_viewer.add_child(bar)
	bar.add_child(UI.button("◀", func(): _step(-1), "", Vector2(64, 50)))
	bar.add_child(UI.button("−", func(): _set_zoom(_zoom / 1.3), "", Vector2(56, 50)))
	bar.add_child(UI.button("RESET", func(): _set_zoom(1.0, true), "", Vector2(100, 50)))
	bar.add_child(UI.button("+", func(): _set_zoom(_zoom * 1.3), "", Vector2(56, 50)))
	bar.add_child(UI.button("▶", func(): _step(1), "", Vector2(64, 50)))
	bar.add_child(UI.button("♥ LOBBY", func():
		var e: Dictionary = _entries[_view_i]
		Game.s["lobby_hero"] = e["id"]
		Game.set_skin(e["id"], e["idx"])
		main.toast("%s (outfit %d) is now in your lobby!" % [DB.name_of(e["id"]), e["idx"] + 1], Color("#ff8fb8")), "GoldButton", Vector2(140, 50)))
	bar.add_child(UI.button("CLOSE", _close_viewer, "", Vector2(110, 50)))
	_show()

func _show() -> void:
	var e: Dictionary = _entries[_view_i]
	_view_tex.texture = DB.art(e["id"], e["idx"])
	_set_zoom(1.0, true)
	_view_tex.modulate.a = 0.0
	_view_tex.create_tween().tween_property(_view_tex, "modulate:a", 1.0, 0.25)

func _step(d: int) -> void:
	var n := _entries.size()
	for i in n:
		_view_i = (_view_i + d + n) % n
		if _entries[_view_i]["unlocked"]:
			break
	_show()

func _base_rect() -> Rect2:
	var vs := _viewer.size
	var ts := _view_tex.texture.get_size() if _view_tex.texture else Vector2(1, 1)
	var sc := minf(vs.x / ts.x, (vs.y - 80) / ts.y)
	var sz := ts * sc
	return Rect2((vs - sz) * 0.5 - Vector2(0, 30), sz)

func _set_zoom(z: float, center: bool = false) -> void:
	var old := _zoom
	_zoom = clampf(z, 1.0, 4.0)
	var base := _base_rect()
	var new_size := base.size * _zoom
	if center or _zoom <= 1.0:
		_view_tex.size = new_size
		_view_tex.position = base.position - (new_size - base.size) * 0.5
	else:
		var mid := _viewer.size * 0.5
		var rel := (mid - _view_tex.position) / maxf(old, 0.01)
		_view_tex.size = new_size
		_view_tex.position = mid - rel * _zoom

func _viewer_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_set_zoom(_zoom * 1.12)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_set_zoom(_zoom / 1.12)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			_drag = e.pressed
			if e.double_click:
				_set_zoom(1.0 if _zoom > 1.5 else 2.2)
	elif e is InputEventMouseMotion and _drag and _zoom > 1.0 and not _pinch.active():
		_view_tex.position += e.relative
	elif e is InputEventMagnifyGesture:
		_set_zoom(_zoom * e.factor)
	elif e is InputEventPanGesture:
		_view_tex.position -= e.delta * 8.0
