extends Screen
## Wardrobe: Special Skins — exclusive outfits bought with a Skin Ticket or Gems.

var _sel := ""

func build() -> void:
	var ids: Array = DB.SPECIAL_SKINS.keys().filter(func(h): return DB.special_index(h) >= 0)
	_sel = str(params.get("hero", ids[0] if not ids.is_empty() else ""))
	if not ids.has(_sel) and not ids.is_empty():
		_sel = ids[0]
	set_bg("blackmarket", 0.55)
	var fx := FestivalFX.new("firefly", Color("#ffd479"), 34)
	add_child(fx)
	move_child(fx, mini(2, get_child_count() - 1))
	header("WARDROBE", ["gems", "skin_ticket"])
	var b := body(76)
	# ---- left: skin list
	var lp := UI.panel()
	lp.anchor_right = 0.26
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(UI.scroll(lv))
	lv.add_child(UI.label("SPECIAL SKINS", 15, UI.GOLD, 3))
	for id in ids:
		var hid: String = id
		var owned := Game.skin_unlocked(hid, DB.special_index(hid))
		var btn := Button.new()
		btn.theme_type_variation = "FlatButton"
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 84)
		var fr := Panel.new()
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.add_theme_stylebox_override("panel", UI.style(Color(0.08, 0.05, 0.14, 0.95), UI.GOLD if hid == _sel else Color("#4a3a6e"), 10, 3 if hid == _sel else 1, 0))
		fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(fr)
		var face := UI.tex_rect(DB.face(hid, DB.special_index(hid)), Vector2(72, 72), true)
		face.position = Vector2(6, 6)
		face.size = Vector2(72, 72)
		fr.add_child(face)
		var nm := UI.label(DB.SPECIAL_SKINS[hid], 13, Color.WHITE, 3)
		nm.position = Vector2(86, 10)
		nm.size = Vector2(200, 20)
		fr.add_child(nm)
		fr.add_child(_tag(DB.name_of(hid), Vector2(86, 32), Color("#d4b8ff")))
		fr.add_child(_tag("OWNED" if owned else "NEW", Vector2(86, 52), UI.GREEN if owned else Color("#ff8fb8")))
		btn.pressed.connect(func():
			Game.sfx("ui_click")
			main.replace("wardrobe", {"hero": hid}))
		lv.add_child(btn)
	if _sel == "":
		return
	# ---- centre: big animated preview
	var idx := DB.special_index(_sel)
	var glow := TextureRect.new()
	glow.texture = load("res://art/ui/rays.png")
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.anchor_left = 0.27
	glow.anchor_right = 0.7
	glow.anchor_bottom = 1.0
	glow.modulate = Color(1, 0.85, 0.6, 0.5)
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = gm
	b.add_child(glow)
	glow.resized.connect(func(): glow.pivot_offset = glow.size * 0.5)
	glow.create_tween().set_loops().tween_property(glow, "rotation", TAU, 50.0).from(0.0)
	var art := UI.tex_rect(DB.art(_sel, idx))
	art.anchor_left = 0.27
	art.anchor_right = 0.7
	art.anchor_bottom = 1.0
	UI.live(art, Color("#ffe6a3"))
	b.add_child(art)
	UI.fade_in(art, 0.5, Vector2(0, 30))
	# ---- right: details & purchase
	var rp := UI.panel()
	rp.anchor_left = 0.71
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var v := UI.vbox(10)
	rp.add_child(v)
	v.add_child(UI.label("✦ SPECIAL SKIN ✦", 14, UI.GOLD, 3))
	v.add_child(UI.wrap_label(DB.SPECIAL_SKINS[_sel], 24, Color.WHITE))
	v.add_child(UI.label(DB.name_of(_sel) + "  •  " + DB.title_of(_sel), 13, Color("#d4b8ff"), 2))
	v.add_child(UI.wrap_label("Exclusive outfit — not available from Star Up or Bond. Wearing it always grants the top outfit bonus: +10% ATK & HP.", 13, UI.MUTED))
	var owned2 := Game.skin_unlocked(_sel, idx)
	if not Game.owns(_sel):
		v.add_child(UI.label("Recruit %s to wear this skin." % DB.name_of(_sel), 14, Color("#ff8a9a"), 2))
	elif owned2:
		var eq := int(Game.hero(_sel).get("skin", 0)) == idx
		v.add_child(UI.button("EQUIPPED" if eq else "WEAR NOW", func():
			Game.set_skin(_sel, idx)
			Game.sfx("star_up")
			main.toast("%s is wearing %s!" % [DB.name_of(_sel).split(" ")[0], DB.SPECIAL_SKINS[_sel]], Color("#ff8fb8"))
			main.replace("wardrobe", {"hero": _sel}), "" if eq else "GoldButton", Vector2(0, 52)))
	else:
		var tickets := Game.amount("skin_ticket")
		var tb := UI.button("USE SKIN TICKET  (%d)" % tickets, _buy, "GoldButton", Vector2(0, 52))
		tb.disabled = tickets <= 0
		v.add_child(tb)
		v.add_child(UI.button("BUY  %s Gems" % Game.fmt(DB.SPECIAL_PRICE), _buy, "", Vector2(0, 48)))
		v.add_child(UI.wrap_label("Skin Tickets: Mailbox gifts and Commander Road (Lv.50 & Lv.100).", 12, UI.MUTED))
	v.add_child(UI.spacer(false))
	v.add_child(UI.button("VIEW HERO", func(): main.go("hero_detail", {"id": _sel}), "", Vector2(0, 42)))

func _tag(text: String, pos: Vector2, col: Color) -> Label:
	var l := UI.label(text, 11, col, 2)
	l.position = pos
	return l

func _buy() -> void:
	var idx := DB.special_index(_sel)
	var use_ticket := Game.amount("skin_ticket") > 0
	main.confirm("Unlock %s for %s?" % [DB.SPECIAL_SKINS[_sel], "1 Skin Ticket" if use_ticket else "%s Gems" % Game.fmt(DB.SPECIAL_PRICE)], func():
		var err := Game.buy_costume(_sel, idx)
		if err != "":
			main.toast(err, UI.RED)
			return
		Game.set_skin(_sel, idx)
		Game.sfx("awakening")
		Game.voice(_sel, "bond")
		main.dialogue([[_sel, "...Do you like it? I wore it just for you, Commander."]], func(): main.replace("wardrobe", {"hero": _sel}), "", false, _sel, "%s_special" % _sel), "UNLOCK")
