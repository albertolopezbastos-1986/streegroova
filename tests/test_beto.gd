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
	var offline = preload("res://tests/mock_online.gd").new()
	game.add_child(offline)
	game.ranking_panel.service = offline
	game.new_run()
	await process_frame
	var hero = game.player
	hero.invincible = 0
	check(is_instance_valid(hero.visual) and hero.visual.motion == "idle", "player uses Beto's idle sheet")
	check(hero.visual.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "pixel textures use nearest filtering")
	for name in hero.visual.sheets:
		var data: Dictionary = hero.visual.definition(name)
		var expected := Vector2(float(data["frame_size"][0]) * float(data["sheet_columns"]), float(data["frame_size"][1]) * float(data["sheet_rows"]))
		check(hero.visual.sheets[name].get_size() == expected, "sheet available: " + name)
	check(hero.visual.definition("attack_01")["frame_indices"].size() == 40 and hero.visual.frame_at("attack_01", 1.0) == 39, "first punch uses 40 frames and skips the two empty cells")
	check(is_equal_approx(hero.visual.duration("attack_01"), 9.0 / (22.0 * 1.15)), "first punch uses the faster combo timing")
	Input.action_press("right")
	hero.tick(0.05)
	check(hero.visual.motion == "walk" and hero.visual.source_frame != 0, "movement advances the new walk cycle")
	Input.action_release("right")
	Input.action_press("left")
	hero.tick(0.05)
	check(hero.visual.facing == -1, "walking left mirrors Beto")
	Input.action_release("left")
	hero.tick(0.05)
	check(hero.visual.motion == "idle", "releasing direction returns to idle")
	hero.facing = 1
	var target = game.enemies[0]
	target.position = hero.position + Vector2(45, 0)
	target.hp = 1000
	target.max_hp = 1000
	target.invincible = 0
	var before: float = target.hp
	hero.combo_window = 0
	hero.begin_attack()
	hero.tick(0.1)
	check(target.hp == before and hero.visual.motion == "attack_01", "first punch wind-up cannot deal damage")
	for i in range(3):
		hero.tick(0.016)
	check(hero.visual.source_frame >= 13 and hero.visual.source_frame <= 22 and target.hp < before, "40-frame punch damage matches extended-arm contact frames")
	var after: float = target.hp
	for i in range(8):
		hero.tick(0.016)
	check(target.hp == after, "contact frames only damage each target once")
	while hero.attack_time > 0.06:
		hero.tick(0.016)
	# Queue a second press just before recovery ends; the next attack must start.
	Input.action_press("attack")
	hero.tick(0.001)
	Input.action_release("attack")
	await process_frame
	for i in range(12):
		hero.tick(0.016)
	check(hero.combo == 1 and hero.visual.motion == "attack_02", "buffered press chains second punch")
	hero.begin_attack()
	check(hero.combo == 2 and hero.visual.motion == "attack_03", "third combo move uses guitar sheet")
	hero.attack_time = 0
	hero.cooldown = 0
	hero.combo_window = 0
	Input.action_press("jump")
	hero.tick(0.016)
	Input.action_release("jump")
	await process_frame
	check(hero.visual.motion == "jump" and hero.visual.position.y < 0, "jump sheet follows physical jump height")
	hero.begin_attack()
	check(hero.visual.motion == "jump_attack", "air attack uses flying kick sheet")
	target.position = hero.position + Vector2(45, 0)
	target.invincible = 0
	before = target.hp
	hero.strike()
	check(target.hp == before - 29 and target.thrown_time > 0 and target.jump_speed > 0 and target.velocity.x == target.THROW_SPEED, "flying kick launches its victim forward and upward")
	var launch_x: float = target.position.x
	target.tick(0.05)
	check(target.position.x > launch_x and target.height > 25 and target.visual.motion == "death" and not target.dead, "kicked survivor flies through the air with knockdown animation")
	hero.strike()
	check(target.hp == before - 29, "flying kick damages its victim only once")
	for i in range(80):
		hero.tick(0.016)
	check(hero.height == 0 and not hero.air_attack and hero.visual.motion == "idle", "landing ends aerial motion cleanly")
	hero.invincible = 0
	hero.hurt(10, -1)
	check(hero.visual.motion == "hurt", "damage starts damage sheet immediately")
	for i in range(25):
		hero.tick(0.016)
	check(hero.visual.motion == "idle", "damage animation recovers to guard")
	game.charge = 100
	game.use_ultimate()
	check(hero.visual.motion == "ultimate", "ultimate uses guitar wind-up")
	game.ult_time = 0.6
	hero.update_visual(0.01)
	check(hero.visual.source_frame >= 6, "ultimate impact uses guitar sweep frames")
	game.ult_time = 0
	hero.ultimate_pose = 0
	hero.height = 65
	game.charge = 100
	game.use_ultimate()
	check(hero.ultimate_airborne and hero.visual.motion == "ultimate_air", "ultimate activated mid-jump selects a distinct aerial animation")
	check(hero.visual.sheets["ultimate_air"] == hero.visual.sheets["ultimate"] and hero.visual.definition("ultimate_air")["placeholder"], "aerial ultimate temporarily shares ground art")
	game.ult_time = 0.6
	hero.height = 0
	hero.update_visual(0.01)
	check(hero.visual.motion == "ultimate_air" and hero.visual.source_frame >= 6, "aerial variant retains its identity and impact timing throughout ultimate")
	game.ult_time = 0
	hero.ultimate_pose = 0
	game.charge = 100
	game.use_ultimate()
	check(not hero.ultimate_airborne and hero.visual.motion == "ultimate", "next grounded ultimate resets aerial variant")
	game.ult_time = 0
	hero.ultimate_pose = 0
	hero.invincible = 0
	hero.height = 65
	hero.hurt(1000, 1)
	check(hero.visual.motion == "death", "lethal damage uses KO sheet")
	for i in range(75):
		hero.tick(0.016)
	check(hero.height == 0 and hero.visual.source_frame == 8, "air KO falls to floor and holds final frame")
	game.respawn_time = 1.39
	game.freeze = 0
	game.update_game(0.02)
	check(not hero.dead and hero.visual.motion == "idle", "respawn resets Beto to idle")
	print("ALL ", checks, " BETO CHECKS PASSED")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
