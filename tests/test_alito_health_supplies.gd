extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var counts := {}
	for id in ["beto", "cami", "alito"]:
		game.active_character_id = id
		game.new_run(true)
		await process_frame
		var expected_hp := 200.0 if id == "alito" else 100.0
		assert(game.player.max_hp == expected_hp and game.player.hp == expected_hp)
		game.load_level(expected_hp - 25)
		assert(game.player.max_hp == expected_hp and game.player.hp == expected_hp - 25, "level changes preserve remaining health")
		game.load_level()
		assert(game.player.hp == expected_hp, "fresh level starts at the character maximum")
		game.debug_room = false
		game.player.hp = 20
		var crates := 0
		var barrels := 0
		for trial in range(1000):
			seed(10000 + trial)
			if game.try_spawn_supply():
				var prop = game.props.pop_back()
				if prop.barrel:
					barrels += 1
				else:
					crates += 1
				prop.free()
		counts[id] = [crates, barrels]
	assert(counts["beto"] == counts["cami"], "other characters keep supply frequency")
	assert(counts["alito"][1] == counts["beto"][1], "barrel frequency stays unchanged")
	var ratio: float = float(counts["alito"][0]) / counts["beto"][0]
	assert(ratio > 0.4 and ratio < 0.6, "Alito receives about half the crates")
	print("ALITO HEALTH/SUPPLIES PASSED: 200 HP, health preserved between levels, half crate frequency, barrels and other characters unchanged: ", counts)
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
