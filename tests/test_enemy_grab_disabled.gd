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
		var enemy = game.enemies[-1]
		game.player.position = Vector2(400, 420)
		game.player.invincible = 0
		enemy.position = Vector2(420, 420)
		enemy.facing = -1
		game.combat_director.turns[enemy] = 100
		assert(not enemy.grapple.try_start())
		assert(game.player.grabbed_by == null and not enemy.grapple.active())
		if tier != 3:
			game.player.facing = 1
			assert(game.player.grapple.try_start())
			assert(enemy.grabbed_by == game.player)
	print("ALL ENEMY GRAB DISABLED CHECKS PASSED: all enemy tiers and bosses blocked, player grabs preserved")
	game.queue_free()
	await process_frame
	quit()
