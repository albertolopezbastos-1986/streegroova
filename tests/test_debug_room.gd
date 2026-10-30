extends SceneTree

func key(code: Key, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	return event

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.show_character_selection()
	game._input(key(KEY_TAB))
	assert(game.state == "debug_select" and game.debug_environment_select.open and not game.character_select.open)
	assert(game.debug_environment_select.buttons.size() == 6)
	game._input(key(KEY_2))
	assert(game.debug_room and game.state == "play" and not game.character_select.open)
	assert(game.background_index == 1)
	assert(game.enemies.is_empty())
	game.update_game(0.04)
	assert(game.transition == 0 and game.stage == 0)
	for code in [KEY_1, KEY_2, KEY_3]:
		game._input(key(code))
		assert(game.active_character_id == ["beto", "cami", "alito"][code - KEY_1])
		assert(game.player.hp == game.player.max_hp)
	for code in [KEY_4, KEY_5, KEY_6, KEY_7]:
		game._input(key(code))
	assert(game.enemies.size() == 4)
	assert(game.enemies[0].kind == 0 and game.enemies[1].kind == 1 and game.enemies[2].kind == 2)
	assert(game.enemies[3].is_boss and game.enemies[3].hp == 520)
	# Debug travel and camera remain open beyond the campaign's end, even with enemies.
	assert(is_inf(game.right_bound))
	for distance in [game.LEVEL_WIDTH * 2, game.LEVEL_WIDTH * 10]:
		game.player.position.x = distance
		game.player.tick(0.016)
		assert(game.player.position.x >= distance - 1)
		game.update_camera(2.0)
		assert(game.camera_x > distance - 960.0 / game.WORLD_ZOOM)
		game.queue_redraw()
		await process_frame
	game.player.position.x = 240
	game.camera_x = 0
	game._input(key(KEY_4, true))
	assert(game.enemies.size() == 4)
	for i in range(30):
		game._input(key(KEY_7))
	assert(game.enemies.size() == 34)
	game._input(key(KEY_8))
	assert(game.charge == 100)
	game._input(key(KEY_9))
	assert(game.enemies.size() >= 37 and game.enemies.size() <= 41)
	game._input(key(KEY_0))
	assert(game.enemies.all(func(enemy): return enemy.dead))
	game.freeze = 0
	game.update_game(0.04)
	assert(game.transition == 0 and game.stage == 0 and game.state == "play")
	game.player.invincible = 0
	game.player.hurt(100, 1)
	game.freeze = 0
	game.lives = 1
	game.respawn_time = 1.5
	game.update_game(0.04)
	assert(not game.player.dead and game.lives == 3 and game.state == "play")
	game._input(key(KEY_TAB))
	assert(game.state == "select" and not game.debug_room)
	game.confirm_character(0)
	game.update_level_transition(game.FADE_DURATION)
	assert(not game.debug_room and game.enemies.size() == 3)
	assert(game.right_bound == 850)
	game.player.position.x = game.LEVEL_WIDTH * 2
	game.update_camera(2.0)
	assert(game.camera_x <= 850 - 960.0 / game.WORLD_ZOOM)
	for index in range(6):
		game.open_debug_environment_selection()
		game.debug_environment_select.buttons[index].pressed.emit()
		assert(game.debug_room and game.state == "play" and game.background_index == index)
	game.open_debug_environment_selection()
	game._input(key(KEY_ESCAPE))
	assert(game.state == "select" and game.character_select.open and not game.debug_room)
	assert(game.environment_tile_texture(0, 0) == game.PIXEL_STREET)
	print("ALL DEBUG ROOM CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
