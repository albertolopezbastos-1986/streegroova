extends Node2D

const Fighter = preload("res://scripts/fighter.gd")
const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const START_LOGO: Texture2D = preload("res://assets/branding/groovaipa-logo.png")
const INK = Color("101322")
const CREAM = Color("f5e9d0")
const MINT = Color("62efd4")
var player: Node2D
var enemies: Array = []
var particles: Array = []
var state := "title"
var previous_state := "play"
var score := 0
var lives := 3
var charge := 0.0
var combo_hits := 0
var combo_timer := 0.0
var stage := 0
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
var touch_visible := false
var touches: Dictionary = {}
var sounds: Dictionary = {}
var audio_players: Array = []
var music: AudioStreamPlayer
var muted := false
var best := 0
var font: Font
var world: Node2D
var online_scores: Node
var ranking_panel: CanvasLayer
var run_id := ""
var show_help := false
var touch_buttons := {"left": Vector2(55, 438), "right": Vector2(159, 438), "up": Vector2(107, 388), "down": Vector2(107, 487), "jump": Vector2(790, 455), "attack": Vector2(886, 416), "ultimate": Vector2(875, 499)}

func _ready() -> void:
	RenderingServer.set_default_clear_color(INK)
	font = ArcadeUI.FONT
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	setup_inputs()
	setup_audio()
	var save := ConfigFile.new()
	if save.load("user://record.cfg") == OK:
		best = save.get_value("score", "best", 0)
	world = Node2D.new()
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
	ranking_panel.replay_requested.connect(new_run)
	new_run()
	state = "title"

func setup_inputs() -> void:
	var keys := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE, KEY_K], "attack": [KEY_J, KEY_Z], "ultimate": [KEY_L, KEY_X], "pause_game": [KEY_ESCAPE, KEY_P], "start": [KEY_ENTER], "help": [KEY_H], "mute": [KEY_M]}
	for action in keys:
		InputMap.add_action(action)
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

func new_run() -> void:
	ranking_panel.reset_run()
	run_id = online_scores.new_run_id()
	show_help = false
	for child in world.get_children():
		child.queue_free()
	enemies.clear()
	particles.clear()
	score = 0
	lives = 3
	charge = 0
	stage = 0
	camera_x = 0
	left_bound = 30
	right_bound = 850
	ult_time = 0
	respawn_time = 0
	transition = 0
	combo_hits = 0
	player = Fighter.new()
	world.add_child(player)
	player.setup(self, -1, Vector2(165, 407))
	player.invincible = 1.5
	spawn_wave()
	state = "play"

func spawn_wave() -> void:
	var waves := [[0, 0, 1], [1, 0, 2, 1], [2, 0, 1, 2, 0]]
	for i in range(waves[stage].size()):
		var enemy = Fighter.new()
		world.add_child(enemy)
		var x := minf(right_bound - 45, left_bound + 590 + i * 48)
		enemy.setup(self, waves[stage][i], Vector2(x, 350 + (i % 3) * 47))
		enemies.append(enemy)
	banner_time = 3

func _input(event: InputEvent) -> void:
	if ranking_panel.open:
		return
	if state == "title":
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
			ranking_panel.show_ranking()
			return
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if ranking_panel.entry_button.get_global_rect().has_point(event.position):
				return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_visible = true
		if event is InputEventScreenTouch and not event.pressed:
			touches.erase(event.index)
		else:
			touches[event.index] = event.position
		for action in touch_buttons:
			var pressed := false
			for point in touches.values():
				if point.distance_to(touch_buttons[action]) < 34:
					pressed = true
			if pressed:
				Input.action_press(action)
			else:
				Input.action_release(action)
		if event is InputEventScreenTouch and event.pressed and state in ["title", "over", "won"]:
			new_run()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state in ["title", "over", "won"]:
			new_run()
	if event.is_action_pressed("mute"):
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
	if event.is_action_pressed("help"):
		show_help = not show_help
	if event.is_action_pressed("start") or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
		if state in ["title", "over", "won"]:
			new_run()
	if event.is_action_pressed("pause_game"):
		if state == "pause":
			state = previous_state
		elif state == "play":
			previous_state = state
			state = "pause"

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play":
		state = "pause"
		previous_state = "play"
		touches.clear()
		for action in touch_buttons:
			Input.action_release(action)

func _process(dt: float) -> void:
	time += dt
	ranking_panel.entry_button.visible = state == "title" and not ranking_panel.open
	if state == "play" and not show_help:
		update_game(minf(dt, 0.04))
	if state != "pause":
		for p in particles:
			p.life -= dt
			p.pos += p.vel * dt
			p.vel.y += dt * 220
		particles = particles.filter(func(p): return p.life > 0)
	shake = maxf(0, shake - dt * 30)
	var offset := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	world.position = Vector2(-camera_x, 0) + offset
	queue_redraw()

func update_game(dt: float) -> void:
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
		return
	player.tick(dt)
	for enemy in enemies:
		enemy.tick(dt)
	if player.dead:
		respawn_time += dt
		if respawn_time > 1.4:
			lives -= 1
			respawn_time = 0
			if lives <= 0:
				finish("over")
			else:
				player.dead = false
				player.death_time = 0
				player.hp = player.max_hp
				player.height = 0
				player.jump_speed = 0
				player.invincible = 2.5
				player.position.x = maxf(left_bound + 80, player.position.x)
		return
	var alive := enemies.filter(func(e): return not e.dead).size()
	if alive == 0:
		transition += dt
		if stage == 2 and transition > 2:
			finish("won")
		elif stage < 2:
			right_bound = (stage + 2) * 850.0
			if player.position.x > (stage + 1) * 850 + 80:
				stage += 1
				left_bound = stage * 850.0
				transition = 0
				player.hp = minf(player.max_hp, player.hp + 25)
				spawn_wave()
	camera_x = lerpf(camera_x, clampf(player.position.x - 310, 0, 2550 - 960), minf(1, dt * 6))

func finish(result: String) -> void:
	state = result
	if score > best:
		best = score
		var save := ConfigFile.new()
		save.set_value("score", "best", best)
		save.save("user://record.cfg")
	ranking_panel.show_result(result, score, run_id)

func use_ultimate() -> void:
	if charge < 100 or ult_time > 0 or player.dead:
		return
	charge = 0
	ult_time = 1.6
	ult_applied = false
	player.ultimate_pose = 1.6
	player.attack_time = 0
	player.invincible = 2.1
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
	rect(0, 0, 960, 540, Color("12182c"))
	draw_circle(Vector2(752 - camera_x * 0.04, 113), 46, Color("e9baad"))
	draw_circle(Vector2(735 - camera_x * 0.04, 100), 44, Color("12182c"))
	for i in range(18):
		var bx := i * 91.0 - fmod(camera_x * 0.18, 91)
		var bh := 80 + (i * 73 % 117)
		rect(bx, 270 - bh, 73, bh, Color("1c2440"))
		for row in range(7):
			for col in range(4):
				if (row * 7 + col * 3 + i) % 4 != 0:
					rect(bx + 9 + col * 16, 282 - bh + row * 22, 5, 8, Color("3b425e"))
	for i in range(10):
		var x := i * 300.0 - camera_x * 0.82 - 150
		if x < -350 or x > 1000:
			continue
		var palette := [Color("30304a"), Color("292b43"), Color("343047")]
		rect(x, 139, 296, 192, palette[i % 3])
		rect(x, 139, 296, 8, Color("4b435b"))
		for row in range(6):
			for col in range(8):
				rect(x + col * 40 + (20 if row % 2 else 0), 153 + row * 26, 33, 2, Color("3d354f"))
		for j in range(3):
			var wx := x + 25 + j * 88
			rect(wx, 167, 54, 70, Color("161c30"))
			rect(wx + 4, 171, 21, 58, Color("4d5368") if (i + j) % 3 else Color("ad866e"))
			rect(wx + 29, 171, 20, 58, Color("29364c"))
			rect(wx - 3, 234, 60, 5, Color("63566b"))
		rect(x + 16, 257, 261, 74, Color("181e30"))
		for slat in range(10):
			rect(x + 20, 260 + slat * 7, 254, 2, Color("34354d"))
		if i % 3 == 0:
			neon_sign(x + 22, 246, "GROOVA", Color("ed7c9c"), 28)
		elif i % 3 == 1:
			neon_sign(x + 40, 252, "24 / RAMEN", MINT, 21)
		else:
			neon_sign(x + 37, 252, "NIGHT RECORDS", Color("ddbf82"), 19)
		# Fire escape.
		rect(x + 220, 160, 5, 159, Color("151b2a"))
		rect(x + 269, 160, 5, 159, Color("151b2a"))
		for rung in range(11):
			rect(x + 220, 165 + rung * 14, 54, 3, Color("1b2131"))
	rect(0, 328, 960, 23, Color("676078"))
	rect(0, 347, 960, 9, Color("292a40"))
	rect(0, 356, 960, 143, Color("343549"))
	rect(0, 499, 960, 41, Color("252a3e"))
	for i in range(34):
		var px := fposmod(i * 113.0 - camera_x, 1050) - 30
		var py := 370 + (i * 43 % 118)
		rect(px, py, 24 + i % 30, 2, Color("424257"))
		if i % 4 == 0:
			rect(px, py + 6, 48, 3, Color("51445f"))
	for i in range(12):
		var px := i * 240.0 - camera_x
		rect(px, 515, 98, 4, Color("9c8d88"))
	for i in range(6):
		var px := i * 475.0 + 275 - camera_x
		rect(px, 183, 7, 166, Color("101b2b"))
		rect(px - 30, 179, 42, 6, Color("152034"))
		draw_circle(Vector2(px - 25, 191), 18, Color(1, 0.79, 0.52, 0.07))
		rect(px - 35, 184, 22, 5, Color("ffdfa0"))
		# Bin, pavement litter and glowing wet reflections.
		rect(px + 39, 306, 33, 39, Color("253f49"))
		rect(px + 35, 301, 41, 7, Color("537074"))
		for line in range(3):
			rect(px + 44 + line * 9, 313, 3, 25, Color("36515a"))
		rect(px - 51, 390, 62, 3, Color("77586d"))
		rect(px - 33, 397, 32, 2, Color("8c6474"))
		rect(px + 96, 365, 12, 5, Color("b0a5a1"))
	if enemies.filter(func(e): return not e.dead).size() > 0:
		var edge := right_bound - camera_x
		if edge < 960:
			for j in range(4):
				draw_line(Vector2(edge, 338 + j * 36), Vector2(edge, 358 + j * 36), Color("e17e8a"), 3)

func neon_sign(x: float, y: float, words: String, color: Color, size: int) -> void:
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, ArcadeUI.font_size(size)).x
	rect(x - 12, y - size - 9, width + 24, size + 21, Color("181d30"))
	draw_rect(Rect2(x - 9, y - size - 6, width + 18, size + 15), Color(color, 0.35), false, 2)
	label_at(words, Vector2(x + 2, y + 2), size, Color(color, 0.22))
	label_at(words, Vector2(x, y), size, color)

func draw_overlay() -> void:
	var canvas: Node2D = get_node("Overlay")
	for p in particles:
		canvas.draw_rect(Rect2(p.pos - Vector2(camera_x, 0), Vector2.ONE * p.size), p.color)
	if ult_time > 0:
		canvas.draw_rect(Rect2(0, 0, 960, 540), Color(0.015, 0.02, 0.08, 0.72))
		var center: Vector2 = player.position - Vector2(camera_x, 45 + player.height)
		canvas.draw_circle(center, 85 + sin(time * 30) * 8, Color(0.3, 1, 0.9, 0.10))
		canvas.draw_arc(center, (1.6 - ult_time) * 600, 0, TAU, 96, MINT, 5)
		# Draw the posed hero above the darkened scene.
		player.z_index = 1001
		overlay_text(canvas, "G R O O V A   B R E A K", Vector2(235, 172), 32, MINT)
	else:
		player.z_index = int(player.position.y)
	draw_hud(canvas)
	if state == "play":
		if banner_time > 0:
			overlay_text(canvas, ["01 / EL DISTRITO NEON", "02 / CALLEJON DEL RITMO", "03 / ULTIMA RONDA"][stage], Vector2(300, 127), 21, CREAM)
		if transition > 0 and stage < 2:
			overlay_text(canvas, "AVANZA  >>", Vector2(740, 267), 22, MINT)
		if combo_hits > 1:
			overlay_text(canvas, "%02d HITS" % combo_hits, Vector2(779, 164), 27, Color("ffc785"))
		if respawn_time > 0:
			overlay_text(canvas, "LEVANTATE. LA NOCHE SIGUE.", Vector2(273, 253), 24, CREAM)
		if touch_visible:
			for action in touch_buttons:
				var point: Vector2 = touch_buttons[action]
				canvas.draw_circle(point, 29, Color(0.04, 0.07, 0.14, 0.65))
				canvas.draw_arc(point, 29, 0, TAU, 32, Color(MINT, 0.6), 2)
				var names := {"left": "<", "right": ">", "up": "^", "down": "v", "jump": "SALTO", "attack": "GOLPE", "ultimate": "ULTI"}
				overlay_text(canvas, names[action], point + Vector2(-20, 5), 12, CREAM)
	if state in ["title", "pause", "over", "won"] or show_help:
		canvas.draw_rect(Rect2(0, 0, 960, 540), Color(0.025, 0.035, 0.08, 0.90))
		if state == "title":
			var logo_scale := minf(360.0 / START_LOGO.get_width(), 190.0 / START_LOGO.get_height())
			var logo_size := START_LOGO.get_size() * logo_scale
			canvas.draw_texture_rect(START_LOGO, Rect2(Vector2((960 - logo_size.x) / 2, 8), logo_size), false)
			overlay_centered(canvas, "UN BARRIO. TRES RONDAS. CERO MARCHA ATRAS.", 199, 16, MINT)
			overlay_centered(canvas, "STREET GROOVA", 258, 60, Color("f187a5"))
			overlay_centered(canvas, "EPISODIO 01 / LA ULTIMA NOCHE", 292, 16, MINT)
			draw_controls(canvas, 340)
			overlay_text(canvas, "ENTER / A / CLIC PARA JUGAR", Vector2(320, 483), 21, CREAM if sin(time * 4) > -0.4 else Color("818799"))
		elif state == "pause" or show_help:
			overlay_text(canvas, "PAUSA" if not show_help else "COMO JUGAR", Vector2(335, 173), 48, MINT)
			draw_controls(canvas, 240)
			overlay_text(canvas, "ESC / START para seguir   -   H cierra ayuda", Vector2(261, 424), 18, CREAM)
		else:
			overlay_text(canvas, "BARRIO LIBERADO" if state == "won" else "FIN DE LA RONDA", Vector2(220, 197), 46, MINT if state == "won" else Color("f187a5"))
			overlay_text(canvas, "La noche vuelve a tener ritmo." if state == "won" else "Una caida mas. Una revancha mas.", Vector2(316, 246), 20, CREAM)
			overlay_text(canvas, "PUNTOS  %06d     RECORD  %06d" % [score, best], Vector2(272, 307), 22, Color("ffc785"))
			overlay_text(canvas, "ENTER / A / CLIC PARA REINTENTAR", Vector2(283, 402), 22, CREAM)

func overlay_text(canvas: Node2D, value: String, at: Vector2, size: int, color: Color) -> void:
	var pixels := ArcadeUI.font_size(size)
	canvas.draw_string(font, at.round() + Vector2(2, 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, INK)
	canvas.draw_string(font, at.round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)

func overlay_centered(canvas: Node2D, value: String, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, ArcadeUI.font_size(size)).x
	overlay_text(canvas, value, Vector2((960 - width) / 2, y), size, color)

func draw_controls(canvas: Node2D, y: float) -> void:
	var lines := ["WASD / FLECHAS   mover     J / Z   combo de 3 golpes", "ESPACIO / K   salto     direccion + salto   salto en avance", "En el aire + J   patada voladora     L / X   ulti cargada", "MANDO: stick / cruceta   |   X golpe   A salto   Y ulti", "ESC pausa    H ayuda    M sonido   |   Recuperas energia entre rondas"]
	for i in range(lines.size()):
		overlay_text(canvas, lines[i], Vector2(219 if i < 4 else 190, y + i * 23), 16 if i < 4 else 14, CREAM if i < 3 else Color("98a3b9"))

func draw_hud(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(0, 0, 960, 92), Color(0.04, 0.06, 0.12, 0.95))
	canvas.draw_line(Vector2(24, 91), Vector2(936, 91), Color("3b4059"), 1)
	canvas.draw_rect(Rect2(24, 19, 47, 51), Color("2c4b58"))
	overlay_text(canvas, "G", Vector2(34, 58), 34, MINT)
	overlay_text(canvas, "AXEL  /  1P", Vector2(85, 28), 16, CREAM)
	canvas.draw_rect(Rect2(85, 36, 264, 16), Color("393044"))
	canvas.draw_rect(Rect2(87, 38, 260 * player.hp / player.max_hp, 12), MINT if player.hp > 30 else Color("f187a5"))
	overlay_text(canvas, "%03d / 100" % int(player.hp), Vector2(360, 50), 14, CREAM)
	for i in range(3):
		canvas.draw_circle(Vector2(92 + i * 20, 69), 5, Color("f187a5") if i < lives else Color("34374c"))
	overlay_text(canvas, "VIDAS", Vector2(151, 74), 11, Color("98a3b9"))
	overlay_text(canvas, "GROOVA BREAK", Vector2(474, 28), 14, MINT)
	canvas.draw_rect(Rect2(474, 36, 192, 14), Color("30344c"))
	canvas.draw_rect(Rect2(476, 38, 188 * charge / 100, 10), Color("f7c47e") if charge < 100 else MINT)
	overlay_text(canvas, "L / Y  LISTA!" if charge >= 100 else "SE CARGA AL PEGAR Y RECIBIR", Vector2(474, 70), 11, MINT if charge >= 100 else Color("98a3b9"))
	overlay_text(canvas, "%06d" % score, Vector2(778, 38), 29, CREAM)
	var remaining := enemies.filter(func(e): return not e.dead).size()
	overlay_text(canvas, "RONDA %d/3   /   %d RIVALES" % [stage + 1, remaining], Vector2(743, 69), 12, Color("98a3b9"))
	if not touch_visible and state == "play":
		overlay_text(canvas, "J GOLPE    ESPACIO SALTO    L ULTI", Vector2(24, 524), 12, CREAM)
		overlay_text(canvas, "H AYUDA / ESC PAUSA / M SONIDO", Vector2(669, 524), 11, CREAM)

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
