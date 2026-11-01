extends Control

const World = preload("res://scripts/ui/garden_world.gd")
const Strings = preload("res://scripts/ui/strings.gd")
const Plot = preload("res://scripts/models/plot_data.gd")
const INK = Color("273c36")
var plots: Array = []
var world: Node2D
var safe: MarginContainer
var context_title: Label
var context_body: Label
var selected_plot: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(9):
		plots.append(Plot.new(i))
	_build_theme()
	world = World.new()
	add_child(world)
	world.plot_selected.connect(_select_plot)
	_build_hud()
	resized.connect(_layout)
	_layout()

func _build_theme() -> void:
	var skin := Theme.new()
	skin.default_font_size = 32
	skin.default_font = preload("res://assets/fonts/OpenSans-Regular.ttf")
	skin.set_color("font_color", "Label", INK)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("fff7e8")
	panel.corner_radius_top_left = 34
	panel.corner_radius_top_right = 34
	panel.corner_radius_bottom_left = 34
	panel.corner_radius_bottom_right = 34
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 22
	panel.content_margin_bottom = 22
	skin.set_stylebox("panel", "PanelContainer", panel)
	theme = skin

func _label(text: String, font_size: int, tint: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	return label

func _panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	return panel

func _build_hud() -> void:
	safe = MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	column.add_child(top)
	var wallet := _panel(top)
	wallet.add_child(_label("●  150", 40, Color("74501e")))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var journal := _panel(top)
	journal.add_child(_label("Field notes  0 / 24", 30))
	var title := _label(Strings.TITLE, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := _label(Strings.TAGLINE, 30, Color("4d685c"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var spring := Control.new()
	spring.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spring)
	var card := _panel(column)
	var text_column := VBoxContainer.new()
	text_column.add_theme_constant_override("separation", 12)
	card.add_child(text_column)
	context_title = _label(Strings.EMPTY, 36)
	context_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(context_title)
	context_body = _label(Strings.HINT, 28, Color("4d685c"))
	context_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(context_body)
	var nav := _panel(column)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 44)
	nav.add_child(row)
	row.add_child(_label("SHOP · SOON", 24, Color("626b61")))
	row.add_child(_label("⌂  GARDEN", 30))
	row.add_child(_label("JOURNAL · SOON", 24, Color("626b61")))
	var phase := _label("FOUNDATION PREVIEW  /  PHASE 0", 21, Color("4d685c"))
	phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(phase)

func _layout() -> void:
	if not is_instance_valid(world):
		return
	var factor: float = minf(size.x / 1080.0, size.y / 1600.0)
	world.scale = Vector2.ONE * factor
	world.position = Vector2(size.x * 0.5, size.y * 0.49)
	var margins := Vector4(40, 48, 40, 36)
	if DisplayServer.get_name() != "headless":
		var rect := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.x > 0 and screen.y > 0 and OS.has_feature("mobile"):
			margins.x = maxf(margins.x, rect.position.x * size.x / screen.x + 24)
			margins.y = maxf(margins.y, rect.position.y * size.y / screen.y + 24)
			margins.z = maxf(margins.z, (screen.x - rect.end.x) * size.x / screen.x + 24)
			margins.w = maxf(margins.w, (screen.y - rect.end.y) * size.y / screen.y + 24)
	for i in range(4):
		safe.add_theme_constant_override(["margin_left", "margin_top", "margin_right", "margin_bottom"][i], int(margins[i]))

func _select_plot(index: int) -> void:
	selected_plot = index
	context_title.text = Strings.SELECTED % (index + 1)
	context_body.text = Strings.FOUNDATION
