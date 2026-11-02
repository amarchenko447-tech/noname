extends SceneTree
## Actual viewport captures. Run with a graphical display or temporary Xvfb.
## godot --path . --script res://scripts/tests/capture_review.gd -- /absolute/output
var output_path: String

func _initialize() -> void:
	call_deferred("capture")

func settle() -> void:
	for frame in range(8):
		await process_frame

func save_frame(name: String, dimensions: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == dimensions, "Captured viewport must match requested resolution")
	var path: String = output_path.path_join(name + ".png")
	assert(image.save_png(path) == OK)
	print("SCREENSHOT ", path, " ", image.get_size())

func capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Screenshots require a rendering display; dummy headless cannot capture pixels.")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	output_path = args[0] if args.size() else ProjectSettings.globalize_path("res://docs/screenshots/night_sprint/localization")
	DirAccess.make_dir_recursive_absolute(output_path)
	var settings := root.get_node("SettingsManager")
	settings.load_preferences("user://capture_preferences.cfg", "en_US")
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	var farm := current_scene
	var garden: Control = farm.hud
	var world: Node2D = farm.world
	world.animate = false
	world.ambience.animate = false
	world.animation_time = 2.25
	world.ambience.animation_time = 2.25
	world.selection_elapsed = 1.0
	settings.set_reduced_motion(false)
	world.queue_redraw()
	world.ambience.queue_redraw()
	for dimensions in [Vector2i(390, 844), Vector2i(430, 932)]:
		root.size = dimensions
		for code in settings.SUPPORTED:
			settings.set_language(code)
			garden.settings_button.release_focus()
			await settle()
			var suffix: String = "%s-%dx%d" % [code, dimensions.x, dimensions.y]
			await save_frame("garden-" + suffix, dimensions)
			garden._open_settings()
			await settle()
			garden.dialog_tween.custom_step(1.0)
			await save_frame("settings-" + suffix, dimensions)
			garden._open_dialog("language")
			await settle()
			garden.dialog_tween.custom_step(1.0)
			await save_frame("language-" + suffix, dimensions)
			garden._close_dialog(false)
			await settle()
	settings.load_preferences(settings.DEFAULT_PATH)
	DirAccess.remove_absolute("user://capture_preferences.cfg")
	quit()
