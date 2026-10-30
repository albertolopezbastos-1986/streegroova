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
	check(ProjectSettings.get_setting("display/window/size/viewport_height") == 640, "viewport matches the backgrounds' 3:2 aspect ratio")
	check(is_equal_approx(960.0 / game.VIEW_HEIGHT, game.ENVIRONMENT_SOURCE_SIZE.x / game.ENVIRONMENT_SOURCE_SIZE.y), "viewport preserves native background proportions")
	check(game.CURB_TOP_Y > game.WALK_MIN_Y and game.CURB_BOTTOM_Y < game.WALK_MAX_Y, "walkable floor spans sidewalk and asphalt")
	check(is_equal_approx(game.CURB_TOP_Y - game.FLOOR_BACK_Y, 182.0 * 492 / 1536), "sidewalk keeps the image's original height")
	check(is_equal_approx(game.WALK_MAX_Y - game.CURB_BOTTOM_Y, 60.0 * 492 / 1536), "lower floor uses the remaining image without repeated strips")
	var hero = game.player
	hero.invincible = 0
	check(game.world.scale == Vector2(1.96875, 1.96875), "world has 1.96875x framing")
	check(is_equal_approx(game.WORLD_ZOOM / 2.625, 0.75), "zoom is exactly 25 percent lower than previous framing")
	check(is_equal_approx(game.world_to_screen(hero.position).y, game.VIEW_HEIGHT - 26 - (game.WALK_MAX_Y - game.START_Y) * game.WORLD_ZOOM), "player feet stay above the bottom HUD")
	check(is_equal_approx(game.world_to_screen(Vector2(0, 99 + 1024.0 * 492 / 1536)).y, game.VIEW_HEIGHT - 26), "complete background ends exactly at the bottom HUD")
	check(game.world_to_screen(hero.position).distance_to(hero.global_position) < 0.01, "effects transform matches actor transform")
	check(is_equal_approx(float(hero.visual.character_data.scale), 0.6), "zoom preserves character's configured sprite scale")
	for enemy in game.enemies:
		check(enemy.position.y >= game.WALK_MIN_Y and enemy.position.y <= game.WALK_MAX_Y, "enemy spawns in sidewalk combat lane")
		check(game.world_to_screen(enemy.position).x < 960, "first encounter is visible at the closer zoom")
	check(game.WALK_MAX_Y - game.WALK_MIN_Y == 77, "walking stays inside the complete background")
	Input.action_press("up")
	for i in range(160):
		hero.tick(0.016)
	Input.action_release("up")
	check(hero.position.y == game.WALK_MIN_Y, "back of sidewalk blocks walking through the wall")
	Input.action_press("jump")
	hero.tick(0.016)
	Input.action_release("jump")
	await process_frame
	var top: float = game.VIEW_HEIGHT
	for i in range(70):
		hero.tick(0.016)
		game.update_world_transform()
		# Highest solid pixels are about 10 pixels below the top of each cell.
		top = minf(top, game.world_to_screen(hero.position - Vector2(0, hero.height + 108)).y)
	check(top >= 92, "jump at back of sidewalk clears the HUD")
	check(hero.height == 0, "jump still lands with zoomed world")
	Input.action_press("down")
	for i in range(160):
		hero.tick(0.016)
	Input.action_release("down")
	check(hero.position.y == game.WALK_MAX_Y and game.world_to_screen(hero.position).y <= game.VIEW_HEIGHT - 26, "foreground movement stays above bottom HUD")
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
	game.camera_x = 0
	game.camera_peak_x = 0
	game.left_bound = 30
	for i in range(160):
		game.update_game(0.016)
	game.update_world_transform()
	check(absf(game.world_to_screen(hero.position).x - game.CAMERA_ANCHOR_X) < 0.1, "scrolling keeps player in the left third of the screen")
	hero.moving = true
	hero.velocity = Vector2(-170, 0)
	var peak: float = game.camera_peak_x
	var smooth := true
	for i in range(120):
		hero.position.x -= 170 * 0.016
		var previous: float = game.camera_x
		game.update_camera(0.016)
		if absf(game.camera_x - previous) > 15:
			smooth = false
	game.update_world_transform()
	check(game.camera_x >= peak - game.BACKTRACK_DISTANCE, "walking left cannot reopen the previous scenery")
	check(smooth, "camera changes directional framing smoothly")
	hero.moving = false
	hero.velocity = Vector2.ZERO
	for i in range(180):
		game.update_camera(0.016)
	game.update_world_transform()
	check(game.camera_x >= peak - game.BACKTRACK_DISTANCE and hero.position.x >= game.left_bound - 0.01, "stopping preserves the limited backtrack area")
	hero.moving = true
	hero.velocity.x = 170
	for i in range(120):
		hero.position.x += 170 * 0.016
		game.update_camera(0.016)
	game.update_world_transform()
	check(game.world_to_screen(hero.position).x < 420, "walking right restores forward camera margin")
	hero.moving = false
	hero.velocity = Vector2.ZERO
	hero.position.x = 30
	for i in range(180):
		game.update_camera(0.016)
	check(game.camera_x >= game.camera_peak_x - game.BACKTRACK_DISTANCE and hero.position.x >= game.left_bound - 0.01, "old areas stay closed after advancing")
	print("ALL ", checks, " FRAMING CHECKS PASSED")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
