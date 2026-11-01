extends Control
## Quiet illustrated meadow surround. Redraw only on resize, no input.
const Art = preload("res://scripts/ui/garden_drawing.gd")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	# Warm morning sky into a pale sage clearing.
	for band in range(70):
		var t: float = band / 69.0
		var tint := Color("f5f0d8").lerp(Color("d9e8c9"), smoothstep(0, 0.60, t)).lerp(Color("edf0d9"), smoothstep(0.66, 1, t))
		draw_rect(Rect2(0, size.y * band / 70.0, size.x, size.y / 70.0 + 1), tint)
	for i in range(4):
		Art.ellipse(self, Vector2(size.x * 0.14, size.y * 0.25), Vector2(95 + i * 25, 100 + i * 20), Color(1, 0.96, 0.76, 0.025))
	# Low-contrast hedges suggest a world beyond the garden, with a clear UI zone.
	for side in [-1, 1]:
		var edge: float = 0 if side < 0 else size.x
		for i in range(6):
			var p := Vector2(edge + side * (10 + i % 3 * 10), size.y * 0.27 + i * 60)
			Art.ellipse(self, p, Vector2(43 + i % 3 * 9, 45), Color(0.57, 0.69, 0.47, 0.07))
	# Fine meadow flecks behind the island; deterministic and sparse.
	for i in range(42):
		var x: float = fmod(i * 73.7, size.x)
		var y: float = size.y * (0.26 + fmod(i * 0.137, 0.44))
		draw_line(Vector2(x, y), Vector2(x + 2, y - 3), Color(0.39, 0.53, 0.30, 0.10), 1, true)
