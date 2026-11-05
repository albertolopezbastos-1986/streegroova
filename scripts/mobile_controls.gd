extends CanvasLayer

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const ACTIONS = ["left", "right", "up", "down", "attack", "jump", "ultimate"]
const CENTER := Vector2(130, 730)
const STICK_RADIUS := 64.0
const DEADZONE := 0.18
const BUTTON_RADIUS := 48.0
const BUTTONS = {"attack": Vector2(795, 690), "jump": Vector2(905, 690), "ultimate": Vector2(850, 770)}
const PAUSE_RECT := Rect2(435, 666, 90, 48)
const MINT := Color.WHITE

var stick_radius := STICK_RADIUS
var stick_center := CENTER
var buttons: Dictionary = BUTTONS.duplicate()
var pause_rect := PAUSE_RECT
var layout_size := Vector2.ZERO
var window_size := Vector2i.ZERO

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
		get_window().content_scale_size = Vector2i(960, 820)
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
		refresh_layout()
		call_deferred("refresh_layout")
	sync_visibility()

static func layout_for_size(size: Vector2) -> Dictionary:
	var width := size.x
	return {
		"stick": Vector2(minf(130, width * 0.20), 700),
		"stick_radius": minf(64, width * 0.16),
		"buttons": {"attack": Vector2(width - 165, 660), "jump": Vector2(width - 55, 660), "ultimate": Vector2(width - 110, 740)},
		"pause": Rect2(Vector2(minf(130, width * 0.20) - 32, 764), Vector2(64, 24))
	}

func refresh_layout() -> void:
	if not enabled:
		return
	window_size = get_window().size
	var logical_size := Vector2i(roundi(float(window_size.x) * 820.0 / maxf(1, window_size.y)), 820)
	get_window().content_scale_size = logical_size
	var size := Vector2(logical_size)
	if layout_size != size:
		release_all()
	layout_size = size
	var layout := layout_for_size(size)
	stick_center = layout["stick"]
	stick_radius = layout["stick_radius"]
	buttons = layout["buttons"]
	pause_rect = layout["pause"]
	# Existing menu controls keep their proportions and transformed touch targets.
	var menu_scale := minf(1, size.x / 960.0)
	for key in ["character_select", "ranking_panel", "debug_environment_select", "debug_items_menu", "concert_layer"]:
		var menu = game.get(key)
		if is_instance_valid(menu):
			if key == "character_select":
				menu.setup_mobile_layout(size)
				continue
			if key == "concert_layer":
				menu.transform = Transform2D.IDENTITY
				continue
			if key == "ranking_panel":
				menu.setup_mobile_layout(size)
				continue
			var screen = menu.get("screen") if key != "concert_layer" else null
			if screen is Control:
				screen.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
				screen.size = Vector2(960, 820)
			menu.transform = Transform2D(0, Vector2.ONE * menu_scale, 0, Vector2((size.x - 960 * menu_scale) / 2, (640 - 640 * menu_scale) / 2))
			if key == "character_select" and screen is Control and screen.get_child_count() > 0:
				var backdrop := screen.get_child(0) as ColorRect
				backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
				backdrop.position = -menu.transform.origin / menu_scale
				backdrop.size = size / menu_scale

func sync_visibility() -> void:
	var active: bool = enabled and game.state in ["play", "pause"] and not game.show_help and not game.ranking_panel.open
	drawer.visible = active
	if not active or game.state != "play":
		release_all()

func _process(_dt: float) -> void:
	if enabled and (window_size != get_window().size or layout_size != get_viewport().get_visible_rect().size):
		refresh_layout()
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
	stick = ((point - stick_center) / stick_radius).limit_length()
	var axis := Vector2.ZERO
	if stick.length() > DEADZONE:
		axis = stick.normalized() * ((stick.length() - DEADZONE) / (1.0 - DEADZONE))
	set_action("left", maxf(0, -axis.x))
	set_action("right", maxf(0, axis.x))
	set_action("up", maxf(0, -axis.y))
	set_action("down", maxf(0, axis.y))

func update_buttons() -> void:
	for action in buttons:
		var held := false
		for finger in fingers.values():
			if finger["role"] == action and finger["point"].distance_to(buttons[action]) <= BUTTON_RADIUS + 14:
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
	if event is InputEventScreenTouch and event.pressed and pause_rect.has_point(event.position):
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
				update_stick(stick_center)
			update_buttons()
			return true
		var role := ""
		if stick_finger == -1 and event.position.distance_to(stick_center) <= stick_radius + 24:
			role = "stick"
			stick_finger = event.index
		else:
			for action in buttons:
				if event.position.distance_to(buttons[action]) <= BUTTON_RADIUS:
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
	drawer.draw_rect(Rect2(0, 600, layout_size.x, 220), Color.BLACK)
	drawer.draw_line(Vector2(0, 601), Vector2(layout_size.x, 601), Color("626873"), 2)
	drawer.draw_circle(stick_center, stick_radius + 8, Color("0a101d"))
	drawer.draw_arc(stick_center, stick_radius, 0, TAU, 64, Color(MINT, 0.45), 3)
	drawer.draw_line(stick_center - Vector2(45, 0), stick_center + Vector2(45, 0), Color("2a3b4b"), 2)
	drawer.draw_line(stick_center - Vector2(0, 45), stick_center + Vector2(0, 45), Color("2a3b4b"), 2)
	var knob := stick_center + stick * 40
	drawer.draw_line(stick_center, knob, Color("737780"), 8)
	drawer.draw_circle(knob + Vector2(0, 4), 25, Color("080d17"))
	drawer.draw_circle(knob, 25, Color("656975") if stick_finger >= 0 else Color("303541"))
	drawer.draw_arc(knob, 25, 0, TAU, 40, MINT, 2)
	if layout_size.x >= 700:
		text_at("MOVER", Vector2(265, 697), 10, Color.WHITE)
		text_at("DOBLE TOQUE", Vector2(285, 720), 8, Color.WHITE)
		text_at("PARA CORRER", Vector2(285, 736), 8, Color.WHITE)
	for action in buttons:
		var point: Vector2 = buttons[action]
		var color := Color.WHITE
		var held: bool = pressed_actions.has(action)
		drawer.draw_circle(point, BUTTON_RADIUS, Color("345560") if held else Color("1c2a3d"))
		drawer.draw_arc(point, BUTTON_RADIUS - 2, 0, TAU, 48, color, 4 if held else 2)
		var names := {"attack": "PEGAR", "jump": "SALTAR", "ultimate": "ULTI"}
		text_at(names[action], point + Vector2(0, 5), 12, color)
		if action == "ultimate":
			drawer.draw_arc(point, BUTTON_RADIUS - 7, -PI / 2, -PI / 2 + TAU * maxf(0.001, game.charge / 100), 48, color, 3)
	drawer.draw_style_box(pause_style(), pause_rect)
	text_at("SEGUIR" if game.state == "pause" else "PAUSA", pause_rect.get_center() + Vector2(0, 4), 9, Color.WHITE)

func pause_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c2a3d")
	style.border_color = Color("38505b")
	style.set_border_width_all(2)
	return style

func _exit_tree() -> void:
	release_all()
