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
	for i in range(2):
		game.debug_spawn_enemy(0)
	var living = game.enemies[0]
	var corpse = game.enemies[1]
	living.position = Vector2(300, 350)
	corpse.position = Vector2(300, 430)
	living.launch_away(5, 1, false)
	corpse.launch_away(1000, 1, false)
	for i in range(32):
		living.tick(0.016)
		corpse.tick(0.016)
	check(living.jump_speed < 0 and corpse.jump_speed < 0 and living.height > 0 and corpse.height > 0, "living and KO bodies are falling while still airborne")
	check(living.velocity.x == 380 and corpse.velocity.x == 380, "both bodies retain lateral momentum throughout flight")
	check(living.position.x > 490 and corpse.position.x > 490, "KO bodies travel as far as living bodies")
	var previous_x: float = corpse.position.x
	for i in range(20):
		living.tick(0.016)
		corpse.tick(0.016)
	check(living.height == 0 and corpse.height == 0 and corpse.position.x > previous_x, "bodies continue advancing as they descend and land")
	check(living.velocity.x > 0 and corpse.velocity.x > 0 and living.velocity.x < 380, "ground friction brakes bodies after landing")
	var smooth_stop := true
	var previous_speed: float = living.velocity.x
	for i in range(100):
		living.tick(0.016)
		corpse.tick(0.016)
		var speed: float = living.velocity.x
		if previous_speed - speed > living.THROW_GROUND_BRAKE * 0.016 + 0.01:
			smooth_stop = false
		previous_speed = speed
		if living.getup_time > 0:
			break
	check(smooth_stop and living.velocity.x == 0, "recovery waits for natural deceleration rather than cutting momentum")
	check(corpse.dead and corpse.height == 0 and living.getup_time > 0, "KO remains down while living fighter starts getting up")
	print("ALL ", checks, " THROW MOTION CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
