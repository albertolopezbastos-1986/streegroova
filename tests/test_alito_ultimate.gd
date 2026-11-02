extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.active_character_id = "alito"
	game.new_run(true)
	await process_frame
	var hero = game.player
	assert(hero.visual.definition("ultimate")["frame_indices"] == range(9))
	assert(is_equal_approx(hero.visual.duration("ultimate"), 1.6))
	game.charge = 100
	hero.height = 50
	game.use_ultimate()
	assert(game.charge == 100 and game.ult_time == 0)
	hero.height = 0
	game.use_ultimate()
	assert(game.charge == 0 and not hero.ultimate_airborne)
	assert(hero.visual.motion == "ultimate" and hero.visual.source_frame == 0)
	assert(hero.visual.sheets["ultimate"].resource_path.ends_with("alito/animations/ultimate/ulti.png"))
	game.ult_time = 0.66
	hero.update_visual(0)
	assert(hero.visual.source_frame == 5, "ignition precedes the damage")
	game.update_game(0.02)
	assert(hero.visual.source_frame == 6 and game.ult_applied, "explosion coincides with damage")
	game.ult_time = 0.01
	hero.update_visual(0)
	assert(hero.visual.source_frame == 8, "recovery reaches the last frame")
	game.update_game(0.02)
	assert(hero.visual.motion == "idle")
	print("ALITO ULTIMATE PASSED: nine frames, grounded activation, explosion synchronized with damage, recovery")
	game.queue_free()
	await process_frame
	quit()
