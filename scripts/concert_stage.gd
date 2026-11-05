extends Node2D

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const MOBILE_STAGE_PATH := "res://assets/endingmobile.png"
var elapsed := 0.0
var win_label: Label

func _ready() -> void:
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
	get_viewport().size_changed.connect(update_layout)
	update_layout()

func mobile_layout() -> bool:
	var game = get_parent().get_parent()
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile") or bool(game.get("touch_visible"))

func update_layout() -> void:
	var frame := get_viewport_rect().size
	get_node("BlackBackdrop").size = frame
	var background := get_node("Background") as Sprite2D
	if mobile_layout() and ResourceLoader.exists(MOBILE_STAGE_PATH):
		background.texture = load(MOBILE_STAGE_PATH) as Texture2D
	var image_size := background.texture.get_size()
	var mobile := mobile_layout()
	var area := frame if mobile else Vector2(960, 640)
	var ratio := maxf(area.x / image_size.x, area.y / image_size.y) if mobile else minf(area.x / image_size.x, area.y / image_size.y)
	background.scale = Vector2.ONE * ratio
	background.position = (area - image_size * ratio) * 0.5
	win_label.position = Vector2(0, area.y * 0.1)
	win_label.size = Vector2(area.x, 64)
	win_label.add_theme_font_size_override("font_size", int(clampf(area.x * 0.046, 28, 44)))
	queue_redraw()

func restart() -> void:
	update_layout()
	elapsed = 0
	queue_redraw()

func _process(dt: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += dt
	win_label.modulate = Color.WHITE
	queue_redraw()

func _draw() -> void:
	var area := get_viewport_rect().size if mobile_layout() else Vector2(960, 640)
	draw_set_transform(Vector2.ZERO, 0, area / Vector2(960, 640))
	var colors := [Color("d735ba"), Color("38c9ed"), Color("ffc36b")]
	for i in range(5):
		var origin := Vector2(180 + i * 150, 75)
		var center := origin.x + sin(elapsed * 0.9 + i * 1.6) * 130
		var tint: Color = colors[i % colors.size()]
		tint.a = 0.035 + (sin(elapsed * 2 + i) + 1) * 0.015
		draw_colored_polygon(PackedVector2Array([origin - Vector2(5, 0), origin + Vector2(5, 0), Vector2(center + 75, 590), Vector2(center - 75, 590)]), tint)
