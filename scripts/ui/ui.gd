class_name UI
extends RefCounted
## Helper grafici condivisi.

const YELLOW := Color("#f7c51e")
const DARK := Color("#141414")
const PANEL := Color("#1d1d1d")
const PAPER := Color("#e9e4d4")
const RED := Color("#d8352e")
const ASSET_COL := {"E": Color("#8cc63f"), "P": Color("#62c6d6"), "C": Color("#b04fc0"), "J": Color("#dddddd"), "M": Color("#ffffff"), "S": Color("#ffffff")}

static var _tex := {}
static var font_title: Font
static var font_body: Font
static var font_bold: Font
static var font_italic: Font


static func init_fonts() -> void:
	if font_title != null:
		return
	font_title = load("res://assets/fonts/BebasNeue-Regular.ttf")
	font_body = load("res://assets/fonts/BarlowCondensed-Medium.ttf")
	font_bold = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	font_italic = load("res://assets/fonts/BarlowCondensed-BoldItalic.ttf")


static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path]


static func token(name: String) -> Texture2D:
	return tex("res://assets/tokens/%s.png" % name)


static func card_tex(cid: String) -> Texture2D:
	return tex("res://assets/cards/card_%s.webp" % cid)


static func asset_icon(t: String) -> Texture2D:
	match t:
		"E", "P", "C", "J":
			return token("asset_" + t)
		"M":
			return token("icon_military")
		"S":
			return token("icon_status")
	return null


static func make_theme() -> Theme:
	init_fonts()
	var th := Theme.new()
	th.default_font = font_body
	th.default_font_size = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#262626")
	sb.border_color = YELLOW
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	th.set_stylebox("normal", "Button", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#3a3220")
	th.set_stylebox("hover", "Button", sbh)
	var sbp := sb.duplicate()
	sbp.bg_color = YELLOW
	th.set_stylebox("pressed", "Button", sbp)
	var sbd := sb.duplicate()
	sbd.bg_color = Color("#1a1a1a")
	sbd.border_color = Color("#555555")
	th.set_stylebox("disabled", "Button", sbd)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color.WHITE)
	th.set_color("font_hover_color", "Button", YELLOW)
	th.set_color("font_pressed_color", "Button", DARK)
	th.set_color("font_disabled_color", "Button", Color("#777777"))
	th.set_font("font", "Button", font_bold)
	th.set_font_size("font_size", "Button", 22)
	th.set_color("font_color", "Label", Color("#eeeeee"))
	var pn := StyleBoxFlat.new()
	pn.bg_color = PANEL
	pn.border_color = Color("#000000")
	pn.set_border_width_all(1)
	th.set_stylebox("panel", "Panel", pn)
	th.set_stylebox("panel", "PanelContainer", pn)
	th.set_font("normal_font", "RichTextLabel", font_body)
	th.set_font("bold_font", "RichTextLabel", font_bold)
	th.set_font("italics_font", "RichTextLabel", font_italic)
	th.set_font_size("normal_font_size", "RichTextLabel", 19)
	th.set_font_size("bold_font_size", "RichTextLabel", 19)
	th.set_font_size("italics_font_size", "RichTextLabel", 19)
	th.set_color("default_color", "RichTextLabel", Color("#e8e8e8"))
	var opt := sb.duplicate()
	th.set_stylebox("normal", "OptionButton", opt)
	th.set_stylebox("hover", "OptionButton", sbh)
	th.set_stylebox("pressed", "OptionButton", sbh)
	th.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	th.set_font("font", "OptionButton", font_bold)
	th.set_font_size("font_size", "OptionButton", 20)
	th.set_font("font", "PopupMenu", font_bold)
	th.set_font_size("font_size", "PopupMenu", 20)
	th.set_font("font", "CheckBox", font_bold)
	th.set_font_size("font_size", "CheckBox", 20)
	th.set_font("font", "TooltipLabel", font_body)
	th.set_font_size("font_size", "TooltipLabel", 18)
	var tp := StyleBoxFlat.new()
	tp.bg_color = Color("#101010ee")
	tp.border_color = YELLOW
	tp.set_border_width_all(1)
	tp.set_content_margin_all(8)
	th.set_stylebox("panel", "TooltipPanel", tp)
	return th


static func label(text: String, size := 20, color := Color("#eeeeee"), font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font != null:
		l.add_theme_font_override("font", font)
	return l


static func title(text: String, size := 40, color := YELLOW) -> Label:
	init_fonts()
	return label(text, size, color, font_title)


static func panel_style(bg: Color, border := Color.BLACK, bw := 0, radius := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(8)
	return sb


static func icon_rect(t: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = size
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Descrizione testuale di un oggetto costo/guadagno
static func item_text(s: String) -> String:
	var it := CardsDB.parse_item(s)
	var name: String = GameEngine.ASSET_NAMES[it["t"]]
	if it["t"] == "J":
		name = "Asset a scelta"
	if it["t"] == "M":
		name = "Militare"
	if it["x"]:
		return "%s×valore %s" % ["" if it["n"] == 1 else str(it["n"]), name]
	return "%d %s" % [it["n"], name]


static func req_text(d: Dictionary) -> String:
	match d["r"]:
		"?":
			return "Funzionario coperto (qualsiasi valore)"
		"=":
			return "Valore esattamente %d" % d["v"]
		"+":
			return "Valore %d o più" % d["v"]
		"<=":
			return "Valore ≥ del Funzionario a sinistra (che deve esserci)"
	return ""
