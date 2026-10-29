extends SceneTree

var checks := 0

func check(value: bool, description: String) -> void:
	if not value:
		push_error("FAIL: " + description)
		quit(1)
		assert(value, description)
	checks += 1
	print("PASS: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(8127)
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run()
	await process_frame
	var director = game.combat_director
	var hero = game.player
	hero.position = Vector2(400, 420)
	hero.invincible = 0
	hero.hp = 100000
	for i in range(game.enemies.size()):
		var enemy = game.enemies[i]
		enemy.position = hero.position + Vector2(100 + i * 35, 0)
		enemy.ai_jump_cooldown = 1000
	director.update(0.01)
	var left := 0
	var right := 0
	for enemy in game.enemies:
		if director.side_for(enemy) < 0:
			left += 1
		else:
			right += 1
	check(left > 0 and right > 0, "three enemies starting together reserve both flanks")
	var flanker = game.enemies[1]
	var route: Vector2 = director.destination(flanker)
	check(route.y == game.WALK_MIN_Y and route.x == flanker.position.x, "crossing enemy first moves into a bypass lane")
	var attackers := {}
	var dual_frames := 0
	var single_frames := 0
	var max_busy := 0
	var reached_left := false
	for frame in range(3600):
		hero.tick(1.0 / 60)
		hero.position = Vector2(400, 420)
		director.update(1.0 / 60)
		var busy := 0
		for enemy in game.enemies:
			enemy.tick(1.0 / 60)
			reached_left = reached_left or enemy.position.x < hero.position.x - 35
			if enemy.windup > 0 or enemy.attack_time > 0:
				busy += 1
				attackers[enemy] = true
		max_busy = maxi(max_busy, busy)
		if busy == 2:
			dual_frames += 1
		if busy == 1:
			single_frames += 1
		check_limit(director.turns.size() <= 2 and busy <= 2)
		if frame < 300:
			check_limit(busy <= 1)
	check(reached_left, "a flanker actually crosses behind the player")
	check(attackers.size() == 3, "all three rivals receive attack turns")
	check(max_busy == 2 and dual_frames > 0, "occasional second attacker intervenes during combat")
	check(single_frames > dual_frames * 2, "single-attacker combat dominates over overlapping attacks")
	var lead = director.turns.keys()[0] if not director.turns.is_empty() else game.enemies[0]
	director.turns[lead] = director.clock + 3
	lead.invincible = 0
	lead.hurt(1, 1)
	director.update(0.016)
	check(not director.allowed(lead), "interrupting a rival releases its attack reservation")
	director.reset()
	check(director.turns.is_empty(), "ultimate/reset cancels all reserved turns")
	hero.position.x = game.left_bound + 20
	director.update(0.016)
	check(game.enemies.all(func(e): return director.side_for(e) > 0), "cornered player does not create unreachable flank positions")
	hero.dead = true
	for i in range(120):
		director.update(0.016)
	check(director.turns.is_empty(), "enemies stop requesting attacks while player is KO")
	print("ALL ", checks, " COMBAT DIRECTOR CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()

func check_limit(value: bool) -> void:
	if not value:
		push_error("attack concurrency limit exceeded")
		quit(1)
		assert(value)
