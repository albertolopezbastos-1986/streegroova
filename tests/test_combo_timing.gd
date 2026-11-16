extends SceneTree

const Catalog = preload("res://scripts/character_catalog.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var beto: Dictionary = Catalog.character("beto")["definition"]
	for id in ["beto", "cami", "dami", "pato", "vampi", "alito", "malu", "meli"]:
		game.active_character_id = id
		game.new_run(true)
		var hero = game.player
		var ratio := 2.0 if id in ["alito", "malu", "meli"] else 1.0
		for step in range(hero.player_combo().size()):
			hero.combo = step - 1
			hero.combo_window = 1
			hero.combo_connected = true
			hero.begin_attack()
			var name: String = hero.attack_motion()
			var reference: Dictionary = beto["animations"][name]
			var expected := float(reference["frame_indices"].size()) / float(reference["fps"]) * float(beto["combo_duration_multiplier"]) * ratio
			assert(is_equal_approx(hero.attack_duration, expected), id + " timing for " + name)
			assert(is_equal_approx(hero.cooldown, expected + 0.015))
			if ratio > 1:
				assert(hero.attack_duration < 0.5, "intermediate group attacks faster than before")
			hero.attack_time = hero.attack_duration * 0.5
			hero.update_visual(0)
			assert(hero.visual.source_frame == hero.visual.frame_at(name, 0.5))
			hero.attack_time = 0
	print("COMBO TIMING PASSED: Beto reference, intermediate group, cooldown and animation progress")
	game.queue_free()
	await process_frame
	quit()
