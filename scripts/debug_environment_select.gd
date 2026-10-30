extends CanvasLayer

signal chosen(index: int)
signal cancelled
const ArcadeUI = preload("res://scripts/arcade_ui.gd")
var screen: Control
var buttons: Array[Button] = []
var selected := 0
var open := false

func _ready() -> void:
	layer = 16
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_font_override("font", ArcadeUI.FONT)
	add_child(screen)
	var background := ColorRect.new()
	background.color = Color("0c1020")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(background)
	var title := Label.new()
	title.text = "DEBUG ROOM / ESCENARIO"
	title.position = Vector2(80, 90)
	title.size = Vector2(800, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("62efd4"))
	screen.add_child(title)
	var back := Button.new()
	back.text = "ESC / VOLVER A PERSONAJES"
	back.position = Vector2(230, 570)
	back.size = Vector2(500, 42)
	back.add_theme_font_size_override("font_size", 12)
	back.pressed.connect(func(): cancelled.emit())
	screen.add_child(back)
	hide_panel()

func show_panel(environments: Array, initial: int) -> void:
	if buttons.is_empty():
		for i in range(environments.size()):
			var button := Button.new()
			button.text = "%d  /  %s" % [i + 1, str(environments[i]["name"]).to_upper()]
			button.position = Vector2(230, 170 + i * 66)
			button.size = Vector2(500, 52)
			button.add_theme_font_size_override("font_size", 16)
			button.pressed.connect(func(): chosen.emit(i))
			screen.add_child(button)
			buttons.append(button)
	open = true
	screen.show()
	select(initial)

func hide_panel() -> void:
	open = false
	if screen != null:
		screen.hide()
	for button in buttons:
		button.release_focus()

func select(index: int) -> void:
	selected = posmod(index, buttons.size())
	buttons[selected].grab_focus()

func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event is InputEventKey and event.pressed and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
		chosen.emit(event.physical_keycode - KEY_1)
	elif event.is_action_pressed("up") or event.is_action_pressed("left"):
		select(selected - 1)
	elif event.is_action_pressed("down") or event.is_action_pressed("right"):
		select(selected + 1)
	elif event.is_action_pressed("start") or event.is_action_pressed("jump"):
		chosen.emit(selected)
	elif event.is_action_pressed("pause_game"):
		cancelled.emit()
	get_viewport().set_input_as_handled()
