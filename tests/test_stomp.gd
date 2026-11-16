extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for id in ["beto", "alito", "cami", "meli", "malu", "pato", "dami", "vampi"]:
		game.active_character_id = id
		game.new_run(true)
		var hero = game.player
		assert(hero.visual.sheets.has("stomp"), id + " has stomp")
		assert(hero.visual.sheets["stomp"].resource_path.ends_with(id + "/animations/stomp/stomp.png"))
		assert(not hero.visual.definition("stomp")["placeholder"])
		for item_kind in ["crate", "barrel"]:
			game.debug_spawn_item(item_kind)
			var prop = game.props[-1]
			hero.position = prop.position - Vector2(40, 0)
			hero.facing = 1
			hero.running = false
			hero.begin_attack()
			assert(hero.prop_attack and not hero.run_attack)
			assert(hero.attack_motion() == "stomp")
			assert(is_equal_approx(hero.attack_duration, hero.visual.duration("stomp")))
			hero.strike()
			assert(prop.dead, id + " breaks " + item_kind)
			hero.tick(hero.attack_duration + 0.01)
			for food in game.food:
				food.dead = true
		# Running retains the existing slide or regular attack selection.
		hero.prop_attack = false
		hero.run_attack = true
		assert(hero.attack_motion() != "stomp")
	print("STOMP PASSED: all characters, crates/barrels, dedicated sheets, running unchanged")
	game.queue_free()
	await process_frame
	quit()
