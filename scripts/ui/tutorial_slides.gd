extends Control
## Presentazione delle regole a schede, con evidenziazione delle aree del tabellone.

var main
var mode := "rules"   # "rules" oppure "tutorial"
var idx := 0
var shade_layer: Control
var content: Control
var text_panel: PanelContainer
var title_l: Label
var body: RichTextLabel
var btn_prev: Button
var btn_next: Button
var page_l: Label


func _ready() -> void:
	size = Vector2(1920, 1080)
	var bg := ColorRect.new()
	bg.color = Color("#0d0d0d")
	bg.size = Vector2(1920, 1080)
	add_child(bg)
	var b := TextureRect.new()
	b.texture = UI.tex("res://assets/board.jpg")
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_SCALE
	b.size = Vector2(CardsDB.BOARD_W, CardsDB.BOARD_H)
	add_child(b)
	shade_layer = Control.new()
	shade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade_layer)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	text_panel = PanelContainer.new()
	text_panel.add_theme_stylebox_override("panel", UI.panel_style(Color("#141414f2"), UI.YELLOW, 3, 10))
	text_panel.custom_minimum_size = Vector2(640, 0)
	add_child(text_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	text_panel.add_child(vb)
	title_l = UI.title("", 46)
	vb.add_child(title_l)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size = Vector2(610, 0)
	body.add_theme_font_size_override("normal_font_size", 22)
	body.add_theme_font_size_override("bold_font_size", 22)
	vb.add_child(body)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	btn_prev = Button.new()
	btn_prev.text = "◀ INDIETRO"
	btn_prev.pressed.connect(func(): _go(idx - 1))
	hb.add_child(btn_prev)
	btn_next = Button.new()
	btn_next.text = "AVANTI ▶"
	btn_next.pressed.connect(func(): _go(idx + 1))
	hb.add_child(btn_next)
	var esc := Button.new()
	esc.text = "MENU"
	esc.pressed.connect(func(): main.show_menu())
	hb.add_child(esc)
	page_l = UI.label("", 18, Color("#999999"))
	hb.add_child(page_l)
	_go(0)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		if ev.keycode == KEY_RIGHT:
			_go(idx + 1)
		elif ev.keycode == KEY_LEFT:
			_go(idx - 1)


func _go(i: int) -> void:
	var slides: Array = TutorialData.SLIDES
	if i >= slides.size():
		_finish()
		return
	idx = clampi(i, 0, slides.size() - 1)
	var s: Dictionary = slides[idx]
	title_l.text = s["title"]
	body.text = s["text"]
	page_l.text = "  %d / %d" % [idx + 1, slides.size()]
	btn_prev.disabled = idx == 0
	var last := idx == slides.size() - 1
	if last:
		btn_next.text = "INIZIA LA PARTITA GUIDATA" if mode == "tutorial" else "FINE"
	else:
		btn_next.text = "AVANTI ▶"
	_shade(s.get("rect", []))
	_content(s)
	_place_panel(s.get("rect", []))


func _shade(r: Array) -> void:
	for c in shade_layer.get_children():
		c.queue_free()
	var full := Rect2(0, 0, 1920, 1080)
	if r.is_empty():
		var c := ColorRect.new()
		c.color = Color(0, 0, 0, 0.72)
		c.position = full.position
		c.size = full.size
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade_layer.add_child(c)
		return
	var h := Rect2(r[0], r[1], r[2], r[3])
	var parts := [
		Rect2(0, 0, 1920, h.position.y),
		Rect2(0, h.end.y, 1920, 1080 - h.end.y),
		Rect2(0, h.position.y, h.position.x, h.size.y),
		Rect2(h.end.x, h.position.y, 1920 - h.end.x, h.size.y)]
	for p in parts:
		var c := ColorRect.new()
		c.color = Color(0, 0, 0, 0.72)
		c.position = p.position
		c.size = p.size
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade_layer.add_child(c)
	var frame := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = UI.YELLOW
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", sb)
	frame.position = h.position - Vector2(4, 4)
	frame.size = h.size + Vector2(8, 8)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade_layer.add_child(frame)


func _content(s: Dictionary) -> void:
	for c in content.get_children():
		c.queue_free()
	match s.get("show", ""):
		"banners":
			for i in range(4):
				var t := UI.icon_rect(UI.tex("res://assets/tokens/screen_%d.jpg" % i), Vector2(560, 179))
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				t.position = Vector2(40 + (i % 2) * 580, 240 + (i / 2) * 200)
				content.add_child(t)
		"assets":
			var x := 80.0
			for t in ["E", "P", "C", "J"]:
				var a := UI.icon_rect(UI.asset_icon(t), Vector2(120, 120))
				a.position = Vector2(x, 200)
				content.add_child(a)
				var r := UI.icon_rect(UI.token("rendita_" + t), Vector2(110, 140))
				r.position = Vector2(x + 5, 380)
				content.add_child(r)
				x += 170
			var m := UI.icon_rect(UI.token("rendita_M"), Vector2(110, 140))
			m.position = Vector2(x + 5, 380)
			content.add_child(m)
			var l1 := UI.title("ASSET", 40)
			l1.position = Vector2(80, 140)
			content.add_child(l1)
			var l2 := UI.title("SEGNALINI RENDITA", 40)
			l2.position = Vector2(80, 330)
			content.add_child(l2)
		"officers":
			for f in range(4):
				for v in range(1, 5):
					var o := UI.icon_rect(UI.token("officer_%d_v%d" % [f, v]), Vector2(110, 95))
					o.position = Vector2(60 + v * 125 - 125, 120 + f * 120)
					content.add_child(o)
				var q := UI.icon_rect(UI.token("officer_%d" % f), Vector2(110, 95))
				q.position = Vector2(60 + 4 * 125 + 30, 120 + f * 120)
				content.add_child(q)
		"card":
			var c := UI.icon_rect(UI.card_tex(s["card"]), Vector2(560, 947))
			c.position = Vector2(80, 66)
			content.add_child(c)
			var notes := [
				[Vector2(660, 560), "← costo (sopra lo spazio)"],
				[Vector2(660, 650), "← requisito sullo spazio"],
				[Vector2(660, 800), "← guadagno (sotto lo spazio)"],
				[Vector2(660, 90), "← ricompensa per la maggioranza"]]
			for n in notes:
				var l := UI.label(n[1], 24, UI.YELLOW, UI.font_bold)
				l.position = n[0] - Vector2(0, 18)
				content.add_child(l)


func _place_panel(r: Array) -> void:
	await get_tree().process_frame
	text_panel.reset_size()
	await get_tree().process_frame
	var sz := text_panel.size
	var pos := Vector2(1240, 540 - sz.y / 2)
	if not r.is_empty():
		var h := Rect2(r[0], r[1], r[2], r[3])
		if h.position.y > 500:
			pos = Vector2(1900 - sz.x, maxf(20, h.position.y - sz.y - 20))
		elif h.end.y < 300:
			pos = Vector2(960 - sz.x / 2, h.end.y + 30)
		elif h.position.x > 900:
			pos = Vector2(maxf(20, h.position.x - sz.x - 30), 120)
		else:
			pos = Vector2(1900 - sz.x, h.end.y + 30)
	pos.y = clampf(pos.y, 10, 1070 - sz.y)
	text_panel.position = pos


func _finish() -> void:
	if mode == "tutorial":
		main.start_game({"seats": [{"fid": 0, "ai": true, "name": "Mano Invisibile"}, {"fid": 1, "ai": false, "name": "Ragione di Stato"}],
			"first_game": true, "promo": false, "ai_level": 0, "ai_delay": 0.8, "tutorial": true})
	else:
		main.show_menu()
