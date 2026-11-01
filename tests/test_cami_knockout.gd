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
	hero.invincible = 0
	hero.hurt(1000, 1, true)
	assert(hero.dead and hero.hp == 0)
	assert(hero.visual.definition("death")["frame_indices"] == range(41))
	assert(hero.visual.duration("death") < 1.4, "fall finishes before respawn")
	for time in [0.0, 0.5, 1.0, 1.39, 5.0]:
		hero.death_time = time
		hero.update_visual(0)
		assert(hero.visual.motion == "death")
		assert(hero.visual.sheets["death"].resource_path.ends_with("cami/animations/death/knockout.png"))
		assert(hero.visual.source_frame == mini(int(time * 30), 40), "knockout plays through and holds final ground pose")
	game.new_run(true)
	await process_frame
	hero = game.player
	hero.invincible = 0
	assert(hero.launch_away(1, 1))
	assert(not hero.dead and hero.visual.motion == "death", "nonlethal knockdown also uses Cami knockout art")
	print("CAMI KNOCKOUT PASSED: lethal and nonlethal falls, 41 frames, final pose holds, completed before respawn")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
