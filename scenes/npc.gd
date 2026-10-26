class_name Npc
extends Interactable
## A villager who receives commissioned items. One NPC, single-line dialogue
## (POC scope: no relationship system, no dialogue trees).

@export var npc_id: String = "farmer"
@export var display_name: String = "Farmer Garside"


func _on_interact() -> void:
	var commission_id: String = GameState.active_commission
	if commission_id.is_empty():
		Events.say(display_name, "Check the notice board if tha's looking for work.")
		return

	var commission: Dictionary = DataLoader.commissions.get(commission_id, {})
	if String(commission.get("npc", "")) != npc_id:
		Events.say(display_name, "Not my order, that one.")
		return

	var item_id: String = String(commission.get("item", ""))
	if GameState.inventory.get(item_id, 0) <= 0:
		Events.say(display_name, String(commission.get("waiting_line", "Bring it when it's ready.")))
		return

	# Deliver: consume item, pay by forged quality, thank the smith.
	GameState.remove_item(item_id)
	var quality: String = GameState.forged_quality if GameState.forged_quality != "" else "good"
	var pay: int = int(Dictionary(commission.get("reward", {})).get(quality, 0))
	GameState.add_gold(pay)
	GameState.complete_commission(commission_id)
	Events.say(display_name, "%s  (+%d gold)" % [String(commission.get("thanks", "Thank you.")), pay])
	Events.commission_completed.emit(commission_id)
