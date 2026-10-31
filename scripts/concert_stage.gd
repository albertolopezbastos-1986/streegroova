extends Node2D

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
var elapsed := 0.0
var win_label: Label

func _ready() -> void:
	get_node("BlackBackdrop").size = get_viewport_rect().size
	var frame := Vector2(960, ProjectSettings.get_setting("display/window/size/viewport_height"))
	var background := get_node("Background") as Sprite2D
	var image_size := background.texture.get_size()
	background.scale = Vector2.ONE * minf(frame.x / image_size.x, frame.y / image_size.y)
	background.position = (frame - image_size * background.scale) * 0.5
	win_label = Label.new()
	win_label.text = "YOU WIN!"
	win_label.position = Vector2(0, 65)
	win_label.size = Vector2(960, 64)
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.add_theme_font_override("font", ArcadeUI.FONT)
	win_label.add_theme_font_size_override("font_size", 44)
	win_label.add_theme_color_override("font_shadow_color", Color("101322"))
	win_label.add_theme_constant_override("shadow_offset_x", 4)
	win_label.add_theme_constant_override("shadow_offset_y", 4)
	win_label.z_index = 5
	add_child(win_label)

func restart() -> void:
	elapsed = 0
	queue_redraw()

func _process(dt: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += dt
	win_label.modulate = Color.WHITE if int(elapsed * 3) % 2 == 0 else Color("62efd4")
	queue_redraw()

func _draw() -> void:
	var colors := [Color("d735ba"), Color("38c9ed"), Color("ffc36b")]
	for i in range(5):
		var origin := Vector2(180 + i * 150, 75)
		var center := origin.x + sin(elapsed * 0.9 + i * 1.6) * 130
		var tint: Color = colors[i % colors.size()]
		tint.a = 0.035 + (sin(elapsed * 2 + i) + 1) * 0.015
		draw_colored_polygon(PackedVector2Array([origin - Vector2(5, 0), origin + Vector2(5, 0), Vector2(center + 75, 590), Vector2(center - 75, 590)]), tint)
