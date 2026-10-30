extends Node2D

var character_data: Dictionary = {}
var sheets: Dictionary = {}

func configure(pack: Dictionary) -> void:
	character_data = pack["definition"]
	sheets = pack["sheets"]
	motion = "idle"
	clock = 0
	source_frame = 0
	queue_redraw()

var motion := "idle"
var source_frame := 0
var clock := 0.0
var facing := 1.0

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func definition(name: String) -> Dictionary:
	return character_data["animations"][name]

func duration(name: String) -> float:
	var data := definition(name)
	return float(data["frame_indices"].size()) / float(data["fps"])

func frame_at(name: String, progress: float) -> int:
	var frames: Array = definition(name)["frame_indices"]
	var timings: Array = definition(name).get("frame_times", [])
	if timings.size() == frames.size():
		var selected := 0
		for i in range(timings.size()):
			if progress >= float(timings[i]):
				selected = i
		return int(frames[selected])
	return int(frames[mini(int(clampf(progress, 0, 1) * frames.size()), frames.size() - 1)])

func update_pose(name: String, dt: float, direction: float, progress := -1.0) -> void:
	if name != motion:
		motion = name
		clock = 0
	clock += dt
	facing = direction
	if name == "ultimate":
		var data := definition(name)
		var frames: Array = data["frame_indices"]
		var impact := int(data.get("impact_frame", data["active_hit_frames"][0]))
		var contact := 0
		for i in range(frames.size()):
			if int(frames[i]) == impact:
				contact = i
				break
		var split := clampf(float(data.get("impact_progress", 0.59)), 0.01, 0.99)
		var index: int
		if progress < split:
			index = mini(maxi(0, contact - 1), int(progress / split * contact))
		else:
			index = mini(frames.size() - 1, contact + int((progress - split) / (1 - split) * (frames.size() - contact)))
		source_frame = int(frames[index])
	elif progress >= 0:
		source_frame = frame_at(name, progress)
	else:
		var data := definition(name)
		var frames: Array = data["frame_indices"]
		var index := int(clock * float(data["fps"]))
		index = index % frames.size() if data["loop"] else mini(index, frames.size() - 1)
		source_frame = int(frames[index])
	queue_redraw()

func _draw() -> void:
	if character_data.is_empty():
		return
	var name := motion
	var data := definition(name)
	var cell := Vector2(data["frame_size"][0], data["frame_size"][1])
	var columns := int(data["sheet_columns"])
	var region := Rect2(Vector2(source_frame % columns, floori(float(source_frame) / columns)) * cell, cell)
	var anchor: Array = data.get("pivot_pixels", character_data["pivot_pixels"])
	var pixel_scale := float(data.get("scale", character_data["scale"]))
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing * (-1 if character_data.get("default_facing", "right") == "left" else 1), 1))
	draw_texture_rect_region(sheets[name], Rect2(-Vector2(anchor[0], anchor[1]) * pixel_scale, cell * pixel_scale), region)
