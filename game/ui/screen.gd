class_name Screen
extends Control
## Base class for every full-page screen. The router (Main) instantiates a
## screen, assigns `main` + `params`, then calls build().

var main: Node          # game/main.gd
var params: Dictionary = {}
var _chips: Array = []

func build() -> void:
	pass

## Called by Main when Game.changed fires while this screen is visible.
func refresh() -> void:
	_update_chips()

func on_back() -> bool:
	## Return true to consume the back action (e.g. close an inner panel).
	return false

# ----------------------------------------------------------------- helpers

func set_bg(key: String, dim: float = 0.45) -> void:
	var t := UI.tex_rect(DB.bg(key), Vector2.ZERO, true)
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(t)
	move_child(t, 0)
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
	"EXPEDITION": "icon_afk", "HEART CATCH": "icon_heart", "CODEX": "icon_codex", "WORLD BOSS": "icon_boss", "FESTIVAL": "icon_festival", "BOSS HUNT": "icon_combat_target", "STARLIGHT RIFT": "icon_awakening", "PRIVATE ROOM": "icon_heart", "BESTIARY": "icon_boss", "DATE": "icon_heart", "WARDROBE": "icon_heart"}

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
	if HEADER_ICONS.has(title):
		var hi := UI.tex_rect(DB.icon(HEADER_ICONS[title]), Vector2(40, 40))
		hi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_child(hi)
		var it := hi.create_tween().set_loops()
		it.tween_property(hi, "modulate", Color(1.25, 1.2, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
		it.tween_property(hi, "modulate", Color.WHITE, 1.2).set_trans(Tween.TRANS_SINE)
	var t := UI.label(title, 26, UI.GOLD, 6)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.size_flags_vertical = Control.SIZE_FILL
	bar.add_child(t)
	bar.add_child(UI.spacer())
	for k in chips:
		bar.add_child(_chip(k))
	_update_chips()
	return bar

func _chip(key: String) -> Control:
	var p := UI.styled_panel(Color(0, 0, 0, 0.55), Color("#5b4790"), 22, 1, 8)
	p.custom_minimum_size = Vector2(150, 44)
	var h := UI.hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	h.add_child(UI.tex_rect(Game.reward_icon(key), Vector2(30, 30)))
	var l := UI.label("", 16, Color.WHITE, 3)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	_chips.append({"key": key, "label": l})
	if key in ["gems", "energy"]:
		var plus := UI.button("+", func(): main.go("shop"), "FlatButton", Vector2(26, 26))
		plus.add_theme_font_size_override("font_size", 18)
		plus.add_theme_color_override("font_color", UI.GOLD)
		h.add_child(plus)
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
