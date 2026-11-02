extends SceneTree
const PATH="user://qa_kill.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var clock:=root.get_node("TimeService")
	clock.begin_mock(2000000000)
	var service:=root.get_node("WorldService")
	var game:=root.get_node("GameState")
	service.use_storage(PATH)
	var mode: String=OS.get_cmdline_user_args()[0]
	if mode=="plant":
		if not game.plant(&"starter_plot_01",&"sunny_carrot",0).ok: quit(1); return
	elif mode=="harvest":
		if service.gameplay.coins!=145 or game.crop_at(&"starter_plot_01")==null: quit(1); return
		clock.advance_mock(30)
		if not game.harvest(&"starter_plot_01",1).ok: quit(1); return
	elif mode in ["verify","invariant"]:
		var state: RefCounted=service.gameplay
		var crop: RefCounted=game.crop_at(&"starter_plot_01")
		var valid: bool=state.coins==150-5*state.statistics.total_planted+10*state.statistics.total_harvests and state.crops.size()==state.statistics.total_planted-state.statistics.total_harvests and service.load_status!="blocked"
		if mode=="verify": valid=valid and state.coins==155 and crop==null and not game.harvest(&"starter_plot_01",1).ok
		if not valid: push_error("Interrupted write violated snapshot invariant")
		print("CRASH VERIFY ",mode,": ","PASS" if valid else "FAIL")
		quit(0 if valid else 1)
		return
	elif mode!="spam":
		quit(1)
		return
	print("SAVED ",mode)
	if mode=="spam":
		while true:
			var crop: RefCounted=game.crop_at(&"starter_plot_01")
			if crop!=null:
				clock.set_mock_wall(crop.ready_at_utc)
				if not game.harvest(&"starter_plot_01",crop.cycle_id).ok: quit(1); return
			else:
				if not game.plant(&"starter_plot_01",&"sunny_carrot",game.cycle_at(&"starter_plot_01")).ok: quit(1); return
			await process_frame
	else:
		while true: await process_frame
