extends Node2D
## Static original environmental illustration, cached by CanvasItem.
const Art = preload("res://scripts/ui/garden_drawing.gd")
var grass_points: Array[Vector2] = []
var font: Font = preload("res://assets/fonts/OpenSans-Regular.ttf")

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8412
	for i in range(460):
		var point := Vector2(rng.randf_range(-530, 530), rng.randf_range(-410, 410))
		if absf(point.x) / 535.0 + absf(point.y) / 422.0 < 0.94:
			grass_points.append(point)

func _bush(point: Vector2, radius: float, color: Color) -> void:
	Art.ellipse(self, point + Vector2(10, 10), Vector2(radius * 1.3, radius * 0.42), Color(0.12, 0.26, 0.14, 0.13))
	for i in range(7):
		var offset := Vector2(cos(i * 2.2) * radius * 0.55, sin(i * 2.2) * radius * 0.3 - radius * 0.35)
		draw_circle(point + offset, radius * 0.62, color.darkened(0.14) if i < 3 else color, true, -1, true)
	for i in range(8):
		var offset := Vector2(cos(i * 2.4) * radius * 0.7, sin(i * 1.7) * radius * 0.4 - radius * 0.45)
		Art.leaf(self, point + offset, Vector2(10, 5), color.lightened(0.16), i * 0.6)

func _fence(start: Vector2, finish: Vector2, posts: int) -> void:
	var direction := finish - start
	for height in [24, 59]:
		draw_line(start - Vector2(0, height), finish - Vector2(0, height), Color("946c48"), 14, true)
		draw_line(start - Vector2(2, height + 5), finish - Vector2(2, height + 5), Color("e3c18d"), 7, true)
	for i in range(posts):
		var point := start + direction * i / float(posts - 1)
		Art.ellipse(self, point + Vector2(14, 8), Vector2(19, 7), Color(0.2, 0.3, 0.15, 0.13))
		var post := PackedVector2Array([point + Vector2(-8, 5), point + Vector2(10, 5), point + Vector2(10, -80), point + Vector2(0, -90), point + Vector2(-8, -80)])
		draw_colored_polygon(post, Color("cba371"))
		draw_line(point + Vector2(-5, -77), point + Vector2(-5, 0), Color("f1d3a1"), 4, true)
		draw_circle(point + Vector2(0, -57), 2.5, Color("886646"), true, -1, true)

func _mushrooms(point: Vector2) -> void:
	for i in range(3):
		var p := point + Vector2(i * 21 - 18, (i % 2) * 12)
		var radius: float = 19 if i == 0 else 12
		Art.ellipse(self, p + Vector2(4, 7), Vector2(radius, 5), Color(0.18, 0.25, 0.13, 0.12))
		draw_line(p, p - Vector2(0, radius), Color("f5e4bd"), 9, true)
		Art.ellipse(self, p - Vector2(0, radius), Vector2(radius, radius * 0.58), Color("d27c65"))
		Art.leaf(self, p - Vector2(radius * 0.25, radius * 1.15), Vector2(radius * 0.65, radius * 0.23), Color("efb28a"), -0.1)
		draw_circle(p - Vector2(radius * 0.35, radius), 3, Color("fff0ce"), true, -1, true)
		draw_circle(p - Vector2(-radius * 0.3, radius * 0.95), 2, Color("fff0ce"), true, -1, true)

func _draw() -> void:
	# Feathered contact shadow, turf depth and warm grass crown.
	for i in range(6):
		Art.ellipse(self, Vector2(14, 44 + i * 2), Vector2(536 + i * 5, 362 + i * 3), Color(0.22, 0.36, 0.23, 0.014))
	draw_colored_polygon(Art.diamond(Vector2(0, 30), Vector2(540, 423)), Color("809667"))
	draw_colored_polygon(Art.diamond(Vector2(0, 18), Vector2(540, 423)), Color("9dbb79"))
	draw_colored_polygon(Art.diamond(Vector2.ZERO, Vector2(540, 423)), Color("9dc987"))
	draw_colored_polygon(Art.diamond(Vector2(-4, -9), Vector2(525, 407)), Color("b1d597"))
	Art.outline(self, Art.diamond(Vector2(0, -6), Vector2(534, 418)), Color("cee2aa"), 5)
	for i in range(grass_points.size()):
		var p := grass_points[i]
		if i % 6 == 0:
			Art.ellipse(self, p, Vector2(14 + i % 17, 5 + i % 6), Color(0.40, 0.60, 0.30, 0.10))
		else:
			draw_line(p, p + Vector2(4, -5), Color("93bc77") if i % 2 == 0 else Color("c6dda1"), 2, true)
	# Soft meadow patches beyond the planted beds.
	_bush(Vector2(-394, -143), 71, Color("78a76d"))
	_bush(Vector2(387, -161), 72, Color("72a176"))
	_bush(Vector2(-176, -341), 53, Color("8eb675"))
	_bush(Vector2(176, -341), 46, Color("89ad72"))
	_fence(Vector2(-355, -151), Vector2(-40, -402), 5)
	_fence(Vector2(40, -402), Vector2(355, -151), 5)
	# Taller botanical silhouettes behind the fence.
	for side in [-1, 1]:
		var base := Vector2(side * 367, -197)
		draw_line(base, base - Vector2(0, 136), Color("8b7654"), 13, true)
		_bush(base - Vector2(0, 101), 65, Color("679971") if side < 0 else Color("82aa78"))
		_bush(base - Vector2(16, 147), 49, Color("8cb77b"))
	# Hand-carved welcome sign, readable word and leaf mark.
	draw_line(Vector2(0, -403), Vector2(0, -507), Color("a27b51"), 16, true)
	var sign := Art.rounded_polygon(PackedVector2Array([Vector2(-94, -503), Vector2(87, -503), Vector2(105, -466), Vector2(87, -429), Vector2(-94, -429)]), 0.12)
	draw_colored_polygon(sign, Color("a47b50"))
	var inner := sign.duplicate()
	for i in range(inner.size()):
		inner[i] += Vector2(-3, -5)
	draw_colored_polygon(inner, Color("e4c38e"))
	Art.outline(self, inner, Color("f3d9a6"), 3)
	var sign_text: String = tr("UI_GARDEN").to_upper()
	var text_width: float = font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	draw_string(font, Vector2(-text_width * 0.5, -454), sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("67553a"))
	draw_circle(Vector2(-81, -471), 3, Color("a88155"), true, -1, true)
	# Front path and border: light stones and blooming little pockets.
	for i in range(5):
		var p := Vector2((i % 2) * 13 - 6, 364 + i * 20)
		Art.ellipse(self, p + Vector2(4, 4), Vector2(31 - i * 2, 12), Color("91aa72"))
		Art.ellipse(self, p, Vector2(29 - i * 2, 11), Color("e8d9ad"))
		Art.leaf(self, p - Vector2(3, 3), Vector2(21 - i, 5), Color("f4e7c4"), 0.05)
	for p in [Vector2(-418, 89), Vector2(421, 78), Vector2(-246, 265), Vector2(252, 260)]:
		_bush(p, 38, Color("85b77a"))
		for j in range(5):
			var flower_pos: Vector2 = p + Vector2(cos(j * 2.1) * 26, sin(j * 2.1) * 14 - 22)
			Art.flower(self, flower_pos, Color("fff5dc") if j % 2 == 0 else Color("efb2ac"), 7)
	_mushrooms(Vector2(-326, 213))
	_mushrooms(Vector2(335, 197))
	for p in [Vector2(-474, -2), Vector2(466, 15), Vector2(141, 330), Vector2(-157, 323)]:
		Art.ellipse(self, p + Vector2(5, 4), Vector2(24, 11), Color("94ad77"))
		Art.leaf(self, p, Vector2(23, 12), Color("c7cbb0"), -0.2)
		Art.leaf(self, p - Vector2(3, 4), Vector2(16, 6), Color("e4e2c7"), -0.2)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()
