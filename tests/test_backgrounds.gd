extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game.LEVEL_COUNT == 3 and game.ENVIRONMENTS.size() == 6)
	var covered: Dictionary = {}
	var orders: Dictionary = {}
	seed(2563)
	for trial in range(50):
		var chosen: Array = game.choose_backgrounds()
		assert(chosen.size() == 3)
		assert(chosen[2] == game.FINAL_BACKGROUND_INDEX)
		assert(game.ENVIRONMENTS[chosen[2]]["id"] == "neon-bar")
		assert(chosen[0] != game.FINAL_BACKGROUND_INDEX and chosen[1] != game.FINAL_BACKGROUND_INDEX)
		var unique: Dictionary = {}
		for index in chosen:
			assert(index >= 0 and index < 6 and not unique.has(index))
			unique[index] = true
			covered[index] = true
		orders[str(chosen)] = true
	assert(covered.size() == 6 and orders.size() > 1)
	assert(game.ENVIRONMENT_TILE_WIDTH == 492 and game.ENVIRONMENT_SOURCE_SIZE == Vector2(1536, 1024))
	for environment_index in range(game.ENVIRONMENTS.size()):
		var environment: Dictionary = game.ENVIRONMENTS[environment_index]
		var count: int = environment["tiles"].size()
		assert(count == (1 if environment_index == 0 else 5))
		var images: Array[Image] = []
		var unique: Dictionary = {}
		for segment in range(count):
			var texture: Texture2D = game.environment_tile_texture(environment_index, segment)
			assert(texture.get_size() == game.PIXEL_STREET.get_size())
			assert(texture.get_size() == Vector2(1536, 1024))
			var image := texture.get_image()
			image.convert(Image.FORMAT_RGBA8)
			images.append(image)
			unique[hash(image.get_data())] = true
		assert(unique.size() == count)
		if count == 5:
			for segment in range(count):
				var right := images[segment].get_region(Rect2i(1408, 0, 128, 1024))
				var left := images[(segment + 1) % count].get_region(Rect2i(0, 0, 128, 1024))
				assert(right.get_data() == left.get_data())
		assert(game.environment_tile_texture(environment_index, 5) == game.environment_tile_texture(environment_index, 0))
		assert(game.environment_tile_texture(environment_index, -1) == game.environment_tile_texture(environment_index, count - 1))
		print("PASS: original-aspect environment and joins: ", environment["id"])
	game.new_run()
	await process_frame
	var chosen: Array = game.campaign_backgrounds.duplicate()
	for level in range(3):
		game.level_index = level
		game.load_level(63)
		assert(game.background_index == chosen[level])
		assert(game.campaign_backgrounds == chosen and game.player.hp == 63)
		assert(game.stage == 0 and game.enemies.size() == 3)
		assert(game.camera_x == 0 and game.right_bound == 850)
		for wave in range(5):
			game.stage = wave
			assert(game.background_index == chosen[level])
	for index in range(6):
		game.background_index = index
		game.queue_redraw()
		await process_frame
	game.new_run(true)
	assert(game.background_index == 0)
	print("ALL BACKGROUND CHECKS PASSED: two random stages, final bar, connected panoramas")
	game.queue_free()
	await process_frame
	quit()
