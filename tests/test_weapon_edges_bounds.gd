extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for friendly_target in [true, false]:
		game.new_run(true)
		await process_frame
		game.camera_x = 250
		game.player.position = Vector2(600 if friendly_target else 500, 420)
		game.player.invincible = 0
		game.debug_spawn_enemy(0)
		var thrower = game.enemies[-1]
		thrower.position = Vector2(400, 420)
		thrower.weapon = "pipe"
		thrower.facing = 1
		thrower.ai_special_cooldown = 100
		thrower.ai_slide_cooldown = 100
		thrower.ai_jump_cooldown = 100
		thrower.update_visual(0)
		var target = game.player
		if friendly_target:
			game.debug_spawn_enemy(0)
			target = game.enemies[-1]
			target.position = Vector2(500, 420)
			target.invincible = 0
		game.combat_director.turns[thrower] = 100
		seed(81)
		for i in range(20):
			thrower.ai_weapon_throw_cooldown = 0
			thrower.enemy_control(0.016)
			if thrower.weapon.is_empty():
				break
		assert(thrower.weapon.is_empty() and game.weapons.size() == 1)
		var item = game.weapons[-1]
		item.tick(0.25)
		assert(target.thrown_time > 0 and target.hp == target.max_hp - 42)
		assert(thrower.hp == thrower.max_hp and item.weapon_velocity.x == 0)
		if friendly_target:
			assert(game.player.hp == game.player.max_hp)
	print("PASS: enemy AI throws and can hit another enemy or the player, excluding itself")
	for direction in [-1, 1]:
		game.new_run(true)
		await process_frame
		game.camera_x = 250
		var hero = game.player
		hero.position = Vector2(350 if direction < 0 else 650, 420)
		hero.weapon = "wood"
		hero.facing = direction
		hero.update_visual(0)
		hero.throw_weapon()
		var item = game.weapons[-1]
		for i in range(20):
			item.tick(0.016)
			if not item.weapon_projectile:
				break
		var edge: float = game.camera_x + 42 if direction < 0 else game.camera_x + 960.0 / game.WORLD_ZOOM - 42
		assert(is_equal_approx(item.position.x, edge) and item.weapon_velocity.x == 0)
		assert(item.weapon_airborne)
		for i in range(100):
			item.tick(0.016)
		assert(is_equal_approx(item.position.x, edge) and item.height == 0 and not item.dead)
		assert(item.weapon_durability == 100)
	print("PASS: both screen edges stop the weapon and leave it intact on the floor")
	game.new_run(true)
	await process_frame
	game.debug_spawn_enemy(2)
	for distance in [1000, 3000, 10000]:
		game.player.position.x = distance
		game.enemies[0].position = Vector2(-100, 900)
		game.update_camera(2)
		var peak: float = game.camera_peak_x
		game.player.position.x = 30
		game.player.velocity = Vector2(-170, 0)
		game.player.moving = true
		for i in range(100):
			game.update_camera(0.016)
		assert(game.camera_x >= peak - game.BACKTRACK_DISTANCE)
		assert(game.player.position.x >= game.left_bound - 0.01)
		var enemy = game.enemies[0]
		assert(enemy.position.x >= game.camera_x + 24 - 0.01 and enemy.position.x <= game.camera_x + 960.0 / game.WORLD_ZOOM - 24 + 0.01)
		assert(enemy.position.y >= game.WALK_MIN_Y and enemy.position.y <= game.WALK_MAX_Y)
	assert(game.camera_x > game.LEVEL_WIDTH)
	print("PASS: continuous limited backtracking, infinite debug advance, enemies remain inside the visible walking area")
	print("ALL WEAPON EDGE AND BOUNDARY CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
