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
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run()
	await process_frame
	var hero = game.player
	var enemy = game.enemies[0]
	var grab = hero.grapple
	check(hero.visual.definition("grab_throw")["frame_indices"].size() == 20, "throw animation uses twenty frames")
	check(hero.visual.sheets["grab_throw"].get_size() == Vector2(1000, 1000), "real throw sheet loaded with five by five cells")
	hero.position = Vector2(400, 420)
	hero.facing = 1
	hero.invincible = 0
	enemy.position = hero.position + Vector2(45, 0)
	check(not grab.try_start(), "normal punch distance does not initiate a grab")
	enemy.position = hero.position + Vector2(-15, 0)
	check(not grab.try_start(), "cannot automatically grab an enemy behind facing")
	enemy.position = hero.position + Vector2(20, 9)
	check(not grab.try_start(), "cannot grab across depth lanes")
	enemy.position = hero.position + Vector2(20, 0)
	enemy.height = 30
	check(not grab.try_start(), "cannot grab an airborne rival")
	enemy.height = 0
	enemy.attack_time = 0.2
	enemy.windup = 0.2
	game.combat_director.turns[enemy] = 999
	check(grab.try_start(), "close enemy is captured")
	check(enemy.grabbed_by == hero and enemy.attack_time == 0 and enemy.windup == 0, "grab cancels captive attack and windup")
	check(not game.combat_director.allowed(enemy), "captive releases its group attack turn")
	for i in range(40):
		hero.tick(0.016)
		enemy.tick(0.016)
	check(grab.state == "hold" and hero.visual.source_frame == 8, "player freezes precisely at throw frame eight")
	check(enemy.visual.motion == "hurt" and enemy.visual.source_frame == 3, "captive freezes precisely at damage frame three")
	var start: Vector2 = enemy.position
	for i in range(60):
		hero.tick(0.016)
		enemy.tick(0.016)
	check(enemy.position == start and hero.visual.source_frame == 8, "both stay frozen while waiting for input")
	var before: float = enemy.hp
	Input.action_press("attack")
	hero.tick(0.016)
	Input.action_release("attack")
	await process_frame
	check(grab.state == "punch" and hero.visual.motion == "attack_01", "attack alone chooses first grab punch with placeholder art")
	for i in range(40):
		hero.tick(0.016)
		enemy.tick(0.016)
	check(enemy.hp == before - 19 and enemy.grabbed_by == hero, "grab punch deals damage once without releasing enemy")
	check(grab.state == "hold" and hero.visual.source_frame == 8, "grab punch returns to frozen hold")
	Input.action_press("left")
	Input.action_press("attack")
	hero.tick(0.016)
	Input.action_release("attack")
	Input.action_release("left")
	await process_frame
	check(grab.state == "throw" and hero.facing == 1 and hero.visual.source_frame >= 9, "back plus attack resumes throw without turning the player")
	for i in range(25):
		hero.tick(0.016)
		enemy.tick(0.016)
	check(not is_instance_valid(enemy.grabbed_by) and enemy.velocity.x < 0 and enemy.height > 0, "throw launches rival backwards into an arc")
	check(enemy.hp == before - 59, "throw applies forty damage once")
	for i in range(130):
		hero.tick(0.016)
		enemy.tick(0.016)
		if not grab.active() and enemy.thrown_time == 0 and enemy.getup_time == 0:
			break
	check(not grab.active() and enemy.height == 0 and enemy.thrown_time == 0, "throw completes and surviving enemy lands and recovers")
	# Mirror controls and verify that a second enemy can interrupt the hold.
	hero.facing = -1
	hero.cooldown = 0
	hero.attack_time = 0
	grab.retry = 0
	enemy.stun = 0
	enemy.position = hero.position + Vector2(-20, 0)
	check(grab.try_start(), "grab works facing left")
	for i in range(35):
		hero.tick(0.016)
	Input.action_press("right")
	Input.action_press("attack")
	hero.tick(0.016)
	Input.action_release("right")
	Input.action_release("attack")
	await process_frame
	check(grab.state == "throw" and hero.facing == -1, "right plus attack is backwards when facing left")
	grab.release()
	grab.retry = 0
	enemy.position = hero.position + Vector2(-20, 0)
	enemy.invincible = 0
	check(grab.try_start(), "enemy can be grabbed again after release")
	hero.invincible = 0
	hero.hurt(10, 1)
	check(not grab.active() and not is_instance_valid(enemy.grabbed_by), "hit from another enemy safely interrupts both sides of grab")
	# Full meter can cancel a hold; no captive remains stuck after the ultimate.
	hero.stun = 0
	hero.cooldown = 0
	grab.retry = 0
	enemy.position = hero.position + Vector2(-20, 0)
	check(grab.try_start(), "grab can restart after interruption")
	game.charge = 100
	game.use_ultimate()
	check(not grab.active() and not is_instance_valid(enemy.grabbed_by) and game.ult_time > 0, "ultimate releases held enemy")
	game.ult_time = 0
	hero.ultimate_pose = 0
	hero.stun = 0
	hero.cooldown = 0
	hero.attack_time = 0
	grab.retry = 0
	enemy.position = hero.position + Vector2(24, 0)
	Input.action_press("right")
	hero.tick(0.016)
	Input.action_release("right")
	await process_frame
	check(grab.active() and enemy.grabbed_by == hero, "walking into close contact automatically begins the grab")
	grab.release()
	# Early throw input is buffered through the shortened catch animation.
	hero.stun = 0
	hero.cooldown = 0
	hero.attack_time = 0
	hero.grapple.retry = 0
	hero.facing = 1
	enemy.getup_time = 0
	enemy.thrown_time = 0
	enemy.height = 0
	enemy.hp = 130
	enemy.invincible = 0
	enemy.position = hero.position + Vector2(20, 0)
	check(grab.try_start(), "can start grab for early throw input")
	Input.action_press("left")
	Input.action_press("attack")
	hero.tick(0.016)
	Input.action_release("left")
	Input.action_release("attack")
	await process_frame
	check(grab.buffered_action == "throw", "back plus attack during catch buffers a throw")
	var throw_delay := 0.016
	for i in range(30):
		hero.tick(0.016)
		throw_delay += 0.016
		if enemy.thrown_time > 0:
			break
	check(enemy.thrown_time > 0 and throw_delay < 0.42, "early throw launches within four tenths of a second from capture")
	check(hero.visual.source_frame >= 15 and enemy.hp == 90, "faster throw keeps release synchronized to the animation and damage")
	print("ALL ", checks, " GRAPPLE CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
