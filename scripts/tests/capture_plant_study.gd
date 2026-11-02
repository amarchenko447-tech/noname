extends SceneTree
const Visual = preload("res://scripts/ui/plant_visual.gd")
const FONT = preload("res://assets/fonts/OpenSans-Regular.ttf")
func _initialize() -> void:
	call_deferred("run")
func label(parent: Node, text: String, point: Vector2, width: float, size_value: int) -> void:
	var caption := Label.new()
	caption.text=text
	caption.position=point
	caption.size.x=width
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font",FONT)
	caption.add_theme_font_size_override("font_size",size_value)
	caption.add_theme_color_override("font_color",Color("294c3c"))
	parent.add_child(caption)
func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(900,1100)
	TranslationServer.set_locale("ru")
	var page := Node2D.new()
	root.add_child(page)
	var background := ColorRect.new()
	background.color=Color("fff9e9")
	background.size=Vector2(900,1100)
	page.add_child(background)
	label(page,TranslationServer.translate("UI_COLLECTION"),Vector2(24,18),850,30)
	label(page,TranslationServer.translate("GAME_TAGLINE"),Vector2(24,62),850,16)
	var stage_keys: Array[String] = ["STAGE_SEED","STAGE_SPROUT","STAGE_GROWING","STAGE_MATURE"]
	for stage in range(4):
		label(page,TranslationServer.translate(stage_keys[stage]),Vector2(235+stage*165,109),155,18)
	var catalog: RefCounted = root.get_node("WorldService").catalog
	var row: int=0
	for definition in catalog.CONTENT:
		var foot: float=260+row*155
		label(page,TranslationServer.translate(definition.name_key),Vector2(24,foot-68),200,17)
		for stage in range(4):
			var visual := Visual.new()
			visual.set_pose(definition.species_id,stage)
			visual.show_indicator=false
			visual.idle_time=2.25
			visual.position=Vector2(290+stage*165,foot)
			visual.scale=Vector2.ONE*0.72
			page.add_child(visual)
		row+=1
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var output: String=OS.get_cmdline_user_args()[0]
	var result: Error=root.get_texture().get_image().save_png(output)
	print("PLANT STUDY ",output)
	quit(0 if result==OK else 1)
