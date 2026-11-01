class_name PlantCatalog
extends RefCounted
const CONTENT = [preload("res://resources/plants/sunny_carrot.tres"), preload("res://resources/plants/moonberry.tres"), preload("res://resources/plants/starflower.tres"), preload("res://resources/plants/bubble_cactus.tres"), preload("res://resources/plants/crystal_mushroom.tres"), preload("res://resources/plants/rainbow_tulip.tres")]
var definitions: Dictionary = {}
func _init() -> void:
	for plant in CONTENT:
		definitions[plant.species_id] = plant
