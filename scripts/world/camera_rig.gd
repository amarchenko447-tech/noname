class_name FarmCameraRig
extends Node2D
signal view_changed
var camera: Camera2D
var focus: Vector2 = Vector2.ZERO
var base_zoom: float = 0.3425926
var relative_zoom: float = 1.0
var viewport_size: Vector2 = Vector2(390, 844)
var anchor: Vector2 = Vector2(195, 396.5)
var play_area := Rect2(0, 190, 390, 400)
var bounds := Rect2(-555, -530, 1110, 990)
const MIN_RELATIVE_ZOOM: float = 0.72
const MAX_RELATIVE_ZOOM: float = 2.1
func _ready() -> void:
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	camera.enabled = true
	add_child(camera)
	_apply()
func configure(size: Vector2, area: Rect2, screen_anchor: Vector2, default_zoom: float) -> void:
	viewport_size = size
	play_area = area
	anchor = screen_anchor
	base_zoom = default_zoom
	_apply()
func zoom_value() -> float:
	return base_zoom * relative_zoom
func is_overview() -> bool:
	return relative_zoom < 0.98 or zoom_value() < 0.32
func screen_to_world(screen_point: Vector2) -> Vector2:
	return camera.get_canvas_transform().affine_inverse() * screen_point
func world_to_screen(world_point: Vector2) -> Vector2:
	return camera.get_canvas_transform() * world_point
func max_relative_zoom() -> float:
	return maxf(MAX_RELATIVE_ZOOM,0.70/base_zoom)

func _apply() -> void:
	if not is_instance_valid(camera):
		return
	relative_zoom = clampf(relative_zoom, MIN_RELATIVE_ZOOM, max_relative_zoom())
	var zoom: float = zoom_value()
	# A small pan allowance when the entire garden fits; at larger zoom the
	# available travel grows with the world. Bounds come from model queries.
	var half_travel := Vector2(maxf(80, (bounds.size.x - play_area.size.x / zoom) * 0.5), maxf(80, (bounds.size.y - play_area.size.y / zoom) * 0.5))
	var middle: Vector2 = bounds.get_center()
	focus.x = clampf(focus.x, middle.x - half_travel.x, middle.x + half_travel.x)
	focus.y = clampf(focus.y, middle.y - half_travel.y, middle.y + half_travel.y)
	camera.zoom = Vector2.ONE * zoom
	camera.position = focus + (viewport_size * 0.5 - anchor) / zoom
	camera.force_update_scroll()
	view_changed.emit()
func pan_screen(delta: Vector2) -> void:
	focus -= delta / zoom_value()
	_apply()
func gesture_zoom_pan(previous_center: Vector2, center: Vector2, ratio: float) -> void:
	var before := screen_to_world(previous_center)
	relative_zoom = clampf(relative_zoom * ratio, MIN_RELATIVE_ZOOM, max_relative_zoom())
	_apply()
	focus += before - screen_to_world(center)
	_apply()
func zoom_at(ratio: float, screen_point: Vector2) -> void:
	gesture_zoom_pan(screen_point, screen_point, ratio)
func center_on(point: Vector2, reset_zoom: bool = true) -> void:
	focus = point
	if reset_zoom:
		relative_zoom = 1.0
	_apply()
