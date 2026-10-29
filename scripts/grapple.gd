extends RefCounted

var owner_fighter: Node2D
var victim: Node2D
var state := ""
var elapsed := 0.0
var locked_facing := 1.0
var did_hit := false
var retry := 0.0

func _init(fighter: Node2D) -> void:
	owner_fighter = fighter

func active() -> bool:
	return not state.is_empty()

func try_start() -> bool:
	var hero := owner_fighter
	if active() or retry > 0 or hero.dead or hero.stun > 0 or hero.height > 0 or hero.attack_time > 0 or hero.cooldown > 0:
		return false
	if not hero.visual.sheets.has("grab_throw"):
		return false
	var closest := 25.0
	var candidate: Node2D
	for enemy in hero.game.enemies:
		if enemy.dead or enemy.height > 0 or enemy.thrown_time > 0 or is_instance_valid(enemy.grabbed_by):
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
	hero.velocity = Vector2.ZERO
	hero.moving = false
	hero.attack_buffer = 0
	hero.combo_window = 0
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
	if hero.dead or hero.stun > 0 or (state != "recover" and (not is_instance_valid(victim) or victim.dead)):
		release()
		return
	elapsed += dt
	hero.facing = locked_facing
	hero.velocity = Vector2.ZERO
	hero.moving = false
	align_victim()
	var data: Dictionary = hero.visual.definition("grab_throw")
	var fps := float(data["fps"])
	var hold_frame := int(data.get("hold_frame", 8))
	match state:
		"catch":
			if elapsed >= float(hold_frame + 1) / fps:
				state = "hold"
				elapsed = 0
		"hold":
			if Input.is_action_just_pressed("ultimate"):
				hero.game.use_ultimate()
				return
			if Input.is_action_just_pressed("attack"):
				var horizontal := Input.get_axis("left", "right")
				state = "throw" if horizontal * locked_facing < -0.35 else "punch"
				elapsed = 0
				did_hit = false
				hero.game.sound("swing")
		"punch":
			var duration: float = hero.visual.duration("grab_punch_01")
			var progress := elapsed / duration
			var frame: int = hero.visual.frame_at("grab_punch_01", progress)
			for contact in hero.visual.definition("grab_punch_01")["active_hit_frames"]:
				if not did_hit and (frame == int(contact) or progress >= 0.75):
					did_hit = true
					victim.invincible = 0
					victim.hurt(19, locked_facing, false, true)
					if victim.dead:
						release()
						return
			if elapsed >= duration:
				state = "hold"
				elapsed = 0
		"throw":
			var current_frame := hold_frame + 1 + int(elapsed * fps)
			if current_frame >= int(data.get("release_frame", 15)):
				launch()
				state = "recover"
		"recover":
			if hold_frame + 1 + int(elapsed * fps) >= int(data["frame_indices"].size()):
				state = ""
				retry = 0.65
				hero.cooldown = 0.15

func launch() -> void:
	var hero := owner_fighter
	var target := victim
	victim = null
	target.grabbed_by = null
	target.invincible = 0
	target.hurt(40, -locked_facing, true)
	target.position = hero.position + Vector2(-locked_facing * 36, 0)
	target.velocity = Vector2(-locked_facing * 310, 0)
	target.height = 25
	target.jump_speed = 330
	target.thrown_time = 1.1
	target.stun = 1.1
	target.hurt_duration = 1.1
	target.update_visual(0)

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
	retry = 0.65

func pose() -> void:
	var hero := owner_fighter
	if state == "punch":
		hero.visual.update_pose("grab_punch_01", 0, locked_facing, elapsed / hero.visual.duration("grab_punch_01"))
		return
	var data: Dictionary = hero.visual.definition("grab_throw")
	var hold_frame := int(data.get("hold_frame", 8))
	var frame := hold_frame
	if state == "catch":
		frame = mini(hold_frame, int(elapsed * float(data["fps"])))
	elif state in ["throw", "recover"]:
		frame = mini(data["frame_indices"].size() - 1, hold_frame + 1 + int(elapsed * float(data["fps"])))
	hero.visual.update_pose("grab_throw", 0, locked_facing, 0)
	hero.visual.source_frame = frame
	hero.visual.queue_redraw()
