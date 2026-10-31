extends Node2D

const WeaponArt = preload("res://scripts/weapon_art.gd")

var character_data: Dictionary = {}
var sheets: Dictionary = {}
var weapon := ""
static var hand_cache: Dictionary = {}
static var image_cache: Dictionary = {}

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
	if name in ["ultimate", "ultimate_air"]:
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
	if not weapon.is_empty():
		var hand := (weapon_hand_position(name, source_frame) - Vector2(anchor[0], anchor[1])) * pixel_scale
		var horizontal_grip: bool = motion == "punch_weapon" or source_frame in data.get("weapon_horizontal_frames", [])
		var direction := Vector2(1, -0.18) if horizontal_grip else Vector2(0.2, -1)
		WeaponArt.draw_weapon(self, weapon, hand, direction.angle())
	draw_texture_rect_region(sheets[name], Rect2(-Vector2(anchor[0], anchor[1]) * pixel_scale, cell * pixel_scale), region)

func weapon_hand_position(name: String, frame: int) -> Vector2:
	var data := definition(name)
	var overrides: Array = data.get("weapon_hand_frames", [])
	if frame < overrides.size():
		return Vector2(overrides[frame][0], overrides[frame][1])
	var texture: Texture2D = sheets[name]
	var cell := Vector2i(data["frame_size"][0], data["frame_size"][1])
	var key := "%s:%s:%d" % [texture.resource_path, cell, frame]
	if hand_cache.has(key):
		return hand_cache[key]
	if not image_cache.has(texture.resource_path):
		image_cache[texture.resource_path] = texture.get_image()
	var image: Image = image_cache[texture.resource_path]
	var columns := int(data["sheet_columns"])
	var origin := Vector2i(frame % columns, frame / columns) * cell
	var hand := Vector2(cell.x * 0.63, cell.y * 0.36)
	# Skin at the leading fist supplies a per-frame grip; metadata can override it.
	if image != null:
		var found := false
		for x in range(cell.x - 1, 0, -1):
			var sum_y := 0.0
			var count := 0
			# Ignore warm pixels in shoe highlights when finding the guarded hand.
			for y in range(int(cell.y * 0.24), ceili(cell.y * 0.82)):
				var color := image.get_pixel(origin.x + x, origin.y + y)
				if color.a > 0.5 and color.r > 0.38 and color.r > color.g * 1.2 and color.g > color.b * 1.15:
					sum_y += y
					count += 1
			if count > 1:
				hand = Vector2(x - 2, sum_y / count)
				found = true
			if found:
				break
	hand_cache[key] = hand
	return hand
