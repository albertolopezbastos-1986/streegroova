extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for id in ["beto", "cami", "alito", "dami", "malu", "meli", "pato", "vampi"]:
		for enabled in [true, false]:
			game.active_character_id = id
			game.enable_hitstop = enabled
			game.new_run(true)
			var hero = game.player
			var target = game.enemies[0]
			for other in game.enemies:
				other.position = Vector2(800, 440)
			hero.position = Vector2(350, 390)
			hero.facing = 1
			target.position = hero.position + Vector2(50, 0)
			target.hp = 1000
			target.invincible = 0
			hero.combo = hero.player_combo().size() - 2
			hero.combo_window = 1
			hero.combo_connected = true
			hero.begin_attack()
			var data: Dictionary = hero.visual.definition(hero.attack_motion())
			var contact := int(data["active_hit_frames"][0])
			var index: int = data["frame_indices"].find(contact)
			hero.attack_time = hero.attack_duration * (1.0 - (index + 0.1) / data["frame_indices"].size())
			hero.strike()
			assert(target.hp < 1000)
			if not enabled:
				assert(hero.hitstop_remaining == 0 and target.hitstop_remaining == 0)
				continue
			assert(is_equal_approx(hero.hitstop_remaining, 10.0 / 60.0))
			assert(hero.visual.source_frame == contact)
			var attack_time: float = hero.attack_time
			var cooldown: float = hero.cooldown
			var stun: float = target.stun
			var frame: int = target.visual.source_frame
			var at: Vector2 = target.position
			var victim_sprite: Vector2 = target.visual.position
			var attacker_sprite: Vector2 = hero.visual.position
			var victim_hp: float = target.hp
			for step in range(10):
				hero.tick(1.0 / 60.0)
				target.tick(1.0 / 60.0)
				assert(hero.attack_time == attack_time and hero.cooldown == cooldown)
				assert(target.stun == stun and target.position == at and target.hp == victim_hp)
				assert(target.visual.source_frame == frame)
				assert(hero.visual.position == attacker_sprite)
				if step < 9:
					assert(target.visual.position != victim_sprite)
			assert(hero.hitstop_remaining == 0 and target.hitstop_remaining == 0)
			assert(target.visual.position == victim_sprite)
			hero.tick(1.0 / 60.0)
			target.tick(1.0 / 60.0)
			assert(hero.attack_time < attack_time and target.stun < stun)
	# Intermediate combo hits stay fluid; special attacks retain the pause.
	for attack in ["combo_0", "combo_1", "combo_2", "combo_3", "runslide", "jump", "weapon"]:
		game.active_character_id = "beto"
		game.enable_hitstop = true
		game.new_run(true)
		var hero = game.player
		var target = game.enemies[0]
		for other in game.enemies:
			other.position = Vector2(800, 440)
		hero.position = Vector2(350, 390)
		hero.facing = 1
		target.position = hero.position + Vector2(50, 0)
		target.hp = 1000
		target.invincible = 0
		hero.begin_attack()
		if attack.begins_with("combo_"):
			hero.combo = int(attack.get_slice("_", 1))
		elif attack == "runslide":
			hero.run_attack = true
		elif attack == "jump":
			hero.air_attack = true
		elif attack == "weapon":
			hero.weapon = "pipe"
			hero.weapon_attack = true
		hero.strike()
		assert(target.hp < 1000)
		var should_pause: bool = attack not in ["combo_0", "combo_1", "combo_2"]
		assert((hero.hitstop_remaining > 0) == should_pause, attack)
		assert((target.hitstop_remaining > 0) == should_pause, attack)
	print("PLAYER HITSTOP PASSED: ten frames, frozen timers/poses, victim shake, resume, toggle, all eight characters")
	game.queue_free()
	await process_frame
	quit()
