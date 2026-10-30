extends CanvasLayer

signal spawn_requested(kind: String)
var open := false
var screen: Control
var buttons: Array[Button] = []
var selected := 0
const ITEMS := ["barrel", "crate", "wood", "pipe"]

func _ready() -> void:
	layer = 25
	screen = Control.new()
	add_child(screen)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.06, 0.92)
	backdrop.size = Vector2(960, 640)
	screen.add_child(backdrop)
	var title := Label.new()
	title.text = "DEBUG / CREAR OBJETO"
	title.position = Vector2(285, 130)
	screen.add_child(title)
	for i in range(ITEMS.size()):
		var button := Button.new()
		button.text = ["1  BARRIL / COMIDA ALEATORIA", "2  CAJA / COMIDA ALEATORIA", "3  TABLON DE MADERA", "4  CAÑO GRIS"][i]
		button.position = Vector2(270, 190 + i * 60)
		button.size = Vector2(420, 48)
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(choose.bind(i))
		screen.add_child(button)
		buttons.append(button)
	var back := Button.new()
	back.text = "O / ESC  VOLVER"
	back.position = Vector2(330, 450)
	back.size = Vector2(300, 42)
	back.pressed.connect(close)
	screen.add_child(back)
	close()

func show_menu() -> void:
	open = true
	screen.show()
	select(0)

func close() -> void:
	open = false
	screen.hide()
	get_viewport().gui_release_focus()

func select(index: int) -> void:
	selected = posmod(index, buttons.size())
	buttons[selected].grab_focus()

func choose(index: int) -> void:
	spawn_requested.emit(ITEMS[index])
	close()

func handle_input(event: InputEvent) -> void:
	# Mouse and touch must reach Control buttons through Godot's GUI input pass.
	if not event is InputEventKey:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_O, KEY_ESCAPE: close()
			KEY_UP, KEY_W: select(selected - 1)
			KEY_DOWN, KEY_S: select(selected + 1)
			KEY_ENTER, KEY_SPACE: choose(selected)
			KEY_1, KEY_2, KEY_3, KEY_4: choose(event.physical_keycode - KEY_1)
	get_viewport().set_input_as_handled()
