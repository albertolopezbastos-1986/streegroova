extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for id in ["beto", "alito", "cami", "dami", "malu", "meli", "pato", "vampi"]:
		game.active_character_id = id
		game.new_run(true)
		var hero = game.player
		hero.hitstop_remaining = 10.0 / 60.0
		game.complete_level()
		assert(hero.hitstop_remaining == 0 and hero.visual.motion == "victory", "finishing hitstop cannot block celebration")
		assert(hero.visual.sheets["victory"].resource_path == "res://assets/characters/%s/animations/victory/victory.png" % id)
		var data: Dictionary = hero.visual.definition("victory")
		var frames: Array = data["frame_indices"]
		var duration: float = hero.visual.duration("victory")
		assert(not data["loop"])
		for index in range(frames.size()):
			hero.victory_time = (index + 0.1) / float(data["fps"])
			hero.update_visual(0)
			assert(hero.visual.motion == "victory" and hero.visual.source_frame == int(frames[index]))
			assert(hero.visual.position.y == 0)
		hero.victory_time = duration + 10
		hero.update_visual(0)
		assert(hero.visual.source_frame == int(frames[-1]), "holds final victory pose")
		hero.victory_time = -1
		hero.update_visual(0)
		assert(hero.visual.motion == "idle")
	print("VICTORY POSES PASSED: all eight characters, frame order, final pose and return to idle")
	game.queue_free()
	await process_frame
	quit()
