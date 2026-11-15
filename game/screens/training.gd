extends Screen
## Training Ground: free, unlimited damage tests against an unkillable partner of each element.
## DUMMY barely hits back (pure damage test); SPARRING fights like a boss (can your team survive 5 rounds?).

func build() -> void:
	set_bg("battle", 0.6)
	ambient(Color(1.0, 0.85, 0.6), 20)
	header("TRAINING GROUND", ["gold", "gems"])
	var b := body(76)
	# ---- left: rules and your team
	var lp := UI.panel()
	lp.anchor_right = 0.3
	lp.anchor_bottom = 1.0
	b.add_child(lp)
	var lv := UI.vbox(8)
	lp.add_child(UI.scroll(lv))
	lv.add_child(UI.label("HOW IT WORKS", 16, UI.GOLD, 3))
	lv.add_child(UI.wrap_label("Pick a partner and fight for %d rounds. She can't be defeated, so the result is the total damage your team deals." % DB.MAX_ROUNDS, 13, UI.TEXT))
	lv.add_child(UI.wrap_label("• DUMMY: she barely hits back. A pure damage test.\n• SPARRING: she fights like a boss, 3 levels above your team.\n• Elements matter: bring heroes strong against hers.\n• Free and unlimited. No Energy, no rewards, and meals are not used up.", 13, UI.MUTED))
	var tp := UI.styled_panel(Color(0.05, 0.03, 0.1, 0.85), Color(UI.GOLD, 0.4), 10, 1, 8)
	lv.add_child(tp)
	var tv := UI.vbox(4)
	tp.add_child(tv)
	tv.add_child(UI.label("YOUR TEAM", 12, UI.MUTED, 2))
	tv.add_child(UI.label("⚔ " + Game.fmt(Game.team_power()), 20, Color("#ffb86b"), 3))
	var faces := UI.hbox(4)
	tv.add_child(faces)
	for e in Game.formation():
		var fp := UI.styled_panel(Color.BLACK, DB.RARITY_COLOR[DB.rarity_of(str(e[0]))], 6, 1, 1)
		fp.add_child(UI.face_rect(str(e[0]), Vector2(38, 38)))
		faces.add_child(fp)
	tv.add_child(UI.label("Training runs: %d" % int(Game._training()["runs"]), 12, UI.MUTED))
	lv.add_child(UI.button("EDIT FORMATION", func(): main.go("formation"), "", Vector2(0, 44)))
	# ---- right: one card per element
	var rp := Control.new()
	rp.anchor_left = 0.31
	rp.anchor_right = 1.0
	rp.anchor_bottom = 1.0
	b.add_child(rp)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	var sc := UI.scroll(g)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rp.add_child(sc)
	for d in DB.training_dummies():
		g.add_child(_card(str(d["elem"]), str(d["id"])))
	UI.stagger(g, 0.05)
	tutorial("training")

func _card(elem: String, id: String) -> Control:
	var col: Color = DB.ELEMENT_COLOR.get(elem, UI.GOLD)
	var p := UI.styled_panel(Color(0.07, 0.05, 0.13, 0.94), Color(col, 0.7), 12, 2, 8)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.set_meta("elem", elem)
	var v := UI.vbox(6)
	p.add_child(v)
	var top := UI.hbox(8)
	v.add_child(top)
	var fp := UI.styled_panel(Color.BLACK, col, 8, 2, 1)
	fp.add_child(UI.face_rect(id, Vector2(64, 64)))
	top.add_child(fp)
	var nv := UI.vbox(2)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nv)
	var eh := UI.hbox(4)
	eh.add_child(UI.tex_rect(DB.icon(DB.ELEMENT_ICON.get(elem, "elem_light")), Vector2(20, 20)))
	eh.add_child(UI.label(elem, 15, col, 3))
	nv.add_child(eh)
	var nl := UI.label(DB.name_of(id), 13, Color.WHITE, 2)
	nl.clip_text = true
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nv.add_child(nl)
	var weak := ""
	for k in DB.ELEMENT_BEATS.keys():
		if str(DB.ELEMENT_BEATS[k]) == elem:
			weak = str(k)
	if weak != "":
		nv.add_child(UI.label("Weak to " + weak, 11, DB.ELEMENT_COLOR.get(weak, UI.MUTED), 2))
	for spar in [false, true]:
		var sp: bool = spar
		var best := Game.training_best(elem, sp)
		var r := UI.hbox(6)
		v.add_child(r)
		var bv := UI.vbox(0)
		bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(bv)
		bv.add_child(UI.label("SPARRING BEST" if sp else "DUMMY BEST", 10, UI.MUTED, 0))
		bv.add_child(UI.label(Game.fmt(best) if best > 0 else "—", 16, UI.GOLD if best > 0 else UI.MUTED, 2))
		var btn := UI.button("SPAR" if sp else "TRAIN", func():
			main.go("formation", {"mode": "training", "elem": elem, "spar": sp}), "" if sp else "GoldButton", Vector2(92, 40))
		btn.set_meta("train", DB.ELEMENT_GROUP.get(elem, elem) + (":spar" if sp else ""))
		r.add_child(btn)
	return p
