extends Node2D

const ArcadeUI = preload("res://scripts/arcade_ui.gd")
const MOBILE_STAGE = preload("res://assets/endingmobile.png")
const DESKTOP_STAGE = preload("res://assets/environment/ending/concert-stage.png")
const PERFORMER_DATA := {
	"alito": {"texture": preload("res://assets/environment/ending/alito.png"), "cell": Vector2(196, 216)},
	"beto": {"texture": preload("res://assets/environment/ending/beto.png"), "cell": Vector2(180, 240)},
	"cami": {"texture": preload("res://assets/environment/ending/cami.png"), "cell": Vector2(168, 256), "frames": 17},
	"dami": {"texture": preload("res://assets/environment/ending/dami.png"), "cell": Vector2(180, 240)},
	"malu": {"texture": preload("res://assets/environment/ending/malu.png"), "cell": Vector2(168, 256)},
	"meli": {"texture": preload("res://assets/environment/ending/meli.png"), "cell": Vector2(168, 256)},
	"pato": {"texture": preload("res://assets/environment/ending/pato.png"), "cell": Vector2(180, 240)},
	"vampi": {"texture": preload("res://assets/environment/ending/vampi.png"), "cell": Vector2(168, 256)}
}
const DESKTOP_PERFORMERS := [
	["pato", 0.18, 0.71, false, 248.0], ["dami", 0.31, 0.71, false, 248.0],
	["alito", 0.54, 0.71, false, 248.0], ["vampi", 0.80, 0.71, true, 248.0],
	["beto", 0.20, 0.82, false, 296.0], ["cami", 0.46, 0.82, true, 296.0],
	["malu", 0.72, 0.82, true, 296.0], ["meli", 0.84, 0.82, false, 296.0]
]
const MOBILE_PERFORMERS := [
	["pato", 0.22, 0.63, false, 168.0], ["alito", 0.50, 0.63, false, 168.0],
	["vampi", 0.78, 0.63, true, 168.0], ["beto", 0.27, 0.71, false, 187.5],
	["dami", 0.73, 0.71, false, 187.5], ["malu", 0.20, 0.79, false, 198.0],
	["cami", 0.50, 0.79, false, 198.0], ["meli", 0.80, 0.79, true, 198.0]
]
var elapsed := 0.0
var win_label: Label
var performers: Dictionary = {}

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
	create_performers()
	get_viewport().size_changed.connect(update_layout)
	update_layout()

func create_performers() -> void:
	var container := get_node("Performers") as Node2D
	for id in PERFORMER_DATA:
		var data: Dictionary = PERFORMER_DATA[id]
		var sprite := Sprite2D.new()
		sprite.name = str(id).capitalize()
		sprite.texture = data["texture"]
		sprite.hframes = 5
		sprite.vframes = 5
		sprite.offset = Vector2(0, -float(data["cell"].y) * 0.5)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		container.add_child(sprite)
		performers[id] = sprite

func mobile_layout() -> bool:
	var game = get_parent().get_parent()
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile") or bool(game.get("touch_visible"))

func update_layout() -> void:
	var frame := get_viewport_rect().size
	get_node("BlackBackdrop").size = frame
	var background := get_node("Background") as Sprite2D
	background.texture = MOBILE_STAGE if mobile_layout() else DESKTOP_STAGE
	var image_size := background.texture.get_size()
	var mobile := mobile_layout()
	var area := frame if mobile else Vector2(960, 640)
	var ratio := maxf(area.x / image_size.x, area.y / image_size.y) if mobile else minf(area.x / image_size.x, area.y / image_size.y)
	background.scale = Vector2.ONE * ratio
	background.position = (area - image_size * ratio) * 0.5
	win_label.position = Vector2(0, area.y * 0.1)
	win_label.size = Vector2(area.x, 64)
	win_label.add_theme_font_size_override("font_size", int(clampf(area.x * 0.046, 28, 44)))
	layout_performers(area, mobile)
	queue_redraw()

func layout_performers(area: Vector2, mobile: bool) -> void:
	var layout: Array = MOBILE_PERFORMERS if mobile else DESKTOP_PERFORMERS
	var mobile_scale := minf(area.x / 360.0, area.y / 640.0) if mobile else 1.0
	for index in range(layout.size()):
		var placement: Array = layout[index]
		var id: String = placement[0]
		var sprite: Sprite2D = performers[id]
		var cell: Vector2 = PERFORMER_DATA[id]["cell"]
		var target_height: float = float(placement[4]) * mobile_scale
		var sprite_scale := target_height / cell.y
		sprite.position = Vector2(area.x * float(placement[1]), area.y * float(placement[2]))
		sprite.scale = Vector2.ONE * sprite_scale
		sprite.flip_h = bool(placement[3])
		sprite.z_index = index

func restart() -> void:
	update_layout()
	elapsed = 0
	queue_redraw()

func _process(dt: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += dt
	win_label.modulate = Color.WHITE
	for id in performers:
		var frame_count := int(PERFORMER_DATA[id].get("frames", 20))
		(performers[id] as Sprite2D).frame = int(elapsed * 12.0) % frame_count
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
