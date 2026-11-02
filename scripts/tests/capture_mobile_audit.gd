extends SceneTree
## Actual rendering of compact layouts and injected safe-area geometry, not device QA.
var folder: String
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in range(12): await process_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(folder.path_join(name+".png"))!=OK:
		quit(1)
	print("MOBILE CAPTURE ",name," physical=",root.size," logical=",root.get_visible_rect().size)
func run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	folder=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var settings:=root.get_node("SettingsManager")
	var service:=root.get_node("WorldService")
	var clock:=root.get_node("TimeService")
	var game:=root.get_node("GameState")
	var old_prefs: String=settings.settings_path
	var old_path: String=service.store.path
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("qa_mobile_capture"): DirAccess.remove_absolute("user://"+file)
	clock.begin_mock(2000000000)
	service.use_storage("user://qa_mobile_capture.json")
	settings.load_preferences("user://qa_mobile_capture.cfg","ru")
	for pair in [[&"starter_plot_01",&"sunny_carrot"],[&"starter_plot_02",&"moonberry"],[&"starter_plot_03",&"bubble_cactus"]]:
		if not game.plant(pair[0],pair[1],0).ok: quit(1); return
	clock.advance_mock(600)
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	var farm:=current_scene
	farm.tick.stop()
	farm.world.animate=false
	farm.world.ambience.animate=false
	farm.world.animation_time=2.25
	farm.world.ambience.animation_time=2.25
	farm.world.selection_elapsed=1
	for dimensions in [Vector2i(320,568),Vector2i(360,640),Vector2i(768,1024)]:
		root.size=dimensions
		await settle()
		farm.hud.settings_button.release_focus()
		await shot("compact-garden-ru-%dx%d"%[dimensions.x,dimensions.y])
		farm.hud._open_dialog("language")
		farm.hud.dialog_tween.custom_step(1)
		await settle()
		await shot("compact-language-ru-%dx%d"%[dimensions.x,dimensions.y])
		farm.hud._close_dialog(false)
	root.size=Vector2i(390,844)
	await settle()
	farm.camera_rig.relative_zoom=farm.camera_rig.max_relative_zoom()
	farm.camera_rig.center_on(farm.world.centers[&"starter_plot_02"],false)
	await settle()
	await shot("zoom-ru-390x844")
	farm.hud.free()
	farm.hud=load("res://tests/fixtures/safe_area_hud.gd").new()
	farm.hud.model=service.model
	farm.hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	farm.hud.layout_changed.connect(farm._on_layout_changed)
	farm.hud_layer.add_child(farm.hud)
	farm.input_router.can_start=farm.hud.can_start_world
	farm.hud.set_selected(&"starter_plot_02")
	farm.hud.refresh_gameplay()
	for dimensions in [Vector2i(390,844),Vector2i(430,932)]:
		root.size=dimensions
		farm.camera_rig.relative_zoom=1
		farm.camera_rig.center_on(Vector2.ZERO,false)
		await settle()
		await shot("simulated-safe-garden-ru-%dx%d"%[dimensions.x,dimensions.y])
		farm.hud._open_dialog("language")
		farm.hud.dialog_tween.custom_step(1)
		await settle()
		await shot("simulated-safe-language-ru-%dx%d"%[dimensions.x,dimensions.y])
		farm.hud._close_dialog(false)
	clock.use_real_clock()
	service.use_storage(old_path)
	settings.load_preferences(old_prefs)
	quit()
