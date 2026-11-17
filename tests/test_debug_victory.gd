extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var action_index := -1
	for index in range(game.debug_items_menu.ACTIONS.size()):
		if game.debug_items_menu.ACTIONS[index]["action"] == "victory":
			action_index = index
	assert(action_index >= 0)
	for id in ["beto", "cami", "alito", "meli", "malu", "pato", "dami", "vampi"]:
		game.active_character_id = id
		game.new_run(true)
		game.debug_spawn_enemy(0)
		var enemy = game.enemies[-1]
		var enemy_at: Vector2 = enemy.position
		var enemy_clock: float = enemy.anim
		var hero = game.player
		hero.hitstop_remaining = 0.1
		hero.height = 30
		hero.moving = true
		game.open_debug_items()
		game.debug_items_menu.choose(action_index)
		assert(not game.debug_items_menu.open and hero.visual.motion == "victory")
		assert(hero.height == 0 and hero.hitstop_remaining == 0)
		var duration: float = hero.visual.duration("victory")
		game.update_game(duration * 0.5)
		assert(hero.visual.source_frame == hero.visual.frame_at("victory", 0.5))
		game.update_game(duration * 0.5)
		assert(hero.visual.source_frame == int(hero.visual.definition("victory")["frame_indices"][-1]))
		Input.action_press("right")
		var at: Vector2 = hero.position
		game.update_game(4.99)
		assert(hero.visual.motion == "victory" and hero.position == at)
		assert(enemy.position == enemy_at and enemy.anim == enemy_clock)
		game.update_game(0.02)
		assert(game.debug_victory_elapsed < 0 and hero.visual.motion == "idle")
		game.update_game(0.04)
		assert(hero.position.x > at.x and hero.visual.motion == "walk")
		Input.action_release("right")
		game.debug_menu_action("victory")
		game.new_run(true)
		assert(game.debug_victory_elapsed < 0 and game.player.visual.motion == "idle")
	game.new_run(false)
	game.debug_preview_victory()
	assert(game.debug_victory_elapsed < 0, "preview is limited to the debug room")
	print("DEBUG VICTORY PASSED: menu action, all characters, playback + five second hold, idle, movement and reset")
	game.queue_free()
	await process_frame
	quit()
