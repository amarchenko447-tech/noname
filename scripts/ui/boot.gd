extends Control
## Boot loads the local foundation scene; no artificial loading delay.
func _ready() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/garden/garden.tscn")
