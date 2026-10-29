extends Node

signal scores_loaded(success: bool, message: String)
signal score_saved(success: bool, entry: Dictionary, message: String)

var scores: Array[Dictionary] = []
var submissions: Array[Dictionary] = []
var loads := 0

func load_scores() -> void:
	loads += 1

func clean_name(value: String) -> String:
	return value.strip_edges().to_upper().left(12)

func cancel_pending() -> void:
	pass

func submit(player_name: String, points: int, run_id: String) -> void:
	submissions.append({"name": player_name, "score": points, "id": run_id})
