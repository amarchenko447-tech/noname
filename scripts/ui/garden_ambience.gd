extends Node2D
## Only this small layer redraws at 30 Hz. No input nodes or particles.
const Art = preload("res://scripts/ui/garden_drawing.gd")
var animation_time: float = 0.0
var reduced_motion: bool = false
var animate: bool = true
var _accumulator: float = 0.0
const GRASS = [Vector2(-460, 30), Vector2(452, -12), Vector2(-281, 254), Vector2(271, 250), Vector2(-229, -304), Vector2(220, -306)]

func _process(delta: float) -> void:
	if not animate or reduced_motion or not is_visible_in_tree():
		return
	_accumulator += delta
	if _accumulator >= 1.0 / 30.0:
		animation_time = fmod(animation_time + _accumulator, 60.0)
		_accumulator = 0.0
		queue_redraw()

func set_motion_reduced(value: bool) -> void:
	reduced_motion = value
	queue_redraw()

func _draw() -> void:
	var time: float = 0.0 if reduced_motion else animation_time
	for i in range(GRASS.size()):
		var base: Vector2 = GRASS[i]
		var sway: float = sin(time * TAU / (3.5 + i * 0.2) + i) * 5.0
		for blade in range(5):
			var p: Vector2 = base + Vector2(blade * 6 - 12, 0)
			draw_polyline(PackedVector2Array([p, p + Vector2(sway * 0.4, -13), p + Vector2(sway + blade - 2, -28 - blade * 3)]), Color("629763") if blade % 2 == 0 else Color("80aa68"), 3, true)
		if i % 2 == 0:
			var head: Vector2 = base + Vector2(sway * 0.7, -44 + sin(time * 1.5 + i) * 2)
			draw_line(base, head, Color("629763"), 3, true)
			Art.flower(self, head, Color("f8e7b7"), 9)
	if reduced_motion:
		return
	# Three pollen motes; soft visibility envelopes, never a strobe.
	for i in range(3):
		var phase: float = fmod(time + i * 3.0, 10.0) / 10.0
		var alpha: float = sin(phase * PI) * 0.65
		var p := Vector2(-300 + i * 270 + sin(time * 0.5 + i) * 22, 100 - phase * 370)
		draw_circle(p, 7, Color(1, 0.96, 0.73, alpha * 0.18), true, -1, true)
		draw_circle(p, 2.5, Color(1, 0.98, 0.83, alpha), true, -1, true)
	# Two butterflies, slow paths and understated wing flaps.
	for i in range(2):
		var p := Vector2(sin(time * 0.25 + i * 2.8) * 310, -210 + i * 330 + sin(time * 0.4 + i) * 38)
		var flap: float = 0.4 + absf(sin(time * 3.5 + i)) * 0.6
		Art.ellipse(self, p + Vector2(8, 26), Vector2(12, 4), Color(0.25, 0.35, 0.18, 0.08))
		for side in [-1, 1]:
			Art.leaf(self, p + Vector2(side * 10 * flap, -3), Vector2(10 * flap, 12), Color("f6cb8d") if i == 0 else Color("c7b7df"), side * -0.3)
			Art.leaf(self, p + Vector2(side * 7 * flap, 8), Vector2(7 * flap, 7), Color("edb77b") if i == 0 else Color("b2a0ce"), side * 0.3)
		draw_line(p - Vector2(0, 8), p + Vector2(0, 12), Color("746347"), 3, true)
	# One restrained, long sunlight caress outside the beds.
	var shimmer: float = (sin(time * TAU / 9.0) + 1) * 0.012
	Art.ellipse(self, Vector2(-215, -264), Vector2(135, 42), Color(1, 0.94, 0.71, shimmer))
