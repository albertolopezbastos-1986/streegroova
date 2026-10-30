extends Node2D

const Breakable = preload("res://scripts/breakable.gd")
const CombatDirector = preload("res://scripts/combat_director.gd")
const Fighter = preload("res://scripts/fighter.gd")
const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const START_LOGO: Texture2D = preload("res://assets/branding/groovaipa-logo.png")
const CharacterCatalog = preload("res://scripts/character_catalog.gd")
const PIXEL_STREET = preload("res://assets/environment/neighborhood-pixel.png")
const LIFE_PIXELS = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
const INK = Color("101322")
const CREAM = Color("f5e9d0")
const MINT = Color("62efd4")
const WORLD_ZOOM := 1.96875
const WALK_MIN_Y := 350.0
const WALK_MAX_Y := 430.0
const START_Y := 420.0
const MELEE_DEPTH := 10.0
const DEPTH_SPEED := 46.6667
const WAVE_COUNT := 5
const LEVEL_COUNT := 3
const STAGE_CLEAR_DURATION := 3.5
const VICTORY_DURATION := 5.0
const SECTION_WIDTH := 850.0
const BACKTRACK_DISTANCE := 700.0
const LEVEL_WIDTH := SECTION_WIDTH * WAVE_COUNT
const CAMERA_ANCHOR_X := 300.0
const VIEW_HEIGHT := 720.0
const FLOOR_BACK_Y := 339.0
const CURB_TOP_Y := 393.0
const CURB_BOTTOM_Y := 399.0
const WORLD_OFFSET_Y := 630.0 - START_Y * WORLD_ZOOM
var combat_director: RefCounted
var player: Node2D
var enemies: Array = []
var particles: Array = []
var props: Array = []
var food: Array = []
var state := "title"
var previous_state := "play"
var score := 0
var lives := 3
var charge := 0.0
var combo_hits := 0
var combo_timer := 0.0
var stage := 0
var level_index := 0
var presentation_time := 0.0
var left_bound := 30.0
var right_bound := 850.0
var camera_x := 0.0
var shake := 0.0
var freeze := 0.0
var ult_time := 0.0
var ult_applied := false
var time := 0.0
var banner_time := 0.0
var respawn_time := 0.0
var transition := 0.0
@export var simulate_mobile := false
var touch_visible := false
var mobile_controls: CanvasLayer
var sounds: Dictionary = {}
var audio_players: Array = []
var music: AudioStreamPlayer
var muted := false
var best := 0
var font: Font
var world: Node2D
var online_scores: Node
var ranking_panel: CanvasLayer
var character_select: CanvasLayer
var debug_room := false
var debug_panel: CanvasLayer
var debug_status: Label
var active_character_id := "beto"
var character_pack: Dictionary = {}
var run_id := ""
var show_help := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	RenderingServer.set_default_clear_color(INK)
	font = ArcadeUI.FONT
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	setup_inputs()
	setup_audio()
	var save := ConfigFile.new()
	if save.load("user://record.cfg") == OK:
		best = save.get_value("score", "best", 0)
	world = Node2D.new()
	world.scale = Vector2.ONE * WORLD_ZOOM
	add_child(world)
	var overlay := Node2D.new()
	overlay.name = "Overlay"
	overlay.z_index = 1000
	overlay.draw.connect(draw_overlay)
	add_child(overlay)
	online_scores = preload("res://scripts/online_scores.gd").new()
	add_child(online_scores)
	ranking_panel = preload("res://scripts/ranking_panel.gd").new()
	add_child(ranking_panel)
	ranking_panel.setup(online_scores)
	ranking_panel.replay_requested.connect(show_character_selection)
	character_select = preload("res://scripts/character_select.gd").new()
	add_child(character_select)
	character_select.confirmed.connect(confirm_character)
	character_select.cancelled.connect(cancel_character_selection)
	setup_debug_panel()
	mobile_controls = preload("res://scripts/mobile_controls.gd").new()
	add_child(mobile_controls)
	touch_visible = simulate_mobile or mobile_controls.is_mobile()
	mobile_controls.setup(self, touch_visible)
	character_select.debug_requested.connect(func(): new_run(true))
	if touch_visible:
		character_select.setup_mobile()
	new_run()
	state = "title"

func setup_inputs() -> void:
	var keys := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE, KEY_K], "attack": [KEY_J, KEY_Z], "ultimate": [KEY_L, KEY_X], "pause_game": [KEY_ESCAPE, KEY_P], "start": [KEY_ENTER], "help": [KEY_H], "mute": [KEY_M]}
	for action in keys:
		InputMap.add_action(action)
		if action in ["left", "right", "up", "down"]:
			InputMap.action_set_deadzone(action, 0.2)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var buttons := {"attack": JOY_BUTTON_X, "jump": JOY_BUTTON_A, "ultimate": JOY_BUTTON_Y, "pause_game": JOY_BUTTON_START, "left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT, "up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN}
	for action in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = buttons[action]
		InputMap.action_add_event(action, event)
	for entry in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.axis = entry[1]
		event.axis_value = entry[2]
		InputMap.action_add_event(entry[0], event)

func new_run(as_debug := false) -> void:
	mobile_controls.release_all()
	debug_room = as_debug
	debug_panel.get_child(0).visible = as_debug
	character_select.hide_panel()
	character_pack = CharacterCatalog.character(active_character_id)
	active_character_id = character_pack["id"]
	ranking_panel.reset_run()
	run_id = online_scores.new_run_id()
	show_help = false
	score = 0
	lives = 3
	charge = 0
	level_index = 0
	load_level()

func load_level(remaining_health := 100.0) -> void:
	mobile_controls.release_all()
	if is_instance_valid(player):
		player.grapple.release()
	for enemy in enemies:
		enemy.grapple.release()
	for child in world.get_children():
		child.queue_free()
	enemies.clear()
	props.clear()
	food.clear()
	combat_director = CombatDirector.new(self)
	particles.clear()
	presentation_time = 0
	stage = 0
	camera_x = 0
	left_bound = 30
	right_bound = 850
	ult_time = 0
	respawn_time = 0
	transition = 0
	combo_hits = 0
	freeze = 0
	shake = 0
	player = Fighter.new()
	world.add_child(player)
	player.setup(self, -1, Vector2(CAMERA_ANCHOR_X / WORLD_ZOOM, START_Y), character_pack)
	player.hp = remaining_health
	player.invincible = 1.5
	if not debug_room:
		spawn_wave()
	else:
		banner_time = 0
	update_world_transform()
	state = "play"

func show_character_selection() -> void:
	debug_room = false
	debug_panel.get_child(0).hide()
	ranking_panel.reset_run()
	ranking_panel.entry_button.hide()
	show_help = false
	state = "select"
	mobile_controls.release_all()
	character_select.show_panel()

func confirm_character(slot: int) -> void:
	active_character_id = CharacterCatalog.character_for_slot(slot)["id"]
	mobile_controls.release_all()
	new_run()

func cancel_character_selection() -> void:
	character_select.hide_panel()
	state = "title"

func setup_debug_panel() -> void:
	debug_panel = CanvasLayer.new()
	debug_panel.layer = 10
	add_child(debug_panel)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 132)
	panel.size = Vector2(936, 110)
	debug_panel.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	debug_status = Label.new()
	debug_status.text = "DEBUG ROOM / TAB: volver a seleccion / vidas infinitas"
	debug_status.add_theme_font_size_override("font_size", 10)
	rows.add_child(debug_status)
	var actions := ["1 Beto", "2 Cami*", "3 Alito*", "4 Rosa", "5 Amarillo", "6 Violeta", "7 Jefe", "8 Ulti MAX", "9 Oleada random", "0 Matar todos"]
	for row_index in range(2):
		var row := HBoxContainer.new()
		rows.add_child(row)
		for column in range(5):
			var index := row_index * 5 + column
			var button := Button.new()
			button.text = actions[index]
			button.custom_minimum_size = Vector2(182, 28)
			button.add_theme_font_size_override("font_size", 10)
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(debug_action.bind((index + 1) % 10))
			row.add_child(button)
	var back := Button.new()
	back.text = "VOLVER A SELECCION"
	back.custom_minimum_size = Vector2(182, 28)
	back.add_theme_font_size_override("font_size", 10)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(show_character_selection)
	rows.add_child(back)
	panel.hide()

func debug_action(number: int) -> void:
	if not debug_room or state != "play":
		return
	match number:
		1, 2, 3:
			var id: String = ["beto", "cami", "alito"][number - 1]
			var pack := CharacterCatalog.load_pack("res://assets/characters/%s/character.json" % id)
			var placeholder := pack.is_empty()
			if placeholder:
				pack = CharacterCatalog.character("beto").duplicate(true)
				pack["id"] = id
				pack["display_name"] = id.capitalize() + " (grafica Beto)"
			var at: Vector2 = player.position
			var direction: float = player.facing
			player.grapple.release()
			if is_instance_valid(player.grabbed_by):
				player.grabbed_by.grapple.release()
			player.z_index = int(at.y)
			player.queue_free()
			character_pack = pack
			active_character_id = id
			player = Fighter.new()
			world.add_child(player)
			player.setup(self, -1, at, pack)
			player.facing = direction
			player.invincible = 1.5
			ult_time = 0
			ult_applied = false
			respawn_time = 0
			freeze = 0
			combat_director.reset()
			debug_status.text = "DEBUG / %s / TAB: seleccion%s" % [id.capitalize(), " / * Graficos temporales de Beto" if placeholder else ""]
		4, 5, 6:
			debug_spawn_enemy(number - 4)
		7:
			debug_spawn_enemy(0, true)
		8:
			charge = 100
		9:
			for i in range(randi_range(3, 7)):
				debug_spawn_enemy(randi_range(0, 2))
		0:
			player.grapple.release()
			combat_director.reset()
			for enemy in enemies:
				if not enemy.dead:
					enemy.invincible = 0
					enemy.thrown_time = 0
					enemy.getup_time = 0
					enemy.hurt(enemy.hp, 1, true)

func debug_spawn_enemy(kind: int, boss := false) -> void:
	var enemy := Fighter.new()
	world.add_child(enemy)
	var x := clampf(player.position.x + (110 if randf() > 0.5 else -110), left_bound + 32, right_bound - 32)
	enemy.setup(self, kind, Vector2(x, randf_range(WALK_MIN_Y, WALK_MAX_Y)))
	if boss:
		enemy.make_boss()
	enemies.append(enemy)

func spawn_wave() -> void:
	combat_director.reset()
	var waves := [[0, 0, 1], [1, 0, 2], [0, 1, 0, 1], [2, 0, 1], [0]]
	for i in range(waves[stage].size()):
		var enemy = Fighter.new()
		world.add_child(enemy)
		var x := minf(right_bound - 65, player.position.x + 155 + i * 38)
		enemy.setup(self, waves[stage][i], Vector2(x, lerpf(WALK_MIN_Y + 10, WALK_MAX_Y - 10, float(i % 3) / 2.0)))
		if stage == WAVE_COUNT - 1:
			enemy.make_boss()
		enemies.append(enemy)
	# Supplies persist when backtracking; they spawn only once per section.
	for i in range(2):
		var prop = Breakable.new()
		world.add_child(prop)
		prop.setup(self, Vector2(stage * SECTION_WIDTH + 380 + i * 290, START_Y + (6 if i == 0 else -6)), i == 1)
		props.append(prop)
	banner_time = 3

func drop_chicken(at: Vector2) -> void:
	var pickup = Breakable.new()
	world.add_child(pickup)
	pickup.setup(self, at, false)
	pickup.as_food = true
	food.append(pickup)

func update_supplies(dt: float) -> void:
	for prop in props:
		prop.tick(dt)
	for pickup in food:
		pickup.tick(dt)
		if pickup.dead or player.dead or player.height > 8 or player.hp >= player.max_hp:
			continue
		if absf(player.position.x - pickup.position.x) < 23 and absf(player.position.y - pickup.position.y) < MELEE_DEPTH:
			player.hp = minf(player.max_hp, player.hp + 50)
			pickup.dead = true
			pickup.hide()
			sound("power")

func _input(event: InputEvent) -> void:
	if mobile_controls.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if ranking_panel.open:
		return
	if state in ["stage_clear", "victory"]:
		return
	if state == "select":
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
			new_run(true)
			get_viewport().set_input_as_handled()
			return
		character_select.handle_input(event)
		return
	if debug_room and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB:
			show_character_selection()
			get_viewport().set_input_as_handled()
			return
		if state == "play" and event.physical_keycode >= KEY_0 and event.physical_keycode <= KEY_9:
			debug_action(event.physical_keycode - KEY_0)
			get_viewport().set_input_as_handled()
			return
	if state == "title":
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
			ranking_panel.show_ranking()
			return
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if ranking_panel.entry_button.get_global_rect().has_point(event.position):
				return
	if event is InputEventScreenTouch and event.pressed and state in ["title", "over", "won"]:
		show_character_selection()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state in ["title", "over", "won"]:
			show_character_selection()
			return
	if event.is_action_pressed("mute"):
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
	if event.is_action_pressed("help"):
		show_help = not show_help
		player.reset_running()
		mobile_controls.release_all()
	if event.is_action_pressed("start") or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		if state in ["title", "over", "won"]:
			show_character_selection()
			return
	if event.is_action_pressed("pause_game"):
		if state == "pause":
			state = previous_state
		elif state == "play":
			player.reset_running()
			previous_state = state
			state = "pause"
			mobile_controls.release_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play":
		player.reset_running()
		state = "pause"
		previous_state = "play"
		mobile_controls.release_all()

func _process(dt: float) -> void:
	time += dt
	ranking_panel.entry_button.visible = state == "title" and not ranking_panel.open
	if state == "play" and not show_help:
		update_game(minf(dt, 0.04))
	elif state in ["stage_clear", "victory"]:
		update_presentation(dt)
	if state != "pause":
		for p in particles:
			p.life -= dt
			p.pos += p.vel * dt
			p.vel.y += dt * 220
		particles = particles.filter(func(p): return p.life > 0)
	shake = maxf(0, shake - dt * 30)
	update_world_transform()
	queue_redraw()

func update_world_transform() -> void:
	var offset := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	var follow_y := 0.0
	if is_instance_valid(player) and is_instance_valid(player.visual):
		var data: Dictionary = player.visual.character_data
		var sprite_height := float(data["pivot_pixels"][1]) * float(data["scale"])
		var top: float = (player.position.y - player.height - sprite_height) * WORLD_ZOOM + WORLD_OFFSET_Y
		# At this close range a full jump exceeds the viewport height. Pan up
		# with the player while keeping the HUD fixed and the jump physics intact.
		follow_y = maxf(0, 100.0 - top)
	world.position = Vector2(-camera_x * WORLD_ZOOM, WORLD_OFFSET_Y + follow_y) + offset

func world_to_screen(point: Vector2) -> Vector2:
	return world.position + point * WORLD_ZOOM

func update_game(dt: float) -> void:
	if state != "play":
		return
	banner_time = maxf(0, banner_time - dt)
	combo_timer = maxf(0, combo_timer - dt)
	if combo_timer == 0:
		combo_hits = 0
	if freeze > 0:
		freeze -= dt
		return
	if ult_time > 0:
		ult_time -= dt
		player.ultimate_pose = 0.1
		player.update_visual(dt)
		player.queue_redraw()
		if ult_time < 0.65 and not ult_applied:
			ult_applied = true
			for enemy in enemies:
				if not enemy.dead:
					enemy.invincible = 0
					enemy.hurt(65, signf(enemy.position.x - player.position.x), true)
			shake = 15
			sound("ultimate")
		if ult_time <= 0:
			player.ultimate_pose = 0
			player.update_visual(0)
		return
	player.tick(dt)
	combat_director.update(dt)
	for enemy in enemies:
		enemy.tick(dt)
	update_supplies(dt)
	if player.dead:
		respawn_time += dt
		if respawn_time > 1.4:
			lives -= 1
			respawn_time = 0
			if debug_room:
				lives = 3
			if lives <= 0:
				finish("over")
			else:
				player.grapple.release()
				player.dead = false
				player.death_time = 0
				player.thrown_time = 0
				player.getup_time = 0
				player.reset_running()
				player.hp = player.max_hp
				player.height = 0
				player.jump_speed = 0
				player.invincible = 2.5
				player.position.x = maxf(left_bound + 80, player.position.x)
				player.stun = 0
				player.attack_time = 0
				player.air_attack = false
				player.attack_buffer = 0
				player.velocity = Vector2.ZERO
				player.moving = false
				player.update_visual(0)
		return
	var alive := enemies.filter(func(e): return not e.dead).size()
	if alive == 0 and not debug_room:
		transition += dt
		if stage == WAVE_COUNT - 1 and transition > 2:
			complete_level()
			return
		elif stage < WAVE_COUNT - 1:
			right_bound = (stage + 2) * SECTION_WIDTH
			if player.position.x > (stage + 1) * SECTION_WIDTH + 80:
				stage += 1
				left_bound = maxf(30, stage * SECTION_WIDTH - BACKTRACK_DISTANCE)
				transition = 0
				spawn_wave()
	camera_x = lerpf(camera_x, clampf(player.position.x - CAMERA_ANCHOR_X / WORLD_ZOOM, 0, LEVEL_WIDTH - 960.0 / WORLD_ZOOM), minf(1, dt * 6))

func complete_level() -> void:
	mobile_controls.release_all()
	combat_director.reset()
	player.grapple.release()
	player.reset_running()
	player.velocity = Vector2.ZERO
	player.attack_time = 0
	player.attack_buffer = 0
	player.stun = 0
	player.thrown_time = 0
	player.getup_time = 0
	player.height = 0
	player.jump_speed = 0
	player.moving = false
	player.invincible = 0
	presentation_time = 0
	freeze = 0
	shake = 0
	show_help = false
	if level_index < LEVEL_COUNT - 1:
		state = "stage_clear"
		player.update_visual(0)
	else:
		state = "victory"
		# Bring the winner into view for the celebration, independent of stage edges.
		player.position.x = camera_x + 480.0 / WORLD_ZOOM
		player.position.y = START_Y
		player.facing = 1
		player.victory_time = 0
		player.update_visual(0)
	sound("power")

func update_presentation(dt: float) -> void:
	presentation_time += dt
	if state == "stage_clear" and presentation_time >= STAGE_CLEAR_DURATION:
		var remaining_health: float = player.hp
		level_index += 1
		load_level(remaining_health)
	elif state == "victory":
		player.victory_time = presentation_time
		player.update_visual(dt)
		player.queue_redraw()
		if presentation_time >= VICTORY_DURATION:
			finish("won")

func finish(result: String) -> void:
	state = result
	if score > best:
		best = score
		var save := ConfigFile.new()
		save.set_value("score", "best", best)
		save.save("user://record.cfg")
	ranking_panel.show_result(result, score, run_id)

func use_ultimate(actor: Node2D = null) -> void:
	if actor != null and actor != player:
		return
	if charge < 100 or ult_time > 0 or not player.can_use_ultimate():
		return
	player.grapple.release()
	player.reset_running()
	player.velocity = Vector2.ZERO
	combat_director.reset()
	charge = 0
	ult_time = 1.6
	ult_applied = false
	player.ultimate_pose = 1.6
	player.attack_time = 0
	player.attack_buffer = 0
	player.stun = 0
	player.moving = false
	player.invincible = 2.1
	player.update_visual(0)
	sound("power")

func impact(at: Vector2, direction: float, heavy: bool) -> void:
	freeze = 0.065 if heavy else 0.035
	shake = 7 if heavy else 3
	for i in range(12 if heavy else 7):
		particles.append({"pos": at, "vel": Vector2(randf_range(-110, 150) * direction, randf_range(-180, 30)), "life": randf_range(0.15, 0.4), "color": Color("ffe5a1"), "size": randf_range(2, 5)})

func dust(at: Vector2) -> void:
	for i in range(6):
		particles.append({"pos": at, "vel": Vector2(randf_range(-65, 65), randf_range(-25, -4)), "life": 0.25, "color": Color("8e849e"), "size": 3.0})

func rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color)

func label_at(value: String, at: Vector2, size := 16, color := CREAM) -> void:
	draw_string(font, at.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, ArcadeUI.font_size(size), color)

func centered(value: String, y: float, size: int, color := CREAM) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, ArcadeUI.font_size(size)).x
	label_at(value, Vector2((960 - width) / 2, y), size, color)

func _draw() -> void:
	draw_city()
	get_node("Overlay").queue_redraw()

func draw_city() -> void:
	rect(0, 0, 960, VIEW_HEIGHT, Color("151b29"))
	draw_set_transform(world.position, 0, Vector2.ONE * WORLD_ZOOM)
	var tile_width := 492.0
	var first := floori((camera_x + 80) / tile_width) - 1
	var last := ceili((camera_x + 960.0 / WORLD_ZOOM + 80) / tile_width)
	for i in range(first, last + 1):
		var x := -80.0 + i * tile_width
		# Keep facades at their original scale; widen only the paving section.
		draw_texture_rect_region(PIXEL_STREET, Rect2(x, 99, tile_width, 240), Rect2(0, 0, 1536, 748))
		draw_texture_rect_region(PIXEL_STREET, Rect2(x, FLOOR_BACK_Y, tile_width, CURB_TOP_Y - FLOOR_BACK_Y), Rect2(0, 748, 1536, 182))
		draw_texture_rect_region(PIXEL_STREET, Rect2(x, CURB_TOP_Y, tile_width, CURB_BOTTOM_Y - CURB_TOP_Y), Rect2(0, 930, 1536, 34))
		# Repeat an interior asphalt patch, excluding the curb seam.
		for strip in range(14):
			draw_texture_rect_region(PIXEL_STREET, Rect2(x, CURB_BOTTOM_Y + strip * 13, tile_width, 13), Rect2(0, 984, 1536, 40))
		draw_street_litter(x, i)
		# Expansion joint hides the material change at horizontal strip seams.
		rect(x - 2, 99, 5, 240, Color("171d28"))
		rect(x, 99, 1, 240, Color("4c4d52"))
		for bracket in range(8):
			rect(x - 3, 118 + bracket * 28, 7, 2, Color("282c35"))
		label_at("GROOVA", Vector2(x + 361, 193), 20, Color("dfb179"))
	if enemies.filter(func(e): return not e.dead).size() > 0:
		var visible_width := 960.0 / WORLD_ZOOM
		if right_bound >= camera_x and right_bound < camera_x + visible_width:
			for j in range(4):
				rect(right_bound, 409 + j * 6, 1, 3, Color("e17e8a"))
	draw_set_transform(Vector2.ZERO)

func draw_street_litter(tile_x: float, tile_index: int) -> void:
	# Fixed positions keep decoration stable while scrolling and consume no RNG.
	var shift := float(posmod(tile_index * 37, 61))
	for at in [Vector2(tile_x + 72 + shift, 363), Vector2(tile_x + 314 - shift, 416), Vector2(tile_x + 441, 444)]:
		# Crushed, empty beer can: shadow, dented body, label and open rim.
		rect(at.x - 1, at.y + 5, 11, 2, Color("20232b"))
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(7, -1), at + Vector2(9, 2), at + Vector2(7, 6), at + Vector2(1, 5)]), Color("a8aaa0"))
		rect(at.x + 2, at.y + 1, 5, 3, Color("63804b"))
		rect(at.x + 3, at.y + 2, 3, 1, Color("d3bf80"))
		rect(at.x, at.y, 2, 4, Color("d0d1c3"))
		rect(at.x + 1, at.y + 1, 1, 2, Color("33383c"))
	for at in [Vector2(tile_x + 198 - shift, 378), Vector2(tile_x + 371 + shift, 430)]:
		# Uneven newsprint, folded corner, headline, picture and text columns.
		draw_colored_polygon(PackedVector2Array([at + Vector2(1, 1), at + Vector2(18, -1), at + Vector2(20, 10), at + Vector2(3, 13)]), Color("27282d"))
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(17, -2), at + Vector2(19, 9), at + Vector2(2, 12)]), Color("bcb9a0"))
		rect(at.x + 3, at.y + 1, 12, 2, Color("515354"))
		rect(at.x + 4, at.y + 5, 4, 4, Color("7e8075"))
		for line in range(3):
			rect(at.x + 10, at.y + 5 + line * 2, 6, 1, Color("72736a"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(14, -1), at + Vector2(17, -2), at + Vector2(18, 2)]), Color("e0d9ba"))

func neon_sign(x: float, y: float, words: String, color: Color, size: int) -> void:
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, ArcadeUI.font_size(size)).x
	rect(x - 12, y - size - 9, width + 24, size + 21, Color("181d30"))
	draw_rect(Rect2(x - 9, y - size - 6, width + 18, size + 15), Color(color, 0.35), false, 2)
	label_at(words, Vector2(x + 2, y + 2), size, Color(color, 0.22))
	label_at(words, Vector2(x, y), size, color)

func draw_overlay() -> void:
	var canvas: Node2D = get_node("Overlay")
	for p in particles:
		canvas.draw_rect(Rect2(world_to_screen(p.pos), Vector2.ONE * p.size * WORLD_ZOOM), p.color)
	if ult_time > 0:
		canvas.draw_rect(Rect2(0, 0, 960, VIEW_HEIGHT), Color(0.015, 0.02, 0.08, 0.72))
		var center: Vector2 = world_to_screen(player.position - Vector2(0, 45 + player.height))
		canvas.draw_circle(center, (85 + sin(time * 30) * 8) * WORLD_ZOOM, Color(0.3, 1, 0.9, 0.10))
		canvas.draw_arc(center, (1.6 - ult_time) * 600 * WORLD_ZOOM, 0, TAU, 96, MINT, 5)
		# Draw the posed hero above the darkened scene.
		player.z_index = 1001
		overlay_text(canvas, "G R O O V A   B R E A K", Vector2(235, 172), 32, MINT)
	else:
		player.z_index = int(player.position.y)
	draw_hud(canvas)
	if state == "play":
		if not debug_room and banner_time > 0 and player.height < 10 and not enemies.any(func(e): return not e.dead and e.height > 10):
			overlay_text(canvas, ("%02d / EL JEFE DEL BARRIO" % WAVE_COUNT if stage == WAVE_COUNT - 1 else "%02d / EL DISTRITO NEON" % (stage + 1)), Vector2(300, 127), 21, CREAM)
		if transition > 0 and stage < WAVE_COUNT - 1:
			overlay_text(canvas, "AVANZA  >>", Vector2(740, 267), 22, MINT)
		if combo_hits > 1:
			overlay_text(canvas, "%02d HITS" % combo_hits, Vector2(779, 164), 27, Color("ffc785"))
		if respawn_time > 0:
			overlay_text(canvas, "LEVANTATE. LA NOCHE SIGUE.", Vector2(273, 253), 24, CREAM)
	if state in ["stage_clear", "victory"]:
		draw_stage_presentation(canvas)
	if state in ["title", "pause", "over", "won"] or show_help:
		canvas.draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.025, 0.035, 0.08, 0.90))
		canvas.draw_set_transform(Vector2(0, (VIEW_HEIGHT - 540.0) / 2))
		if state == "title":
			var logo_scale := minf(360.0 / START_LOGO.get_width(), 190.0 / START_LOGO.get_height())
			var logo_size := START_LOGO.get_size() * logo_scale
			canvas.draw_texture_rect(START_LOGO, Rect2(Vector2((960 - logo_size.x) / 2, 8), logo_size), false)
			overlay_centered(canvas, "TRES NIVELES. QUINCE OLEADAS. UNA NOCHE.", 199, 16, MINT)
			overlay_centered(canvas, "STREET GROOVA", 258, 60, Color("f187a5"))
			overlay_centered(canvas, "EPISODIO 01 / LA ULTIMA NOCHE", 292, 16, MINT)
			draw_controls(canvas, 340)
			overlay_text(canvas, "TOCA PARA JUGAR" if touch_visible else "ENTER / A / CLIC PARA JUGAR", Vector2(320, 483), 21, CREAM if sin(time * 4) > -0.4 else Color("818799"))
		elif state == "pause" or show_help:
			overlay_text(canvas, "PAUSA" if not show_help else "COMO JUGAR", Vector2(335, 173), 48, MINT)
			draw_controls(canvas, 240)
			overlay_text(canvas, "TOCA SEGUIR PARA VOLVER" if touch_visible else "ESC / START para seguir   -   H cierra ayuda", Vector2(261, 424), 18, CREAM)
		else:
			overlay_text(canvas, "CONGRATULATIONS!" if state == "won" else "FIN DE LA RONDA", Vector2(220, 197), 46, MINT if state == "won" else Color("f187a5"))
			overlay_text(canvas, "La noche vuelve a tener ritmo." if state == "won" else "Una caida mas. Una revancha mas.", Vector2(316, 246), 20, CREAM)
			overlay_text(canvas, "PUNTOS  %06d     RECORD  %06d" % [score, best], Vector2(272, 307), 22, Color("ffc785"))
			overlay_text(canvas, "ENTER / A / CLIC PARA REINTENTAR", Vector2(283, 402), 22, CREAM)

		canvas.draw_set_transform(Vector2.ZERO)

func draw_stage_presentation(canvas: Node2D) -> void:
	var final := state == "victory"
	var top := 155.0 if final else 205.0
	canvas.draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.025, 0.035, 0.08, 0.42))
	canvas.draw_rect(Rect2(62, top, 836, 225), Color("101322"))
	canvas.draw_rect(Rect2(70, top + 8, 820, 209), MINT, false, 3)
	canvas.draw_line(Vector2(90, top + 49), Vector2(870, top + 49), Color("3b5660"), 2)
	overlay_centered(canvas, "STREET GROOVA / ALL STAGES CLEAR" if final else "STREET GROOVA / NIVEL %02d" % (level_index + 1), top + 34, 17, Color("f7c47e"))
	var color := MINT if sin(presentation_time * 8) > -0.5 else Color("f7c47e")
	overlay_centered(canvas, "CONGRATULATIONS!" if final else "STAGE CLEAR", top + 112, 65 if final else 76, color)
	overlay_centered(canvas, "LOS TRES NIVELES COMPLETADOS" if final else "PREPARATE PARA EL NIVEL %02d" % (level_index + 2), top + 157, 20, CREAM)
	overlay_centered(canvas, "PUNTOS  %06d" % score if final else "SIGUIENTE NIVEL EN %d" % maxi(1, ceili(STAGE_CLEAR_DURATION - presentation_time)), top + 192, 18, Color("f7c47e"))
	for i in range(18):
		var x := 90.0 + i * 46
		var glow := MINT if (i + int(presentation_time * 8)) % 3 == 0 else Color("34434e")
		canvas.draw_rect(Rect2(x, top - 8, 9, 4), glow)
		canvas.draw_rect(Rect2(x, top + 229, 9, 4), glow)
	if final:
		for i in range(44):
			var x := fposmod(i * 137.0 + sin(presentation_time * 2 + i) * 18, 940) + 10
			var y := fposmod(i * 71.0 + presentation_time * (42 + i % 4 * 12), VIEW_HEIGHT - 110) + 100
			var colors := [MINT, Color("f7c47e"), Color("f187a5")]
			canvas.draw_rect(Rect2(x, y, 4 if i % 2 else 7, 5), colors[i % 3])

func overlay_text(canvas: Node2D, value: String, at: Vector2, size: int, color: Color) -> void:
	var pixels := ArcadeUI.font_size(size)
	canvas.draw_string(font, at.round() + Vector2(2, 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, INK)
	canvas.draw_string(font, at.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)

func overlay_centered(canvas: Node2D, value: String, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, ArcadeUI.font_size(size)).x
	overlay_text(canvas, value, Vector2((960 - width) / 2, y), size, color)

func draw_controls(canvas: Node2D, y: float) -> void:
	if touch_visible:
		var mobile_lines := ["PALANCA IZQUIERDA: MOVER EN TODAS LAS DIRECCIONES", "DOBLE TOQUE Y MANTENER: CORRER", "PEGAR / SALTAR / ULTI: BOTONES A LA DERECHA", "CORRER + PEGAR: DESLIZANTE | SALTAR + PEGAR: PATADA", "AGARRE: PEGAR O PALANCA ATRAS + PEGAR PARA LANZAR", "PAUSA / SEGUIR: BOTON CENTRAL"]
		for i in range(mobile_lines.size()):
			overlay_text(canvas, mobile_lines[i], Vector2(190, y + i * 23), 14, CREAM)
		return
	var lines := ["WASD / FLECHAS mover | doble toque + mantener: correr", "J / Z combo | corriendo + J / Z: golpe deslizante", "ESPACIO / K salto | aire + J patada | L / X ulti", "Pegado al rival: agarre   |   J golpe   |   atras + J lanzar", "MANDO: stick / cruceta   |   X golpe   A salto   Y ulti", "ESC pausa    H ayuda    M sonido   |   Busca pollo en cajas y barriles"]
	for i in range(lines.size()):
		overlay_text(canvas, lines[i], Vector2(219 if i < 4 else 190, y + i * 23), 16 if i < 4 else 14, CREAM if i < 3 else Color("98a3b9"))

func draw_hud(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(0, 0, 960, 92), Color(0.04, 0.06, 0.12, 0.95))
	canvas.draw_line(Vector2(24, 91), Vector2(936, 91), Color("3b4059"), 1)
	canvas.draw_rect(Rect2(24, 19, 47, 51), Color("2c4b58"))
	overlay_text(canvas, "G", Vector2(34, 58), 34, MINT)
	overlay_text(canvas, str(character_pack["display_name"]).to_upper() + " / 1P", Vector2(85, 28), 16, CREAM)
	canvas.draw_rect(Rect2(85, 36, 264, 16), Color("393044"))
	canvas.draw_rect(Rect2(87, 38, 260 * player.hp / player.max_hp, 12), MINT if player.hp > 30 else Color("f187a5"))
	overlay_text(canvas, "%03d / 100" % int(player.hp), Vector2(360, 50), 14, CREAM)
	for i in range(3):
		var life_color := Color("f187a5") if i < lives else Color("34374c")
		for row in range(LIFE_PIXELS.size()):
			for col in range(LIFE_PIXELS[row].length()):
				if LIFE_PIXELS[row][col] == "1":
					canvas.draw_rect(Rect2(85 + i * 20 + col * 2, 62 + row * 2, 2, 2), life_color)
	overlay_text(canvas, "VIDAS", Vector2(151, 74), 11, Color("98a3b9"))
	overlay_text(canvas, "GROOVA BREAK", Vector2(474, 28), 14, MINT)
	canvas.draw_rect(Rect2(474, 36, 192, 14), Color("30344c"))
	canvas.draw_rect(Rect2(476, 38, 188 * charge / 100, 10), Color("f7c47e") if charge < 100 else MINT)
	overlay_text(canvas, "L / Y  LISTA!" if charge >= 100 else "SE CARGA AL PEGAR Y RECIBIR", Vector2(474, 70), 11, MINT if charge >= 100 else Color("98a3b9"))
	overlay_text(canvas, "%06d" % score, Vector2(778, 38), 29, CREAM)
	var remaining := enemies.filter(func(e): return not e.dead).size()
	overlay_text(canvas, ("DEBUG / %d RIVALES" % remaining) if debug_room else ("N%d/%d OLEADA %d/%d  %d RIVALES" % [level_index + 1, LEVEL_COUNT, stage + 1, WAVE_COUNT, remaining]), Vector2(743, 69), 12, Color("98a3b9"))
	for enemy in enemies:
		if enemy.is_boss and not enemy.dead and state == "play":
			canvas.draw_rect(Rect2(270, 102, 420, 20), Color("241b2c"))
			canvas.draw_rect(Rect2(272, 104, 416 * enemy.hp / enemy.max_hp, 16), Color("d45c79"))
			overlay_centered(canvas, "JEFE DEL BARRIO  %d / %d" % [enemy.hp, enemy.max_hp], 115, 12, CREAM)
	if not touch_visible and state == "play":
		canvas.draw_rect(Rect2(0, VIEW_HEIGHT - 26, 960, 26), Color(0.04, 0.06, 0.12, 0.94))
		overlay_text(canvas, "J GOLPE / CORRIENDO: DESLIZANTE   ESPACIO SALTO   L ULTI", Vector2(24, VIEW_HEIGHT - 16), 12, CREAM)
		overlay_text(canvas, "H AYUDA / ESC PAUSA / M SONIDO", Vector2(669, VIEW_HEIGHT - 16), 11, CREAM)

func setup_audio() -> void:
	for i in range(8):
		var audio := AudioStreamPlayer.new()
		audio.volume_db = -15
		add_child(audio)
		audio_players.append(audio)
	for sound_name in ["hit", "swing", "jump", "power", "ultimate"]:
		sounds[sound_name] = synth_sound(sound_name)
	music = AudioStreamPlayer.new()
	music.volume_db = -23
	add_child(music)
	music.stream = synth_music()
	music.play()

func _exit_tree() -> void:
	CharacterCatalog.cache.clear()
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for audio in audio_players:
		if is_instance_valid(audio):
			audio.stop()
			audio.stream = null
	sounds.clear()

func sound(which: String) -> void:
	for audio in audio_players:
		if not audio.playing:
			audio.stream = sounds[which]
			audio.play()
			return

func synth_sound(which: String) -> AudioStreamWAV:
	var duration := 0.13
	if which in ["power", "ultimate"]:
		duration = 0.7
	var samples := PackedByteArray()
	var count := int(duration * 22050)
	samples.resize(count * 2)
	for i in range(count):
		var t := float(i) / 22050
		var fade := 1.0 - float(i) / count
		var hz := 120.0
		var value := 0.0
		match which:
			"hit": value = (randf_range(-1, 1) * 0.6 + sin(t * 95 * TAU) * 0.4) * fade * fade
			"swing": value = randf_range(-1, 1) * fade * 0.3
			"jump":
				hz = 180 + t * 1500
				value = sin(t * hz * TAU) * fade * 0.6
			"power": value = sin(t * (150 + t * 450) * TAU) * fade * 0.5
			"ultimate": value = (sin(t * 60 * TAU) + randf_range(-0.4, 0.4)) * fade * 0.7
		samples.encode_s16(i * 2, int(clampf(value, -1, 1) * 26000))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = samples
	return wav

func synth_music() -> AudioStreamWAV:
	var rate := 22050
	var beat := 0.48
	var duration := beat * 32
	var count := int(duration * rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	var notes := [55.0, 55.0, 65.406, 73.416, 55.0, 82.407, 73.416, 65.406]
	for i in range(count):
		var t := float(i) / rate
		var step := int(t / (beat / 2))
		var phase := fmod(t, beat / 2)
		var frequency: float = notes[(step / 2) % notes.size()]
		var bass := sin(t * frequency * TAU) * exp(-phase * 11) * 0.36
		var kick_t := fmod(t, beat)
		var kick := sin(kick_t * (53 + 70 * exp(-kick_t * 35)) * TAU) * exp(-kick_t * 23) * 0.55
		var snare := randf_range(-1, 1) * exp(-kick_t * 27) * 0.17 if int(t / beat) % 2 == 1 else 0.0
		var hat := randf_range(-1, 1) * exp(-phase * 100) * 0.11
		var melody := sin(t * frequency * 8 * TAU) * exp(-phase * 18) * 0.065
		data.encode_s16(i * 2, int(clampf(bass + kick + snare + hat + melody, -1, 1) * 27000))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = count
	return wav
