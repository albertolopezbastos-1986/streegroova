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
	hero.invincible = 0
	check(game.world.scale == Vector2(1.96875, 1.96875), "world has 1.96875x framing")
	check(is_equal_approx(game.WORLD_ZOOM / 2.625, 0.75), "zoom is exactly 25 percent lower than previous framing")
	check(is_equal_approx(game.world_to_screen(hero.position).y, 480), "player feet start on the foreground sidewalk")
	check(game.world_to_screen(hero.position).distance_to(hero.global_position) < 0.01, "effects transform matches actor transform")
	check(is_equal_approx(float(hero.visual.character_data.scale), 0.6), "zoom preserves character's configured sprite scale")
	for enemy in game.enemies:
		check(enemy.position.y >= game.WALK_MIN_Y and enemy.position.y <= game.WALK_MAX_Y, "enemy spawns in sidewalk combat lane")
		check(game.world_to_screen(enemy.position).x < 960, "first encounter is visible at the closer zoom")
	Input.action_press("up")
	for i in range(80):
		hero.tick(0.016)
	Input.action_release("up")
	check(hero.position.y == game.WALK_MIN_Y, "back of sidewalk blocks walking through the wall")
	Input.action_press("jump")
	hero.tick(0.016)
	Input.action_release("jump")
	await process_frame
	var top := 540.0
	for i in range(70):
		hero.tick(0.016)
		game.update_world_transform()
		# Highest solid pixels are about 10 pixels below the top of each cell.
		top = minf(top, game.world_to_screen(hero.position - Vector2(0, hero.height + 108)).y)
	check(top >= 92, "jump at back of sidewalk clears the HUD")
	check(hero.height == 0, "jump still lands with zoomed world")
	Input.action_press("down")
	for i in range(80):
		hero.tick(0.016)
	Input.action_release("down")
	check(hero.position.y == game.WALK_MAX_Y and game.world_to_screen(hero.position).y < 520, "curb blocks walking into the street")
	hero.facing = 1
	var target = game.enemies[0]
	target.position = hero.position + Vector2(45, -game.MELEE_DEPTH - 1)
	target.invincible = 0
	var hp: float = target.hp
	hero.begin_attack()
	hero.strike()
	check(target.hp == hp, "melee respects sidewalk depth instead of hitting every lane")
	target.position.y = hero.position.y
	hero.strike()
	check(target.hp < hp, "same-lane melee still hits")
	hero.attack_time = 0
	game.freeze = 0
	game.right_bound = game.LEVEL_WIDTH
	for enemy in game.enemies:
		enemy.cooldown = 100
	hero.position.x = game.LEVEL_WIDTH - 50
	for i in range(160):
		game.update_game(0.016)
	game.shake = 0
	game.update_world_transform()
	var right_edge: Vector2 = game.world_to_screen(Vector2(game.LEVEL_WIDTH, game.START_Y))
	check(absf(right_edge.x - 960) < 0.1, "camera uses zoomed viewport width at end of level")
	hero.position.x = 1000
	for i in range(160):
		game.update_game(0.016)
	game.update_world_transform()
	check(absf(game.world_to_screen(hero.position).x - game.CAMERA_ANCHOR_X) < 0.1, "scrolling keeps player in the left third of the screen")
	print("ALL ", checks, " FRAMING CHECKS PASSED")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
