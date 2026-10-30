extends SceneTree

var checks := 0

func check(value: bool, description: String) -> void:
	assert(value, description)
	checks += 1
	print("PASS: ", description)

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
		var captor = game.enemies[0]
		hero.position = Vector2(400, 420)
		hero.invincible = 0
		captor.position = Vector2(420, 420)
		captor.facing = -1
		game.combat_director.turns[captor] = 999
		check(captor.grapple.try_start(), "tier %d capture starts" % (tier + 1))
		var required: int = [3, 6, 9, 18][tier]
		check(captor.grapple.escape_required() == required, "escape threshold matches tier")
		for i in range(required - 1):
			Input.action_press("attack")
			hero.tick(0.016)
			Input.action_release("attack")
			hero.tick(0.016)
		check(is_instance_valid(hero.grabbed_by), "escape needs all required fresh presses")
		Input.action_press("attack")
		hero.tick(0.016)
		Input.action_release("attack")
		check(not is_instance_valid(hero.grabbed_by), "final required press frees the player")
	# A realistic single-button mash cannot reliably beat the boss's throw window.
	game.new_run(true)
	await process_frame
	game.debug_spawn_enemy(0, true)
	var hero = game.player
	var boss = game.enemies[0]
	hero.position = Vector2(400, 420)
	hero.invincible = 0
	boss.position = Vector2(420, 420)
	boss.facing = -1
	game.combat_director.turns[boss] = 999
	check(boss.max_hp == 520 and boss.max_hp > 260, "boss has double tier-three health regardless of base kind")
	check(boss.grapple.try_start(), "boss captures player for timing test")
	for action in boss.grapple.ESCAPE_ACTIONS:
		Input.action_press(action)
	hero.tick(0.016)
	check(boss.grapple.escape_presses == 1, "pressing all buttons simultaneously counts as one effort")
	for action in boss.grapple.ESCAPE_ACTIONS:
		Input.action_release(action)
	hero.tick(0.016)
	boss.grapple.punch_count = 2
	for i in range(40):
		if i % 4 == 0:
			Input.action_press("attack")
		else:
			Input.action_release("attack")
		hero.tick(0.032)
		boss.tick(0.032)
		if hero.thrown_time > 0:
			break
	Input.action_release("attack")
	check(hero.thrown_time > 0 and hero.hp == 45, "boss throws before eight presses per second can free player and deals 55 damage")
	# The boss's regular hit is stronger even when built from the weakest kind.
	game.new_run(true)
	await process_frame
	game.debug_spawn_enemy(0, true)
	hero = game.player
	boss = game.enemies[0]
	hero.invincible = 0
	boss.position = hero.position + Vector2(40, 0)
	boss.facing = -1
	boss.begin_attack()
	boss.strike()
	check(hero.hp == 64, "boss normal hit deals 36 rather than tier-three 26")
	# Both boss decisions are possible; neither permanently stalls a grip.
	hero.invincible = 0
	hero.stun = 0
	boss.attack_time = 0
	boss.cooldown = 0
	boss.position = hero.position + Vector2(20, 0)
	game.combat_director.turns[boss] = 999
	check(boss.grapple.try_start(), "boss captures player for decision test")
	seed(42)
	var decisions: Dictionary = {}
	for i in range(30):
		boss.grapple.state = "hold"
		boss.grapple.elapsed = 0.18
		boss.grapple.tick(0.016)
		decisions[boss.grapple.state] = true
	check(decisions.has("punch") and decisions.has("throw"), "boss can choose either a grab punch or a throw")
	boss.grapple.state = "punch"
	boss.grapple.select_punch_animation()
	boss.grapple.elapsed = 0
	boss.grapple.did_hit = false
	var before: float = hero.hp
	for i in range(15):
		boss.grapple.tick(0.016)
	check(hero.hp == before - 30, "boss grab punch deals thirty damage once")
	print("ALL ", checks, " GRIP TIER CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
