extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func finish_fade(game) -> void:
	game.update_screen_transition(game.FADE_DURATION / 2)
	assert(game.fade_screen.color.a > 0 and game.fade_screen.color.a < 1)
	game.update_screen_transition(game.FADE_DURATION / 2)
	assert(game.fade_screen.color.a == 1 and game.screen_transition_phase == "hold")
	game.update_screen_transition(0.99)
	assert(game.screen_transition_phase == "hold" and game.fade_screen.color.a == 1)
	game.update_screen_transition(0.02)
	game.update_screen_transition(game.FADE_DURATION)
	assert(game.screen_transition_phase.is_empty() and game.fade_screen.color.a == 0)

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var offline = preload("res://tests/mock_online.gd").new()
	game.add_child(offline)
	game.ranking_panel.service = offline
	game.request_character_selection()
	assert(game.state == "title" and not game.character_select.open)
	finish_fade(game)
	assert(game.state == "select" and game.character_select.open)
	game.character_select.set_process(false)
	game.character_select._process(0.01)
	var border := game.character_select.cards[0].get_theme_stylebox("pressed") as StyleBoxFlat
	assert(border.border_color == Color.WHITE)
	game.character_select._process(0.2)
	assert(border.border_color == Color("62efd4"))
	for player in game.audio_players:
		player.stop()
	game.confirm_character(0)
	assert(game.state == "fade_out" and game.character_select.locked)
	assert(game.audio_players.any(func(player): return player.stream == game.sounds["select"] and player.playing))
	game.new_run()
	game.score = 12345
	var id: String = game.run_id
	game.level_index = 2
	game.complete_level()
	game.update_presentation(game.VICTORY_DURATION - 0.01)
	assert(game.state == "victory" and game.screen_transition_phase.is_empty())
	game.update_presentation(0.02)
	assert(game.screen_transition_target == "concert" and not game.ranking_panel.open)
	finish_fade(game)
	assert(game.state == "concert" and game.concert_layer.visible and not game.world.visible)
	assert(game.concert_layer.get_child(0).win_label.text == "YOU WIN!")
	game._process(3.99)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_ENTER
	press.pressed = true
	game._input(press)
	assert(game.screen_transition_phase.is_empty() and not game.ranking_panel.open)
	game._process(0.02)
	press.echo = true
	game._input(press)
	assert(game.screen_transition_phase.is_empty())
	press.echo = false
	press.pressed = false
	game._input(press)
	assert(game.screen_transition_phase.is_empty())
	var motion := InputEventJoypadMotion.new()
	motion.axis_value = 1
	game._input(motion)
	assert(game.screen_transition_phase.is_empty())
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	game._input(button)
	assert(game.screen_transition_target == "results")
	finish_fade(game)
	assert(game.state == "won" and game.ranking_panel.open and not game.concert_layer.visible)
	assert(game.ranking_panel.points == 12345 and game.ranking_panel.pending_id == id)
	game.ranking_panel.replay_button.pressed.emit()
	assert(game.ranking_panel.open and game.screen_transition_target == "title")
	finish_fade(game)
	assert(game.state == "title" and not game.ranking_panel.open and not game.character_select.open)
	game.request_character_selection()
	finish_fade(game)
	assert(game.state == "select" and not game.character_select.locked)
	print("ALL SCREEN FLOW CHECKS PASSED: title, selection, concert, results, title")
	game.queue_free()
	await process_frame
	quit()
