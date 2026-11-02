extends SceneTree
## Injects OS geometry through a HUD subclass. Does not claim physical-device QA.
var assertions: int=0
var failures: int=0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,text: String) -> void:
	assertions+=1
	if not value:
		failures+=1
		push_error("FAIL: "+text)
func settle() -> void:
	for i in range(10): await process_frame
func run() -> void:
	var settings:=root.get_node("SettingsManager")
	var original: String=settings.settings_path
	for file in ["user://qa_mobile_layout.cfg","user://qa_mobile_layout.cfg.backup"]: DirAccess.remove_absolute(file)
	settings.load_preferences("user://qa_mobile_layout.cfg","en")
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	var farm: Node=current_scene
	farm.hud.free()
	var hud: Variant=load("res://tests/fixtures/safe_area_hud.gd").new()
	hud.model=root.get_node("WorldService").model
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	farm.hud = hud
	hud.layout_changed.connect(farm._on_layout_changed)
	farm.hud_layer.add_child(hud)
	farm.input_router.can_start = hud.can_start_world
	hud.set_selected(&"starter_plot_05")
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(430,932),Vector2i(768,1024)]:
		root.size=dimensions
		for geometry in [Rect2(0,141,1170,2289),Rect2(0,240,1170,1992),Rect2()]:
			hud.usable=geometry
			for locale in settings.SUPPORTED:
				settings.set_language(locale)
				await settle()
				check(root.get_visible_rect().encloses(hud.safe.get_global_rect()),"inset HUD fits "+str(dimensions)+locale)
				for kind in ["settings","language","guide","notes","seeds"]:
					hud._open_dialog(kind)
					await settle()
					var panel: Control=hud.dialog_margins.get_node("Center/DialogPanel")
					var margins: Vector4=hud._safe_margins()
					var usable: Rect2=Rect2(margins.x,margins.y,hud.size.x-margins.x-margins.z,hud.size.y-margins.y-margins.w)
					check(usable.grow(1).encloses(panel.get_global_rect()),"safe dialog "+str(dimensions)+locale+kind+str(geometry))
					hud._close_dialog(false)
	hud.queue_free()
	await settle()
	settings.load_preferences(original)
	print("MOBILE LAYOUT: ",assertions," assertions, ",failures," failures")
	quit(1 if failures else 0)
