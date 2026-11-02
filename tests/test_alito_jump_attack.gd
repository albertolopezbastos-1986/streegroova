extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.active_character_id = "alito"
	game.new_run(true)
	await process_frame
	game.debug_spawn_enemy(0)
	var hero = game.player
	var enemy = game.enemies[-1]
	hero.position = Vector2(400, 390)
	hero.facing = 1
	hero.height = 50
	enemy.position = hero.position + Vector2(45, 0)
	enemy.hp = 1000
	enemy.invincible = 0
	hero.begin_attack()
	assert(hero.air_attack and hero.visual.motion == "jump_attack")
	assert(hero.visual.sheets["jump_attack"].resource_path.ends_with("alito/animations/jump_attack/flykick.png"))
	for step in range(5):
		hero.attack_time = hero.attack_duration * (1.0 - (step + 0.1) / 5.0)
		hero.update_visual(0)
		assert(hero.visual.source_frame == step + 5)
		assert(hero.attack_is_active() == (step == 4), "contact only at full extension")
	hero.strike()
	assert(enemy.hp < 1000 and enemy.thrown_time > 0)
	var hp: float = enemy.hp
	hero.strike()
	assert(enemy.hp == hp)
	hero.height = 0
	hero.jump_speed = 0
	hero.attack_time = 0
	hero.update_visual(0)
	assert(hero.visual.motion == "idle")
	print("ALITO FLYING KICK PASSED: frames 6–10, contact at extension, one launch, landing recovery")
	game.queue_free()
	await process_frame
	quit()
