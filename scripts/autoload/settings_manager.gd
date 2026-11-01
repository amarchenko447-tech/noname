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

func load_preferences(path: String = DEFAULT_PATH, system_locale: String = "") -> void:
	settings_path = path
	var config := ConfigFile.new()
	var result: Error = config.load(settings_path)
	var stored: Variant = config.get_value("preferences", "language", "") if result == OK else ""
	var detected: String = OS.get_locale() if system_locale.is_empty() else system_locale
	locale = resolve_locale(stored if stored is String and not stored.is_empty() else detected)
	var motion: Variant = config.get_value("preferences", "reduced_motion", false) if result == OK else false
	reduced_motion = motion if motion is bool else false
	TranslationServer.set_locale(locale)
	# Persist first-run choice as well as normalized regional variants.
	_save_preferences()
	language_changed.emit(locale)
	motion_changed.emit(reduced_motion)

func set_language(value: String) -> void:
	locale = resolve_locale(value)
	TranslationServer.set_locale(locale)
	_save_preferences()
	language_changed.emit(locale)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	_save_preferences()
	motion_changed.emit(value)

func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("preferences", "language", locale)
	config.set_value("preferences", "reduced_motion", reduced_motion)
	var temp: String = settings_path + ".tmp"
	var result: Error = config.save(temp)
	if result == OK:
		result = DirAccess.rename_absolute(temp, settings_path)
	last_save_ok = result == OK
	if not last_save_ok:
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
