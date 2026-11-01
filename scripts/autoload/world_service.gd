extends Node
## Owns world state and transactional commands, never HUD or Camera2D.
signal world_changed
signal save_failed(key: String)
const Model = preload("res://scripts/world/world_model.gd")
const Record = preload("res://scripts/world/object_record.gd")
const Store = preload("res://scripts/world/snapshot_store.gd")
const DEFINITION = preload("res://resources/world/default.tres")
var model: RefCounted
var store: RefCounted
var load_status: String = "new"
var last_save_ok: bool = true
func _ready() -> void:
	use_storage("user://world_v1.json")
func use_storage(path: String) -> void:
	store = Store.new(path)
	reload_world()
func _valid(data: Dictionary) -> bool:
	return Model.new(DEFINITION).load_data(data)
func reload_world() -> void:
	model = Model.new(DEFINITION)
	var data: Dictionary = store.load_snapshot(_valid)
	load_status = store.status
	if data.is_empty():
		if not model.populate_starter():
			push_error("Invalid starter region")
			return
		last_save_ok = store.commit(model.to_data()) if load_status == "new" else false
	else:
		if not model.load_data(data):
			push_error("Validated snapshot failed to load")
			return
		last_save_ok = store.commit(model.to_data()) if load_status == "recovered" else true
	world_changed.emit()
func _candidate() -> RefCounted:
	var candidate := Model.new(DEFINITION)
	if not candidate.load_data(model.to_data()):
		push_error("Invalid current world state")
		return null
	return candidate
func _commit(candidate: RefCounted) -> bool:
	candidate.generation = model.generation + 1
	if not store.commit(candidate.to_data()):
		last_save_ok = false
		save_failed.emit("WORLD_SAVE_ERROR")
		return false
	model = candidate
	last_save_ok = true
	load_status = "ok"
	world_changed.emit()
	return true
func place_object(record: RefCounted) -> bool:
	var candidate := _candidate()
	if candidate == null or not candidate.place(Record.from_data(record.to_data())):
		return false
	return _commit(candidate)
func move_object(id: StringName, cell: Vector2i, rotation: int = 0) -> bool:
	var candidate := _candidate()
	return _commit(candidate) if candidate != null and candidate.move(id, cell, rotation) else false
func remove_object(id: StringName) -> bool:
	var candidate := _candidate()
	return _commit(candidate) if candidate != null and candidate.remove(id) else false
func focus_plot_id() -> StringName:
	var preferred: StringName = model.regions[DEFINITION.starter_region_id].focus_object_id
	var ids: Array[StringName] = model.ids_of_kind("plot")
	if preferred in ids:
		return preferred
	return ids[0] if not ids.is_empty() else &""
func next_plot_id(current: StringName) -> StringName:
	var ids: Array[StringName] = model.ids_of_kind("plot")
	if ids.is_empty():
		return &""
	var offset: int = ids.find(current)
	return ids[(offset + 1) % ids.size()]
