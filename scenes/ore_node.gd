class_name OreNode
extends Interactable
## Marked rock the player mines for ore. Infinite for the POC.

@export var item_id: String = "iron_ore"


func _on_interact() -> void:
	GameState.add_item(item_id)
