extends SceneTree
## Actual screen-touch and mouse events, not a simulated screenshot mockup.
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for frame in range(8):
		await process_frame
func finger(id: int, point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = down
	root.push_input(event, true)
func move_finger(id: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = point
	root.push_input(event, true)
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A rendering display is required")
		quit(1)
		return
	var settings := root.get_node("SettingsManager")
	settings.load_preferences("user://qa_navigation_preferences.cfg", "ru_RU")
	settings.set_language("ru")
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	var farm := current_scene
	farm.world.animate = false
	farm.world.ambience.animate = false
	farm.world.animation_time = 2.25
	farm.world.ambience.animation_time = 2.25
	farm.world.selection_elapsed = 1.0
	settings.set_reduced_motion(false)
	farm.world.queue_redraw()
	farm.world.ambience.queue_redraw()
	var directory: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(directory)
	for dimensions in [Vector2i(390, 844), Vector2i(430, 932)]:
		root.size = dimensions
		await settle()
		farm._focus_garden()
		farm.hud.settings_button.release_focus()
		farm.world.selection_elapsed = 1.0
		await settle()
		var center: Vector2 = farm.camera_rig.play_area.get_center()
		finger(1, center - Vector2(40, 0), true)
		finger(2, center + Vector2(40, 0), true)
		move_finger(2, center + Vector2(80, 0))
		finger(2, center + Vector2(80, 0), false)
		move_finger(1, center - Vector2(75, -20))
		finger(1, center - Vector2(75, -20), false)
		await settle()
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		var output: String = directory.path_join("navigation-ru-%dx%d.png" % [dimensions.x, dimensions.y])
		if screenshot.get_size() != dimensions or screenshot.save_png(output) != OK:
			quit(1)
			return
		print("NAVIGATION SCREENSHOT ", output, " zoom=", farm.camera_rig.relative_zoom, " focus=", farm.camera_rig.focus)
	settings.load_preferences(settings.DEFAULT_PATH)
	DirAccess.remove_absolute("user://qa_navigation_preferences.cfg")
	quit()
