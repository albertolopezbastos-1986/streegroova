extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 640)
	root.add_child(viewport)
	var game = preload("res://scenes/main.tscn").instantiate()
	game.simulate_mobile = true
	viewport.add_child(game)
	game.set_process(false)
	var concert = game.concert_layer.get_child(0)
	for size in [Vector2i(360, 800), Vector2i(1440, 640), Vector2i(960, 640)]:
		viewport.size = size
		concert.restart()
		var background = concert.get_node("Background")
		assert(background.texture.resource_path == "res://assets/endingmobile.png", "mobile ending uses the supplied portrait image")
		var rendered: Vector2 = background.texture.get_size() * background.scale
		assert(rendered.x >= size.x - 0.01 and rendered.y >= size.y - 0.01, "stage covers mobile viewport")
		assert(is_equal_approx(background.scale.x, background.scale.y), "image keeps its aspect ratio")
		assert(background.position.is_equal_approx((Vector2(size) - rendered) / 2), "crop stays centered")
		assert(concert.win_label.size.x == size.x, "victory text follows viewport width")
	game.touch_visible = false
	concert.update_layout()
	var background = concert.get_node("Background")
	assert(background.texture.resource_path == "res://assets/environment/ending/concert-stage.png", "desktop restores its landscape image")
	var rendered: Vector2 = background.texture.get_size() * background.scale
	assert(rendered.x <= 960.01 and rendered.y <= 640.01, "desktop retains complete stage")
	print("MOBILE CONCERT PASSED: portrait, landscape, proportional fill, centered crop, responsive title, desktop layout")
	viewport.queue_free()
	await process_frame
	quit()
