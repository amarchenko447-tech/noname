class_name WorldInputRouter
extends Node
## Tap is committed on release. Gesture lifetime/ownership is independent of art.
signal tapped(screen_point: Vector2)
var rig: Node2D
var can_start: Callable
var touches: Dictionary = {}
var ignored: Dictionary = {}
var touch_origin: Vector2
var tap_eligible: bool = false
var pinch_seen: bool = false
var mouse_down: bool = false
var mouse_origin: Vector2
var mouse_last: Vector2
var mouse_dragged: bool = false
var middle_pan: bool = false
const DRAG_THRESHOLD: float = 8.0
func cancel() -> void:
	touches.clear()
	ignored.clear()
	tap_eligible = false
	pinch_seen = false
	mouse_down = false
	middle_pan = false
	mouse_dragged = false
func _input(event: InputEvent) -> void:
	if not is_instance_valid(rig) or not can_start.is_valid():
		return
	if event is InputEventScreenTouch:
		_touch(event)
	elif event is InputEventScreenDrag:
		_drag(event)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		_mouse_button(event)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		_mouse_motion(event)
func _touch(event: InputEventScreenTouch) -> void:
	if event.canceled:
		cancel()
		return
	if event.pressed:
		if not can_start.call(event.position) or not ignored.is_empty():
			# A UI-owned touch cancels a pending world action, and is never
			# stolen when that finger crosses from a button into the world.
			tap_eligible = false
			for id in touches:
				ignored[id] = true
			touches.clear()
			ignored[event.index] = true
			return
		if touches.is_empty():
			touch_origin = event.position
			tap_eligible = ignored.is_empty()
			pinch_seen = false
		touches[event.index] = event.position
		if touches.size() >= 2:
			tap_eligible = false
			pinch_seen = true
		get_viewport().set_input_as_handled()
	else:
		if ignored.has(event.index):
			ignored.erase(event.index)
			return
		if not touches.has(event.index):
			return
		var should_tap: bool = touches.size() == 1 and tap_eligible and not pinch_seen and touch_origin.distance_to(event.position) < DRAG_THRESHOLD and can_start.call(event.position)
		touches.erase(event.index)
		if touches.is_empty():
			tap_eligible = false
			pinch_seen = false
		if should_tap:
			tapped.emit(event.position)
		get_viewport().set_input_as_handled()
func _pair() -> Array:
	var ids: Array = touches.keys()
	ids.sort()
	return [touches[ids[0]], touches[ids[1]]]
func _drag(event: InputEventScreenDrag) -> void:
	if not touches.has(event.index):
		return
	if touches.size() >= 2:
		var previous := _pair()
		touches[event.index] = event.position
		var current := _pair()
		var old_distance: float = previous[0].distance_to(previous[1])
		if old_distance > 0.01:
			rig.gesture_zoom_pan((previous[0] + previous[1]) * 0.5, (current[0] + current[1]) * 0.5, current[0].distance_to(current[1]) / old_distance)
	else:
		var previous: Vector2 = touches[event.index]
		touches[event.index] = event.position
		if touch_origin.distance_to(event.position) >= DRAG_THRESHOLD:
			tap_eligible = false
		if not tap_eligible:
			rig.pan_screen(event.position - previous)
	get_viewport().set_input_as_handled()
func _mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if event.pressed and can_start.call(event.position):
			mouse_down = false
			rig.zoom_at(1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12, event.position)
			get_viewport().set_input_as_handled()
		return
	if event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
		return
	if event.pressed:
		if not can_start.call(event.position):
			return
		mouse_down = true
		mouse_origin = event.position
		mouse_last = event.position
		mouse_dragged = false
		middle_pan = event.button_index == MOUSE_BUTTON_MIDDLE
		get_viewport().set_input_as_handled()
	elif mouse_down:
		var should_tap: bool = not middle_pan and not mouse_dragged and event.position.distance_to(mouse_origin) < DRAG_THRESHOLD and can_start.call(event.position)
		mouse_down = false
		if should_tap:
			tapped.emit(event.position)
		get_viewport().set_input_as_handled()
func _mouse_motion(event: InputEventMouseMotion) -> void:
	if not mouse_down:
		return
	if mouse_origin.distance_to(event.position) >= DRAG_THRESHOLD:
		mouse_dragged = true
	if middle_pan or mouse_dragged:
		rig.pan_screen(event.position - mouse_last)
	mouse_last = event.position
	get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel()
