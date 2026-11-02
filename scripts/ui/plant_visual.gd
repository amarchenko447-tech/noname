class_name PlantVisual
extends Node2D
## Six original silhouettes / four growth poses. No input, physics or gameplay clock.
signal effect_finished
const Art = preload("res://scripts/ui/garden_drawing.gd")
var species_id: StringName = &"sunny_carrot"
var stage: int = 0
var idle_time: float = 0.0
var reduced_motion: bool = false
var particles_enabled: bool = true
var show_indicator: bool = true
var effect_kind: StringName = &""
var effect_progress: float = 1.0
var effect_tween: Tween
var _alpha: float = 1.0
func tone(hex: String) -> Color:
	var color := Color(hex)
	color.a *= _alpha
	return color
func set_pose(species: StringName, growth_stage: int) -> void:
	species_id = species
	stage = clampi(growth_stage, 0, 3)
	queue_redraw()
func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		if is_instance_valid(effect_tween):
			effect_tween.kill()
		effect_kind = &""
		effect_progress = 1.0
		effect_finished.emit()
	queue_redraw()
func play_effect(kind: StringName) -> void:
	if is_instance_valid(effect_tween):
		effect_tween.kill()
	effect_kind = kind
	effect_progress = 0.0
	var duration: float = {&"plant": 0.45, &"grow": 0.7, &"mature": 0.8}.get(kind, 0.7)
	if reduced_motion:
		duration = 0.12
	effect_tween = create_tween()
	effect_tween.tween_method(_progress, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	effect_tween.tween_callback(func() -> void:
		effect_kind = &""
		effect_finished.emit()
		queue_redraw())
func _progress(value: float) -> void:
	effect_progress = value
	queue_redraw()
func _leaf(point: Vector2, length: Vector2, tint: String, angle: float = 0.0) -> void:
	var unfold: float = 1.0 if reduced_motion or effect_kind == &"" else lerpf(0.55, 1.0, effect_progress)
	Art.leaf(self, point, length * Vector2(unfold, 1), tone(tint), angle)
func _stem(a: Vector2, b: Vector2, width: float = 6.0) -> void:
	draw_line(a, b, tone("4f885f"), width, true)
func _circle(point: Vector2, radius: float, tint: String) -> void:
	draw_circle(point, radius, tone(tint), true, -1, true)
func _polygon(points: PackedVector2Array, tint: String) -> void:
	draw_colored_polygon(points, tone(tint))
func _draw() -> void:
	var t: float = 0.0 if reduced_motion else idle_time
	var p: float = effect_progress
	_alpha = clampf((p - 0.42) / 0.58, 0, 1) if effect_kind == &"plant" else 1.0
	if reduced_motion and effect_kind != &"":
		_alpha = p
	Art.ellipse(self, Vector2(5, 5), Vector2(42 + stage * 3, 13), Color(0.19, 0.30, 0.20, 0.16 * _alpha))
	if stage == 3:
		var glow: float = 0.07 + (sin(t * 1.2) + 1) * 0.025
		Art.ellipse(self, Vector2(0, -38), Vector2(63, 59), Color(1, 0.93, 0.62, glow * _alpha))
	var bounce: float = sin(p * PI) * 0.10 if effect_kind in [&"grow", &"mature"] and not reduced_motion else 0.0
	var scale_value: float = (lerpf(0.84, 1.0, p) + bounce) if effect_kind in [&"grow", &"mature"] and not reduced_motion else 1.0
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_value)
	match species_id:
		&"sunny_carrot": _carrot(t)
		&"moonberry": _berry(t)
		&"starflower": _starflower(t)
		&"bubble_cactus": _cactus(t)
		&"crystal_mushroom": _mushroom(t)
		&"rainbow_tulip": _tulip(t)
	draw_set_transform(Vector2.ZERO)
	_alpha = 1.0
	if stage == 3 and show_indicator:
		Art.ellipse(self, Vector2(89, 31), Vector2(27, 21), Color("fff4c7"))
		draw_polyline(PackedVector2Array([Vector2(76, 31), Vector2(85, 40), Vector2(102, 22)]), Color("547544"), 5, true)
	if effect_kind != &"" and not reduced_motion:
		if effect_kind == &"plant" and p < 0.45:
			var seed := Vector2(0, -125 * pow(1 - p / 0.45, 2))
			Art.leaf(self, seed, Vector2(8, 12), Color("d9ac70"), -0.3)
		if particles_enabled:
			for i in range(5):
				var progress: float = clampf((p - (0.35 if effect_kind == &"plant" else 0.0)) / 0.65, 0, 1)
				var point := Vector2.from_angle(-PI + i * PI / 5.0) * (12 + progress * 60)
				point.y -= progress * 22
				var tint := Color("b18660") if effect_kind == &"plant" else Color("fff2bc")
				tint.a = sin(progress * PI) * 0.8
				draw_circle(point, 3.5, tint, true, -1, true)
func _sprout(seed_color: String) -> void:
	Art.ellipse(self, Vector2.ZERO, Vector2(19, 8), tone("a07850"))
	_circle(Vector2(0, -5), 7, seed_color)
	_stem(Vector2.ZERO, Vector2(0, -24), 4)
	_leaf(Vector2(-9, -23), Vector2(13, 6), "8dbb75", 0.5)
	_leaf(Vector2(9, -28), Vector2(14, 7), "b4d88c", -0.5)
func _carrot(t: float) -> void:
	if stage == 0:
		_sprout("e7a25b")
		return
	var height: float = [0, 31, 50, 65][stage]
	var width: float = [0, 16, 24, 31][stage]
	_polygon(Art.rounded_polygon(PackedVector2Array([Vector2(-width,-height), Vector2(width,-height), Vector2(width * 0.65,-height * 0.50), Vector2(0,5), Vector2(-width * 0.7,-height * 0.55)]),0.16),"e88f48")
	_polygon(Art.rounded_polygon(PackedVector2Array([Vector2(-width,-height), Vector2(-width * 0.1,-height), Vector2(1,0), Vector2(-width * 0.7,-height * 0.55)]),0.1),"f7b265")
	for i in range(stage + 1):
		draw_line(Vector2(-width * 0.45,-height * 0.8 + i * 12),Vector2(width * 0.12,-height * 0.72 + i * 12),tone("c8753f"),3,true)
	var sway: float = sin(t * TAU / 3.8) * 0.10
	for i in range(stage + 3):
		var angle: float = -PI + i * PI / (stage + 2) + sway
		var root := Vector2(0, -height + 2)
		var end: Vector2 = root + Vector2(cos(angle) * (27 + stage * 4), -24 - absf(sin(angle)) * 33)
		_stem(root,end,4)
		_leaf(end,Vector2(10 + stage,25),"69a66b" if i % 2 == 0 else "96c77d", angle * 0.35)
func _berry(t: float) -> void:
	if stage == 0:
		_sprout("a98ac2")
		return
	var height: float = 34 + stage * 17
	_stem(Vector2.ZERO,Vector2(0,-height),6)
	for i in range(stage + 1):
		var side: int = -1 if i % 2 == 0 else 1
		var center := Vector2(side * (20 + i * 3), -18 - i * 16)
		_stem(Vector2(0,center.y+8),center,4)
		_leaf(center+Vector2(side*11,-16),Vector2(20,10),"a5d8bf",side * -0.6 + sin(t*1.3+i)*0.05)
		Art.ellipse(self,center+Vector2(side*11,-16),Vector2(23,13),Color(0.75,0.90,0.79, (0.08 + (sin(t*1.4)+1)*0.04) * _alpha))
		if stage >= 2:
			var bob: float = sin(t*1.1+i)*1.8
			_circle(center+Vector2(0,bob),13+stage*2,"8164ad")
			_circle(center+Vector2(-5,-5+bob),7,"ad8ac9")
			Art.flower(self,center+Vector2(0,-12+bob),tone("c4b4db"),4)
	if stage == 1:
		_circle(Vector2(0,-height),9,"c3a0d5")
func _starflower(t: float) -> void:
	if stage == 0:
		_sprout("e6c770")
		return
	var height: float = 33 + stage * 22
	_stem(Vector2.ZERO,Vector2(0,-height),6)
	_leaf(Vector2(-17,-24),Vector2(26,10),"82b779",0.6)
	if stage >= 2:
		_leaf(Vector2(20,-43),Vector2(28,11),"a5ca84",-0.6)
	var center := Vector2(sin(t*1.4)*1.5,-height)
	if stage == 1:
		_leaf(center,Vector2(11,16),"c5ce7b",-0.1)
	elif stage == 2:
		for i in range(3):
			_leaf(center+Vector2((i-1)*10,0),Vector2(13,24),"e7c462",(i-1)*0.4)
	else:
		var star := PackedVector2Array()
		for i in range(10):
			var angle: float = -PI/2 + i*TAU/10 + sin(t*1.3)*0.035
			star.append(center+Vector2.from_angle(angle)*(40 if i%2==0 else 20))
		_polygon(Art.rounded_polygon(star,0.07),"f4ca58")
		_circle(center,15,"dfa64c")
		_circle(center+Vector2(-4,-4),8,"ffe5a0")
func _cactus(t: float) -> void:
	if stage == 0:
		Art.ellipse(self,Vector2.ZERO,Vector2(18,8),tone("a07850"))
		_leaf(Vector2(0,-13),Vector2(12,15),"97b77f")
		return
	var radius: float = 15 + stage * 10
	var center := Vector2(0,-radius)
	_leaf(center,Vector2(radius,radius*1.15),"75ae89")
	_leaf(center+Vector2(-radius*0.3,-3),Vector2(radius*0.55,radius),"9ac79c")
	for i in range(-1,2):
		draw_arc(center+Vector2(i*radius*0.24,0),radius*0.88,-1.35,1.35,18,tone("629b7c"),2,true)
	for i in range(stage+2):
		var point := center+Vector2(sin(i*2.4)*radius*0.7,cos(i*2.4)*radius*0.65)
		draw_line(point-Vector2(3,1),point+Vector2(3,-1),tone("e3e3b7"),2,true)
	if stage >= 2:
		_leaf(Vector2(-radius-7,-22),Vector2(15,20),"90bd92",-0.3)
	if stage == 3:
		_leaf(Vector2(radius+5,-30),Vector2(18,24),"89b98e",0.4)
		Art.flower(self,Vector2(8,-radius*2.15),tone("eaa8b3"),9)
	for i in range(stage):
		var progress: float = fmod(t*0.12+i*0.36,1)
		var bubble := Vector2(28+i*13+sin(t+i)*3,-42-progress*45)
		var alpha: float = (0.24 + sin(progress*PI)*0.20) * _alpha
		draw_arc(bubble,7+i*2,0,TAU,24,Color(0.76,0.92,0.85,alpha),2,true)
func _crystal(point: Vector2, size_value: float) -> void:
	_polygon(PackedVector2Array([point+Vector2(-size_value*0.4,0),point+Vector2(-size_value*0.5,-size_value),point+Vector2(0,-size_value*1.5),point+Vector2(size_value*0.5,-size_value),point+Vector2(size_value*0.4,0)]),"83cddc")
	_polygon(PackedVector2Array([point,point+Vector2(0,-size_value*1.5),point+Vector2(size_value*0.5,-size_value),point+Vector2(size_value*0.4,0)]),"b9e5e5")
func _mushroom(t: float) -> void:
	if stage == 0:
		Art.ellipse(self,Vector2.ZERO,Vector2(17,7),tone("a07850"))
		_crystal(Vector2(-4,-2),12)
		_circle(Vector2(7,-8),8,"b8dbe0")
		return
	var width: float = 18 + stage * 12
	var height: float = 21 + stage * 12
	_polygon(Art.rounded_polygon(PackedVector2Array([Vector2(-12,1),Vector2(13,1),Vector2(10,-height),Vector2(-10,-height)]),0.15),"d7e7d9")
	Art.ellipse(self,Vector2(0,-height),Vector2(width+4,16),tone("6b9db7"))
	Art.ellipse(self,Vector2(0,-height-10),Vector2(width,25),tone("9acbd5"))
	Art.leaf(self,Vector2(-width*0.25,-height-17),Vector2(width*0.70,10),tone("c9e6dc"),-0.1)
	for i in range(stage+1):
		_crystal(Vector2((i-stage*0.5)*20,-height-22),12+stage*3+(i%2)*6)
	if stage == 3:
		var alpha: float = (sin(t*1.4)+1)*0.18*_alpha
		draw_circle(Vector2(-20,-height-49),4,Color(1,1,0.92,alpha),true,-1,true)
func _tulip(t: float) -> void:
	if stage == 0:
		_sprout("e9a9bc")
		return
	var height: float = 28 + stage * 19
	_stem(Vector2.ZERO,Vector2(0,-height),6)
	_leaf(Vector2(-18,-28),Vector2(11,33),"8fc1a0",-0.55)
	if stage >= 2:
		_leaf(Vector2(18,-35),Vector2(12,41),"b0d4a0",0.45)
	if stage == 1:
		_leaf(Vector2(0,-height),Vector2(13,20),"de9cbd",0)
	else:
		var petals: Array[String] = ["b2b2d9","83c8cb","edbf7c","e99db8","bd9fcd"]
		var count: int = 3 if stage == 2 else 5
		for i in range(count):
			var angle: float = (i-(count-1)*0.5)*0.24 + sin(t*1.1)*0.025
			var tint: Color = tone(petals[i])
			tint = tint.lerp(Color(1,0.92,0.87,tint.a),(sin(t*0.65+i)+1)*0.055)
			Art.leaf(self,Vector2((i-(count-1)*0.5)*10,-height-12),Vector2(18,32+stage*2),tint,angle)
		_leaf(Vector2(-5,-height-14),Vector2(7,25),"f6c4c7",-0.1)
