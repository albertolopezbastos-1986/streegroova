extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func press_zero(game, echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_0
	event.pressed = true
	event.echo = echo
	game._input(event)
func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run()
	game.enable_level_skip = false
	press_zero(game)
	assert(game.state == "play" and game.enemies.any(func(enemy): return not enemy.dead))
	game.enable_level_skip = true
	press_zero(game, true)
	assert(game.state == "play")
	press_zero(game)
	assert(game.state == "stage_clear" and game.presentation_time == 0 and game.player.victory_time == 0)
	assert(game.enemies.all(func(enemy): return enemy.dead))
	game.update_presentation(game.STAGE_CLEAR_DURATION)
	assert(game.state == "fade_out")
	game.new_run()
	game.level_index = game.LEVEL_COUNT - 1
	press_zero(game)
	assert(game.state == "victory" and game.presentation_time == 0)
	game.new_run(true)
	game.debug_spawn_enemy(0)
	press_zero(game)
	assert(game.state == "play" and game.enemies.all(func(enemy): return enemy.dead))
	print("ALL LEVEL SKIP CHECKS PASSED: flag off/on, celebration, countdown, final victory, debug unchanged")
	game.queue_free()
	await process_frame
	quit()
