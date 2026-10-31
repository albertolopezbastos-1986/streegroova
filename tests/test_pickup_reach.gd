extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	var hero = game.player
	var data: Dictionary = hero.visual.definition("pickup")
	assert(data["frame_count"] == 11 and data["collect_progress"] == 0.5)
	assert(hero.visual.sheets["pickup"] != hero.visual.sheets["crouch"])
	var previous_y := 130.0
	for frame in [8, 9, 10]:
		var hand: Vector2 = hero.visual.weapon_hand_position("pickup", frame)
		assert(hand.y > previous_y)
		previous_y = hand.y
	assert(previous_y > 170)
	hero.position = Vector2(350, 420)
	hero.hp = 20
	game.drop_food(hero.position + Vector2(20, 0))
	var food = game.food[-1]
	food.beer = false
	hero.begin_attack()
	var duration: float = hero.visual.duration("pickup")
	hero.tick(duration * 0.49)
	assert(not food.dead and hero.hp == 20 and hero.visual.source_frame == 10)
	hero.tick(duration * 0.02)
	assert(food.dead and hero.hp == 95 and hero.visual.source_frame == 10)
	hero.tick(duration * 0.2)
	assert(hero.visual.source_frame < 10 and hero.pickup_target != null)
	hero.tick(duration * 0.3)
	assert(hero.pickup_target == null and hero.visual.motion == "idle")
	print("ALL PICKUP REACH CHECKS PASSED: hand lowers in 3 frames, contact grants item, arm retracts and actor stands")
	game.queue_free()
	await process_frame
	quit()
