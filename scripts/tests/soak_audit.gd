extends SceneTree
## Wall-clock, real-render soak. Samples only settled frames after warm-up.
var farm: Node
var samples: Array[Dictionary]=[]
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await process_frame
func run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var args:=OS.get_cmdline_user_args()
	var seconds: int=int(args[1]) if args.size()>1 else 300
	var service:=root.get_node("WorldService")
	var settings:=root.get_node("SettingsManager")
	var clock:=root.get_node("TimeService")
	var game:=root.get_node("GameState")
	var original_path: String=service.store.path
	var original_prefs: String=settings.settings_path
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("qa_soak"): DirAccess.remove_absolute("user://"+file)
	clock.begin_mock(2000000000)
	service.use_storage("user://qa_soak.json")
	settings.load_preferences("user://qa_soak.cfg","en")
	for id in service.model.ids_of_kind("plot"):
		game.plant(id,&"sunny_carrot",game.cycle_at(id))
	clock.advance_mock(30)
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await frames(12)
	farm=current_scene
	farm.tick.stop()
	for locale in settings.SUPPORTED:
		settings.set_language(locale)
		for kind in ["settings","language","guide","notes","seeds"]:
			farm.hud._open_dialog(kind)
			await frames(2)
			farm.hud._close_dialog(false)
			await frames(2)
	settings.set_language("en")
	await frames(90)
	var started: int=Time.get_ticks_msec()
	var next_cycle: int=0
	var last_sample: int=-10
	var cycles: int=0
	while (Time.get_ticks_msec()-started)/1000.0<seconds:
		var elapsed: int=(Time.get_ticks_msec()-started)/1000
		if elapsed>=next_cycle:
			settings.set_language(settings.SUPPORTED[cycles%7])
			settings.set_reduced_motion(cycles%8==0)
			farm.hud._open_dialog(["settings","language","guide","notes","seeds"][cycles%5])
			await frames(3)
			farm.hud._close_dialog(false)
			farm.camera_rig.zoom_at(1.02 if cycles%2==0 else 1/1.02,farm.hud.play_area.get_center())
			await frames(3)
			cycles+=1
			next_cycle=elapsed+1
		if elapsed-last_sample>=10:
			samples.append({"seconds":elapsed,"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),"bindings":farm.hud._bindings.size(),"tweens":get_processed_tweens().size()})
			print("SOAK ",JSON.stringify(samples[-1]))
			last_sample=elapsed
		await process_frame
	var passed: bool=true
	for sample in samples:
		passed=passed and sample.orphans==0 and sample.nodes==samples[0].nodes and sample.bindings==samples[0].bindings
	var report: Dictionary={"elapsed_seconds":(Time.get_ticks_msec()-started)/1000.0,"cycles":cycles,"renderer":RenderingServer.get_video_adapter_name(),"samples":samples,"bounded_nodes_bindings":passed,"coin_balance":service.gameplay.coins,"harvest_count":service.gameplay.statistics.total_harvests}
	var file:=FileAccess.open(args[0],FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	clock.use_real_clock()
	service.use_storage(original_path)
	settings.load_preferences(original_prefs)
	print("SOAK COMPLETE: ","PASS" if passed else "FAIL")
	quit(0 if passed else 1)
