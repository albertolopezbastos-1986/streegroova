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

func collect(game, hero) -> void:
	hero.attack_time = 0
	hero.cooldown = 0
	hero.begin_attack()
	check(hero.visual.motion == "pickup", "attack near food starts pickup placeholder")
	hero.tick(0.18)
	hero.tick(0.18)

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
	check(game.LEVEL_WIDTH == 4250 and game.WAVE_COUNT == 5, "each level has five waves")
	check(game.enemies[0].max_hp == 130 and game.enemies[2].max_hp == 84, "normal enemy health doubled")
	check(game.props.is_empty(), "full-health start has no unnecessary supplies")
	hero.hp = 20
	for i in range(100):
		if game.try_spawn_supply():
			break
	check(game.props.size() == 1, "injured player can receive one supply")
	var crate = game.props[0]
	crate.barrel = false
	check(not game.try_spawn_supply(), "unbroken supply prevents another spawn")
	hero.position = crate.position - Vector2(40, 0)
	hero.facing = 1
	hero.begin_attack()
	check(hero.attack_motion() == "runslide" and not hero.run_attack, "attacking a nearby supply uses slide art without forcing movement")
	hero.strike()
	check(crate.dead and game.food.size() == 1, "one hit destroys crate and drops food")
	hero.strike()
	check(game.food.size() == 1, "same attack cannot drop food twice")
	var pickup = game.food[0]
	check(not game.try_spawn_supply(), "uncollected food prevents supply stockpiling")
	hero.position = pickup.position
	hero.hp = 100
	game.update_supplies(0.016)
	check(not pickup.dead, "full-health player preserves pickup")
	hero.hp = 20
	hero.height = 30
	game.update_supplies(0.016)
	check(hero.hp == 20 and not pickup.dead, "airborne player cannot collect pickup")
	hero.height = 0
	pickup.beer = true
	game.update_supplies(0.016)
	check(hero.hp == 20 and not pickup.dead, "touching food no longer collects it")
	collect(game, hero)
	check(hero.hp == 70 and pickup.dead, "beer restores fifty percent of maximum health")
	game.update_supplies(0.016)
	check(hero.hp == 70, "consumed pickup cannot heal twice")
	var barrel = preload("res://scripts/breakable.gd").new()
	game.world.add_child(barrel)
	barrel.setup(game, hero.position + Vector2(40, 0), true)
	game.props.append(barrel)
	barrel.hurt(1, 1)
	check(barrel.dead and game.food.size() == 2, "metal barrel breaks with even one point of damage")
	game.food[1].beer = false
	hero.hp = 10
	hero.position = game.food[1].position
	collect(game, hero)
	check(hero.hp == 85, "sushi restores seventy-five percent of maximum health")
	game.drop_food(hero.position)
	game.food[-1].beer = false
	collect(game, hero)
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
			check(game.left_bound >= maxf(30, game.camera_peak_x - game.BACKTRACK_DISTANCE + 12), "backtracking follows the furthest camera advance")
			if game.stage == game.WAVE_COUNT - 1:
				var boss = game.enemies[-1]
				check(boss.is_boss and boss.visual.scale == Vector2(1.25, 1.25), "final wave boss is 25 percent larger than Beto")
				check(boss.max_hp == 520 and boss.hp == 520, "boss has double tier-three health")
		else:
			for i in range(140):
				game.update_game(0.016)
	check(game.state == "stage_clear", "first boss clear enters stage-clear intermission")
	game.new_run()
	await process_frame
	check(game.props.is_empty() and game.food.is_empty() and game.stage == 0, "restart clears loot and resets level")
	print("ALL ", checks, " LEVEL CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
