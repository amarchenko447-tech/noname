extends SceneTree
## Earns currency and plants through real commands in an isolated save/clock.
var output: String
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for frame in range(8):
		await process_frame
func shot(name: String, dimensions: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	if capture.get_size() != dimensions or capture.save_png(output.path_join(name + ".png")) != OK:
		push_error("Screenshot failed")
		quit(1)
	print("GAME SCREENSHOT ",name,dimensions)
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rendering display required")
		quit(1)
		return
	output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	var service := root.get_node("WorldService")
	var game := root.get_node("GameState")
	var clock := root.get_node("TimeService")
	var settings := root.get_node("SettingsManager")
	var original_path: String = service.store.path
	var path: String = "user://qa_game_capture.json"
	for file in [path,path.get_basename()+".backup.json"]:
		DirAccess.remove_absolute(file)
	settings.load_preferences("user://qa_game_capture_preferences.cfg","ru_RU")
	clock.begin_mock(2000000000)
	service.use_storage(path)
	for cycle in range(50):
		if not game.plant(&"starter_plot_01",&"sunny_carrot",cycle).ok:
			quit(1)
			return
		clock.advance_mock(30)
		if not game.harvest(&"starter_plot_01",cycle+1).ok:
			quit(1)
			return
	var final_time: int = clock.now_utc() + 5000
	var specimens: Array = [["starter_plot_01","sunny_carrot",32],["starter_plot_02","moonberry",120],["starter_plot_03","starflower",300],["starter_plot_04","bubble_cactus",600],["starter_plot_05","crystal_mushroom",1200],["starter_plot_06","rainbow_tulip",2400],["starter_plot_07","sunny_carrot",2],["starter_plot_08","moonberry",45],["starter_plot_09","starflower",210]]
	specimens.sort_custom(func(a: Array,b: Array) -> bool: return a[2] > b[2])
	for specimen in specimens:
		clock.set_mock_wall(final_time-specimen[2])
		var id := StringName(specimen[0])
		if not game.plant(id,StringName(specimen[1]),game.cycle_at(id)).ok:
			quit(1)
			return
	clock.set_mock_wall(final_time)
	game.refresh_growth()
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	var farm := current_scene
	farm.tick.stop()
	farm.world.animate = false
	farm.world.ambience.animate = false
	farm.world.animation_time = 2.25
	farm.world.ambience.animation_time = 2.25
	farm.world.selection_elapsed = 1.0
	settings.set_reduced_motion(false)
	for visual in farm.world.crop_views.values():
		visual.idle_time = 2.25
		visual.queue_redraw()
	farm.world.queue_redraw()
	farm.world.ambience.queue_redraw()
	for dimensions in [Vector2i(390,844),Vector2i(430,932)]:
		root.size = dimensions
		await settle()
		for code in settings.SUPPORTED:
			settings.set_language(code)
			farm.hud.settings_button.release_focus()
			await settle()
			var suffix: String = "%s-%dx%d" % [code,dimensions.x,dimensions.y]
			await shot("garden-"+suffix,dimensions)
	# Create an empty slot only after both garden sizes have been captured.
	var receipt: Dictionary = game.harvest(&"starter_plot_01",game.cycle_at(&"starter_plot_01"))
	if not receipt.ok:
		quit(1)
		return
	if is_instance_valid(farm.hud.balance_tween):
		farm.hud.balance_tween.custom_step(1.0)
	for dimensions in [Vector2i(390,844),Vector2i(430,932)]:
		root.size = dimensions
		await settle()
		for code in settings.SUPPORTED:
			settings.set_language(code)
			farm.hud.open_seeds(&"starter_plot_01")
			farm.hud.seed_picker.selected_species = &"rainbow_tulip"
			farm.hud.seed_picker.refresh_texts()
			if is_instance_valid(farm.hud.dialog_tween):
				farm.hud.dialog_tween.custom_step(1.0)
			await settle()
			await shot("seeds-"+"%s-%dx%d" % [code,dimensions.x,dimensions.y],dimensions)
			farm.hud._close_dialog(false)
			await settle()
		farm.world.select_plot(&"starter_plot_05")
		farm.world.selection_elapsed = 1.0
	settings.load_preferences(settings.DEFAULT_PATH)
	clock.use_real_clock()
	service.use_storage(original_path)
	for file in [path,path.get_basename()+".backup.json","user://qa_game_capture_preferences.cfg"]:
		DirAccess.remove_absolute(file)
	quit()
