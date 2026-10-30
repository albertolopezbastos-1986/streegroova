extends SceneTree

var checks := 0

func check(value: bool, description: String) -> void:
	if not value:
		push_error("FAIL: " + description)
		quit(1)
		assert(value, description)
	checks += 1
	print("PASS: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var offline = preload("res://tests/mock_online.gd").new()
	game.add_child(offline)
	game.ranking_panel.service = offline
	game.new_run()
	await process_frame
	var id: String = game.run_id
	game.player.hp = 63
	game.lives = 2
	game.charge = 75
	for level in range(3):
		check(game.level_index == level and game.stage == 0 and game.state == "play", "level %d starts at wave one" % (level + 1))
		for wave in range(game.WAVE_COUNT):
			check(game.stage == wave, "level %d wave %d is reachable" % [level + 1, wave + 1])
			if wave == game.WAVE_COUNT - 1:
				check(game.enemies[-1].is_boss, "each level has its final boss")
			for enemy in game.enemies:
				enemy.dead = true
			game.score += 100
			game.freeze = 0
			if wave < game.WAVE_COUNT - 1:
				game.update_game(0.016)
				game.player.position.x = (wave + 1) * game.SECTION_WIDTH + 100
				game.update_game(0.016)
			else:
				game.update_game(2.1)
		check(not game.ranking_panel.open, "clearing a level does not prematurely open ranking")
		if level < 2:
			check(game.state == "stage_clear", "intermediate clear enters arcade intermission")
			var event := InputEventKey.new()
			event.physical_keycode = KEY_ENTER
			event.pressed = true
			game._input(event)
			check(game.state == "stage_clear", "held start cannot restart campaign during intermission")
			game.update_presentation(game.STAGE_CLEAR_DURATION - 0.1)
			check(game.level_index == level and game.state == "stage_clear", "intermission stays on screen for its duration")
			game.update_presentation(0.11)
			check(game.state == "play" and game.enemies.size() == 3 and game.props.size() == 2 and game.food.is_empty(), "next level reloads its enemies and supplies")
			check(game.player.hp == 63 and game.lives == 2 and game.charge == 75 and game.score == (level + 1) * game.WAVE_COUNT * 100, "next level preserves health lives ultimate and accumulated score")
			check(game.run_id == id and game.active_character_id == "beto", "all levels share a single run and character")
			check(game.camera_x == 0 and game.left_bound == 30 and game.right_bound == 850 and game.player.position.y == game.START_Y, "next level resets camera and starting bounds")
	check(game.state == "victory" and game.level_index == 2, "third level clear enters final celebration")
	check(game.player.visual.motion == "jump" and game.player.victory_time == 0, "victory uses jump until dedicated art exists")
	game.update_presentation(0.1)
	check(game.player.visual.position.y < 0 and game.player.height == 0, "victory placeholder animates without restarting combat")
	check(not game.ranking_panel.open, "ranking waits for victory animation")
	game.update_presentation(game.VICTORY_DURATION)
	check(game.state == "won" and game.ranking_panel.open, "ranking opens after celebration completes")
	check(game.ranking_panel.heading.text == "CONGRATULATIONS!" and game.ranking_panel.points == game.LEVEL_COUNT * game.WAVE_COUNT * 100 and game.ranking_panel.pending_id == id, "final ranking contains entire campaign score")
	game.new_run(true)
	for enemy in game.enemies:
		enemy.dead = true
	game.update_game(4)
	check(game.state == "play" and game.level_index == 0, "debug room does not trigger campaign completion")
	game.new_run()
	check(game.level_index == 0 and game.stage == 0 and game.score == 0 and game.lives == 3 and game.player.victory_time < 0, "new campaign resets level progress and victory animation")
	print("ALL ", checks, " CAMPAIGN CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
