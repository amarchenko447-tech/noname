extends SceneTree
## Regression coverage for audit findings. All files use an isolated qa_audit prefix.
const PATH="user://qa_audit_world.json"
const PREFS="user://qa_audit_preferences.cfg"
var assertions: int=0
var failures: int=0
var service: Node
var game: Node
var clock: Node
var settings: Node
var farm: Node
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, description: String) -> void:
	assertions+=1
	if not value:
		failures+=1
		push_error("FAIL: "+description)
func settle(count: int=8) -> void:
	for i in range(count): await process_frame
func write(path: String,text: String) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
func clean() -> void:
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("qa_audit_"):
			DirAccess.remove_absolute("user://"+file)
func run() -> void:
	service=root.get_node("WorldService")
	game=root.get_node("GameState")
	clock=root.get_node("TimeService")
	settings=root.get_node("SettingsManager")
	var original_path: String=service.store.path
	var original_prefs: String=settings.settings_path
	clean()
	clock.begin_mock(2000000000)
	service.use_storage(PATH)
	settings.load_preferences(PREFS,"ru")
	settings.set_reduced_motion(true)
	settings.set_language("ru")
	# Syntactically valid but invalid types: no parser-error noise from fixtures.
	var damaged: String="[preferences]\nlanguage=123\nreduced_motion=\"broken\"\n"
	write(PREFS,damaged)
	settings.load_preferences(PREFS,"de")
	check(settings.locale=="ru" and settings.reduced_motion,"recover a whole known-good preferences snapshot")
	check(settings.last_save_ok,"recovered preferences repaired atomically")
	var archives: Array[String]=[]
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("qa_audit_preferences.cfg.rejected-"):
			archives.append(file)
	check(archives.size()==1 and FileAccess.get_file_as_string("user://"+archives[0])==damaged,"preserve rejected preference bytes")
	DirAccess.remove_absolute(PREFS+".backup")
	write(PREFS,damaged)
	settings.load_preferences(PREFS,"pl")
	check(not settings.last_save_ok and FileAccess.get_file_as_string(PREFS)==damaged,"no startup overwrite when both preference copies unavailable")
	settings.set_language("fr")
	check(settings.last_save_ok and settings.locale=="fr","explicit settings change repairs after archiving")
	var before: Dictionary=service.gameplay.to_data(clock.now_utc())
	settings.load_preferences("user://missing_audit_directory/settings.cfg","en")
	settings.set_language("es")
	check(not settings.last_save_ok,"unwritable preference path reports failure")
	check(service.gameplay.to_data(clock.now_utc())==before,"preference failures do not change gameplay")
	settings.load_preferences(PREFS,"en")
	check(game.plant(&"starter_plot_01",&"sunny_carrot",0).ok,"plant before recovery failure")
	var saved: Dictionary=service.snapshot()
	write(PATH,"{broken")
	write(service.store.backup_path(),"{broken backup")
	service.reload_world()
	check(service.load_status=="blocked" and service.gameplay.coins==145 and game.crop_at(&"starter_plot_01")!=null,"failed retry retains the currently loaded progress")
	check(not game.harvest(&"starter_plot_01",1).ok,"blocked storage prevents transactions")
	write(PATH,JSON.stringify(saved))
	service.reload_world()
	check(service.last_save_ok and service.gameplay.coins==145,"retry after restoring permissions/data resumes progress")
	write(PATH,"{rejected source")
	write(service.store.backup_path(),JSON.stringify(saved))
	service.reload_world()
	check(service.last_save_ok and service.load_status=="recovered","backup recovery completes")
	check(not service.store.recovery_archive.is_empty() and FileAccess.get_file_as_string(service.store.recovery_archive)=="{rejected source","world recovery preserves damaged primary before replacing it")
	# Timestamp behavior across background notifications, timezone-independent UTC.
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	farm=current_scene
	farm.tick.stop()
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(farm.tick.is_stopped(),"background stops shared UI clock")
	check(not farm.world.is_processing() and not farm.world.ambience.is_processing(),"background stops ambient redraw callbacks")
	clock.advance_mock(18)
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not farm.tick.is_stopped() and game.crop_at(&"starter_plot_01").stage_at(clock.now_utc())==2,"resume immediately refreshes elapsed stage")
	check(farm.world.is_processing() and farm.world.ambience.is_processing(),"resume restores ambient callbacks")
	farm.tick.stop()
	clock.advance_mock(12)
	farm._on_tick()
	check(farm.world.crop_views[&"starter_plot_01"].stage==3,"background elapsed time yields mature visual")
	check(not quit_on_go_back and not auto_accept_quit,"OS close/back are routed before exiting")
	farm.hud._open_dialog("language")
	await settle()
	check(farm.hud.handle_back() and farm.hud.dialog_kind=="settings","Android Back goes from language to settings")
	check(farm.hud.handle_back(),"Android Back consumes an open settings dialog")
	if is_instance_valid(farm.hud.dialog_tween): farm.hud.dialog_tween.custom_step(1)
	await settle()
	check(not farm.hud.handle_back() and farm.hud.can_start_world(farm.hud.play_area.get_center()),"closed dialog releases gesture ownership")
	for kind in ["settings","language","guide","notes","seeds"]:
		for i in range(8):
			farm.hud._open_dialog(kind)
			farm.hud._close_dialog()
			farm.hud._open_dialog("settings")
			farm.hud._close_dialog(false)
		await settle()
		check(not is_instance_valid(farm.hud.dialog),"rapid replacement/close settles "+kind)
		check(farm.hud._bindings.size()<40,"navigation bindings remain bounded "+kind)
	check(game.harvest(&"starter_plot_01",1).ok,"harvest remains available after modal stress")
	check(game.plant(&"starter_plot_02",&"sunny_carrot",0).ok,"begin a planting tween")
	check(farm.world.bump_tweens.has(&"starter_plot_02"),"planting tween is tracked")
	farm.world.rebuild(service.model)
	farm.world.sync_crops()
	await settle()
	check(farm.world.bump_tweens.is_empty() and farm.world.plant_bumps.is_empty(),"world rebuild cancels obsolete planting tweens")
	farm.world.play_crop_effect(&"starter_plot_02",&"plant")
	settings.set_reduced_motion(true)
	check(farm.world.bump_tweens.is_empty() and farm.world.plant_bumps.is_empty(),"Reduced Motion cancels in-flight soil movement")
	for dimensions in [Vector2i(320,568),Vector2i(360,640),Vector2i(390,844),Vector2i(430,932),Vector2i(768,1024)]:
		root.size=dimensions
		await settle()
		if dimensions.x<=360:
			check(farm.hud.size.y<844,"short phone does not compress a fixed 844px canvas")
			farm.camera_rig.center_on(Vector2.ZERO)
			farm._on_tap(farm.world.screen_position(&"starter_plot_05"))
			check(farm.camera_rig.zoom_value()>=0.334 and not is_instance_valid(farm.hud.dialog),"first compact overview tap zooms without spending or opening seeds")
			var point: Vector2=farm.world.screen_position(&"starter_plot_05")
			check(farm.world.plot_at(farm.camera_rig.screen_to_world(point))==&"starter_plot_05","clipped camera coordinates roundtrip on compact phone")
			farm._on_tap(point)
			check(farm.hud.dialog_kind=="seeds" and farm.hud.seed_picker.plot_id==&"starter_plot_05","second compact tap selects the correct stable ID")
			farm.hud._close_dialog(false)
			farm.camera_rig.center_on(Vector2.ZERO)
		for locale in settings.SUPPORTED:
			settings.set_language(locale)
			for kind in ["settings","language","guide","notes","seeds"]:
				farm.hud._open_dialog(kind)
				await settle()
				var rect: Rect2=farm.hud.dialog_margins.get_node("Center/DialogPanel").get_global_rect()
				check(root.get_visible_rect().grow(1).encloses(rect),"dialog fits "+str(dimensions)+" "+locale+" "+kind)
				farm.hud._close_dialog(false)
	# Four-direction touch swipes across a mature plant never harvest it.
	clock.advance_mock(30)
	farm._on_tick()
	var touch_id: StringName=&"starter_plot_02"
	var harvest_count: int=service.gameplay.statistics.total_harvests
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		farm.camera_rig.relative_zoom=1.4
		farm.camera_rig.center_on(farm.world.centers[touch_id],false)
		var origin: Vector2=farm.world.screen_position(touch_id)
		var press:=InputEventScreenTouch.new()
		press.index=12
		press.pressed=true
		press.position=origin
		root.push_input(press,true)
		var drag:=InputEventScreenDrag.new()
		drag.index=12
		drag.position=origin+direction*60
		drag.relative=direction*60
		root.push_input(drag,true)
		press=InputEventScreenTouch.new()
		press.index=12
		press.position=origin+direction*60
		root.push_input(press,true)
		check(service.gameplay.statistics.total_harvests==harvest_count and game.crop_at(touch_id)!=null,"swipe does not harvest "+str(direction))
	check(farm.hud.safe_margins_for(Vector2(390,844),Vector2(1170,2532),Rect2())==Vector4(18,24,18,24),"unavailable OS safe area uses normal margins")
	check(farm.hud.safe_margins_for(Vector2(390,844),Vector2(1170,2532),Rect2(5000,0,100,100))==Vector4(18,24,18,24),"out-of-display safe area cannot collapse HUD")
	var primary_before: String=FileAccess.get_file_as_string(PATH)
	var balance_before: int=service.gameplay.coins
	if OS.get_name()=="Linux":
		check(FileAccess.set_unix_permissions(PATH,0)==OK,"inject actual Linux read denial")
		check(FileAccess.set_unix_permissions(service.store.backup_path(),0)==OK,"deny backup read too")
		service.reload_world()
		check(service.load_status=="blocked" and service.gameplay.coins==balance_before,"kernel read denial retains live model")
		FileAccess.set_unix_permissions(PATH,384)
		FileAccess.set_unix_permissions(service.store.backup_path(),384)
		check(FileAccess.get_file_as_string(PATH)==primary_before,"denied load did not overwrite durable data")
		service.reload_world()
		var directory: String="user://qa_audit_locked"
		DirAccess.make_dir_absolute(directory)
		var old_path: String=service.store.path
		service.use_storage(directory+"/farm.json")
		check(FileAccess.set_unix_permissions(directory,320)==OK,"inject actual Linux directory write denial")
		check(not game.plant(&"starter_plot_01",&"sunny_carrot",0).ok and service.gameplay.coins==150,"kernel write denial cannot charge the player")
		FileAccess.set_unix_permissions(directory,448)
		check(game.plant(&"starter_plot_01",&"sunny_carrot",0).ok,"storage retry succeeds after permissions restored")
		service.use_storage(old_path)
		for file in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory+"/"+file)
		DirAccess.remove_absolute(directory)
	check(farm.world_clip.clip_contents and farm.world_clip.position.is_equal_approx(farm.hud.play_area.position) and farm.world_clip.size.is_equal_approx(farm.hud.play_area.size),"zoomed world is clipped to the HUD play area")
	# An invalid extreme clock must never poison the next loadable snapshot.
	var durable: String=FileAccess.get_file_as_string(PATH)
	var coins: int=service.gameplay.coins
	clock.set_mock_wall(5000000000)
	check(not game.plant(&"starter_plot_03",&"sunny_carrot",0).ok,"out-of-range UTC cannot create an invalid save")
	check(service.gameplay.coins==coins and FileAccess.get_file_as_string(PATH)==durable,"rejected candidate retains both money and durable primary")
	# No one-minute phase reset in ambience or crop idle movement.
	farm.world.ambience.animation_time=59.99
	farm.world.ambience.reduced_motion=false
	farm.world.ambience._process(.05)
	check(farm.world.ambience.animation_time>60,"ambient animation does not jump backwards after one minute")
	farm.queue_free()
	await settle()
	clock.use_real_clock()
	service.use_storage(original_path)
	settings.load_preferences(original_prefs)
	clean()
	print("STABILIZATION: ",assertions," assertions, ",failures," failures")
	quit(1 if failures else 0)
