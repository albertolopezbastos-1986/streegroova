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
	game.new_run(true)
	await process_frame
	for i in range(4):
		game.debug_spawn_enemy(0)
	var hero = game.player
	var source = game.enemies[0]
	var secondary = game.enemies[1]
	var third = game.enemies[2]
	var other_lane = game.enemies[3]
	source.position = Vector2(200, 420)
	secondary.position = Vector2(230, 420)
	third.position = Vector2(285, 420)
	other_lane.position = Vector2(230, 400)
	source.launch_away(10, 1)
	source.tick(0.04)
	check(secondary.thrown_time > 0 and secondary.hp == 110, "flying enemy launches another enemy on contact")
	check(source.flight_can_hit and not secondary.flight_can_hit, "only original throw propagates flight impacts")
	secondary.tick(0.12)
	check(third.hp == 130 and third.thrown_time == 0, "secondary launch cannot create a third generation")
	check(other_lane.hp == 130, "flight collision respects depth lanes")
	source.velocity.x = 2000
	source.tick(0.04)
	check(third.thrown_time > 0 and third.hp == 110, "original flying body can hit more than one enemy with swept collision")
	var hp: float = secondary.hp
	source.update_flight_impacts(Vector2(230, 420))
	check(secondary.hp == hp, "flight hits each victim only once")
	# A thrown player can hit enemies too, including the enemy that threw them.
	game.new_run(true)
	await process_frame
	hero = game.player
	game.debug_spawn_enemy(0)
	secondary = game.enemies[0]
	hero.position = Vector2(400, 420)
	hero.invincible = 0
	secondary.position = Vector2(370, 420)
	hero.launch_away(10, -1)
	hero.tick(0.04)
	check(secondary.thrown_time > 0 and secondary.velocity.x < 0 and not secondary.flight_can_hit, "thrown player knocks enemies away without further chains")
	# Lethal initial launches retain body collisions while the body is airborne.
	game.new_run(true)
	await process_frame
	for i in range(2):
		game.debug_spawn_enemy(0)
	source = game.enemies[0]
	secondary = game.enemies[1]
	source.position = Vector2(200, 420)
	secondary.position = Vector2(230, 420)
	source.launch_away(1000, 1)
	source.tick(0.04)
	check(source.dead and secondary.thrown_time > 0, "KO body can still knock others over in flight")
	# Three punches, returning to hold between the first two, then non-chain launch.
	game.new_run(true)
	await process_frame
	hero = game.player
	game.debug_spawn_enemy(0)
	secondary = game.enemies[0]
	hero.position = Vector2(350, 420)
	hero.facing = 1
	secondary.position = Vector2(370, 420)
	check(hero.grapple.try_start(), "player starts grab for three-hit sequence")
	for i in range(40):
		hero.tick(0.016)
	for punch in range(3):
		Input.action_press("attack")
		hero.tick(0.016)
		Input.action_release("attack")
		await process_frame
		check(hero.visual.motion == "attack_01", "grab punch %d uses punch one art" % (punch + 1))
		for i in range(30):
			hero.tick(0.016)
		if punch < 2:
			check(hero.grapple.state == "hold" and hero.visual.source_frame == 8 and secondary.grabbed_by == hero, "punch %d returns to held frame" % (punch + 1))
	check(secondary.hp == 73 and secondary.thrown_time > 0 and not secondary.flight_can_hit, "third grab punch launches with no chain effect")
	check(not hero.grapple.active() and not is_instance_valid(secondary.grabbed_by), "third punch cleanly ends grab")
	# Jump abandons the grab without dealing damage.
	game.new_run(true)
	await process_frame
	hero = game.player
	game.debug_spawn_enemy(0)
	secondary = game.enemies[0]
	hero.position = Vector2(350, 420)
	hero.facing = 1
	secondary.position = Vector2(370, 420)
	hero.grapple.try_start()
	Input.action_press("jump")
	hero.tick(0.016)
	Input.action_release("jump")
	await process_frame
	check(not hero.grapple.active() and hero.height > 0 and secondary.hp == 130 and not is_instance_valid(secondary.grabbed_by), "jump leaves grab immediately without striking or throwing")
	# Escape is based on fresh presses; held keys do not repeatedly count.
	game.new_run(true)
	await process_frame
	hero = game.player
	game.debug_spawn_enemy(0)
	var captor = game.enemies[0]
	hero.position = Vector2(350, 420)
	hero.invincible = 0
	captor.position = Vector2(370, 420)
	captor.facing = -1
	game.combat_director.turns[captor] = 999
	Input.action_press("right")
	check(captor.grapple.try_start(), "enemy captures player for escape test")
	for i in range(4):
		hero.tick(0.016)
	check(captor.grapple.escape_presses == 0, "direction already held at capture earns no escape presses")
	Input.action_press("attack")
	hero.tick(0.016)
	for i in range(8):
		hero.tick(0.016)
	check(captor.grapple.escape_presses == 1 and is_instance_valid(hero.grabbed_by), "holding attack counts only once")
	Input.action_release("attack")
	Input.action_release("right")
	hero.tick(0.016)
	for action in ["jump", "left", "attack", "down"]:
		Input.action_press(action)
		hero.tick(0.016)
		Input.action_release(action)
		hero.tick(0.016)
	check(not is_instance_valid(hero.grabbed_by) and not captor.grapple.active(), "mashing attack jump and movement escapes enemy grip")
	check(hero.hp == 100 and hero.stun == 0 and hero.invincible > 0 and captor.stun > 0, "escape gives player control and briefly staggers captor")
	check(not game.combat_director.allowed(captor), "escaped captor releases its attack turn")
	# Normal throws preserve chain capability, separate from third punch finishers.
	game.new_run(true)
	await process_frame
	hero = game.player
	game.debug_spawn_enemy(0)
	secondary = game.enemies[0]
	hero.position = Vector2(350, 420)
	hero.facing = 1
	secondary.position = Vector2(370, 420)
	hero.grapple.try_start()
	hero.grapple.launch()
	check(secondary.flight_can_hit, "normal grab throw enables one generation of flight impacts")
	print("ALL ", checks, " FLIGHT AND GRAPPLE CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
