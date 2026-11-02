extends SceneTree
## Real 30-second elapsed time across separate processes; no injected clock or OS changes.
const PATH="user://qa_real_clock.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var mode: String=OS.get_cmdline_user_args()[0]
	if mode=="cleanup":
		for path in [PATH,PATH.get_basename()+".backup.json"]:
			DirAccess.remove_absolute(path)
		quit()
		return
	var service:=root.get_node("WorldService")
	var game:=root.get_node("GameState")
	service.use_storage(PATH)
	if mode=="write":
		if not game.plant(&"starter_plot_01",&"sunny_carrot",0).ok or service.gameplay.coins!=145:
			quit(1)
			return
	elif mode=="read":
		var crop: RefCounted=game.crop_at(&"starter_plot_01")
		if crop==null or crop.stage_at(root.get_node("TimeService").now_utc())!=3 or not game.harvest(&"starter_plot_01",1).ok or service.gameplay.coins!=155:
			push_error("Real-clock offline crop/reward failed")
			quit(1)
			return
	elif mode=="claimed":
		if game.crop_at(&"starter_plot_01")!=null or service.gameplay.coins!=155 or game.harvest(&"starter_plot_01",1).ok:
			quit(1)
			return
	else:
		quit(1)
		return
	print("REAL CLOCK RESTART ",mode,": PASS")
	quit()
