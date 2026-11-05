extends SceneTree

const Rules = preload("res://scripts/score_rules.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var rules = Rules.new()
	assert(rules.points(100, 0, 3, 1) == 100)
	assert(rules.points(100, 100, 3, 1) == 110)
	assert(rules.points(100, 0, 3, 1, true) == 200)
	assert(rules.multiplier(0, 3, 20) > rules.multiplier(0, 3, 10))
	assert(is_equal_approx(rules.multiplier(0, 3, 999), 3))
	assert(rules.multiplier(0, 1, 1) < rules.multiplier(0, 2, 1))
	rules.consume(false)
	rules.consume(true)
	assert(is_equal_approx(rules.multiplier(100, 2, 11, true), 1.1 * 0.85 * 1.5 * 2 * 1.25 * 1.25))
	assert(rules.points(193, 100, 2, 11, true) % 10 == 0)
	rules.tick(9)
	assert(rules.sushi_time > 0 and rules.beer_time > 0)
	rules.consume(false)
	assert(rules.sushi_time == 10 and rules.beer_time == 1)
	rules.tick(1)
	assert(rules.beer_time == 0 and rules.sushi_time == 9)
	rules.reset()
	assert(rules.sushi_time == 0 and rules.beer_time == 0)
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.new_run()
	await process_frame
	var enemy = game.enemies[0]
	game.charge = 0
	enemy.hp = 1000
	enemy.invincible = 0
	enemy.hurt(10, 1)
	assert(game.score == 100 and game.combo_hits == 1)
	enemy.invincible = 0
	enemy.launch_away(10, 1, false, game.player, true)
	assert(game.score == 310, "ultimate doubles hit score and stacks with combo")
	enemy.thrown_time = 0
	enemy.hit_lock = 0
	enemy.is_boss = true
	enemy.lock_on_hit()
	assert(enemy.hit_lock == 0, "boss receives no extended combo lock")
	enemy.is_boss = false
	enemy.lock_on_hit()
	assert(enemy.hit_lock > 0, "ordinary enemies retain combo lock")
	game.player.invincible = 0
	game.player.hurt(1, 1)
	assert(game.combo_hits == 0 and not game.score_rules.level_unhurt)
	game.score = Rules.MAX_SCORE - 10
	game.award_score(9999)
	assert(game.score == Rules.MAX_SCORE, "score fits the ranking limit")
	game.score_rules.consume(true)
	game.new_run()
	assert(game.score == 0 and game.score_rules.beer_time == 0)
	print("SCORE SYSTEM PASSED: stacking, expiry, lives, ultimate, boss lock, resets and ranking limits")
	game.queue_free()
	await process_frame
	quit()
