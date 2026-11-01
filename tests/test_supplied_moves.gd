extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run()
	await process_frame
	var hero = game.player
	var enemy = game.enemies[0]
	hero.invincible = 0
	hero.facing = 1
	enemy.position = hero.position + Vector2(20, 0)
	enemy.hp = 1000
	assert(hero.grapple.try_start())
	var grab = hero.grapple
	grab.state = "punch"
	grab.punch_count = 2
	grab.elapsed = 0
	grab.did_hit = false
	grab.select_punch_animation()
	assert(grab.punch_animation == "grab_punch_03")
	hero.update_visual(0)
	assert(hero.visual.motion == "grab_punch_03")
	for i in range(30):
		hero.tick(0.016)
	assert(enemy.hp == 981 and enemy.thrown_time > 0)
	assert(not grab.active() and enemy.grabbed_by == null)
	hero.height = 65
	game.charge = 100
	game.use_ultimate()
	assert(hero.visual.motion == "ultimate_air")
	assert(hero.visual.material == hero.ultimate_air_material)
	game.ult_time = 0
	hero.ultimate_pose = 0
	hero.height = 0
	hero.update_visual(0)
	assert(hero.visual.material == null)
	hero.victory_time = 5
	hero.update_visual(0)
	assert(hero.visual.motion == "victory" and hero.visual.source_frame == 8)
	assert(hero.visual.position.y == 0)
	hero.victory_time = 10
	hero.update_visual(0)
	assert(hero.visual.source_frame == 8)
	print("SUPPLIED MOVES PASSED: third grab punch hits once and launches, aerial gold material resets, victory holds final pose")
	game.queue_free()
	await process_frame
	quit()
