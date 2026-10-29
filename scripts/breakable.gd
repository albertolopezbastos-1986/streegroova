extends Node2D

var game: Node2D
var hp := 38.0
var dead := false
var height := 0.0
var barrel := false
var as_food := false
var flash := 0.0
var age := 0.0

func setup(owner_game: Node2D, at: Vector2, is_barrel: bool) -> void:
	game = owner_game
	position = at
	barrel = is_barrel
	hp = 57.0 if barrel else 38.0
	z_index = int(position.y)

func hurt(damage: float, direction: float, _heavy := false) -> void:
	if dead or as_food:
		return
	hp -= damage
	flash = 0.12
	game.sound("hit")
	game.impact(position - Vector2(0, 16), direction, false)
	if hp <= 0:
		dead = true
		hide()
		game.score += 50
		game.drop_chicken(position)
		for i in range(8):
			game.particles.append({"pos": position - Vector2(0, 16), "vel": Vector2(randf_range(-100, 100), randf_range(-130, -30)), "life": 0.45, "color": Color("be8846"), "size": 3.0})

func tick(dt: float) -> void:
	flash = maxf(0, flash - dt)
	age += dt
	queue_redraw()

func pixel(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func _draw() -> void:
	if dead:
		return
	pixel(-19, -2, 38, 5, "1b1b27")
	if as_food:
		draw_chicken()
		return
	modulate = Color(1.8, 1.8, 1.8) if flash > 0 else Color.WHITE
	if barrel:
		pixel(-16, -39, 32, 38, "251a19")
		pixel(-19, -34, 38, 29, "543321")
		pixel(-16, -37, 32, 36, "8b552d")
		for x in [-12, -4, 4, 12]:
			pixel(x, -36, 2, 34, "4a2e24")
			pixel(x + 2, -34, 2, 31, "b47c3c")
		for y in [-32, -13]:
			pixel(-18, y, 36, 5, "252e39")
			pixel(-18, y, 36, 1, "92958d")
			pixel(-14, y + 2, 2, 2, "c0b9a0")
		pixel(-14, -39, 28, 3, "c18a4b")
	else:
		pixel(-21, -40, 42, 40, "2c201d")
		pixel(-19, -38, 38, 36, "9d632f")
		for y in [-35, -26, -17, -8]:
			pixel(-17, y, 34, 6, "be8542")
			pixel(-16, y + 2, 16, 1, "d49e58")
		pixel(-20, -39, 4, 38, "e0ab60")
		pixel(16, -39, 4, 38, "70462a")
		for i in range(8):
			pixel(-16 + i * 4, -8 - i * 4, 5, 5, "67432b")
			pixel(-16 + i * 4, -10 - i * 4, 4, 3, "dba05a")
		for x in [-18, 17]:
			for y in [-36, -5]:
				pixel(x, y, 2, 2, "37333a")
	if hp < (57 if barrel else 38):
		pixel(-3, -30, 2, 13, "34221e")
		pixel(-1, -19, 6, 2, "34221e")

func draw_chicken() -> void:
	# Hand-drawn pixel silhouette: roast body, highlights, leg and white bone.
	pixel(-20, -5, 40, 5, "9b97a1")
	pixel(-17, -6, 34, 3, "e5dcc7")
	pixel(-14, -15, 25, 10, "60341d")
	pixel(-11, -22, 20, 17, "9a4824")
	pixel(-8, -25, 14, 18, "cb702d")
	pixel(-11, -19, 20, 10, "d98435")
	pixel(-5, -23, 9, 3, "f4b550")
	pixel(-8, -17, 5, 3, "f6be62")
	pixel(4, -12, 11, 7, "8d3e20")
	pixel(6, -14, 10, 6, "d58234")
	pixel(14, -12, 6, 3, "eee3bd")
	pixel(18, -14, 4, 7, "fff1cf")
	pixel(-15, -12, 7, 5, "ba612c")
	if int(age * 3) % 2 == 0:
		pixel(-23, -25, 2, 6, "ffe6a0")
		pixel(-25, -23, 6, 2, "ffe6a0")
