extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	game._input(key(KEY_O))
	assert(game.debug_items_menu.open and game.debug_items_menu.buttons.size() == 4)
	game._input(key(KEY_1))
	assert(not game.debug_items_menu.open and game.props.size() == 1 and game.props[0].barrel)
	game._input(key(KEY_O))
	game._input(key(KEY_2))
	assert(game.props.size() == 2 and not game.props[1].barrel)
	var types := {}
	seed(423)
	for i in range(30):
		game.debug_spawn_item("crate" if i % 2 else "barrel")
		game.props[-1].hurt(1, 1)
		assert(game.food.size() == i + 1)
		types[game.food[-1].beer] = true
	assert(types.size() == 2)
	game._input(key(KEY_O))
	game._input(key(KEY_4))
	assert(game.weapons[-1].weapon == "pipe")
	game._input(key(KEY_O))
	game._input(key(KEY_ESCAPE))
	assert(not game.debug_items_menu.open and game.state == "play")
	game._input(key(KEY_O))
	await process_frame
	var center: Vector2 = game.debug_items_menu.buttons[2].get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion, true)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = center
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		root.push_input(click, true)
	await process_frame
	assert(not game.debug_items_menu.open and game.weapons[-1].weapon == "wood")
	print("PASS: O item menu, barrel/crate, both random food drops and weapons")
	game.new_run(true)
	await process_frame
	var hero = game.player
	hero.position = Vector2(400, 420)
	game.camera_x = 250
	hero.invincible = 0
	hero.weapon = "pipe"
	hero.weapon_durability = 80
	hero.facing = 1
	hero.update_visual(0)
	game.debug_spawn_enemy(2)
	var target = game.enemies[-1]
	target.position = Vector2(500, 420)
	target.invincible = 0
	Input.action_press("jump")
	Input.action_press("attack")
	hero.tick(0.016)
	Input.action_release("jump")
	Input.action_release("attack")
	assert(hero.weapon.is_empty() and hero.height == 0 and game.weapons.size() == 1)
	var item = game.weapons[-1]
	assert(item.weapon_projectile and item.weapon_velocity.x > 0 and item.weapon_durability == 80)
	item.tick(0.25)
	assert(target.thrown_time > 0 and target.hp == target.max_hp - 42)
	assert(not item.weapon_projectile and item.weapon_velocity.x == 0 and item.weapon_durability == 50)
	var stop_x: float = item.position.x
	for i in range(100):
		item.tick(0.016)
	assert(item.position.x == stop_x and item.height == 0 and not item.weapon_airborne)
	assert(target.hp == target.max_hp - 42)
	print("PASS: jump+attack throws, swept hit launches one enemy, weapon stops and lands with wear")
	game.new_run(true)
	await process_frame
	hero = game.player
	hero.position = Vector2(400, 420)
	hero.weapon = "wood"
	hero.facing = -1
	hero.update_visual(0)
	hero.throw_weapon()
	item = game.weapons[-1]
	assert(item.weapon_velocity.x < 0)
	for i in range(100):
		item.tick(0.016)
	assert(not item.weapon_projectile and not item.weapon_airborne and not item.dead)
	print("PASS: left-facing throw and miss land safely without wear")
	game.debug_spawn_enemy(0)
	var enemy = game.enemies[-1]
	enemy.position = item.position
	hero.position = enemy.position + Vector2(200, 0)
	enemy.ai_weapon_cooldown = 1
	assert(not enemy.seek_weapon(0.016))
	seed(741)
	var interest := 0
	for i in range(100):
		enemy.ai_weapon_cooldown = 0
		enemy.ai_weapon_target = null
		if enemy.seek_weapon(0.016):
			interest += 1
			enemy.cancel_pickup()
	assert(interest > 0 and interest < 35 and enemy.ai_weapon_cooldown >= 12)
	enemy.ai_weapon_target = item
	enemy.ai_weapon_seek_time = 3
	assert(enemy.seek_weapon(0.016))
	enemy.tick(enemy.visual.duration("pickup") * 0.51)
	assert(enemy.weapon == "wood" and item.dead)
	enemy.tick(enemy.visual.duration("pickup") * 0.51)
	hero.position = enemy.position + Vector2(50, 0)
	hero.invincible = 0
	enemy.facing = 1
	enemy.cooldown = 0
	enemy.attack_time = 0
	enemy.begin_attack()
	assert(enemy.attack_motion() == "punch_weapon")
	enemy.strike()
	assert(hero.hp == 76 and enemy.weapon_durability == 90)
	enemy.invincible = 0
	assert(enemy.launch_away(1, -1))
	assert(enemy.weapon.is_empty() and game.weapons[-1].weapon_durability == 90)
	print("PASS: enemy picks up, uses, wears and drops weapon on launch")
	game.new_run(true)
	await process_frame
	hero = game.player
	hero.weapon = "wood"
	hero.invincible = 0
	Input.action_press("attack")
	hero.tick(0.016)
	assert(hero.weapon_attack)
	await process_frame
	Input.action_press("jump")
	hero.tick(0.016)
	Input.action_release("jump")
	Input.action_release("attack")
	assert(hero.weapon.is_empty() and game.weapons[-1].weapon_projectile)
	print("PASS: throw chord tolerates attack just before jump")
	for remaining in [100, 50]:
		game.new_run(true)
		await process_frame
		game.camera_x = 250
		hero = game.player
		hero.position = Vector2(400, 420)
		hero.weapon = "wood"
		hero.weapon_durability = remaining
		hero.facing = 1
		hero.update_visual(0)
		game.debug_spawn_enemy(0)
		var victim = game.enemies[-1]
		victim.position = Vector2(500, 420)
		victim.invincible = 0
		hero.throw_weapon()
		var plank = game.weapons[-1]
		plank.tick(0.25)
		assert(victim.thrown_time > 0 and plank.weapon_durability == remaining - 50)
		assert(plank.weapon_broken == (remaining == 50))
	print("PASS: thrown plank impact costs 50 durability and breaks at zero")
	print("ALL WEAPON THROW AND DEBUG ITEM CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
