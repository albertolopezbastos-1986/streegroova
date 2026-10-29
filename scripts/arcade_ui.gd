extends RefCounted

const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")

# Press Start 2P has wider glyphs than the former proportional font.
static func font_size(previous_size: int) -> int:
	return maxi(8, roundi(previous_size * 0.62))
