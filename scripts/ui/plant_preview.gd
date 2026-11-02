extends Control
const Visual = preload("res://scripts/ui/plant_visual.gd")
var species_id: StringName
var preview_height: float = 64
var preview_scale: float = 0.36
var visual: Node2D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(48,preview_height)
	visual = Visual.new()
	visual.show_indicator = false
	visual.set_pose(species_id,3)
	visual.reduced_motion = true
	add_child(visual)
	resized.connect(_layout)
	_layout()
func _layout() -> void:
	visual.position = Vector2(size.x*0.5,size.y-5)
	visual.scale = Vector2.ONE * preview_scale
