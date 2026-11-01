class_name CropState
extends RefCounted
## Crop state references a stable plot ID; no map placement or UI dependencies.
var plot_id: StringName
var species_id: StringName
var cycle_id: int = 0
var planted_at_utc: int = 0
var ready_at_utc: int = 0
func stage_at(now: int) -> int:
	if now >= ready_at_utc:
		return 3
	var fraction: float = clampf(float(now - planted_at_utc) / maxi(1, ready_at_utc - planted_at_utc), 0, 1)
	return 2 if fraction >= 0.60 else (1 if fraction >= 0.25 else 0)
func remaining(now: int) -> int:
	return maxi(0, ready_at_utc - now)
func to_data(now: int) -> Dictionary:
	return {"plot_id": String(plot_id), "species_id": String(species_id), "cycle_id": cycle_id,
		"planted_at_utc": planted_at_utc, "ready_at_utc": ready_at_utc,
		"stage": stage_at(now), "ready": now >= ready_at_utc}
static func from_data(raw: Dictionary) -> CropState:
	var crop := CropState.new()
	crop.plot_id = StringName(raw.plot_id)
	crop.species_id = StringName(raw.species_id)
	crop.cycle_id = int(raw.cycle_id)
	crop.planted_at_utc = int(raw.planted_at_utc)
	crop.ready_at_utc = int(raw.ready_at_utc)
	return crop
