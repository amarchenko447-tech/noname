extends SceneTree
## Real-render measurements; isolated saves. Not a physical-device benchmark.
var samples: Array[Dictionary] = []
var farm: Node
var service: Node
var settings: Node
var clock: Node
var original_path: String
var original_prefs: String
var options: PackedStringArray
var output: String
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):
		await process_frame
func measure(mode: String, count: int) -> void:
	var durations: Array[float] = []
	var processes: Array[float] = []
	var draws: Array[float] = []
	var memory: Array[int] = []
	var nodes: Array[int] = []
	var texture_bytes: Array[int] = []
	var last: int = Time.get_ticks_usec()
	for frame in range(count):
		if mode == "dialogs" and frame % 20 == 0:
			farm.hud._open_dialog(["settings","language","guide","notes","seeds"][(frame / 20) % 5])
		elif mode == "dialogs" and frame % 20 == 10:
			farm.hud._close_dialog()
		await process_frame
		var now: int = Time.get_ticks_usec()
		durations.append((now-last)/1000.0)
		last = now
		processes.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if frame % 60 == 0:
			memory.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
			nodes.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
			texture_bytes.append(int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))
	durations.sort()
	processes.sort()
	draws.sort()
	samples.append({"scenario":mode,"frames":count,"frame_ms_p50":durations[count/2],"frame_ms_p95":durations[int(count*.95)],"frame_ms_max":durations[-1],"process_ms_p95":processes[int(count*.95)],"draw_calls_p50":draws[count/2],"static_bytes_series":memory,"node_count_series":nodes,"texture_bytes_series":texture_bytes,"orphan_nodes":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))})
	print("PROFILE ",JSON.stringify(samples[-1]))
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Use actual rendering, e.g. DISPLAY=:99, not --headless")
		quit(1)
		return
	options=OS.get_cmdline_user_args()
	output=options[0]
	var count: int=int(options[1]) if options.size()>1 else 600
	service=root.get_node("WorldService")
	settings=root.get_node("SettingsManager")
	clock=root.get_node("TimeService")
	original_path=service.store.path
	original_prefs=settings.settings_path
	for path in ["user://qa_profile.json","user://qa_profile.backup.json","user://qa_profile.cfg"]:
		DirAccess.remove_absolute(path)
	settings.load_preferences("user://qa_profile.cfg","en")
	clock.begin_mock(2000000000)
	service.use_storage("user://qa_profile.json")
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await frames(90)
	farm=current_scene
	await measure("empty",count)
	var game: Node=root.get_node("GameState")
	for id in service.model.ids_of_kind("plot"):
		game.plant(id,&"sunny_carrot",game.cycle_at(id))
	clock.advance_mock(30)
	farm._on_tick()
	await frames(90)
	await measure("nine_mature",count)
	settings.set_reduced_motion(true)
	await frames(60)
	await measure("reduced_motion",count)
	settings.set_reduced_motion(false)
	await frames(60)
	await measure("dialogs",count)
	farm.hud._close_dialog(false)
	await frames(120)
	var report: Dictionary={"engine":Engine.get_version_info().string,"os":OS.get_name(),"renderer":RenderingServer.get_video_adapter_name(),"size":str(root.size),"samples":samples,"settled_nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"settled_objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"settled_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))}
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	clock.use_real_clock()
	service.use_storage(original_path)
	settings.load_preferences(original_prefs)
	quit(0)
