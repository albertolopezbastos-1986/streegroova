extends SceneTree

var game: Node2D
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
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var offline_ranking = preload("res://tests/mock_online.gd").new()
	game.add_child(offline_ranking)
	game.ranking_panel.service = offline_ranking
	game.set_process(false)
	await process_frame
	check(game.state == "title", "boots to title")
	game.new_run()
	await process_frame
	check(game.lives == 3 and game.enemies.size() == 3, "new run has three lives and first wave")
	var hero = game.player
	Input.action_press("jump")
	hero.tick(0.016)
	check(hero.height > 0 and hero.velocity == Vector2.ZERO, "neutral jump has no horizontal movement")
	Input.action_release("jump")
	await process_frame
	for i in range(90):
		hero.tick(0.016)
	check(hero.height == 0, "jump lands on the floor")
	Input.action_press("right")
	Input.action_press("jump")
	hero.tick(0.016)
	check(hero.height > 0 and hero.velocity.x > 0, "direction plus jump preserves forward momentum")
	Input.action_release("jump")
	Input.action_release("right")
	await process_frame
	hero.tick(0.016)
	check(hero.velocity.x > 0, "releasing direction does not cancel a forward jump")
	hero.height = 60
	hero.jump_speed = 0
	hero.cooldown = 0
	hero.begin_attack()
	check(hero.air_attack, "attack in air becomes flying kick")
	var enemy = game.enemies[0]
	enemy.position = hero.position + Vector2(45, 0)
	enemy.invincible = 0
	var before: float = enemy.hp
	hero.strike()
	check(enemy.hp < before, "flying kick damages enemy in reach")
	var after: float = enemy.hp
	hero.strike()
	check(enemy.hp == after, "one attack cannot repeatedly damage the same target")
	hero.height = 0
	hero.invincible = 0
	enemy.stun = 0
	enemy.position = hero.position + Vector2(45, 0)
	game.combat_director.turns[enemy] = 999.0
	var telegraphed := false
	for i in range(140):
		enemy.tick(0.016)
		telegraphed = telegraphed or enemy.windup > 0
	check(telegraphed and hero.hp < 100, "enemy AI telegraphs then attacks the player")
	hero.hp = 100
	hero.height = 80
	hero.invincible = 0
	enemy.begin_attack()
	enemy.strike()
	check(hero.hp == 100, "jumping above a ground attack evades it")
	hero.height = 0
	hero.attack_time = 0
	hero.invincible = 0
	var health: float = hero.hp
	hero.hurt(10, -1)
	check(hero.hp == health - 10 and game.charge > 0, "incoming hit removes health and builds ultimate")
	hero.hurt(10, -1)
	check(hero.hp == health - 10, "player has invulnerability after damage")
	game.charge = 99
	game.use_ultimate()
	check(game.ult_time == 0, "ultimate cannot activate before full charge")
	game.charge = 100
	game.use_ultimate()
	check(game.ult_time > 0 and game.charge == 0, "ultimate consumes full meter")
	game.freeze = 0
	var healths: Array = game.enemies.map(func(e): return e.hp)
	for i in range(110):
		game.update_game(0.016)
	for i in range(game.enemies.size()):
		check(game.enemies[i].hp < healths[i], "ultimate damages enemy %d regardless of distance" % i)
	check(hero.hp == health - 10, "ultimate pose protects player")
	game.freeze = 0
	hero.invincible = 0
	hero.hurt(1000, 1)
	for i in range(110):
		game.update_game(0.016)
	check(game.lives == 2 and not hero.dead and hero.hp == 100, "losing life respawns with full health")
	for wave in range(game.WAVE_COUNT):
		for target in game.enemies:
			target.dead = true
		game.freeze = 0
		if wave < game.WAVE_COUNT - 1:
			game.update_game(0.016)
			hero.position.x = (wave + 1) * 850 + 100
			game.update_game(0.016)
			check(game.stage == wave + 1, "cleared wave unlocks next street section")
		else:
			for i in range(150):
				game.update_game(0.016)
	check(game.state == "won", "clearing final wave ends level in victory")
	game.new_run()
	await process_frame
	check(game.state == "play" and game.stage == 0 and game.lives == 3, "restart resets run")
	for life in range(3):
		game.player.invincible = 0
		game.player.hurt(1000, 1)
		game.freeze = 0
		for i in range(100):
			if game.state == "play":
				game.update_game(0.016)
	check(game.state == "over" and game.lives == 0, "three deaths end the run")
	print("ALL ", checks, " GAMEPLAY CHECKS PASSED")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
