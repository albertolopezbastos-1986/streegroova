extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	assert(not game.enable_weapon_spawns)
	for trial in range(20):
		game.load_level()
		assert(game.weapon_spawn_waves.size() >= 1 and game.weapon_spawn_waves.size() <= 2)
		assert(game.weapons.is_empty())
		var expected: int = game.weapon_spawn_waves.size() if game.enable_weapon_spawns else 0
		for wave in range(game.WAVE_COUNT):
			game.stage = wave
			game.spawn_wave()
			var count: int = game.weapons.size()
			game.spawn_wave()
			assert(game.weapons.size() == count)
			for item in game.weapons:
				item.dead = true
			game.player.weapon = "pipe"
		assert(game.weapons.size() == expected)
		await process_frame
	print("ALL WEAPON SPAWN CHECKS PASSED: automatic weapons disabled, no replenishment")
	game.queue_free()
	await process_frame
	quit()
