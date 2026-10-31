extends SceneTree

const ROOT := "res://assets/characters/beto/animations/pickup/"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var base := Image.load_from_file("res://assets/characters/beto/animations/crouch/frames/07.png")
	DirAccess.make_dir_recursive_absolute(ROOT + "frames")
	if args.is_empty() or args[0] == "reference":
		base.resize(1024, 1024, Image.INTERPOLATE_NEAREST)
		base.save_png("res://.godot/pickup-crouch-reference.png")
	else:
		assert(args[0] == "pack")
		var sheet := Image.create(800, 600, false, Image.FORMAT_RGBA8)
		var hand_anchors: Array = []
		for index in range(11):
			var frame: Image
			if index < 8:
				frame = Image.load_from_file("res://assets/characters/beto/animations/crouch/frames/%02d.png" % index)
			else:
				frame = Image.load_from_file(ROOT + "source/%02d.png" % index)
				frame.convert(Image.FORMAT_RGBA8)
				frame.resize(200, 200, Image.INTERPOLATE_NEAREST)
				for y in range(200):
					for x in range(200):
						var color := frame.get_pixel(x, y)
						color.a = 1 if color.a >= 0.5 else 0
						frame.set_pixel(x, y, color)
				var bounds := frame.get_used_rect()
				var feet := frame.get_region(Rect2i(0, bounds.end.y - 16, 200, 16)).get_used_rect()
				var base_feet := base.get_region(Rect2i(0, 173, 200, 16)).get_used_rect()
				var aligned := Image.create(200, 200, false, Image.FORMAT_RGBA8)
				aligned.blit_rect(frame, Rect2i(0, 0, 200, 200), Vector2i(roundi(base_feet.get_center().x - feet.get_center().x), 189 - bounds.end.y))
				frame = aligned
			frame.convert(Image.FORMAT_RGBA8)
			hand_anchors.append(find_hand(frame, index))
			frame.save_png(ROOT + "frames/%02d.png" % index)
			sheet.blit_rect(frame, Rect2i(0, 0, 200, 200), Vector2i((index % 4) * 200, floori(index / 4.0) * 200))
			print("PICKUP FRAME ", index, " ", frame.get_used_rect())
		sheet.save_png(ROOT + "pickup.png")
		var file := FileAccess.open(ROOT + "hand-anchors.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(hand_anchors, "  ") + "\n")
	quit()

func is_skin(color: Color) -> bool:
	return color.a > 0.5 and color.r > 0.58 and color.g > 0.25 and color.r > color.g * 1.2 and color.g > color.b * 1.15

func find_hand(frame: Image, index: int) -> Array:
	if index >= 8:
		# Explicit palm anchors for the reaching hand; the other fist stays in guard.
		return [[115, 155], [123, 173], [116, 177]][index - 8]
	for x in range(199, 0, -1):
		var sum_y := 0.0
		var count := 0
		for y in range(48, 150):
			if is_skin(frame.get_pixel(x, y)):
				sum_y += y
				count += 1
		if count > 1:
			return [x - 2, sum_y / count]
	return [126, 72]
