extends RefCounted

const MAX_SCORE := 9999990
const COMBO_WINDOW := 2.5
const BOOST_DURATION := 10.0

var sushi_time := 0.0
var beer_time := 0.0
var level_unhurt := true

func reset() -> void:
	sushi_time = 0
	beer_time = 0
	level_unhurt = true

func tick(dt: float) -> void:
	sushi_time = maxf(0, sushi_time - dt)
	beer_time = maxf(0, beer_time - dt)

func consume(beer: bool) -> void:
	if beer:
		beer_time = BOOST_DURATION
	else:
		sushi_time = BOOST_DURATION

func multiplier(charge: float, lives: int, hits: int, ultimate := false) -> float:
	var result := 1.1 if charge >= 100 else 1.0
	result *= 2.0 if ultimate else 1.0
	result *= 1.0 + minf(2.0, maxf(0, hits - 1) * 0.05)
	result *= 1.0 if lives >= 3 else (0.85 if lives == 2 else 0.65)
	result *= 1.25 if sushi_time > 0 else 1.0
	result *= 1.25 if beer_time > 0 else 1.0
	return result

func points(base: float, charge: float, lives: int, hits: int, ultimate := false) -> int:
	# Keep scores in tens, as required by the online ranking.
	return maxi(10, roundi(base * multiplier(charge, lives, hits, ultimate) / 10.0) * 10) if base > 0 else 0
