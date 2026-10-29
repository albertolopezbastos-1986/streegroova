extends Node2D

const ArcadeUI = preload("res://scripts/arcade_ui.gd")

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

func setup(owner_game: Node2D, type: int, at: Vector2) -> void:
	game = owner_game
	kind = type
	position = at
	if kind >= 0:
		max_hp = [65.0, 42.0, 130.0][kind]
		hp = max_hp
		ai_wait = randf_range(0.2, 0.8)
	queue_redraw()

func tick(dt: float) -> void:
	anim += dt
	cooldown = maxf(0, cooldown - dt)
	stun = maxf(0, stun - dt)
	invincible = maxf(0, invincible - dt)
	combo_window = maxf(0, combo_window - dt)
	ultimate_pose = maxf(0, ultimate_pose - dt)
	if dead:
		death_time += dt
		queue_redraw()
		return
	if height > 0 or jump_speed > 0:
		height += jump_speed * dt
		jump_speed -= 950 * dt
		if height <= 0:
			height = 0
			jump_speed = 0
			air_attack = false
			game.dust(position)
	if attack_time > 0:
		attack_time = maxf(0, attack_time - dt)
		if attack_time < attack_duration * 0.72 and attack_time > attack_duration * 0.2:
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
	position.y = clampf(position.y, 332, 465)
	position.x = clampf(position.x, game.left_bound, game.right_bound)
	z_index = int(position.y)
	queue_redraw()

func player_control(dt: float) -> void:
	var direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	if height == 0:
		velocity = direction * 170
		if direction.x != 0:
			facing = signf(direction.x)
	# Horizontal momentum is conserved in the air: neutral and forward jumps differ.
	if attack_time <= 0 or height > 0:
		position += velocity * dt
	moving = direction.length() > 0.1 and height == 0 and attack_time <= 0
	if Input.is_action_just_pressed("jump") and height == 0 and attack_time <= 0:
		jump_speed = 420
		height = 1
		game.sound("jump")
	if Input.is_action_just_pressed("attack") and cooldown <= 0:
		begin_attack()
	if Input.is_action_just_pressed("ultimate"):
		game.use_ultimate()

func enemy_control(dt: float) -> void:
	var target = game.player
	if target.dead:
		return
	var delta: Vector2 = target.position - position
	facing = 1 if delta.x >= 0 else -1
	moving = false
	if windup > 0:
		windup -= dt
		if windup <= 0:
			begin_attack()
		return
	if attack_time > 0:
		return
	ai_wait -= dt
	var range_x: float = 65 if kind == 2 else 50
	if absf(delta.x) < range_x and absf(delta.y) < 22:
		if cooldown <= 0 and ai_wait <= 0:
			windup = 0.55 if kind == 2 else 0.3
			ai_wait = randf_range(0.35, 0.85)
	else:
		var desired := Vector2(target.position.x - facing * (range_x - 9), target.position.y)
		# A little separation prevents the entire wave stacking on one pixel.
		var steer: Vector2 = (desired - position).normalized()
		for other in game.enemies:
			if other != self and not other.dead:
				var away: Vector2 = position - other.position
				if away.length() < 34 and away.length() > 0.1:
					steer += away.normalized() * 0.8
		var speed: float = [79.0, 125.0, 53.0][kind]
		position += steer.limit_length() * speed * dt
		moving = true

func begin_attack() -> void:
	air_attack = height > 0
	combo = (combo + 1) % 3 if combo_window > 0 else 0
	combo_window = 0.7
	attack_duration = 0.34 if kind != 2 else 0.58
	if air_attack:
		attack_duration = 0.5
	attack_time = attack_duration
	cooldown = attack_duration + (0.55 if kind >= 0 else 0.015)
	hits.clear()
	game.sound("swing")

func strike() -> void:
	var targets: Array = game.enemies if kind == -1 else [game.player]
	for target in targets:
		if target.dead or target in hits:
			continue
		var delta: Vector2 = target.position - position
		var reach := 89.0 if air_attack or combo == 2 else 70.0
		if kind == 2:
			reach = 80
		if delta.x * facing > -12 and delta.x * facing < reach and absf(delta.y) < 28:
			if kind >= 0 and target.height > 40:
				continue
			if kind == -1 and height > 112:
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
	stun = 0.32 if heavy else 0.2
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
		if kind != -1:
			game.score += [250, 350, 600][kind]

func limb(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(a, b, Color("111526"), width + 4)
	draw_line(a, b, color, width)

func _draw() -> void:
	if dead and death_time > 0.9:
		return
	if invincible > 0 and int(anim * 22) % 2 == 0:
		return
	draw_set_transform(Vector2.ZERO)
	draw_ellipse_shadow()
	var bulk := 1.25 if kind == 2 else 1.0
	var origin := Vector2(0, -height)
	if dead:
		draw_set_transform(Vector2(0, -7), facing * 1.4, Vector2(facing, 0.65))
	else:
		draw_set_transform(origin, 0, Vector2(facing * bulk, bulk))
	var skin := Color("eeb78b") if kind == -1 else Color("bb8374")
	var shirt := Color("35d5cf")
	var pants := Color("263f6c")
	if kind == 0:
		shirt = Color("e26887")
		pants = Color("452e53")
	elif kind == 1:
		shirt = Color("e9bc4b")
		pants = Color("333152")
	elif kind == 2:
		shirt = Color("9a83d5")
		pants = Color("2c263e")
	if stun > 0:
		shirt = Color("fff4d4")
	var stride := sin(anim * 14) * 10 if moving else sin(anim * 3) * 1.5
	var attacking := attack_time > 0
	var leg_left := Vector2(-9 - stride, -4)
	var leg_right := Vector2(10 + stride, -4)
	if height > 0:
		leg_left = Vector2(-15, -15)
		leg_right = Vector2(16, -22)
	if air_attack and attacking:
		leg_right = Vector2(52, -37)
	elif attacking and combo == 2:
		leg_right = Vector2(46, -30)
	limb(Vector2(-7, -32), leg_left, pants, 12)
	limb(Vector2(7, -32), leg_right, pants.lightened(0.12), 12)
	draw_rect(Rect2(leg_left + Vector2(-8, -3), Vector2(20, 7)), Color("101929"))
	draw_rect(Rect2(leg_right + Vector2(-7, -3), Vector2(21, 7)), Color("101929"))
	draw_style_box(body_style(shirt), Rect2(-17, -66, 34, 36))
	draw_rect(Rect2(-17, -36, 34, 5), Color("e6c17c"))
	draw_rect(Rect2(-3, -36, 7, 5), Color("fff0ad"))
	var fist := Vector2(22, -48 + stride * 0.3)
	if attacking and not air_attack:
		fist = Vector2(52, -55 if combo == 1 else -48)
	if ultimate_pose > 0:
		fist = Vector2(5, -99)
	limb(Vector2(-12, -60), Vector2(-22, -39 - stride * 0.4), shirt.darkened(0.2), 10)
	limb(Vector2(12, -60), fist, skin, 10)
	draw_circle(fist, 7, Color("f2f3de") if kind == -1 else shirt.lightened(0.25))
	draw_rect(Rect2(-11, -87, 24, 24), skin)
	draw_rect(Rect2(-13, -91, 27, 10), Color("202033"))
	draw_rect(Rect2(-13, -85, 8, 13), Color("202033"))
	draw_rect(Rect2(8, -80, 4, 4), Color("151526"))
	if kind == -1:
		draw_rect(Rect2(-14, -84, 29, 4), Color("f26788"))
		draw_line(Vector2(-12, -82), Vector2(-29 - sin(anim * 10) * 5, -74), Color("f26788"), 4)
	elif kind == 1:
		draw_rect(Rect2(-7, -98, 17, 12), Color("e9bc4b"))
	elif kind == 2:
		draw_rect(Rect2(-12, -70, 25, 8), Color("312139"))
	if attacking:
		var end := Vector2(55, -37 if air_attack else -52)
		draw_arc(end - Vector2(12, 0), 24, -1.3, 1.2, 10, Color(1, 0.9, 0.6, 0.8), 3)
	if windup > 0:
		draw_string(ArcadeUI.FONT, Vector2(-4, -111), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffbf69"))
	draw_set_transform(Vector2.ZERO)
	if kind >= 0 and hp < max_hp and not dead:
		draw_rect(Rect2(-22, -112 * bulk, 44, 4), Color("211d34"))
		draw_rect(Rect2(-22, -112 * bulk, 44 * hp / max_hp, 4), shirt)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.27))
	draw_circle(Vector2.ZERO, 22 if kind != 2 else 29, Color(0.015, 0.02, 0.06, 0.55))
	draw_set_transform(Vector2.ZERO)

func body_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("14182b")
	style.set_border_width_all(2)
	return style
