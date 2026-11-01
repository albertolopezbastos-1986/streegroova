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
	for heavy in [false, true]:
		hero.invincible = 0
		hero.hp = 100
		hero.hurt(1, 1, heavy)
		assert(hero.hp == 99 and hero.visual.motion == "hurt")
		assert(hero.visual.sheets["hurt"].resource_path.ends_with("cami/animations/hurt/hurt.png"))
		assert(is_equal_approx(hero.hurt_duration, 0.44 if heavy else 0.36))
		assert(hero.visual.definition("hurt")["frame_indices"] == range(9))
		for progress in [0.0, 0.5, 0.99]:
			hero.stun = hero.hurt_duration * (1.0 - progress)
			hero.update_visual(0)
			assert(hero.visual.source_frame == mini(int(progress * 9), 8), "hurt frames follow the entire damage reaction")
		hero.tick(0.02)
		assert(hero.stun == 0 and hero.visual.motion == "idle", "damage recovery returns to idle")
	print("CAMI HURT PASSED: own nine frames, normal/heavy damage timing, full reaction and recovery")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
