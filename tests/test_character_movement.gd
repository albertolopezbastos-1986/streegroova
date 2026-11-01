extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for character_id in ["beto", "cami", "alito"]:
		game.active_character_id = character_id
		game.new_run(true)
		await process_frame
		var hero = game.player
		var multiplier := 0.9 if character_id == "alito" else 1.0
		for action in ["right", "left", "up", "down"]:
			for sprint in [false, true]:
				hero.reset_running()
				hero.position = Vector2(350, 390)
				hero.running = sprint
				hero.previous_horizontal = -1 if action == "left" else (1 if action == "right" else 0)
				Input.action_press(action)
				var start: Vector2 = hero.position
				hero.player_control(0.2)
				Input.action_release(action)
				var base_speed: float = game.DEPTH_SPEED if action in ["up", "down"] else (hero.RUN_SPEED if sprint else hero.WALK_SPEED)
				var walk_multiplier := 0.75 if character_id == "cami" and (not sprint or action in ["up", "down"]) else 1.0
				var run_multiplier := 0.75 if character_id == "cami" and hero.running else 1.0
				assert(is_equal_approx(hero.position.distance_to(start), base_speed * multiplier * walk_multiplier * run_multiplier * 0.2), "%s %s sprint=%s travels the expected distance" % [character_id, action, sprint])
		hero.reset_running()
		assert(hero.takeoff(Vector2.ZERO))
		var expected_height_multiplier := 0.5 if character_id == "alito" else 0.85
		var normal_peak := 1.0 + 420.0 * 420.0 / 1900.0
		var peak: float = hero.height + hero.jump_speed * hero.jump_speed / 1900.0
		assert(is_equal_approx(peak, normal_peak * expected_height_multiplier), character_id + " has the expected jump height")
		print("PASS: ", character_id, " walk/run distance in all four directions")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("CHARACTER MOVEMENT: 24 distance checks passed")
	quit()
