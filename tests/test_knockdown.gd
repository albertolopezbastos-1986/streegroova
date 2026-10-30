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
	game.new_run(true)
	await process_frame
	var hero = game.player
	game.debug_spawn_enemy(0)
	var enemy = game.enemies[0]
	hero.position = Vector2(350, 420)
	hero.invincible = 0
	enemy.position = Vector2(410, 420)
	hero.facing = 1
	hero.running = true
	hero.begin_attack()
	hero.strike()
	check(enemy.thrown_time > 0 and enemy.height == 25 and enemy.velocity.x == enemy.THROW_SPEED, "player slide launches enemy with throw physics")
	check(enemy.visual.motion == "death" and not enemy.dead, "living enemy uses falling animation")
	var hp: float = enemy.hp
	hero.strike()
	check(enemy.hp == hp, "slide cannot damage its victim twice")
	for i in range(120):
		enemy.tick(0.016)
		if enemy.getup_time > 0:
			break
	check(enemy.height == 0 and enemy.getup_time > 0 and enemy.visual.motion == "jump", "survivor lands then uses jump as get-up placeholder")
	check(not enemy.takeoff(Vector2.ZERO), "get-up cannot be interrupted by jumping")
	var at: Vector2 = enemy.position
	for i in range(10):
		enemy.tick(0.016)
	check(enemy.position == at and not enemy.dead, "survivor stays grounded during get-up")
	for i in range(20):
		enemy.tick(0.016)
	check(enemy.getup_time == 0 and enemy.thrown_time == 0, "survivor returns to normal controls")
	# Isolate the AI's decision from the director's scheduling.
	hero.attack_time = 0
	hero.cooldown = 0
	hero.reset_running()
	hero.hp = 100
	hero.position = Vector2(350, 420)
	hero.invincible = 0
	enemy.position = Vector2(370, 420)
	enemy.facing = -1
	enemy.invincible = 0
	enemy.stun = 0
	enemy.ai_wait = 0
	enemy.cooldown = 0
	enemy.ai_special_cooldown = 0
	game.combat_director.turns[enemy] = 999.0
	enemy.tick(0.016)
	check(enemy.grapple.active() and hero.grabbed_by == enemy, "AI chooses a close-range grab")
	check(hero.visual.motion == "hurt", "captured player displays held damage pose")
	var launched := false
	for i in range(95):
		enemy.tick(0.016)
		if hero.thrown_time > 0:
			launched = true
			break
	check(launched and hero.hp == 60 and hero.velocity.x > 0, "AI automatically throws player for forty damage")
	check(hero.visual.motion == "death" and not hero.dead, "thrown player falls without losing a life")
	check(not hero.can_use_ultimate(), "fall cannot be cancelled by ultimate")
	var player_hp: float = hero.hp
	hero.hurt(5, 1)
	check(hero.hp == player_hp, "grounded recovery cannot be stun-locked by more hits")
	for i in range(120):
		hero.tick(0.016)
		if hero.getup_time > 0:
			break
	check(hero.getup_time > 0 and hero.visual.motion == "jump" and hero.height == 0, "player also uses grounded get-up animation")
	for i in range(30):
		hero.tick(0.016)
	check(hero.getup_time == 0 and hero.invincible > 0 and game.lives == 3, "player gets up with remaining health and brief protection")
	# An available committed enemy at range warns, runs, and slides autonomously.
	enemy.grapple.release()
	enemy.reset_running()
	enemy.attack_time = 0
	enemy.stun = 0
	enemy.windup = 0
	enemy.cooldown = 0
	enemy.ai_wait = 0
	enemy.ai_special_cooldown = 0
	enemy.height = 0
	hero.invincible = 0
	hero.position = Vector2(350, 420)
	enemy.position = Vector2(510, 420)
	game.combat_director.turns[enemy] = 999.0
	enemy.tick(0.016)
	check(enemy.rush_windup > 0 and not enemy.running, "enemy telegraphs its running approach")
	var ran := false
	var slid := false
	for i in range(90):
		enemy.tick(0.016)
		ran = ran or enemy.running
		slid = slid or enemy.run_attack
		if hero.thrown_time > 0:
			break
	check(ran and slid, "AI runs and performs sliding first punch")
	check(hero.thrown_time > 0 and hero.visual.motion == "death" and hero.hp < 60, "enemy slide launches player and starts knockdown")
	# Lethal launches retain KO and never enter get-up.
	hero.thrown_time = 0
	hero.getup_time = 0
	hero.invincible = 0
	hero.hp = 1
	hero.launch_away(10, 1)
	for i in range(110):
		hero.tick(0.016)
	check(hero.dead and hero.getup_time == 0 and hero.visual.motion == "death", "lethal launch stays KO instead of getting up")
	print("ALL ", checks, " KNOCKDOWN CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
