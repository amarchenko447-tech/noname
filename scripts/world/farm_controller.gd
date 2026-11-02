extends Node2D
## Composition root. HUD owns no model creation, map placement or camera transforms.
const WorldView = preload("res://scripts/ui/garden_world.gd")
const Hud = preload("res://scripts/ui/garden.gd")
const Backdrop = preload("res://scripts/ui/garden_backdrop.gd")
const CameraRig = preload("res://scripts/world/camera_rig.gd")
const Router = preload("res://scripts/world/world_input_router.gd")
var world: Node2D
var hud: Control
var camera_rig: Node2D
var input_router: Node
var tick: Timer
var hud_layer: CanvasLayer
func _ready() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	var backdrop := Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_layer.add_child(backdrop)
	world = WorldView.new()
	world.model = WorldService.model
	add_child(world)
	camera_rig = CameraRig.new()
	add_child(camera_rig)
	camera_rig.bounds = WorldService.model.navigation_bounds()
	camera_rig.view_changed.connect(_on_camera_changed)
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = Hud.new()
	hud.model = WorldService.model
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.layout_changed.connect(_on_layout_changed)
	hud.next_requested.connect(_next_plot)
	hud.action_requested.connect(_perform_action)
	hud.focus_requested.connect(_focus_garden)
	hud.retry_requested.connect(WorldService.reload_world)
	hud.modal_changed.connect(_on_modal_changed)
	hud_layer.add_child(hud)
	world.plot_selected.connect(hud.set_selected)
	input_router = Router.new()
	input_router.rig = camera_rig
	input_router.can_start = hud.can_start_world
	input_router.tapped.connect(_on_tap)
	add_child(input_router)
	SettingsManager.motion_changed.connect(world.set_motion_reduced)
	SettingsManager.language_changed.connect(func(_locale: String) -> void: world.update_crop_timers())
	WorldService.world_changed.connect(_on_world_changed)
	WorldService.gameplay_changed.connect(_on_gameplay_changed)
	WorldService.transaction_completed.connect(_on_transaction)
	GameState.growth_changed.connect(func(_ids: Array[StringName]) -> void: world.sync_crops())
	WorldService.save_failed.connect(hud.show_world_error)
	world.set_motion_reduced(SettingsManager.reduced_motion)
	world.select_plot(WorldService.focus_plot_id())
	world.selection_elapsed = 1.0
	world.sync_crops()
	hud.refresh_gameplay()
	tick = Timer.new()
	tick.name = "SharedGrowthClock"
	tick.wait_time = 1.0
	tick.timeout.connect(_on_tick)
	add_child(tick)
	tick.start()
func _on_layout_changed(size: Vector2, area: Rect2, anchor: Vector2, zoom: float) -> void:
	camera_rig.configure(size, area, anchor, zoom)
func _on_camera_changed() -> void:
	world.touch_half_size = 24.0 / camera_rig.zoom_value()
func _on_modal_changed(_opened: bool) -> void:
	if is_instance_valid(input_router):
		input_router.cancel()
func _on_tap(point: Vector2) -> void:
	if camera_rig.is_overview():
		camera_rig.zoom_at(1.0 / camera_rig.relative_zoom, point)
		return
	var id: StringName = world.plot_at(camera_rig.screen_to_world(point))
	if id != &"":
		world.select_plot(id)
		_perform_action(id, true)
func _next_plot() -> void:
	var id: StringName = WorldService.next_plot_id(world.selected_id)
	if id != &"":
		world.select_plot(id)
		if not camera_rig.play_area.has_point(world.screen_position(id)):
			camera_rig.center_on(world.centers[id])
func _focus_garden() -> void:
	var id: StringName = WorldService.focus_plot_id()
	if id != &"":
		world.select_plot(id)
		camera_rig.center_on(world.centers[id])
func _on_world_changed() -> void:
	world.rebuild(WorldService.model)
	hud.model = WorldService.model
	camera_rig.bounds = WorldService.model.navigation_bounds()
	camera_rig._apply()
	var id: StringName = world.selected_id
	if id == &"":
		id = WorldService.focus_plot_id()
	world.select_plot(id)
	hud.refresh_world_status()

func _perform_action(id: StringName, from_tap: bool = false) -> void:
	if id == &"":
		return
	var crop: RefCounted = GameState.crop_at(id)
	if crop == null:
		hud.open_seeds(id)
	elif crop.stage_at(TimeService.now_utc()) == 3:
		var result: Dictionary = GameState.harvest(id,crop.cycle_id)
		if not result.ok:
			hud.show_world_error(result.error)
	elif not from_tap:
		hud.refresh_timer()
func _on_gameplay_changed() -> void:
	world.model = WorldService.model
	hud.model = WorldService.model
	world.sync_crops()
	hud.refresh_world_status()
	hud.refresh_gameplay()
func _on_transaction(receipt: Dictionary) -> void:
	var id: StringName = receipt.plot_id
	if receipt.kind == "plant":
		world.play_crop_effect(id,&"plant")
	elif receipt.kind == "harvest":
		world.harvest_ghost(id,StringName(receipt.species_id))
		hud.show_harvest(receipt,world.screen_position(id))
func _on_tick() -> void:
	GameState.refresh_growth()
	world.update_crop_timers()
	hud.refresh_timer()
func _notification(what: int) -> void:
	if not is_instance_valid(tick):
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		tick.stop()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		tick.start()
		_on_tick()
