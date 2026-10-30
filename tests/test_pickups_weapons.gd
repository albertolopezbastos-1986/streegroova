extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	await process_frame
	var hero = game.player
	hero.position = Vector2(400, 420)
	hero.hp = 20
	game.drop_food(hero.position)
	var food = game.food[0]
	food.beer = false
	game.update_supplies(0.1)
	assert(hero.hp == 20 and not food.dead)
	hero.begin_attack()
	assert(hero.visual.motion == "pickup" and hero.attack_time == 0)
	hero.tick(0.1)
	assert(hero.hp == 20 and not food.dead)
	hero.invincible = 0
	hero.hurt(1, -1)
	assert(hero.pickup_target == null and not food.dead)
	hero.stun = 0
	hero.cooldown = 0
	hero.begin_attack()
	hero.tick(0.2)
	assert(hero.hp == 94 and food.dead)
	hero.tick(0.2)
	assert(hero.pickup_target == null)
	for kind in ["wood", "pipe"]:
		var item = game.spawn_weapon(hero.position, kind)
		hero.hp = hero.max_hp
		hero.cooldown = 0
		game.update_supplies(0.1)
		assert(not item.dead)
		hero.begin_attack()
		assert(hero.visual.motion == "pickup" and hero.weapon != kind)
		hero.tick(0.2)
		assert(item.dead and hero.weapon == kind and hero.visual.weapon == kind)
		hero.tick(0.2)
		hero.cooldown = 0
		hero.begin_attack()
		assert(hero.attack_motion() == "punch_weapon")
		game.debug_spawn_enemy(0)
		var enemy = game.enemies[-1]
		enemy.position = hero.position + Vector2(90, 0)
		enemy.invincible = 0
		var before: float = enemy.hp
		hero.facing = 1
		hero.strike()
		assert(enemy.hp == before - (42 if kind == "pipe" else 36))
		hero.strike()
		assert(enemy.hp == before - (42 if kind == "pipe" else 36))
		hero.attack_time = 0
	for motion in hero.visual.sheets:
		var data: Dictionary = hero.visual.definition(motion)
		for frame in data["frame_indices"]:
			var hand: Vector2 = hero.visual.weapon_hand_position(motion, int(frame))
			assert(hand.x >= 0 and hand.x < data["frame_size"][0])
			assert(hand.y >= 0 and hand.y < data["frame_size"][1])
		hero.visual.update_pose(motion, 0.01, -1)
		assert(hero.visual.weapon == "pipe")
	game.complete_level()
	game.update_presentation(0.1)
	assert(hero.victory_time > 0 and hero.visual.position.y < 0)
	print("ALL PICKUP AND WEAPON CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
