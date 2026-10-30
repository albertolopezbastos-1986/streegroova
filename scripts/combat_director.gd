extends RefCounted

# One committed attacker, plus a short, infrequent opening for a second one.
# Reservations include anticipation, jumping and recovery, not only hit frames.
var game: Node2D
var turns: Dictionary = {}
var sides: Dictionary = {}
var rested_until: Dictionary = {}
var clock := 0.0
var next_turn := 0.6
var next_assist := 7.0
var next_start := 0.0
var last_attacker: Node2D

func _init(owner_game: Node2D) -> void:
	game = owner_game
	next_assist = randf_range(6.0, 9.0)

func allowed(enemy: Node2D) -> bool:
	return turns.has(enemy)

func reset() -> void:
	for enemy in turns:
		if is_instance_valid(enemy):
			enemy.windup = 0
	turns.clear()
	sides.clear()
	rested_until.clear()
	next_turn = clock + 0.65
	next_assist = clock + randf_range(6.0, 9.0)
	last_attacker = null

func side_for(enemy: Node2D) -> float:
	return float(sides.get(enemy, 1.0))

func destination(enemy: Node2D) -> Vector2:
	var side := side_for(enemy)
	var rank := 0
	for other in game.enemies:
		if other == enemy:
			break
		if not other.dead and side_for(other) == side and not allowed(other):
			rank += 1
	var distance := (53.0 if enemy.kind == 2 else 41.0) if allowed(enemy) else 94.0 + rank * 34.0
	var goal: Vector2 = game.player.position + Vector2(side * distance, 0)
	goal.x = clampf(goal.x, game.left_bound + 12, game.right_bound - 12)
	if not allowed(enemy):
		goal.y = clampf(game.player.position.y + (12.0 if rank % 2 == 0 else -12.0), game.WALK_MIN_Y, game.WALK_MAX_Y)
	# Cross behind the player along the opposite depth lane before closing in.
	var dx: float = enemy.position.x - game.player.position.x
	if dx * side < -18:
		var bypass: float = game.WALK_MIN_Y if game.player.position.y >= game.START_Y else game.WALK_MAX_Y
		if absf(enemy.position.y - bypass) > 2:
			return Vector2(enemy.position.x, bypass)
		goal.y = bypass
	return goal

func update(dt: float) -> void:
	clock += dt
	for enemy in sides.keys():
		if not is_instance_valid(enemy) or enemy.dead or enemy not in game.enemies:
			sides.erase(enemy)
			rested_until.erase(enemy)
	var counts := [0, 0]
	for enemy in game.enemies:
		if enemy.dead:
			continue
		if not sides.has(enemy):
			var preferred := 0 if enemy.position.x < game.player.position.x else 1
			var index := preferred if counts[preferred] <= counts[1 - preferred] else 1 - preferred
			sides[enemy] = -1.0 if index == 0 else 1.0
		var side := side_for(enemy)
		# At an edge there is no space to flank on that side.
		if game.player.position.x - game.left_bound < 62:
			side = 1.0
		elif game.right_bound - game.player.position.x < 62:
			side = -1.0
		elif counts[0] == 0 and counts[1] >= 2:
			side = -1.0
		elif counts[1] == 0 and counts[0] >= 2:
			side = 1.0
		# Do not flip the committed attacker in the middle of a combo.
		if not allowed(enemy):
			sides[enemy] = side
		counts[0 if side_for(enemy) < 0 else 1] += 1
	for enemy in turns.keys():
		var invalid := not is_instance_valid(enemy)
		if not invalid:
			invalid = enemy.dead or enemy.stun > 0 or is_instance_valid(enemy.grabbed_by) or enemy.thrown_time > 0 or enemy.getup_time > 0 or game.player.dead
		var finished: bool = false
		if not invalid:
			finished = enemy.height == 0 and enemy.attack_time <= 0 and enemy.windup <= 0 and enemy.rush_windup <= 0 and not enemy.running and not enemy.grapple.active() and (clock >= float(turns[enemy]) or (enemy.combo == 2 and enemy.combo_window > 0))
		if invalid or finished:
			turns.erase(enemy)
			if is_instance_valid(enemy):
				enemy.windup = 0
				rested_until[enemy] = clock + randf_range(1.2, 2.0)
				last_attacker = enemy
			next_turn = maxf(next_turn, clock + randf_range(0.35, 0.65))
	if game.player.dead or game.player.stun > 0 or game.player.invincible > 0.7 or game.player.thrown_time > 0 or game.player.getup_time > 0 or is_instance_valid(game.player.grabbed_by):
		return
	if turns.is_empty() and clock >= next_turn:
		grant_turn()
	elif turns.size() == 1 and clock >= next_assist and clock >= next_start:
		var lead: Node2D = turns.keys()[0]
		if lead.attack_time > 0 or lead.windup > 0:
			if grant_turn():
				next_assist = clock + randf_range(6.0, 10.0)

func grant_turn() -> bool:
	var candidate: Node2D
	var best := INF
	for enemy in game.enemies:
		if enemy.dead or enemy.stun > 0 or allowed(enemy) or enemy.height > 0 or enemy.attack_time > 0 or is_instance_valid(enemy.grabbed_by) or enemy.thrown_time > 0 or enemy.getup_time > 0 or enemy.grapple.active():
			continue
		if clock < float(rested_until.get(enemy, 0.0)):
			continue
		var distance: float = enemy.position.distance_to(game.player.position)
		if distance > 200:
			continue
		var cost := distance + (95.0 if enemy == last_attacker else 0.0)
		if cost < best:
			best = cost
			candidate = enemy
	if candidate == null:
		return false
	turns[candidate] = clock + (3.5 if turns.is_empty() else 1.8)
	candidate.combo_window = 0
	candidate.ai_wait = maxf(candidate.ai_wait, 0.15)
	next_start = clock + 0.8
	return true
