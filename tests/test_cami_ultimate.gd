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
	var animation: Dictionary = hero.visual.definition("ultimate")
	assert(animation["frame_indices"] == range(17) + range(32, 41))
	assert(is_equal_approx(hero.visual.duration("ultimate"), 1.6))
	game.charge = 100
	game.use_ultimate()
	assert(not hero.ultimate_airborne and game.charge == 0)
	assert(hero.visual.sheets["ultimate"].resource_path.ends_with("cami/animations/ultimate/ulti.png"))
	for i in range(101):
		game.ult_time = 1.6 * (1.0 - i / 100.0)
		hero.update_visual(0)
		assert(hero.visual.motion == "ultimate")
		assert(not hero.visual.source_frame in range(17, 32), "frames with white scream effect never play")
	game.ult_time = 1.6 * (1.0 - 0.59)
	hero.update_visual(0)
	assert(hero.visual.source_frame == 16)
	assert(hero.visual.material == null, "ground ultimate keeps its own appearance")
	print("CAMI ULTIMATE PASSED: 26 clean frames, all white scream frames excluded, ground variant, timed impact")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
