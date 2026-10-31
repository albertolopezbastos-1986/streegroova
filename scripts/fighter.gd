extends Node2D

const Grapple = preload("res://scripts/grapple.gd")
const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const CharacterVisual = preload("res://scripts/character_visual.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const ENEMY_PALETTE = preload("res://assets/characters/enemy_palette.gdshader")
const ENEMY_COLORS = [Color("d6aa51"), Color("d45c79"), Color("c94742")]
const ENEMY_SPEEDS = [79.0, 96.0, 53.0]
const ENEMY_JUMP_INTERVALS = [7.6, 5.6, 16.0]
const ENEMY_SLIDE_INTERVALS = [12.0, 9.0, 8.0]

const WALK_SPEED := 170.0
const RUN_SPEED := 300.0
const DOUBLE_TAP_TIME := 0.28
const SLIDE_SPEED := 360.0
const SLIDE_BRAKE := 450.0
const THROW_SPEED := 380.0
const THROW_GROUND_BRAKE := 800.0

var running := false
var run_attack := false
var prop_attack := false
var weapon := ""
var weapon_durability := 100
var weapon_attack := false
var throw_chord_latched := false
var ai_weapon_cooldown := randf_range(8, 16)
var ai_weapon_target: Node2D
var ai_weapon_seek_time := 0.0
var ai_weapon_throw_cooldown := randf_range(6, 12)
var ai_returning := false
var pickup_target: Node2D
var pickup_elapsed := 0.0
var pickup_applied := false
var slide_animation_duration := 0.0
var tap_time := 0.0
var tap_direction := 0.0
var previous_horizontal := 0.0

var game: Node2D
var kind := -1
var is_boss := false
var grapple: RefCounted
var grabbed_by: Node2D
var thrown_time := 0.0
var flight_can_hit := false
var flight_hits: Array = []
const FLIGHT_IMPACT_DAMAGE := 20.0
var getup_time := 0.0
var victory_time := -1.0
const GETUP_DURATION := 0.4
var ai_special_cooldown := 4.0
var ai_slide_cooldown := 8.0
var boss_dodge_time := 0.0
var boss_dodge_cooldown := 0.0
var rush_windup := 0.0
var rush_time := 0.0
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
var ultimate_airborne := false
var air_attack := false
var visual: Node2D
var hurt_duration := 0.0
var jump_elapsed := 0.0
var attack_buffer := 0.0
var jump_duration := 840.0 / 950.0
var ai_jump_cooldown := 2.0

func setup(owner_game: Node2D, type: int, at: Vector2, character_pack: Dictionary = {}) -> void:
	game = owner_game
	grapple = Grapple.new(self)
	kind = type
	position = at
	visual = CharacterVisual.new()
	visual.configure(character_pack if not character_pack.is_empty() else Catalog.character("beto"))
	add_child(visual)
	if kind >= 0:
		facing = 1 if game.player.position.x >= position.x else -1
		max_hp = [130.0, 84.0, 260.0][kind]
		hp = max_hp
		ai_wait = randf_range(0.2, 0.8)
		ai_jump_cooldown = ENEMY_JUMP_INTERVALS[kind] * randf_range(0.75, 1.2)
		ai_slide_cooldown = ENEMY_SLIDE_INTERVALS[kind] * randf_range(0.75, 1.2)
		var palette := ShaderMaterial.new()
		palette.shader = ENEMY_PALETTE
		palette.set_shader_parameter("outfit_color", ENEMY_COLORS[kind])
		visual.material = palette
		visual.scale = Vector2.ONE * [1.0, 0.94, 1.113][kind]
	update_visual(0)
	queue_redraw()

func make_boss() -> void:
	is_boss = true
	max_hp = 520.0
	hp = max_hp
	visual.scale = Vector2.ONE * 1.25
	visual.material.set_shader_parameter("outfit_color", Color("a347ce"))
	ai_wait = 0.08
	ai_special_cooldown = 1.0
	ai_slide_cooldown = 2.0
	ai_jump_cooldown = 2.5
	queue_redraw()

func tick(dt: float) -> void:
	anim += dt
	grapple.retry = maxf(0, grapple.retry - dt)
	cooldown = maxf(0, cooldown - dt)
	stun = maxf(0, stun - dt)
	invincible = maxf(0, invincible - dt)
	combo_window = maxf(0, combo_window - dt)
	ultimate_pose = maxf(0, ultimate_pose - dt)
	attack_buffer = maxf(0, attack_buffer - dt)
	ai_jump_cooldown = maxf(0, ai_jump_cooldown - dt)
	ai_special_cooldown = maxf(0, ai_special_cooldown - dt)
	ai_slide_cooldown = maxf(0, ai_slide_cooldown - dt)
	boss_dodge_cooldown = maxf(0, boss_dodge_cooldown - dt)
	ai_weapon_throw_cooldown = maxf(0, ai_weapon_throw_cooldown - dt)
	if is_instance_valid(grabbed_by) and not dead:
		if kind == -1:
			grabbed_by.grapple.try_escape(dt)
		update_visual(0)
		queue_redraw()
		return
	if grapple.active():
		grapple.tick(dt)
		update_visual(0)
		queue_redraw()
		return
	if is_instance_valid(pickup_target) and not dead and stun <= 0:
		tick_pickup(dt)
		return
	if dead:
		var from := position
		death_time += dt
		height = maxf(0, height + jump_speed * dt)
		jump_speed -= 950 * dt
		position.x = clampf(position.x + velocity.x * dt, movement_left_bound(), game.right_bound)
		if height == 0:
			velocity = velocity.move_toward(Vector2.ZERO, dt * (THROW_GROUND_BRAKE if thrown_time > 0 else 650.0))
		update_flight_impacts(from)
		if height == 0:
			flight_can_hit = false
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
	if thrown_time > 0:
		var from := position
		thrown_time = maxf(0, thrown_time - dt)
		position.x = clampf(position.x + velocity.x * dt, movement_left_bound(), game.right_bound)
		update_flight_impacts(from)
		if height == 0:
			flight_can_hit = false
			velocity = velocity.move_toward(Vector2.ZERO, dt * THROW_GROUND_BRAKE)
		if thrown_time == 0 and (height > 0 or not velocity.is_zero_approx()):
			thrown_time = dt
		stun = maxf(stun, thrown_time)
		if thrown_time == 0 and height == 0:
			getup_time = GETUP_DURATION
			velocity = Vector2.ZERO
			stun = 0
			invincible = maxf(invincible, GETUP_DURATION + 0.65) if kind == -1 else 0.0
		update_visual(dt)
		queue_redraw()
		return
	if getup_time > 0:
		getup_time = maxf(0, getup_time - dt)
		velocity = Vector2.ZERO
		moving = false
		update_visual(dt)
		queue_redraw()
		return
	if run_attack and attack_time > 0 and stun <= 0:
		position.x = clampf(position.x + velocity.x * dt, movement_left_bound(), game.right_bound)
		velocity.x = move_toward(velocity.x, 0, SLIDE_BRAKE * dt)
	if attack_time > 0:
		attack_time = maxf(0, attack_time - dt)
		if attack_is_active():
			strike()
	if run_attack and attack_time <= 0:
		run_attack = false
		combo_window = 0
		velocity = Vector2.ZERO
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
	position.x = clampf(position.x, movement_left_bound(), game.right_bound)
	z_index = int(position.y)
	update_visual(dt)
	queue_redraw()

func player_control(dt: float) -> void:
	var chord := Input.is_action_pressed("jump") and Input.is_action_pressed("attack")
	if not chord:
		throw_chord_latched = false
	var early_weapon_attack := weapon_attack and attack_time > 0 and attack_progress() < 0.2
	if chord and not throw_chord_latched and not weapon.is_empty() and (attack_time <= 0 or early_weapon_attack) and (cooldown <= 0 or early_weapon_attack) and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack")):
		throw_chord_latched = true
		throw_weapon()
		return
	var direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	if run_attack:
		if Input.is_action_just_pressed("ultimate"):
			game.use_ultimate()
		return
	update_running(direction.x, dt)
	if height == 0:
		velocity = Vector2(direction.x * (RUN_SPEED if running else WALK_SPEED), direction.y * game.DEPTH_SPEED)
		if direction.x != 0 and attack_time <= 0:
			facing = signf(direction.x)
	# Horizontal momentum is conserved in the air: neutral and forward jumps differ.
	if attack_time <= 0 or height > 0:
		position += velocity * dt
	moving = direction.length() > 0.1 and height == 0 and attack_time <= 0
	if moving and not running and grapple.try_start():
		return
	if Input.is_action_just_pressed("jump") and height == 0 and attack_time <= 0:
		takeoff(velocity)
	if Input.is_action_just_pressed("attack"):
		attack_buffer = 0.18
	if attack_buffer > 0 and cooldown <= 0:
		attack_buffer = 0
		begin_attack()
	if Input.is_action_just_pressed("ultimate"):
		game.use_ultimate()

func update_running(horizontal: float, dt: float) -> void:
	tap_time = maxf(0, tap_time - dt)
	var pressed := signf(horizontal) if absf(horizontal) > 0.35 else 0.0
	if height > 0 or attack_time > 0:
		running = false
		tap_time = 0
	elif pressed == 0:
		running = false
	elif pressed != previous_horizontal:
		running = pressed == tap_direction and tap_time > 0
		tap_direction = pressed
		tap_time = 0 if running else DOUBLE_TAP_TIME
	previous_horizontal = pressed

func reset_running() -> void:
	cancel_pickup()
	weapon_attack = false
	running = false
	run_attack = false
	prop_attack = false
	boss_dodge_time = 0
	tap_time = 0
	tap_direction = 0
	previous_horizontal = 0
	rush_windup = 0
	rush_time = 0

func takeoff(momentum: Vector2, impulse := 420.0) -> bool:
	if dead or stun > 0 or height > 0 or thrown_time > 0 or getup_time > 0 or attack_time > 0 or is_instance_valid(grabbed_by) or grapple.active():
		return false
	reset_running()
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
	return kind == -1 and not dead and thrown_time <= 0 and getup_time <= 0 and not is_instance_valid(grabbed_by)

func enemy_control(dt: float) -> void:
	ai_returning = false
	ai_weapon_cooldown = maxf(0, ai_weapon_cooldown - dt)
	if run_attack:
		return
	var target = game.player
	ai_wait = maxf(0, ai_wait - dt)
	moving = false
	if target.dead or target.thrown_time > 0 or target.getup_time > 0 or is_instance_valid(target.grabbed_by):
		reset_running()
		return
	var delta: Vector2 = target.position - position
	if position.x < game.camera_x + 24 and height == 0 and attack_time <= 0:
		reset_running()
		ai_returning = true
		moving = true
		facing = 1
		position.x = move_toward(position.x, game.camera_x + 48, RUN_SPEED * 1.2 * dt)
		position.y = move_toward(position.y, target.position.y, game.DEPTH_SPEED * dt)
		return
	if is_boss and boss_dodge_time > 0:
		boss_dodge_time = maxf(0, boss_dodge_time - dt)
		position += velocity * dt
		moving = true
		if boss_dodge_time == 0:
			velocity = Vector2.ZERO
		return
	var committed: bool = game.combat_director.allowed(self)
	var on_flank: bool = (position.x - target.position.x) * game.combat_director.side_for(self) > 18
	if (running or rush_windup > 0) and not committed:
		reset_running()
	if rush_windup > 0:
		rush_windup = maxf(0, rush_windup - dt)
		if rush_windup == 0:
			running = true
			rush_time = 0.9
		return
	if running:
		rush_time -= dt
		if rush_time <= 0 or absf(delta.y) >= game.MELEE_DEPTH:
			reset_running()
			ai_wait = 0.5
			return
		if absf(delta.x) <= 75:
			begin_attack()
			return
		position.x += facing * RUN_SPEED * dt
		moving = true
		return
	if height > 0:
		position += velocity * dt
		if committed and not air_attack and jump_elapsed > 0.12 and cooldown <= 0 and absf(delta.x) < 105 and absf(delta.y) < game.MELEE_DEPTH:
			begin_attack()
		return
	if windup > 0 and not committed:
		windup = 0
	if windup > 0:
		windup -= dt
		if windup <= 0:
			begin_attack()
		return
	if attack_time > 0:
		return
	if seek_weapon(dt):
		return
	if not weapon.is_empty() and committed and ai_weapon_throw_cooldown <= 0 and cooldown <= 0 and absf(delta.y) < game.MELEE_DEPTH and absf(delta.x) >= 100 and absf(delta.x) <= 260:
		ai_weapon_throw_cooldown = randf_range(6, 12)
		if randf() < 0.35:
			facing = signf(delta.x)
			throw_weapon()
			return
	facing = 1 if delta.x >= 0 else -1
	var speed: float = 105.0 if is_boss else ENEMY_SPEEDS[kind]
	var in_lane: bool = absf(delta.y) < game.MELEE_DEPTH
	if is_boss and boss_dodge_cooldown <= 0 and target.attack_time > 0 and target.height < 20 and absf(delta.x) < 85 and in_lane and delta.x * target.facing < 0:
		var away_y := -1.0 if position.y > (game.WALK_MIN_Y + game.WALK_MAX_Y) / 2 else 1.0
		velocity = Vector2(-signf(delta.x) * 45, away_y * 150)
		boss_dodge_time = 0.18
		boss_dodge_cooldown = 1.6
		position += velocity * dt
		moving = true
		ai_wait = 0
		return
	if committed and on_flank and cooldown <= 0 and ai_wait <= 0 and ai_special_cooldown <= 0 and in_lane and target.invincible <= 0:
		var prefer_jump := kind == 1 and ai_jump_cooldown <= 0 and absf(delta.x) <= 175
		if ai_slide_cooldown <= 0 and not prefer_jump and absf(delta.x) >= 100 and absf(delta.x) <= 220 and target.height == 0:
			rush_windup = 0.22 if is_boss else 0.4
			ai_slide_cooldown = 4.0 if is_boss else ENEMY_SLIDE_INTERVALS[kind]
			ai_special_cooldown = 2.2 if is_boss else 5.0
			velocity = Vector2.ZERO
			return
	if committed and on_flank and ai_jump_cooldown <= 0 and cooldown <= 0 and ai_wait <= 0 and in_lane:
		var chase_jump := absf(delta.x) >= 85 and absf(delta.x) <= 175
		var dodge_jump: bool = target.attack_time > 0 and absf(delta.x) < 75
		if chase_jump or dodge_jump:
			var momentum := Vector2(facing * speed * 1.25, clampf(delta.y * 2, -16, 16)) if chase_jump else Vector2.ZERO
			takeoff(momentum, [250.0, 260.0, 240.0][kind])
			ai_jump_cooldown = 4.5 if is_boss else ENEMY_JUMP_INTERVALS[kind]
			return
	var range_x: float = 90 if not weapon.is_empty() else (65 if kind == 2 or is_boss else 50)
	if committed and on_flank and absf(delta.x) < range_x and in_lane:
		if cooldown <= 0 and ai_wait <= 0:
			windup = 0.16 if is_boss else (0.5 if kind == 2 else 0.3)
			if combo_window > 0 and combo < 2:
				windup *= 0.6
	else:
		var desired: Vector2 = game.combat_director.destination(self)
		if position.distance_to(desired) < 1.0:
			return
		var steer: Vector2 = (desired - position).normalized()
		for other in game.enemies:
			if other != self and not other.dead:
				var away: Vector2 = position - other.position
				if absf(away.y) < 6 and away.length() < 26 and away.length() > 0.1:
					steer += away.normalized() * 0.55
		position += steer.limit_length() * Vector2(speed, minf(speed, game.DEPTH_SPEED)) * dt
		moving = true

func begin_attack() -> void:
	if dead or getup_time > 0 or is_instance_valid(grabbed_by) or grapple.active() or thrown_time > 0:
		return
	if is_instance_valid(pickup_target):
		return
	if kind == -1 and height == 0 and attack_time <= 0:
		var item = game.nearby_pickup(self)
		if item != null:
			begin_pickup(item)
			return
	run_attack = running and height == 0
	weapon_attack = false
	prop_attack = false
	if kind == -1 and height == 0 and not run_attack:
		for prop in game.props:
			var delta: Vector2 = prop.position - position
			if not prop.dead and delta.x * facing >= 0 and delta.x * facing < 89 and absf(delta.y) < game.MELEE_DEPTH:
				prop_attack = true
				break
	running = false
	tap_time = 0
	air_attack = height > 0
	weapon_attack = not weapon.is_empty() and not air_attack and not run_attack and not prop_attack
	combo = 0 if run_attack else ((combo + 1) % 3 if combo_window > 0 else 0)
	if run_attack:
		velocity = Vector2(facing * SLIDE_SPEED, 0)
		moving = false
		game.dust(position)
	attack_duration = visual.duration(attack_motion())
	if kind >= 0:
		attack_duration *= 0.8 if is_boss else [1.0, 0.9, 1.22][kind]
	if run_attack:
		slide_animation_duration = attack_duration
		attack_duration = maxf(attack_duration, SLIDE_SPEED / SLIDE_BRAKE + 0.08)
	combo_window = attack_duration + (1.1 if kind >= 0 else 0.45)
	attack_time = attack_duration
	cooldown = attack_duration + (0.04 if is_boss else (0.12 if kind >= 0 else 0.015))
	if kind >= 0:
		ai_wait = (0.04 if combo < 2 else 0.18) if is_boss else (0.12 if combo < 2 else 0.8)
	hits.clear()
	game.sound("swing")
	update_visual(0)

func attack_motion() -> String:
	if (run_attack or prop_attack) and visual.sheets.has("runslide"):
		return "runslide"
	if weapon_attack:
		return "punch_weapon"
	return "jump_attack" if air_attack else "attack_%02d" % (combo + 1)

func begin_pickup(item: Node2D) -> void:
	reset_running()
	pickup_target = item
	pickup_elapsed = 0
	pickup_applied = false
	velocity = Vector2.ZERO
	moving = false
	attack_buffer = 0
	update_visual(0)

func cancel_pickup() -> void:
	pickup_target = null
	pickup_elapsed = 0
	pickup_applied = false

func tick_pickup(dt: float) -> void:
	pickup_elapsed += dt
	var duration: float = visual.duration("pickup")
	if not pickup_applied:
		if pickup_target.dead or position.distance_to(pickup_target.position) > 38:
			cancel_pickup()
			return
		var collect_progress: float = visual.definition("pickup").get("collect_progress", 0.55)
		if pickup_elapsed >= duration * collect_progress:
			if pickup_target.weapon.is_empty():
				hp = minf(max_hp, hp + max_hp * (0.5 if pickup_target.beer else 0.75))
			else:
				weapon = pickup_target.weapon
				weapon_durability = pickup_target.weapon_durability
			pickup_target.dead = true
			pickup_target.hide()
			pickup_applied = true
			game.sound("power")
	update_visual(0)
	if pickup_elapsed >= duration:
		cancel_pickup()
		cooldown = 0.08
		update_visual(0)

func attack_progress() -> float:
	# Keep contact timing while the slide continues through recovery.
	var duration := slide_animation_duration if run_attack else attack_duration
	return clampf((attack_duration - attack_time) / duration, 0, 1)

func attack_is_active() -> bool:
	if weapon_attack and weapon.is_empty():
		return false
	if attack_time <= 0:
		return false
	var name := attack_motion()
	var frame: int = visual.frame_at(name, attack_progress())
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
	elif is_instance_valid(pickup_target):
		motion = "pickup"
		progress = pickup_elapsed / visual.duration("pickup")
	elif victory_time >= 0:
		motion = "victory" if visual.sheets.has("victory") else "jump"
		progress = fposmod(victory_time, visual.duration(motion)) / visual.duration(motion)
	elif is_instance_valid(grabbed_by):
		motion = "hurt"
		progress = -1
	elif thrown_time > 0:
		motion = "death"
		progress = clampf((1.1 - thrown_time) / 0.8, 0, 1)
	elif getup_time > 0:
		motion = "get_up" if visual.sheets.has("get_up") else "jump"
		progress = 1.0 - getup_time / GETUP_DURATION
	elif ultimate_pose > 0 and can_use_ultimate():
		motion = "ultimate_air" if ultimate_airborne else "ultimate"
		progress = (1.6 - game.ult_time) / 1.6
	elif stun > 0:
		motion = "hurt"
		progress = 1.0 - stun / maxf(hurt_duration, 0.01)
	elif attack_time > 0:
		motion = attack_motion()
		progress = attack_progress()
	elif height > 0:
		motion = "jump"
		progress = jump_elapsed / jump_duration
	elif moving:
		motion = "run" if (running or ai_returning) and visual.sheets.has("run") else "walk"
	var celebration_hop := 0.0
	if victory_time >= 0 and not visual.sheets.has("victory"):
		celebration_hop = sin(progress * PI) * 24
	visual.position = Vector2(0, -roundf(height + celebration_hop))
	visual.modulate.a = 0.4 if invincible > 0 and stun <= 0 and ultimate_pose <= 0 and not dead and int(anim * 16) % 2 == 0 else 1.0
	visual.visible = kind == -1 or not dead or death_time < 1.65
	if dead and kind >= 0:
		visual.modulate.a = clampf((1.65 - death_time) / 0.35, 0, 1)
	visual.weapon = weapon
	visual.update_pose(motion, dt, facing, progress)
	if not dead and is_instance_valid(grabbed_by):
		visual.source_frame = 3
		visual.modulate.a = 1
		visual.queue_redraw()
	elif not dead and grapple.active():
		grapple.pose()

func strike() -> void:
	if weapon_attack and weapon.is_empty():
		return
	var targets: Array = (game.enemies + game.props) if kind == -1 else [game.player]
	for target in targets:
		if target.dead or target in hits:
			continue
		var delta: Vector2 = target.position - position
		var reach := 105.0 if attack_motion() == "punch_weapon" else (89.0 if air_attack or combo == 2 or prop_attack else 70.0)
		if kind == 2 and not weapon_attack:
			reach = 80
		if delta.x * facing > -12 and delta.x * facing < reach and absf(delta.y) < game.MELEE_DEPTH:
			var height_difference: float = absf(height - target.height)
			if height_difference > (112.0 if air_attack else 40.0):
				continue
			hits.append(target)
			var hp_before: float = target.hp
			var damage := 16.0
			if kind == -1:
				damage = 29 if combo == 2 or air_attack or run_attack else 19
				if attack_motion() == "punch_weapon":
					damage = 42 if weapon == "pipe" else 36
			elif is_boss:
				damage = 36
			elif kind == 1:
				damage = 10
			elif kind == 2:
				damage = 26
			if kind >= 0 and weapon_attack:
				damage *= 1.5
			if launches_on_special() and target.has_method("launch_away"):
				target.launch_away(damage, facing, true, self)
			else:
				target.hurt(damage, facing, combo == 2 or air_attack or kind == 2)
			if weapon_attack and target.has_method("launch_away") and target.hp < hp_before:
				weapon_durability = maxi(0, weapon_durability - weapon_hit_cost(target))
				if weapon_durability == 0:
					break_equipped_weapon()
					break

static func weapon_hit_cost(target: Node2D) -> int:
	return 50 if target.is_boss else ([10, 20, 30][target.kind] if target.kind >= 0 else 10)

func seek_weapon(dt: float) -> bool:
	if not weapon.is_empty() or height > 0 or cooldown > 0:
		return false
	if not is_instance_valid(ai_weapon_target):
		if ai_weapon_cooldown > 0:
			return false
		ai_weapon_cooldown = randf_range(12, 20)
		if randf() >= 0.2 or position.distance_to(game.player.position) < 90:
			return false
		for item in game.weapons:
			if not item.dead and not item.weapon_airborne and not item.weapon_broken and position.distance_to(item.position) < 120:
				ai_weapon_target = item
				ai_weapon_seek_time = 3
				break
	if not is_instance_valid(ai_weapon_target):
		return false
	ai_weapon_seek_time -= dt
	if ai_weapon_target.dead or ai_weapon_target.weapon_airborne or ai_weapon_target.weapon_broken or ai_weapon_seek_time <= 0:
		ai_weapon_target = null
		return false
	var delta: Vector2 = ai_weapon_target.position - position
	if absf(delta.x) < 28 and absf(delta.y) < game.MELEE_DEPTH:
		begin_pickup(ai_weapon_target)
		ai_weapon_target = null
	else:
		facing = 1 if delta.x >= 0 else -1
		position += delta.normalized() * Vector2(ENEMY_SPEEDS[kind], game.DEPTH_SPEED) * dt
		moving = true
	return true

func throw_weapon() -> void:
	var item := release_weapon(facing)
	if item == null:
		return
	item.weapon_thrower = self
	item.weapon_projectile = true
	item.weapon_velocity.x = facing * 480
	item.weapon_lift_speed = 140
	reset_running()
	attack_time = 0
	attack_buffer = 0
	cooldown = 0.25
	game.sound("swing")
	update_visual(0)

func release_weapon(direction: float, broken := false) -> Node2D:
	if weapon.is_empty():
		return null
	var hand := Vector2(20 * facing, -55 - height)
	if is_instance_valid(visual):
		var data: Dictionary = visual.definition(visual.motion)
		var anchor: Array = data.get("pivot_pixels", visual.character_data["pivot_pixels"])
		var pixel_scale := float(data.get("scale", visual.character_data["scale"]))
		var grip: Vector2 = visual.weapon_hand_position(visual.motion, visual.source_frame)
		hand = (grip - Vector2(anchor[0], anchor[1])) * pixel_scale
		hand.x *= facing
		hand.y += visual.position.y
	var item = game.spawn_weapon(position + Vector2(hand.x, 0), weapon)
	item.weapon_durability = weapon_durability
	item.height = maxf(15, -hand.y)
	item.weapon_broken = broken
	item.weapon_airborne = not broken
	item.weapon_velocity = Vector2(direction * 150, 0)
	item.weapon_lift_speed = 220
	weapon = ""
	visual.weapon = ""
	visual.queue_redraw()
	return item

func break_equipped_weapon() -> void:
	release_weapon(facing, true)
	game.sound("hit")

func launches_on_special() -> bool:
	if kind == -1:
		return run_attack or air_attack
	if is_boss:
		return run_attack or air_attack
	return (air_attack and kind >= 1) or (run_attack and kind == 2)

func launch_away(damage: float, direction: float, can_hit_others := true, thrower: Node2D = null, from_ultimate := false) -> bool:
	if dead or invincible > 0 or thrown_time > 0 or (getup_time > 0 and kind == -1):
		return false
	if is_boss and not from_ultimate:
		var before := hp
		hurt(damage, direction, true)
		return hp < before
	release_weapon(direction)
	hurt(damage, direction, true)
	velocity = Vector2(direction * THROW_SPEED, 0)
	height = 25
	jump_speed = 330
	thrown_time = 1.1
	flight_can_hit = can_hit_others
	flight_hits.clear()
	if is_instance_valid(thrower):
		flight_hits.append(thrower)
	getup_time = 0
	stun = 1.1
	hurt_duration = 1.1
	air_attack = false
	moving = false
	update_visual(0)
	return true

func update_flight_impacts(from: Vector2) -> void:
	if not flight_can_hit or thrown_time <= 0 or height <= 0:
		return
	var direction := signf(velocity.x)
	if direction == 0:
		return
	for target in game.enemies:
		if target == self or target.dead or target in flight_hits:
			continue
		# Sweep the body along this frame's path so fast throws cannot skip rivals.
		if target.position.x < minf(from.x, position.x) - 22 or target.position.x > maxf(from.x, position.x) + 22:
			continue
		if absf(target.position.y - position.y) >= game.MELEE_DEPTH or absf(target.height - height) > 90:
			continue
		if target.launch_away(FLIGHT_IMPACT_DAMAGE, direction, false):
			flight_hits.append(target)

func hurt(damage: float, direction: float, heavy := false, from_grab := false) -> void:
	if dead or invincible > 0 or thrown_time > 0 or (getup_time > 0 and kind == -1):
		return
	if kind >= 0:
		getup_time = 0
	if not from_grab:
		if grapple.active():
			grapple.release()
		if is_instance_valid(grabbed_by):
			grabbed_by.grapple.release()
	reset_running()
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
		release_weapon(direction)
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
	if windup > 0 or rush_windup > 0:
		draw_string(ArcadeUI.FONT, Vector2(-4, -head * 0.65), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffdb8b"))

func draw_ellipse_shadow() -> void:
	var shade := Color(0.015, 0.02, 0.06, 0.5)
	draw_rect(Rect2(-15, -3, 30, 6), shade)
	draw_rect(Rect2(-20, -1, 40, 3), shade)

func movement_left_bound() -> float:
	return game.left_bound if kind == -1 else 30.0
