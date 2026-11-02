class_name GameplayState
extends RefCounted
const Crop = preload("res://scripts/models/crop_state.gd")
const ECONOMY = preload("res://resources/economy/default.tres")
var coins: int = 0
var crops: Dictionary = {}
var cycles: Dictionary = {}
var statistics: Dictionary = {"total_planted": 0, "total_harvests": 0}
func _init() -> void:
	coins = ECONOMY.starting_balance
func to_data(now: int) -> Dictionary:
	var planted: Array = []
	var ids: Array = crops.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for id in ids:
		planted.append(crops[id].to_data(now))
	var serialized_cycles: Dictionary = {}
	for id in cycles:
		serialized_cycles[String(id)] = cycles[id]
	return {"coins": coins, "crops": planted, "cycles": serialized_cycles, "statistics": statistics.duplicate(true)}
func whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and floorf(float(value)) == float(value)
func load_data(raw: Variant, world: RefCounted, catalog: RefCounted) -> bool:
	if not raw is Dictionary or not whole(raw.get("coins")) or raw.coins < 0 or raw.coins > ECONOMY.max_coins or not raw.get("crops") is Array or not raw.get("cycles") is Dictionary or not raw.get("statistics") is Dictionary:
		return false
	var loaded_cycles: Dictionary = {}
	for id in raw.cycles:
		if not id is String or not world.objects.has(StringName(id)) or world.definitions[world.objects[StringName(id)].definition_id].kind != "plot" or not whole(raw.cycles[id]) or raw.cycles[id] < 0 or raw.cycles[id] > 1000000000:
			return false
		loaded_cycles[StringName(id)] = int(raw.cycles[id])
	var loaded_crops: Dictionary = {}
	for crop in raw.crops:
		if not crop is Dictionary or not crop.get("plot_id") is String or not crop.get("species_id") is String:
			return false
		var id := StringName(crop.plot_id)
		if loaded_crops.has(id) or not loaded_cycles.has(id) or not catalog.definitions.has(StringName(crop.species_id)):
			return false
		for field in ["cycle_id", "planted_at_utc", "ready_at_utc"]:
			if not whole(crop.get(field)):
				return false
		if crop.cycle_id != loaded_cycles[id] or crop.cycle_id < 1 or crop.planted_at_utc <= 0 or crop.ready_at_utc <= crop.planted_at_utc or crop.ready_at_utc > 4102444800 or crop.ready_at_utc - crop.planted_at_utc > 86400:
			return false
		loaded_crops[id] = Crop.from_data(crop)
	var stats: Dictionary = {}
	for key in ["total_planted", "total_harvests"]:
		if not whole(raw.statistics.get(key)) or raw.statistics[key] < 0 or raw.statistics[key] > 1000000000:
			return false
		stats[key] = int(raw.statistics[key])
	coins = int(raw.coins)
	crops = loaded_crops
	cycles = loaded_cycles
	statistics = stats
	return true
