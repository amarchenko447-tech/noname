class_name WorldModel
extends RefCounted
## Map state, placement and query boundary. No Nodes, UI, timers or fixed plot count.
const Record = preload("res://scripts/world/object_record.gd")
const Grid = preload("res://scripts/world/iso_grid.gd")
var definition: Resource
var grid: RefCounted
var definitions: Dictionary = {}
var regions: Dictionary = {}
var unlocked_regions: Array[StringName] = []
var objects: Dictionary = {}
var occupancy: Dictionary = {}
var generation: int = 0

func _init(source: Resource) -> void:
	definition = source
	grid = Grid.new(source.metrics)
	for entry in source.object_definitions:
		definitions[entry.definition_id] = entry
	for region in source.regions:
		regions[region.region_id] = region

func populate_starter() -> bool:
	unlocked_regions = [definition.starter_region_id]
	for raw in regions[definition.starter_region_id].initial_objects:
		if not place(Record.from_data(raw)):
			return false
	return true

func get_object(id: StringName) -> RefCounted:
	return objects.get(id)

func ids_of_kind(kind: String) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in objects:
		if definitions[objects[id].definition_id].kind == kind:
			result.append(id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result

func occupied_cells(record: RefCounted) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not definitions.has(record.definition_id):
		return result
	for offset in definitions[record.definition_id].footprint:
		var rotated: Vector2i = offset
		for turn in range(record.rotation):
			rotated = Vector2i(-rotated.y, rotated.x)
		result.append(record.cell + rotated)
	return result

func is_unlocked(cell: Vector2i) -> bool:
	for region_id in unlocked_regions:
		if regions[region_id].bounds.has_point(cell):
			return true
	return false

func can_place(record: RefCounted, exclude_id: StringName = &"") -> bool:
	if record.id == &"" or not definitions.has(record.definition_id) or record.rotation < 0 or record.rotation > 3:
		return false
	var content: Resource = definitions[record.definition_id]
	if content.kind not in ["plot", "plant", "building", "decoration"] or content.footprint.is_empty():
		return false
	var cells := occupied_cells(record)
	var seen: Dictionary = {}
	var layer: Dictionary = occupancy.get(content.occupancy_layer, {})
	for cell in cells:
		if seen.has(cell) or not is_unlocked(cell):
			return false
		seen[cell] = true
		if layer.has(cell) and layer[cell] != exclude_id:
			return false
	return true

func place(record: RefCounted) -> bool:
	if objects.has(record.id) or not can_place(record):
		return false
	objects[record.id] = Record.from_data(record.to_data())
	_index(objects[record.id])
	return true

func _index(record: RefCounted) -> void:
	var layer_name: StringName = definitions[record.definition_id].occupancy_layer
	if not occupancy.has(layer_name):
		occupancy[layer_name] = {}
	for cell in occupied_cells(record):
		occupancy[layer_name][cell] = record.id

func remove(id: StringName) -> bool:
	if not objects.has(id):
		return false
	var record: RefCounted = objects[id]
	var layer: Dictionary = occupancy[definitions[record.definition_id].occupancy_layer]
	for cell in occupied_cells(record):
		layer.erase(cell)
	objects.erase(id)
	return true

func move(id: StringName, cell: Vector2i, rotation: int) -> bool:
	if not objects.has(id):
		return false
	var candidate := Record.from_data(objects[id].to_data())
	candidate.cell = cell
	candidate.rotation = rotation
	if not can_place(candidate, id):
		return false
	remove(id)
	return place(candidate)

func sort_anchor(record: RefCounted) -> Vector2:
	var point: Vector2 = grid.cell_to_world(record.cell)
	for cell in occupied_cells(record):
		var foot: Vector2 = grid.cell_to_world(cell)
		if foot.y > point.y:
			point = foot
	return point

func object_bounds(record: RefCounted) -> Rect2:
	var half: Vector2 = definitions[record.definition_id].visual_half_size
	var result := Rect2(grid.cell_to_world(record.cell) - half, half * 2)
	for cell in occupied_cells(record):
		result = result.merge(Rect2(grid.cell_to_world(cell) - half, half * 2))
	return result

func objects_in_world_rect(rect: Rect2) -> Array[StringName]:
	# Replace this query implementation with a spatial index/streamer later.
	# Placement already has an occupancy hash. No viewport owns the data.
	var result: Array[StringName] = []
	for id in objects:
		if object_bounds(objects[id]).intersects(rect, true):
			result.append(id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result

func objects_in_cells(area: Rect2i) -> Array[StringName]:
	var found: Dictionary = {}
	for layer in occupancy.values():
		for cell in layer:
			if area.has_point(cell):
				found[layer[cell]] = true
	var result: Array[StringName] = []
	for id in found:
		result.append(id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result

func navigation_bounds() -> Rect2:
	var result: Rect2 = regions[definition.starter_region_id].scenery_bounds
	for record in objects.values():
		result = result.merge(object_bounds(record))
	return result

func to_data() -> Dictionary:
	var serialized: Array = []
	var ids: Array = objects.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for id in ids:
		serialized.append(objects[id].to_data())
	var region_ids: Array[String] = []
	for id in unlocked_regions:
		region_ids.append(String(id))
	return {"schema_version": 1, "world_id": String(definition.world_id), "generation": generation,
		"unlocked_regions": region_ids, "objects": serialized}

func integer_value(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))

func load_data(data: Variant) -> bool:
	# Validate into a separate model: failure never partially replaces this model.
	if not data is Dictionary or data.get("schema_version") != 1 or data.get("world_id") != String(definition.world_id):
		return false
	if not data.get("objects") is Array or not data.get("unlocked_regions") is Array:
		return false
	if not integer_value(data.get("generation")) or data.generation < 0 or data.generation > 9007199254740991:
		return false
	var candidate := WorldModel.new(definition)
	for region in data.unlocked_regions:
		if not region is String or not regions.has(StringName(region)) or StringName(region) in candidate.unlocked_regions:
			return false
		candidate.unlocked_regions.append(StringName(region))
	if definition.starter_region_id not in candidate.unlocked_regions:
		return false
	for raw in data.objects:
		if not raw is Dictionary or not raw.get("id") is String or raw.id.is_empty() or raw.id.length() > 128 or not raw.get("definition_id") is String:
			return false
		for field in ["u", "v", "rotation", "label_number", "art_seed"]:
			if not integer_value(raw.get(field)) or absf(float(raw[field])) > 1000000000:
				return false
		if not candidate.place(Record.from_data(raw)):
			return false
	objects = candidate.objects
	occupancy = candidate.occupancy
	unlocked_regions = candidate.unlocked_regions
	generation = int(data.generation)
	return true
