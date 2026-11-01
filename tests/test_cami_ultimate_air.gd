extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.active_character_id = "cami"
	game.new_run(true)
	await process_frame
	var hero = game.player
	var animation: Dictionary = hero.visual.definition("ultimate_air")
	assert(animation["frame_indices"] == range(23) + range(31, 41))
	assert(is_equal_approx(hero.visual.duration("ultimate_air"), 1.6))
	hero.height = 50
	game.charge = 100
	game.use_ultimate()
	assert(hero.ultimate_airborne and game.charge == 0)
	assert(hero.visual.sheets["ultimate_air"].resource_path.ends_with("cami/animations/ultimate_air/ultiair.png"))
	for i in range(101):
		game.ult_time = 1.6 * (1.0 - i / 100.0)
		hero.update_visual(0)
		assert(hero.visual.motion == "ultimate_air")
		assert(not hero.visual.source_frame in range(23, 31), "explosion frames never play")
	game.ult_time = 1.6 * (1.0 - 0.59)
	hero.update_visual(0)
	assert(hero.visual.source_frame == 22, "clean impact pose matches the ultimate impact time")
	hero.height = 0
	hero.update_visual(0)
	assert(hero.visual.motion == "ultimate_air", "landing does not switch the chosen ultimate variant")
	hero.ultimate_pose = 0
	hero.update_visual(0)
	assert(hero.visual.motion == "idle" and hero.visual.material == null)
	print("CAMI AIR ULTIMATE PASSED: own art, 33 clean frames, no explosions, timed impact and landing continuity")
	for direction in [1.0, -1.0]:
		for delta in [0.016, 0.08]:
			game.ult_time = 0
			game.freeze = 0
			game.charge = 100
			hero.position = Vector2(350, 390)
			hero.height = 50
			hero.jump_speed = 0
			hero.facing = direction
			game.use_ultimate()
			var last_x: float = hero.position.x
			var last_height: float = hero.height
			while game.ult_time > 0:
				game.update_game(delta)
				assert((hero.position.x - last_x) * direction <= 0.001, "recoil always moves backward")
				assert(hero.height >= last_height, "recoil rises smoothly without snapping down")
				if (1.6 - game.ult_time) / 1.6 <= 0.4:
					assert(is_equal_approx(hero.position.x, 350) and is_equal_approx(hero.height, 50), "no movement before the scream")
				last_x = hero.position.x
				last_height = hero.height
			assert(is_equal_approx(hero.position.x, 350 - direction * 18), "scream retreats 18 units in either facing")
			assert(is_equal_approx(hero.height, 66), "scream lifts Cami 16 units")
	print("CAMI SCREAM RECOIL PASSED: delayed smooth diagonal impulse, both facings, frame-rate independent, no end snap")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
