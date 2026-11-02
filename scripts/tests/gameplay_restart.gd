extends SceneTree
const PATH = "user://qa_crop_restart.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var service := root.get_node("WorldService")
	var game := root.get_node("GameState")
	var clock := root.get_node("TimeService")
	var mode: String = OS.get_cmdline_user_args()[0]
	if mode == "cleanup":
		for path in [PATH,PATH.get_basename()+".backup.json"]:
			DirAccess.remove_absolute(path)
		quit(0)
		return
	clock.begin_mock(1000000 if mode == "write" else 1000000 + 48*3600)
	service.use_storage(PATH)
	if mode == "write":
		for entry in [[&"starter_plot_01",&"sunny_carrot"],[&"starter_plot_02",&"moonberry"],[&"starter_plot_03",&"starflower"]]:
			if not game.plant(entry[0],entry[1],0).ok:
				push_error("Could not initialize restart fixture")
				quit(1)
				return
	elif mode == "resume":
		if service.gameplay.coins != 108 or service.gameplay.crops.size() != 3:
			push_error("Currency/crops not restored")
			quit(1)
			return
		for id in service.gameplay.crops.keys():
			if game.crop_at(id).stage_at(clock.now_utc()) != 3 or not game.harvest(id,1).ok:
				quit(1)
				return
	elif mode == "verify_claimed":
		if service.gameplay.coins != 198 or not service.gameplay.crops.is_empty() or game.harvest(&"starter_plot_01",1).ok:
			push_error("Reward replayed after a process restart")
			quit(1)
			return
	else:
		quit(1)
		return
	print("GAMEPLAY RESTART ",mode,": PASS")
	quit(0)
