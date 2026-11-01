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
	var hero = game.player
	game.debug_spawn_enemy(0)
	var enemy = game.enemies[0]
	hero.position = Vector2(350, 390)
	hero.facing = 1
	enemy.position = hero.position + Vector2(50, 0)
	enemy.hp = 1000
	enemy.invincible = 0
	hero.begin_attack()
	assert(hero.attack_motion() == "attack_01")
	assert(hero.visual.sheets["attack_01"].resource_path == "res://assets/characters/cami/animations/attack_01/punch1.png")
	assert(is_equal_approx(hero.attack_duration, 0.5))
	for frame in range(9):
		hero.attack_time = hero.attack_duration * (1.0 - (frame + 0.1) / 9.0)
		hero.update_visual(0)
		assert(hero.visual.source_frame == frame)
		assert(hero.attack_is_active() == (frame in [3, 4, 5]))
		if hero.attack_is_active():
			hero.strike()
		assert(enemy.hp == (1000 if frame < 3 else 981), "Cami attack hits once, on the impact frames")
	assert(hero.hits.size() == 1)
	print("CAMI ATTACK PASSED: own texture, nine frames, impact timing, one hit per target")
	hero.attack_time = 0
	hero.cooldown = 0
	hero.combo = 0
	hero.combo_window = 1
	enemy.hp = 1000
	enemy.invincible = 0
	hero.begin_attack()
	assert(hero.attack_motion() == "attack_02", "second combo step uses Cami punch 2")
	assert(hero.visual.sheets["attack_02"].resource_path.ends_with("cami/animations/attack_02/punch2.png"))
	for frame in range(9):
		hero.attack_time = hero.attack_duration * (1.0 - (frame + 0.1) / 9.0)
		hero.update_visual(0)
		assert(hero.visual.source_frame == frame)
		assert(hero.attack_is_active() == (frame in [4, 5]))
		if hero.attack_is_active():
			hero.strike()
		assert(enemy.hp == (1000 if frame < 4 else 981), "second attack hits only once when the kick extends")
	print("CAMI SECOND ATTACK PASSED: combo step, own art, nine frames, kick contact, single hit")
	hero.attack_time = 0
	hero.cooldown = 0
	hero.height = 50
	enemy.hp = 1000
	enemy.invincible = 0
	hero.begin_attack()
	assert(hero.air_attack and hero.attack_motion() == "jump_attack")
	assert(hero.visual.sheets["jump_attack"].resource_path.ends_with("cami/animations/jump_attack/jumpattack.png"))
	for frame in range(9):
		hero.attack_time = hero.attack_duration * (1.0 - (frame + 0.1) / 9.0)
		hero.update_visual(0)
		assert(hero.visual.source_frame == frame)
		assert(hero.attack_is_active() == (frame in [3, 4, 5]))
		if hero.attack_is_active():
			hero.strike()
		assert(enemy.hp == (1000 if frame < 3 else 971), "aerial kick hits once on contact")
	hero.height = 0
	hero.air_attack = false
	print("CAMI JUMP ATTACK PASSED: own art, nine frames, airborne variant, timed single hit")
	for direction in [1.0, -1.0]:
		hero.attack_time = 0
		hero.cooldown = 0
		hero.combo = 1
		hero.combo_window = 1
		hero.position = Vector2(350, 390)
		hero.facing = direction
		enemy.position = hero.position + Vector2(direction * 60, 0)
		enemy.height = 0
		enemy.jump_speed = 0
		enemy.thrown_time = 0
		enemy.getup_time = 0
		enemy.stun = 0
		enemy.velocity = Vector2.ZERO
		enemy.hp = 1000
		enemy.invincible = 0
		hero.begin_attack()
		assert(hero.attack_motion() == "attack_03")
		assert(hero.visual.source_frame == 8, "third attack starts on original frame 8")
		assert(hero.visual.definition("attack_03")["frame_indices"] == range(8, 41))
		assert(Vector2(hero.visual.definition("attack_03")["frame_size"][0], hero.visual.definition("attack_03")["frame_size"][1]) == Vector2(324, 325), "larger cells fit repaired frames")
		assert(Vector2(hero.visual.definition("attack_03")["pivot_pixels"][0], hero.visual.definition("attack_03")["pivot_pixels"][1]) == Vector2(162, 281), "expanded canvas preserves world alignment")
		assert(hero.visual.sheets["attack_03"].resource_path.ends_with("cami/animations/attack_03/punch3.png"))
		var max_lift := 0.0
		var start: Vector2 = hero.position
		while hero.attack_time > 0:
			hero.tick(0.005)
			max_lift = maxf(max_lift, -hero.visual.position.y)
			assert(hero.attack_motion() == "attack_03", "hop cannot switch the attack to jump_attack")
		assert(is_equal_approx(hero.position.x, start.x - direction * 41.4), "third attack retreats 41.4 units in either facing")
		assert(max_lift == 48 and hero.visual.position.y == 0, "hop lifts 48 units and lands at the end")
		assert(enemy.hp == 971 and hero.hits.size() == 1, "third attack hits once for combo finisher damage")
	# An interruption cancels the remaining hop and retreat.
	hero.combo = 1
	hero.combo_window = 1
	hero.cooldown = 0
	hero.begin_attack()
	hero.tick(hero.attack_duration * 0.6)
	assert(hero.visual.position.y < 0)
	hero.invincible = 0
	hero.hurt(1, 1)
	assert(hero.visual.position.y == 0, "taking damage clears the attack hop immediately")
	print("CAMI FINISHER PASSED: own art, 48-unit hop, 41.4-unit retreat in both directions, one hit, clean interruption")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
