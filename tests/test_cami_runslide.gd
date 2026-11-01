extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.active_character_id = "cami"
	game.new_run(true)
	await process_frame
	game.debug_spawn_enemy(0)
	var hero = game.player
	var enemy = game.enemies[0]
	for direction in [1.0, -1.0]:
		hero.position = Vector2(350, 390)
		hero.facing = direction
		hero.running = true
		hero.cooldown = 0
		enemy.position = hero.position + Vector2(60 * direction, 0)
		enemy.hp = 1000
		enemy.invincible = 0
		enemy.thrown_time = 0
		enemy.height = 0
		hero.begin_attack()
		assert(hero.run_attack and hero.attack_motion() == "runslide")
		assert(hero.visual.sheets["runslide"].resource_path.ends_with("cami/animations/runslide/runslide.png"))
		assert(is_equal_approx(hero.slide_animation_duration, 0.5))
		var cell: Array = hero.visual.definition("runslide")["frame_size"]
		assert(Vector2(cell[0], cell[1]) == Vector2(162, 245))
		assert(not hero.visual.definition("runslide").has("scale"), "new slide inherits Cami normal size")
		for frame in range(9):
			hero.attack_time = hero.attack_duration - (frame + 0.1) / 18.0
			hero.update_visual(0)
			assert(hero.visual.source_frame == frame)
			assert(hero.attack_is_active() == (frame in [3, 4, 5]))
			if hero.attack_is_active():
				hero.strike()
			assert(enemy.hp == (1000 if frame < 3 else 971))
		assert(enemy.thrown_time > 0 and enemy.velocity.x * direction > 0)
		assert(hero.hits.size() == 1)
		hero.attack_time = hero.attack_duration
		var start: Vector2 = hero.position
		while hero.attack_time > 0:
			hero.tick(0.005)
		assert((hero.position.x - start.x) * direction > 130)
		assert(not hero.run_attack and hero.velocity == Vector2.ZERO)
	print("CAMI RUNSLIDE PASSED: own nine-frame sheet, contact timing, one hit, launch and braking in both directions")
	game.queue_free()
	await process_frame
	quit()
