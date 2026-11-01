class_name PlantDefinition
extends Resource
@export var species_id: StringName
@export var name_key: String
@export var description_key: String
@export_range(1, 100000) var seed_cost: int = 10
@export_range(1, 86400) var growth_seconds: int = 45
@export_range(1, 100000) var reward_coins: int = 18
