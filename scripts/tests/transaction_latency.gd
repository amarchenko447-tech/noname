extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var service:=root.get_node("WorldService")
	var game:=root.get_node("GameState")
	var clock:=root.get_node("TimeService")
	var original: String=service.store.path
	var path: String="user://qa_latency.json"
	for file in [path,path.get_basename()+".backup.json"]: DirAccess.remove_absolute(file)
	clock.begin_mock(2000000000)
	service.use_storage(path)
	var times: Array[float]=[]
	var valid: bool=true
	for cycle in range(100):
		var start: int=Time.get_ticks_usec()
		valid=game.plant(&"starter_plot_01",&"sunny_carrot",cycle).ok and valid
		times.append((Time.get_ticks_usec()-start)/1000.0)
		clock.advance_mock(30)
		start=Time.get_ticks_usec()
		valid=game.harvest(&"starter_plot_01",cycle+1).ok and valid
		times.append((Time.get_ticks_usec()-start)/1000.0)
	valid=valid and service.gameplay.coins==650 and service.gameplay.crops.is_empty()
	times.sort()
	var report: Dictionary={"transactions":times.size(),"p50_ms":times[times.size()/2],"p95_ms":times[int(times.size()*.95)],"max_ms":times[-1],"valid":valid,"environment":"Linux local temporary storage; includes snapshot validation, backup, flush and rename; no device durability/latency claim"}
	var output:=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	clock.use_real_clock()
	service.use_storage(original)
	print("TRANSACTION LATENCY ",JSON.stringify(report))
	quit(0 if valid else 1)
