extends Node2D

const SUPPLIES = preload("res://assets/items/supplies.png")
const WeaponArt = preload("res://scripts/weapon_art.gd")

var game: Node2D
var hp := 1.0
var dead := false
var height := 0.0
var barrel := false
var as_food := false
var beer := false
var weapon := ""
var weapon_durability := 100
var weapon_airborne := false
var weapon_broken := false
var weapon_projectile := false
var weapon_thrower: Node2D
var weapon_velocity := Vector2.ZERO
var weapon_lift_speed := 0.0
var weapon_rotation := 0.0
var break_elapsed := 0.0
var age := 0.0

func setup(owner_game: Node2D, at: Vector2, is_barrel: bool) -> void:
	game = owner_game
	position = at
	barrel = is_barrel
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = int(position.y)

func hurt(damage: float, direction: float, _heavy := false) -> void:
	if dead or as_food or not weapon.is_empty() or damage <= 0:
		return
	hp = 0
	dead = true
	hide()
	game.sound("hit")
	game.impact(position - Vector2(0, 16), direction, false)
	game.score += 50
	game.drop_food(position)
	for i in range(8):
		game.particles.append({"pos": position - Vector2(0, 16), "vel": Vector2(randf_range(-100, 100), randf_range(-130, -30)), "life": 0.45, "color": Color("8899a6" if barrel else "be8846"), "size": 3.0})

func tick(dt: float) -> void:
	age += dt
	if weapon_broken:
		break_elapsed += dt
		if break_elapsed >= 0.65:
			dead = true
			hide()
	elif weapon_airborne:
		var from := position.x
		var min_x: float = game.left_bound + 12
		var max_x: float = game.right_bound - 12
		if weapon_projectile:
			min_x = maxf(min_x, game.camera_x + 42)
			max_x = minf(max_x, game.camera_x + 960.0 / game.WORLD_ZOOM - 42)
		var next_x := position.x + weapon_velocity.x * dt
		position.x = clampf(next_x, min_x, max_x)
		height += weapon_lift_speed * dt
		weapon_lift_speed -= 850 * dt
		weapon_rotation += 24 * dt * signf(weapon_velocity.x)
		if weapon_projectile:
			projectile_hit(from)
			if weapon_projectile and not is_equal_approx(next_x, position.x):
				stop_projectile()
				game.sound("hit")
		if height <= 0:
			height = 0
			weapon_airborne = false
			weapon_rotation = 0
			weapon_projectile = false
	queue_redraw()

func projectile_hit(from: float) -> void:
	if not is_instance_valid(weapon_thrower):
		weapon_projectile = false
		return
	var targets: Array = game.enemies + [game.player]
	var nearest: Node2D
	var nearest_distance := INF
	for target in targets:
		if target.dead or target == weapon_thrower or absf(target.position.y - position.y) >= game.MELEE_DEPTH:
			continue
		if height < target.height or height > target.height + 105:
			continue
		if target.invincible > 0 or target.thrown_time > 0 or (target.kind == -1 and target.getup_time > 0):
			continue
		if target.position.x < minf(from, position.x) - 22 or target.position.x > maxf(from, position.x) + 22:
			continue
		var distance: float = absf(target.position.x - from)
		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance
	if nearest == null:
		return
	var direction := signf(weapon_velocity.x)
	if not nearest.launch_away(42 if weapon == "pipe" else 36, direction, false, weapon_thrower):
		return
	position.x = nearest.position.x - direction * 20
	stop_projectile()
	weapon_durability = maxi(0, weapon_durability - weapon_thrower.weapon_hit_cost(nearest))
	if weapon_durability == 0:
		weapon_broken = true
		weapon_airborne = false
	game.sound("hit")

func stop_projectile() -> void:
	weapon_projectile = false
	weapon_velocity.x = 0
	weapon_lift_speed = minf(0, weapon_lift_speed)

func _draw() -> void:
	if dead:
		return
	draw_set_transform(Vector2(0, -1), 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 19, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if not weapon.is_empty():
		if weapon_broken:
			for side in [-1, 1]:
				var offset := Vector2(side * break_elapsed * 80, -height + break_elapsed * break_elapsed * 180)
				WeaponArt.draw_weapon(self, weapon, offset, side * break_elapsed * 12, 48, 0 if side == -1 else 1)
			return
		WeaponArt.draw_weapon(self, weapon, Vector2(0, -height - 4), weapon_rotation if weapon_airborne else -0.16)
		return
	# The wide sushi platter extends beyond a quarter of the atlas.
	var region := Rect2(0, 0, 0.52, 0.50)
	var size := Vector2(46, 46)
	if as_food:
		region = Rect2(0.62, 0.50, 0.31, 0.47) if beer else Rect2(0, 0.53, 0.61, 0.45)
		size = Vector2(24, 42) if beer else Vector2(52, 34)
	elif barrel:
		region = Rect2(0.60, 0, 0.38, 0.50)
		size = Vector2(39, 52)
	var atlas_size := SUPPLIES.get_size()
	region = Rect2((region.position * atlas_size).floor(), (region.size * atlas_size).floor())
	draw_texture_rect_region(SUPPLIES, Rect2(Vector2(-size.x / 2, -size.y), size), region)
	if as_food and int(age * 3) % 2 == 0:
		draw_rect(Rect2(-size.x / 2 - 4, -size.y + 3, 2, 6), Color("ffe6a0"))
		draw_rect(Rect2(-size.x / 2 - 6, -size.y + 5, 6, 2), Color("ffe6a0"))
