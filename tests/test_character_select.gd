extends SceneTree

const Catalog = preload("res://scripts/character_catalog.gd")
var checks := 0

func check(value: bool, description: String) -> void:
	if not value:
		push_error("FAIL: " + description)
		quit(1)
		assert(value, description)
	checks += 1
	print("PASS: ", description)

func key(code: Key, repeated := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = repeated
	return event

func _initialize() -> void:
	call_deferred("run")

func finish_entrance(game) -> void:
	check(game.state == "fade_out", "selection fades out before starting")
	game.update_level_transition(game.FADE_DURATION * 0.5)
	check(game.fade_screen.color.a > 0 and game.fade_screen.color.a < 1, "fade passes through partial black")
	game.update_level_transition(game.FADE_DURATION)
	check(game.state == "black_hold" and game.fade_screen.color.a == 1, "level loads under full black")
	game.update_level_transition(0.9)
	check(game.state == "black_hold", "black screen waits a full second")
	game.update_level_transition(0.11)
	game.update_level_transition(game.FADE_DURATION)
	check(game.state == "entrance" and game.player.position.x < 0, "hero enters from outside the left edge")
	var enemy_position: Vector2 = game.enemies[0].position
	Input.action_press("left")
	Input.action_press("attack")
	game.update_level_transition(0.1)
	check(game.player.visual.motion == "walk" and game.player.position.x < game.entrance_target and game.player.attack_time == 0, "entrance walks automatically despite player input")
	Input.action_release("left")
	Input.action_release("attack")
	game.update_level_transition(5)
	check(game.state == "start" and game.player.position.x == game.entrance_target and game.enemies[0].position == enemy_position, "START waits for arrival while enemies stay frozen")
	game.update_level_transition(game.START_DURATION)
	check(game.state == "play" and game.fade_screen.color.a == 0, "control unlocks after START")

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var run_id: String = game.run_id
	game._input(key(KEY_ENTER))
	check(game.state == "title" and game.screen_transition_phase == "out", "title fades before selection appears")
	game.update_screen_transition(game.FADE_DURATION)
	game.update_screen_transition(game.BLACK_HOLD_DURATION)
	game.update_screen_transition(game.FADE_DURATION)
	check(game.state == "select" and game.character_select.open, "press start opens character select")
	check(game.run_id == run_id, "opening select does not start a run")
	check(game.character_select.cards.size() == 3, "selection has three portrait cards")
	var expected_ids := ["beto", "cami", "alito"]
	for i in range(3):
		check(Catalog.character_for_slot(i)["id"] == expected_ids[i], "slot %d resolves its character identity" % i)
		check(game.character_select.cards[i].get_node("Portrait").texture == Catalog.character_for_slot(i)["portrait"], "slot %d shows its character portrait" % i)
	game._input(key(KEY_LEFT))
	check(game.character_select.selected == 2, "left navigation wraps to last card")
	game._input(key(KEY_RIGHT))
	check(game.character_select.selected == 0, "right navigation wraps to first card")
	game._input(key(KEY_RIGHT, true))
	check(game.character_select.selected == 0, "key repeat cannot accidentally skip portraits")
	game._input(key(KEY_D))
	check(game.character_select.selected == 1, "WASD can change selection")
	game._input(key(KEY_ENTER))
	finish_entrance(game)
	check(game.state == "play" and not game.character_select.open and game.active_character_id == "cami", "enter confirms and starts chosen character")
	check(game.player.visual.sheets["idle"] == Catalog.character("cami")["sheets"]["idle"], "player receives selected character's sprites")
	for i in range(3):
		game.show_character_selection()
		game.character_select.cards[i].pressed.emit()
		check(game.state == "select" and game.character_select.selected == i, "click selects card without starting run")
		game.confirm_character(i)
		finish_entrance(game)
		check(game.active_character_id == expected_ids[i] and game.player.visual.motion == "idle", "each slot starts its selected character")
	game.show_character_selection()
	game._input(key(KEY_ESCAPE))
	game.update_screen_transition(game.FADE_DURATION)
	game.update_screen_transition(game.BLACK_HOLD_DURATION)
	game.update_screen_transition(game.FADE_DURATION)
	check(game.state == "title" and not game.character_select.open, "escape returns to title")
	game.show_character_selection()
	game.character_select.select(0)
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = 0.8
	game._input(stick)
	game._input(stick)
	check(game.character_select.selected == 1, "held stick only advances one card")
	stick.axis_value = 0
	game._input(stick)
	stick.axis_value = 0.8
	game._input(stick)
	check(game.character_select.selected == 2, "releasing and moving stick can select next card")
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	game._input(button)
	finish_entrance(game)
	check(game.state == "play", "gamepad A confirms selection")
	var alito: Dictionary = Catalog.character("alito")
	check(alito["definition"]["id"] == "alito", "Alito loads his own character definition")
	check(alito["definition"]["animations"]["idle"]["frame_indices"].size() == 41, "Alito idle uses 41 nonempty frames")
	for motion in alito["sheets"]:
		check(alito["sheets"][motion].resource_path.begins_with("res://assets/characters/alito/"), "Alito keeps his own appearance during " + motion)
	check(alito["definition"]["animations"]["walk"]["frame_indices"] == range(20), "Alito walk uses exactly frames 0 through 19")
	check(alito["sheets"]["walk"] != alito["sheets"]["idle"], "Alito walk has its own texture")
	game.player.moving = true
	game.player.update_visual(0.15)
	check(game.player.visual.motion == "walk" and game.player.visual.sheets["walk"] == alito["sheets"]["walk"], "selected Alito walks with his own animation")
	check(alito["definition"]["animations"]["run"]["frame_indices"] == range(5, 20), "Alito run uses frames 5 through penultimate drawn frame 19")
	game.player.running = true
	game.player.update_visual(0.05)
	check(game.player.visual.motion == "run" and game.player.visual.source_frame in range(5, 20), "Alito sprints with his dedicated run animation")
	check(alito["definition"]["animations"]["jump"]["frame_indices"] == range(2, 11), "Alito jump skips the first two and last two frames")
	game.player.running = false
	check(game.player.takeoff(Vector2.ZERO), "selected Alito can jump")
	var normal_peak := 1.0 + 420.0 * 420.0 / (2.0 * 950.0)
	var alito_peak: float = game.player.height + game.player.jump_speed * game.player.jump_speed / (2.0 * 950.0)
	check(is_equal_approx(alito_peak, normal_peak * 0.5), "Alito jumps exactly half as high")
	check(is_equal_approx(game.player.jump_duration, game.player.jump_speed * 2.0 / 950.0), "Alito jump animation follows the shorter flight duration")
	for progress in [0.0, 0.5, 0.99]:
		game.player.jump_elapsed = game.player.jump_duration * progress
		game.player.update_visual(0)
		check(game.player.visual.motion == "jump" and game.player.visual.sheets["jump"] == alito["sheets"]["jump"], "Alito uses his jump texture throughout the jump")
		check(game.player.visual.source_frame == 2 + mini(int(progress * 9), 8), "Alito jump frame follows physical jump progress")
	# Enable a complete alternative pack in memory; production files stay intact.
	var original_roster: Dictionary = Catalog.roster.duplicate(true)
	var test_roster: Dictionary = original_roster.duplicate(true)
	test_roster["characters"][2]["enabled"] = true
	test_roster["characters"][2]["definition"] = "res://tests/fixtures/alito.json"
	Catalog.roster = test_roster
	Catalog.cache.clear()
	game.show_character_selection()
	game.confirm_character(2)
	finish_entrance(game)
	check(game.active_character_id == "alito" and game.character_pack["display_name"] == "Alito", "enabled slot resolves its own manifest")
	check(game.player.visual.sheets["idle"] != Catalog.character("beto")["sheets"]["idle"], "different character loads different sprite texture")
	check(is_equal_approx(game.player.visual.duration("attack_01"), 0.6), "selected character controls its own animation timing")
	check(is_equal_approx(float(game.player.visual.character_data["scale"]), 0.75), "selected character controls its own scale")
	var cami: Dictionary = Catalog.load_pack("res://assets/characters/cami/character.json")
	check(not cami.is_empty(), "Cami pack loads with temporary action animations")
	var beto_data: Dictionary = Catalog.character("beto")["definition"]
	var beto_idle: Dictionary = beto_data["animations"]["idle"]
	var cami_data: Dictionary = cami["definition"]
	var beto_height := float(beto_idle["frame_size"][1]) * float(beto_idle.get("scale", beto_data["scale"]))
	var cami_height := float(cami_data["animations"]["idle"]["frame_size"][1]) * float(cami_data["scale"])
	check(is_equal_approx(cami_height, beto_height * 0.88), "Cami height follows Beto at 88 percent despite different sprite sizes")
	check(cami["sheets"]["idle"] != Catalog.character("beto")["sheets"]["idle"], "Cami uses her own idle texture")
	check(cami["definition"]["animations"]["walk"]["frame_indices"] == range(22), "Cami walk uses exactly frames 0 through 21")
	for motion in cami["sheets"]:
		check(cami["sheets"][motion].resource_path.begins_with("res://assets/characters/cami/"), "Cami keeps her own appearance during " + motion)
	game.character_pack = cami
	game.active_character_id = "cami"
	game.new_run()
	await process_frame
	game.player.moving = true
	game.player.update_visual(0.15)
	check(game.player.visual.motion == "walk" and game.player.visual.sheets["walk"] == cami["sheets"]["walk"], "Cami walks using her own animation in game")
	check(cami["definition"]["animations"]["run"]["frame_indices"] == range(11, 21), "Cami run uses frames 11 through 20")
	game.player.running = true
	game.player.update_visual(0.05)
	check(game.player.visual.motion == "run" and game.player.visual.source_frame in range(11, 21), "Cami sprints with her dedicated run animation")
	game.player.running = false
	check(cami["definition"]["animations"]["jump"]["frame_indices"] == range(21), "Cami jump uses all 21 nonempty frames")
	check(game.player.takeoff(Vector2.ZERO), "selected Cami can jump")
	for sample in [[0.0, 0], [0.5, 7], [0.9, 11], [0.98, 14], [0.99, 15]]:
		game.player.jump_elapsed = game.player.jump_duration * float(sample[0])
		game.player.update_visual(0)
		check(game.player.visual.motion == "jump" and game.player.visual.sheets["jump"] == cami["sheets"]["jump"], "Cami uses her own jump texture")
		check(game.player.visual.source_frame == int(sample[1]), "Cami holds airborne poses through descent and returns to idle near landing")
	Catalog.roster = original_roster
	Catalog.cache.clear()
	print("ALL ", checks, " SELECTION CHECKS PASSED")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
