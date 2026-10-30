extends RefCounted

var owner_fighter: Node2D
var victim: Node2D
var state := ""
var elapsed := 0.0
var locked_facing := 1.0
var did_hit := false
var retry := 0.0
var punch_count := 0
var punch_animation := "grab_punch_01"
var escape_presses := 0
var escape_idle := 0.0
var escape_down: Dictionary = {}
const ESCAPE_ACTIONS = ["attack", "jump", "left", "right", "up", "down"]
const ESCAPE_REQUIRED := 5
const PLAYER_THROW_SPEED := 2.0
const PLAYER_CATCH_SPEED := 2.0
var buffered_action := ""

func _init(fighter: Node2D) -> void:
	owner_fighter = fighter

func active() -> bool:
	return not state.is_empty()

func try_start() -> bool:
	var hero := owner_fighter
	if active() or retry > 0 or hero.dead or hero.stun > 0 or hero.height > 0 or hero.attack_time > 0 or hero.cooldown > 0 or hero.thrown_time > 0 or hero.getup_time > 0 or is_instance_valid(hero.grabbed_by):
		return false
	if not hero.visual.sheets.has("grab_throw"):
		return false
	var closest := 25.0
	var candidate: Node2D
	var candidates: Array = hero.game.enemies if hero.kind == -1 else [hero.game.player]
	if hero.kind >= 0 and not hero.game.combat_director.allowed(hero):
		return false
	for enemy in candidates:
		if enemy.dead or enemy.height > 0 or enemy.thrown_time > 0 or enemy.getup_time > 0 or enemy.grapple.active() or is_instance_valid(enemy.grabbed_by):
			continue
		if hero.kind >= 0 and enemy.invincible > 0:
			continue
		var delta: Vector2 = enemy.position - hero.position
		if delta.x * hero.facing < 0 or absf(delta.y) > 6 or absf(delta.x) >= closest:
			continue
		candidate = enemy
		closest = absf(delta.x)
	if candidate == null:
		return false
	victim = candidate
	locked_facing = hero.facing
	state = "catch"
	elapsed = 0
	did_hit = false
	punch_count = 0
	buffered_action = ""
	escape_presses = 0
	escape_idle = 0
	escape_down.clear()
	for action in ESCAPE_ACTIONS:
		escape_down[action] = Input.is_action_pressed(action)
	hero.velocity = Vector2.ZERO
	hero.moving = false
	hero.attack_buffer = 0
	hero.combo_window = 0
	hero.reset_running()
	victim.reset_running()
	victim.grabbed_by = hero
	victim.attack_time = 0
	victim.windup = 0
	victim.velocity = Vector2.ZERO
	victim.moving = false
	hero.game.combat_director.turns.erase(victim)
	align_victim()
	hero.update_visual(0)
	victim.update_visual(0)
	return true

func align_victim() -> void:
	if not is_instance_valid(victim):
		return
	var hero := owner_fighter
	# Keep the hands and the captive on the same lane, even at a stage edge.
	hero.position.x = clampf(hero.position.x, hero.game.left_bound + 32, hero.game.right_bound - 32)
	victim.position = hero.position + Vector2(locked_facing * 32, 0)
	victim.facing = -locked_facing
	victim.velocity = Vector2.ZERO
	victim.z_index = int(victim.position.y) - 1

func tick(dt: float) -> void:
	var hero := owner_fighter
	if hero.dead or hero.stun > 0 or (hero.kind >= 0 and not hero.game.combat_director.allowed(hero)) or (state not in ["recover", "punch_recover"] and (not is_instance_valid(victim) or victim.dead)):
		release()
		return
	if hero.kind == -1 and Input.is_action_just_pressed("jump") and state != "recover":
		release()
		var direction := Input.get_vector("left", "right", "up", "down")
		hero.takeoff(direction * Vector2(hero.WALK_SPEED, hero.game.DEPTH_SPEED))
		return
	if hero.kind == -1 and state == "catch" and Input.is_action_just_pressed("attack"):
		buffered_action = "throw" if Input.get_axis("left", "right") * locked_facing < -0.35 else "punch"
	elapsed += dt
	hero.facing = locked_facing
	hero.velocity = Vector2.ZERO
	hero.moving = false
	align_victim()
	var data: Dictionary = hero.visual.definition("grab_throw")
	var fps := float(data["fps"])
	var catch_speed := PLAYER_CATCH_SPEED if hero.kind == -1 else 1.0
	var throw_speed := PLAYER_THROW_SPEED if hero.kind == -1 else 1.0
	var hold_frame := int(data.get("hold_frame", 8))
	match state:
		"catch":
			if elapsed * catch_speed >= float(hold_frame + 1) / fps:
				state = "hold" if buffered_action.is_empty() else buffered_action
				elapsed = 0
				if not buffered_action.is_empty():
					select_punch_animation()
					did_hit = false
					hero.game.sound("swing")
					buffered_action = ""
		"hold":
			if hero.kind >= 0:
				if elapsed >= 0.3:
					state = "throw"
					elapsed = 0
					hero.game.sound("swing")
				return
			if Input.is_action_just_pressed("ultimate"):
				hero.game.use_ultimate()
				return
			if Input.is_action_just_pressed("attack"):
				var horizontal := Input.get_axis("left", "right")
				state = "throw" if horizontal * locked_facing < -0.35 else "punch"
				select_punch_animation()
				elapsed = 0
				did_hit = false
				hero.game.sound("swing")
		"punch", "punch_recover":
			var duration: float = hero.visual.duration(punch_animation)
			var progress := elapsed / duration
			var frame: int = hero.visual.frame_at(punch_animation, progress)
			for contact in hero.visual.definition(punch_animation)["active_hit_frames"]:
				if state == "punch" and not did_hit and (frame == int(contact) or progress >= 0.75):
					did_hit = true
					punch_count += 1
					victim.invincible = 0
					if punch_count == 3:
						var target := victim
						victim = null
						target.grabbed_by = null
						target.launch_away(19, locked_facing, false, hero)
						state = "punch_recover"
					else:
						victim.hurt(19, locked_facing, false, true)
						if victim.dead:
							release()
							return
			if elapsed >= duration:
				if state == "punch_recover":
					release()
					hero.cooldown = 0.15
				else:
					state = "hold"
					elapsed = 0
		"throw":
			var current_frame := hold_frame + 1 + int(elapsed * fps * throw_speed)
			if current_frame >= int(data.get("release_frame", 15)):
				launch()
				state = "recover"
		"recover":
			if hold_frame + 1 + int(elapsed * fps * throw_speed) >= int(data["frame_indices"].size()):
				state = ""
				retry = 0.65
				hero.cooldown = 0.15

func launch() -> void:
	var hero := owner_fighter
	var target := victim
	victim = null
	target.grabbed_by = null
	target.invincible = 0
	target.position = hero.position + Vector2(-locked_facing * 36, 0)
	target.position.x = clampf(target.position.x, hero.game.left_bound, hero.game.right_bound)
	target.launch_away(40, -locked_facing, true, hero)

func release() -> void:
	if is_instance_valid(victim):
		victim.grabbed_by = null
		victim.velocity = Vector2.ZERO
		if not victim.dead:
			victim.stun = 0.3
			victim.hurt_duration = 0.3
			victim.ai_wait = 0.6
		victim.update_visual(0)
	victim = null
	state = ""
	elapsed = 0
	punch_count = 0
	buffered_action = ""
	escape_presses = 0
	escape_down.clear()
	retry = 0.65

func try_escape(dt: float) -> void:
	if owner_fighter.kind < 0 or not is_instance_valid(victim) or victim.kind != -1:
		return
	escape_idle += dt
	if escape_idle > 0.8:
		escape_presses = 0
	for action in ESCAPE_ACTIONS:
		var down := Input.is_action_pressed(action)
		if down and not escape_down.get(action, false):
			escape_presses += 1
			escape_idle = 0
		escape_down[action] = down
	if escape_presses < ESCAPE_REQUIRED:
		return
	var escaped := victim
	var captor := owner_fighter
	release()
	escaped.stun = 0
	escaped.invincible = maxf(escaped.invincible, 1.0)
	escaped.attack_buffer = 0
	escaped.position.x = clampf(escaped.position.x + locked_facing * 18, captor.game.left_bound, captor.game.right_bound)
	captor.stun = 0.6
	captor.hurt_duration = 0.6
	captor.cooldown = 0.8
	captor.ai_wait = 0.8
	captor.game.combat_director.turns.erase(captor)
	escaped.update_visual(0)
	captor.update_visual(0)

func select_punch_animation() -> void:
	var name := "grab_punch_%02d" % (punch_count + 1)
	punch_animation = name if owner_fighter.visual.sheets.has(name) else "grab_punch_01"

func pose() -> void:
	var hero := owner_fighter
	if state in ["punch", "punch_recover"]:
		hero.visual.update_pose(punch_animation, 0, locked_facing, elapsed / hero.visual.duration(punch_animation))
		return
	var data: Dictionary = hero.visual.definition("grab_throw")
	var hold_frame := int(data.get("hold_frame", 8))
	var frame := hold_frame
	if state == "catch":
		frame = mini(hold_frame, int(elapsed * float(data["fps"]) * (PLAYER_CATCH_SPEED if hero.kind == -1 else 1.0)))
	elif state in ["throw", "recover"]:
		frame = mini(data["frame_indices"].size() - 1, hold_frame + 1 + int(elapsed * float(data["fps"]) * (PLAYER_THROW_SPEED if hero.kind == -1 else 1.0)))
	hero.visual.update_pose("grab_throw", 0, locked_facing, 0)
	hero.visual.source_frame = frame
	hero.visual.queue_redraw()
