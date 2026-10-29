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

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var run_id: String = game.run_id
	game._input(key(KEY_ENTER))
	check(game.state == "select" and game.character_select.open, "press start opens character select")
	check(game.run_id == run_id, "opening select does not start a run")
	check(game.character_select.cards.size() == 3, "selection has three portrait cards")
	var supplied_portrait: Texture2D = load("res://assets/characters/beto/portraits/portrait.png")
	for i in range(3):
		check(Catalog.character_for_slot(i)["id"] == "beto", "placeholder slot %d resolves to Beto" % i)
		check(game.character_select.cards[i].get_node("Portrait").texture == supplied_portrait, "slot %d shows supplied portrait instead of idle crop" % i)
	game._input(key(KEY_LEFT))
	check(game.character_select.selected == 2, "left navigation wraps to last card")
	game._input(key(KEY_RIGHT))
	check(game.character_select.selected == 0, "right navigation wraps to first card")
	game._input(key(KEY_RIGHT, true))
	check(game.character_select.selected == 0, "key repeat cannot accidentally skip portraits")
	game._input(key(KEY_D))
	check(game.character_select.selected == 1, "WASD can change selection")
	game._input(key(KEY_ENTER))
	check(game.state == "play" and not game.character_select.open and game.active_character_id == "beto", "enter confirms and starts chosen character")
	check(game.player.visual.sheets["idle"] == Catalog.character("beto")["sheets"]["idle"], "player receives selected character's sprites")
	for i in range(3):
		game.show_character_selection()
		game.character_select.cards[i].pressed.emit()
		check(game.state == "select" and game.character_select.selected == i, "click selects card without starting run")
		game.confirm_character(i)
		check(game.active_character_id == "beto" and game.player.visual.motion == "idle", "each placeholder is playable as Beto")
	game.show_character_selection()
	game._input(key(KEY_ESCAPE))
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
	check(game.state == "play", "gamepad A confirms selection")
	# Enable a complete alternative pack in memory; production files stay intact.
	var original_roster: Dictionary = Catalog.roster.duplicate(true)
	var test_roster: Dictionary = original_roster.duplicate(true)
	test_roster["characters"][1]["enabled"] = true
	test_roster["characters"][1]["definition"] = "res://tests/fixtures/alito.json"
	Catalog.roster = test_roster
	Catalog.cache.clear()
	game.confirm_character(1)
	check(game.active_character_id == "alito" and game.character_pack["display_name"] == "Alito", "enabled slot resolves its own manifest")
	check(game.player.visual.sheets["idle"] != Catalog.character("beto")["sheets"]["idle"], "different character loads different sprite texture")
	check(is_equal_approx(game.player.visual.duration("attack_01"), 0.6), "selected character controls its own animation timing")
	check(is_equal_approx(float(game.player.visual.character_data["scale"]), 0.75), "selected character controls its own scale")
	check(Catalog.load_pack("res://assets/characters/cami/character.json").is_empty(), "incomplete pack is rejected without crashing")
	Catalog.roster = original_roster
	Catalog.cache.clear()
	print("ALL ", checks, " SELECTION CHECKS PASSED")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
