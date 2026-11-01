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
	assert(hero.visual.definition("victory")["frame_indices"] == range(41))
	for time in [0.0, 0.5, 1.0, 2.0, 5.0, 10.0]:
		hero.victory_time = time
		hero.update_visual(0)
		assert(hero.visual.motion == "victory")
		assert(hero.visual.sheets["victory"].resource_path.ends_with("cami/animations/victory/victory.png"))
		assert(hero.visual.source_frame == mini(int(time * 24), 40))
		assert(hero.visual.position.y == 0, "victory uses her own pose without placeholder hopping")
	hero.victory_time = -1
	hero.update_visual(0)
	assert(hero.visual.motion == "idle")
	print("CAMI VICTORY PASSED: 41 frames, own pose, final frame holds, no hopping, return to idle")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
