extends SceneTree
var assertions: int = 0
var failures: int = 0
var farm: Node
var service: Node
var game: Node
var clock: Node
var settings: Node
const PATH = "user://qa_gameplay_ui.json"
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
func settle() -> void:
	for frame in range(6):
		await process_frame
func click(point: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = point
		root.push_input(event,true)
		await process_frame
	await settle()
func tap(id: StringName) -> void:
	var point: Vector2 = farm.world.screen_position(id)
	for down in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = down
		root.push_input(event,true)
	await settle()
func labels(parent: Node) -> Array[Label]:
	var result: Array[Label] = []
	for child in parent.get_children():
		if child is Label:
			result.append(child)
		result.append_array(labels(child))
	return result
func run() -> void:
	create_timer(45).timeout.connect(func() -> void:
		push_error("UI test timed out")
		quit(1))
	service = root.get_node("WorldService")
	game = root.get_node("GameState")
	clock = root.get_node("TimeService")
	settings = root.get_node("SettingsManager")
	var old_path: String = service.store.path
	var old_locale: String = settings.locale
	var old_motion: bool = settings.reduced_motion
	var old_preferences_path: String = settings.settings_path
	DirAccess.remove_absolute("user://qa_gameplay_ui_preferences.cfg")
	DirAccess.remove_absolute("user://qa_gameplay_ui_preferences.cfg.backup")
	settings.load_preferences("user://qa_gameplay_ui_preferences.cfg",old_locale)
	for path in [PATH,PATH.get_basename()+".backup.json"]:
		DirAccess.remove_absolute(path)
	clock.begin_mock(1000000)
	service.use_storage(PATH)
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	farm = current_scene
	farm.tick.stop()
	var ids: Array[StringName] = service.model.ids_of_kind("plot")
	for id in ids:
		await tap(id)
		check(farm.hud.dialog_kind == "seeds" and farm.hud.seed_picker.plot_id == id, "empty-bed tap opens correct seed picker")
		check(farm.hud.seed_picker.cards.size() == 6, "all six resource previews")
		await click(farm.hud.seed_picker.confirm.get_global_rect().get_center())
		check(game.crop_at(id) != null and farm.world.crop_views.has(id), "GUI confirmation plants actual model and visual")
		farm.hud._close_dialog(false)
		await settle()
	check(service.gameplay.coins == 105, "GUI spends once per bed")
	check(farm.world.crop_views.size() == 9 and farm.world.crop_badges.size() == 9, "every plot has crop and countdown")
	check(farm.world.active_effects.size() <= 3, "transient plant effects have a global particle budget")
	for age in [8,18,30]:
		clock.set_mock_wall(1000000+age)
		farm._on_tick()
		for id in ids:
			var expected: int = 1 if age == 8 else (2 if age == 18 else 3)
			check(farm.world.crop_views[id].stage == expected, "model stage synchronizes to visible pose")
			check(farm.world.crop_badges[id].visible == (age < 30), "countdown replaced by ready indicator")
	for id in ids:
		await tap(id)
		check(game.crop_at(id) == null, "tap mature crop harvests")
	check(service.gameplay.coins == 195 and service.gameplay.statistics.total_harvests == 9, "GUI harvest rewards exactly once")
	check(farm.world.crop_views.is_empty(), "harvest frees every crop visual")
	check(farm.hud.effects.flights.size() <= 3, "coin flights bounded")
	if is_instance_valid(farm.hud.balance_tween):
		farm.hud.balance_tween.custom_step(1.0)
	check(farm.hud.coin_label.text == "195", "animated counter reaches authoritative balance")
	service.reload_world()
	check(service.gameplay.coins == 195 and service.gameplay.crops.is_empty(), "GUI economy survives reload without replay")
	# All languages and both phone sizes; two-line names keep their font size.
	for dimensions in [Vector2i(390,844),Vector2i(430,932)]:
		root.size = dimensions
		await settle()
		for locale in settings.SUPPORTED:
			settings.set_language(locale)
			farm.hud.open_seeds(ids[0])
			farm.hud.seed_picker.selected_species = &"rainbow_tulip"
			farm.hud.seed_picker.refresh_texts()
			if is_instance_valid(farm.hud.dialog_tween):
				farm.hud.dialog_tween.custom_step(1.0)
			await settle()
			var panel: PanelContainer = farm.hud.dialog_margins.get_node("Center/DialogPanel")
			check(farm.hud.get_global_rect().encloses(panel.get_global_rect()), "seed panel inside phone viewport "+locale)
			check(farm.hud.seed_picker.confirm.size.y >= 48, "comfortable confirm button")
			for species in farm.hud.seed_picker.cards:
				var widgets: Dictionary = farm.hud.seed_picker.cards[species]
				check(widgets.name.text == TranslationServer.translate(service.catalog.definitions[species].name_key), "all visible plant names localized")
				check(widgets.name.get_theme_font_size("font_size") >= 15, "names never shrink to fit")
				check(widgets.button.get_global_rect().encloses(widgets.availability.get_global_rect()), "availability does not overflow its card")
				check(widgets.button.get_global_rect().encloses(widgets.duration.get_global_rect()), "duration inside card")
			farm.hud._close_dialog(false)
			await settle()
	# Affordability through real UI: buy the tulip, then reject an expensive seed.
	settings.set_language("en")
	farm.world.select_plot(ids[0])
	farm.hud.open_seeds(ids[0])
	farm.hud.seed_picker.selected_species = &"rainbow_tulip"
	farm.hud.seed_picker.refresh_texts()
	await settle()
	await click(farm.hud.seed_picker.confirm.get_global_rect().get_center())
	farm.hud._close_dialog(false)
	check(service.gameplay.coins == 45 and game.crop_at(ids[0]).species_id == &"rainbow_tulip","UI buys selected expensive species")
	farm.hud.open_seeds(ids[1])
	farm.hud.seed_picker.selected_species = &"crystal_mushroom"
	farm.hud.seed_picker.refresh_texts()
	await settle()
	check(farm.hud.seed_picker.confirm.disabled,"insufficient currency disables confirmation")
	await click(farm.hud.seed_picker.confirm.get_global_rect().get_center())
	check(service.gameplay.coins == 45 and game.crop_at(ids[1]) == null,"disabled UI purchase cannot spend")
	farm.hud._close_dialog(false)
	farm.world.select_plot(ids[2])
	# Touch drag over a ready plant must never collect it.
	settings.set_language("en")
	settings.set_reduced_motion(true)
	check(game.plant(ids[2],&"sunny_carrot",game.cycle_at(ids[2])).ok,"plant for gesture safety test")
	clock.advance_mock(30)
	farm._on_tick()
	check(farm.world.plot_at(farm.world.centers[ids[2]]+Vector2(0,-120)) == ids[2],"plant canopy is tappable beyond soil bounds")
	var balance: int = service.gameplay.coins
	var center: Vector2 = farm.world.screen_position(ids[2])
	var down := InputEventScreenTouch.new()
	down.index=0
	down.position=center
	down.pressed=true
	root.push_input(down,true)
	var drag := InputEventScreenDrag.new()
	drag.index=0
	drag.position=center+Vector2(25,10)
	root.push_input(drag,true)
	down.pressed=false
	down.position=drag.position
	root.push_input(down,true)
	check(service.gameplay.coins == balance and game.crop_at(ids[2]) != null,"drag over mature crop cannot harvest")
	check(farm.world.crop_views[ids[2]].reduced_motion,"reduced motion applies to plants")
	check(farm.world.crop_views[ids[2]].effect_kind == &"" or farm.world.crop_views[ids[2]].effect_tween != null,"reduced reveal uses fade instead of particles")
	# Exercise every card callback and species through GUI clicks, not direct selection.
	farm._focus_garden()
	for definition in service.catalog.CONTENT:
		var id: StringName = ids[3]
		await tap(id)
		var card: Button = farm.hud.seed_picker.cards[definition.species_id].button
		await click(card.get_global_rect().get_center())
		check(farm.hud.seed_picker.selected_species == definition.species_id,"card callback selects its own species")
		var starting: int = service.gameplay.coins
		await click(farm.hud.seed_picker.confirm.get_global_rect().get_center())
		farm.hud._close_dialog(false)
		check(game.crop_at(id) != null and game.crop_at(id).species_id == definition.species_id,"GUI plants every species")
		clock.advance_mock(definition.growth_seconds)
		farm._on_tick()
		await tap(id)
		check(game.crop_at(id) == null and service.gameplay.coins == starting-definition.seed_cost+definition.reward_coins,"GUI harvest every species exactly once")
	# A long translated write error must shrink the scrolling list, not overflow.
	settings.set_language("de")
	farm.world.select_plot(ids[4])
	farm.hud.open_seeds(ids[4])
	await settle()
	var before_error: int = service.gameplay.coins
	service.store.simulate_write_failure = true
	await click(farm.hud.seed_picker.confirm.get_global_rect().get_center())
	await settle()
	var error_panel: PanelContainer = farm.hud.dialog_margins.get_node("Center/DialogPanel")
	check(farm.hud.get_global_rect().encloses(error_panel.get_global_rect()),"long localized write error keeps panel on screen")
	check(service.gameplay.coins == before_error and game.crop_at(ids[4]) == null,"UI write error never charges or plants")
	service.store.simulate_write_failure = false
	farm.hud._close_dialog(false)
	settings.load_preferences(old_preferences_path)
	DirAccess.remove_absolute("user://qa_gameplay_ui_preferences.cfg")
	DirAccess.remove_absolute("user://qa_gameplay_ui_preferences.cfg.backup")
	clock.use_real_clock()
	service.use_storage(old_path)
	for path in [PATH,PATH.get_basename()+".backup.json"]:
		DirAccess.remove_absolute(path)
	print("GAMEPLAY UI: %d assertions, %d failures" % [assertions,failures])
	quit(0 if failures == 0 else 1)
