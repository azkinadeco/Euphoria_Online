class_name Screen
extends Control
## Base class for every full-page screen. The router (Main) instantiates a
## screen, assigns `main` + `params`, then calls build().

var main: Node          # game/main.gd
var params: Dictionary = {}
var _chips: Array = []
# header parts, kept so the bar can tighten itself when the screen is too narrow (_fit_header)
var _hdr_bar: HBoxContainer
var _hdr_title: Label
var _hdr_icon: Control
var _hdr_nav: Array = []
var _hdr_level := 0

func build() -> void:
	pass

func _ready() -> void:
	# Safety net for big UI sizes / short windows (see _fit_scan). It used to walk the whole screen every
	# 0.3 s for as long as the screen was open (a hitch you could see on busy screens); now it checks a few
	# times while the screen settles, and again after a resize.
	resized.connect(func():
		_hdr_level = 0
		_hdr_apply()
		_fit_header()
		_fit_soon())
	_fit_soon()
	_fit_header.call_deferred()

## Header + tall-panel check at 0.12 s (after the first layout; wrapping labels report a huge height
## before it), 0.5 s and 1.2 s (late content: lazy pictures, staggered rows).
func _fit_soon() -> void:
	if not is_inside_tree():
		return
	for d in [0.12, 0.5, 1.2]:
		# owned by the screen: it can never fire after the screen is gone
		var t := Timer.new()
		t.one_shot = true
		t.wait_time = d
		t.timeout.connect(func():
			_fit_header()
			_fit_scan(self, 0)
			t.queue_free())
		add_child(t)
		t.start()

## Called by Main when Game.changed fires while this screen is visible.
func refresh() -> void:
	_update_chips()

func on_back() -> bool:
	## Return true to consume the back action (e.g. close an inner panel).
	return false

# ----------------------------------------------------------------- helpers

var bg_rect: TextureRect   # the backdrop picture (LiveRig can slide it for depth)

func set_bg(key: String, dim: float = 0.45) -> void:
	var t := UI.tex_rect(DB.bg(key), Vector2.ZERO, true)
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(t)
	move_child(t, 0)
	bg_rect = t
	var d := ColorRect.new()
	d.color = Color(0.02, 0.01, 0.06, dim)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(d)
	move_child(d, 1)
	# soft vignette: darker edges keep focus on the content
	var vg := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0.01, 0.0, 0.03, 0.55))
	g.add_point(0.55, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	vg.texture = gt
	vg.stretch_mode = TextureRect.STRETCH_SCALE
	vg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vg)
	move_child(vg, 2)

## Shows the first-visit tutorial for `key` once per save.
func tutorial(key: String) -> bool:
	if not DB.TUTORIALS.has(key):
		return false
	var seen: Array = Game.s.get("tips_seen", [])
	if seen.has(key):
		return false
	seen.append(key)
	Game.s["tips_seen"] = seen
	Game.mark_dirty()
	(func(): main.dialogue(DB.TUTORIALS[key], Callable(), "", true)).call_deferred()
	return true

## Decorative floating motes above the background.
func ambient(col: Color = Color(1.0, 0.8, 1.0), n: int = 36) -> void:
	var a := AmbientFX.new(col, n)
	add_child(a)
	move_child(a, mini(2, get_child_count() - 1))

## Standard header: back button, title, currency chips. Returns the bar so
## screens can append extra controls.
const HEADER_ICONS := {"HEROES": "icon_codex", "HERO": "icon_codex", "FORMATION": "icon_formation", "BATTLE PREP": "icon_formation",
	"STORY": "icon_story", "SUMMON": "icon_gacha", "SHOP": "icon_shop", "BAG": "icon_bag", "MISSIONS": "icon_quest", "MAILBOX": "icon_mail",
	"ARENA": "icon_arena", "TOWER OF TRIALS": "icon_tower", "SETTINGS": "icon_settings", "EVENT": "icon_live_ops", "GUILD": "icon_guild",
	"FRIENDS": "icon_friends", "DAILY DUNGEON": "icon_dungeon", "SEASON PASS": "icon_pass", "GARDEN": "icon_heart", "GALLERY": "icon_codex",
	"EXPEDITION": "icon_afk", "HEART CATCH": "icon_heart", "CODEX": "icon_codex", "WORLD BOSS": "icon_boss", "FESTIVAL": "icon_festival", "BOSS HUNT": "icon_combat_target", "STARLIGHT RIFT": "icon_awakening", "PRIVATE ROOM": "icon_heart", "BESTIARY": "icon_boss", "DATE": "icon_heart", "WARDROBE": "item_skin_ticket"}

func header(title: String, chips: Array = ["gold", "gems", "energy"]) -> HBoxContainer:
	# decorative ribbon behind the header
	var rib := TextureRect.new()
	if ResourceLoader.exists("res://art/ui/header.png"):
		rib.texture = load("res://art/ui/header.png")
	else:
		var rg := Gradient.new()
		rg.set_color(0, Color(0.03, 0.01, 0.08, 0.92))
		rg.set_color(1, Color(0.03, 0.01, 0.08, 0.0))
		var rgt := GradientTexture2D.new()
		rgt.gradient = rg
		rgt.fill_from = Vector2(0, 0)
		rgt.fill_to = Vector2(0, 1)
		rib.texture = rgt
	rib.stretch_mode = TextureRect.STRETCH_SCALE
	rib.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rib.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rib.offset_bottom = 77
	rib.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rib)
	var line := ColorRect.new()
	line.color = Color(1.0, 0.83, 0.47, 0.0 if rib.texture is Texture2D and not (rib.texture is GradientTexture2D) else 0.35)
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = 66
	line.offset_bottom = 67
	line.offset_left = 16
	line.offset_right = -16
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	var bar := UI.hbox(10)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 16
	bar.offset_right = -16
	bar.offset_top = 10
	bar.offset_bottom = 62
	add_child(bar)
	var back := UI.button("◀", func(): main.back(), "", Vector2(56, 48))
	back.add_theme_font_size_override("font_size", 22)
	bar.add_child(back)
	_hdr_bar = bar
	_hdr_nav = [back]
	# HOME: jump straight back to the lobby from any feature screen
	var home := UI.button("", func():
		Game.sfx("ui_click")
		main.home(), "", Vector2(56, 48))
	home.icon = DB.icon("icon_home")
	home.expand_icon = true
	home.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home.add_theme_constant_override("icon_max_width", 30)
	home.tooltip_text = "Home"
	bar.add_child(home)
	_hdr_nav.append(home)
	if HEADER_ICONS.has(title):
		var hi := UI.tex_rect(DB.icon(HEADER_ICONS[title]), Vector2(40, 40))
		hi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_child(hi)
		_hdr_icon = hi
		var it := hi.create_tween().set_loops()
		it.tween_property(hi, "modulate", Color(1.25, 1.2, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
		it.tween_property(hi, "modulate", Color.WHITE, 1.2).set_trans(Tween.TRANS_SINE)
	var t := UI.label(title, 26, UI.GOLD, 6)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.size_flags_vertical = Control.SIZE_FILL
	bar.add_child(t)
	_hdr_title = t
	bar.add_child(UI.spacer())
	for k in chips:
		bar.add_child(_chip(k))
	_update_chips()
	if not Game.reduce_fx():
		_header_intro(t, line, bar)
	return bar

## One-shot header entrance: title pops in, gold rule grows from the centre, chips drop in one by one.
func _header_intro(title: Label, line: ColorRect, bar: HBoxContainer) -> void:
	title.modulate.a = 0.0
	title.resized.connect(func(): title.pivot_offset = Vector2(0, title.size.y * 0.5))
	title.scale = Vector2(0.86, 0.86)
	var tw := title.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title, "modulate:a", 1.0, 0.25).set_delay(0.08)
	tw.tween_property(title, "scale", Vector2.ONE, 0.35).set_delay(0.08)
	line.resized.connect(func(): line.pivot_offset = line.size * 0.5)
	line.scale.x = 0.0
	line.create_tween().tween_property(line, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.1)
	var i := 0
	for c in _chips:
		var lab: Label = c["label"]
		var chip := lab.get_parent().get_parent() as Control
		if chip == null or chip.get_parent() != bar:
			continue
		chip.modulate.a = 0.0
		chip.resized.connect(func(): chip.pivot_offset = chip.size * 0.5)
		chip.scale = Vector2(0.8, 0.8)
		var ct := chip.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ct.tween_property(chip, "modulate:a", 1.0, 0.2).set_delay(0.12 + 0.06 * i)
		ct.tween_property(chip, "scale", Vector2.ONE, 0.3).set_delay(0.12 + 0.06 * i)
		i += 1

## Chip feedback when a currency changes: bump + tint flash + a floating delta.
func _chip_pulse(c: Dictionary, delta: int) -> void:
	if Game.reduce_fx() or not is_inside_tree():
		return
	var lab: Label = c["label"]
	var chip := lab.get_parent().get_parent() as Control
	if chip == null:
		return
	var gain := delta > 0
	chip.pivot_offset = chip.size * 0.5
	var tw := chip.create_tween()
	tw.tween_property(chip, "scale", Vector2(1.1, 1.1), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(chip, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var flash := Color(1.35, 1.28, 0.95) if gain else Color(1.3, 0.72, 0.72)
	var mt := chip.create_tween()
	mt.tween_property(chip, "modulate", flash, 0.08)
	mt.tween_property(chip, "modulate", Color.WHITE, 0.4)
	var f := UI.label(("+" if gain else "-") + Game.fmt(absi(delta)), 15, Color("#9dffb0") if gain else Color("#ff8a8a"), 4)
	f.top_level = true
	f.z_index = 50
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(f)
	var start := chip.global_position + Vector2(chip.size.x * 0.5 - 20.0, chip.size.y - 2.0)
	f.global_position = start
	var ft := f.create_tween().set_parallel(true)
	ft.tween_property(f, "global_position:y", start.y + 18.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ft.tween_property(f, "modulate:a", 0.0, 0.5).set_delay(0.45)
	ft.chain().tween_callback(f.queue_free)

func _chip(key: String) -> Control:
	var p := UI.styled_panel(Color(0, 0, 0, 0.55), Color("#5b4790"), 22, 1, 8)
	p.custom_minimum_size = Vector2(150, 44)
	p.set_meta("hdr_chip", true)
	var h := UI.hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	h.add_child(UI.tex_rect(Game.reward_icon(key), Vector2(30, 30)))
	var l := UI.label("", 16, Color.WHITE, 3)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	_chips.append({"key": key, "label": l, "panel": p})
	if key in ["gems", "energy"]:
		var plus := UI.button("+", func(): main.go("shop"), "FlatButton", Vector2(26, 26))
		plus.add_theme_font_size_override("font_size", 18)
		plus.add_theme_color_override("font_color", UI.GOLD)
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE   # the whole chip is the button (the "+" alone was 26 px wide)
		h.add_child(plus)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		p.tooltip_text = "Open the Shop"
		p.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				Game.sfx("ui_click")
				main.go("shop"))
	return p

func _update_chips() -> void:
	for c in _chips:
		var k: String = c["key"]
		if not is_instance_valid(c["label"]):
			continue
		if k == "energy":
			c["label"].text = "%d/%d" % [Game.amount("energy"), Game.energy_max()]
		else:
			var nv := Game.amount(k)
			var ov: int = int(c.get("value", nv))
			c["value"] = nv
			if ov != nv and is_inside_tree():
				UI.count_to(c["label"], ov, nv, func(x: int) -> String: return Game.fmt(x))
				_chip_pulse(c, nv - ov)
			else:
				c["label"].text = Game.fmt(nv)

## A full-rect content area under the header.
func body(top: float = 72.0, pad: float = 16.0) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.offset_top = top
	c.offset_left = pad
	c.offset_right = -pad
	c.offset_bottom = -pad
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c

# ----------------------------------------------------------------- auto-fit
## A panel whose content is taller than the window would push its last rows (often the main button)
## off the screen: UI size X-LARGE, short browser windows. Such a panel gets a scroll area for its
## content while the action row at the bottom stays pinned and always reachable.
func _fit_scan(n: Node, depth: int) -> void:
	for ch in n.get_children():
		if not (ch is Control) or not (ch as Control).visible or ch is ScrollContainer:
			continue
		if ch is PanelContainer and _fit_panel(ch as PanelContainer):
			continue
		if depth < 5:
			_fit_scan(ch, depth + 1)

func _fit_panel(p: PanelContainer) -> bool:
	if p.get_child_count() != 1 or not (p.get_child(0) is VBoxContainer):
		return false
	var v := p.get_child(0) as VBoxContainer
	if v.get_child_count() > 0 and v.get_child(0).has_meta("autofit"):
		return true
	var top: float = p.global_position.y - global_position.y
	var need: float = p.get_combined_minimum_size().y
	if need < 220.0 or top + need <= size.y - 4.0 or top > size.y * 0.5 or p.size.x < 80.0:
		return false
	return UI.fit_tall(p, 0, -1.0)

## The header holds back, home, icon, title, the screen's own buttons and the currency chips. On a narrow
## window or a big UI size that row gets wider than the screen and its right end (often a button) is lost.
## Tighten it step by step until it fits: drop the icon, slim the chips, shrink the title, then trim it.
func _fit_header() -> void:
	if _hdr_bar == null or not is_instance_valid(_hdr_bar) or size.x < 100.0:
		return
	while _hdr_level < 4 and _hdr_bar.get_combined_minimum_size().x > size.x - 32.0 + 1.0:
		_hdr_level += 1
		_hdr_apply()

func _hdr_apply() -> void:
	if _hdr_bar == null or not is_instance_valid(_hdr_bar):
		return
	var lv := _hdr_level
	if _hdr_icon != null and is_instance_valid(_hdr_icon):
		_hdr_icon.visible = lv < 1
	for c in _chips:
		if c.has("panel") and is_instance_valid(c["panel"]):
			(c["panel"] as Control).custom_minimum_size.x = 150.0 if lv < 2 else 112.0
	_hdr_bar.add_theme_constant_override("separation", 10 if lv < 2 else 6)
	if _hdr_title != null and is_instance_valid(_hdr_title):
		_hdr_title.add_theme_font_size_override("font_size", 26 if lv < 3 else 20)
		_hdr_title.clip_text = lv >= 4
		_hdr_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if lv >= 4 else TextServer.OVERRUN_NO_TRIMMING
		_hdr_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL if lv >= 4 else Control.SIZE_FILL
	for b in _hdr_nav:
		if is_instance_valid(b):
			(b as Control).custom_minimum_size.x = 56.0 if lv < 3 else 46.0
