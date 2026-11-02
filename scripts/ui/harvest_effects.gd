extends Control
## At most three three-coin flights. Pure presentation, never grants currency.
var flights: Array[Dictionary] = []
var reduced_motion: bool = false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func play(start: Vector2, target: Vector2) -> void:
	if flights.size() >= 3:
		var old: Dictionary = flights.pop_front()
		old.tween.kill()
	var flight: Dictionary = {"start":start,"target":target,"progress":0.0}
	flights.append(flight)
	var tween := create_tween()
	flight.tween = tween
	tween.tween_method(func(progress: float) -> void:
		flight.progress = progress
		queue_redraw(),0.0,1.0,0.12 if reduced_motion else 0.6)
	tween.tween_callback(func() -> void:
		flights.erase(flight)
		queue_redraw())
func _draw() -> void:
	for flight in flights:
		var p: float = flight.progress
		for i in range(3):
			var progress: float = clampf((p-i*0.06)/0.88,0,1)
			var point: Vector2 = flight.start.lerp(flight.target,progress) + Vector2(i*7-7,-sin(progress*PI)*(28+i*8))
			if reduced_motion:
				point = flight.target + Vector2(i*7-7,0)
			var color := Color("e6b34d")
			color.a = 1-progress
			draw_circle(point,6,color,true,-1,true)
			draw_arc(point,4,-2.4,0,12,Color(1,0.92,0.64,color.a),1.4,true)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		for flight in flights:
			flight.tween.kill()
		flights.clear()
		queue_redraw()
