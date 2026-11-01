class_name IsoGrid
extends RefCounted
const Metrics = preload("res://scripts/world/grid_metrics.gd")
var metrics: Resource
func _init(configuration: Resource = null) -> void:
	metrics = configuration if configuration != null else Metrics.new()
func cell_to_world(cell: Vector2i) -> Vector2:
	return metrics.origin + Vector2((cell.x - cell.y) * metrics.tile_size.x * 0.5, (cell.x + cell.y) * metrics.tile_size.y * 0.5)
func world_to_cell_fractional(point: Vector2) -> Vector2:
	var relative: Vector2 = point - metrics.origin
	return Vector2(relative.x / metrics.tile_size.x + relative.y / metrics.tile_size.y, relative.y / metrics.tile_size.y - relative.x / metrics.tile_size.x)
func world_to_cell(point: Vector2) -> Vector2i:
	var cell := world_to_cell_fractional(point)
	return Vector2i(floori(cell.x + 0.5), floori(cell.y + 0.5))
func chunk_of(cell: Vector2i, chunk_size: int = 16) -> Vector2i:
	assert(chunk_size > 0)
	return Vector2i(floori(float(cell.x) / chunk_size), floori(float(cell.y) / chunk_size))
