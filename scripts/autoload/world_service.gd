extends Node
## One durable root snapshot contains map and gameplay; preferences stay separate.
signal world_changed
signal gameplay_changed
signal transaction_completed(receipt: Dictionary)
signal save_failed(key: String)
const Model = preload("res://scripts/world/world_model.gd")
const Record = preload("res://scripts/world/object_record.gd")
const Store = preload("res://scripts/world/snapshot_store.gd")
const Gameplay = preload("res://scripts/models/gameplay_state.gd")
const Catalog = preload("res://scripts/models/plant_catalog.gd")
const DEFINITION = preload("res://resources/world/default.tres")
const SAVE_VERSION: int = 2
var model: RefCounted
var gameplay: RefCounted
var catalog: RefCounted
var store: RefCounted
var load_status: String = "new"
var last_save_ok: bool = true
var busy: bool = false
func _ready() -> void:
	catalog = Catalog.new()
	use_storage("user://world_v1.json")
func use_storage(path: String) -> void:
	model = null
	gameplay = null
	store = Store.new(path, SAVE_VERSION)
	store.register_migration(1, _migrate_world_v1)
	reload_world()
func _migrate_world_v1(data: Dictionary) -> Dictionary:
	return {"schema_version": 2, "world": data.duplicate(true), "gameplay": Gameplay.new().to_data(TimeService.now_utc()), "last_observed_utc": TimeService.now_utc()}
func _valid(data: Dictionary) -> bool:
	if data.get("schema_version") != SAVE_VERSION or not data.get("world") is Dictionary or not data.get("gameplay") is Dictionary:
		return false
	var floor_time: Variant = data.get("last_observed_utc")
	if not (floor_time is int or floor_time is float) or not is_finite(float(floor_time)) or floor_time < 0 or floor_time > 4102444800 or floorf(float(floor_time)) != float(floor_time):
		return false
	var candidate := Model.new(DEFINITION)
	return candidate.load_data(data.world) and Gameplay.new().load_data(data.gameplay, candidate, catalog)
func snapshot(map: RefCounted = model, game: RefCounted = gameplay) -> Dictionary:
	var now: int = TimeService.now_utc()
	return {"schema_version": SAVE_VERSION, "world": map.to_data(), "gameplay": game.to_data(now), "last_observed_utc": now}
func reload_world() -> void:
	var data: Dictionary = store.load_snapshot(_valid)
	load_status = store.status
	if data.is_empty() and load_status == "blocked" and is_instance_valid(model):
		last_save_ok = false
		save_failed.emit("WORLD_SAVE_BLOCKED")
		return
	model = Model.new(DEFINITION)
	gameplay = Gameplay.new()
	if data.is_empty():
		if not model.populate_starter():
			push_error("Invalid starter region")
			return
		last_save_ok = _write_snapshot(snapshot()) if load_status == "new" else false
	else:
		TimeService.observe_floor(int(data.last_observed_utc))
		if not model.load_data(data.world) or not gameplay.load_data(data.gameplay, model, catalog):
			push_error("Validated farm snapshot failed to load")
			return
		last_save_ok = _write_snapshot(snapshot()) if load_status == "recovered" or store.migrated else true
	world_changed.emit()
	gameplay_changed.emit()
func _write_snapshot(data: Dictionary) -> bool:
	# Reject invalid candidates before touching either durable copy.
	return _valid(data) and store.commit(data)

func _candidate() -> RefCounted:
	var candidate := Model.new(DEFINITION)
	return candidate if candidate.load_data(model.to_data()) else null
func game_candidate() -> RefCounted:
	var candidate := Gameplay.new()
	return candidate if candidate.load_data(gameplay.to_data(TimeService.now_utc()), model, catalog) else null
func _commit(candidate: RefCounted, game: RefCounted, map_changed: bool, receipt: Dictionary = {}) -> bool:
	if busy or store.status == "blocked":
		return false
	busy = true
	candidate.generation = model.generation + 1
	if not _write_snapshot(snapshot(candidate, game)):
		busy = false
		last_save_ok = false
		save_failed.emit("WORLD_SAVE_ERROR")
		return false
	model = candidate
	gameplay = game
	last_save_ok = true
	load_status = "ok"
	if map_changed:
		world_changed.emit()
	gameplay_changed.emit()
	if not receipt.is_empty():
		receipt.balance = gameplay.coins
		transaction_completed.emit(receipt)
	busy = false
	return true
func commit_game(game: RefCounted, receipt: Dictionary = {}) -> bool:
	var candidate := _candidate()
	return candidate != null and game != null and _commit(candidate, game, false, receipt)
func checkpoint() -> bool:
	return commit_game(game_candidate())
func place_object(record: RefCounted) -> bool:
	var candidate := _candidate()
	return candidate != null and candidate.place(Record.from_data(record.to_data())) and _commit(candidate, game_candidate(), true)
func move_object(id: StringName, cell: Vector2i, rotation: int = 0) -> bool:
	var candidate := _candidate()
	return candidate != null and candidate.move(id, cell, rotation) and _commit(candidate, game_candidate(), true)
func remove_object(id: StringName) -> bool:
	if gameplay.crops.has(id):
		return false
	var candidate := _candidate()
	var game := game_candidate()
	if candidate == null or game == null or not candidate.remove(id):
		return false
	game.cycles.erase(id)
	return _commit(candidate, game, true)
func focus_plot_id() -> StringName:
	var preferred: StringName = model.regions[DEFINITION.starter_region_id].focus_object_id
	var ids: Array[StringName] = model.ids_of_kind("plot")
	return preferred if preferred in ids else (ids[0] if not ids.is_empty() else &"")
func next_plot_id(current: StringName) -> StringName:
	var ids: Array[StringName] = model.ids_of_kind("plot")
	return ids[(ids.find(current) + 1) % ids.size()] if not ids.is_empty() else &""
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(model) and is_instance_valid(gameplay):
			checkpoint()
