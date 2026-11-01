extends SceneTree
## Separate-process world persistence, independent from preferences and UI.
const Model = preload("res://scripts/world/world_model.gd")
const Record = preload("res://scripts/world/object_record.gd")
const Store = preload("res://scripts/world/snapshot_store.gd")
const WORLD = preload("res://resources/world/default.tres")
const PATH = "user://qa_world_restart_075.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	if mode == "cleanup":
		for path in [PATH, PATH.get_basename() + ".backup.json", PATH + ".tmp"]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		quit(0)
		return
	var model := Model.new(WORLD)
	var store := Store.new(PATH)
	if mode == "write":
		if not model.populate_starter() or not model.move(&"starter_plot_05", Vector2i(-1, -1), 0):
			quit(1)
			return
		var extra := Record.new()
		extra.id = &"persisted_unique_id"
		extra.definition_id = &"garden_plot"
		extra.cell = Vector2i(4, 4)
		if not model.place(extra) or not store.commit(model.to_data()):
			quit(1)
			return
	elif mode == "read":
		var data: Dictionary = store.load_snapshot(func(value: Dictionary) -> bool: return Model.new(WORLD).load_data(value))
		if not model.load_data(data) or model.objects.size() != 10 or model.get_object(&"starter_plot_05").cell != Vector2i(-1, -1) or model.get_object(&"persisted_unique_id").cell != Vector2i(4, 4):
			push_error("World did not survive a process restart")
			quit(1)
			return
	else:
		quit(1)
		return
	print("WORLD RESTART ", mode, ": PASS")
	quit(0)
