extends Node
## Loads game data from data/*.json at startup. Registered as autoload
## "DataLoader". No item/commission definitions belong in scripts.

var items: Dictionary = {}
var commissions: Dictionary = {}


func _ready() -> void:
	items = _load_json("res://data/items.json")
	commissions = _load_json("res://data/commissions.json")
	print("[DataLoader] loaded %d items, %d commissions" % [items.size(), commissions.size()])


func item_name(item_id: String) -> String:
	var entry: Dictionary = items.get(item_id, {})
	return String(entry.get("name", item_id))


## Materials needed to forge item_id: { material_id: count }. Empty if the
## item has no recipe entry.
func recipe(item_id: String) -> Dictionary:
	var entry: Dictionary = items.get(item_id, {})
	return Dictionary(entry.get("recipe", {}))


## Human-readable recipe, e.g. "2 Iron Ore". Empty string if no recipe.
func recipe_text(item_id: String) -> String:
	var parts: PackedStringArray = []
	var needs: Dictionary = recipe(item_id)
	for material_id: String in needs:
		parts.append("%d %s" % [int(needs[material_id]), item_name(material_id)])
	return ", ".join(parts)


## Commission ids sorted by their "order" field (then id), so the notice board
## posts them in a deliberate sequence regardless of JSON key order.
func commission_ids_in_order() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in commissions.keys():
		ids.append(String(key))
	ids.sort_custom(func(a: String, b: String) -> bool:
		var order_a: int = int(Dictionary(commissions[a]).get("order", 0))
		var order_b: int = int(Dictionary(commissions[b]).get("order", 0))
		if order_a != order_b:
			return order_a < order_b
		return a < b)
	return ids


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: missing file " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("DataLoader: invalid JSON in " + path)
	return {}
