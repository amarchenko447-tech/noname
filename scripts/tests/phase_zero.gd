extends SceneTree

var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/boot/boot.tscn")
	for frame in range(5):
		await process_frame
	var farm := current_scene
	var garden: Control = farm.hud
	var world: Node2D = farm.world
	var plot_ids: Array[StringName] = garden.model.ids_of_kind("plot")
	check(garden != null and farm.name == "Garden", "boot transitions to garden")
	if garden == null:
		quit(1)
		return
	check(plot_ids.size() == 9, "exactly nine plots")
	var ids: Dictionary = {}
	for id in plot_ids:
		var plot: RefCounted = garden.model.get_object(id)
		ids[plot.id] = true
		check(garden.model.definitions[plot.definition_id].kind == "plot", "starter plot %s" % plot.id)
	check(ids.size() == 9, "unique plot IDs")
	for index in range(9):
		check(world.plot_at(world.centers[plot_ids[index]]) == plot_ids[index], "hit target %d" % index)
	check(world.plot_at(Vector2(700, 700)) == &"", "outside hit rejected")
	world.plot_selected.emit(&"starter_plot_05")
	check(garden.selected_plot_id == &"starter_plot_05" and "5" in garden.context_title.text, "selection updates context")
	for dimensions in [Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(1170, 2532), Vector2i(1440, 3200), Vector2i(1080, 2106)]:
		root.size = dimensions
		root.content_scale_size = Vector2i(390, 844)
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		for frame in range(4):
			await process_frame
		var viewport_rect: Rect2 = garden.get_global_rect()
		check(garden.safe.get_global_rect().size.x <= viewport_rect.size.x + 1, "HUD fits width %s" % dimensions)
		var bounds: Rect2 = world.screen_bounds()
		check(viewport_rect.encloses(bounds), "island fits %s" % dimensions)
		check(garden.context_body.get_global_rect().end.y < viewport_rect.end.y - 24, "context fits height %s" % dimensions)
		check(bounds.end.y < garden.context_title.get_global_rect().position.y, "garden clear of bottom card %s" % dimensions)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = world.get_global_transform_with_canvas() * world.centers[plot_ids[7]]
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)
	await process_frame
	check(garden.selected_plot_id == plot_ids[7], "real mouse input reaches plot through HUD")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = world.get_global_transform_with_canvas() * world.centers[plot_ids[2]]
	root.push_input(touch, true)
	touch.pressed = false
	root.push_input(touch, true)
	await process_frame
	check(garden.selected_plot_id == plot_ids[2], "real touch input reaches plot through HUD")
	print("PHASE 0: %d failures" % failures)
	quit(0 if failures == 0 else 1)
