extends Node2D
## Original vector placeholders; nine disjoint diamond hit regions.
signal plot_selected(index: int)
var centers: Array[Vector2] = []
var selected: int = -1
const TILE = [Vector2(0, -72), Vector2(146, 0), Vector2(0, 72), Vector2(-146, 0)]

func _ready() -> void:
	for row in range(3):
		for col in range(3):
			centers.append(Vector2((col - row) * 160, (col + row - 2) * 83))
	queue_redraw()

func _diamond(center: Vector2, width: float, height: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -height), center + Vector2(width, 0), center + Vector2(0, height), center + Vector2(-width, 0)]), color)

func _draw() -> void:
	# Soft island shadow, earth depth, grass top and inset lawn.
	draw_set_transform(Vector2(0, 85), 0, Vector2(1, 0.48))
	draw_circle(Vector2.ZERO, 500, Color(0.22, 0.38, 0.28, 0.10))
	draw_set_transform(Vector2.ZERO)
	_diamond(Vector2(0, 50), 514, 296, Color("9b8060"))
	_diamond(Vector2(0, 25), 514, 296, Color("639c69"))
	_diamond(Vector2.ZERO, 514, 296, Color("8bcf8a"))
	_diamond(Vector2(0, -7), 478, 269, Color("a4d995"))
	for i in range(centers.size()):
		var point := centers[i]
		_diamond(point + Vector2(0, 12), 148, 74, Color("785640"))
		_diamond(point, 148, 74, Color("bf9470"))
		_diamond(point, 135, 64, Color("9a6a52"))
		_diamond(point + Vector2(0, -4), 122, 53, Color("aa795c"))
		for furrow in range(-2, 3):
			var x: float = furrow * 26.0
			draw_line(point + Vector2(x - 28, -14), point + Vector2(x + 28, 14), Color("916348"), 4, true)
		if i == selected:
			var outline := PackedVector2Array()
			for vertex in TILE:
				outline.append(point + vertex)
			outline.append(point + TILE[0])
			draw_polyline(outline, Color("fff3bd"), 7, true)
	# Border botanicals, stones and tiny daisies outside all hit targets.
	for i in range(18):
		var angle: float = TAU * i / 18.0
		var point := Vector2(cos(angle) * 447, sin(angle) * 247)
		if absf(point.x) + absf(point.y) * 1.75 > 484:
			continue
		draw_circle(point, 7, Color("6fae78"))
		draw_line(point, point + Vector2(0, -15), Color("4e865d"), 3, true)
		if i % 3 == 0:
			for petal in range(5):
				var direction := Vector2.from_angle(TAU * petal / 5.0)
				draw_circle(point + Vector2(0, -19) + direction * 7, 5, Color("fff7e8"))
			draw_circle(point + Vector2(0, -19), 4, Color("f5c45e"))
	for point in [Vector2(-380, 125), Vector2(375, 128), Vector2(90, 263)]:
		draw_set_transform(point, -0.2, Vector2(1.5, 0.7))
		draw_circle(Vector2.ZERO, 12, Color("dfddc1"))
		draw_circle(Vector2(-2, -3), 8, Color("f4efda"))
	draw_set_transform(Vector2.ZERO)

func plot_at(point: Vector2) -> int:
	for i in range(centers.size()):
		var relative := point - centers[i]
		if absf(relative.x) / 146.0 + absf(relative.y) / 72.0 <= 1.0:
			return i
	return -1

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var screen_position := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		screen_position = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		screen_position = event.position
	if pressed:
		var index := plot_at(get_global_transform_with_canvas().affine_inverse() * screen_position)
		if index >= 0:
			selected = index
			queue_redraw()
			plot_selected.emit(index)
			get_viewport().set_input_as_handled()
