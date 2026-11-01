extends Control

const Icon = preload("res://scripts/ui/garden_icon.gd")
const Strings = preload("res://scripts/ui/strings.gd")
const INK = Color("294c3c")
const MUTED = Color("52634c")
signal layout_changed(viewport_size: Vector2, play_area: Rect2, anchor: Vector2, zoom: float)
signal next_requested
signal focus_requested
signal retry_requested
signal modal_changed(opened: bool)
var model: RefCounted
var play_area: Rect2
var safe: MarginContainer
var context_title: Label
var context_body: Label
var context_card: PanelContainer
var header: VBoxContainer
var selected_plot_id: StringName = &""
var world_error_key: String = ""
var level_label: Label
var collection_label: Label
var coin_label: Label
var action_button: Button
var settings_button: Button
var settings_language_button: Button
var motion_toggle: CheckButton
var dialog: Control
var dialog_kind: String = ""
var dialog_margins: MarginContainer
var language_buttons: Array[Button] = []
var _bindings: Array[Dictionary] = []
var _layout_pending: bool = false
var _refreshing: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_theme()
	_build_hud()
	SettingsManager.language_changed.connect(_on_language_changed)
	SettingsManager.save_failed.connect(_on_save_failed)
	resized.connect(_schedule_layout)
	refresh_world_status()
	_refresh_texts()
	_schedule_layout()

func _style(color: Color, radius: int = 20, padding: int = 16, shadow: bool = true) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	box.border_color = Color("e4dfc8")
	box.set_border_width_all(1)
	if shadow:
		box.shadow_color = Color(0.22, 0.29, 0.16, 0.10)
		box.shadow_size = 6
		box.shadow_offset = Vector2(0, 4)
	return box

func _build_theme() -> void:
	var skin := Theme.new()
	skin.default_font_size = 16
	skin.default_font = preload("res://assets/fonts/OpenSans-Regular.ttf")
	skin.set_color("font_color", "Label", INK)
	skin.set_stylebox("panel", "PanelContainer", _style(Color("fff9e9")))
	for state in ["normal", "hover", "pressed", "focus"]:
		var color := Color("f6f4e2")
		if state == "hover":
			color = Color("ebeecd")
		elif state == "pressed":
			color = Color("dce6c4")
		var box := _style(color, 16, 10, state == "normal")
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
			box.border_color = Color("66895f")
			box.set_border_width_all(2)
		skin.set_stylebox(state, "Button", box)
	skin.set_color("font_color", "Button", INK)
	skin.set_color("font_hover_color", "Button", INK)
	skin.set_color("font_pressed_color", "Button", INK)
	skin.set_color("font_color", "CheckButton", INK)
	skin.set_font_size("font_size", "Button", 17)
	skin.set_font_size("font_size", "CheckButton", 16)
	theme = skin

func _bind(control: Control, key: String, property: String = "text") -> void:
	control.set(property, tr(key))
	_bindings.append({"node": control, "key": key, "property": property})

func _label(key: String, font_size: int = 16, tint: Color = INK) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not key.is_empty():
		_bind(label, key)
	return label

func _button(key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 48
	if not key.is_empty():
		_bind(button, key)
	button.pressed.connect(callback)
	return button

func _primary(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, _style(Color("496d4a") if state != "pressed" else Color("36563b"), 15, 12))
		button.add_theme_color_override("font_" + (state + "_" if state != "normal" else "") + "color", Color("fff9e9"))

func _panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	return panel

func _icon_button(kind: String, callback: Callable) -> Button:
	var button := _button("", callback)
	button.custom_minimum_size = Vector2(48, 48)
	var icon := Icon.new()
	icon.kind = kind
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(icon)
	return button

func _nav_button(key: String, kind: String, callback: Callable, active: bool = false) -> Button:
	var button := _button("", callback)
	_bind(button, key, "accessibility_name")
	_bind(button, key, "tooltip_text")
	button.custom_minimum_size = Vector2(0, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if active:
		button.add_theme_stylebox_override("normal", _style(Color("e5ebd1"), 18, 8, false))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(column)
	var icon := Icon.new()
	icon.kind = kind
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var label := _label(key, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	return button

func _build_hud() -> void:
	safe = MarginContainer.new()
	safe.z_index = 2000
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	column.add_child(top)
	var wallet := _panel(top)
	wallet.custom_minimum_size = Vector2(88, 60)
	wallet.add_theme_stylebox_override("panel", _style(Color("fff8dd"), 20, 10))
	var wallet_column := VBoxContainer.new()
	wallet_column.add_theme_constant_override("separation", 0)
	wallet.add_child(wallet_column)
	coin_label = _label("", 22, Color("795621"))
	wallet_column.add_child(coin_label)
	wallet_column.add_child(_label("UI_COINS", 14, MUTED))
	var level := _panel(top)
	level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level.add_theme_stylebox_override("panel", _style(Color("f4f2dd"), 20, 10))
	var level_column := VBoxContainer.new()
	level_column.add_theme_constant_override("separation", 2)
	level.add_child(level_column)
	level_label = _label("", 16)
	level_column.add_child(level_label)
	collection_label = _label("", 14, MUTED)
	level_column.add_child(collection_label)
	settings_button = _icon_button("gear", _open_settings)
	settings_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(settings_button)
	header = VBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 5)
	column.add_child(header)
	var title := _label(Strings.TITLE, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	var subtitle := _label("GARDEN_SUBTITLE", 16, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(subtitle)
	var spring := Control.new()
	spring.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spring)
	context_card = _panel(column)
	context_card.add_theme_stylebox_override("panel", _style(Color("fff9e9"), 22, 14))
	context_card.resized.connect(_schedule_layout)
	header.resized.connect(_schedule_layout)
	column.sort_children.connect(_schedule_layout)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	context_card.add_child(content)
	context_title = _label("", 21)
	content.add_child(context_title)
	context_body = _label("", 16, MUTED)
	content.add_child(context_body)
	action_button = _button("ACTION_NEXT_BED", _next_bed)
	_primary(action_button)
	content.add_child(action_button)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	column.add_child(nav)
	nav.add_child(_nav_button("UI_GUIDE", "help", func() -> void: _open_dialog("guide")))
	nav.add_child(_nav_button("UI_GARDEN", "leaf", _focus_garden, true))
	nav.add_child(_nav_button("UI_COLLECTION", "book", func() -> void: _open_dialog("notes")))

func _refresh_texts() -> void:
	if _refreshing:
		return
	_refreshing = true
	var live: Array[Dictionary] = []
	for binding in _bindings:
		if not is_instance_valid(binding.node):
			continue
		var control: Control = binding.node
		if is_instance_valid(control) and not control.is_queued_for_deletion():
			control.set(binding.property, tr(binding.key))
			live.append(binding)
	_bindings = live
	if is_instance_valid(level_label):
		level_label.text = tr("GARDEN_LEVEL") % 1
		collection_label.text = tr("UI_COLLECTION_PROGRESS") % [SettingsManager.format_integer(0), SettingsManager.format_integer(24)]
		coin_label.text = SettingsManager.format_integer(150)
		settings_button.tooltip_text = tr("UI_SETTINGS")
		settings_button.accessibility_name = tr("UI_SETTINGS")
		_refresh_context()
	if is_instance_valid(settings_language_button) and not settings_language_button.is_queued_for_deletion():
		settings_language_button.text = tr(SettingsManager.NATIVE_KEYS[SettingsManager.SUPPORTED.find(SettingsManager.locale)])
	for i in range(language_buttons.size()):
		var button := language_buttons[i]
		if is_instance_valid(button) and not button.is_queued_for_deletion():
			var active: bool = SettingsManager.locale == SettingsManager.SUPPORTED[i]
			button.button_pressed = active
			button.add_theme_stylebox_override("normal", _style(Color("dfe9cb") if active else Color("f6f4e2"), 13, 10, false))
			button.text = ("✓  " if active else "") + tr(SettingsManager.NATIVE_KEYS[i])
	_refreshing = false
	_schedule_layout()

func _refresh_context() -> void:
	var record: RefCounted = model.get_object(selected_plot_id)
	if record != null:
		context_title.text = (tr("PLOT_TITLE") % record.label_number if record.label_number > 0 else tr("UI_GARDEN")) + " · " + tr("PLOT_EMPTY")
		context_body.text = tr("PLOT_SELECTED_HINT")
	else:
		context_title.text = tr(Strings.EMPTY)
		context_body.text = tr(Strings.HINT)
	action_button.text = tr("ACTION_NEXT_BED")
	if not world_error_key.is_empty():
		context_body.text = tr(world_error_key)
		action_button.text = tr("UI_RETRY")
	if not SettingsManager.last_save_ok:
		context_body.text = tr("SAVE_SETTINGS_ERROR")

func _on_language_changed(_locale: String) -> void:
	_refresh_texts()

func _on_save_failed() -> void:
	if is_instance_valid(context_body):
		context_body.text = tr("SAVE_SETTINGS_ERROR")

func _schedule_layout() -> void:
	if not _layout_pending:
		_layout_pending = true
		call_deferred("_layout")

func safe_margins_for(viewport_size: Vector2, screen_size: Vector2, usable: Rect2) -> Vector4:
	var margins := Vector4(18, 24, 18, 24)
	if screen_size.x > 0 and screen_size.y > 0:
		margins.x = maxf(margins.x, usable.position.x * viewport_size.x / screen_size.x + 12)
		margins.y = maxf(margins.y, usable.position.y * viewport_size.y / screen_size.y + 12)
		margins.z = maxf(margins.z, (screen_size.x - usable.end.x) * viewport_size.x / screen_size.x + 12)
		margins.w = maxf(margins.w, (screen_size.y - usable.end.y) * viewport_size.y / screen_size.y + 12)
	return margins

func _layout() -> void:
	_layout_pending = false
	if not is_instance_valid(safe):
		return
	var margins := Vector4(18, 24, 18, 24)
	if OS.has_feature("mobile") and DisplayServer.get_name() != "headless":
		margins = safe_margins_for(size, Vector2(DisplayServer.screen_get_size()), Rect2(DisplayServer.get_display_safe_area()))
	for i in range(4):
		var margin_name: String = ["margin_left", "margin_top", "margin_right", "margin_bottom"][i]
		var pixels: int = int(ceilf(margins[i]))
		if safe.get_theme_constant(margin_name) != pixels:
			safe.add_theme_constant_override(margin_name, pixels)
	if is_instance_valid(dialog_margins):
		for i in range(4):
			var margin_name: String = ["margin_left", "margin_top", "margin_right", "margin_bottom"][i]
			var pixels: int = int(ceilf(margins[i]))
			if dialog_margins.get_theme_constant(margin_name) != pixels:
				dialog_margins.add_theme_constant_override(margin_name, pixels)
		var panel: PanelContainer = dialog_margins.get_node("Center/DialogPanel")
		panel.custom_minimum_size.x = minf(size.x - margins.x - margins.z, 390)
	# Fixed phone reference keeps text at 14–32 logical pixels. World scales
	# independently, and 160×128 spacing leaves a full 48×48 cell per bed.
	var factor: float = clampf((size.x - 20.0) / 1080.0, 0.335, 0.345)
	var top: float = header.get_global_rect().end.y + 14.0
	var bottom: float = context_card.get_global_rect().position.y - 18.0
	play_area = Rect2(0, top, size.x, maxf(1, bottom - top))
	layout_changed.emit(size, play_area, Vector2(size.x * 0.5, (top + bottom) * 0.5 + 9), factor)

func set_selected(id: StringName) -> void:
	selected_plot_id = id
	_refresh_context()
	_schedule_layout()

func _next_bed() -> void:
	if not world_error_key.is_empty():
		retry_requested.emit()
	else:
		next_requested.emit()

func _focus_garden() -> void:
	_close_dialog()
	focus_requested.emit()

func can_start_world(point: Vector2) -> bool:
	return not is_instance_valid(dialog) and play_area.has_point(point)

func refresh_world_status() -> void:
	world_error_key = "WORLD_SAVE_BLOCKED" if WorldService.load_status == "blocked" else ("WORLD_SAVE_ERROR" if not WorldService.last_save_ok else ("WORLD_RECOVERED" if WorldService.load_status == "recovered" else ""))
	if is_instance_valid(context_body):
		_refresh_context()

func show_world_error(key: String) -> void:
	world_error_key = key
	_refresh_context()

func _open_settings() -> void:
	_open_dialog("settings")

func _close_dialog() -> void:
	if is_instance_valid(dialog):
		dialog.queue_free()
		dialog = null
	language_buttons.clear()
	dialog_kind = ""
	modal_changed.emit(false)
	settings_button.grab_focus()

func _open_dialog(kind: String) -> void:
	if is_instance_valid(dialog):
		remove_child(dialog)
		dialog.queue_free()
	language_buttons.clear()
	dialog_kind = kind
	modal_changed.emit(true)
	dialog = Control.new()
	dialog.z_index = 3000
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dialog)
	var scrim := ColorRect.new()
	scrim.color = Color(0.12, 0.22, 0.15, 0.28)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(scrim)
	dialog_margins = MarginContainer.new()
	dialog_margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for margin_name in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		dialog_margins.add_theme_constant_override(margin_name, safe.get_theme_constant(margin_name))
	dialog.add_child(dialog_margins)
	var center := CenterContainer.new()
	center.name = "Center"
	dialog_margins.add_child(center)
	var panel := _panel(center)
	panel.name = "DialogPanel"
	panel.custom_minimum_size.x = minf(size.x - 36, 390)
	panel.add_theme_stylebox_override("panel", _style(Color("fff9e9"), 24, 20))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	content.add_child(heading)
	var key: String = {"settings": "UI_SETTINGS", "language": "UI_LANGUAGE", "guide": "UI_GUIDE_TITLE", "notes": "UI_COLLECTION"}[kind]
	var title := _label(key, 23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := _icon_button("close", _close_dialog)
	_bind(close, "UI_CLOSE", "tooltip_text")
	_bind(close, "UI_CLOSE", "accessibility_name")
	heading.add_child(close)
	if kind == "settings":
		content.add_child(_label("UI_SETTINGS_HINT", 16, MUTED))
		content.add_child(_label("UI_LANGUAGE", 16))
		var language := _button(SettingsManager.NATIVE_KEYS[SettingsManager.SUPPORTED.find(SettingsManager.locale)], func() -> void: _open_dialog("language"))
		settings_language_button = language
		language.custom_minimum_size.y = 54
		content.add_child(language)
		motion_toggle = CheckButton.new()
		_bind(motion_toggle, "UI_REDUCED_MOTION")
		motion_toggle.custom_minimum_size.y = 52
		motion_toggle.button_pressed = SettingsManager.reduced_motion
		motion_toggle.toggled.connect(SettingsManager.set_reduced_motion)
		content.add_child(motion_toggle)
		content.add_child(_label("UI_LOCAL_ONLY", 14, MUTED))
	elif kind == "language":
		content.add_child(_label("UI_LANGUAGE_HINT", 16, MUTED))
		for i in range(SettingsManager.SUPPORTED.size()):
			var code: String = SettingsManager.SUPPORTED[i]
			var button := _button(SettingsManager.NATIVE_KEYS[i], func() -> void: SettingsManager.set_language(code))
			button.custom_minimum_size.y = 48
			button.toggle_mode = true
			language_buttons.append(button)
			content.add_child(button)
		content.add_child(_button("UI_BACK", _open_settings))
	else:
		content.add_child(_label("UI_GUIDE_BODY" if kind == "guide" else "UI_NOTES_BODY", 16, MUTED))
		var okay := _button("UI_OK", _close_dialog)
		_primary(okay)
		content.add_child(okay)
	_refresh_texts()
	close.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_instance_valid(dialog):
		_close_dialog()
		get_viewport().set_input_as_handled()
