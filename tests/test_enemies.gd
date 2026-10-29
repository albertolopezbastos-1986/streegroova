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
	seed(3456)
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run()
	await process_frame
	var hero = game.player
	hero.invincible = 999
	for enemy in game.enemies:
		check(is_instance_valid(enemy.visual), "enemy has pixel sprite renderer")
		check(enemy.visual.sheets["idle"] == hero.visual.sheets["idle"], "enemy clones Beto's actual sprite sheets")
		check(enemy.visual.definition("attack_01")["frame_indices"].size() == 40, "enemy shares the 40-frame first punch")
		check(enemy.visual.material is ShaderMaterial, "enemy has a separate clothing palette")
		check(not enemy.can_use_ultimate(), "enemy has no ultimate permission")
	var enemy = game.enemies[0]
	# Isolate animation/move coverage from the separately tested group director.
	game.combat_director.turns[enemy] = 999.0
	enemy.position = hero.position + Vector2(45, 0)
	enemy.ai_wait = 0
	enemy.cooldown = 0
	enemy.ai_jump_cooldown = 100
	var attacks: Dictionary = {}
	var telegraphed := false
	for i in range(360):
		enemy.tick(0.016)
		telegraphed = telegraphed or enemy.windup > 0
		if enemy.visual.motion.begins_with("attack_"):
			attacks[enemy.visual.motion] = true
	check(telegraphed, "enemy telegraphs its ground attacks")
	check(attacks.has("attack_01") and attacks.has("attack_02") and attacks.has("attack_03"), "AI executes all three grounded combo moves")
	enemy.position = hero.position + Vector2(120, 0)
	enemy.attack_time = 0
	enemy.windup = 0
	enemy.cooldown = 0
	enemy.ai_wait = 0
	enemy.ai_jump_cooldown = 0
	enemy.tick(0.016)
	check(enemy.height > 0 and enemy.velocity.x < 0 and enemy.visual.motion == "jump", "AI jumps forward to close distance")
	var kicked := false
	for i in range(60):
		enemy.tick(0.016)
		kicked = kicked or (enemy.visual.motion == "jump_attack" and enemy.height > 0)
	check(kicked, "AI converts its approach jump to flying kick")
	check(enemy.height == 0, "enemy lands after its aerial attack")
	enemy.position = hero.position + Vector2(45, 0)
	enemy.attack_time = 0
	enemy.windup = 0
	enemy.cooldown = 0
	enemy.ai_wait = 0
	enemy.ai_jump_cooldown = 0
	hero.attack_time = 0.1
	enemy.tick(0.016)
	check(enemy.height > 0 and enemy.velocity == Vector2.ZERO, "AI can neutral-jump to evade a close attack")
	hero.attack_time = 0
	enemy.height = 0
	enemy.jump_speed = 0
	enemy.air_attack = false
	enemy.attack_time = 0
	hero.hp = 100
	hero.invincible = 0
	hero.height = 70
	enemy.begin_attack()
	enemy.strike()
	check(hero.hp == 100, "ground punch cannot hit a high airborne player")
	enemy.height = 70
	enemy.begin_attack()
	enemy.strike()
	check(hero.hp < 100, "air kick can hit a player at matching height")
	enemy.ultimate_pose = 1
	enemy.update_visual(0)
	check(enemy.visual.motion != "ultimate", "enemy cannot enter ultimate animation even with pose timer set")
	game.charge = 100
	game.ult_time = 0
	game.use_ultimate(enemy)
	check(game.charge == 100 and game.ult_time == 0, "enemy cannot spend player's ultimate or trigger its screen-wide hit")
	enemy.ultimate_pose = 0
	enemy.height = 0
	enemy.jump_speed = 0
	enemy.ai_wait = 100
	enemy.cooldown = 100
	enemy.invincible = 0
	enemy.hurt(10, -1)
	check(enemy.visual.motion == "hurt", "enemy uses Beto's damage animation")
	for i in range(25):
		enemy.tick(0.016)
	check(enemy.visual.motion != "hurt", "enemy recovers after damage")
	enemy.invincible = 0
	enemy.hurt(1000, -1)
	check(enemy.dead and enemy.visual.motion == "death", "enemy uses Beto's KO animation")
	for i in range(75):
		enemy.tick(0.016)
	check(enemy.visual.source_frame == 8, "enemy KO reaches final lying-down frame")
	for i in range(40):
		enemy.tick(0.016)
	check(not enemy.visual.visible, "defeated clone fades after KO instead of staying in the lane")
	check(game.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "pixel environment uses nearest texture filtering")
	check(game.PIXEL_STREET.get_size() == Vector2(1536, 1024), "pixel background asset is loaded")
	print("ALL ", checks, " ENEMY CHECKS PASSED")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
