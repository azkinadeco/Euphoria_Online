extends Screen
## Daily shop: gem/gold/arena-coin exchanges with daily purchase limits.

var _grid: GridContainer
var _tab := "gems"
var _keeper: TextureRect
var _keeper_id := ""
var _bubble: PanelContainer
var _bubble_l: Label
var _keeper_name: Label
var _puppets: Dictionary = {}   # keeper id -> NPCPuppet (all pivot-rigged & animated)
## Which keeper runs which tab.
const TAB_KEEPER := {"gems": "shop1", "gold": "shop1", "arena_coin": "hairly", "friend_point": "grafity", "market": "shop2"}
const SHOP1_PIVOTS := {"eye_l": Vector2(0.445, 0.114), "eye_r": Vector2(0.617, 0.112), "mouth": Vector2(0.55, 0.158),
	"neck": Vector2(0.54, 0.195), "chest": Vector2(0.55, 0.33), "hand": Vector2(0.32, 0.36), "hips": Vector2(0.55, 0.53)}
const KEEPERS := {"shop1": ["Lulu", "res://art/npc/shopkeeper_1.png", "Merchant of Euphoria"], "shop2": ["Lulu", "res://art/npc/store_lulu.png", "Black Market (Night Shift)"],
	"hairly": ["Hairly", "res://art/npc/hairly_lobby.png", "Champion's Oracle"], "grafity": ["Grafity", "res://art/npc/grafity_shop.png", "Friendship Corner"]}

func build() -> void:
	set_bg("asgard", 0.55)
	_tab = str(params.get("tab", "gems"))
	header("SHOP", ["gold", "gems", "arena_coin", "friend_point"])
	var b := body(76)
	# --- shopkeeper NPC on the left
	_keeper = UI.tex_rect(null)
	_keeper.anchor_right = 0.24
	_keeper.anchor_bottom = 1.0
	_keeper.offset_top = 40
	_keeper.mouse_filter = Control.MOUSE_FILTER_STOP
	_keeper.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_child(_keeper)
	_keeper.resized.connect(func(): _keeper.pivot_offset = Vector2(_keeper.size.x * 0.5, _keeper.size.y))
	var br := _keeper.create_tween().set_loops()
	br.tween_property(_keeper, "scale", Vector2(1.006, 1.018), 1.6).set_trans(Tween.TRANS_SINE)
	br.tween_property(_keeper, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)
	_keeper.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_keeper_touch())
	# animated (pivot-rigged) Night Shift Lulu for the Black Market
	var pv := {"shop1": SHOP1_PIVOTS, "shop2": {}, "hairly": DB.HAIRLY_PIVOTS, "grafity": DB.GRAFITY_PIVOTS}
	for kid in KEEPERS.keys():
		var pp := NPCPuppet.new(DB.tex(KEEPERS[kid][1]), kid, pv[kid])
		pp.anchor_right = 0.24
		pp.anchor_bottom = 1.0
		pp.offset_top = 120
		pp.visible = false
		b.add_child(pp)
		pp.spoke.connect(func(text): _say(text))
		_puppets[kid] = pp
	_keeper_name = UI.label("", 16, UI.GOLD, 5)
	_keeper_name.anchor_right = 0.24
	_keeper_name.offset_top = 4
	_keeper_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(_keeper_name)
	_bubble = UI.styled_panel(Color(1, 1, 1, 0.95), UI.GOLD, 14, 2, 10)
	_bubble.anchor_right = 0.24
	_bubble.offset_top = 34
	_bubble.offset_left = 6
	_bubble.offset_right = -6
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_l = UI.wrap_label("", 13, Color("#2a1a3a"))
	_bubble.add_child(_bubble_l)
	_bubble.visible = false
	b.add_child(_bubble)
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.anchor_left = 0.25
	b.add_child(v)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 6)
	v.add_child(tabs)
	for t in [["gems", "GEM SHOP"], ["gold", "GOLD SHOP"], ["arena_coin", "ARENA SHOP"], ["friend_point", "FRIEND SHOP"], ["market", "BLACK MARKET"]]:
		var key: String = t[0]
		var tb := UI.button(t[1], func(): _tab = key; _render(), "TabButton", Vector2(150, 42))
		tb.toggle_mode = true
		tb.set_meta("key", key)
		tabs.add_child(tb)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	var sc := UI.scroll(_grid)
	v.add_child(sc)
	sc.resized.connect(func(): _grid.columns = maxi(2, int((sc.size.x + 14) / 262.0)))
	_render()

func _set_keeper(kid: String) -> void:
	if kid == _keeper_id:
		return
	_keeper_id = kid
	var k: Array = KEEPERS[kid]
	_keeper_name.text = "%s  •  %s" % [k[0], k[2]]
	var p: NPCPuppet = _puppets[kid]
	for k2 in _puppets.keys():
		_puppets[k2].visible = k2 == kid
		_puppets[k2].set_process(k2 == kid)
	_keeper.visible = false
	UI.fade_in(p, 0.35, Vector2(-30, 0))
	p.greet()
	return
	_keeper.texture = DB.tex(k[1])
	UI.fade_in(_keeper, 0.35, Vector2(-30, 0))
	_say(Game.voice(kid, "greet"))

func _say(text: String) -> void:
	_bubble_l.text = "%s\n%s" % [KEEPERS[_keeper_id][0], text]
	_bubble.visible = true
	UI.pop(_bubble, 0.2)
	if _bubble.has_meta("tw"):
		var old: Tween = _bubble.get_meta("tw")
		if old and old.is_valid():
			old.kill()
	var tw := _bubble.create_tween()
	tw.tween_interval(3.5)
	tw.tween_callback(func(): _bubble.visible = false)
	_bubble.set_meta("tw", tw)

func _keeper_touch() -> void:
	_say(Game.voice(_keeper_id, "tap"))
	var tw := _keeper.create_tween()
	tw.tween_property(_keeper, "position:y", _keeper.position.y - 18, 0.12).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_keeper, "position:y", _keeper.position.y, 0.25).set_trans(Tween.TRANS_BOUNCE)

## Called after a purchase attempt so the shopkeeper reacts.
func _react(ok: bool) -> void:
	var p: NPCPuppet = _puppets.get(_keeper_id)
	if is_instance_valid(p):
		if ok:
			p.react_happy()
		else:
			p.react_sad()
		return
	_say(Game.voice(_keeper_id, "thanks" if ok else "poor"))
	if ok:
		var tw := _keeper.create_tween()
		tw.tween_property(_keeper, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_keeper, "scale", Vector2.ONE, 0.2)

func _render_market() -> void:
	var offers := Game.market_offers()
	# refresh / info card first
	var rp := UI.styled_panel(Color(0.12, 0.04, 0.12, 0.9), Color("#ff6fae", 0.55), 14, 1, 12.0)
	rp.custom_minimum_size = Vector2(230, 252)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := UI.vbox(8)
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rp.add_child(rv)
	var mi := UI.tex_rect(DB.icon("icon_shop"), Vector2(0, 54))
	rv.add_child(mi)
	for t in [["BLACK MARKET", 18, Color("#ff9ad0"), 3], ["Rare goods, shady discounts.", 12, UI.MUTED, 0]]:
		var l := UI.label(t[0], t[1], t[2], t[3])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rv.add_child(l)
	var secs := (Game.day_key() + 1) * 86400 - 7 * 3600 - Game.now()
	var chip := UI.styled_panel(Color(0, 0, 0, 0.45), Color("#9fd0ff", 0.5), 10, 1, 5.0)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_child(UI.label("⟳ New stock in %dh %02dm" % [secs / 3600, (secs / 60) % 60], 12, Color("#9fd0ff"), 0))
	rv.add_child(chip)
	var left := DB.MARKET_REFRESHES - int(Game.s["market"]["refresh"])
	var rb := UI.button("REFRESH  %d" % DB.MARKET_REFRESH_COST, func():
		var err := Game.market_refresh()
		if err != "":
			main.toast(err, UI.RED)
		_render(), "", Vector2(0, 44))
	rb.icon = Game.reward_icon("gems")
	rb.add_theme_constant_override("icon_max_width", 22)
	rb.disabled = left <= 0
	rv.add_child(rb)
	var rl := UI.label("Refreshes left today: %d / %d" % [left, DB.MARKET_REFRESHES], 11, UI.MUTED)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(rl)
	_grid.add_child(rp)
	for i in offers.size():
		var o: Dictionary = offers[i]
		var oi: int = i
		var sold: bool = o["sold"]
		var off := int(o["off"])
		var p := UI.styled_panel(Color(0.1, 0.05, 0.13, 0.92) if not sold else Color(0.06, 0.05, 0.08, 0.85), Color("#ff6fae", 0.7) if (off >= 20 and not sold) else Color("#6b55a8", 0.6), 14, 1, 10.0)
		p.custom_minimum_size = Vector2(230, 252)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(6)
		p.add_child(v)
		var k: String = o["give"].keys()[0]
		var halo := Control.new()
		halo.custom_minimum_size = Vector2(0, 100)
		halo.draw.connect(func():
			var c := Vector2(halo.size.x * 0.5, 50)
			for q in 6:
				halo.draw_circle(c, 46.0 - q * 6.0, Color(1.0, 0.45, 0.75, 0.04 + q * 0.025)))
		v.add_child(halo)
		var ic: Control
		if k.begins_with("shard:"):
			var hid := k.split(":")[1]
			var fr := Panel.new()
			fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
			fr.add_theme_stylebox_override("panel", UI.style(Color.WHITE, Color.TRANSPARENT, 44, 0, 0))
			fr.custom_minimum_size = Vector2(88, 88)
			fr.set_anchors_preset(Control.PRESET_CENTER_TOP)
			fr.offset_left = -44
			fr.offset_right = 44
			fr.offset_top = 6
			fr.offset_bottom = 94
			halo.add_child(fr)
			var ft := UI.tex_rect(DB.face(hid), Vector2.ZERO, true)
			ft.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			fr.add_child(ft)
			var ring := Panel.new()
			ring.add_theme_stylebox_override("panel", UI.style(Color.TRANSPARENT, DB.RARITY_COLOR.get(DB.rarity_of(hid), UI.GOLD), 44, 2, 0))
			ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			fr.add_child(ring)
			ic = fr
		else:
			var t := UI.tex_rect(Game.reward_icon(k), Vector2.ZERO)
			t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			t.offset_top = 8
			t.offset_bottom = -8
			if k.begins_with("rune:"):
				t.modulate = DB.RUNES[k.split(":")[1]]["color"].lightened(0.2)
			halo.add_child(t)
			ic = t
		if off > 0 and not sold:
			var tp := UI.styled_panel(Color(1.0, 0.35, 0.6, 0.3), Color("#ff6fae"), 8, 1, 3.0)
			tp.position = Vector2(6, 6)
			tp.add_child(UI.label(" -%d%% " % off, 12, Color("#ffc2df"), 2))
			halo.add_child(tp)
		var n := UI.label("%s x%s" % [Game.reward_name(k), Game.fmt(int(o["give"][k]))], 16, Color.WHITE if not sold else UI.MUTED, 3)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		v.add_child(n)
		var was := UI.label("was %s" % Game.fmt(int(round(float(o["price"]) / (1.0 - off / 100.0)))) if off > 0 else "Limit 1 per stock", 12, UI.MUTED, 0)
		was.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(was)
		var afford := Game.amount(str(o["cur"])) >= int(o["price"])
		var b := UI.button("SOLD OUT" if sold else Game.fmt(o["price"]), func():
			var err := Game.market_buy(oi)
			_react(err == "")
			if err != "":
				main.toast(err, UI.RED)
			else:
				Game.sfx("star_up")
				main.toast("Purchased!", UI.GREEN)
			_render(), "GoldButton" if (afford and not sold) else "", Vector2(0, 46))
		b.disabled = sold
		if not sold:
			b.icon = Game.reward_icon(str(o["cur"]))
			b.add_theme_constant_override("icon_max_width", 24)
			if not afford:
				b.add_theme_color_override("font_color", Color("#ff7a7a"))
		else:
			ic.modulate = Color(0.45, 0.45, 0.5)
			var stamp := UI.label("SOLD OUT", 20, Color("#ff7a7a"), 4)
			stamp.rotation = -0.25
			stamp.position = Vector2(60, 36)
			halo.add_child(stamp)
		v.add_child(b)
		_grid.add_child(p)
	UI.stagger(_grid)

func refresh() -> void:
	super.refresh()

func _render() -> void:
	for tb in find_children("*", "Button", true, false):
		if tb.has_meta("key"):
			tb.button_pressed = tb.get_meta("key") == _tab
	_set_keeper(TAB_KEEPER.get(_tab, "shop1"))
	var bgr := get_child(0) as TextureRect
	if bgr:
		bgr.texture = DB.bg("blackmarket" if _tab == "market" else "asgard")
	for c in _grid.get_children():
		c.queue_free()
	if _tab == "market":
		_render_market()
		return
	_grid.add_child(_info_card())
	for item in DB.SHOP:
		if item["cur"] != _tab:
			continue
		_grid.add_child(_item_card(item))
	UI.stagger(_grid)

## Strip-card that explains the tab and counts down to the daily restock.
func _info_card() -> Control:
	var p := UI.styled_panel(Color(0.08, 0.05, 0.14, 0.88), Color(UI.GOLD, 0.45), 14, 1, 12.0)
	p.custom_minimum_size = Vector2(230, 252)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var cur := "gems" if _tab == "market" else _tab
	var ic := UI.tex_rect(Game.reward_icon(cur), Vector2(0, 54))
	v.add_child(ic)
	var titles := {"gems": "GEM SHOP", "gold": "GOLD SHOP", "arena_coin": "ARENA SHOP", "friend_point": "FRIEND SHOP"}
	var subs := {"gems": "Tickets, energy and premium gifts.", "gold": "Daily upgrade materials for your heroes.", "arena_coin": "Earn coins by winning Arena battles.", "friend_point": "Earn points from hearts and friend supports."}
	for t in [[titles.get(_tab, "SHOP"), 18, UI.GOLD, 3], ["You have %s" % Game.fmt(Game.amount(cur)), 14, Color.WHITE, 2]]:
		var l := UI.label(t[0], t[1], t[2], t[3])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var sub := UI.wrap_label(subs.get(_tab, ""), 12, UI.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var secs := (Game.day_key() + 1) * 86400 - 7 * 3600 - Game.now()
	var chip := UI.styled_panel(Color(0, 0, 0, 0.45), Color("#9fd0ff", 0.5), 10, 1, 5.0)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var cl := UI.label("⟳ Restocks in %dh %02dm" % [secs / 3600, (secs / 60) % 60], 12, Color("#9fd0ff"), 0)
	chip.add_child(cl)
	v.add_child(chip)
	if _tab == "friend_point":
		v.add_child(UI.button("EARN POINTS", func(): main.go("friends"), "", Vector2(0, 40)))
	elif _tab == "arena_coin":
		v.add_child(UI.button("GO TO ARENA", func(): main.go("arena"), "", Vector2(0, 40)))
	return p

func _item_card(it: Dictionary) -> Control:
	var left := int(it["limit"]) - Game.shop_bought(it["id"])
	var sold := left <= 0
	var free := int(it["price"]) == 0
	var afford := free or Game.amount(str(it["cur"])) >= int(it["price"])
	var first_key: String = it["give"].keys()[0]
	var glow_c: Color = UI.GREEN if free else Color(0.75, 0.55, 1.0)
	var p := UI.styled_panel(Color(0.09, 0.06, 0.16, 0.92) if not sold else Color(0.06, 0.05, 0.09, 0.85), Color(UI.GREEN, 0.8) if (free and not sold) else Color("#6b55a8", 0.6), 14, 2 if (free and not sold) else 1, 10.0)
	p.custom_minimum_size = Vector2(230, 252)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(5)
	p.add_child(v)
	# icon on a soft radial halo
	var halo := Control.new()
	halo.custom_minimum_size = Vector2(0, 92)
	halo.draw.connect(func():
		var c := Vector2(halo.size.x * 0.5, 46)
		for k in 6:
			halo.draw_circle(c, 44.0 - k * 6.0, Color(glow_c, 0.05 + k * 0.025)))
	var ic := UI.tex_rect(Game.reward_icon(first_key), Vector2.ZERO)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_top = 6
	ic.offset_bottom = -6
	halo.add_child(ic)
	v.add_child(halo)
	var tag := ""
	var tag_c := UI.GOLD
	if free:
		tag = "FREE"
		tag_c = UI.GREEN
	elif int(it["limit"]) <= 2:
		tag = "LIMITED"
		tag_c = Color("#ff8a5c")
	elif first_key == "summon_ticket":
		tag = "POPULAR"
		tag_c = Color("#ff6fae")
	if tag != "" and not sold:
		var tp := UI.styled_panel(Color(tag_c, 0.25), tag_c, 8, 1, 3.0)
		tp.position = Vector2(8, 8)
		var tl := UI.label(" %s " % tag, 11, tag_c, 2)
		tp.add_child(tl)
		halo.add_child(tp)
	var n := UI.label(it["name"], 17, Color.WHITE if not sold else UI.MUTED, 3)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.clip_text = true
	v.add_child(n)
	var gr := UI.reward_row(it["give"], 22, 13)
	gr.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(gr)
	# stock bar
	var sb := UI.bar(left, int(it["limit"]), "", 5)
	sb.add_theme_stylebox_override("fill", UI.style(UI.GREEN if left > 0 else UI.MUTED, Color.TRANSPARENT, 3, 0, 0))
	v.add_child(sb)
	var lim := UI.label("Stock today: %d / %d" % [left, it["limit"]], 11, UI.MUTED)
	lim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lim)
	var price := "FREE" if free else Game.fmt(it["price"])
	var b := UI.button("SOLD OUT" if sold else price, func():
		var err := Game.buy(it)
		_react(err == "")
		if err != "":
			main.toast(err, UI.RED)
		else:
			Game.sfx("star_up")
			main.toast("Purchased %s!" % it["name"], UI.GREEN)
			_render(), "GoldButton" if (afford and not sold) else "", Vector2(0, 46))
	if not free and not sold:
		b.icon = Game.reward_icon(str(it["cur"]))
		b.add_theme_constant_override("icon_max_width", 24)
		if not afford:
			b.add_theme_color_override("font_color", Color("#ff7a7a"))
			b.tooltip_text = "Not enough %s" % Game.reward_name(str(it["cur"]))
	b.disabled = sold
	v.add_child(b)
	if free and not sold:
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "modulate", Color(1.2, 1.2, 1.2), 0.6)
		tw.tween_property(b, "modulate", Color.WHITE, 0.6)
	if sold:
		halo.modulate = Color(0.5, 0.5, 0.55)
		var stamp := UI.label("SOLD OUT", 20, Color("#ff7a7a"), 4)
		stamp.rotation = -0.25
		stamp.position = Vector2(60, 34)
		halo.add_child(stamp)
	return p
