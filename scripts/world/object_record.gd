class_name WorldObjectRecord
extends RefCounted
## Stable instance identity never changes when the anchor is moved.
var id: StringName
var definition_id: StringName
var cell: Vector2i
var rotation: int = 0
var label_number: int = 0
var art_seed: int = 0
func to_data() -> Dictionary:
	return {"id": String(id), "definition_id": String(definition_id), "u": cell.x, "v": cell.y,
		"rotation": rotation, "label_number": label_number, "art_seed": art_seed}
static func from_data(data: Dictionary) -> WorldObjectRecord:
	var record := WorldObjectRecord.new()
	record.id = StringName(data.id)
	record.definition_id = StringName(data.definition_id)
	record.cell = Vector2i(int(data.u), int(data.v))
	record.rotation = int(data.get("rotation", 0))
	record.label_number = int(data.get("label_number", 0))
	record.art_seed = int(data.get("art_seed", 0))
	return record
