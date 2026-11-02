extends VBoxContainer
const Preview = preload("res://scripts/ui/plant_preview.gd")
var host: Control
var plot_id: StringName
var expected_cycle: int
var selected_species: StringName = &"sunny_carrot"
var cards: Dictionary = {}
var confirm: Button
var message: Label
var scroll: ScrollContainer
var fit_pending: bool = false
func setup(owner_hud: Control, id: StringName) -> void:
	host = owner_hud
	plot_id = id
	expected_cycle = GameState.cycle_at(id)
	add_theme_constant_override("separation", 10)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(590, maxf(300, host.size.y - host.safe.get_theme_constant("margin_top") - host.safe.get_theme_constant("margin_bottom") - 210))
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for definition in WorldService.catalog.CONTENT:
		var species: StringName = definition.species_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 188)
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			selected_species = species
			refresh_texts())
		grid.add_child(button)
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right","top","bottom"]:
			margin.add_theme_constant_override("margin_" + side, 8)
		button.add_child(margin)
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", 2)
		margin.add_child(column)
		column.minimum_size_changed.connect(func() -> void:
			button.custom_minimum_size.y = maxf(188,column.get_combined_minimum_size().y+16))
		var art := Preview.new()
		art.species_id = species
		art.preview_height = 40
		art.preview_scale = 0.29
		column.add_child(art)
		var name_label: Label = host._label("", 15)
		name_label.custom_minimum_size.y = 42
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		column.add_child(name_label)
		var price: Label = host._label("",14)
		column.add_child(price)
		var duration: Label = host._label("",14)
		column.add_child(duration)
		var availability: Label = host._label("",14)
		column.add_child(availability)
		cards[species] = {"button":button,"name":name_label,"price":price,"duration":duration,"availability":availability}
	message = host._label("",15)
	message.minimum_size_changed.connect(_request_fit)
	message.resized.connect(_request_fit)
	resized.connect(_request_fit)
	add_child(message)
	confirm = host._button("ACTION_PLANT", _confirm)
	host._primary(confirm)
	add_child(confirm)
	refresh_texts()
func refresh_texts() -> void:
	if not is_instance_valid(confirm):
		return
	for species in cards:
		var widgets: Dictionary = cards[species]
		var definition: Resource = WorldService.catalog.definitions[species]
		var affordable: bool = WorldService.gameplay.coins >= definition.seed_cost
		widgets.name.text = tr(definition.name_key)
		widgets.price.text = tr("PRICE_COINS") % SettingsManager.format_integer(definition.seed_cost)
		widgets.duration.text = tr("SEED_GROWTH") % SettingsManager.format_duration(definition.growth_seconds)
		widgets.availability.text = tr("SEED_AVAILABLE") if affordable else tr("SHOP_INSUFFICIENT_COINS")
		widgets.availability.add_theme_color_override("font_color", Color("52634c") if affordable else Color("95513c"))
		widgets.button.add_theme_stylebox_override("normal",host._style(Color("e0ebcf") if species == selected_species else Color("f8f5e5"),16,6,false))
		widgets.button.button_pressed = species == selected_species
		widgets.button.accessibility_name = "%s. %s. %s" % [widgets.name.text,widgets.price.text,widgets.availability.text]
	var chosen: Resource = WorldService.catalog.definitions[selected_species]
	confirm.text = tr("SEED_CONFIRM") % SettingsManager.format_integer(chosen.seed_cost)
	confirm.disabled = WorldService.gameplay.coins < chosen.seed_cost or GameState.crop_at(plot_id) != null or GameState.cycle_at(plot_id) != expected_cycle
	message.text = tr("GROWTH_STATUS") % [tr(chosen.name_key),SettingsManager.format_duration(chosen.growth_seconds)]
	if confirm.disabled:
		message.text = tr("GROWTH_STATUS") % [tr("SHOP_INSUFFICIENT_COINS"),SettingsManager.format_duration(chosen.growth_seconds)] if WorldService.gameplay.coins < chosen.seed_cost else tr("PLOT_OCCUPIED")
	_request_fit()
func _confirm() -> void:
	var result: Dictionary = GameState.plant(plot_id, selected_species, expected_cycle)
	if result.ok:
		host._close_dialog()
	else:
		refresh_texts()
		message.text = tr(result.error)
		_request_fit()

func _request_fit() -> void:
	if not fit_pending:
		fit_pending = true
		call_deferred("_fit_height")
func _fit_height() -> void:
	fit_pending = false
	if not is_instance_valid(message) or not is_inside_tree():
		return
	var available: float = host.size.y-host.safe.get_theme_constant("margin_top")-host.safe.get_theme_constant("margin_bottom")
	var heading: Control = host.dialog_margins.get_node("Center/DialogPanel").get_child(0).get_child(0)
	var overhead: float = maxf(48,heading.get_combined_minimum_size().y)+48+40+12+20+24
	var desired: float = clampf(available-overhead-message.get_combined_minimum_size().y,220,590)
	if absf(scroll.custom_minimum_size.y-desired)>0.5:
		scroll.custom_minimum_size.y=desired
