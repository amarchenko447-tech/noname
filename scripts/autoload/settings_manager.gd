extends Node
## Preferences only. Never opens or modifies gameplay saves or plot models.
signal language_changed(locale: String)
signal motion_changed(reduced: bool)
signal save_failed
const SUPPORTED: Array[String] = ["en", "ru", "pl", "es", "de", "fr", "pt_BR"]
const NATIVE_KEYS: Array[String] = ["LOCALE_EN", "LOCALE_RU", "LOCALE_PL", "LOCALE_ES", "LOCALE_DE", "LOCALE_FR", "LOCALE_PT_BR"]
const DEFAULT_PATH = "user://settings_v1.cfg"
var settings_path: String = DEFAULT_PATH
var locale: String = "en"
var reduced_motion: bool = false
var last_save_ok: bool = true
var _last_good_text: String = ""
var _blocked_preferences: bool = false

func _ready() -> void:
	load_preferences()

func resolve_locale(value: String) -> String:
	var normalized := value.replace("-", "_").to_lower()
	if normalized == "pt" or normalized == "pt_br" or normalized.begins_with("pt_br_"):
		return "pt_BR"
	var language := normalized.get_slice("_", 0)
	if language in SUPPORTED and language != "pt_BR":
		return language
	return "en"

func _valid_config(config: ConfigFile) -> bool:
	return config.get_value("preferences", "language", "") is String and config.get_value("preferences", "reduced_motion", false) is bool

func load_preferences(path: String = DEFAULT_PATH, system_locale: String = "") -> void:
	settings_path = path
	_last_good_text = ""
	_blocked_preferences = false
	var config := ConfigFile.new()
	var result: Error = config.load(settings_path)
	var primary_ok: bool = result == OK and _valid_config(config)
	var needs_write: bool = result == ERR_FILE_NOT_FOUND
	if not primary_ok and (result != ERR_FILE_NOT_FOUND or FileAccess.file_exists(settings_path + ".backup")):
		var backup := ConfigFile.new()
		if backup.load(settings_path + ".backup") == OK and _valid_config(backup) and _preserve_rejected():
			config = backup
			primary_ok = true
			needs_write = true
		else:
			_blocked_preferences = true
	var stored: Variant = config.get_value("preferences", "language", "") if primary_ok else ""
	var detected: String = OS.get_locale() if system_locale.is_empty() else system_locale
	locale = resolve_locale(stored if stored is String and not stored.is_empty() else detected)
	reduced_motion = config.get_value("preferences", "reduced_motion", false) if primary_ok else false
	TranslationServer.set_locale(locale)
	if primary_ok:
		_last_good_text = config.encode_to_text()
		needs_write = needs_write or stored != locale
	last_save_ok = not _blocked_preferences
	if needs_write and not _blocked_preferences:
		_save_preferences()
	elif _blocked_preferences:
		save_failed.emit()
	language_changed.emit(locale)
	motion_changed.emit(reduced_motion)

func _preserve_rejected() -> bool:
	if not FileAccess.file_exists(settings_path):
		return true
	var preserved: String = settings_path + ".rejected-" + str(Time.get_unix_time_from_system()).replace(".","-") + "-" + str(Time.get_ticks_usec())
	return DirAccess.copy_absolute(settings_path, preserved) == OK

func _explicit_repair() -> void:
	# A deliberate settings change may repair the file, preserving its old bytes.
	if _blocked_preferences and _preserve_rejected():
		_blocked_preferences = false

func set_language(value: String) -> void:
	locale = resolve_locale(value)
	TranslationServer.set_locale(locale)
	_explicit_repair()
	_save_preferences()
	language_changed.emit(locale)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	_explicit_repair()
	_save_preferences()
	motion_changed.emit(value)

func _atomic_text(path: String, text: String) -> bool:
	var temp: String = path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK and DirAccess.rename_absolute(temp,path) == OK

func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("preferences", "language", locale)
	config.set_value("preferences", "reduced_motion", reduced_motion)
	var text: String = config.encode_to_text()
	last_save_ok = not _blocked_preferences
	if last_save_ok and not _last_good_text.is_empty():
		last_save_ok = _atomic_text(settings_path + ".backup", _last_good_text)
	if last_save_ok:
		last_save_ok = _atomic_text(settings_path, text)
	if last_save_ok:
		_last_good_text = text
	else:
		save_failed.emit()

func format_integer(value: int) -> String:
	var separator: String = ","
	if locale in ["ru", "pl", "fr"]:
		separator = "\u202f"
	elif locale in ["de", "es", "pt_BR"]:
		separator = "."
	var digits: String = str(absi(value))
	var groups: Array[String] = []
	while digits.length() > 3:
		groups.push_front(digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.push_front(digits)
	return ("-" if value < 0 else "") + separator.join(groups)

func format_duration(seconds: int) -> String:
	var clamped: int = maxi(0, seconds)
	if clamped < 60:
		return tr("TIME_SECONDS") % clamped
	if clamped < 3600:
		return tr("TIME_MINUTES") % (clamped / 60)
	return tr("TIME_HOURS") % [clamped / 3600, (clamped % 3600) / 60]

func format_countdown(seconds: int) -> String:
	var value: int = maxi(0, seconds)
	if value >= 3600:
		return "%d:%02d" % [value / 3600, (value % 3600) / 60]
	return "%02d:%02d" % [value / 60, value % 60]
