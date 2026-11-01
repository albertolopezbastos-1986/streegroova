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
	game.debug_spawn_enemy(0)
	var hero = game.player
	var enemy = game.enemies[0]
	for combo_index in range(3):
		for direction in [1.0, -1.0]:
			for outside in [false, true]:
				hero.attack_time = 0
				hero.cooldown = 0
				hero.combo = combo_index - 1
				hero.combo_window = 1
				hero.position = Vector2(350, 390)
				hero.facing = direction
				var reach := 178.0 if combo_index == 2 else 140.0
				enemy.position = hero.position + Vector2(direction * (reach + (1 if outside else -1)), 0)
				enemy.hp = 1000
				enemy.invincible = 0
				hero.begin_attack()
				var data: Dictionary = hero.visual.definition(hero.attack_motion())
				var contact_index: int = data["frame_indices"].find(int(data["active_hit_frames"][0]))
				assert(contact_index >= 0)
				hero.attack_time = hero.attack_duration * (1.0 - (contact_index + 0.1) / data["frame_indices"].size())
				assert(hero.attack_is_active())
				hero.strike()
				hero.strike()
				assert(enemy.hp == (1000 if outside else (971 if combo_index == 2 else 981)), "Cami hit %d direction %s outside %s obeys doubled reach and hits once" % [combo_index + 1, direction, outside])
	print("CAMI REACH PASSED: all three hits, both facings, inside/outside doubled reach, single damage")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
