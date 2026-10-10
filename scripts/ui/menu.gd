extends Control
## Menu principale a pieno schermo: copertina a sinistra, schermi delle fazioni a destra.

const MODES := ["UMANO", "IA", "ASSENTE"]

var main
var seat_mode := [1, 0, 1, 1]      # 0 umano, 1 IA, 2 assente
var tiles := {}
var level := 1
var speed := 1
var chk_first: CheckBox
var chk_promo: CheckBox
var chk_reveal: CheckBox
var msg: Label


func _ready() -> void:
	size = Vector2(1920, 1080)
	# Sfondo: copertina sfocata e scurita a tutto schermo
	var bg := TextureRect.new()
	bg.texture = UI.tex("res://assets/cover.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(1920, 1080)
	bg.modulate = Color(0.22, 0.2, 0.18)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.05, 0.05, 0.55)
	shade.size = Vector2(1920, 1080)
	add_child(shade)

	# Copertina nitida a sinistra, a tutta altezza
	var cover := TextureRect.new()
	cover.texture = UI.tex("res://assets/cover.png")
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cover.size = Vector2(782, 1080)
	cover.position = Vector2(0, 0)
	add_child(cover)
	var edge := TextureRect.new()
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.06, 0.06, 0.06, 0.0))
	g.set_color(1, Color(0.06, 0.06, 0.06, 0.95))
	grad.gradient = g
	grad.width = 64
	grad.height = 4
	edge.texture = grad
	edge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	edge.stretch_mode = TextureRect.STRETCH_SCALE
	edge.position = Vector2(690, 0)
	edge.size = Vector2(100, 1080)
	add_child(edge)

	# Colonna destra
	var x0 := 830.0
	var head := UI.title("NUOVA PARTITA", 64)
	head.position = Vector2(x0, 26)
	add_child(head)
	var sub := UI.label("Scegli chi governa ogni fazione: almeno due devono partecipare. L'ordine di gioco segue la sequenza qui sotto.", 22, Color("#cccccc"))
	sub.position = Vector2(x0 + 2, 100)
	add_child(sub)

	for f in GameEngine.FACTIONS:
		var i: int = f["id"]
		var pos := Vector2(x0 + (i % 2) * 545, 140 + (i / 2) * 250)
		_make_tile(f, pos)

	# Opzioni
	var opt_y := 650.0
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI.panel_style(Color("#101010dd"), Color("#3a3a3a"), 1, 8))
	box.position = Vector2(x0, opt_y)
	box.custom_minimum_size = Vector2(1060, 0)
	add_child(box)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 12)
	box.add_child(ov)
	ov.add_child(_segmented("Livello IA", ["Facile", "Normale", "Difficile"], level, func(k): level = k))
	ov.add_child(_segmented("Velocità IA", ["Lenta", "Normale", "Veloce", "Istantanea"], speed, func(k): speed = k))
	var ck := HBoxContainer.new()
	ck.add_theme_constant_override("separation", 30)
	ov.add_child(ck)
	chk_first = _check("Solo carte della prima partita", false)
	ck.add_child(chk_first)
	chk_promo = _check("Carte promo", true)
	ck.add_child(chk_promo)
	chk_reveal = _check("Mostra info nascoste (debug)", false)
	ck.add_child(chk_reveal)

	msg = UI.label("", 24, UI.RED, UI.font_bold)
	msg.position = Vector2(x0, 868)
	add_child(msg)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 18)
	btns.position = Vector2(x0, 906)
	add_child(btns)
	var b_start := _big_button("INIZIA PARTITA", 380, true)
	b_start.pressed.connect(_on_start)
	btns.add_child(b_start)
	var b_tut := _big_button("TUTORIAL", 230)
	b_tut.pressed.connect(func(): main.start_tutorial())
	btns.add_child(b_tut)
	var b_rules := _big_button("REGOLE", 200)
	b_rules.pressed.connect(func(): main.show_rules())
	btns.add_child(b_rules)
	var b_quit := _big_button("ESCI", 190)
	b_quit.pressed.connect(func(): get_tree().quit())
	btns.add_child(b_quit)

	var credits := UI.label("Adattamento digitale non ufficiale per uso personale · STATUS di Paolo Mori, illustrazioni di Alan D'Amico · © Nova Lectio / MS Edizioni · F11 schermo intero / finestra", 17, Color("#8a8a8a"))
	credits.position = Vector2(x0, 1040)
	add_child(credits)
	_refresh_tiles()


func _make_tile(f: Dictionary, pos: Vector2) -> void:
	var i: int = f["id"]
	var root := Control.new()
	root.position = pos
	root.size = Vector2(530, 236)
	add_child(root)
	var frame := Panel.new()
	frame.size = root.size
	root.add_child(frame)
	var img := TextureRect.new()
	img.texture = UI.tex("res://assets/tokens/screen_%d.jpg" % i)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.position = Vector2(4, 4)
	img.size = Vector2(522, 170)
	img.clip_contents = true
	root.add_child(img)
	var ord := UI.title("", 40, Color.WHITE)
	ord.position = Vector2(470, 2)
	root.add_child(ord)
	var bar := HBoxContainer.new()
	bar.position = Vector2(4, 178)
	bar.size = Vector2(522, 54)
	bar.add_theme_constant_override("separation", 4)
	root.add_child(bar)
	var buttons := []
	for k in range(3):
		var b := Button.new()
		b.text = MODES[k]
		b.custom_minimum_size = Vector2(171, 54)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(func():
			seat_mode[i] = k
			msg.text = ""
			_refresh_tiles())
		bar.add_child(b)
		buttons.append(b)
	var rend := UI.icon_rect(UI.token("rendita_" + f["rendita"]), Vector2(40, 48))
	rend.position = Vector2(418, 10)
	rend.tooltip_text = "Rendita iniziale"
	rend.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(rend)
	tiles[i] = {"frame": frame, "img": img, "buttons": buttons, "ord": ord, "color": f["light"]}
	# clic sull'immagine: cicla Umano → IA → Assente
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	img.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			seat_mode[i] = (seat_mode[i] + 1) % 3
			_refresh_tiles())


func _refresh_tiles() -> void:
	var n := 0
	for i in range(4):
		var t: Dictionary = tiles[i]
		var m: int = seat_mode[i]
		var active := m != 2
		t["img"].modulate = Color.WHITE if active else Color(0.28, 0.28, 0.28)
		t["frame"].add_theme_stylebox_override("panel", UI.panel_style(Color("#0c0c0c"), t["color"] if active else Color("#333333"), 4 if active else 2, 6))
		if active:
			n += 1
			t["ord"].text = "%d°" % n
		else:
			t["ord"].text = ""
		for k in range(3):
			var b: Button = t["buttons"][k]
			var sel := k == m
			var sb := UI.panel_style(UI.YELLOW if sel else Color("#1c1c1c"), UI.YELLOW if sel else Color("#444444"), 2, 4)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", UI.panel_style(UI.YELLOW if sel else Color("#3a3220"), UI.YELLOW, 2, 4))
			b.add_theme_color_override("font_color", UI.DARK if sel else Color("#dddddd"))
			b.add_theme_color_override("font_hover_color", UI.DARK if sel else UI.YELLOW)


func _segmented(label_text: String, items: Array, current: int, cb: Callable) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var l := UI.label(label_text, 28, Color.WHITE, UI.font_bold)
	l.custom_minimum_size = Vector2(190, 0)
	hb.add_child(l)
	var btns := []
	for k in range(items.size()):
		var b := Button.new()
		b.text = items[k]
		b.custom_minimum_size = Vector2(190, 50)
		b.add_theme_font_size_override("font_size", 24)
		hb.add_child(b)
		btns.append(b)
	var paint := func(sel: int):
		for k in range(btns.size()):
			var on: bool = k == sel
			btns[k].add_theme_stylebox_override("normal", UI.panel_style(UI.YELLOW if on else Color("#1c1c1c"), UI.YELLOW if on else Color("#444444"), 2, 4))
			btns[k].add_theme_color_override("font_color", UI.DARK if on else Color("#dddddd"))
			btns[k].add_theme_color_override("font_hover_color", UI.DARK if on else UI.YELLOW)
	for k in range(btns.size()):
		btns[k].pressed.connect(func():
			cb.call(k)
			paint.call(k))
	paint.call(current)
	return hb


func _check(text: String, on: bool) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.button_pressed = on
	c.add_theme_font_size_override("font_size", 24)
	return c


func _big_button(text: String, w: float, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 82)
	b.add_theme_font_override("font", UI.font_title)
	b.add_theme_font_size_override("font_size", 44)
	if primary:
		b.add_theme_stylebox_override("normal", UI.panel_style(UI.YELLOW, UI.YELLOW, 2, 6))
		b.add_theme_stylebox_override("hover", UI.panel_style(Color("#ffd84a"), Color.WHITE, 3, 6))
		b.add_theme_color_override("font_color", UI.DARK)
		b.add_theme_color_override("font_hover_color", UI.DARK)
	return b


func _on_start() -> void:
	var seats := []
	for f in GameEngine.FACTIONS:
		var m: int = seat_mode[f["id"]]
		if m == 2:
			continue
		seats.append({"fid": f["id"], "ai": m == 1, "name": f["name"]})
	if seats.size() < 2:
		msg.text = "Servono almeno 2 fazioni in gioco."
		return
	var speeds := [1.1, 0.55, 0.2, 0.0]
	main.start_game({"seats": seats, "first_game": chk_first.button_pressed, "promo": chk_promo.button_pressed,
		"ai_level": level, "ai_delay": speeds[speed], "reveal": chk_reveal.button_pressed})
