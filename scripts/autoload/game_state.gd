extends Node
## Crop commands use stable plot IDs, the shared farm snapshot and a clock.
signal growth_changed(ids: Array[StringName])
const Crop = preload("res://scripts/models/crop_state.gd")
const ECONOMY = preload("res://resources/economy/default.tres")
var stages: Dictionary = {}
var stage_save_pending: bool = false
func _ready() -> void:
	WorldService.world_changed.connect(_rebuild_cache)
	_rebuild_cache()
func _rebuild_cache() -> void:
	stage_save_pending = false
	stages.clear()
	for id in WorldService.gameplay.crops:
		stages[id] = WorldService.gameplay.crops[id].stage_at(TimeService.now_utc())
func crop_at(id: StringName) -> RefCounted:
	return WorldService.gameplay.crops.get(id)
func cycle_at(id: StringName) -> int:
	return int(WorldService.gameplay.cycles.get(id, 0))
func _guard(id: StringName) -> String:
	if WorldService.store.status == "blocked":
		return "WORLD_SAVE_BLOCKED"
	if WorldService.busy:
		return "ACTION_BUSY"
	var record: RefCounted = WorldService.model.get_object(id)
	return "PLOT_INVALID" if record == null or WorldService.model.definitions[record.definition_id].kind != "plot" else ""
func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}
func plant(id: StringName, species: StringName, expected_cycle: int) -> Dictionary:
	var error: String = _guard(id)
	if not error.is_empty():
		return _failure(error)
	if crop_at(id) != null or cycle_at(id) != expected_cycle:
		return _failure("PLOT_OCCUPIED")
	if not WorldService.catalog.definitions.has(species):
		return _failure("SEED_UNKNOWN")
	var definition: Resource = WorldService.catalog.definitions[species]
	if WorldService.gameplay.coins < definition.seed_cost:
		return _failure("SHOP_INSUFFICIENT_COINS")
	var game: RefCounted = WorldService.game_candidate()
	var crop := Crop.new()
	crop.plot_id = id
	crop.species_id = species
	crop.cycle_id = expected_cycle + 1
	crop.planted_at_utc = TimeService.now_utc()
	crop.ready_at_utc = crop.planted_at_utc + definition.growth_seconds
	game.coins -= definition.seed_cost
	game.crops[id] = crop
	game.cycles[id] = crop.cycle_id
	game.statistics.total_planted += 1
	var receipt := {"ok": true, "kind": "plant", "plot_id": id, "species_id": species, "cycle_id": crop.cycle_id}
	if not WorldService.commit_game(game, receipt):
		return _failure("WORLD_SAVE_ERROR")
	stages[id] = 0
	return receipt
func harvest(id: StringName, expected_cycle: int) -> Dictionary:
	var error: String = _guard(id)
	if not error.is_empty():
		return _failure(error)
	var crop: RefCounted = crop_at(id)
	if crop == null or crop.cycle_id != expected_cycle or crop.stage_at(TimeService.now_utc()) != 3:
		return _failure("HARVEST_NOT_READY")
	var definition: Resource = WorldService.catalog.definitions[crop.species_id]
	if WorldService.gameplay.coins > ECONOMY.max_coins - definition.reward_coins:
		return _failure("COIN_LIMIT")
	var game: RefCounted = WorldService.game_candidate()
	var old: int = game.coins
	game.coins += definition.reward_coins
	game.crops.erase(id)
	game.statistics.total_harvests += 1
	var receipt := {"ok": true, "kind": "harvest", "plot_id": id, "species_id": crop.species_id,
		"cycle_id": crop.cycle_id, "reward": definition.reward_coins, "old_balance": old}
	if not WorldService.commit_game(game, receipt):
		return _failure("WORLD_SAVE_ERROR")
	stages.erase(id)
	return receipt
func refresh_growth() -> void:
	var changed: Array[StringName] = []
	for id in WorldService.gameplay.crops:
		var current: int = WorldService.gameplay.crops[id].stage_at(TimeService.now_utc())
		if stages.get(id, -1) != current:
			stages[id] = current
			changed.append(id)
	if not changed.is_empty():
		stage_save_pending = true
		growth_changed.emit(changed)
	if stage_save_pending:
		stage_save_pending = not WorldService.checkpoint()
