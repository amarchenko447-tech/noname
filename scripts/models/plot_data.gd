class_name PlotData
extends RefCounted
## Reserved crop attachment state, separate from map placement and definition.
## No planting/growth mechanics are implemented in Phase 0.75.
var plot_id: StringName
var crop_id: StringName = &""
func _init(stable_plot_id: StringName = &"") -> void:
	plot_id = stable_plot_id
