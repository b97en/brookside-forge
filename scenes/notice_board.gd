class_name NoticeBoard
extends Interactable
## Village notice board: posts commissions one at a time, in data order,
## skipping ones already delivered. Reading it again repeats the current job.

func _on_interact() -> void:
	if not GameState.active_commission.is_empty():
		var current: Dictionary = DataLoader.commissions.get(GameState.active_commission, {})
		var item_id: String = String(current.get("item", ""))
		Events.say("Notice board", "Current job: %s. %s needs %s." % [
			String(current.get("title", "?")),
			DataLoader.item_name(item_id), DataLoader.recipe_text(item_id)])
		return
	var commission_id: String = GameState.next_commission_id()
	if commission_id.is_empty():
		Events.say("Notice board", "Nothing posted today.")
		return
	var commission: Dictionary = DataLoader.commissions[commission_id]
	GameState.active_commission = commission_id
	Events.commission_accepted.emit(commission_id)
	Events.say("Notice board", "%s -- %s" % [
		String(commission.get("title", "?")), String(commission.get("text", ""))])
