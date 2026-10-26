class_name Anvil
extends Interactable
## The forge anvil. Opens the forging mini-game when the player holds the
## materials for the item being made; on completion consumes those materials
## and produces the item. The item is the active commission's, or
## fallback_item when no commission is accepted. Recipes come from items.json.

const MINIGAME_SCENE: PackedScene = preload("res://scenes/forge_minigame.tscn")

@export var fallback_item: String = "scythe"

var _pending_item: String = ""


func _on_interact() -> void:
	var item_id: String = _target_item()
	var needs: Dictionary = _recipe_for(item_id)
	if not GameState.has_items(needs):
		Events.say("Anvil", "%s needs %s. Mine the rock east of the village." % [
			DataLoader.item_name(item_id), DataLoader.recipe_text(item_id)])
		return
	_pending_item = item_id
	var minigame: ForgeMinigame = MINIGAME_SCENE.instantiate()
	minigame.item_name = DataLoader.item_name(item_id)
	# Own screen-space layer (above the HUD) so the overlay ignores the camera;
	# the layer goes when the mini-game frees itself.
	var layer := CanvasLayer.new()
	layer.layer = 2
	layer.add_child(minigame)
	minigame.tree_exited.connect(layer.queue_free)
	get_tree().current_scene.add_child(layer)
	minigame.finished.connect(_on_forged)


func _on_forged(quality: String) -> void:
	var item_id: String = _pending_item
	_pending_item = ""
	var needs: Dictionary = _recipe_for(item_id)
	for material_id: String in needs:
		GameState.remove_item(material_id, int(needs[material_id]))
	GameState.forged_quality = quality
	GameState.add_item(item_id)
	Events.say("Anvil", "Forged: %s (%s)" % [DataLoader.item_name(item_id), quality])


func _target_item() -> String:
	if GameState.active_commission.is_empty():
		return fallback_item
	var commission: Dictionary = DataLoader.commissions.get(GameState.active_commission, {})
	return String(commission.get("item", fallback_item))


## Items with no recipe entry still cost one ore, so the anvil never forges
## something from nothing.
func _recipe_for(item_id: String) -> Dictionary:
	var needs: Dictionary = DataLoader.recipe(item_id)
	if needs.is_empty():
		needs = {"iron_ore": 1}
	return needs
