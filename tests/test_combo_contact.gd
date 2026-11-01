extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for id in ["beto", "cami", "alito"]:
		game.active_character_id = id
		game.new_run(true)
		await process_frame
		game.debug_spawn_enemy(0)
		var hero = game.player
		var enemy = game.enemies[-1]
		for direction in [1.0, -1.0]:
			hero.combo_window = 0
			hero.position = Vector2(400, 390)
			hero.facing = direction
			enemy.hp = 10000
			for attempt in range(5):
				enemy.position = hero.position + Vector2(direction * 500, 0)
				hero.begin_attack()
				hero.strike()
				assert(hero.combo == 0 and hero.attack_motion() == "attack_01")
				assert(not hero.combo_connected, "misses cannot build a combo")
			for step in range(4):
				enemy.position = hero.position + Vector2(direction * 45, 0)
				enemy.invincible = 0
				hero.strike()
				assert(hero.combo_connected)
				hero.begin_attack()
				assert(hero.combo == (step + 1) % 4, "confirmed hits advance the combo and wrap after the finisher")
			# Miss the second punch: the third input must restart from punch 1.
			enemy.invincible = 0
			hero.strike()
			hero.begin_attack()
			assert(hero.combo == 1)
			enemy.position.x += direction * 500
			hero.strike()
			hero.begin_attack()
			assert(hero.combo == 0 and hero.attack_motion() == "attack_01")
			# Invulnerable targets do not count as confirmed impacts.
			enemy.position = hero.position + Vector2(direction * 45, 0)
			enemy.invincible = 1
			hero.strike()
			hero.begin_attack()
			assert(hero.combo == 0 and not hero.combo_connected)
			# A connected punch still expires with the existing combo window.
			enemy.invincible = 0
			hero.strike()
			hero.combo_window = 0
			hero.begin_attack()
			assert(hero.combo == 0)
		print("PASS: ", id, " misses restart punch 1, connected combos, invulnerability and timeout")
	for tier in range(4):
		game.new_run(true)
		await process_frame
		game.debug_spawn_enemy(mini(tier, 2), tier == 3)
		var enemy = game.enemies[-1]
		var hero = game.player
		enemy.position = Vector2(400, 390)
		enemy.facing = 1
		hero.position = Vector2(800, 390)
		hero.invincible = 0
		for attempt in range(3):
			enemy.begin_attack()
			enemy.strike()
			assert(enemy.combo == 0)
		hero.position = Vector2(445, 390)
		enemy.strike()
		assert(enemy.combo_connected)
		enemy.begin_attack()
		assert(enemy.combo == 1)
		hero.position.x = 800
		enemy.strike()
		enemy.begin_attack()
		assert(enemy.combo == 0)
	print("COMBO CONTACT PASSED: three heroes, three enemy tiers and boss")
	game.queue_free()
	await process_frame
	quit()
