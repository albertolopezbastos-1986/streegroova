extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for id in ["beto", "cami"]:
		for direction in [1.0, -1.0]:
			game.active_character_id = id
			game.new_run(true)
			await process_frame
			game.debug_spawn_enemy(0)
			var hero = game.player
			var enemy = game.enemies[-1]
			var grab = hero.grapple
			hero.position = Vector2(400, 390)
			hero.facing = direction
			enemy.position = hero.position + Vector2(direction * 20, 0)
			enemy.hp = 1000
			assert(hero.visual.sheets["grab"].resource_path == "res://assets/characters/%s/animations/grab/grab.png" % id)
			assert(grab.try_start())
			assert(hero.visual.motion == "grab" and hero.visual.source_frame == 0)
			var hold_frame := 2
			for frame in range(hold_frame + 1):
				grab.elapsed = (frame + 0.1) / 40.0
				hero.update_visual(0)
				assert(hero.visual.motion == "grab" and hero.visual.source_frame == frame)
			hero.tick(0.025)
			assert(grab.state == "hold" and hero.visual.source_frame == hold_frame)
			hero.tick(0.3)
			enemy.tick(0.3)
			assert(hero.visual.motion == "grab" and hero.visual.source_frame == hold_frame)
			assert(enemy.grabbed_by == hero and enemy.visual.motion == "hurt")
			assert(enemy.position.is_equal_approx(hero.position + Vector2(direction * 32, 0)))
			# A grab punch returns to the character's own held pose.
			grab.state = "punch"
			grab.select_punch_animation()
			grab.elapsed = 0
			hero.update_visual(0)
			if id == "beto":
				assert(hero.visual.source_frame == 3)
				assert(hero.visual.definition("grab_punch_01")["frame_indices"] == range(3, 13))
			while grab.state == "punch":
				hero.tick(0.005)
			assert(enemy.hp == 981 and enemy.grabbed_by == hero)
			assert(grab.state == "hold" and hero.visual.motion == "grab" and hero.visual.source_frame == hold_frame)
			grab.state = "throw"
			grab.elapsed = 0
			hero.update_visual(0)
			assert(hero.visual.motion == "grab_throw")
			assert(hero.visual.source_frame == (9 if id == "beto" else 0))
			var throw_data: Dictionary = hero.visual.definition("grab_throw")
			var first := int(throw_data.get("throw_start_frame", int(throw_data.get("hold_frame", 8)) + 1))
			if id == "cami":
				assert(hero.visual.sheets["grab_throw"].resource_path.ends_with("cami/animations/grab_throw/grabthrow.png"))
				assert(not throw_data["placeholder"])
				for frame in range(9):
					grab.elapsed = (frame + 0.1) / 40.0
					hero.update_visual(0)
					assert(hero.visual.source_frame == frame, "throw plays the nine supplied frames in order")
				grab.elapsed = 0
			var release_time := float(int(throw_data["release_frame"]) - first) / (float(throw_data["fps"]) * 2)
			hero.tick(release_time - 0.001)
			assert(enemy.grabbed_by == hero, "victim remains held until the release frame")
			hero.tick(0.002)
			assert(enemy.grabbed_by == null and enemy.thrown_time > 0 and enemy.hp == 941)
			assert(enemy.velocity.x * direction < 0)
			while grab.active():
				hero.tick(0.005)
			assert(hero.visual.motion == "idle")
			print("PASS: ", id, " direction=", direction, " own capture, hold, punch return and synchronized throw")
	# The three Cami grab punches share the supplied knee art, skipping frame 0.
	for direction in [1.0, -1.0]:
		game.active_character_id = "cami"
		game.new_run(true)
		await process_frame
		game.debug_spawn_enemy(0)
		var hero = game.player
		var enemy = game.enemies[-1]
		hero.position = Vector2(400, 390)
		hero.facing = direction
		enemy.position = hero.position + Vector2(direction * 20, 0)
		enemy.hp = 1000
		assert(hero.grapple.try_start())
		hero.tick(0.08)
		for step in range(1, 4):
			var name := "grab_punch_%02d" % step
			assert(hero.visual.definition(name)["frame_indices"] == range(1, 9))
			hero.grapple.state = "punch"
			hero.grapple.elapsed = 0
			hero.grapple.did_hit = false
			hero.grapple.select_punch_animation()
			hero.update_visual(0)
			assert(hero.visual.motion == name and hero.visual.source_frame == 1)
			assert(hero.visual.sheets[name].resource_path.ends_with("cami/animations/%s/grabpunch.png" % name))
			while hero.grapple.state in ["punch", "punch_recover"]:
				hero.tick(0.005)
				if hero.visual.motion == name:
					assert(hero.visual.source_frame != 0)
			assert(enemy.hp == 1000 - 19 * step, "each grab punch damages exactly once")
			if step < 3:
				assert(hero.grapple.state == "hold" and hero.visual.source_frame == 2)
				assert(enemy.grabbed_by == hero)
			else:
				assert(not hero.grapple.active() and enemy.grabbed_by == null)
				assert(enemy.thrown_time > 0 and enemy.velocity.x * direction > 0)
		print("PASS: Cami three grab knees skip frame 0, hit once and launch on third, direction=", direction)
	# Characters without a separate grab keep the combined sheet.
	game.active_character_id = "alito"
	game.new_run(true)
	await process_frame
	assert(game.player.grapple.catch_motion() == "grab_throw")
	print("GRAB ANIMATIONS PASSED")
	game.queue_free()
	await process_frame
	quit()
