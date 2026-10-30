extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	game.debug_spawn_enemy(2, true)
	var boss = game.enemies[-1]
	var hero = game.player
	hero.position = Vector2(350, 420)
	hero.facing = 1
	boss.position = Vector2(370, 420)
	assert(not hero.grapple.try_start() and boss.grabbed_by == null)
	for damage in [19, 29, 36, 42, 20]:
		boss.invincible = 0
		var before: float = boss.hp
		assert(boss.launch_away(damage, 1, true, hero))
		assert(boss.hp == before - damage and boss.thrown_time == 0 and boss.height == 0 and boss.jump_speed == 0)
	game.camera_x = 200
	hero.position = Vector2(350, 420)
	hero.weapon = "wood"
	hero.weapon_durability = 100
	hero.update_visual(0)
	boss.position = Vector2(450, 420)
	boss.invincible = 0
	hero.throw_weapon()
	var item = game.weapons[-1]
	var before: float = boss.hp
	item.tick(0.25)
	assert(boss.hp == before - 36 and boss.thrown_time == 0)
	assert(item.weapon_velocity.x == 0 and item.weapon_durability == 50)
	game.ult_time = 0.7
	game.ult_applied = false
	game.freeze = 0
	game.update_game(0.1)
	assert(game.ult_applied and boss.thrown_time > 0 and boss.height > 0)
	print("ALL BOSS IMMUNITY CHECKS PASSED: no grabs, grounded damage, thrown weapon contact, ultimate launches")
	game.queue_free()
	await process_frame
	quit()
