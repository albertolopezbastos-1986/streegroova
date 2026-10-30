extends SceneTree

var checks := 0

func check(value: bool, description: String) -> void:
	if not value:
		push_error("FAIL: " + description)
		quit(1)
		assert(value, description)
	checks += 1
	print("PASS: ", description)

func touch(index: int, point: Vector2, pressed := true) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	return event

func drag(index: int, point: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	return event

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	game.simulate_mobile = false
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	await process_frame
	var controls = game.mobile_controls
	check(not controls.enabled and not controls.drawer.visible, "desktop hides mobile controls")
	game._input(touch(0, controls.CENTER))
	check(not controls.drawer.visible and not Input.is_action_pressed("left"), "desktop touch does not enable mobile overlay")
	controls.setup(game, true)
	game.touch_visible = true
	check(get_root().content_scale_size == Vector2i(960, 820), "mobile reserves a separate lower control deck")
	check(controls.drawer.visible, "mobile gameplay shows controls")
	check(not controls.handle_input(touch(8, Vector2(480, 250), false)), "unclaimed touches remain available to debug UI buttons")
	var center: Vector2 = controls.CENTER
	game._input(touch(0, center))
	check(Input.get_vector("left", "right", "up", "down") == Vector2.ZERO, "joystick center has a deadzone")
	game._input(drag(0, center + Vector2(40, -40)))
	check(Input.is_action_pressed("right") and Input.is_action_pressed("up"), "joystick supports diagonal movement")
	game._input(touch(1, controls.BUTTONS.attack))
	game._input(touch(2, controls.BUTTONS.jump))
	check(Input.is_action_pressed("right") and Input.is_action_pressed("attack") and Input.is_action_pressed("jump"), "stick and two buttons work simultaneously")
	game._input(touch(1, controls.BUTTONS.attack, false))
	check(not Input.is_action_pressed("attack") and Input.is_action_pressed("jump"), "releasing one finger preserves the others")
	game._input(touch(2, controls.BUTTONS.jump, false))
	game._input(drag(0, center + Vector2(400, 0)))
	check(Input.get_action_strength("right") == 1 and controls.stick.length() <= 1, "captured stick clamps when finger leaves its base")
	game._input(touch(0, center, false))
	check(controls.stick == Vector2.ZERO and not Input.is_action_pressed("right"), "releasing stick recenters and stops movement")
	await process_frame
	# Full input path for running: press, release, press and hold.
	game._input(touch(0, center + Vector2(64, 0)))
	game.player.tick(0.016)
	game._input(touch(0, center, false))
	game.player.tick(0.016)
	game._input(touch(0, center + Vector2(64, 0)))
	game.player.tick(0.016)
	check(game.player.running, "double tap and hold joystick starts running")
	game._input(touch(1, controls.BUTTONS.attack))
	game.player.tick(0.016)
	check(game.player.run_attack, "mobile attack while running starts sliding attack")
	game._input(touch(3, controls.PAUSE_RECT.get_center()))
	check(game.state == "pause" and controls.fingers.is_empty() and not Input.is_action_pressed("right") and not Input.is_action_pressed("attack"), "pause releases all held mobile actions")
	game._input(touch(3, controls.PAUSE_RECT.get_center()))
	check(game.state == "play", "mobile pause button resumes the game")
	game._input(touch(0, center + Vector2(-64, 0)))
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state == "pause" and not Input.is_action_pressed("left"), "backgrounding app clears held controls")
	game.state = "play"
	game._input(touch(0, center + Vector2(64, 0)))
	game.show_character_selection()
	controls.sync_visibility()
	check(not controls.drawer.visible and not Input.is_action_pressed("right"), "selection hides deck and clears joystick")
	game.confirm_character(0)
	game.update_level_transition(game.FADE_DURATION)
	game.update_level_transition(game.BLACK_HOLD_DURATION)
	game.update_level_transition(game.FADE_DURATION)
	game.update_level_transition(5)
	game.update_level_transition(game.START_DURATION)
	controls.sync_visibility()
	game._input(touch(1, controls.BUTTONS.ultimate))
	check(Input.is_action_pressed("ultimate"), "ultimate has its own touch button")
	game._input(drag(1, center))
	check(not Input.is_action_pressed("ultimate") and controls.stick_finger == -1, "button drag cannot take over joystick")
	var canceled := touch(1, center)
	canceled.canceled = true
	game._input(canceled)
	check(controls.fingers.is_empty(), "cancelled touch is cleaned up")
	controls.release_all()
	Input.action_press("left")
	controls.release_all()
	check(Input.is_action_pressed("left"), "idle mobile cleanup preserves keyboard input")
	Input.action_release("left")
	print("ALL ", checks, " MOBILE CONTROL CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
