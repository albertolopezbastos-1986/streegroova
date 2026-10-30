extends SceneTree

var checks := 0

func check(value: bool, description: String) -> void:
	if not value:
		push_error("FAIL: " + description)
		quit(1)
		assert(value, description)
	checks += 1
	print("PASS: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run(true)
	await process_frame
	var hero = game.player
	hero.position.x = 350
	Input.action_press("right")
	hero.tick(0.016)
	check(not hero.running and hero.velocity.x == 170, "single press walks")
	for i in range(30):
		hero.tick(0.016)
	check(not hero.running, "holding a single press never starts running")
	Input.action_release("right")
	hero.tick(0.016)
	Input.action_press("right")
	hero.tick(0.016)
	check(not hero.running, "late second tap still walks")
	Input.action_release("right")
	hero.tick(0.016)
	Input.action_press("right")
	hero.tick(0.016)
	check(hero.running and hero.velocity.x == 300 and hero.visual.motion == "walk", "double tap and hold runs using walking art")
	for i in range(8):
		hero.tick(0.016)
	check(hero.running, "second press sustains running")
	Input.action_release("right")
	hero.tick(0.016)
	check(not hero.running and hero.velocity.x == 0, "releasing stops the run")
	Input.action_press("left")
	hero.tick(0.016)
	check(not hero.running, "opposite direction does not count as double tap")
	Input.action_release("left")
	hero.tick(0.016)
	Input.action_press("left")
	hero.tick(0.016)
	check(hero.running and hero.velocity.x == -300 and hero.facing == -1, "double tap also runs left")
	game.debug_spawn_enemy(0)
	var enemy = game.enemies[0]
	enemy.position = hero.position + Vector2(-60, 0)
	enemy.hp = 1000
	enemy.invincible = 0
	hero.combo = 2
	hero.combo_window = 1
	Input.action_press("attack")
	hero.tick(0.016)
	Input.action_release("attack")
	await process_frame
	check(hero.run_attack and not hero.grapple.active(), "running attack takes priority over grabbing")
	check(hero.attack_motion() == "attack_01" and hero.combo == 0, "slide always uses first punch even after a combo")
	var start: float = hero.position.x
	var speed: float = absf(hero.velocity.x)
	# Opposite direction and jumping cannot steer or cancel an active slide.
	Input.action_release("left")
	Input.action_press("right")
	Input.action_press("jump")
	hero.tick(0.016)
	Input.action_release("jump")
	await process_frame
	check(hero.facing == -1 and hero.height == 0 and hero.position.x < start, "slide locks direction and stays grounded")
	check(absf(hero.velocity.x) < speed, "slide brakes progressively")
	for i in range(14):
		hero.tick(0.016)
	check(enemy.hp == 971, "slide hits each enemy once for heavy damage")
	Input.action_release("right")
	for i in range(15):
		hero.tick(0.016)
	check(hero.run_attack and absf(hero.velocity.x) > 100 and hero.visual.source_frame == 39, "slide keeps braking after punch animation ends")
	while hero.attack_time > 0:
		hero.tick(0.016)
	check(not hero.run_attack and hero.velocity == Vector2.ZERO, "slide ends at rest")
	check(start - hero.position.x > 130 and start - hero.position.x < 165, "slide travels over twice its previous distance")
	hero.cooldown = 0
	hero.begin_attack()
	check(hero.combo == 0 and not hero.run_attack, "normal combo restarts after slide")
	hero.attack_time = 0
	hero.cooldown = 0
	hero.reset_running()
	hero.update_running(1, 0.016)
	hero.update_running(0, 0.016)
	hero.update_running(1, 0.016)
	hero.takeoff(Vector2(300, 0))
	check(not hero.running and hero.velocity.x == 300, "running jump preserves momentum and clears run state")
	hero.height = 0
	hero.jump_speed = 0
	hero.update_running(0, 0.016)
	hero.update_running(1, 0.016)
	hero.update_running(0, 0.016)
	hero.update_running(1, 0.016)
	hero.begin_attack()
	hero.invincible = 0
	hero.hurt(5, 1)
	check(not hero.running and not hero.run_attack and hero.attack_time == 0, "taking damage interrupts run and slide")
	hero.stun = 0
	hero.running = true
	hero.begin_attack()
	game.charge = 100
	game.use_ultimate()
	check(not hero.run_attack and hero.velocity == Vector2.ZERO, "ultimate safely cancels the slide")
	print("ALL ", checks, " RUNNING CHECKS PASSED")
	game.queue_free()
	await process_frame
	quit()
