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
	for tier in range(4):
		game.new_run(true)
		await process_frame
		game.debug_spawn_enemy(mini(tier, 2), tier == 3)
		var enemy = game.enemies[0]
		enemy.launch_away(1, 1, false, null, true)
		for i in range(180):
			enemy.tick(0.016)
			if enemy.getup_time > 0:
				break
		check(enemy.getup_time > 0 and enemy.invincible == 0, "enemy recovery grants no invulnerability")
		var hp: float = enemy.hp
		enemy.hurt(1, -1)
		check(enemy.hp == hp - 1 and enemy.getup_time == 0 and enemy.visual.motion == "hurt", "hit interrupts get-up immediately")
		enemy.getup_time = 0.2
		enemy.invincible = 0
		check(enemy.launch_away(1, -1, true, null, true), "ultimate can relaunch an enemy during get-up")
	var attack_counts: Array[int] = []
	for boss_mode in [false, true]:
		game.new_run(true)
		await process_frame
		game.debug_spawn_enemy(2, boss_mode)
		var hero = game.player
		var enemy = game.enemies[0]
		hero.position = Vector2(400, 420)
		hero.invincible = 999
		enemy.position = Vector2(440, 420)
		enemy.ai_wait = 0
		enemy.ai_jump_cooldown = 999
		enemy.ai_slide_cooldown = 999
		enemy.ai_special_cooldown = 999
		game.combat_director.turns[enemy] = 999
		game.combat_director.sides[enemy] = 1.0
		var attacks := 0
		for i in range(900):
			var before: float = enemy.attack_time
			enemy.tick(0.016)
			if before <= 0 and enemy.attack_time > 0:
				attacks += 1
		attack_counts.append(attacks)
	check(attack_counts[1] > attack_counts[0] * 1.5, "boss attacks at least fifty percent more often than tier three")
	game.new_run(true)
	await process_frame
	game.debug_spawn_enemy(0, true)
	var hero = game.player
	var boss = game.enemies[0]
	hero.position = Vector2(400, 390)
	hero.facing = 1
	boss.position = Vector2(440, 390)
	hero.begin_attack()
	boss.tick(0.016)
	check(boss.boss_dodge_time > 0 and boss.position.y != hero.position.y, "boss sidesteps a nearby incoming attack")
	check(boss.invincible == 0, "boss dodge adds no invulnerability")
	var hp: float = boss.hp
	hero.strike()
	check(boss.hp < hp, "boss remains hittable before moving out of reach")
	# The director gives a boss another chance quickly without bypassing reservations.
	boss.stun = 0
	boss.boss_dodge_time = 0
	boss.attack_time = 0
	boss.windup = 0
	boss.height = 0
	boss.grapple.release()
	hero.attack_time = 0
	hero.invincible = 0
	var director = game.combat_director
	director.turns[boss] = director.clock - 1
	director.next_turn = 0
	director.update(0.016)
	check(float(director.rested_until[boss]) - director.clock <= 0.35, "boss has short rest between reserved turns")
	print("Attack counts tier 3 / boss: ", attack_counts)
	print("ALL ", checks, " BOSS AGGRESSION CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
