extends Control
## Vista di gioco: tabellone, pannello laterale, dialoghi decisionali.

const SIDE_X := 1600.0
const SIDE_W := 320.0
const GSPACE := Vector2(70, 64)

var main
var config: Dictionary
var engine: GameEngine

var board: Control
var card_layer: Control
var token_layer: Control
var hl_layer: Control
var fx_layer: Control
var mil_tokens := {}
var status_tokens := {}
var clock: TextureRect
var side: Control
var phase_label: Label
var round_label: Label
var deck_label: Label
var faction_rows := {}
var screen_box: VBoxContainer
var log_box: RichTextLabel
var overlay: Control
var banner: PanelContainer
var banner_label: Label
var hint_panel: PanelContainer
var hint_label: RichTextLabel
var zoom: TextureRect
var coin_fx: Control

var humans: Array = []
var viewer := -1
var reveal := false
var pending: Dictionary = {}
var tutorial := false
var hints_shown := {}
var paused := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial = config.get("tutorial", false)
	reveal = config.get("reveal", false)
	size = Vector2(1920, 1080)
	var bg := ColorRect.new()
	bg.color = Color("#0d0d0d")
	bg.size = Vector2(1920, 1080)
	add_child(bg)
	_build_board()
	_build_side()
	_build_overlays()

	engine = GameEngine.new()
	add_child(engine)
	engine.setup(config)
	engine.ai_delay = config.get("ai_delay", 0.55)
	for p in engine.players:
		if not p["ai"]:
			humans.append(p["seat"])
	viewer = humans[0] if humans.size() > 0 else -1
	engine.pause_enabled = humans.size() > 0
	engine.changed.connect(refresh)
	engine.log_added.connect(_on_log)
	engine.decision_requested.connect(_on_decision)
	engine.pause_requested.connect(_on_pause)
	engine.phase_changed.connect(_on_phase)
	engine.game_ended.connect(_on_game_end)
	engine.fx.connect(_on_fx)
	_build_faction_rows()
	refresh()
	if humans.size() > 1:
		_curtain(viewer, func(): engine.run())
	else:
		engine.run.call_deferred()


func _exit_tree() -> void:
	if engine != null:
		engine.abort = true


# =================================================================== costruzione

func _build_board() -> void:
	board = Control.new()
	board.position = Vector2.ZERO
	board.size = Vector2(CardsDB.BOARD_W, CardsDB.BOARD_H)
	board.clip_contents = true
	add_child(board)
	var bt := TextureRect.new()
	bt.texture = UI.tex("res://assets/board.jpg")
	bt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bt.stretch_mode = TextureRect.STRETCH_SCALE
	bt.size = board.size
	bt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(bt)
	card_layer = Control.new()
	card_layer.size = board.size
	card_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(card_layer)
	token_layer = Control.new()
	token_layer.size = board.size
	token_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(token_layer)
	fx_layer = Control.new()
	fx_layer.size = board.size
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(fx_layer)
	hl_layer = Control.new()
	hl_layer.size = board.size
	hl_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(hl_layer)
	clock = UI.icon_rect(UI.token("clock"), Vector2(40, 40))
	board.add_child(clock)
	# area Giornale: tooltip informativi
	for g in ["G1", "G2", "G3"]:
		var info := Control.new()
		var r := _group_rect(g)
		info.position = r.position
		info.size = r.size
		info.tooltip_text = "%s\n%s" % [CardsDB.GIORNALE[g]["name"], CardsDB.GIORNALE[g]["txt"]]
		info.mouse_filter = Control.MOUSE_FILTER_PASS
		card_layer.add_child(info)


func _group_rect(g: String) -> Rect2:
	match g:
		"G1":
			return Rect2(40, 280, 340, 255)
		"G2":
			return Rect2(415, 240, 350, 300)
		"G3":
			return Rect2(790, 260, 345, 265)
	return Rect2()


func _build_side() -> void:
	side = Control.new()
	side.position = Vector2(SIDE_X, 0)
	side.size = Vector2(SIDE_W, 1080)
	add_child(side)
	var bg := Panel.new()
	bg.size = side.size
	bg.add_theme_stylebox_override("panel", UI.panel_style(Color("#161616"), Color.BLACK, 0, 0))
	side.add_child(bg)
	round_label = UI.title("ROUND 1 / 4", 34)
	round_label.position = Vector2(12, 4)
	side.add_child(round_label)
	deck_label = UI.label("", 17, Color("#aaaaaa"))
	deck_label.position = Vector2(200, 14)
	side.add_child(deck_label)
	phase_label = UI.label("", 21, Color.WHITE, UI.font_bold)
	phase_label.position = Vector2(12, 40)
	side.add_child(phase_label)
	screen_box = VBoxContainer.new()
	screen_box.position = Vector2(8, 470)
	screen_box.size = Vector2(SIDE_W - 16, 150)
	side.add_child(screen_box)
	var lp := PanelContainer.new()
	lp.position = Vector2(6, 640)
	lp.size = Vector2(SIDE_W - 12, 372)
	lp.add_theme_stylebox_override("panel", UI.panel_style(Color("#0f0f0f"), Color("#333333"), 1, 4))
	side.add_child(lp)
	log_box = RichTextLabel.new()
	log_box.scroll_following = true
	log_box.bbcode_enabled = true
	log_box.add_theme_font_size_override("normal_font_size", 16)
	log_box.add_theme_font_size_override("bold_font_size", 17)
	lp.add_child(log_box)
	var hb := HBoxContainer.new()
	hb.position = Vector2(6, 1020)
	hb.add_theme_constant_override("separation", 6)
	side.add_child(hb)
	var b1 := Button.new()
	b1.text = "MENU"
	b1.pressed.connect(_on_menu)
	hb.add_child(b1)
	var b2 := Button.new()
	b2.text = "CARTE"
	b2.tooltip_text = "Le carte Evento che hai preso"
	b2.pressed.connect(_show_my_cards)
	hb.add_child(b2)
	var b3 := Button.new()
	b3.text = "REGOLE"
	b3.pressed.connect(_show_rules_popup)
	hb.add_child(b3)


func _build_faction_rows() -> void:
	var y := 74.0
	for p in engine.players:
		var f: Dictionary = GameEngine.FACTIONS[p["fid"]]
		var row := Panel.new()
		row.position = Vector2(6, y)
		row.size = Vector2(SIDE_W - 12, 94)
		row.add_theme_stylebox_override("panel", UI.panel_style(Color("#222222"), f["color"], 2, 5))
		side.add_child(row)
		var stripe := ColorRect.new()
		stripe.color = f["color"]
		stripe.position = Vector2(0, 0)
		stripe.size = Vector2(10, 94)
		row.add_child(stripe)
		var nm := UI.label(f["name"].to_upper(), 22, Color.WHITE, UI.font_title)
		nm.position = Vector2(18, 2)
		row.add_child(nm)
		var tag := UI.label("", 15, Color("#bbbbbb"))
		tag.position = Vector2(18, 26)
		row.add_child(tag)
		var prio := UI.icon_rect(UI.token("priority"), Vector2(30, 30))
		prio.position = Vector2(270, 4)
		prio.tooltip_text = "Priorità"
		row.add_child(prio)
		var turn := UI.label("▶", 22, UI.YELLOW)
		turn.position = Vector2(248, 4)
		row.add_child(turn)
		var stats := HBoxContainer.new()
		stats.position = Vector2(18, 48)
		stats.add_theme_constant_override("separation", 3)
		row.add_child(stats)
		faction_rows[p["seat"]] = {"row": row, "tag": tag, "prio": prio, "turn": turn, "stats": stats}
		y += 98


func _build_overlays() -> void:
	banner = PanelContainer.new()
	banner.add_theme_stylebox_override("panel", UI.panel_style(Color("#000000dd"), UI.YELLOW, 2, 6))
	banner.position = Vector2(420, 545)
	banner.visible = false
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	banner_label = UI.label("", 30, UI.YELLOW, UI.font_bold)
	banner.add_child(banner_label)

	hint_panel = PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", UI.panel_style(Color("#fff6d8f2"), UI.YELLOW, 3, 8))
	hint_panel.position = Vector2(1150, 610)
	hint_panel.custom_minimum_size = Vector2(312, 0)
	hint_panel.visible = false
	add_child(hint_panel)
	var hv := VBoxContainer.new()
	hint_panel.add_child(hv)
	var ht := UI.title("TUTORIAL", 30, Color("#7a5a00"))
	hv.add_child(ht)
	hint_label = RichTextLabel.new()
	hint_label.bbcode_enabled = true
	hint_label.fit_content = true
	hint_label.custom_minimum_size = Vector2(292, 0)
	hint_label.add_theme_color_override("default_color", Color("#1a1a1a"))
	hint_label.add_theme_font_size_override("normal_font_size", 19)
	hint_label.add_theme_font_size_override("bold_font_size", 19)
	hv.add_child(hint_label)
	var hb := Button.new()
	hb.text = "HO CAPITO"
	hb.pressed.connect(func(): hint_panel.visible = false)
	hv.add_child(hb)

	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	zoom = TextureRect.new()
	zoom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	zoom.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	zoom.size = Vector2(540, 913)
	zoom.visible = false
	zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zoom)

	coin_fx = Control.new()
	coin_fx.visible = false
	coin_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin_fx)


# =================================================================== geometria

func space_rect(key: String) -> Rect2:
	var parts := key.split("_")
	var head: String = parts[0]
	var idx := int(parts[1])
	if head.begins_with("G"):
		var p: Array = CardsDB.GIORNALE[head]["spaces"][idx]["p"]
		return Rect2(Vector2(p[0], p[1]) - Vector2(GSPACE.x / 2, GSPACE.y / 2 + 2), GSPACE)
	var slot := int(head.substr(1))
	var cid: String = engine.monitor[slot]
	var cr := card_rect(slot)
	var b: Array = CardsDB.CARDS[cid]["sp"][idx]["b"]
	var sx := cr.size.x / CardsDB.CARD_W
	var sy := cr.size.y / CardsDB.CARD_H
	return Rect2(cr.position + Vector2(b[0] * sx, b[1] * sy), Vector2(CardsDB.BOX_W * sx, CardsDB.BOX_H * sy))


func card_rect(slot: int) -> Rect2:
	return Rect2(CardsDB.MONITOR_X[slot], CardsDB.MONITOR_Y, CardsDB.MONITOR_W, CardsDB.MONITOR_H)


func can_see(seat: int) -> bool:
	return reveal or viewer == -1 or seat == viewer


# =================================================================== refresh

func refresh() -> void:
	if engine == null:
		return
	_refresh_cards()
	_refresh_tokens()
	_refresh_highlights()
	_refresh_side()


func _refresh_cards() -> void:
	for c in card_layer.get_children():
		if c.has_meta("card"):
			c.queue_free()
	for slot in range(5):
		var cid: String = engine.monitor[slot]
		if cid == "":
			continue
		var tr := TextureRect.new()
		tr.set_meta("card", cid)
		tr.texture = UI.card_tex(cid)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		var r := card_rect(slot)
		tr.position = r.position
		tr.size = r.size
		tr.tooltip_text = _card_tooltip(cid)
		tr.mouse_filter = Control.MOUSE_FILTER_PASS
		tr.gui_input.connect(_on_card_input.bind(cid))
		tr.mouse_exited.connect(func(): zoom.visible = false)
		card_layer.add_child(tr)


func _card_tooltip(cid: String) -> String:
	var c: Dictionary = CardsDB.CARDS[cid]
	var t: String = c["t"].to_upper()
	var rw: String = c["rw"]
	if rw == "S":
		t += "\nRicompensa: 1 Status"
	elif rw != "":
		t += "\nRicompensa: segnalino Rendita %s" % GameEngine.ASSET_NAMES[rw]
	if c["cont"].size() > 0:
		var names := []
		for k in c["cont"]:
			names.append(GameEngine.CONT_NAMES[k])
		t += "\nContinenti: " + ", ".join(names)
	if c["txt"] != "":
		var w: String = c["fx"].get("w", "")
		t += "\n%s %s" % ["⚡ (subito):" if w == "now" else "⟳ (risoluzione):", c["txt"]]
	t += "\n(clic destro: ingrandisci)"
	return t


func _on_card_input(ev: InputEvent, cid: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		_show_zoom(cid)


func _show_zoom(cid: String) -> void:
	zoom.texture = UI.card_tex(cid)
	zoom.position = Vector2(1050, 80)
	zoom.visible = not zoom.visible or zoom.get_meta("cid", "") != cid
	zoom.set_meta("cid", cid)


func _refresh_tokens() -> void:
	for c in token_layer.get_children():
		c.queue_free()
	for key in engine.spaces:
		var sp: Dictionary = engine.spaces[key]
		var fid: int = engine.players[sp["seat"]]["fid"]
		var r := space_rect(key)
		# Un Funzionario coperto mostra sempre il lato "?" sul tabellone.
		# Solo il suo proprietario (o la modalità debug) vede un piccolo promemoria del valore.
		var tex: Texture2D
		if sp["up"]:
			tex = UI.token("officer_%d_v%d" % [fid, sp["value"]])
		else:
			tex = UI.token("officer_%d" % fid)
		var tr := UI.icon_rect(tex, r.size * 0.92)
		tr.position = r.position + r.size * 0.04
		token_layer.add_child(tr)
		if not sp["up"] and can_see(sp["seat"]) and viewer >= 0:
			var badge := PanelContainer.new()
			var sb := UI.panel_style(Color("#000000d0"), UI.YELLOW, 1, 8)
			sb.set_content_margin_all(2)
			sb.content_margin_left = 6
			sb.content_margin_right = 6
			badge.add_theme_stylebox_override("panel", sb)
			var who: String = "tu" if sp["seat"] == viewer else engine.players[sp["seat"]]["name"].split(" ")[0]
			badge.add_child(UI.label("%s: %d" % [who, sp["value"]], 13, UI.YELLOW, UI.font_bold))
			badge.position = tr.position + Vector2(-4, -6)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			token_layer.add_child(badge)
	# Militare
	for p in engine.players:
		var s: int = p["seat"]
		if not mil_tokens.has(s):
			var m := UI.icon_rect(UI.token("mil_%d" % p["fid"]), Vector2(36, 46))
			board.add_child(m)
			mil_tokens[s] = m
			m.position = CardsDB.mil_pos(p["mil"]) - Vector2(18, 26)
			var st := UI.icon_rect(UI.token("flag_%d" % p["fid"]), Vector2(40, 38))
			board.add_child(st)
			status_tokens[s] = st
		var target: Vector2 = CardsDB.mil_pos(p["mil"]) - Vector2(18, 26)
		if mil_tokens[s].position != target:
			create_tween().tween_property(mil_tokens[s], "position", target, 0.35)
	# Status: più bandiere sullo stesso spazio vengono sfalsate
	var by_pos := {}
	for p in engine.players:
		var k: int = p["status"]
		if not by_pos.has(k):
			by_pos[k] = []
		by_pos[k].append(p["seat"])
	for k in by_pos:
		var lst: Array = by_pos[k]
		for i in range(lst.size()):
			var off := Vector2(-14 + 10 * i, -22 + 8 * i) if lst.size() > 1 else Vector2(-6, -12)
			var tgt: Vector2 = CardsDB.status_pos(k) - Vector2(14, 8) + off
			if status_tokens[lst[i]].position != tgt:
				create_tween().tween_property(status_tokens[lst[i]], "position", tgt, 0.35)
			status_tokens[lst[i]].tooltip_text = "%s: %d Status" % [engine.pname(lst[i]), k]
			if k > 20:
				status_tokens[lst[i]].tooltip_text += " (oltre 20)"
	var ph := clampi(engine.phase, 1, 6)
	clock.position = Vector2(CardsDB.PHASE_NUM_X[ph - 1] - 20, 4)


func _refresh_highlights() -> void:
	for c in hl_layer.get_children():
		c.queue_free()
	if pending.get("type", "") != "place":
		return
	for key in pending["options"]:
		var r := space_rect(key)
		var b := Button.new()
		b.position = r.position - Vector2(3, 3)
		b.size = r.size + Vector2(6, 6)
		var sb := StyleBoxFlat.new()
		# Magenta: contrasta sia con il giallo delle carte sia con il beige dei Giornali
		sb.bg_color = Color(0.9, 0.05, 0.55, 0.22)
		sb.border_color = Color("#e6007e")
		sb.set_border_width_all(5)
		sb.set_corner_radius_all(6)
		sb.shadow_color = Color(0, 0, 0, 0.85)
		sb.shadow_size = 4
		b.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate()
		sbh.bg_color = Color(0.9, 0.05, 0.55, 0.5)
		sbh.border_color = Color("#ff4fb0")
		b.add_theme_stylebox_override("hover", sbh)
		b.add_theme_stylebox_override("pressed", sbh)
		b.tooltip_text = _space_tooltip(key)
		b.pressed.connect(_on_space_clicked.bind(key))
		hl_layer.add_child(b)
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "modulate", Color(1, 1, 1, 0.55), 0.6)
		tw.tween_property(b, "modulate", Color(1, 1, 1, 1), 0.6)


func _space_tooltip(key: String) -> String:
	var d := engine.space_def(key)
	var v: int = pending.get("value", 0)
	var t := ""
	if d["slot"] >= 0:
		t = CardsDB.CARDS[d["card"]]["t"].to_upper()
	else:
		t = CardsDB.GIORNALE[d["group"]]["name"].to_upper()
	t += "\n" + UI.req_text(d)
	var cs := []
	for c in d.get("c", []):
		cs.append("%s (= %d)" % [UI.item_text(c), CardsDB.item_amount(c, v)])
	if cs.size() > 0:
		t += "\nCosto: " + ", ".join(cs)
	var gs := []
	for g in d.get("g", []):
		gs.append("%s (= %d)" % [UI.item_text(g), CardsDB.item_amount(g, v)])
	if gs.size() > 0:
		t += "\nGuadagno: " + ", ".join(gs)
	if d.get("g2", false):
		t += "\nGuadagno: 1 Asset a scelta oppure +1 Militare"
	if d["group"] == "G1":
		t += "\nAttenzione: in risoluzione scarterai 1 Asset (o 1 Status) per ogni tuo Funzionario qui."
	if d["group"] == "G3":
		t += "\n⚡ Puoi scartare C+P+E, oppure 4 Asset, oppure 4 Militare per 1 Status."
	if d["slot"] >= 0:
		var c: Dictionary = CardsDB.CARDS[d["card"]]
		if c["txt"] != "":
			t += "\n%s %s" % ["⚡" if c["fx"].get("w", "") == "now" else "⟳", c["txt"]]
	return t


func _refresh_side() -> void:
	round_label.text = "ROUND %d / 4" % engine.round_n
	if engine.phase >= 7:
		phase_label.text = "Fine della partita"
	elif engine.phase > 0:
		phase_label.text = "Fase %s · %s" % [["", "I", "II", "III", "IV", "V", "VI"][engine.phase], GameEngine.PHASE_NAMES[engine.phase]]
	deck_label.text = "Mazzo: %d carte" % engine.deck.size()
	for p in engine.players:
		var s: int = p["seat"]
		var fr: Dictionary = faction_rows[s]
		fr["prio"].visible = engine.priority == s
		fr["turn"].visible = engine.current_seat == s
		var who := "IA" if p["ai"] else "Umano"
		if s == viewer:
			who += " · stai guardando tu"
		fr["tag"].text = who
		var st: HBoxContainer = fr["stats"]
		for c in st.get_children():
			c.queue_free()
		_stat(st, UI.token("icon_status"), str(p["status"]), "Status")
		_stat(st, UI.token("icon_military"), str(p["mil"]), "Militare")
		_stat(st, UI.card_tex("back") if false else UI.tex("res://assets/cards/card_back.webp"), str(p["cards"].size()), "Carte Evento prese")
		for t in ["E", "P", "C", "J", "M"]:
			if p["rendita"][t] > 0:
				_stat(st, UI.token("rendita_" + t), str(p["rendita"][t]), "Rendita " + GameEngine.ASSET_NAMES[t])
		if can_see(s):
			for t in ["E", "P", "C"]:
				_stat(st, UI.asset_icon(t), str(p["assets"][t]), GameEngine.ASSET_NAMES[t])
		else:
			_stat(st, UI.asset_icon("J"), "?", "Asset nascosti dietro lo schermo")
	# schermo del giocatore
	for c in screen_box.get_children():
		c.queue_free()
	if viewer < 0:
		screen_box.add_child(UI.label("Partita tra IA: tutte le informazioni sono visibili.", 18, Color("#aaaaaa")))
		return
	var vp: Dictionary = engine.players[viewer]
	var f: Dictionary = GameEngine.FACTIONS[vp["fid"]]
	screen_box.add_child(UI.label("DIETRO IL TUO SCHERMO · " + f["short"].to_upper(), 22, f["light"], UI.font_title))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	screen_box.add_child(hb)
	for t in ["E", "P", "C"]:
		var v := VBoxContainer.new()
		v.add_child(UI.icon_rect(UI.asset_icon(t), Vector2(48, 48)))
		var l := UI.label(str(vp["assets"][t]), 26, Color.WHITE, UI.font_title)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		v.tooltip_text = GameEngine.ASSET_NAMES[t]
		hb.add_child(v)
	var sep := VSeparator.new()
	hb.add_child(sep)
	var ov := VBoxContainer.new()
	if vp["hand"] > 0 and engine.phase == 2:
		ov.add_child(UI.icon_rect(UI.token("officer_%d_v%d" % [vp["fid"], vp["hand"]]), Vector2(70, 58)))
		ov.add_child(UI.label("in mano · pila %d" % vp["stack"].size(), 15, Color("#bbbbbb")))
	else:
		ov.add_child(UI.label("Nessun\nFunzionario", 16, Color("#888888")))
	hb.add_child(ov)


func _stat(parent: HBoxContainer, t: Texture2D, val: String, tip: String) -> void:
	var c := HBoxContainer.new()
	c.add_theme_constant_override("separation", 0)
	c.tooltip_text = tip
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.add_child(UI.icon_rect(t, Vector2(22, 26)))
	c.add_child(UI.label(val, 17, Color.WHITE, UI.font_bold))
	parent.add_child(c)


# =================================================================== eventi motore

func _on_log(t: String) -> void:
	var line := t
	if t.begins_with("—") or t.begins_with("==="):
		line = "[color=#f7c51e][b]%s[/b][/color]" % t
	elif not t.begins_with("  "):
		line = "[color=#ffffff]%s[/color]" % t
	else:
		line = "[color=#bdbdbd]%s[/color]" % t
	log_box.append_text(line + "\n")


func _on_phase(r: int, ph: int) -> void:
	if ph == 1 or ph == 4:
		_clear_frames()
	if ph >= 1 and ph <= 6 and not (ph == 6 and engine.round_n >= GameEngine.ROUNDS):
		_flash("ROUND %d · FASE %s\n%s" % [r, ["", "I", "II", "III", "IV", "V", "VI"][ph], GameEngine.PHASE_NAMES[ph].to_upper()])
		_hint("phase_%d" % ph)


func _flash(text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.panel_style(Color("#000000cc"), UI.YELLOW, 2, 8))
	var l := UI.title(text, 46)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	await get_tree().process_frame
	p.position = Vector2(800 - p.size.x / 2, 640)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


func _on_fx(kind: String, data: Dictionary) -> void:
	match kind:
		"coin":
			_show_coin(data["side"])
		"card_won":
			var r := card_rect(data["slot"])
			var f: Dictionary = GameEngine.FACTIONS[engine.players[data["seat"]]["fid"]]
			var frame := Panel.new()
			frame.position = r.position - Vector2(4, 4)
			frame.size = r.size + Vector2(8, 8)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = f["light"]
			sb.set_border_width_all(6)
			sb.set_corner_radius_all(10)
			frame.add_theme_stylebox_override("panel", sb)
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.set_meta("frame", true)
			fx_layer.add_child(frame)
			var lab := UI.label(" → " + f["short"].to_upper() + " ", 30, Color.WHITE, UI.font_title)
			var lb := PanelContainer.new()
			lb.add_theme_stylebox_override("panel", UI.panel_style(f["color"], Color.BLACK, 1, 4))
			lb.add_child(lab)
			lb.position = r.position + Vector2(20, r.size.y - 70)
			lb.set_meta("frame", true)
			lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fx_layer.add_child(lb)


func _show_coin(side_s: String) -> void:
	for c in coin_fx.get_children():
		c.queue_free()
	coin_fx.visible = true
	coin_fx.modulate = Color.WHITE
	var img := UI.icon_rect(UI.token("coin_head" if side_s == "head" else "coin_arch"), Vector2(150, 150))
	img.position = Vector2(70, 250)
	coin_fx.add_child(img)
	var l := UI.title("TESTA" if side_s == "head" else "ARCO", 54)
	l.position = Vector2(90, 400)
	coin_fx.add_child(l)
	img.pivot_offset = Vector2(75, 75)
	var tw := create_tween()
	tw.tween_property(img, "scale", Vector2(1, 0.05), 0.12)
	tw.tween_property(img, "scale", Vector2(1, 1), 0.12)
	tw.tween_property(img, "scale", Vector2(1, 0.05), 0.12)
	tw.tween_property(img, "scale", Vector2(1, 1), 0.12)
	tw.tween_interval(1.0)
	tw.tween_property(coin_fx, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): coin_fx.visible = false)


# =================================================================== decisioni

func _on_decision(req: Dictionary) -> void:
	var seat: int = req["seat"]
	if humans.size() > 1 and seat != viewer:
		_curtain(seat, func(): _present(req))
	else:
		_present(req)


func _present(req: Dictionary) -> void:
	viewer = req["seat"]
	pending = req
	refresh()
	match req["type"]:
		"place":
			banner_label.text = "Invia il tuo Funzionario di valore %d: clicca uno spazio evidenziato" % req["value"]
			banner.visible = true
			await get_tree().process_frame
			banner.position = Vector2(800 - banner.size.x / 2, 548)
			if engine.round_n == 1 and not hints_shown.has("first_place"):
				_hint("first_place")
		"choice":
			_choice_dialog(req)
		"alloc":
			_alloc_dialog(req)


func _finish(result) -> void:
	pending = {}
	banner.visible = false
	_clear_overlay()
	refresh()
	engine.provide_decision(result)


func _on_space_clicked(key: String) -> void:
	if pending.get("type", "") != "place":
		return
	zoom.visible = false
	_finish(key)


func _clear_overlay() -> void:
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _modal(title_text: String, width := 780.0, dim := true) -> VBoxContainer:
	_clear_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if dim:
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.45)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.add_child(shade)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.panel_style(Color("#1b1b1b"), UI.YELLOW, 3, 10))
	p.custom_minimum_size = Vector2(width, 0)
	overlay.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var t := UI.title(title_text, 44)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD
	t.custom_minimum_size = Vector2(width - 30, 0)
	vb.add_child(t)
	_center_later(p)
	return vb


func _center_later(p: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(p):
		p.position = Vector2(800 - p.size.x / 2, 540 - p.size.y / 2)


func _choice_dialog(req: Dictionary) -> void:
	var vb := _modal(req.get("title", "Scegli"))
	_assets_reminder(vb)
	for o in req["options"]:
		var b := Button.new()
		b.text = o["label"]
		b.custom_minimum_size = Vector2(0, 62)
		b.add_theme_font_size_override("font_size", 28)
		b.disabled = not o.get("enabled", true)
		b.pressed.connect(_finish.bind(o["id"]))
		vb.add_child(b)
	if req.get("ctx", "") == "buy_status":
		_hint("buy_status")


func _assets_reminder(vb: VBoxContainer) -> void:
	var vp: Dictionary = engine.players[viewer]
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(UI.label("Hai: ", 28))
	for t in ["E", "P", "C"]:
		hb.add_child(UI.icon_rect(UI.asset_icon(t), Vector2(42, 42)))
		hb.add_child(UI.label("%d   " % vp["assets"][t], 30, Color.WHITE, UI.font_bold))
	hb.add_child(UI.icon_rect(UI.token("icon_military"), Vector2(36, 42)))
	hb.add_child(UI.label("%d   " % vp["mil"], 30, Color.WHITE, UI.font_bold))
	hb.add_child(UI.icon_rect(UI.token("icon_status"), Vector2(42, 42)))
	hb.add_child(UI.label("%d" % vp["status"], 30, Color.WHITE, UI.font_bold))
	vb.add_child(hb)


func _alloc_dialog(req: Dictionary) -> void:
	var vb := _modal(req.get("title", "Scegli"))
	_assets_reminder(vb)
	var n: int = req["n"]
	var mx: Dictionary = req["max"]
	var counts := {}
	var labels := {}
	var info := UI.label("", 26, UI.YELLOW)
	var ok := Button.new()
	var types := ["E", "P", "C"]
	if mx.has("S"):
		types.append("S")
	var upd := func():
		var tot := 0
		for t in types:
			tot += counts[t]
			labels[t].text = str(counts[t])
		info.text = "Scelti %d di %d" % [tot, n]
		ok.disabled = tot != n
	for t in types:
		counts[t] = 0
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(UI.icon_rect(UI.asset_icon(t), Vector2(56, 56)))
		var nm := UI.label(("Perdi Status" if t == "S" else GameEngine.ASSET_NAMES[t]), 30)
		nm.custom_minimum_size = Vector2(200, 0)
		row.add_child(nm)
		var minus := Button.new()
		minus.text = " − "
		minus.custom_minimum_size = Vector2(56, 52)
		minus.add_theme_font_size_override("font_size", 30)
		row.add_child(minus)
		var l := UI.label("0", 40, Color.WHITE, UI.font_title)
		l.custom_minimum_size = Vector2(56, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		labels[t] = l
		row.add_child(l)
		var plus := Button.new()
		plus.text = " + "
		plus.custom_minimum_size = Vector2(56, 52)
		plus.add_theme_font_size_override("font_size", 30)
		row.add_child(plus)
		row.add_child(UI.label("(max %d)" % mx.get(t, 0), 22, Color("#aaaaaa")))
		minus.pressed.connect(func():
			if counts[t] > 0:
				counts[t] -= 1
			upd.call())
		plus.pressed.connect(func():
			var tot := 0
			for k in types:
				tot += counts[k]
			if counts[t] < mx.get(t, 0) and tot < n:
				counts[t] += 1
			upd.call())
		vb.add_child(row)
	vb.add_child(info)
	ok.text = "CONFERMA"
	ok.custom_minimum_size = Vector2(0, 62)
	ok.add_theme_font_size_override("font_size", 28)
	ok.pressed.connect(func(): _finish(counts.duplicate()))
	vb.add_child(ok)
	# suggerimento automatico
	var sug := Button.new()
	sug.text = "Scelta suggerita"
	sug.add_theme_font_size_override("font_size", 24)
	sug.pressed.connect(func():
		var s: Dictionary = engine.ai.decide_alloc(engine, viewer, req)
		for t in types:
			counts[t] = s.get(t, 0)
		upd.call())
	vb.add_child(sug)
	upd.call()


func _on_pause(text: String) -> void:
	viewer = humans[0] if viewer < 0 else viewer
	refresh()
	_hint("resolve_done")
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.panel_style(Color("#000000e6"), UI.YELLOW, 2, 8))
	var vb := VBoxContainer.new()
	p.add_child(vb)
	vb.add_child(UI.title("Risoluzione degli eventi", 42))
	var l := UI.label(text, 26, Color.WHITE)
	vb.add_child(l)
	var b := Button.new()
	b.text = "CONTINUA"
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func():
		p.queue_free()
		_clear_frames()
		engine.provide_decision(null))
	vb.add_child(b)
	overlay.add_child(p)
	_center_later(p)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(p):
		p.position = Vector2(800 - p.size.x / 2, 240)


func _clear_frames() -> void:
	for c in fx_layer.get_children():
		c.queue_free()


func _curtain(seat: int, then: Callable) -> void:
	_clear_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 1)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var f: Dictionary = GameEngine.FACTIONS[engine.players[seat]["fid"]]
	var vb := VBoxContainer.new()
	vb.position = Vector2(560, 260)
	vb.add_theme_constant_override("separation", 20)
	overlay.add_child(vb)
	var ban := UI.icon_rect(UI.tex("res://assets/tokens/screen_%d.jpg" % f["id"]), Vector2(800, 256))
	ban.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ban.clip_contents = true
	vb.add_child(ban)
	vb.add_child(UI.title("Tocca a %s" % f["name"], 56))
	vb.add_child(UI.label("Passa il dispositivo: le informazioni dietro lo schermo sono nascoste.", 22))
	var b := Button.new()
	b.text = "SONO PRONTO"
	b.custom_minimum_size = Vector2(260, 60)
	b.pressed.connect(func():
		_clear_overlay()
		viewer = seat
		refresh()
		then.call())
	vb.add_child(b)


func _on_game_end(results: Array) -> void:
	viewer = -1 if humans.is_empty() else viewer
	reveal = true
	refresh()
	_show_results(results)


## Schermata del punteggio finale a tutto schermo.
func _show_results(results: Array) -> void:
	_clear_overlay()
	overlay.move_to_front()
	hint_panel.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.03, 0.96)
	shade.size = Vector2(1920, 1080)
	overlay.add_child(shade)
	var win: Dictionary = results[0]
	var wf: Dictionary = GameEngine.FACTIONS[win["fid"]]
	var t := UI.title("FINE DELLA PARTITA", 40, Color("#bbbbbb"))
	t.position = Vector2(60, 18)
	overlay.add_child(t)
	var t2 := UI.title("VINCE %s CON %d PUNTI STATUS" % [wf["name"].to_upper(), win["status"]], 72, UI.YELLOW)
	t2.position = Vector2(60, 52)
	overlay.add_child(t2)
	if results.size() > 1 and results[1]["status"] == win["status"]:
		var tie := UI.label("Parità di Status: vince chi è più avanti sul tracciato Militare.", 24, Color.WHITE, UI.font_bold)
		tie.position = Vector2(1040, 82)
		overlay.add_child(tie)

	# Colonne: [x, larghezza, titolo]
	var cols := [
		[470, 110, "ROUND"], [590, 150, "PIÙ ASSET"],
		[750, 110, "AM"], [870, 110, "EU"], [990, 110, "AF"], [1110, 110, "AS"],
		[1230, 150, "SET 4 CONT."], [1390, 120, "CARTE"], [1520, 120, "MILITARE"], [1650, 210, "TOTALE"]]
	var hy := 150.0
	for c in cols:
		var cx: float = c[0]
		if c[2] in ["AM", "EU", "AF", "AS"]:
			var ic := UI.icon_rect(UI.token("cont_" + c[2]), Vector2(52, 52))
			ic.position = Vector2(cx + c[1] / 2.0 - 26, hy - 8)
			ic.tooltip_text = GameEngine.CONT_NAMES[c[2]]
			ic.mouse_filter = Control.MOUSE_FILTER_PASS
			overlay.add_child(ic)
		else:
			var hl := UI.label(c[2], 22, Color("#aaaaaa"), UI.font_bold)
			hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hl.position = Vector2(cx, hy + 8)
			hl.size = Vector2(c[1], 30)
			overlay.add_child(hl)
	var sub := UI.label("Continenti: +1 a chi ha più carte di quel continente (sotto, le carte di ciascuno); in parità vince chi è più avanti nel Militare.", 18, Color("#888888"))
	sub.position = Vector2(470, hy + 50)
	overlay.add_child(sub)

	var row_h := 178.0
	var y0 := 228.0
	for i in range(results.size()):
		var r: Dictionary = results[i]
		var f: Dictionary = GameEngine.FACTIONS[r["fid"]]
		var b: Dictionary = r["breakdown"]
		var y := y0 + i * row_h
		var first := i == 0
		var panel := Panel.new()
		panel.position = Vector2(40, y)
		panel.size = Vector2(1840, row_h - 12)
		var bg := Color(f["color"].r, f["color"].g, f["color"].b, 0.22)
		panel.add_theme_stylebox_override("panel", UI.panel_style(bg, UI.YELLOW if first else f["light"], 4 if first else 2, 8))
		overlay.add_child(panel)
		# immagine della fazione
		var img := UI.icon_rect(UI.tex("res://assets/tokens/screen_%d.jpg" % r["fid"]), Vector2(410, 131))
		img.stretch_mode = TextureRect.STRETCH_SCALE
		img.position = Vector2(48, y + (row_h - 12 - 131) / 2.0)
		overlay.add_child(img)
		var rank := PanelContainer.new()
		rank.add_theme_stylebox_override("panel", UI.panel_style(UI.YELLOW if first else Color("#111111ee"), Color.BLACK, 0, 6))
		var rl := UI.title("%d°" % (i + 1), 56, UI.DARK if first else Color.WHITE)
		rank.add_child(rl)
		rank.position = Vector2(52, y + row_h - 104)
		overlay.add_child(rank)
		var who := UI.label("IA" if r["ai"] else "UMANO", 18, Color.WHITE, UI.font_bold)
		var wp := PanelContainer.new()
		wp.add_theme_stylebox_override("panel", UI.panel_style(Color("#000000cc"), Color.BLACK, 0, 4))
		wp.add_child(who)
		wp.position = Vector2(390, y + 12)
		overlay.add_child(wp)
		var cy := y + (row_h - 12) / 2.0
		# ROUND (status accumulato durante la partita)
		_res_cell(cols[0], cy, str(b["base"]), "Status a fine round", Color.WHITE, false)
		# PIÙ ASSET
		var at: int = b["asset_total"]
		_res_cell(cols[1], cy, "+1" if b["assets"] > 0 else "—", "%d Asset" % at, UI.YELLOW if b["assets"] > 0 else Color("#777777"), b["assets"] > 0)
		# CONTINENTI
		for k in range(4):
			var cont: String = GameEngine.CONTINENTS[k]
			var n: int = b["cc"][cont]
			var won: bool = cont in b["cont_won"]
			_res_cell(cols[2 + k], cy, "+1" if won else "—", "%d %s" % [n, "carta" if n == 1 else "carte"], UI.YELLOW if won else Color("#777777"), won)
		# SET
		_res_cell(cols[6], cy, ("+%d" % b["sets"]) if b["sets"] > 0 else "—", "set completi", UI.YELLOW if b["sets"] > 0 else Color("#777777"), b["sets"] > 0)
		# CARTE / MILITARE (informativi)
		_res_cell(cols[7], cy, str(r["cards"]), "carte Evento", Color("#cccccc"), false)
		_res_cell(cols[8], cy, str(r["mil"]), "spareggio", Color("#cccccc"), false)
		# TOTALE
		var tot := PanelContainer.new()
		tot.add_theme_stylebox_override("panel", UI.panel_style(UI.YELLOW if first else Color("#1a1a1a"), UI.YELLOW if first else f["light"], 3, 8))
		var th := 142.0
		tot.position = Vector2(cols[9][0], cy - th / 2.0)
		tot.custom_minimum_size = Vector2(cols[9][1], th)
		tot.size = Vector2(cols[9][1], th)
		var tv := VBoxContainer.new()
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tot.add_child(tv)
		var tl := UI.title(str(r["status"]), 80, UI.DARK if first else Color.WHITE)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(tl)
		var gain: int = r["status"] - b["base"]
		var tg := UI.label(("+%d a fine partita" % gain) if gain > 0 else "nessun bonus", 18, UI.DARK if first else Color("#bbbbbb"), UI.font_bold)
		tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(tg)
		overlay.add_child(tot)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.position = Vector2(470, y0 + results.size() * row_h + 10)
	overlay.add_child(hb)
	for spec in [["TORNA AL MENU", func(): main.show_menu()], ["GUARDA IL TABELLONE", _results_hide.bind(results)], ["RIGIOCA", func(): main.start_game(config)]]:
		var bt := Button.new()
		bt.text = spec[0]
		bt.custom_minimum_size = Vector2(300, 64)
		bt.add_theme_font_override("font", UI.font_title)
		bt.add_theme_font_size_override("font_size", 34)
		bt.pressed.connect(spec[1])
		hb.add_child(bt)


func _results_hide(results: Array) -> void:
	_clear_overlay()
	var b := Button.new()
	b.text = "PUNTEGGIO FINALE"
	b.position = Vector2(620, 548)
	b.custom_minimum_size = Vector2(360, 64)
	b.add_theme_font_override("font", UI.font_title)
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(func():
		b.queue_free()
		_show_results(results))
	add_child(b)


func _res_cell(col: Array, cy: float, big: String, small: String, color: Color, highlight: bool) -> void:
	var w: float = col[1]
	var box := PanelContainer.new()
	if highlight:
		box.add_theme_stylebox_override("panel", UI.panel_style(Color(0.97, 0.77, 0.12, 0.18), UI.YELLOW, 3, 8))
	else:
		box.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	box.position = Vector2(col[0] + 4, cy - 52)
	box.custom_minimum_size = Vector2(w - 8, 104)
	box.size = Vector2(w - 8, 104)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -6)
	box.add_child(v)
	var l := UI.title(big, 56, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	if small != "":
		var s := UI.label(small, 17, UI.YELLOW if highlight else Color("#999999"), UI.font_bold)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	overlay.add_child(box)


# =================================================================== pannelli vari

func _on_menu() -> void:
	var vb := _modal("Abbandonare la partita?", 520)
	var b1 := Button.new()
	b1.text = "TORNA AL MENU PRINCIPALE"
	b1.pressed.connect(func(): main.show_menu())
	vb.add_child(b1)
	var b2 := Button.new()
	b2.text = "CONTINUA A GIOCARE"
	b2.pressed.connect(_back_to_pending)
	vb.add_child(b2)


func _back_to_pending() -> void:
	_clear_overlay()
	if pending.get("type", "") in ["choice", "alloc"]:
		_present(pending)


func _show_my_cards() -> void:
	var seat := viewer if viewer >= 0 else 0
	var p: Dictionary = engine.players[seat]
	var vb := _modal("Carte Evento di %s" % p["name"], 1300)
	var cc := engine.continent_counts(p)
	vb.add_child(UI.label("Continenti: America %d · Europa %d · Africa %d · Asia %d" % [cc["AM"], cc["EU"], cc["AF"], cc["AS"]], 22))
	var grid := GridContainer.new()
	grid.columns = 8
	vb.add_child(grid)
	if p["cards"].is_empty():
		vb.add_child(UI.label("Nessuna carta presa finora.", 20, Color("#999999")))
	for cid in p["cards"]:
		var t := UI.icon_rect(UI.card_tex(cid), Vector2(150, 254))
		t.tooltip_text = _card_tooltip(cid)
		t.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(t)
	var b := Button.new()
	b.text = "CHIUDI"
	b.pressed.connect(_back_to_pending)
	vb.add_child(b)


func _show_rules_popup() -> void:
	var vb := _modal("Riepilogo del round", 900)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(860, 0)
	rt.text = TutorialData.SUMMARY
	vb.add_child(rt)
	var b := Button.new()
	b.text = "CHIUDI"
	b.pressed.connect(_back_to_pending)
	vb.add_child(b)


func _hint(id: String) -> void:
	if not tutorial or hints_shown.has(id):
		return
	if not TutorialData.HINTS.has(id):
		return
	hints_shown[id] = true
	hint_label.text = TutorialData.HINTS[id]
	hint_panel.visible = true
	hint_panel.reset_size()
	await get_tree().process_frame
	hint_panel.position = Vector2(1604, 1012 - hint_panel.size.y)
