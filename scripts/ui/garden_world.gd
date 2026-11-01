extends Node2D
## WorldView: projects model records, never creates gameplay state or handles input.
signal plot_selected(id: StringName)
const Art = preload("res://scripts/ui/garden_drawing.gd")
const EnvironmentArt = preload("res://scripts/ui/garden_environment.gd")
const Ambience = preload("res://scripts/ui/garden_ambience.gd")
const Bed = preload("res://scripts/ui/garden_bed.gd")
const BOUNCE_DURATION: float = 0.18
var model: RefCounted
var centers: Dictionary = {}
var views: Dictionary = {}
var view_roots: Dictionary = {}
var object_root: Node2D
var selected_id: StringName = &""
var touch_half_size: float = 72.0
var ambience: Node2D
var reduced_motion: bool = false
var animate: bool = true
var animation_time: float = 0.0
var selection_elapsed: float = 1.0
var _accumulator: float = 0.0
func _ready() -> void:
	var environment := EnvironmentArt.new()
	environment.z_index = -2
	add_child(environment)
	object_root = Node2D.new()
	object_root.name = "WorldObjects"
	object_root.y_sort_enabled = true
	object_root.z_index = 1
	add_child(object_root)
	ambience = Ambience.new()
	ambience.z_index = 2
	add_child(ambience)
	rebuild(model)
func rebuild(source: RefCounted) -> void:
	model = source
	for view in view_roots.values():
		object_root.remove_child(view)
		view.queue_free()
	views.clear()
	view_roots.clear()
	centers.clear()
	for id in model.ids_of_kind("plot"):
		var record: RefCounted = model.get_object(id)
		if model.definitions[record.definition_id].visual_key != &"garden_bed":
			continue
		var point: Vector2 = model.grid.cell_to_world(record.cell)
		centers[id] = point
		var root := Node2D.new()
		root.position = model.sort_anchor(record)
		object_root.add_child(root)
		view_roots[id] = root
		var bed := Bed.new()
		bed.art_seed = record.art_seed
		bed.position = point - root.position
		# One shared YSort across all future regions; never world_y as z_index.
		bed.z_index = 0
		root.add_child(bed)
		views[id] = bed
	if not views.has(selected_id):
		selected_id = &""
	queue_redraw()
func _process(delta: float) -> void:
	if not animate or not is_visible_in_tree() or reduced_motion:
		return
	selection_elapsed += delta
	_accumulator += delta
	if _accumulator >= 1.0 / 30.0:
		animation_time = fmod(animation_time + _accumulator, 60.0)
		_accumulator = 0.0
		_apply_bounce()
		if selected_id != &"":
			queue_redraw()
func _apply_bounce() -> void:
	if not views.has(selected_id):
		return
	var progress: float = clampf(selection_elapsed / BOUNCE_DURATION, 0, 1)
	var lift: float = sin(progress * PI) if not reduced_motion else 0.0
	views[selected_id].position = centers[selected_id] - view_roots[selected_id].position - Vector2(0, lift * 10)
	views[selected_id].scale = Vector2.ONE * (1.0 + lift * 0.035)
func set_motion_reduced(value: bool) -> void:
	reduced_motion = value
	ambience.set_motion_reduced(value)
	_apply_bounce()
	queue_redraw()
func select_plot(id: StringName) -> void:
	if not views.has(id):
		return
	if views.has(selected_id):
		views[selected_id].position = centers[selected_id] - view_roots[selected_id].position
		views[selected_id].scale = Vector2.ONE
	selected_id = id
	selection_elapsed = 0.0
	queue_redraw()
	plot_selected.emit(id)
func _draw() -> void:
	if not centers.has(selected_id):
		return
	var pulse: float = 0 if reduced_motion else (sin(animation_time * TAU / 2.8) + 1) * 0.5
	var outline := Art.diamond(centers[selected_id], Vector2(155, 108))
	Art.outline(self, outline, Color(1, 0.91, 0.57, 0.12 + pulse * 0.09), 18)
	Art.outline(self, outline, Color("648654"), 6)
	Art.outline(self, outline, Color(1, 0.97, 0.69, 0.85 + pulse * 0.15), 3)
func plot_at(point: Vector2) -> StringName:
	var nearest: StringName = &""
	var best_distance: float = INF
	var radius := Vector2.ONE * maxf(160, touch_half_size + 1)
	for id in model.objects_in_world_rect(Rect2(point - radius, radius * 2)):
		if not centers.has(id):
			continue
		var relative: Vector2 = point - centers[id]
		var in_square: bool = maxf(absf(relative.x), absf(relative.y)) <= touch_half_size + 0.01
		var in_diamond: bool = absf(relative.x) / 151.0 + absf(relative.y) / 106.0 <= 1.0
		if in_square or in_diamond:
			var distance: float = relative.length_squared()
			# Query returns stable lexicographic IDs, providing a deterministic tie.
			if distance < best_distance - 0.001:
				nearest = id
				best_distance = distance
	return nearest
func screen_position(id: StringName) -> Vector2:
	return get_global_transform_with_canvas() * centers[id]
func screen_bounds() -> Rect2:
	var transform := get_global_transform_with_canvas()
	return transform * model.navigation_bounds()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		set_process(false)
		if is_instance_valid(ambience):
			ambience.set_process(false)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		set_process(true)
		if is_instance_valid(ambience):
			ambience.set_process(true)
