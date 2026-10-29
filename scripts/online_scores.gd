extends Node

signal scores_loaded(success: bool, message: String)
signal score_saved(success: bool, entry: Dictionary, message: String)

var scores: Array[Dictionary] = []
var base_url := ""
var fetch_request: HTTPRequest
var submit_request: HTTPRequest
var pending_id := ""


func _ready() -> void:
	base_url = str(ProjectSettings.get_setting("ranking/api_base_url", "")).trim_suffix("/")
	if base_url.is_empty():
		base_url = str(JavaScriptBridge.eval("window.location.origin")) if OS.has_feature("web") else "http://localhost:8888"
	fetch_request = HTTPRequest.new()
	submit_request = HTTPRequest.new()
	for request: HTTPRequest in [fetch_request, submit_request]:
		request.timeout = 12.0
		request.body_size_limit = 32768
		add_child(request)
	fetch_request.request_completed.connect(_on_scores_received)
	submit_request.request_completed.connect(_on_score_saved)


func new_run_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


func clean_name(value: String) -> String:
	var result := ""
	for character in value.strip_edges().to_upper():
		# Letras latinas (incluye acentos), numeros y signos arcade sencillos.
		var code := character.unicode_at(0)
		if (code >= 65 and code <= 90) or (code >= 48 and code <= 57) or (code >= 192 and code <= 255 and code != 215 and code != 247) or character in " _.-":
			result += character
	result = result.strip_edges().left(12)
	return result if not result.is_empty() else "JUGADOR"


func load_scores() -> void:
	fetch_request.cancel_request()
	var error := fetch_request.request(base_url + "/api/scores")
	if error != OK:
		scores_loaded.emit(false, "NO SE PUDO CONECTAR AL RANKING")


func submit(player_name: String, points: int, run_id: String) -> void:
	pending_id = run_id
	var body := JSON.stringify({"id": run_id, "name": player_name, "score": points})
	var error := submit_request.request(base_url + "/api/submit-score", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if error != OK:
		score_saved.emit(false, {"id": run_id}, "NO SE PUDO CONECTAR. REINTENTA.")


func cancel_pending() -> void:
	fetch_request.cancel_request()
	submit_request.cancel_request()
	pending_id = ""


func _decode(body: PackedByteArray) -> Dictionary:
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return {}
	return json.data


func _valid_entry(entry: Variant) -> bool:
	if not entry is Dictionary:
		return false
	if not entry.get("id") is String or not entry.get("name") is String or not entry.get("date") is String:
		return false
	var points: Variant = entry.get("score")
	return (points is int or points is float) and is_finite(float(points)) and points >= 0 and points <= 9999990 and float(points) == floorf(float(points))


func _on_scores_received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var data := _decode(body)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not data.get("scores") is Array:
		scores_loaded.emit(false, "SIN CONEXION AL TOP 10. PODES SEGUIR JUGANDO.")
		return
	var loaded: Array[Dictionary] = []
	for entry in data["scores"]:
		if not _valid_entry(entry) or loaded.size() >= 10:
			scores_loaded.emit(false, "RESPUESTA DE RANKING INVALIDA")
			return
		loaded.append(entry)
	scores = loaded
	scores_loaded.emit(true, "")


func _on_score_saved(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var data := _decode(body)
	var entry: Variant = data.get("entry")
	if result == HTTPRequest.RESULT_SUCCESS and code in [200, 201] and _valid_entry(entry) and entry["id"] == pending_id:
		score_saved.emit(true, entry, "PUNTAJE GUARDADO ONLINE")
		return
	var message := "SIN CONEXION. REINTENTA O VOLVE A JUGAR."
	if code == 429:
		message = "DEMASIADOS ENVIOS. ESPERA UN MINUTO."
	elif code in [400, 409, 413, 415]:
		message = str(data.get("error", "DATOS INVALIDOS")).to_upper()
	score_saved.emit(false, {"id": pending_id}, message)
