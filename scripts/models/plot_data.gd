class_name PlotData
extends RefCounted
## Foundation only. Crop timestamps and atomic operations arrive in Phase 1.
var id: int
var species_id: StringName = &""
func _init(plot_id: int = 0) -> void:
	id = plot_id
