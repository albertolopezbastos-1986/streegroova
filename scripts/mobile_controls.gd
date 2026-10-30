extends CanvasLayer

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const ACTIONS = ["left", "right", "up", "down", "attack", "jump", "ultimate"]
const CENTER := Vector2(130, 810)
const STICK_RADIUS := 64.0
const DEADZONE := 0.18
const BUTTON_RADIUS := 43.0
const BUTTONS = {"attack": Vector2(875, 766), "jump": Vector2(766, 810), "ultimate": Vector2(875, 852)}
const PAUSE_RECT := Rect2(435, 746, 90, 48)
const MINT := Color("62efd4")

var game: Node2D
var enabled := false
var drawer: Node2D
var fingers: Dictionary = {}
var stick_finger := -1
var stick := Vector2.ZERO
var pressed_actions: Dictionary = {}

static func is_mobile() -> bool:
	if OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("Boolean(navigator.userAgentData?.mobile || /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1))"))
	return false

func setup(owner_game: Node2D, mobile: bool) -> void:
	game = owner_game
	enabled = mobile
	layer = 30
	if not is_instance_valid(drawer):
		drawer = Node2D.new()
		drawer.draw.connect(draw_controls)
		add_child(drawer)
	if enabled:
		# A separate lower deck keeps fingers away from the playable floor.
		get_window().content_scale_size = Vector2i(960, 900)
	sync_visibility()

func sync_visibility() -> void:
	var active: bool = enabled and game.state in ["play", "pause"] and not game.show_help and not game.ranking_panel.open
	drawer.visible = active
	if not active or game.state != "play":
		release_all()

func _process(_dt: float) -> void:
	sync_visibility()
	if drawer.visible:
		drawer.queue_redraw()

func set_action(action: String, strength: float) -> void:
	if strength > 0:
		if not pressed_actions.has(action) or not is_equal_approx(float(pressed_actions[action]), strength):
			Input.action_press(action, strength)
		pressed_actions[action] = strength
	elif pressed_actions.has(action):
		Input.action_release(action)
		pressed_actions.erase(action)

func update_stick(point: Vector2) -> void:
	stick = ((point - CENTER) / STICK_RADIUS).limit_length()
	var axis := Vector2.ZERO
	if stick.length() > DEADZONE:
		axis = stick.normalized() * ((stick.length() - DEADZONE) / (1.0 - DEADZONE))
	set_action("left", maxf(0, -axis.x))
	set_action("right", maxf(0, axis.x))
	set_action("up", maxf(0, -axis.y))
	set_action("down", maxf(0, axis.y))

func update_buttons() -> void:
	for action in BUTTONS:
		var held := false
		for finger in fingers.values():
			if finger["role"] == action and finger["point"].distance_to(BUTTONS[action]) <= BUTTON_RADIUS + 14:
				held = true
		set_action(action, 1.0 if held else 0.0)

func release_all() -> void:
	for action in pressed_actions.keys():
		Input.action_release(action)
	pressed_actions.clear()
	fingers.clear()
	stick_finger = -1
	stick = Vector2.ZERO

func handle_input(event: InputEvent) -> bool:
	if not enabled or not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return false
	sync_visibility()
	if not drawer.visible:
		return false
	if event is InputEventScreenTouch and event.pressed and PAUSE_RECT.has_point(event.position):
		release_all()
		game.player.reset_running()
		if game.state == "pause":
			game.state = game.previous_state
		else:
			game.previous_state = game.state
			game.state = "pause"
		return true
	if game.state != "play":
		return true
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if not fingers.has(event.index):
				return false
			fingers.erase(event.index)
			if event.index == stick_finger:
				stick_finger = -1
				update_stick(CENTER)
			update_buttons()
			return true
		var role := ""
		if stick_finger == -1 and event.position.distance_to(CENTER) <= STICK_RADIUS + 24:
			role = "stick"
			stick_finger = event.index
		else:
			for action in BUTTONS:
				if event.position.distance_to(BUTTONS[action]) <= BUTTON_RADIUS:
					role = action
					break
		if role.is_empty():
			return false
		fingers[event.index] = {"role": role, "point": event.position}
	elif fingers.has(event.index):
		fingers[event.index]["point"] = event.position
	else:
		return false
	if event.index == stick_finger:
		update_stick(event.position)
	update_buttons()
	drawer.queue_redraw()
	return true

func text_at(value: String, at: Vector2, size: int, color: Color) -> void:
	var font: Font = ArcadeUI.FONT
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	drawer.draw_string(font, at - Vector2(width / 2, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_controls() -> void:
	drawer.draw_rect(Rect2(0, 720, 960, 180), Color("101827"))
	drawer.draw_line(Vector2(0, 721), Vector2(960, 721), Color("38505b"), 2)
	drawer.draw_circle(CENTER, STICK_RADIUS + 8, Color("0a101d"))
	drawer.draw_arc(CENTER, STICK_RADIUS, 0, TAU, 64, Color(MINT, 0.45), 3)
	drawer.draw_line(CENTER - Vector2(45, 0), CENTER + Vector2(45, 0), Color("2a3b4b"), 2)
	drawer.draw_line(CENTER - Vector2(0, 45), CENTER + Vector2(0, 45), Color("2a3b4b"), 2)
	var knob := CENTER + stick * 40
	drawer.draw_line(CENTER, knob, Color("47636d"), 8)
	drawer.draw_circle(knob + Vector2(0, 4), 25, Color("080d17"))
	drawer.draw_circle(knob, 25, Color("345560") if stick_finger >= 0 else Color("263d4b"))
	drawer.draw_arc(knob, 25, 0, TAU, 40, MINT, 2)
	text_at("MOVER", Vector2(265, 807), 10, MINT)
	text_at("DOBLE TOQUE", Vector2(285, 830), 8, Color("98a3b9"))
	text_at("PARA CORRER", Vector2(285, 846), 8, Color("98a3b9"))
	for action in BUTTONS:
		var point: Vector2 = BUTTONS[action]
		var color := MINT if action != "ultimate" else Color("f7c47e")
		var held: bool = pressed_actions.has(action)
		drawer.draw_circle(point, BUTTON_RADIUS, Color("345560") if held else Color("1c2a3d"))
		drawer.draw_arc(point, BUTTON_RADIUS - 2, 0, TAU, 48, color, 4 if held else 2)
		var names := {"attack": "PEGAR", "jump": "SALTAR", "ultimate": "ULTI"}
		text_at(names[action], point + Vector2(0, 5), 10, color)
		if action == "ultimate":
			drawer.draw_arc(point, BUTTON_RADIUS - 7, -PI / 2, -PI / 2 + TAU * maxf(0.001, game.charge / 100), 48, color, 3)
	drawer.draw_style_box(pause_style(), PAUSE_RECT)
	text_at("SEGUIR" if game.state == "pause" else "PAUSA", PAUSE_RECT.get_center() + Vector2(0, 4), 9, MINT)

func pause_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c2a3d")
	style.border_color = Color("38505b")
	style.set_border_width_all(2)
	return style

func _exit_tree() -> void:
	release_all()
