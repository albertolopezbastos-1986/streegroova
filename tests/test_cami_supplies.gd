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
	assert(not game.weapons_allowed())
	for kind in ["wood", "pipe"]:
		assert(game.spawn_weapon(game.player.position, kind) == null)
		game.debug_spawn_item(kind)
	assert(game.weapons.is_empty())
	game.weapon_spawn_waves.assign(range(game.WAVE_COUNT))
	for wave in range(game.WAVE_COUNT):
		game.stage = wave
		game.spawn_wave()
		assert(game.weapons.is_empty(), "no weapons spawn during any Cami wave")
	for kind in ["crate", "barrel"]:
		var count: int = game.props.size()
		game.debug_spawn_item(kind)
		assert(game.props.size() == count + 1)
		var prop = game.props[-1]
		var food_count: int = game.food.size()
		prop.hurt(1000, 1)
		assert(prop.dead and game.food.size() == food_count + 1, "Cami still gets food from breakables")
		var food = game.food[-1]
		game.player.position = food.position
		game.player.hp = 20
		assert(game.nearby_pickup(game.player) != null)
		game.player.begin_pickup(food)
		game.player.tick(game.player.visual.duration("pickup") * 0.51)
		assert(food.dead and game.player.hp > 20)
		game.player.tick(game.player.visual.duration("pickup"))
	assert(game.weapons.is_empty())
	game.active_character_id = "beto"
	game.new_run(true)
	await process_frame
	assert(game.weapons_allowed())
	assert(game.spawn_weapon(game.player.position, "pipe") != null)
	print("CAMI SUPPLIES PASSED: no weapons in waves/debug, crates and barrels still drop collectible food, Beto weapons preserved")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
