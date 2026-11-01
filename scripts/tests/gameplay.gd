extends SceneTree
var failures: int = 0
var assertions: int = 0
var service: Node
var game: Node
var clock: Node
const PATH = "user://qa_gameplay_sprint.json"
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
func clean() -> void:
	for path in [PATH, PATH + ".tmp", PATH.get_basename() + ".backup.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
func fresh(at: int) -> void:
	clean()
	clock.begin_mock(at)
	service.use_storage(PATH)
func run() -> void:
	service = root.get_node("WorldService")
	game = root.get_node("GameState")
	clock = root.get_node("TimeService")
	var original_path: String = service.store.path
	var settings: Node = root.get_node("SettingsManager")
	var original_locale: String = settings.locale
	var preferences: String = FileAccess.get_file_as_string(settings.settings_path)
	var table: Array = [["sunny_carrot",30,5,10],["moonberry",120,12,25],["starflower",300,25,55],["bubble_cactus",600,45,100],["crystal_mushroom",1200,80,180],["rainbow_tulip",2400,150,350]]
	check(service.catalog.definitions.size() == 6, "six distinct resource definitions")
	var n: int = 0
	for row in table:
		fresh(1000000 + n * 10000)
		n += 1
		var base: int = clock.now_utc()
		var id: StringName = &"starter_plot_05"
		var species := StringName(row[0])
		var resource: Resource = service.catalog.definitions[species]
		check(resource.growth_seconds == row[1] and resource.seed_cost == row[2] and resource.reward_coins == row[3], "night-sprint balance " + row[0])
		check(service.gameplay.coins == 150 and service.model.objects.size() == 9 and service.gameplay.crops.is_empty(), "fresh garden")
		check(game.plant(id, species, 0).ok, "plant " + row[0])
		check(service.gameplay.coins == 150 - row[2], "seed charged exactly once")
		var crop: RefCounted = game.crop_at(id)
		check(crop.stage_at(base) == 0 and crop.ready_at_utc == base + row[1], "initial stage / exact saved duration")
		for tap in range(20):
			check(not game.plant(id, species, 0).ok, "repeated planting rejected")
		check(service.gameplay.coins == 150 - row[2], "repeated taps never deduct again")
		check(not game.harvest(id, 1).ok, "immature harvest rejected")
		for stage in [1,2,3]:
			clock.set_mock_wall(base + ceili(row[1] * [0.0,0.25,0.60,1.0][stage]))
			game.refresh_growth()
			check(game.crop_at(id).stage_at(clock.now_utc()) == stage, "stage %d/%s" % [stage,row[0]])
			service.reload_world()
			check(game.crop_at(id).stage_at(clock.now_utc()) == stage, "stage survives reload")
		var snapshot: Dictionary = service.snapshot()
		var disk: String = FileAccess.get_file_as_string(PATH)
		for locale in settings.SUPPORTED:
			settings.set_language(locale)
			check(service.snapshot() == snapshot and FileAccess.get_file_as_string(PATH) == disk, "language preserves live crop and currency " + locale)
		var receipt: Dictionary = game.harvest(id, 1)
		check(receipt.ok and receipt.reward == row[3] and game.crop_at(id) == null, "harvest grants configured reward and frees ID")
		var expected: int = 150 - row[2] + row[3]
		for tap in range(20):
			check(not game.harvest(id, 1).ok, "repeated harvest rejected")
		service.reload_world()
		check(service.gameplay.coins == expected and not game.harvest(id, 1).ok, "no reward replay after restart")
		check(game.plant(id, species, 1).ok, "replant increments cycle")
		clock.advance_mock(row[1])
		check(not game.harvest(id, 1).ok and game.harvest(id, 2).ok, "stale crop-cycle cannot claim new harvest")
	fresh(2000000)
	check(game.plant(&"starter_plot_01", &"rainbow_tulip", 0).ok and service.gameplay.coins == 0, "purchase exact balance")
	check(not game.plant(&"starter_plot_02", &"sunny_carrot", 0).ok and service.gameplay.coins == 0, "insufficient funds never go negative")
	check(not service.remove_object(&"starter_plot_01"), "cannot orphan crop by deleting its plot")
	clock.advance_mock(48 * 3600)
	service.reload_world()
	check(game.crop_at(&"starter_plot_01").stage_at(clock.now_utc()) == 3, "48h offline resume reaches maturity without auto reward")
	check(service.gameplay.coins == 0, "offline growth never auto-harvests")
	check(game.harvest(&"starter_plot_01",1).ok and service.gameplay.coins == 350, "explicit offline harvest")
	fresh(3000000)
	for cycle in range(10):
		check(game.plant(&"starter_plot_01", &"sunny_carrot", cycle).ok, "ten-cycle plant")
		clock.advance_mock(30)
		check(game.harvest(&"starter_plot_01", cycle+1).ok, "ten-cycle harvest")
		service.reload_world()
	check(service.gameplay.coins == 200 and service.gameplay.statistics.total_harvests == 10, "ten cycles retain exact balance and statistics")
	fresh(4000000)
	for id in service.model.ids_of_kind("plot"):
		check(game.plant(id, &"sunny_carrot", 0).ok, "plant on every stable ID")
	check(service.gameplay.coins == 105 and service.gameplay.crops.size() == 9, "all nine crops persisted")
	var before: int = clock.now_utc()
	clock.set_mock_wall(before - 10000)
	check(clock.now_utc() == before and game.crop_at(&"starter_plot_01").remaining(clock.now_utc()) == 30, "backward clock freezes elapsed, never negative")
	clock.set_mock_wall(before + 30)
	for id in service.model.ids_of_kind("plot"):
		check(game.harvest(id,1).ok, "harvest every stable ID")
	fresh(5000000)
	var old: Dictionary = service.snapshot()
	var original_disk: String = FileAccess.get_file_as_string(PATH)
	service.store.simulate_write_failure = true
	check(not game.plant(&"starter_plot_01", &"sunny_carrot", 0).ok, "save failure rejects planting")
	check(service.snapshot() == old and FileAccess.get_file_as_string(PATH) == original_disk, "failure leaves live state and file unchanged")
	service.store.simulate_write_failure = false
	check(game.plant(&"starter_plot_01", &"sunny_carrot", 0).ok, "write retry can plant")
	clock.advance_mock(30)
	service.store.simulate_write_failure = true
	check(not game.harvest(&"starter_plot_01",1).ok and service.gameplay.coins == 145 and game.crop_at(&"starter_plot_01") != null, "failed harvest cannot grant or destroy crop")
	service.store.simulate_write_failure = false
	check(game.harvest(&"starter_plot_01",1).ok and service.gameplay.coins == 155, "retry harvest once")
	# Migration preserves Phase 0.75 map IDs/positions and separate preferences.
	var legacy: Dictionary = service.model.to_data()
	legacy.objects.reverse()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	service.reload_world()
	check(service.gameplay.coins == 150 and service.gameplay.crops.is_empty(), "v1 map migrates to fresh wallet without resetting objects")
	check(service.model.objects.has(&"starter_plot_05"), "migration retains stable IDs")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	check(raw.schema_version == 2 and raw.world.objects.size() == 9, "migration saved as atomic farm schema 2")
	settings.set_language(original_locale)
	check(FileAccess.get_file_as_string(settings.settings_path) == preferences, "preferences unchanged after gameplay and migration")
	clean()
	clock.use_real_clock()
	service.use_storage(original_path)
	print("GAMEPLAY: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
