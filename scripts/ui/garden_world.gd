extends Node2D
## WorldView: projects model records, never creates gameplay state or handles input.
signal plot_selected(id: StringName)
const Art = preload("res://scripts/ui/garden_drawing.gd")
const StaticArt = preload("res://scripts/ui/static_art_cache.gd")
const EnvironmentArt = preload("res://scripts/ui/garden_environment.gd")
const Ambience = preload("res://scripts/ui/garden_ambience.gd")
const Bed = preload("res://scripts/ui/garden_bed.gd")
const Plant = preload("res://scripts/ui/plant_visual.gd")
const FONT = preload("res://assets/fonts/OpenSans-Regular.ttf")
const BOUNCE_DURATION: float = 0.18
var model: RefCounted
var centers: Dictionary = {}
var views: Dictionary = {}
var view_roots: Dictionary = {}
var crop_views: Dictionary = {}
var crop_badges: Dictionary = {}
var active_effects: Dictionary = {}
var plant_bumps: Dictionary = {}
var bump_tweens: Dictionary = {}
var harvest_ghosts: Array[Node2D] = []
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
	var environment := StaticArt.new()
	environment.artist_script = EnvironmentArt
	environment.bounds = Rect2(-600,-600,1200,1150)
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
	_clear_ghosts()
	_clear_bumps()
	for view in view_roots.values():
		object_root.remove_child(view)
		view.queue_free()
	views.clear()
	crop_views.clear()
	crop_badges.clear()
	active_effects.clear()
	plant_bumps.clear()
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
		var bed := StaticArt.new()
		bed.artist_script = Bed
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
		animation_time += _accumulator
		_accumulator = 0.0
		if selection_elapsed <= BOUNCE_DURATION + delta or not plant_bumps.is_empty():
			_apply_bounce()
		for id in crop_views:
			crop_views[id].idle_time = animation_time + model.get_object(id).art_seed * 0.13
			crop_views[id].queue_redraw()
		if selected_id != &"":
			queue_redraw()
func _apply_bounce() -> void:
	for id in views:
		var progress: float = clampf(selection_elapsed / BOUNCE_DURATION,0,1)
		var lift: float = sin(progress*PI) * 10 if id == selected_id else 0.0
		var planting: float = sin(float(plant_bumps.get(id,1.0))*PI) * 7
		if reduced_motion:
			lift = 0
			planting = 0
		views[id].position = centers[id] - view_roots[id].position - Vector2(0,lift+planting)
		views[id].scale = Vector2.ONE * (1.0 + lift * 0.0035 + planting * 0.002)
func set_motion_reduced(value: bool) -> void:
	reduced_motion = value
	if value:
		_clear_ghosts()
		_clear_bumps()
	ambience.set_motion_reduced(value)
	for visual in crop_views.values():
		visual.set_reduced_motion(value)
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
		var in_plant: bool = crop_views.has(id) and crop_views[id].stage > 0 and absf(relative.x) <= 74 and relative.y >= -160 and relative.y <= 12
		if in_square or in_diamond or in_plant:
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

func sync_crops() -> void:
	for id in crop_views.keys():
		if not WorldService.gameplay.crops.has(id) or not views.has(id):
			var visual: Node2D = crop_views[id]
			visual.get_parent().remove_child(visual)
			visual.queue_free()
			crop_views.erase(id)
			if crop_badges.has(id):
				crop_badges[id].queue_free()
				crop_badges.erase(id)
			active_effects.erase(id)
			_cancel_bump(id)
	for id in WorldService.gameplay.crops:
		if not views.has(id):
			continue
		var crop: RefCounted = WorldService.gameplay.crops[id]
		var stage: int = crop.stage_at(TimeService.now_utc())
		if not crop_views.has(id):
			var visual := Plant.new()
			visual.set_pose(crop.species_id,stage)
			visual.reduced_motion = reduced_motion
			visual.position = centers[id] - view_roots[id].position + Vector2(0,-9)
			visual.z_index = 1
			view_roots[id].add_child(visual)
			crop_views[id] = visual
			visual.effect_finished.connect(func() -> void:
				if crop_views.get(id) == visual:
					active_effects.erase(id))
			var badge := Label.new()
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.add_theme_font_override("font",FONT)
			badge.add_theme_font_size_override("font_size",42)
			badge.add_theme_color_override("font_color",Color("38553e"))
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var skin := StyleBoxFlat.new()
			skin.bg_color = Color("fff6dd")
			skin.set_corner_radius_all(12)
			badge.add_theme_stylebox_override("normal",skin)
			badge.position = Vector2(-73,57) + centers[id] - view_roots[id].position
			badge.size = Vector2(146,52)
			badge.z_index = 2
			view_roots[id].add_child(badge)
			crop_badges[id] = badge
		elif crop_views[id].stage != stage:
			crop_views[id].set_pose(crop.species_id,stage)
			play_crop_effect(id,&"mature" if stage == 3 else &"grow")
	update_crop_timers()
func update_crop_timers() -> void:
	for id in crop_badges:
		var crop: RefCounted = GameState.crop_at(id)
		if crop == null:
			continue
		crop_badges[id].visible = crop.stage_at(TimeService.now_utc()) != 3
		crop_badges[id].text = SettingsManager.format_countdown(crop.remaining(TimeService.now_utc()))
		crop_badges[id].accessibility_name = tr("GROWING_TIME") % crop_badges[id].text
func play_crop_effect(id: StringName, kind: StringName) -> void:
	if not crop_views.has(id):
		return
	active_effects.erase(id)
	crop_views[id].particles_enabled = active_effects.size() < 3
	if crop_views[id].particles_enabled:
		active_effects[id] = true
	crop_views[id].play_effect(kind)
	if kind == &"plant" and not reduced_motion:
		_cancel_bump(id)
		plant_bumps[id] = 0.0
		var tween := create_tween()
		bump_tweens[id] = tween
		tween.tween_method(func(p: float) -> void:
			plant_bumps[id] = p
			_apply_bounce(),0.0,1.0,0.45)
		tween.tween_callback(func() -> void:
			plant_bumps.erase(id)
			bump_tweens.erase(id))
func harvest_ghost(id: StringName, species: StringName) -> void:
	if not centers.has(id):
		return
	var ghost := Plant.new()
	ghost.set_pose(species,3)
	ghost.show_indicator = false
	ghost.reduced_motion = reduced_motion
	ghost.idle_time = animation_time + model.get_object(id).art_seed * 0.13
	ghost.position = centers[id] + Vector2(0,-9)
	ghost.z_index = 4
	add_child(ghost)
	harvest_ghosts.append(ghost)
	var tween := create_tween()
	ghost.set_meta("effect_tween",tween)
	if not reduced_motion:
		tween.tween_property(ghost,"position",ghost.position-Vector2(0,24),0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ghost,"scale",Vector2.ONE*1.08,0.2)
		tween.tween_property(ghost,"modulate:a",0.0,0.4)
		tween.parallel().tween_property(ghost,"scale",Vector2.ONE*0.25,0.4)
	else:
		tween.tween_property(ghost,"modulate:a",0.0,0.12)
	tween.tween_callback(func() -> void:
		harvest_ghosts.erase(ghost)
		ghost.queue_free())

func _clear_ghosts() -> void:
	for ghost in harvest_ghosts:
		if is_instance_valid(ghost):
			var tween: Tween = ghost.get_meta("effect_tween")
			if is_instance_valid(tween):
				tween.kill()
			ghost.queue_free()
	harvest_ghosts.clear()

func _cancel_bump(id: StringName) -> void:
	if bump_tweens.has(id):
		bump_tweens[id].kill()
		bump_tweens.erase(id)
	plant_bumps.erase(id)
func _clear_bumps() -> void:
	for id in bump_tweens.keys():
		_cancel_bump(id)
	plant_bumps.clear()
