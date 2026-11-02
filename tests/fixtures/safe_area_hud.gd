extends "res://scripts/ui/garden.gd"
var physical_screen:=Vector2(1170,2532)
var usable:=Rect2(0,141,1170,2289)
func _safe_margins() -> Vector4:
	return safe_margins_for(size,physical_screen,usable)
