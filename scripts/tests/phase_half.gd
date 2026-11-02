extends SceneTree
## Phase 0.5 regression/UX/localization tests; intentionally no gameplay systems.
var failures: int = 0
var assertions: int = 0
var settings: Node

func check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		push_error("FAIL: " + description)
		failures += 1

func settle(frames: int = 6) -> void:
	for frame in range(frames):
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func controls(parent: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in parent.get_children():
		if child is Control:
			result.append(child)
		result.append_array(controls(child))
	return result

func click(position: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = position
		root.push_input(event, true)
		await process_frame
	await settle()

func run() -> void:
	settings = root.get_node("SettingsManager")
	var original_locale: String = settings.locale
	var test_path: String = "user://qa_preferences.cfg"
	DirAccess.remove_absolute(test_path)
	settings.load_preferences(test_path, "es_MX")
	check(settings.locale == "es", "first run uses supported regional OS language")
	settings.set_language("pl")
	settings.load_preferences(test_path, "de_DE")
	check(settings.locale == "pl", "saved preference overrides changed system language")
	check(settings.last_save_ok, "preferences written atomically")
	for pair in [["en_US", "en"], ["es-MX", "es"], ["ru_RU", "ru"], ["pl_PL", "pl"], ["pt-BR", "pt_BR"], ["pt_BR", "pt_BR"], ["pt", "pt_BR"], ["pt_PT", "en"], ["ja_JP", "en"], ["fr_CA", "fr"], ["de_AT", "de"]]:
		check(settings.resolve_locale(pair[0]) == pair[1], "locale mapping " + pair[0])
	check(settings.SUPPORTED.size() == 7, "exactly seven selectable locales")
	var csv := FileAccess.open("res://localization/ui.csv", FileAccess.READ)
	var columns := csv.get_csv_line()
	check(columns.size() == 8, "CSV has key plus seven columns")
	var keys: Dictionary = {}
	var glyphs: Dictionary = {}
	var font: Font = load("res://assets/fonts/OpenSans-Regular.ttf")
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size() < 2:
			continue
		check(row.size() == 8, "all locales for " + row[0])
		check(not keys.has(row[0]), "unique translation key " + row[0])
		keys[row[0]] = true
		for i in range(1, row.size()):
			check(not row[i].strip_edges().is_empty(), "nonempty " + row[0] + "/" + columns[i])
			for character in row[i]:
				if character != "\n" and character != "\t":
					glyphs[character] = true
	csv.close()
	for character in glyphs:
		check(font.has_char(character.unicode_at(0)), "font glyph " + character)
	change_scene_to_file("res://scenes/boot/boot.tscn")
	await settle()
	var farm := current_scene
	var garden: Control = farm.hud
	var world: Node2D = farm.world
	var plot_ids: Array[StringName] = garden.model.ids_of_kind("plot")
	check(garden != null and farm.name == "Garden", "actual garden opens")
	var identity: int = farm.get_instance_id()
	var snapshot: Array = []
	for id in plot_ids:
		var plot: RefCounted = garden.model.get_object(id)
		snapshot.append([plot.id, plot.cell])
	# Sentinel save deliberately includes future fields; preference writes must
	# not rewrite this existing gameplay file or change stable model IDs.
	var sentinel_path: String = "user://qa_gameplay_fixture.json"
	var sentinel_text: String = '{"coins":137,"ready_at_utc":2000000000,"species_id":"mint"}'
	var sentinel := FileAccess.open(sentinel_path, FileAccess.WRITE)
	sentinel.store_string(sentinel_text)
	sentinel.close()
	var fallback := Translation.new()
	fallback.locale = "en"
	fallback.add_message("QA_FALLBACK_ONLY", "English fallback")
	TranslationServer.add_translation(fallback)
	for code in settings.SUPPORTED:
		settings.set_language(code)
		check(current_scene.get_instance_id() == identity, "no scene restart " + code)
		check(garden.context_body.text == TranslationServer.translate("PLOT_SELECTED_HINT"), "immediate UI translation " + code)
		check(TranslationServer.translate("QA_FALLBACK_ONLY") == "English fallback", "missing locale key falls back to English " + code)
		var translation: Translation = load("res://localization/ui." + code + ".translation")
		for key in keys:
			check(not translation.get_message(key).is_empty(), "imported translation " + code + "/" + key)
		for i in range(plot_ids.size()):
			var record: RefCounted = garden.model.get_object(plot_ids[i])
			check([record.id, record.cell] == snapshot[i], "stable game identity " + code)
		check(garden.coin_label.text == "150", "coin presentation unchanged " + code)
		check(FileAccess.get_file_as_string(sentinel_path) == sentinel_text, "gameplay save unchanged " + code)
		for dimensions in [Vector2i(390, 844), Vector2i(430, 932)]:
			root.size = dimensions
			await settle()
			var bounds: Rect2 = world.screen_bounds()
			check(garden.get_global_rect().encloses(bounds), "whole garden visible " + code + str(dimensions))
			check(bounds.position.y > garden.header.get_global_rect().end.y, "garden clears header " + code)
			check(bounds.end.y < garden.context_card.get_global_rect().position.y, "garden clears card " + code)
			for control in controls(garden.safe):
				if control is Button:
					check(control.size.x >= 48 and control.size.y >= 48, "button touch size " + code)
				if control is Label:
					check(control.get_theme_font_size("font_size") >= 14, "readable font " + code)
				check(garden.get_global_rect().encloses(control.get_global_rect()), "HUD control inside viewport " + code + " " + str(control))
			for i in range(9):
				# Every edge/corner in each 48×48 logical square must choose
				# that bed even where its visual diamond tapers away.
				for x in [-24.0, -12.0, 0.0, 12.0, 24.0]:
					for y in [-24.0, -12.0, 0.0, 12.0, 24.0]:
						var p: Vector2 = world.centers[plot_ids[i]] + Vector2(x, y) / farm.camera_rig.zoom_value()
						check(world.plot_at(p) == plot_ids[i], "48px effective target bed %d/%s" % [i, code])
			garden._open_settings()
			await settle()
			check(garden.dialog_kind == "settings", "settings opens " + code)
			for control in controls(garden.dialog):
				check(garden.get_global_rect().encloses(control.get_global_rect()), "settings inside viewport " + code)
			garden._open_dialog("language")
			await settle()
			check(garden.language_buttons.size() == 7, "seven visible language choices " + code)
			for button in garden.language_buttons:
				check(button.size.x >= 48 and button.size.y >= 48, "language target " + code)
				check(garden.get_global_rect().encloses(button.get_global_rect()), "language choice fits " + code)
				check(button.button_pressed == (settings.SUPPORTED[garden.language_buttons.find(button)] == code), "selected language marked " + code)
			garden._close_dialog(false)
			await settle()
	# Stable overlap policy: create deliberate overlap without changing geometry.
	var old_half: float = world.touch_half_size
	world.touch_half_size = 200
	var midpoint: Vector2 = (world.centers[plot_ids[0]] + world.centers[plot_ids[1]]) * 0.5
	check(world.plot_at(midpoint) == plot_ids[0], "equidistant overlap resolves lower stable ID")
	check(world.plot_at(midpoint + Vector2(0.1, 0.1)) == plot_ids[1], "overlap selects closest center")
	world.touch_half_size = old_half
	world.animate = false
	world.ambience.animate = false
	world.select_plot(plot_ids[0])
	world.selection_elapsed = 0.09
	world._apply_bounce()
	check(world.views[plot_ids[0]].get_global_position().y < world.centers[plot_ids[0]].y, "180ms bounce lifts at midpoint")
	world.selection_elapsed = 0.18
	world._apply_bounce()
	check(world.views[plot_ids[0]].get_global_position().is_equal_approx(world.centers[plot_ids[0]]), "bounce finishes at 180ms")
	settings.set_reduced_motion(true)
	check(world.reduced_motion and world.ambience.reduced_motion, "reduced motion reaches all effects")
	world.select_plot(plot_ids[2])
	world.selection_elapsed = 0.09
	world._apply_bounce()
	check(world.views[plot_ids[2]].get_global_position() == world.centers[plot_ids[2]], "reduced motion disables bounce")
	settings.set_reduced_motion(false)
	# Decorative animation phases must never alter touch resolution.
	for phase in [0.0, 2.25, 7.0]:
		world.ambience.animation_time = phase
		for i in range(9):
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.pressed = true
			touch.position = world.get_global_transform_with_canvas() * world.centers[plot_ids[i]]
			root.push_input(touch, true)
			touch.pressed = false
			root.push_input(touch, true)
			await process_frame
			check(garden.selected_plot_id == plot_ids[i], "ambient layer never intercepts touch")
			garden._close_dialog(false)
	# Buttons activate on a completed press/release, unlike plot press feedback.
	await click(garden.settings_button.get_global_transform_with_canvas() * (garden.settings_button.size * 0.5))
	check(garden.dialog_kind == "settings", "gear opens settings with GUI input")
	var prior_selection: StringName = garden.selected_plot_id
	await click(world.get_global_transform_with_canvas() * world.centers[plot_ids[0]])
	check(garden.selected_plot_id == prior_selection, "dialog blocks garden input")
	garden._open_dialog("language")
	await settle()
	var language_choice: Button = garden.language_buttons[5]
	await click(language_choice.get_global_transform_with_canvas() * (language_choice.size * 0.5))
	check(settings.locale == "fr", "clicking language choice immediately changes locale")
	garden._close_dialog(false)
	var margins: Vector4 = garden.safe_margins_for(Vector2(390, 844), Vector2(390, 844), Rect2(0, 59, 390, 751))
	check(margins.y >= 71 and margins.w >= 46, "safe area includes notch and home indicator plus padding")
	settings.set_language("en")
	check(settings.format_integer(12345) == "12,345", "English number format")
	settings.set_language("de")
	check(settings.format_integer(12345) == "12.345", "German number format")
	settings.set_language("ru")
	check(settings.format_integer(12345) == "12\u202f345", "Russian number format")
	check("ч" in settings.format_duration(3660), "duration uses selected locale")
	TranslationServer.remove_translation(fallback)
	settings.set_language(original_locale)
	settings.load_preferences(settings.DEFAULT_PATH)
	DirAccess.remove_absolute(test_path)
	DirAccess.remove_absolute(sentinel_path)
	print("PHASE 0.5: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
