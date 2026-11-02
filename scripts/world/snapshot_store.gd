class_name WorldSnapshotStore
extends RefCounted
## One atomic JSON snapshot now; commit/load boundary supports future chunk storage.
const CURRENT_VERSION: int = 1
var target_version: int = CURRENT_VERSION
var migrated: bool = false
var path: String
var status: String = "new"
var last_good: Dictionary = {}
var migrations: Dictionary = {}
var simulate_write_failure: bool = false
var recovery_archive: String = ""
func _init(storage_path: String, version: int = CURRENT_VERSION) -> void:
	path = storage_path
	target_version = version
func backup_path() -> String:
	return path.get_basename() + ".backup.json"
func register_migration(from_version: int, migration: Callable) -> void:
	assert(from_version < target_version)
	migrations[from_version] = migration
func migrate(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not (raw.get("schema_version") is int or raw.get("schema_version") is float):
		return {}
	var numeric: float = float(raw.schema_version)
	if not is_finite(numeric) or numeric != floorf(numeric) or numeric < 0 or numeric > target_version:
		return {}
	var version: int = int(numeric)
	var result: Dictionary = raw.duplicate(true)
	while version < target_version:
		if not migrations.has(version):
			return {}
		var next: Variant = migrations[version].call(result.duplicate(true))
		if not next is Dictionary or next.get("schema_version") != version + 1:
			return {}
		result = next
		version += 1
	return result
func _read(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	return parser.data if error == OK else null
func load_snapshot(validate: Callable) -> Dictionary:
	last_good = {}
	recovery_archive = ""
	migrated = false
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(backup_path()):
		status = "new"
		return {}
	var primary: Variant = _read(path)
	if primary is Dictionary and (primary.get("schema_version") is int or primary.get("schema_version") is float) and primary.schema_version > target_version:
		status = "blocked"
		return {}
	for file_path in [path, backup_path()]:
		var candidate := migrate(primary if file_path == path else _read(file_path))
		if not candidate.is_empty() and validate.call(candidate):
			var original: Variant = primary if file_path == path else _read(file_path)
			migrated = original is Dictionary and original.get("schema_version") != target_version
			last_good = candidate.duplicate(true)
			status = "ok" if file_path == path else "recovered"
			return candidate
	status = "blocked"
	return {}
func commit(candidate: Dictionary) -> bool:
	if status == "blocked" or simulate_write_failure:
		return false
	if status == "recovered" and recovery_archive.is_empty() and FileAccess.file_exists(path):
		var archive: String = path + ".rejected-" + str(Time.get_ticks_usec())
		if DirAccess.copy_absolute(path, archive) != OK:
			return false
		recovery_archive = archive
	if not last_good.is_empty() and not _atomic_write(backup_path(), last_good):
		return false
	if not _atomic_write(path, candidate):
		return false
	last_good = candidate.duplicate(true)
	status = "ok"
	return true
func _atomic_write(file_path: String, data: Dictionary) -> bool:
	var temp: String = file_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(file_path)) == OK
