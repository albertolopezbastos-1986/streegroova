extends RefCounted

const ROSTER = preload("res://assets/characters/roster.json")
const REQUIRED = ["idle", "walk", "attack_01", "attack_02", "attack_03", "jump", "jump_attack", "hurt", "death"]

static var cache: Dictionary = {}
static var roster: Dictionary = ROSTER.data.duplicate(true)

static func slots() -> Array:
	return roster["characters"]

static func character_for_slot(index: int) -> Dictionary:
	return character(str(slots()[clampi(index, 0, slots().size() - 1)]["id"]))

static func character(id: String) -> Dictionary:
	if cache.has(id):
		return cache[id]
	for entry in slots():
		if entry["id"] == id and entry.get("enabled", false):
			var pack := load_pack(str(entry["definition"]))
			if not pack.is_empty():
				cache[id] = pack
				return pack
	var fallback: String = roster["fallback"]
	if id != fallback:
		return character(fallback)
	push_error("No se pudo cargar el personaje base: " + fallback)
	return {}

static func load_pack(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var resource = load(path)
	if not resource is JSON or not resource.data is Dictionary:
		return {}
	var data: Dictionary = resource.data.duplicate(true)
	var animations: Dictionary = data.get("animations", {})
	var sheets: Dictionary = {}
	var base := path.get_base_dir()
	for name in REQUIRED:
		if not animations.has(name):
			return {}
	for name in animations:
		var animation: Dictionary = animations[name]
		if animation.get("source_animation", "") != "":
			continue
		if animation.get("format", "") != "sheet" or not animation.get("file") is String:
			return {}
		var texture_path := base.path_join(str(animation.get("path", ""))).path_join(animation["file"]).simplify_path()
		if not ResourceLoader.exists(texture_path):
			return {}
		var texture = load(texture_path)
		if not texture is Texture2D:
			return {}
		var size: Variant = animation.get("frame_size")
		if not size is Array or size.size() != 2 or float(size[0]) <= 0 or float(size[1]) <= 0:
			return {}
		if animation.get("sheet_columns") == null or animation.get("sheet_rows") == null:
			return {}
		var columns := int(animation["sheet_columns"])
		var rows := int(animation["sheet_rows"])
		if columns <= 0 or rows <= 0 or columns * float(size[0]) > texture.get_width() or rows * float(size[1]) > texture.get_height():
			return {}
		var indices: Array = animation.get("frame_indices", [])
		if indices.is_empty():
			indices = range(int(animation.get("frame_count") if animation.get("frame_count") != null else columns * rows))
		var frames: Array[int] = []
		for index in indices:
			if int(index) < 0 or int(index) >= columns * rows:
				return {}
			frames.append(int(index))
		if frames.is_empty() or float(animation.get("fps", 0)) <= 0:
			return {}
		animation["frame_indices"] = frames
		if not animation.get("active_hit_frames") is Array:
			animation["active_hit_frames"] = [frames[int(frames.size() * 0.6)]]
		sheets[name] = texture
	# A character can use the grab mechanic before its dedicated punch art arrives.
	if animations.has("grab_throw") and not animations.has("grab_punch_01"):
		animations["grab_punch_01"] = {"source_animation": "attack_01", "placeholder": true}
	# An optional dedicated ultimate sheet can replace this alias later.
	if not animations.has("ultimate"):
		animations["ultimate"] = {"source_animation": "attack_03"}
	for name in animations:
		var alias: Dictionary = animations[name]
		var source: String = alias.get("source_animation", "")
		if source.is_empty():
			continue
		if not sheets.has(source):
			return {}
		var combined: Dictionary = animations[source].duplicate(true)
		combined.merge(alias, true)
		animations[name] = combined
		sheets[name] = sheets[source]
	# Replace with an ultimate_air animation in the character manifest when art arrives.
	if not animations.has("ultimate_air"):
		animations["ultimate_air"] = animations["ultimate"].duplicate(true)
		animations["ultimate_air"]["source_animation"] = "ultimate"
		animations["ultimate_air"]["placeholder"] = true
		sheets["ultimate_air"] = sheets["ultimate"]
	var idle: Dictionary = animations["idle"]
	data["pivot_pixels"] = data.get("pivot_pixels", [float(idle["frame_size"][0]) / 2, float(idle["frame_size"][1]) - 10])
	var portrait: Texture2D
	var portrait_file: String = data.get("portrait_file", "portraits/portrait.png")
	if not portrait_file.is_empty() and ResourceLoader.exists(base.path_join(portrait_file)):
		portrait = load(base.path_join(portrait_file)) as Texture2D
	if portrait == null:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheets["idle"]
		var crop: Array = data.get("portrait_region", [0, 0, idle["frame_size"][0], idle["frame_size"][1]])
		atlas.region = Rect2(crop[0], crop[1], crop[2], crop[3])
		portrait = atlas
	return {"id": str(data["id"]), "display_name": str(data["display_name"]), "definition": data, "sheets": sheets, "portrait": portrait}
