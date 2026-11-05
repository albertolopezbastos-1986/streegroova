extends CanvasLayer

signal confirmed(slot: int)
signal cancelled
signal debug_requested
signal selection_changed

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const PREVIEW_CHARACTERS = ["meli", "malu", "pato", "dami", "vampi"]
const PREVIEW_PORTRAITS = {
	"dami": preload("res://assets/characters_40_frames/dami/portraits/damiportrait.png"),
	"malu": preload("res://assets/characters_40_frames/malu/portraits/Maluportrait.png"),
	"meli": preload("res://assets/characters_40_frames/meli/portraits/Meliportrait.png"),
	"pato": preload("res://assets/characters_40_frames/pato/portraits/Patoportrait.png"),
	"vampi": preload("res://assets/characters_40_frames/vampi/portraits/vampiportrait.png")
}

var screen: Control
var cards: Array[Button] = []
var selected := 0
var open := false
var stick_latched := false
var locked := false
var blink_time := 0.0
var mobile_direct_confirm := false
var confirm_button: Button

func _process(dt: float) -> void:
	if not open:
		return
	blink_time += dt
	for i in range(cards.size()):
		var style := cards[i].get_theme_stylebox("pressed") as StyleBoxFlat
		style.border_color = Color.WHITE if i == selected and int(blink_time * (14 if locked else 6)) % 2 == 0 else Color("62efd4")

func _ready() -> void:
	layer = 15
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var background := ColorRect.new()
	background.color = Color("0c1020")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(background)
	add_label("ELIGE TU PERSONAJE", Rect2(70, 44, 820, 40), 26, Color.WHITE)
	for i in range(Catalog.slots().size() + PREVIEW_CHARACTERS.size()):
		var playable := i < Catalog.slots().size()
		var pack: Dictionary
		if playable:
			pack = Catalog.character_for_slot(i)
		else:
			var id: String = PREVIEW_CHARACTERS[i - Catalog.slots().size()]
			pack = {"display_name": id.capitalize(), "portrait": PREVIEW_PORTRAITS[id]}
		var card := Button.new()
		card.position = Vector2(72 + (i % 4) * 208, 130 + (i / 4) * 190)
		card.size = Vector2(192, 180)
		card.toggle_mode = true
		card.set_meta("playable", playable)
		if not playable:
			card.focus_mode = Control.FOCUS_NONE
			card.mouse_default_cursor_shape = Control.CURSOR_ARROW
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("192034")
		normal.border_color = Color("354158")
		normal.set_border_width_all(2)
		var active := normal.duplicate() as StyleBoxFlat
		active.bg_color = Color("263d49")
		active.border_color = Color("62efd4")
		active.set_border_width_all(4)
		card.add_theme_stylebox_override("normal", normal)
		card.add_theme_stylebox_override("hover", active)
		card.add_theme_stylebox_override("pressed", active)
		card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		screen.add_child(card)
		var portrait := TextureRect.new()
		portrait.name = "Portrait"
		portrait.position = Vector2(16, 8)
		portrait.size = Vector2(160, 144)
		portrait.texture = pack["portrait"]
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var name_label := Label.new()
		name_label.text = str(pack["display_name"]).to_upper()
		name_label.position = Vector2(8, 154)
		name_label.size = Vector2(176, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_label)
		if playable:
			card.pressed.connect(on_card_pressed.bind(i))
		else:
			card.toggle_mode = false
		cards.append(card)
	confirm_button = Button.new()
	confirm_button.text = "ENTER / A  -  ELEGIR"
	confirm_button.position = Vector2(294, 510)
	confirm_button.size = Vector2(372, 43)
	confirm_button.add_theme_font_size_override("font_size", 12)
	confirm_button.pressed.connect(func(): confirmed.emit(selected))
	screen.add_child(confirm_button)
	for child in screen.get_children():
		if child != background:
			child.position.y += 50
	hide_panel()

func add_label(value: String, bounds: Rect2, pixels: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = bounds.position
	label.size = bounds.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(label)

func show_panel() -> void:
	open = true
	locked = false
	blink_time = 0
	stick_latched = false
	screen.show()
	select(selected)

func hide_panel() -> void:
	open = false
	screen.hide()
	for card in cards:
		if card.has_focus():
			card.release_focus()

func select(index: int) -> void:
	if locked:
		return
	var previous := selected
	selected = posmod(index, Catalog.slots().size())
	for i in range(cards.size()):
		cards[i].set_pressed_no_signal(i == selected)
	cards[selected].grab_focus()
	if selected != previous:
		selection_changed.emit()

func on_card_pressed(index: int) -> void:
	if index < 0 or index >= Catalog.slots().size() or locked:
		return
	select(index)
	if mobile_direct_confirm and not locked:
		confirmed.emit(selected)

func handle_input(event: InputEvent) -> void:
	if locked:
		return
	if event.is_echo():
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_X:
			if absf(event.axis_value) < 0.3:
				stick_latched = false
			elif absf(event.axis_value) > 0.6 and not stick_latched:
				select(selected + (1 if event.axis_value > 0 else -1))
				stick_latched = true
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("left"):
		select(selected - 1)
	elif event.is_action_pressed("right"):
		select(selected + 1)
	elif event.is_action_pressed("start") or event.is_action_pressed("jump") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		confirmed.emit(selected)
	elif event.is_action_pressed("pause_game") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
		cancelled.emit()
	else:
		return
	get_viewport().set_input_as_handled()

func setup_mobile() -> void:
	mobile_direct_confirm = true
	confirm_button.hide()
	var background := screen.get_child(0) as ColorRect
	background.color = Color.BLACK
	for card in cards:
		var label := card.get_child(1) as Label
		label.add_theme_font_size_override("font_size", 20)
	setup_mobile_layout(get_viewport().get_visible_rect().size)

func setup_mobile_layout(area: Vector2) -> void:
	transform = Transform2D.IDENTITY
	screen.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	screen.size = area
	var background := screen.get_child(0) as ColorRect
	background.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	background.position = Vector2.ZERO
	background.size = area
	background.color = Color.BLACK
	var heading := screen.get_child(1) as Label
	heading.position = Vector2(12, 16)
	heading.size = Vector2(area.x - 24, 38)
	heading.add_theme_font_size_override("font_size", mini(18, int((area.x - 24) / 18)))
	var gap := 12.0
	var row_height := (area.y - 116.0) / 4.0
	var card_width := minf((area.x - 36.0) / 2.0, row_height - gap)
	var origin_x := (area.x - card_width * 2 - gap) / 2
	for i in range(cards.size()):
		var card := cards[i]
		card.position = Vector2(origin_x + (i % 2) * (card_width + gap), 64 + floori(i / 2.0) * row_height)
		card.size = Vector2(card_width, row_height - gap)
		var portrait := card.get_node("Portrait") as TextureRect
		portrait.position = Vector2(6, 6)
		portrait.size = Vector2(card_width - 12, card.size.y - 32)
		var label := card.get_child(1) as Label
		label.position = Vector2(4, card.size.y - 24)
		label.size = Vector2(card_width - 8, 20)
		label.add_theme_font_size_override("font_size", 14)
