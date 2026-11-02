extends Node2D
## Rasterize unchanged static vector art once at >= its maximum displayed density.
## Plants, selection and ambience remain independent live vector layers.
var artist_script: Script
var art_seed: int = 0
var bounds := Rect2(-170,-120,340,260)
var viewport: SubViewport
func _ready() -> void:
	var artist: Node2D = artist_script.new()
	if artist_script == preload("res://scripts/ui/garden_bed.gd"):
		artist.art_seed = art_seed
	if DisplayServer.get_name() == "headless":
		add_child(artist)
		return
	viewport = SubViewport.new()
	viewport.size = Vector2i(bounds.size.ceil())
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	artist.position = -bounds.position
	viewport.add_child(artist)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.position = bounds.position
	sprite.texture = viewport.get_texture()
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	sprite.material = material
	add_child(sprite)
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
