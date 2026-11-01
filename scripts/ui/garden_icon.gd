extends Control
## Original line icons; no dependence on emoji or platform glyph fallback.
var kind: String = "leaf"
var ink := Color("385d48")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(24, 24)

func _draw() -> void:
	var center := size * 0.5
	if kind == "gear":
		draw_arc(center, 7, 0, TAU, 24, ink, 2, true)
		draw_arc(center, 2.5, 0, TAU, 18, ink, 1.8, true)
		for i in range(8):
			var direction := Vector2.from_angle(i * TAU / 8.0)
			draw_line(center + direction * 7, center + direction * 10, ink, 3, true)
	elif kind == "book":
		draw_polyline(PackedVector2Array([center + Vector2(-10, -8), center + Vector2(-2, -6), center + Vector2(0, -4), center + Vector2(2, -6), center + Vector2(10, -8), center + Vector2(10, 8), center + Vector2(3, 8), center + Vector2(0, 10), center + Vector2(-3, 8), center + Vector2(-10, 8), center + Vector2(-10, -8)]), ink, 1.8, true)
		draw_line(center + Vector2(0, -3), center + Vector2(0, 8), ink, 1.5, true)
	elif kind == "help":
		draw_arc(center, 10, 0, TAU, 30, ink, 1.8, true)
		draw_arc(center + Vector2(0, -3), 3.5, -PI, PI * 0.5, 16, ink, 1.8, true)
		draw_line(center + Vector2(0, 0), center + Vector2(0, 3), ink, 1.8, true)
		draw_circle(center + Vector2(0, 6.5), 1, ink, true, -1, true)
	elif kind == "close":
		draw_line(center - Vector2(6, 6), center + Vector2(6, 6), ink, 2, true)
		draw_line(center + Vector2(-6, 6), center + Vector2(6, -6), ink, 2, true)
	else:
		draw_polyline(PackedVector2Array([center + Vector2(-8, 8), center + Vector2(-8, -2), center + Vector2(-3, -9), center + Vector2(9, -10), center + Vector2(8, 2), center + Vector2(2, 8), center + Vector2(-8, 8)]), ink, 1.8, true)
		draw_line(center + Vector2(-7, 7), center + Vector2(4, -4), ink, 1.8, true)
