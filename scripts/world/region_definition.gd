class_name RegionDefinition
extends Resource
@export var region_id: StringName
@export var bounds: Rect2i = Rect2i(-4, -4, 12, 12)
@export var biome_id: StringName = &"meadow"
@export var scenery_bounds: Rect2 = Rect2(-555, -530, 1110, 990)
@export var initial_objects: Array[Dictionary] = []
@export var focus_object_id: StringName
