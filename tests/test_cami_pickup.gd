extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.active_character_id = "cami"
	game.new_run(true)
	await process_frame
	var hero = game.player
	var sequence := range(8) + range(6, 0, -1)
	assert(hero.visual.definition("pickup")["frame_indices"] == sequence)
	assert(hero.visual.definition("crouch")["frame_indices"] == sequence)
	for i in range(sequence.size()):
		assert(hero.visual.frame_at("pickup", (i + 0.1) / sequence.size()) == sequence[i])
	game.drop_food(hero.position)
	var food = game.food[0]
	food.beer = false
	hero.hp = 20
	hero.begin_pickup(food)
	var duration: float = hero.visual.duration("pickup")
	assert(is_equal_approx(duration, 14.0 / 16.0), "removing eight held frames shortens pickup by half a second")
	hero.tick(duration * 0.49)
	assert(not food.dead and hero.hp == 20)
	hero.tick(duration * 0.02)
	assert(food.dead and hero.hp == 95 and hero.visual.source_frame == 7)
	hero.tick(duration * 0.48)
	assert(hero.visual.source_frame == 1, "reverse sequence ends with arms raised on frame 1")
	hero.tick(duration * 0.02)
	assert(hero.pickup_target == null and hero.visual.motion == "idle")
	assert(game.spawn_weapon(hero.position, "pipe") == null)
	assert(game.spawn_weapon(hero.position, "wood") == null)
	assert(game.weapons.is_empty())
	print("CAMI PICKUP PASSED: trimmed 0–7 then 6–1 sequence, food pickup, raised arms on recovery, no weapons")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
