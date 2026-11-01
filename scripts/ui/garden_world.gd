extends Node2D
## Scene coordinator; static scenery, independent soil nodes and lightweight ambience.
signal plot_selected(index: int)
const Art = preload("res://scripts/ui/garden_drawing.gd")
const EnvironmentArt = preload("res://scripts/ui/garden_environment.gd")
const Ambience = preload("res://scripts/ui/garden_ambience.gd")
const Bed = preload("res://scripts/ui/garden_bed.gd")
const BOUNCE_DURATION: float = 0.18
var centers: Array[Vector2] = []
var beds: Array[Node2D] = []
var selected: int = -1
var touch_half_size: float = 72.0
var ambience: Node2D
var reduced_motion: bool = false
var animate: bool = true
var animation_time: float = 0.0
var selection_elapsed: float = 1.0
var _accumulator: float = 0.0

func _ready() -> void:
	var environment := EnvironmentArt.new()
	environment.z_index = -10
	add_child(environment)
	for row in range(3):
		for col in range(3):
			var point := Vector2((col - row) * 160, (col + row - 2) * 128)
			centers.append(point)
			var bed := Bed.new()
			bed.bed_id = row * 3 + col
			bed.position = point
			bed.z_index = int(point.y) + 300
			beds.append(bed)
			add_child(bed)
	ambience = Ambience.new()
	ambience.z_index = 1000
	add_child(ambience)
	z_as_relative = true

func _process(delta: float) -> void:
	if not animate or not is_visible_in_tree() or reduced_motion:
		return
	selection_elapsed += delta
	_accumulator += delta
	if _accumulator >= 1.0 / 30.0:
		animation_time = fmod(animation_time + _accumulator, 60.0)
		_accumulator = 0.0
		_apply_bounce()
		if selected >= 0:
			queue_redraw()

func _apply_bounce() -> void:
	if selected < 0:
		return
	var progress: float = clampf(selection_elapsed / BOUNCE_DURATION, 0, 1)
	var lift: float = sin(progress * PI) if not reduced_motion else 0.0
	beds[selected].position = centers[selected] - Vector2(0, lift * 10)
	beds[selected].scale = Vector2.ONE * (1.0 + lift * 0.035)

func set_motion_reduced(value: bool) -> void:
	reduced_motion = value
	ambience.set_motion_reduced(value)
	_apply_bounce()
	queue_redraw()

func select_plot(index: int) -> void:
	if index < 0 or index >= centers.size():
		return
	if selected >= 0:
		beds[selected].position = centers[selected]
		beds[selected].scale = Vector2.ONE
	selected = index
	selection_elapsed = 0.0
	queue_redraw()
	plot_selected.emit(index)

func _draw() -> void:
	# A narrow outside outline only. It never covers the soil artwork.
	if selected < 0 or centers.is_empty():
		return
	var pulse: float = 0.0 if reduced_motion else (sin(animation_time * TAU / 2.8) + 1) * 0.5
	var point: Vector2 = centers[selected]
	var outline := Art.diamond(point, Vector2(155, 108))
	Art.outline(self, outline, Color(1, 0.91, 0.57, 0.12 + pulse * 0.09), 18)
	Art.outline(self, outline, Color("648654"), 6)
	Art.outline(self, outline, Color(1, 0.97, 0.69, 0.85 + pulse * 0.15), 3)

func plot_at(point: Vector2) -> int:
	# Union visual diamonds with >=48px squares around centers. All candidates
	# are resolved by Euclidean distance; exact ties keep the smaller stable ID.
	var nearest: int = -1
	var best_distance: float = INF
	for i in range(centers.size()):
		var relative := point - centers[i]
		var in_square: bool = maxf(absf(relative.x), absf(relative.y)) <= touch_half_size + 0.01
		var in_diamond: bool = absf(relative.x) / 151.0 + absf(relative.y) / 106.0 <= 1.0
		if in_square or in_diamond:
			var distance: float = relative.length_squared()
			if distance < best_distance - 0.001:
				best_distance = distance
				nearest = i
	return nearest

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
			select_plot(index)
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		set_process(false)
		if is_instance_valid(ambience):
			ambience.set_process(false)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		set_process(true)
		if is_instance_valid(ambience):
			ambience.set_process(true)
