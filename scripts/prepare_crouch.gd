extends SceneTree

const ROOT := "res://assets/characters/beto/animations/crouch/"
const SOURCES := ["", "near-idle.png", "01.png", "02.png", "mid-crouch.png", "03.png", "04.png", "07.png"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var idle := Image.load_from_file("res://assets/characters_20_frames/beto/animations/idle/idle.png").get_region(Rect2i(0, 0, 200, 200))
	DirAccess.make_dir_recursive_absolute(ROOT + "frames")
	if args.is_empty() or args[0] == "reference":
		idle.save_png(ROOT + "frames/00.png")
		idle.resize(1024, 1024, Image.INTERPOLATE_NEAREST)
		idle.save_png("res://.godot/crouch-idle-reference.png")
		print("CROUCH REFERENCE READY")
	elif args[0] == "pack":
		idle.convert(Image.FORMAT_RGBA8)
		var sheet := Image.create(800, 400, false, Image.FORMAT_RGBA8)
		var idle_bounds := idle.get_used_rect()
		var idle_feet := idle.get_region(Rect2i(0, idle_bounds.end.y - 16, 200, 16)).get_used_rect()
		for index in range(8):
			var frame := idle.duplicate() as Image
			if index > 0:
				frame = Image.load_from_file(ROOT + "source/" + SOURCES[index])
				assert(frame != null and not frame.is_empty())
				frame.convert(Image.FORMAT_RGBA8)
				frame.resize(200, 200, Image.INTERPOLATE_NEAREST)
				# Raster preparation only: nearest sampling, crisp alpha, and foot alignment.
				for y in range(200):
					for x in range(200):
						var color := frame.get_pixel(x, y)
						color.a = 1 if color.a >= 0.5 else 0
						frame.set_pixel(x, y, color)
				var bounds := frame.get_used_rect()
				var feet := frame.get_region(Rect2i(0, bounds.end.y - 16, 200, 16)).get_used_rect()
				var offset := Vector2i(roundi(idle_feet.get_center().x - feet.get_center().x), idle_bounds.end.y - bounds.end.y)
				var aligned := Image.create(200, 200, false, Image.FORMAT_RGBA8)
				aligned.blit_rect(frame, Rect2i(0, 0, 200, 200), offset)
				frame = aligned
			frame.save_png(ROOT + "frames/%02d.png" % index)
			sheet.blit_rect(frame, Rect2i(0, 0, 200, 200), Vector2i((index % 4) * 200, (index / 4) * 200))
			print("FRAME ", index, " bounds ", frame.get_used_rect())
		sheet.save_png(ROOT + "crouch.png")
		print("CROUCH SHEET READY: 8 frames, 200x200, 4x2 grid")
	else:
		push_error("Unknown preparation command")
	quit()
