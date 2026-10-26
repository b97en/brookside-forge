extends Node
## Player-facing state: inventory, gold, commission progress. Registered as
## autoload "GameState". Persists to a single JSON file (user://save.json).

## Tools/tests set this false to avoid writing the real save file, or repoint
## save_path at a temp file.
var save_enabled: bool = true
var save_path: String = "user://save.json"

var gold: int = 0
var inventory: Dictionary = {}  # item_id (String) -> count (int)
var active_commission: String = "":  # commission id, or "" if none accepted
	set(value):
		active_commission = value
		save_game()
var forged_quality: String = "":  # quality of the most recently forged item
	set(value):
		forged_quality = value
		save_game()
## Commission ids already delivered, in order. The notice board posts the
## first commission not in this list.
var completed_commissions: Array[String] = []

## True until a save file is found on launch; the HUD shows a controls hint.
var is_new_game: bool = true

## Where the player should appear after the next scene change.
## Vector2.INF means "use the position baked into the scene".
var next_spawn: Vector2 = Vector2.INF

var _loading: bool = false


func _ready() -> void:
	load_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + count
	Events.inventory_changed.emit()
	Events.item_gained.emit(item_id, count)
	print("[GameState] inventory: ", inventory)
	save_game()


func remove_item(item_id: String, count: int = 1) -> bool:
	var have: int = int(inventory.get(item_id, 0))
	if have < count:
		return false
	if have == count:
		inventory.erase(item_id)
	else:
		inventory[item_id] = have - count
	Events.inventory_changed.emit()
	save_game()
	return true


## True if the inventory covers every { item_id: count } in needs.
func has_items(needs: Dictionary) -> bool:
	for item_id: String in needs:
		if int(inventory.get(item_id, 0)) < int(needs[item_id]):
			return false
	return true


func add_gold(amount: int) -> void:
	gold += amount
	Events.gold_changed.emit(gold)
	print("[GameState] gold: ", gold)
	save_game()


## The next commission the notice board should post: the first in data order
## that hasn't been delivered. Once every commission is done the list resets
## so the loop keeps going for playtests. "" only if no commissions exist.
func next_commission_id() -> String:
	var ids: Array[String] = DataLoader.commission_ids_in_order()
	if ids.is_empty():
		return ""
	for id in ids:
		if id not in completed_commissions:
			return id
	completed_commissions.clear()
	return ids[0]


## Marks the active commission delivered and clears it.
func complete_commission(commission_id: String) -> void:
	if commission_id not in completed_commissions:
		completed_commissions.append(commission_id)
	forged_quality = ""
	active_commission = ""  # setter saves


func save_game() -> void:
	if _loading or not save_enabled:
		return
	var data: Dictionary = {
		"gold": gold,
		"inventory": inventory,
		"active_commission": active_commission,
		"forged_quality": forged_quality,
		"completed_commissions": completed_commissions,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: cannot write " + save_path)
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is not Dictionary:
		push_error("GameState: corrupt save, starting fresh")
		return
	_loading = true
	is_new_game = false
	var data: Dictionary = parsed
	gold = int(data.get("gold", 0))
	inventory.clear()
	var saved_inventory: Dictionary = data.get("inventory", {})
	for item_id: Variant in saved_inventory:
		inventory[String(item_id)] = int(saved_inventory[item_id])
	active_commission = String(data.get("active_commission", ""))
	forged_quality = String(data.get("forged_quality", ""))
	completed_commissions.clear()
	for id: Variant in Array(data.get("completed_commissions", [])):
		completed_commissions.append(String(id))
	_loading = false
	Events.gold_changed.emit(gold)
	Events.inventory_changed.emit()
	if not active_commission.is_empty():
		Events.commission_accepted.emit(active_commission)
	print("[GameState] loaded save: %d gold, %s, %d done" % [gold, inventory, completed_commissions.size()])
