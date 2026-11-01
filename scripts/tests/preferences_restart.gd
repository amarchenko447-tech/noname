extends SceneTree
## Launch separately in write/read/cleanup modes to verify a real process restart.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var settings := root.get_node("SettingsManager")
	var mode: String = OS.get_cmdline_user_args()[0]
	var path: String = "user://qa_restart_preferences.cfg"
	if mode == "cleanup":
		DirAccess.remove_absolute(path)
		quit(0)
		return
	settings.load_preferences(path, "en_US")
	if mode == "write":
		settings.set_language("ru")
		settings.set_reduced_motion(true)
		assert(settings.last_save_ok)
	elif mode == "read":
		assert(settings.locale == "ru", "Locale survives process restart, regardless of OS override")
		assert(settings.reduced_motion, "Motion preference survives process restart")
	else:
		quit(1)
		return
	print("PERSISTENCE ", mode, ": PASS")
	quit(0)
