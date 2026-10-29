extends SceneTree

var checks := 0
var received := false
var saved := false

func check(condition: bool, description: String) -> void:
	assert(condition, description)
	if not condition:
		quit(1)
		return
	checks += 1
	print("PASS: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var online = preload("res://scripts/online_scores.gd").new()
	root.add_child(online)
	online.scores_loaded.connect(func(success, _message): received = success)
	online.score_saved.connect(func(success, _entry, _message): saved = success)
	var id: String = online.new_run_id()
	check(id.length() == 32 and id != online.new_run_id(), "each run gets a distinct id")
	check(online.clean_name("  josé<script>  ") == "JOSÉSCRIPT", "player name is sanitized")
	var entry := {"id": id, "name": "AXEL", "score": 1250, "date": "2026-10-29T12:00:00.000Z"}
	online._on_scores_received(0, 200, PackedStringArray(), JSON.stringify({"scores": [entry]}).to_utf8_buffer())
	check(received and online.scores.size() == 1, "valid JSON populates online ranking")
	online._on_scores_received(0, 200, PackedStringArray(), "<html>not an API</html>".to_utf8_buffer())
	check(not received and online.scores.size() == 1, "invalid response preserves previously loaded ranking")
	online._on_scores_received(0, 503, PackedStringArray(), "{}".to_utf8_buffer())
	check(not received, "server outage is reported as failure")
	online.pending_id = id
	online._on_score_saved(0, 201, PackedStringArray(), JSON.stringify({"entry": entry}).to_utf8_buffer())
	check(saved, "save confirms matching run id")
	online.pending_id = online.new_run_id()
	online._on_score_saved(0, 201, PackedStringArray(), JSON.stringify({"entry": entry}).to_utf8_buffer())
	check(not saved, "save cannot confirm a different run id")
	var service = preload("res://tests/mock_online.gd").new()
	root.add_child(service)
	var panel = preload("res://scripts/ranking_panel.gd").new()
	root.add_child(panel)
	panel.setup(service)
	panel.show_result("won", 1250, id)
	panel.name_input.text = ""
	panel.submit()
	check(service.submissions.is_empty(), "blank name cannot submit a score")
	panel.name_input.text = "  beto  "
	panel.submit()
	check(panel.busy and panel.save_button.disabled and not panel.name_input.editable, "submission locks controls while in flight")
	panel.submit()
	check(service.submissions.size() == 1, "double click does not submit twice")
	service.score_saved.emit(false, {"id": id}, "SIN CONEXION")
	check(not panel.busy and not panel.saved and not panel.save_button.disabled, "failure enables retry")
	panel.submit()
	check(service.submissions.size() == 2 and service.submissions[0] == service.submissions[1], "retry sends identical id, name and score")
	service.score_saved.emit(true, entry, "PUNTAJE GUARDADO ONLINE")
	check(panel.saved and panel.save_button.disabled, "confirmed save cannot be sent again")
	panel.submit()
	check(service.submissions.size() == 2, "save after success is ignored")
	service.scores.assign([entry])
	service.scores_loaded.emit(true, "")
	check(panel.table.get_child_count() == 33, "top ten table renders with headers and empty slots")
	panel.reset_run()
	check(not panel.open and not panel.saved, "new run closes and resets score screen")
	panel.show_ranking()
	check(panel.open and not panel.name_row.visible, "title ranking only allows reading")
	panel.hide_panel()
	check(not panel.open, "ranking can be closed")
	panel.queue_free()
	service.queue_free()
	online.queue_free()
	await process_frame
	print("ALL ", checks, " ONLINE CLIENT CHECKS PASSED")
	quit()
