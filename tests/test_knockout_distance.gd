extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for id in ["beto", "cami", "alito"]:
		for direction in [1.0, -1.0]:
			var distances := []
			for lethal in [false, true]:
				game.active_character_id = id
				game.new_run(true)
				await process_frame
				game.right_bound = 4000
				var hero = game.player
				hero.position.x = 1500
				hero.invincible = 0
				hero.hp = 1 if lethal else hero.max_hp
				assert(hero.launch_away(1, direction, false))
				if lethal:
					assert(hero.dead and hero.facing == -direction)
					assert(not hero.flight_can_hit)
				for i in range(400):
					hero.tick(0.005)
				assert(hero.height == 0 and hero.velocity.is_zero_approx())
				distances.append(absf(hero.position.x - 1500))
			print(id, " direction=", direction, " distances=", distances)
			assert(absf(float(distances[1]) - float(distances[0]) * 0.5) < 0.1, "KO distance is exactly half the ordinary launch for " + id)
			# Ordinary lethal hits must also launch, not only special attacks.
			game.new_run(true)
			await process_frame
			var hero = game.player
			hero.invincible = 0
			hero.hurt(hero.max_hp, direction)
			assert(hero.dead and hero.height > 0 and hero.jump_speed > 0)
			assert(hero.velocity.x == direction * hero.THROW_SPEED * 0.5)
	print("KNOCKOUT DISTANCE PASSED: all three heroes, both facings, lethal ordinary/special hits, half launch distance, ground stop")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
