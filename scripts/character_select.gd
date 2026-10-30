extends CanvasLayer

signal confirmed(slot: int)
signal cancelled
signal debug_requested
signal selection_changed

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const Catalog = preload("res://scripts/character_catalog.gd")

var screen: Control
var cards: Array[Button] = []
var selected := 0
var open := false
var stick_latched := false
var locked := false
var blink_time := 0.0

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
	add_label("ELIGE TU PERSONAJE", Rect2(70, 44, 820, 40), 26, Color("62efd4"))
	add_label("LA NOCHE TE ESPERA   /   TAB: DEBUG ROOM", Rect2(70, 92, 820, 24), 11, Color("98a3b9"))
	for i in range(Catalog.slots().size()):
		var pack: Dictionary = Catalog.character_for_slot(i)
		var card := Button.new()
		card.position = Vector2(112 + i * 250, 149)
		card.size = Vector2(236, 249)
		card.toggle_mode = true
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
		portrait.position = Vector2(16, 13)
		portrait.size = Vector2(204, 182)
		portrait.texture = pack["portrait"]
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var name_label := Label.new()
		name_label.text = str(pack["display_name"]).to_upper()
		name_label.position = Vector2(8, 211)
		name_label.size = Vector2(220, 25)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_label)
		card.pressed.connect(select.bind(i))
		cards.append(card)
	var confirm := Button.new()
	confirm.text = "ENTER / A  -  ELEGIR"
	confirm.position = Vector2(294, 427)
	confirm.size = Vector2(372, 43)
	confirm.add_theme_font_size_override("font_size", 12)
	confirm.pressed.connect(func(): confirmed.emit(selected))
	screen.add_child(confirm)
	add_label("A / D O FLECHAS PARA CAMBIAR   -   ESC PARA VOLVER", Rect2(50, 491, 860, 22), 10, Color("98a3b9"))
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
	selected = posmod(index, cards.size())
	for i in range(cards.size()):
		cards[i].set_pressed_no_signal(i == selected)
	cards[selected].grab_focus()
	if selected != previous:
		selection_changed.emit()

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
	var back := Button.new()
	back.text = "VOLVER"
	back.position = Vector2(294, 628)
	back.size = Vector2(180, 48)
	back.add_theme_font_size_override("font_size", 12)
	back.pressed.connect(func(): cancelled.emit())
	screen.add_child(back)
	var debug := Button.new()
	debug.text = "DEBUG ROOM"
	debug.position = Vector2(486, 628)
	debug.size = Vector2(180, 48)
	debug.add_theme_font_size_override("font_size", 12)
	debug.pressed.connect(func(): debug_requested.emit())
	screen.add_child(debug)
