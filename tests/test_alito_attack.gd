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
	var target = game.enemies[0]
	hero.position = Vector2(400, 390)
	hero.facing = 1
	target.position = hero.position + Vector2(45, 0)
	target.hp = 1000
	target.invincible = 0
	hero.begin_attack()
	assert(hero.visual.motion == "attack_01")
	assert(hero.visual.sheets["attack_01"].resource_path.ends_with("alito/animations/attack_01/punch1.png"))
	assert(hero.visual.definition("attack_01")["frame_indices"] == range(9))
	hero.tick(0.1)
	assert(target.hp == 1000, "wind-up does not damage")
	hero.tick(0.13)
	assert(hero.visual.source_frame == 4 and target.hp < 1000, "embestida deals damage on contact")
	var hp: float = target.hp
	for i in range(8):
		hero.tick(0.016)
	assert(target.hp == hp, "contact deals damage once per target")
	hero.tick(0.2)
	assert(hero.visual.motion == "idle", "recovery returns to idle")
	print("ALITO PUNCH 1 PASSED: own nine frames, timed contact, one hit per target, recovery")
	game.queue_free()
	await process_frame
	quit()
