extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	game.simulate_mobile = true
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	await process_frame
	var controls = game.mobile_controls
	assert(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_IGNORE)
	assert(controls.BUTTON_RADIUS > 43)
	for size in [Vector2i(390, 844), Vector2i(360, 900), Vector2i(844, 390), Vector2i(768, 1024)]:
		root.size = size
		await process_frame
		await process_frame
		controls.refresh_layout()
		var viewport: Vector2 = game.get_viewport_rect().size
		assert(absf(viewport.y - 820) < 1)
		assert(absf(viewport.x / viewport.y - float(size.x) / size.y) < 0.01, "viewport fills the device without letterboxing")
		assert(is_equal_approx(game.screen_width(), viewport.x))
		for card in game.character_select.cards:
			var bounds: Rect2 = card.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, card.size)
			assert(bounds.position.x >= 0 and bounds.end.x <= viewport.x, "selection cards fit the mobile width")
		var buttons: Dictionary = controls.buttons
		assert(buttons.attack.x < buttons.jump.x)
		assert(buttons.ultimate.y > buttons.attack.y and buttons.ultimate.y > buttons.jump.y)
		assert(is_equal_approx(buttons.ultimate.x, (buttons.attack.x + buttons.jump.x) / 2))
		for action in buttons:
			var point: Vector2 = buttons[action]
			assert(point.x - controls.BUTTON_RADIUS >= 0 and point.x + controls.BUTTON_RADIUS <= viewport.x)
			assert(point.y - controls.BUTTON_RADIUS >= 640 and point.y + controls.BUTTON_RADIUS <= viewport.y)
			assert(point.distance_to(controls.stick_center) > controls.BUTTON_RADIUS + controls.stick_radius)
			for other in buttons:
				if other != action:
					assert(point.distance_to(buttons[other]) > controls.BUTTON_RADIUS * 2, "action buttons do not overlap")
		game.player.position.x = 1000
		game.camera_x = 0
		game.camera_peak_x = 0
		game.left_bound = 30
		game.right_bound = game.LEVEL_WIDTH
		game.player.velocity = Vector2.ZERO
		game.camera_direction = 1
		for i in range(200):
			game.update_camera(0.016)
		game.update_world_transform()
		assert(absf(game.world_to_screen(game.player.position).x - viewport.x * 300 / 960) < 0.1)
		var event := InputEventScreenTouch.new()
		event.index = 1
		event.position = buttons.attack
		event.pressed = true
		assert(controls.handle_input(event) and Input.is_action_pressed("attack"))
		controls.release_all()
		assert(not Input.is_action_pressed("attack"))
		print("PASS: mobile fills ", size, ", visible controls and responsive camera")
	print("MOBILE FRAMING PASSED")
	game.queue_free()
	await process_frame
	quit()
