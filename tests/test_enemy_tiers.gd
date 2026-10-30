extends SceneTree

var checks := 0

func check(value: bool, description: String) -> void:
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
	for tier in range(3):
		for aerial in [false, true]:
			game.new_run(true)
			await process_frame
			game.debug_spawn_enemy(tier)
			var hero = game.player
			var enemy = game.enemies[0]
			hero.position = Vector2(400, 420)
			hero.invincible = 0
			hero.height = 40 if aerial else 0
			enemy.position = Vector2(440, 420)
			enemy.facing = -1
			enemy.height = hero.height
			enemy.running = not aerial
			enemy.begin_attack()
			enemy.strike()
			var launches: bool = tier == 2 or (tier == 1 and aerial)
			check((hero.thrown_time > 0) == launches, "tier %d %s launch rule" % [tier + 1, "kick" if aerial else "slide"])
			check(hero.hp == 100 - [16, 10, 26][tier], "tier damage matches strength")
			check(enemy.max_hp == [130, 84, 260][tier], "tier health matches role")
			check(is_equal_approx(enemy.visual.scale.x, [1.0, 0.94, 1.113][tier]), "tier silhouette matches role")
	var fighter = preload("res://scripts/fighter.gd")
	check(fighter.ENEMY_SPEEDS[1] > fighter.ENEMY_SPEEDS[0] and fighter.ENEMY_SPEEDS[2] < fighter.ENEMY_SPEEDS[0], "pink is faster and red is slower")
	check(fighter.ENEMY_JUMP_INTERVALS[1] < fighter.ENEMY_SLIDE_INTERVALS[1], "pink favors kicks over slides")
	check(fighter.ENEMY_JUMP_INTERVALS[2] > fighter.ENEMY_SLIDE_INTERVALS[2], "red favors slides over jumps")
	game.new_run()
	await process_frame
	var hero = game.player
	hero.position.x = game.right_bound - 10
	game.camera_x = 900
	game.update_camera(0.016)
	var locked_max: float = game.right_bound - 960.0 / game.WORLD_ZOOM
	check(game.camera_x <= locked_max, "camera viewport cannot cross locked arena edge")
	for enemy in game.enemies:
		enemy.dead = true
	game.freeze = 0
	game.update_game(0.016)
	hero.position.x = 1000
	game.update_camera(0.1)
	check(game.camera_x > locked_max, "camera can advance after clearing the wave")
	print("ALL ", checks, " TIER AND CAMERA CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
