extends SceneTree
## Dev tool: boots the game and screenshots a list of screens.
## Usage: Godot --path . -s res://tools/shot_runner.gd -- <out_dir> <step1,step2,...>
## A step is a screen name (e.g. "heroes"), "screen:param=value", or "call:method".

var main_node: Node
var steps: PackedStringArray
var out_dir: String
var idx: int = -1
var frame: int = 0
var wait := 45

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://shots"
	steps = (args[1] if args.size() > 1 else "lobby").split(",")
	if args.size() > 2:
		wait = int(args[2])
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(_d: float) -> bool:
	frame += 1
	if frame == 2:
		if not root.has_node("Game"):
			var g: Node = load("res://game/core/game.gd").new()
			g.name = "Game"
			root.add_child(g)
		main_node = load("res://game/main.tscn").instantiate()
		root.add_child(main_node)
	if frame == 30:
		_next()
	elif frame > 30 and (frame - 30) % wait == 0:
		RenderingServer.force_draw(false)
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/%02d_%s.png" % [out_dir, idx, steps[idx].replace(":", "_").replace("=", "-")])
		print("SHOT ", steps[idx])
		if OS.get_environment("AUDIT") != "":
			_audit(steps[idx])
		_next()
	return false

func _next() -> void:
	idx += 1
	if idx >= steps.size():
		quit(0)
		return
	var v := steps[idx]
	if v.begins_with("call:"):
		var parts := v.substr(5).split("|")
		if parts.size() > 1:
			main_node.call(parts[0], parts[1])
		else:
			main_node.call(parts[0])
	elif v.begins_with("viewer:"):
		# viewer:morana|3 -> full-screen ArtViewer on outfit 3 (all outfits browsable)
		var parts := v.substr(7).split("|")
		var all: Array = []
		for i in 30:
			all.append(i)
		var dbs = load("res://game/core/db.gd")
		all = all.slice(0, dbs.art_list(parts[0]).size())
		var vw = load("res://game/ui/art_viewer.gd").open(main_node, parts[0], int(parts[1]) if parts.size() > 1 else 0, all)
		if parts.size() > 2:
			(func(): vw._zoom_to(float(parts[2]), false, Vector2(640, 160)); vw._tap(Vector2(640, 160))).call_deferred()
	elif v.begins_with("detail:"):
		# detail:hero_detail|gala -> main.go(screen, {"id"/"sel": arg})
		var parts := v.substr(7).split("|")
		main_node.go(parts[0], {"id": parts[1], "sel": parts[1]})
	elif v.begins_with("game:"):
		var parts := v.substr(5).split("|")
		var g = root.get_node("Game")
		if parts.size() > 1:
			var arg: Variant = int(parts[1]) if parts[1].is_valid_int() else parts[1]
			if parts[1].begins_with("{"):
				arg = JSON.parse_string(parts[1])
			g.call(parts[0], arg)
		else:
			g.call(parts[0])
	elif v.begins_with("gcall:"):
		# gcall:finish_date|fidelia|forest|120 -> Game.finish_date("fidelia", "forest", 120)
		var parts := v.substr(6).split("|")
		var cargs: Array = []
		for a in parts.slice(1):
			cargs.append(int(a) if a.is_valid_int() else a)
		root.get_node("Game").callv(parts[0], cargs)
	elif v.begins_with("kills:"):
		# kills:octra|30 -> Game.record_kills([octra x30])
		var parts := v.substr(6).split("|")
		var arr: Array = []
		for i in int(parts[1]) if parts.size() > 1 else 1:
			arr.append(parts[0])
		root.get_node("Game").record_kills(arr)
	elif v.begins_with("gset:"):
		# gset:tower.floor|9 -> Game.s["tower"]["floor"] = 9
		var parts := v.substr(5).split("|")
		var keys := parts[0].split(".")
		var d = root.get_node("Game").s
		for k in keys.slice(0, keys.size() - 1):
			d = d[k]
		d[keys[keys.size() - 1]] = int(parts[1]) if parts[1].is_valid_int() else parts[1]
	elif v.begins_with("cur:"):
		var parts := v.substr(4).split("|")
		var args: Array = []
		for a in parts.slice(1):
			args.append(int(a) if a.is_valid_int() else a)
		main_node.current.callv(parts[0], args)
	elif v.begins_with("scale="):
		root.content_scale_factor = float(v.substr(6))
	elif v.begins_with("touch:"):
		main_node.current.call("_on_hero_touch", float(v.substr(6)), Vector2(400, 300))
	elif v.begins_with("vn:"):
		main_node.dialogue([["mora", "Commander, the forest has grown restless."], ["fidelia", "Then we clear a path. Stay behind my shield."], ["commander", "Let us go."], ["mora", "Be careful."]], Callable(), "forest")
	elif v.begins_with("chvn:"):
		var parts := v.substr(5).split("|")
		var chd: Dictionary = DB.CHAPTERS[int(parts[0])]
		main_node.dialogue((chd[parts[1]] as Array).slice(int(parts[2])), Callable(), str(chd["bg"]))
	elif v.begins_with("clear:"):
		var g = root.get_node("Game")
		for i in int(v.substr(6)):
			g.s["story"]["cleared"][DB.stage_id(i)] = 3
	elif v == "boost":
		var g = root.get_node("Game")
		for hid in g.s["heroes"].keys():
			g.s["heroes"][hid]["level"] = 80
			g.s["heroes"][hid]["star"] = 6
	elif v == "novn":
		# close any open VN dialogue / tutorial so the screen under it is visible
		for c in main_node.overlay.get_children():
			if c.has_method("_show_log"):
				c.queue_free()
	elif v == "skipbattle":
		for c in main_node.host.get_children():
			if c.has_method("skip"):
				c.skip()
	elif v == "pressok":
		# press the visible CONTINUE button of the top popup, like a player would
		# a player reads any open dialogue first
		for c in main_node.overlay.get_children():
			if c.has_method("_show_log"):
				c.queue_free()
		# overlay first (popups), then the screen itself (battle result layer); topmost wins
		var found := false
		for scope in [main_node.overlay, main_node.host]:
			var btns: Array = scope.find_children("*", "Button", true, false)
			btns.reverse()
			for c in btns:
				if c.text == "CONTINUE" and c.is_visible_in_tree() and not c.disabled and not _closing(c):
					c.emit_signal("pressed")
					found = true
					break
			if found:
				break
		if not found:
			print("STUCK: no CONTINUE button visible")
	elif v.begins_with("press:"):
		# press:<prefix> → press the topmost visible, enabled button whose text starts with it
		var want := v.substr(6)
		var hit := false
		for scope in [main_node.overlay, main_node.host]:
			var bs: Array = scope.find_children("*", "Button", true, false)
			bs.reverse()
			for c in bs:
				if c.text.begins_with(want) and c.is_visible_in_tree() and not c.disabled and not _closing(c):
					c.emit_signal("pressed")
					hit = true
					break
			if hit:
				break
		if not hit:
			print("STUCK: no button '%s'" % want)
	elif v.begins_with("expect:"):
		if str(main_node.current_name) != v.substr(7):
			print("STUCK: expected screen '%s' but on '%s'" % [v.substr(7), main_node.current_name])
		else:
			print("OK screen ", v.substr(7))
	elif v == "riftwin":
		var g = root.get_node("Game")
		g.apply_rift_result(true)
	elif v == "riftstart":
		root.get_node("Game").rift_start()
	elif v.begins_with("spawngear:"):
		# spawngear:N → N random free pieces plus Embers and Gold
		var g2 := root.get_node("Game")
		for i in int(v.substr(10)):
			g2.add_gear(["weapon", "armor", "accessory"][i % 3], ["R", "R", "SR", "SSR"][i % 4])
		g2.give({"forge_ember": 200, "gold": 900000})
	elif v.begins_with("gearset:"):
		# gearset:<hero>|<set>  → three SSR pieces of that set worn by the hero
		var g := root.get_node("Game")
		var gp := v.substr(8).split("|")
		var pieces := ["weapon", "armor", "accessory"]
		for i in pieces.size():
			var gg: Dictionary = g.add_gear(pieces[i], "SSR")
			gg["set"] = gp[1] if i < 3 else "swift"
			gg["owner"] = gp[0]
	elif v == "matprobe":
		# print every live/rigged art on screen: texture, shader, variant flag
		var stack: Array = [main_node]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			stack.append_array(n.get_children())
			if n is TextureRect and n.has_node("LiveRig") and n.texture:
				var sm := n.material as ShaderMaterial
				print("PROBE ", n.texture.resource_path.get_file(), " -> ", sm.shader.resource_path.get_file() if sm else "none", " corrupt=", sm.get_shader_parameter("corrupt_on") if sm and sm.shader.resource_path.ends_with("live25d.gdshader") else "-", " tone=", sm.get_shader_parameter("tone") if sm else "-", " desat=", sm.get_shader_parameter("desat") if sm else "-")
	elif v.begins_with("tame:"):
		var g := root.get_node("Game")
		var tid := v.substr(5)
		var bst: Dictionary = g.s.get("bestiary", {})
		bst[tid] = 200
		g.s["bestiary"] = bst
		g.give({"gold": 20000})
		print("TAME ", g.tame(tid))
		g.pet(tid)["bond"] = 6
		g.set_companion(tid)
	elif v.begins_with("wear:"):
		# wear:<hero>|<skin index>  (also makes her the secretary)
		var g := root.get_node("Game")
		var wp := v.substr(5).split("|")
		if not g.owns(wp[0]):
			g.add_hero(wp[0])
		g.hero(wp[0])["skin"] = int(wp[1])
		g.s["lobby_hero"] = wp[0]
	elif v.begins_with("oath:"):
		var g := root.get_node("Game")
		var oid := v.substr(5)
		g.hero(oid)["bond"] = 10
		g.give({"oath_ring": 1})
		print("OATH ", g.swear_oath(oid))
		main_node.current._ceremony(Callable())
	elif v == "notips":
		# mark every first-visit tutorial as seen so screens are not covered
		root.get_node("Game").s["tips_seen"] = DB.TUTORIALS.keys()
	elif v == "news":
		main_node.show_news()
	elif v.begins_with("drag:"):
		# simulate a finger: press at (x1,y1), move in steps to (x2,y2), release
		var c := v.substr(5).split("|")
		var a := Vector2(float(c[0]), float(c[1]))
		var b := Vector2(float(c[2]), float(c[3]))
		var pe := InputEventMouseButton.new()
		pe.button_index = MOUSE_BUTTON_LEFT
		pe.pressed = true
		pe.position = a
		pe.global_position = a
		Input.parse_input_event(pe)
		var prev := a
		for i in range(1, 13):
			var p2 := a.lerp(b, i / 12.0)
			var me := InputEventMouseMotion.new()
			me.position = p2
			me.global_position = p2
			me.relative = p2 - prev
			me.button_mask = MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(me)
			prev = p2
		var re := InputEventMouseButton.new()
		re.button_index = MOUSE_BUTTON_LEFT
		re.pressed = false
		re.position = b
		re.global_position = b
		Input.parse_input_event(re)
	elif v == "fortune":
		for c in main_node.host.get_children():
			if c.has_method("_open_fortune"):
				c._open_fortune()
	elif v.begins_with("kill:"):
		var g = root.get_node("Game")
		for i in 12:
			g.record_kills([v.substr(5)])
	elif v.begins_with("msgreply:"):
		# answer the open Messenger chat with reply 0/1
		for c in main_node.host.get_children():
			if c.has_method("_reply"):
				c._reply(int(v.substr(9)))
	elif v.begins_with("scroll:"):
		# scroll:<px> → scroll every ScrollContainer of the current screen down by px
		for sc in main_node.host.find_children("*", "ScrollContainer", true, false):
			sc.scroll_vertical += int(v.substr(7))
	elif v == "bond5":
		var g = root.get_node("Game")
		for hid in g.s["heroes"].keys():
			g.s["heroes"][hid]["bond"] = 5
	elif v == "vnall":
		# advance the open dialogue to the end, always picking option 0
		for k in 40:
			for c in main_node.overlay.get_children():
				if c.has_method("_show_log"):
					if c._choice_box != null and is_instance_valid(c._choice_box):
						c._choice_box.get_children()[0].emit_signal("pressed")
					else:
						c._advance()
						c._advance()
	elif v.begins_with("hold:"):
		var hc := v.substr(5).split("|")
		var hp := Vector2(float(hc[0]), float(hc[1]))
		var he := InputEventMouseButton.new()
		he.button_index = MOUSE_BUTTON_LEFT
		he.pressed = true
		he.position = hp
		he.global_position = hp
		Input.parse_input_event(he)
		set_meta("hold_pos", hp)
	elif v == "release":
		var rp: Vector2 = get_meta("hold_pos", Vector2.ZERO)
		var re2 := InputEventMouseButton.new()
		re2.button_index = MOUSE_BUTTON_LEFT
		re2.pressed = false
		re2.position = rp
		re2.global_position = rp
		Input.parse_input_event(re2)
	elif v == "board":
		main_node.show_daily_board()
	elif v == "schedule":
		main_node.show_schedule()
	elif v.begins_with("huntclear:"):
		root.get_node("Game").s["hunt"]["cleared"][v.substr(10)] = 1
	elif v == "welcome":
		root.get_node("Game").away_secs = 5 * 3600 + 720
		main_node._welcome_back(Callable())
	elif v.begins_with("cg:"):
		main_node.dialogue([[v.substr(3), "Look up, Commander. Every star feels close tonight."]], Callable(), "", false, v.substr(3), v.substr(3) + "_3")
	elif v.begins_with("bondup:"):
		main_node._on_bond_up(v.substr(7), 6)
	elif v.begins_with("pick:"):
		for c in main_node.overlay.get_children():
			if c.has_method("_show_log") and c._choice_box != null:
				var btns: Array = c._choice_box.get_children()
				btns[int(v.substr(5))].emit_signal("pressed")
	elif v.begins_with("adv:"):
		for c in main_node.overlay.get_children():
			if c.has_method("_show_log"):
				c._advance()
				c._advance()
	elif v == "wait":
		pass
	elif v == "close":
		main_node._close_all_popups()
	else:
		var parts := v.split(":")
		var params := {}
		if parts.size() > 1:
			for kv in parts[1].split("&"):
				var p := kv.split("=")
				params[p[0]] = (Array(p[1].split(";")) if ";" in p[1] else (p[1] if not p[1].is_valid_int() else int(p[1])))
		var t0 := Time.get_ticks_usec()
		main_node.call("go", parts[0], params)
		if OS.get_environment("TIMING") != "":
			print("TIMING %5.1f ms  %s" % [(Time.get_ticks_usec() - t0) / 1000.0, v])

## True while the control sits in a popup that is fading out.
func _closing(n: Node) -> bool:
	while n != null:
		if n.has_meta("closing"):
			return true
		n = n.get_parent()
	return false

## Layout audit (AUDIT=1): reports texts that are cut off or pushed off the screen on the current screen.
##   CLIP  = a label/button whose own text does not fit its box
##   CUT   = a text that sticks out of a clipping parent (not a scroll list)
##   OFF   = a text or panel outside the window
func _audit(step: String) -> void:
	var seen := {}
	var vp := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	_audit_node(main_node, step, vp, seen)
	# OVER = two texts drawn on top of each other
	var rects: Array = []
	# with a popup open only the popup counts (the dimmed screen behind it is not a clash)
	var over_root: Node = main_node
	for c in main_node.overlay.get_children():
		if c is Control and c.has_meta("popup"):
			over_root = c
	_audit_collect(over_root, vp, rects)
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			var a: Rect2 = rects[i][0]
			var b: Rect2 = rects[j][0]
			var x := a.intersection(b)
			if x.size.x > 6.0 and x.size.y > 5.0 and x.get_area() >= 0.3 * min(a.get_area(), b.get_area()):
				_audit_report("OVER", step, rects[i][1], "with \"%s\"" % [_audit_text(rects[j][1]).left(30)], seen)

func _audit_text(c: Control) -> String:
	if c is Label or c is Button:
		return str(c.text).strip_edges()
	return ""

func _audit_report(kind: String, step: String, c: Control, extra: String, seen: Dictionary) -> void:
	var t := _audit_text(c).replace("\n", " / ").left(46)
	var key := "%s|%s|%s" % [kind, step, t if t != "" else str(c.get_path())]
	if seen.has(key):
		return
	seen[key] = true
	var par := c.get_parent()
	var chain := ""
	for i in 3:
		if par == null:
			break
		chain = par.name + "/" + chain
		par = par.get_parent()
	print("AUDIT %s [%s] \"%s\" %s  <%s%s>" % [kind, step, t, extra, chain, c.get_class()])

func _audit_node(n: Node, step: String, vp: Rect2, seen: Dictionary) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n is Control:
		var c := n as Control
		if c.modulate.a < 0.05 or c.self_modulate.a < 0.0:
			return
		var txt := _audit_text(c)
		var r := c.get_global_rect()
		if txt != "" and r.size.x > 1.0:
			var font := c.get_theme_font("font")
			var fs := c.get_theme_font_size("font_size")
			if c is Label:
				var l := c as Label
				if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
					if (l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING) and txt.find("\n") < 0:
						var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
						# an ellipsis is a graceful cut: only report it when most of the text is gone
						var soft: bool = l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
						if w > l.size.x + 2.0 and (not soft or l.size.x < w * 0.6):
							_audit_report("TRIM" if soft else "CLIP", step, c, "needs %d px, has %d" % [int(w), int(l.size.x)], seen)
				elif l.get_line_count() > l.get_visible_line_count() and l.get_visible_line_count() > 0:
					_audit_report("CLIP", step, c, "%d of %d lines shown" % [l.get_visible_line_count(), l.get_line_count()], seen)
			elif c is Button:
				var b := c as Button
				if b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
					var bw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					var sb := b.get_theme_stylebox("normal")
					var avail: float = b.size.x - sb.get_minimum_size().x - (b.icon.get_width() if b.icon != null and not b.expand_icon else 0)
					var bsoft: bool = b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
					if bw > avail + 2.0 and (not bsoft or avail < bw * 0.6):
						_audit_report("TRIM" if bsoft else "CLIP", step, c, "needs %d px, has %d" % [int(bw), int(avail)], seen)
			# sticks out of a clipping ancestor / the window?
			var in_scroll := false
			var p := c.get_parent()
			var cut_by := ""
			while p != null and p != root:
				if p is ScrollContainer:
					in_scroll = true
					break
				if p is Control and (p as Control).clip_contents:
					var pr := (p as Control).get_global_rect()
					if not pr.grow(3.0).encloses(r) and cut_by == "":
						cut_by = "%s (%d px over)" % [p.name, int(max(max(pr.position.x - r.position.x, r.end.x - pr.end.x), max(pr.position.y - r.position.y, r.end.y - pr.end.y)))]
				p = p.get_parent()
			if not in_scroll:
				if cut_by != "":
					_audit_report("CUT", step, c, "by " + cut_by, seen)
				elif not vp.grow(2.0).encloses(r) and vp.intersects(r):
					_audit_report("OFF", step, c, "rect %s" % [str(Rect2i(r))], seen)
		elif c is PanelContainer and r.size.x > 60.0 and not vp.grow(6.0).encloses(r) and vp.intersects(r):
			var inside := false
			var q := c.get_parent()
			while q != null and q != root:
				if q is ScrollContainer or (q is Control and (q as Control).clip_contents):
					inside = true
					break
				q = q.get_parent()
			if not inside:
				_audit_report("OFF", step, c, "panel rect %s" % [str(Rect2i(r))], seen)
				if r.end.x > vp.end.x + 6.0:
					print("AUDIT   widest: [%s] %s" % [step, _audit_widest(c)])
	for ch in n.get_children():
		_audit_node(ch, step, vp, seen)

## Tight rectangles of the visible single-line labels (for the overlap check).
func _audit_collect(n: Node, clip: Rect2, out: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	var my_clip := clip
	if n is Control:
		var c := n as Control
		if c.modulate.a < 0.05:
			return
		if c.clip_contents or c is ScrollContainer:
			my_clip = clip.intersection(c.get_global_rect())
		if c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
			var l := c as Label
			var txt := str(l.text).strip_edges()
			if txt != "" and txt.find("\n") < 0:
				var sz: Vector2 = l.get_theme_font("font").get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size"))
				var sc := l.get_global_transform().get_scale()
				var r := l.get_global_rect()
				var w: float = min(sz.x * sc.x, r.size.x) if l.clip_text else sz.x * sc.x
				var x: float = r.position.x
				if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
					x += (r.size.x - w) * 0.5
				elif l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
					x += r.size.x - w
				var h: float = sz.y * sc.y * 0.72
				var y: float = r.position.y + (r.size.y - h) * (0.5 if l.vertical_alignment == VERTICAL_ALIGNMENT_CENTER else (1.0 if l.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM else 0.0))
				if l.vertical_alignment == VERTICAL_ALIGNMENT_TOP:
					y += sz.y * sc.y * 0.14
				var tr := Rect2(x, y, w, h).intersection(my_clip)
				if tr.size.x > 4.0 and tr.size.y > 4.0:
					out.append([tr, c])
	for ch in n.get_children():
		_audit_collect(ch, my_clip, out)

## Follows the child with the largest minimum width: shows what makes a panel wider than the screen.
func _audit_widest(c: Control) -> String:
	var out := ""
	var cur := c
	for i in 9:
		var best: Control = null
		var bw := 0.0
		for ch in cur.get_children():
			if ch is Control and (ch as Control).visible:
				var w: float = (ch as Control).get_combined_minimum_size().x
				if w > bw:
					bw = w
					best = ch
		if best == null:
			break
		var t := _audit_text(best).left(18)
		out += " > %s%s %d" % [best.get_class().replace("Container", "C"), (" \"%s\"" % t) if t != "" else "", int(bw)]
		if best is HBoxContainer or best is HFlowContainer or best is GridContainer:
			var parts: Array = []
			for ch in best.get_children():
				if ch is Control and (ch as Control).visible:
					parts.append("%s%d" % [(_audit_text(ch).left(10) + ":") if _audit_text(ch) != "" else "", int((ch as Control).get_combined_minimum_size().x)])
			out += " [" + ", ".join(parts) + "]"
			break
		cur = best
	return out
