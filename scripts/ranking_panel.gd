extends CanvasLayer

const ArcadeUI = preload("res://scripts/arcade_ui.gd")

signal replay_requested

var service: Node
var screen: Control
var heading: Label
var subtitle: Label
var name_row: HBoxContainer
var name_input: LineEdit
var save_button: Button
var status: Label
var table: GridContainer
var refresh_button: Button
var replay_button: Button
var close_button: Button
var entry_button: Button
var pending_id := ""
var points := 0
var busy := false
var saved := false
var submitted_name := ""
var is_result := false
var open := false

func setup(online_service: Node) -> void:
	service = online_service
	layer = 20
	entry_button = make_button("TOP 10 [R]", show_ranking)
	entry_button.position = Vector2(760, 567)
	entry_button.size = Vector2(174, 40)
	entry_button.hide()
	add_child(entry_button)
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.035, 0.08, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(backdrop)
	var panel := VBoxContainer.new()
	panel.position = Vector2(100, 74)
	panel.size = Vector2(760, 490)
	panel.add_theme_constant_override("separation", 8)
	screen.add_child(panel)
	heading = make_label("TOP 10 / STREET GROOVA", 30)
	heading.add_theme_color_override("font_color", Color("62efd4"))
	panel.add_child(heading)
	subtitle = make_label("Ranking online del barrio", 16)
	panel.add_child(subtitle)
	name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	panel.add_child(name_row)
	name_input = LineEdit.new()
	name_input.placeholder_text = "TU NOMBRE"
	name_input.max_length = 12
	name_input.custom_minimum_size = Vector2(450, 40)
	name_input.add_theme_font_size_override("font_size", ArcadeUI.font_size(20))
	name_input.virtual_keyboard_enabled = true
	name_row.add_child(name_input)
	name_input.text_submitted.connect(func(_value): submit())
	save_button = make_button("GUARDAR ONLINE", submit)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(save_button)
	status = make_label("", 14)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 22
	panel.add_child(status)
	table = GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 20)
	table.add_theme_constant_override("v_separation", 9)
	panel.add_child(table)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	panel.add_child(buttons)
	refresh_button = make_button("ACTUALIZAR TOP 10", refresh)
	buttons.add_child(refresh_button)
	replay_button = make_button("VOLVER AL INICIO", func(): replay_requested.emit())
	buttons.add_child(replay_button)
	close_button = make_button("VOLVER", hide_panel)
	buttons.add_child(close_button)
	service.scores_loaded.connect(on_loaded)
	service.score_saved.connect(on_saved)
	var prefs := ConfigFile.new()
	if prefs.load("user://ranking.cfg") == OK:
		name_input.text = str(prefs.get_value("player", "name", ""))
	render_scores()
	hide_panel()

func make_label(value: String, size: int) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", ArcadeUI.font_size(size))
	item.add_theme_color_override("font_color", Color("f5e9d0"))
	return item

func make_button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 40)
	button.add_theme_font_size_override("font_size", ArcadeUI.font_size(16))
	button.pressed.connect(callback)
	return button

func show_ranking() -> void:
	is_result = false
	heading.text = "TOP 10 / STREET GROOVA"
	subtitle.text = "Puntajes compartidos de todos los jugadores"
	name_row.hide()
	replay_button.hide()
	close_button.show()
	screen.show()
	open = true
	refresh()
	close_button.grab_focus()

func show_result(result: String, final_score: int, run_id: String) -> void:
	is_result = true
	points = final_score
	pending_id = run_id
	saved = false
	busy = false
	submitted_name = ""
	heading.text = "CONGRATULATIONS!" if result == "won" else "FIN DE LA RONDA"
	subtitle.text = "PUNTOS: %06d  /  Guarda tu partida en el ranking online" % points
	name_input.editable = true
	save_button.disabled = false
	save_button.text = "GUARDAR ONLINE"
	name_row.show()
	replay_button.show()
	close_button.hide()
	screen.show()
	open = true
	refresh()
	name_input.grab_focus()

func hide_panel() -> void:
	open = false
	screen.hide()
	hide_browser_input()
	if is_instance_valid(name_input) and name_input.has_focus():
		name_input.release_focus()

func reset_run() -> void:
	service.cancel_pending()
	busy = false
	saved = false
	is_result = false
	submitted_name = ""
	pending_id = ""
	hide_panel()

func refresh() -> void:
	refresh_button.disabled = true
	if not busy and not saved:
		status.text = "CARGANDO TOP 10..."
	service.load_scores()

func submit() -> void:
	if busy or saved or not is_result:
		return
	if OS.has_feature("web") and submitted_name.is_empty():
		var browser_name: Variant = JavaScriptBridge.eval("window.GroovaNameInput ? window.GroovaNameInput.getValue() : null")
		if browser_name is String:
			name_input.text = browser_name
	if submitted_name.is_empty():
		if name_input.text.strip_edges().is_empty():
			status.text = "Escribi tu nombre antes de guardar."
			name_input.grab_focus()
			return
		submitted_name = service.clean_name(name_input.text)
		name_input.text = submitted_name
	busy = true
	name_input.editable = false
	hide_browser_input()
	save_button.disabled = true
	status.text = "GUARDANDO PUNTAJE..."
	service.submit(submitted_name, points, pending_id)

func on_loaded(success: bool, message: String) -> void:
	refresh_button.disabled = false
	if success:
		render_scores()
	if not busy and not saved and (not is_result or submitted_name.is_empty()):
		status.text = ("TOP 10 ONLINE" if service.scores.size() > 0 else "Se el primero en registrar tu puntaje.") if success else message

func on_saved(success: bool, entry: Dictionary, message: String) -> void:
	if entry.get("id", "") != pending_id or not is_result:
		return
	busy = false
	saved = success
	save_button.disabled = success
	save_button.text = "GUARDADO" if success else "REINTENTAR ENVIO"
	status.text = message
	if success:
		var prefs := ConfigFile.new()
		prefs.set_value("player", "name", submitted_name)
		prefs.save("user://ranking.cfg")
		service.load_scores()

func render_scores() -> void:
	for child in table.get_children():
		table.remove_child(child)
		child.queue_free()
	for title in ["PUESTO", "JUGADOR", "PUNTOS"]:
		var item := make_label(title, 13)
		item.add_theme_color_override("font_color", Color("98a3b9"))
		if title == "JUGADOR":
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		table.add_child(item)
	for i in range(10):
		var entry: Dictionary = service.scores[i] if i < service.scores.size() else {}
		for value in ["%02d" % (i + 1), str(entry.get("name", "---")), "%06d" % int(entry.get("score", 0)) if not entry.is_empty() else "---"]:
			var item := make_label(value, 17)
			if entry.get("id", "") == pending_id and not pending_id.is_empty():
				item.add_theme_color_override("font_color", Color("62efd4"))
			table.add_child(item)

func _unhandled_key_input(event: InputEvent) -> void:
	if open and not is_result and event.is_action_pressed("pause_game"):
		hide_panel()
		get_viewport().set_input_as_handled()

func hide_browser_input() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.GroovaNameInput) window.GroovaNameInput.hide();")

func _process(_dt: float) -> void:
	if not OS.has_feature("web") or not DisplayServer.is_touchscreen_available():
		return
	var area := name_input.get_global_rect()
	var shown := open and is_result and name_input.editable
	var viewport_size := get_viewport().get_visible_rect().size
	var data := {"session": pending_id, "value": name_input.text, "visible": shown, "x": area.position.x, "y": area.position.y, "w": area.size.x, "h": area.size.y, "width": viewport_size.x, "height": viewport_size.y}
	var response: Variant = JavaScriptBridge.eval("window.GroovaNameInput ? JSON.stringify(window.GroovaNameInput.update(%s)) : null" % JSON.stringify(data))
	if response is String:
		var parsed: Variant = JSON.parse_string(response)
		if parsed is Dictionary and parsed.get("value") is String:
			name_input.text = str(parsed["value"]).left(12)
			if parsed.get("submitted", false):
				submit()
