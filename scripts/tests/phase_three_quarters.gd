extends SceneTree
const Model = preload("res://scripts/world/world_model.gd")
const Record = preload("res://scripts/world/object_record.gd")
const Definition = preload("res://scripts/world/object_definition.gd")
const Store = preload("res://scripts/world/snapshot_store.gd")
const WORLD = preload("res://resources/world/default.tres")
var failures: int = 0
var assertions: int = 0
var service: Node
var settings: Node
func check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for frame in range(6):
		await process_frame
func record(id: StringName, cell: Vector2i, definition_id: StringName = &"garden_plot") -> RefCounted:
	var object := Record.new()
	object.id = id
	object.definition_id = definition_id
	object.cell = cell
	return object
func write_raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
func clean(path: String) -> void:
	for file in [path, path + ".tmp", path.get_basename() + ".backup.json", path.get_basename() + ".backup.json.tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
func touch(id: int, point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = down
	root.push_input(event, true)
func drag(id: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = point
	root.push_input(event, true)
func mouse(point: Vector2, down: bool, button: int = MOUSE_BUTTON_LEFT, device: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.pressed = down
	event.button_index = button
	event.device = device
	root.push_input(event, true)
func run() -> void:
	create_timer(30).timeout.connect(func() -> void:
		push_error("Test watchdog: incomplete test run")
		quit(1))
	service = root.get_node("WorldService")
	settings = root.get_node("SettingsManager")
	var model := Model.new(WORLD)
	check(model.populate_starter(), "starter region loads from Resource")
	var ids: Array[StringName] = model.ids_of_kind("plot")
	check(ids.size() == 9, "only starter fixture requires nine plots")
	for n in range(ids.size()):
		var object: RefCounted = model.get_object(ids[n])
		var expected := Vector2((n % 3 - n / 3) * 160, (n % 3 + n / 3 - 2) * 128)
		check(model.grid.cell_to_world(object.cell).is_equal_approx(expected), "legacy starter center " + String(object.id))
		check(String(object.id) == "starter_plot_%02d" % (n + 1), "stable ID lexical order")
	for u in [-101, -17, -1, 0, 1, 17, 101]:
		for v in [-101, -17, -1, 0, 1, 17, 101]:
			var cell := Vector2i(u, v)
			check(model.grid.world_to_cell(model.grid.cell_to_world(cell)) == cell, "grid inverse positive/negative")
			var chunk: Vector2i = model.grid.chunk_of(cell)
			var local: Vector2i = cell - chunk * 16
			check(local.x >= 0 and local.x < 16 and local.y >= 0 and local.y < 16, "floor-based negative chunk addressing")
	# Large record sets are data-only fixtures; no large game map is created.
	var source: Resource = WORLD.duplicate()
	var copied_regions: Array[Resource] = [WORLD.regions[0].duplicate()]
	source.regions = copied_regions
	source.object_definitions = WORLD.object_definitions.duplicate()
	source.regions[0].bounds = Rect2i(-500, -500, 1000, 1000)
	for amount in [0, 9, 37, 1000]:
		var arbitrary := Model.new(source)
		arbitrary.unlocked_regions.append(source.starter_region_id)
		for i in range(amount):
			check(arbitrary.place(record(StringName("arbitrary_%04d" % i), Vector2i(i % 40 - 20, i / 40 - 12))), "arbitrary object count placement")
		var data: Dictionary = arbitrary.to_data()
		data.objects.reverse()
		var loaded := Model.new(source)
		check(loaded.load_data(data) and loaded.objects.size() == amount, "unordered snapshot, dynamic count %d" % amount)
		check(loaded.to_data() == arbitrary.to_data(), "stable IDs survive reordered serialization")
	# Generic placement, occupancy layers and rotated cross-chunk footprints.
	var building := Definition.new()
	building.definition_id = &"test_building"
	building.kind = "building"
	building.footprint = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
	source.object_definitions.append(building)
	for kind in ["plant", "decoration"]:
		var content := Definition.new()
		content.definition_id = StringName("test_" + kind)
		content.kind = kind
		content.occupancy_layer = StringName(kind)
		source.object_definitions.append(content)
	var placement := Model.new(source)
	placement.unlocked_regions.append(source.starter_region_id)
	var house := record(&"building_unique", Vector2i(17, 0), &"test_building")
	house.rotation = 1
	check(placement.place(house), "rotated 2x3 building placement")
	check(placement.occupied_cells(house).size() == 6, "all footprint cells reserved")
	check(placement.sort_anchor(house).y == placement.grid.cell_to_world(Vector2i(17, 1)).y, "large objects sort at their lowest footprint anchor")
	check(not placement.place(record(&"collision", Vector2i(15, 0))), "cross-chunk collision rejected")
	check(placement.objects_in_cells(Rect2i(15, 0, 4, 2)) == [&"building_unique"], "one owner through multiple cells/chunks")
	check(placement.place(record(&"free_plot", Vector2i.ZERO)), "plot category")
	check(placement.place(record(&"plant_attachment", Vector2i.ZERO, &"test_plant")), "reserved plant category has separate occupancy layer")
	check(placement.place(record(&"decoration_attachment", Vector2i.ZERO, &"test_decoration")), "decoration category")
	check(not placement.place(record(&"free_plot", Vector2i(4, 4))), "duplicate stable ID rejected")
	check(not placement.place(record(&"locked", Vector2i(1000, 1000))), "locked/outside region rejected")
	check(not placement.move(&"building_unique", Vector2i.ZERO, 0), "occupied move rejected")
	check(placement.get_object(&"building_unique").cell == Vector2i(17, 0), "failed move retains old coordinates")
	check(placement.move(&"building_unique", Vector2i(20, 0), 0), "move preserves stable ID")
	check(placement.remove(&"building_unique") and placement.place(record(&"after_remove", Vector2i(20, 0))), "removal frees footprint")
	var invalid: Dictionary = model.to_data()
	invalid.objects.append(invalid.objects[0].duplicate(true))
	var original: Dictionary = model.to_data()
	check(not model.load_data(invalid) and model.to_data() == original, "invalid snapshot cannot partially replace model")
	# Versioned atomic store, backup recovery, missing migration, future protection.
	var path: String = "user://qa_world_075_store.json"
	clean(path)
	var store := Store.new(path)
	var valid: Callable = func(data: Dictionary) -> bool: return Model.new(WORLD).load_data(data)
	check(store.load_snapshot(valid).is_empty() and store.status == "new", "fresh store")
	check(store.commit(original), "initial atomic snapshot")
	var next: Dictionary = original.duplicate(true)
	next.generation = 1
	check(store.commit(next), "second generation and backup")
	check(not FileAccess.file_exists(path + ".tmp"), "temporary file replaced")
	var restored := Store.new(path)
	check(restored.load_snapshot(valid).generation == 1, "latest generation loads")
	write_raw(path, "{broken")
	var recovered := Store.new(path)
	check(recovered.load_snapshot(valid).generation == 0 and recovered.status == "recovered", "corrupt primary restores whole prior snapshot")
	write_raw(recovered.backup_path(), "{also broken")
	var blocked := Store.new(path)
	check(blocked.load_snapshot(valid).is_empty() and blocked.status == "blocked", "two invalid files block writes")
	check(not blocked.commit(original) and FileAccess.get_file_as_string(path) == "{broken", "no silent overwrite of corrupt data")
	var future: Dictionary = original.duplicate(true)
	future.schema_version = 2
	write_raw(path, JSON.stringify(future))
	write_raw(store.backup_path(), JSON.stringify(original))
	var newer := Store.new(path)
	check(newer.load_snapshot(valid).is_empty() and newer.status == "blocked", "future schema never downgraded through backup")
	var legacy: Dictionary = original.duplicate(true)
	legacy.schema_version = 0
	var migrator := Store.new(path)
	check(migrator.migrate(legacy).is_empty(), "unknown historical version requires explicit migration")
	migrator.register_migration(0, func(data: Dictionary) -> Dictionary:
		data.schema_version = 1
		return data)
	check(migrator.migrate(legacy) == original and legacy.schema_version == 0, "registered migration preserves IDs and source")
	var bad_path := Store.new("user://missing_world_directory_075/snapshot.json")
	check(not bad_path.commit(original), "actual I/O failure returns safely")
	clean(path)
	# Test actual scene, camera/input separation and model transactions.
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	var farm := current_scene
	var hud: Control = farm.hud
	var world: Node2D = farm.world
	var rig: Node2D = farm.camera_rig
	var input: Node = farm.input_router
	var hud_rect: Rect2 = hud.context_card.get_global_rect()
	check(farm.hud_layer.layer == 10 and hud.get_parent() is CanvasLayer, "HUD in independent CanvasLayer")
	check(world.object_root.y_sort_enabled, "shared YSort across regions")
	var fixed_anchor: Vector2 = world.view_roots[&"starter_plot_05"].position
	world.selection_elapsed = 0.09
	world._apply_bounce()
	check(world.view_roots[&"starter_plot_05"].position == fixed_anchor, "animation cannot change depth-sort anchor")
	var changes: Dictionary = {"count": 0}
	world.plot_selected.connect(func(_id: StringName) -> void: changes.count += 1)
	for dimensions in [Vector2i(390, 844), Vector2i(430, 932)]:
		root.size = dimensions
		await settle()
		farm._focus_garden()
		await settle()
		for id in world.model.ids_of_kind("plot"):
			var point: Vector2 = world.screen_position(id)
			touch(1, point, true)
			touch(1, point, false)
			check(world.selected_id == id and hud.selected_plot_id == id, "tap selects stable ID at both sizes")
	root.size = Vector2i(390, 844)
	farm._focus_garden()
	await settle()
	world.select_plot(&"starter_plot_01")
	var center: Vector2 = world.screen_position(&"starter_plot_05")
	hud_rect = hud.context_card.get_global_rect()
	var before_focus: Vector2 = rig.focus
	touch(1, center, true)
	check(world.selected_id == &"starter_plot_01", "press alone cannot select")
	drag(1, center + Vector2(40, 20))
	touch(1, center + Vector2(40, 20), false)
	check(world.selected_id == &"starter_plot_01" and rig.focus != before_focus, "one-finger pan never taps")
	check(hud.context_card.get_global_rect().is_equal_approx(hud_rect), "camera pan leaves HUD fixed")
	farm._focus_garden()
	await settle()
	world.select_plot(&"starter_plot_01")
	center = world.screen_position(&"starter_plot_05")
	touch(1, center, true)
	drag(1, center + Vector2(3, 1))
	touch(1, center + Vector2(3, 1), false)
	check(world.selected_id == &"starter_plot_05", "small finger jitter remains a tap")
	world.select_plot(&"starter_plot_01")
	center = world.screen_position(&"starter_plot_05")
	var held_world: Vector2 = rig.screen_to_world(center)
	touch(1, center - Vector2(40, 0), true)
	touch(2, center + Vector2(40, 0), true)
	drag(2, center + Vector2(80, 0))
	check(is_equal_approx(rig.relative_zoom, 1.5), "two-finger distance controls zoom")
	check(rig.screen_to_world(center + Vector2(20, 0)).distance_to(held_world) < 0.1, "pinch preserves world anchor under moving centroid")
	touch(2, center + Vector2(80, 0), false)
	touch(1, center - Vector2(40, 0), false)
	check(world.selected_id == &"starter_plot_01", "pinch release cannot select")
	check(hud.context_card.get_global_rect().is_equal_approx(hud_rect), "pinch leaves HUD fixed")
	farm._focus_garden()
	await settle()
	world.select_plot(&"starter_plot_01")
	center = world.screen_position(&"starter_plot_05")
	mouse(center, true)
	var motion := InputEventMouseMotion.new()
	motion.position = center + Vector2(50, 10)
	root.push_input(motion, true)
	mouse(motion.position, false)
	check(world.selected_id == &"starter_plot_01" and rig.focus != Vector2.ZERO, "mouse drag pans without selection")
	farm._focus_garden()
	await settle()
	center = world.screen_position(&"starter_plot_05")
	mouse(center, true, MOUSE_BUTTON_WHEEL_UP)
	check(rig.relative_zoom > 1, "mouse wheel zoom")
	rig.zoom_at(0.00001, center)
	check(is_equal_approx(rig.relative_zoom, rig.MIN_RELATIVE_ZOOM), "minimum zoom clamp")
	world.select_plot(&"starter_plot_01")
	touch(1, center, true)
	touch(1, center, false)
	check(not rig.is_overview() and world.selected_id == &"starter_plot_01", "overview tap zooms before enabling tiny targets")
	rig.zoom_at(1000000, center)
	check(is_equal_approx(rig.relative_zoom, rig.MAX_RELATIVE_ZOOM), "maximum zoom clamp")
	rig.pan_screen(Vector2(1000000, -1000000))
	check(world.screen_bounds().intersects(rig.play_area), "camera bounds prevent losing the garden")
	farm._focus_garden()
	await settle()
	var stable_focus: Vector2 = rig.focus
	var gear: Vector2 = hud.settings_button.get_global_rect().get_center()
	touch(7, gear, true)
	drag(7, center)
	touch(7, center, false)
	check(rig.focus == stable_focus, "UI-owned touch cannot turn into world drag")
	hud._open_settings()
	await settle()
	touch(1, center, true)
	drag(1, center + Vector2(40, 0))
	touch(1, center + Vector2(40, 0), false)
	check(rig.focus == stable_focus, "modal blocks camera gestures")
	hud._close_dialog()
	await settle()
	center = world.screen_position(&"starter_plot_05")
	touch(1, center, true)
	input._notification(NOTIFICATION_APPLICATION_PAUSED)
	touch(1, center, false)
	check(input.touches.is_empty(), "pause cancels pending gestures")
	var count_before: int = changes.count
	touch(1, center, true)
	touch(1, center, false)
	mouse(center, true, MOUSE_BUTTON_LEFT, InputEvent.DEVICE_ID_EMULATION)
	mouse(center, false, MOUSE_BUTTON_LEFT, InputEvent.DEVICE_ID_EMULATION)
	check(changes.count == count_before + 1, "emulated mouse cannot duplicate touch selection")
	# Transactions use separate storage and never touch saved language settings.
	var saved_path: String = service.store.path
	var test_path: String = "user://qa_world_075_service.json"
	clean(test_path)
	var preferences: String = FileAccess.get_file_as_string(settings.settings_path)
	service.use_storage(test_path)
	check(service.place_object(record(&"independent_id", Vector2i(4, 4))), "service places arbitrary ID")
	check(service.move_object(&"independent_id", Vector2i(-1, -1)), "service moves by ID")
	service.reload_world()
	check(service.model.get_object(&"independent_id").cell == Vector2i(-1, -1), "saved ID and negative coordinates restored")
	var prior: Dictionary = service.model.to_data()
	var disk: String = FileAccess.get_file_as_string(test_path)
	service.store.simulate_write_failure = true
	check(not service.move_object(&"independent_id", Vector2i(-2, -2)), "failed commit rejected")
	check(service.model.to_data() == prior and FileAccess.get_file_as_string(test_path) == disk, "failed commit keeps model and disk unchanged")
	service.store.simulate_write_failure = false
	service.reload_world()
	var locale: String = settings.locale
	for code in settings.SUPPORTED:
		settings.set_language(code)
		check(service.model.to_data() == prior and FileAccess.get_file_as_string(test_path) == disk, "language never rewrites map " + code)
	settings.set_language(locale)
	check(FileAccess.get_file_as_string(settings.settings_path) == preferences, "world transaction never changes preferences")
	service.use_storage(saved_path)
	clean(test_path)
	print("PHASE 0.75: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
