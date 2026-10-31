extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	var hero = game.player
	assert(hero.visual.sheets.has("crouch") and not InputMap.has_action("crouch"))
	var sheet: Image = hero.visual.sheets["crouch"].get_image()
	var idle: Image = hero.visual.sheets["idle"].get_image().get_region(Rect2i(0, 0, 200, 200))
	sheet.convert(Image.FORMAT_RGBA8)
	idle.convert(Image.FORMAT_RGBA8)
	assert(sheet.get_size() == Vector2i(800, 400))
	assert(sheet.get_region(Rect2i(0, 0, 200, 200)).get_data() == idle.get_data())
	var top := 0
	for index in range(8):
		var frame := sheet.get_region(Rect2i((index % 4) * 200, (index / 4) * 200, 200, 200))
		var bounds := frame.get_used_rect()
		assert(bounds.end.y == 189 and bounds.position.y >= top)
		top = bounds.position.y
		assert(frame.get_pixel(0, 0).a == 0)
	var at: Vector2 = hero.position
	var event := make_key()
	event.pressed = true
	Input.parse_input_event(event)
	hero.tick(0.1)
	assert(hero.visual.motion == "idle" and hero.position == at)
	event = make_key()
	event.pressed = false
	Input.parse_input_event(event)
	hero.begin_attack()
	assert(hero.pickup_target == null and hero.attack_time > 0)
	hero.attack_time = 0
	hero.cooldown = 0
	hero.hp = 20
	game.drop_food(hero.position + Vector2(20, 0))
	hero.begin_attack()
	assert(hero.visual.motion == "pickup")
	hero.tick(hero.visual.duration("pickup") * 0.51)
	assert(game.food[-1].dead and hero.visual.source_frame == 10)
	hero.tick(hero.visual.duration("pickup") * 0.51)
	assert(hero.visual.motion == "idle" and hero.position == at)
	print("ALL CROUCH CHECKS PASSED: aligned artwork, C inactive, attack picks up nearby items only")
	game.queue_free()
	await process_frame
	quit()

func make_key() -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_C
	return event
