extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for tier in range(4):
		game.new_run(true)
		await process_frame
		game.debug_spawn_enemy(mini(tier, 2), tier == 3)
		var hero = game.player
		var enemy = game.enemies[0]
		hero.position = Vector2(400, 420)
		hero.weapon = "wood"
		hero.weapon_durability = 100
		hero.facing = 1
		enemy.hp = 10000
		var cost: int = [10, 20, 30, 50][tier]
		for hit in range(ceili(100.0 / cost)):
			hero.attack_time = 0
			hero.cooldown = 0
			enemy.position = hero.position + Vector2(45, 0)
			enemy.invincible = 0
			hero.begin_attack()
			hero.strike()
			assert(hero.weapon_durability == maxi(0, 100 - (hit + 1) * cost))
			hero.strike()
			assert(hero.weapon_durability == maxi(0, 100 - (hit + 1) * cost))
		assert(hero.weapon.is_empty() and game.weapons[-1].weapon_broken)
		var broken = game.weapons[-1]
		assert(game.nearby_pickup(hero) == null)
		broken.tick(0.7)
		assert(broken.dead)
		print("PASS: weapon cost and break for tier ", tier + 1)
	game.new_run(true)
	await process_frame
	var hero = game.player
	hero.position = Vector2(400, 420)
	hero.weapon = "pipe"
	hero.weapon_durability = 70
	hero.invincible = 0
	hero.update_visual(0)
	assert(hero.launch_away(1, -1))
	assert(hero.weapon.is_empty() and game.weapons.size() == 1)
	var dropped = game.weapons[0]
	assert(dropped.weapon_airborne and dropped.height > 0 and dropped.weapon_durability == 70)
	hero.position = dropped.position
	assert(game.nearby_pickup(hero) == null)
	var maximum_spin := 0.0
	for i in range(120):
		dropped.tick(0.016)
		maximum_spin = maxf(maximum_spin, absf(dropped.weapon_rotation))
		if not dropped.weapon_airborne:
			break
	assert(maximum_spin > TAU * 2 and dropped.height == 0 and not dropped.dead)
	hero.position = dropped.position
	hero.thrown_time = 0
	hero.getup_time = 0
	hero.height = 0
	hero.stun = 0
	hero.cooldown = 0
	hero.invincible = 0
	hero.begin_attack()
	hero.tick(hero.visual.duration("pickup") * 0.51)
	assert(hero.weapon == "pipe" and hero.weapon_durability == 70)
	hero.tick(hero.visual.duration("pickup") * 0.51)
	hero.invincible = 0
	hero.hurt(1, 1)
	assert(hero.weapon == "pipe")
	print("PASS: launched weapon spins, lands and retains wear when picked up; normal hit keeps it")
	print("ALL WEAPON DURABILITY CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
