extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game.current_music == "intro" and game.music.stream.resource_path.ends_with("Intro.wav"))
	var intro = game.music.stream
	game.show_character_selection()
	assert(game.current_music == "intro" and game.music.stream == intro, "selection continues intro")
	for level in range(3):
		game.begin_level_transition(level == 0)
		game.update_level_transition(game.FADE_DURATION)
		assert(game.state == "map_in" and game.current_music == game.LEVEL_MUSIC[level])
		var track = game.music.stream
		game.update_level_transition(game.FADE_DURATION)
		game.update_level_transition(game.MAP_DURATION)
		game.update_level_transition(game.FADE_DURATION)
		game.update_level_transition(game.BLACK_HOLD_DURATION)
		game.update_level_transition(game.FADE_DURATION)
		game.update_level_transition(5)
		game.update_level_transition(game.START_DURATION)
		assert(game.state == "play" and game.music.stream == track, "level continues map music")
	game.activate_screen("concert")
	assert(game.current_music == "3d" and game.music.stream.resource_path.ends_with("3D.wav"))
	game.activate_screen("title")
	assert(game.current_music == "intro")
	print("MUSIC PASSED: intro and selection, three maps and levels, final stage, return to title")
	game.queue_free()
	await process_frame
	quit()
