extends CanvasLayer

signal spawn_requested(kind: String)
signal action_requested(action: String)
var open := false
var screen: Control
var buttons: Array[Button] = []
var selected := 0
const ACTIONS := [
	{"label": "ENEMIGO AMARILLO", "action": "enemy_0"},
	{"label": "ENEMIGO ROSA", "action": "enemy_1"},
	{"label": "ENEMIGO ROJO", "action": "enemy_2"},
	{"label": "JEFE", "action": "boss"},
	{"label": "ULTI MAX", "action": "ultimate"},
	{"label": "OLEADA ALEATORIA", "action": "wave"},
	{"label": "MATAR TODOS", "action": "kill_all"},
	{"label": "BARRIL / COMIDA", "action": "barrel"},
	{"label": "CAJA / COMIDA", "action": "crate"},
	{"label": "TABLON DE MADERA", "action": "wood"},
	{"label": "CAÑO GRIS", "action": "pipe"}
]

func _ready() -> void:
	layer = 25
	screen = Control.new()
	add_child(screen)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.06, 0.92)
	backdrop.size = Vector2(960, 640)
	screen.add_child(backdrop)
	var title := Label.new()
	title.text = "DEBUG / OPCIONES"
	title.position = Vector2(350, 56)
	screen.add_child(title)
	for i in range(ACTIONS.size()):
		var button := Button.new()
		button.text = str(ACTIONS[i]["label"])
		button.position = Vector2(130 + (i % 2) * 360, 105 + (i / 2) * 66)
		button.size = Vector2(340, 48)
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(choose.bind(i))
		screen.add_child(button)
		buttons.append(button)
	var back := Button.new()
	back.text = "0 / ESC  VOLVER"
	back.position = Vector2(330, 520)
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
	var action: String = ACTIONS[index]["action"]
	if action in ["barrel", "crate", "wood", "pipe"]:
		spawn_requested.emit(action)
	else:
		action_requested.emit(action)
	close()

func handle_input(event: InputEvent) -> void:
	# Mouse and touch must reach Control buttons through Godot's GUI input pass.
	if not event is InputEventKey:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_0, KEY_ESCAPE: close()
			KEY_UP, KEY_W: select(selected - 1)
			KEY_DOWN, KEY_S: select(selected + 1)
			KEY_ENTER, KEY_SPACE: choose(selected)
	get_viewport().set_input_as_handled()
