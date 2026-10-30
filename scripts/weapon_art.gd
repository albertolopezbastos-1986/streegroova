extends RefCounted

static var textures: Dictionary = {}
static var regions: Dictionary = {}

static func draw_weapon(canvas: CanvasItem, kind: String, at: Vector2, angle: float, length := 48.0, fragment := -1) -> void:
	if not textures.has(kind):
		var texture := load("res://assets/items/weapon-%s.png" % kind) as Texture2D
		textures[kind] = texture
		regions[kind] = Rect2(texture.get_image().get_used_rect())
	var texture: Texture2D = textures[kind]
	var full: Rect2 = regions[kind]
	var source := full
	if fragment >= 0:
		source.size.x *= 0.5
		source.position.x += source.size.x * fragment
	var scale_factor := length / full.size.x
	var offset := Vector2(source.position.x - full.position.x - full.size.x * 0.15, -full.size.y * 0.7) * scale_factor
	var size := source.size * scale_factor
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for corner in [Vector2.ZERO, Vector2(1, 0), Vector2.ONE, Vector2(0, 1)]:
		points.append(at + (offset + corner * size).rotated(angle))
		uvs.append((source.position + corner * source.size) / texture.get_size())
	canvas.draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, texture)
