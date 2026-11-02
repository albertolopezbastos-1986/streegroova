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
	var hero = game.player
	assert(hero.player_combo().size() == 2 and int(hero.player_combo()[0]) == 1 and int(hero.player_combo()[1]) == 2)
	for direction in [1.0, -1.0]:
		game.debug_spawn_enemy(0)
		var enemy = game.enemies[-1]
		hero.position = Vector2(400, 390)
		hero.facing = direction
		hero.combo_window = 0
		enemy.position = hero.position + Vector2(direction * 45, 0)
		enemy.hp = 1000
		enemy.invincible = 0
		hero.begin_attack()
		hero.tick(0.23)
		assert(hero.combo == 0 and hero.combo_connected and enemy.thrown_time == 0)
		enemy.invincible = 0 # Enemy simulation is paused in this isolated contact test.
		hero.begin_attack()
		assert(hero.combo == 1 and hero.is_combo_finisher())
		assert(hero.visual.motion == "attack_02")
		assert(hero.visual.sheets["attack_02"].resource_path.ends_with("alito/animations/attack_02/punch2.png"))
		hero.tick(0.1)
		assert(enemy.thrown_time == 0)
		hero.tick(0.1)
		assert(enemy.thrown_time > 0 and enemy.jump_speed > 0)
		assert(enemy.velocity.x * direction > 0 and hero.combo_connected)
		var hp: float = enemy.hp
		hero.tick(0.02)
		assert(enemy.hp == hp, "kick hits once")
		hero.begin_attack()
		assert(hero.combo == 0 and hero.attack_motion() == "attack_01", "third input restarts the two-hit combo")
	print("ALITO COMBO PASSED: two hits, kick contact, launches in both directions, one hit per target, wraps to punch one")
	game.queue_free()
	await process_frame
	quit()
