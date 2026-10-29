extends Node2D

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const CharacterVisual = preload("res://scripts/character_visual.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const ENEMY_PALETTE = preload("res://assets/characters/enemy_palette.gdshader")
const ENEMY_COLORS = [Color("d45c79"), Color("d6aa51"), Color("9980d2")]

var game: Node2D
var kind := -1
var hp := 100.0
var max_hp := 100.0
var facing := 1.0
var velocity := Vector2.ZERO
var height := 0.0
var jump_speed := 0.0
var attack_time := 0.0
var attack_duration := 0.3
var cooldown := 0.0
var stun := 0.0
var invincible := 0.0
var dead := false
var death_time := 0.0
var anim := 0.0
var moving := false
var combo := 0
var combo_window := 0.0
var hits: Array = []
var ai_wait := 0.0
var windup := 0.0
var ultimate_pose := 0.0
var air_attack := false
var visual: Node2D
var hurt_duration := 0.0
var jump_elapsed := 0.0
var attack_buffer := 0.0
var jump_duration := 840.0 / 950.0
var ai_jump_cooldown := 2.0

func setup(owner_game: Node2D, type: int, at: Vector2, character_pack: Dictionary = {}) -> void:
	game = owner_game
	kind = type
	position = at
	visual = CharacterVisual.new()
	visual.configure(character_pack if not character_pack.is_empty() else Catalog.character("beto"))
	add_child(visual)
	if kind >= 0:
		facing = 1 if game.player.position.x >= position.x else -1
		max_hp = [65.0, 42.0, 130.0][kind]
		hp = max_hp
		ai_wait = randf_range(0.2, 0.8)
		ai_jump_cooldown = randf_range(1.0, 2.2)
		var palette := ShaderMaterial.new()
		palette.shader = ENEMY_PALETTE
		palette.set_shader_parameter("outfit_color", ENEMY_COLORS[kind])
		visual.material = palette
		visual.scale = Vector2.ONE * [1.0, 0.97, 1.06][kind]
	update_visual(0)
	queue_redraw()

func tick(dt: float) -> void:
	anim += dt
	cooldown = maxf(0, cooldown - dt)
	stun = maxf(0, stun - dt)
	invincible = maxf(0, invincible - dt)
	combo_window = maxf(0, combo_window - dt)
	ultimate_pose = maxf(0, ultimate_pose - dt)
	attack_buffer = maxf(0, attack_buffer - dt)
	ai_jump_cooldown = maxf(0, ai_jump_cooldown - dt)
	if dead:
		death_time += dt
		jump_speed = minf(0, jump_speed) - 950 * dt
		height = maxf(0, height + jump_speed * dt)
		position.x = clampf(position.x + velocity.x * dt, game.left_bound, game.right_bound)
		velocity = velocity.move_toward(Vector2.ZERO, dt * 650)
		update_visual(dt)
		queue_redraw()
		return
	if height > 0 or jump_speed > 0:
		jump_elapsed += dt
		height += jump_speed * dt
		jump_speed -= 950 * dt
		if height <= 0:
			height = 0
			jump_speed = 0
			if air_attack:
				attack_time = 0
			air_attack = false
			game.dust(position)
	if attack_time > 0:
		attack_time = maxf(0, attack_time - dt)
		if attack_is_active():
			strike()
	if stun > 0:
		position += velocity * dt
		velocity = velocity.move_toward(Vector2.ZERO, dt * 650)
		moving = false
	elif ultimate_pose <= 0:
		if kind == -1:
			player_control(dt)
		else:
			enemy_control(dt)
	position.y = clampf(position.y, game.WALK_MIN_Y, game.WALK_MAX_Y)
	position.x = clampf(position.x, game.left_bound, game.right_bound)
	z_index = int(position.y)
	update_visual(dt)
	queue_redraw()

func player_control(dt: float) -> void:
	var direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	if height == 0:
		velocity = Vector2(direction.x * 170, direction.y * game.DEPTH_SPEED)
		if direction.x != 0 and attack_time <= 0:
			facing = signf(direction.x)
	# Horizontal momentum is conserved in the air: neutral and forward jumps differ.
	if attack_time <= 0 or height > 0:
		position += velocity * dt
	moving = direction.length() > 0.1 and height == 0 and attack_time <= 0
	if Input.is_action_just_pressed("jump") and height == 0 and attack_time <= 0:
		takeoff(velocity)
	if Input.is_action_just_pressed("attack"):
		attack_buffer = 0.18
	if attack_buffer > 0 and cooldown <= 0:
		attack_buffer = 0
		begin_attack()
	if Input.is_action_just_pressed("ultimate"):
		game.use_ultimate()

func takeoff(momentum: Vector2, impulse := 420.0) -> bool:
	if dead or stun > 0 or height > 0 or attack_time > 0:
		return false
	jump_speed = impulse
	jump_duration = impulse * 2.0 / 950.0
	height = 1
	jump_elapsed = 0
	velocity = momentum
	moving = false
	game.sound("jump")
	update_visual(0)
	return true

func can_use_ultimate() -> bool:
	return kind == -1 and not dead

func enemy_control(dt: float) -> void:
	var target = game.player
	ai_wait = maxf(0, ai_wait - dt)
	moving = false
	if target.dead:
		return
	var delta: Vector2 = target.position - position
	if height > 0:
		position += velocity * dt
		if not air_attack and jump_elapsed > 0.12 and cooldown <= 0 and absf(delta.x) < 105 and absf(delta.y) < game.MELEE_DEPTH:
			begin_attack()
		return
	if windup > 0:
		windup -= dt
		if windup <= 0:
			begin_attack()
		return
	if attack_time > 0:
		return
	facing = 1 if delta.x >= 0 else -1
	var speed: float = [79.0, 125.0, 53.0][kind]
	var in_lane: bool = absf(delta.y) < game.MELEE_DEPTH
	if ai_jump_cooldown <= 0 and cooldown <= 0 and ai_wait <= 0 and in_lane:
		var chase_jump := absf(delta.x) >= 85 and absf(delta.x) <= 175
		var dodge_jump: bool = target.attack_time > 0 and absf(delta.x) < 75
		if chase_jump or dodge_jump:
			var momentum := Vector2(facing * speed * 1.25, clampf(delta.y * 2, -16, 16)) if chase_jump else Vector2.ZERO
			takeoff(momentum, [250.0, 260.0, 240.0][kind])
			ai_jump_cooldown = [3.8, 2.8, 5.0][kind]
			return
	var range_x: float = 65 if kind == 2 else 50
	if absf(delta.x) < range_x and in_lane:
		if cooldown <= 0 and ai_wait <= 0:
			windup = 0.5 if kind == 2 else 0.3
			if combo_window > 0 and combo < 2:
				windup *= 0.6
	else:
		var desired := Vector2(target.position.x - facing * (range_x - 9), target.position.y)
		var steer: Vector2 = (desired - position).normalized()
		for other in game.enemies:
			if other != self and not other.dead:
				var away: Vector2 = position - other.position
				if away.length() < 26 and away.length() > 0.1:
					steer += away.normalized() * 0.55
		position += steer.limit_length() * Vector2(speed, minf(speed, game.DEPTH_SPEED)) * dt
		moving = true

func begin_attack() -> void:
	air_attack = height > 0
	combo = (combo + 1) % 3 if combo_window > 0 else 0
	attack_duration = visual.duration(attack_motion())
	if kind >= 0:
		attack_duration *= [1.0, 0.9, 1.22][kind]
	combo_window = attack_duration + (1.1 if kind >= 0 else 0.45)
	attack_time = attack_duration
	cooldown = attack_duration + (0.12 if kind >= 0 else 0.015)
	if kind >= 0:
		ai_wait = 0.12 if combo < 2 else 0.8
	hits.clear()
	game.sound("swing")
	update_visual(0)

func attack_motion() -> String:
	return "jump_attack" if air_attack else "attack_%02d" % (combo + 1)

func attack_is_active() -> bool:
	if attack_time <= 0:
		return false
	var name := attack_motion()
	var frame: int = visual.frame_at(name, 1.0 - attack_time / attack_duration)
	for active_frame in visual.definition(name)["active_hit_frames"]:
		# JSON numbers are floats; Array.has would compare their Variant types.
		if frame == int(active_frame):
			return true
	return false

func update_visual(dt: float) -> void:
	if not is_instance_valid(visual):
		return
	var motion := "idle"
	var progress := -1.0
	if dead:
		motion = "death"
		progress = death_time / visual.duration("death")
	elif ultimate_pose > 0 and can_use_ultimate():
		motion = "ultimate"
		progress = (1.6 - game.ult_time) / 1.6
	elif stun > 0:
		motion = "hurt"
		progress = 1.0 - stun / maxf(hurt_duration, 0.01)
	elif attack_time > 0:
		motion = attack_motion()
		progress = 1.0 - attack_time / attack_duration
	elif height > 0:
		motion = "jump"
		progress = jump_elapsed / jump_duration
	elif moving:
		motion = "walk"
	visual.position = Vector2(0, -roundf(height))
	visual.modulate.a = 0.4 if invincible > 0 and stun <= 0 and ultimate_pose <= 0 and not dead and int(anim * 16) % 2 == 0 else 1.0
	visual.visible = kind == -1 or not dead or death_time < 1.65
	if dead and kind >= 0:
		visual.modulate.a = clampf((1.65 - death_time) / 0.35, 0, 1)
	visual.update_pose(motion, dt, facing, progress)

func strike() -> void:
	var targets: Array = game.enemies if kind == -1 else [game.player]
	for target in targets:
		if target.dead or target in hits:
			continue
		var delta: Vector2 = target.position - position
		var reach := 89.0 if air_attack or combo == 2 else 70.0
		if kind == 2:
			reach = 80
		if delta.x * facing > -12 and delta.x * facing < reach and absf(delta.y) < game.MELEE_DEPTH:
			var height_difference: float = absf(height - target.height)
			if height_difference > (112.0 if air_attack else 40.0):
				continue
			hits.append(target)
			var damage := 16.0
			if kind == -1:
				damage = 29 if combo == 2 or air_attack else 19
			elif kind == 1:
				damage = 10
			elif kind == 2:
				damage = 26
			target.hurt(damage, facing, combo == 2 or air_attack or kind == 2)

func hurt(damage: float, direction: float, heavy := false) -> void:
	if dead or invincible > 0:
		return
	hp = maxf(0, hp - damage)
	stun = (0.44 if heavy else 0.36) if kind == -1 else (0.38 if heavy else 0.25)
	hurt_duration = stun
	attack_buffer = 0
	velocity = Vector2(direction * (230 if heavy else 115), 0)
	attack_time = 0
	windup = 0
	invincible = 0.65 if kind == -1 else 0.13
	game.charge = minf(100, game.charge + (damage * 0.65 if kind == -1 else damage * 0.30))
	game.impact(position - Vector2(0, 45 + height), direction, heavy)
	game.sound("hit")
	if kind == -1:
		game.combo_hits = 0
	else:
		game.score += int(damage * 10)
		game.combo_hits += 1
		game.combo_timer = 2.0
	if hp <= 0:
		dead = true
		death_time = 0
		if kind != -1:
			game.score += [250, 350, 600][kind]
	update_visual(0)

func _draw() -> void:
	if dead and kind >= 0 and death_time >= 1.65:
		return
	draw_ellipse_shadow()
	if kind < 0:
		return
	var color: Color = ENEMY_COLORS[kind]
	# Colored pixel marker identifies clones without changing the player's art.
	draw_rect(Rect2(-13, 1, 26, 2), Color(color, 0.7))
	if not is_instance_valid(visual) or dead:
		return
	var data: Dictionary = visual.character_data
	var head := float(data["pivot_pixels"][1]) * float(data["scale"]) * visual.scale.y
	if hp < max_hp:
		draw_rect(Rect2(-20, -head - height - 5, 40, 4), Color("171b2b"))
		draw_rect(Rect2(-19, -head - height - 4, 38 * hp / max_hp, 2), color)
	if windup > 0:
		draw_string(ArcadeUI.FONT, Vector2(-4, -head * 0.65), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffdb8b"))

func draw_ellipse_shadow() -> void:
	var shade := Color(0.015, 0.02, 0.06, 0.5)
	draw_rect(Rect2(-15, -3, 30, 6), shade)
	draw_rect(Rect2(-20, -1, 40, 3), shade)
