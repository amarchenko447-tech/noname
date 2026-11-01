extends Node2D
## Static local soil art: recorded once, moved by the selection tween.
const Art = preload("res://scripts/ui/garden_drawing.gd")
var bed_id: int = 0
var flecks: Array[Vector2] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 200 + bed_id
	for i in range(85):
		var point := Vector2(rng.randf_range(-119, 119), rng.randf_range(-76, 76))
		if absf(point.x) / 119.0 + absf(point.y) / 76.0 < 0.9:
			flecks.append(point)

func _draw() -> void:
	Art.ellipse(self, Vector2(5, 19), Vector2(146, 91), Color(0.17, 0.29, 0.15, 0.13))
	draw_colored_polygon(Art.diamond(Vector2(0, 14), Vector2(147, 100)), Color("77553d"))
	draw_colored_polygon(Art.diamond(Vector2(0, 7), Vector2(147, 100)), Color("b28a5c"))
	draw_colored_polygon(Art.diamond(Vector2.ZERO, Vector2(147, 100)), Color("d2ac79"))
	Art.outline(self, Art.diamond(Vector2(0, -2), Vector2(141, 94)), Color("e6c694"), 3)
	draw_colored_polygon(Art.diamond(Vector2(0, -2), Vector2(131, 85)), Color("674733"))
	draw_colored_polygon(Art.diamond(Vector2(0, 1), Vector2(125, 79)), Color("82563c"))
	draw_colored_polygon(Art.diamond(Vector2(0, 5), Vector2(113, 67)), Color("8f6041"))
	# Broad curved furrows, soft dark troughs and warm sunlit lips.
	for row in range(-2, 3):
		var offset := Vector2(row * 23, row * -13)
		var groove := PackedVector2Array()
		for j in range(10):
			var t: float = j / 9.0
			groove.append(offset + Vector2(lerpf(-42, 42, t), lerpf(-24, 24, t) + sin(t * PI) * 5))
		draw_polyline(groove, Color("704930"), 6, true)
		var lip := PackedVector2Array()
		for point in groove:
			lip.append(point + Vector2(-1, -4))
		draw_polyline(lip, Color("a9744d"), 3, true)
	for i in range(flecks.size()):
		draw_circle(flecks[i], 1.2 + (i % 3) * 0.5, Color("b38559") if i % 3 == 0 else Color("704a34"), true, -1, true)
	# Tiny moss along the outside; soil remains unobscured.
	Art.leaf(self, Vector2(-112, 28), Vector2(10, 4), Color("8eaf68"), -0.4)
	Art.leaf(self, Vector2(-122, 20), Vector2(8, 3), Color("b3c37c"), 0.2)
