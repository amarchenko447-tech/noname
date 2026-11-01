class_name WorldObjectDefinition
extends Resource
## Immutable content; footprint is logical occupancy, independent of sprite bounds.
@export var definition_id: StringName
@export_enum("plot", "plant", "building", "decoration") var kind: String = "plot"
@export var occupancy_layer: StringName = &"solid"
@export var footprint: Array[Vector2i] = [Vector2i.ZERO]
@export var visual_key: StringName = &"garden_bed"
@export var visual_half_size: Vector2 = Vector2(160, 128)
