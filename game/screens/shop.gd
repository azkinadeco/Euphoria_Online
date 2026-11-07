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
	for i in offers.size():
		var o: Dictionary = offers[i]
		var oi: int = i
		var p := UI.panel("CardPanel")
		p.custom_minimum_size = Vector2(230, 240)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(6)
		p.add_child(v)
		var k: String = o["give"].keys()[0]
		var top := UI.hbox(4)
		top.add_child(UI.spacer())
		if int(o["off"]) > 0:
			top.add_child(UI.rarity_tag("-%d%%" % int(o["off"]), 13))
		v.add_child(top)
		var ic := UI.tex_rect(Game.reward_icon(k), Vector2(0, 76), k.begins_with("shard:"))
		if k.begins_with("rune:"):
			ic.modulate = DB.RUNES[k.split(":")[1]]["color"].lightened(0.2)
		v.add_child(ic)
		var n := UI.label("%s x%s" % [Game.reward_name(k), Game.fmt(int(o["give"][k]))], 16, Color.WHITE, 3)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
		var b := UI.button("SOLD OUT" if o["sold"] else "%s %s" % [Game.fmt(o["price"]), Game.reward_name(o["cur"])], func():
			var err := Game.market_buy(oi)
			_react(err == "")
			if err != "":
				main.toast(err, UI.RED)
			else:
				Game.sfx("star_up")
				main.toast("Purchased!", UI.GREEN)
			_render(), "GoldButton", Vector2(0, 46))
		b.disabled = o["sold"]
		v.add_child(b)
		_grid.add_child(p)
	var rp := UI.panel("CardPanel")
	rp.custom_minimum_size = Vector2(270, 240)
	var rv := UI.vbox(8)
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rp.add_child(rv)
	rv.add_child(UI.label("NEW STOCK DAILY", 18, UI.GOLD, 3))
	rv.add_child(UI.wrap_label("Rare goods at a discount. Refreshes at 00:00.", 13, UI.MUTED))
	var left := DB.MARKET_REFRESHES - int(Game.s["market"]["refresh"])
	var rb := UI.button("REFRESH (%d Gems) %d/%d" % [DB.MARKET_REFRESH_COST, left, DB.MARKET_REFRESHES], func():
		var err := Game.market_refresh()
		if err != "":
			main.toast(err, UI.RED)
		_render(), "", Vector2(0, 46))
	rb.disabled = left <= 0
	rv.add_child(rb)
	_grid.add_child(rp)
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
	for item in DB.SHOP:
		if item["cur"] != _tab:
			continue
		var it: Dictionary = item
		var p := UI.panel("CardPanel")
		p.custom_minimum_size = Vector2(230, 240)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(6)
		p.add_child(v)
		var first_key: String = it["give"].keys()[0]
		var ic := UI.tex_rect(Game.reward_icon(first_key), Vector2(0, 86))
		v.add_child(ic)
		var n := UI.label(it["name"], 18, Color.WHITE, 3)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
		var gr := UI.reward_row(it["give"], 22, 13)
		gr.alignment = FlowContainer.ALIGNMENT_CENTER
		v.add_child(gr)
		var left := int(it["limit"]) - Game.shop_bought(it["id"])
		var lim := UI.label("Left today: %d / %d" % [left, it["limit"]], 12, UI.MUTED)
		lim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lim)
		var price := "FREE" if int(it["price"]) == 0 else "%s %s" % [Game.fmt(it["price"]), Game.reward_name(it["cur"])]
		var b := UI.button(price if left > 0 else "SOLD OUT", func():
			var err := Game.buy(it)
			_react(err == "")
			if err != "":
				main.toast(err, UI.RED)
			else:
				Game.sfx("star_up")
				main.toast("Purchased %s!" % it["name"], UI.GREEN)
				_render(), "GoldButton", Vector2(0, 46))
		b.disabled = left <= 0
		v.add_child(b)
		_grid.add_child(p)
	UI.stagger(_grid)
