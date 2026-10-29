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
	var hero = game.player
	check(is_equal_approx(game.WORLD_ZOOM, 2.625 * 0.75), "zoom reduced exactly 25 percent")
	check(game.LEVEL_WIDTH == 8500 and game.WAVE_COUNT == 10, "long level has ten waves")
	check(game.enemies[0].max_hp == 130 and game.enemies[2].max_hp == 84, "normal enemy health doubled")
	check(game.props.size() == 2 and not game.props[0].barrel and game.props[1].barrel, "section contains crate and barrel")
	var crate = game.props[0]
	hero.position = crate.position - Vector2(40, 0)
	hero.facing = 1
	hero.begin_attack()
	hero.strike()
	check(crate.hp == 19 and not crate.dead, "player punch damages crate")
	hero.strike()
	check(crate.hp == 19, "same punch cannot damage crate twice")
	hero.begin_attack()
	hero.strike()
	check(crate.dead and game.food.size() == 1, "breaking crate drops a chicken")
	var chicken = game.food[0]
	hero.position = chicken.position
	hero.hp = 100
	game.update_supplies(0.016)
	check(not chicken.dead, "full-health player preserves food")
	hero.hp = 20
	hero.height = 30
	game.update_supplies(0.016)
	check(hero.hp == 20 and not chicken.dead, "airborne player cannot collect food")
	hero.height = 0
	game.update_supplies(0.016)
	check(hero.hp == 70 and chicken.dead, "walking onto chicken heals 50 and consumes it")
	game.update_supplies(0.016)
	check(hero.hp == 70, "consumed chicken cannot heal twice")
	var barrel = game.props[1]
	barrel.hurt(100, 1)
	check(barrel.dead and game.food.size() == 2, "barrel also drops food")
	hero.hp = 85
	hero.position = game.food[1].position
	game.update_supplies(0.016)
	check(hero.hp == 100, "food healing caps at maximum energy")
	hero.hp = 37
	for wave in range(game.WAVE_COUNT):
		for enemy in game.enemies:
			enemy.dead = true
		game.freeze = 0
		if wave < game.WAVE_COUNT - 1:
			game.update_game(0.016)
			hero.position.x = (wave + 1) * game.SECTION_WIDTH + 100
			game.update_game(0.016)
			check(game.stage == wave + 1 and hero.hp == 37, "wave %d unlocks without healing" % (wave + 2))
			check(game.left_bound == maxf(30, game.stage * game.SECTION_WIDTH - 700), "backtracking retains 700 units of previous section")
			if game.stage == 9:
				var boss = game.enemies[-1]
				check(boss.is_boss and boss.visual.scale == Vector2(2, 2), "final wave boss is twice normal size")
				check(boss.max_hp == 390 and boss.hp == 390, "boss has triple standard enemy health")
		else:
			for i in range(140):
				game.update_game(0.016)
	check(game.state == "won", "victory occurs after final boss wave")
	game.new_run()
	await process_frame
	check(game.props.size() == 2 and game.food.is_empty() and game.stage == 0, "restart clears loot and resets level")
	print("ALL ", checks, " LEVEL CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
