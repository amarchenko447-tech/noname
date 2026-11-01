class_name GardenDrawing
extends RefCounted
## Shared original vector geometry. Rounded silhouettes, no external art.
static func rounded_polygon(vertices: PackedVector2Array, roundness: float = 0.12) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(vertices.size()):
		var corner := vertices[i]
		var start := corner.lerp(vertices[(i - 1 + vertices.size()) % vertices.size()], roundness)
		var finish := corner.lerp(vertices[(i + 1) % vertices.size()], roundness)
		for step in range(7):
			var t: float = step / 6.0
			result.append(start.lerp(corner, t).lerp(corner.lerp(finish, t), t))
	return result

static func diamond(center: Vector2, half_size: Vector2) -> PackedVector2Array:
	return rounded_polygon(PackedVector2Array([center + Vector2(0, -half_size.y), center + Vector2(half_size.x, 0), center + Vector2(0, half_size.y), center + Vector2(-half_size.x, 0)]))

static func ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		points.append(center + Vector2(cos(TAU * i / 32.0), sin(TAU * i / 32.0)) * radius)
	canvas.draw_colored_polygon(points, color)

static func outline(canvas: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, color, width, true)

static func leaf(canvas: CanvasItem, point: Vector2, radius: Vector2, color: Color, tilt: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle: float = TAU * i / 20.0
		points.append(point + Vector2(cos(angle) * radius.x, sin(angle) * radius.y).rotated(tilt))
	canvas.draw_colored_polygon(points, color)

static func flower(canvas: CanvasItem, point: Vector2, color: Color, radius: float = 8.0) -> void:
	for petal in range(5):
		canvas.draw_circle(point + Vector2.from_angle(TAU * petal / 5.0) * radius, radius * 0.64, color, true, -1, true)
	canvas.draw_circle(point, radius * 0.46, Color("edba5d"), true, -1, true)
