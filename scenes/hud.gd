extends CanvasLayer
## Persistent HUD (autoload "Hud"): gold, inventory, commission card, dialogue
## box. Driven entirely by Events/GameState — scenes never talk to it directly.

## Dialogue stays up for this long plus a per-character allowance, so long
## lines can actually be read.
const DIALOGUE_MIN_SECONDS: float = 3.0
const DIALOGUE_SECONDS_PER_CHAR: float = 0.06

var _dialogue_token: int = 0

@onready var gold_label: Label = %GoldLabel
@onready var inventory_label: Label = %InventoryLabel
@onready var commission_title: Label = %CommissionTitle
@onready var commission_body: Label = %CommissionBody
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var line_label: Label = %LineLabel


func _ready() -> void:
	Events.gold_changed.connect(func(_total: int) -> void: _refresh_gold())
	Events.inventory_changed.connect(_refresh_inventory)
	Events.inventory_changed.connect(_refresh_commission)
	Events.commission_accepted.connect(func(_id: String) -> void: _refresh_commission())
	Events.commission_completed.connect(func(_id: String) -> void: _refresh_commission())
	Events.dialogue_line.connect(_show_dialogue)
	_refresh_gold()
	_refresh_inventory()
	_refresh_commission()
	dialogue_panel.visible = false
	if GameState.is_new_game:
		# Deferred so the first scene is on screen before the hint appears.
		Events.say.call_deferred("Brookside",
			"WASD or arrows to walk, E to interact. Start at the notice board by the crossroads.")


func _refresh_gold() -> void:
	gold_label.text = "Gold: %d" % GameState.gold


func _refresh_inventory() -> void:
	var commission: Dictionary = DataLoader.commissions.get(GameState.active_commission, {})
	var commission_item: String = String(commission.get("item", ""))
	var parts: PackedStringArray = []
	for item_id: String in GameState.inventory:
		var label: String = DataLoader.item_name(item_id)
		if item_id == commission_item and not GameState.forged_quality.is_empty():
			label += " (%s)" % GameState.forged_quality
		parts.append("%s x%d" % [label, GameState.inventory[item_id]])
	inventory_label.text = "  ".join(parts) if not parts.is_empty() else "-"


func _refresh_commission() -> void:
	if GameState.active_commission.is_empty():
		commission_title.text = "No commission"
		commission_body.text = "Read the notice board"
		return
	var commission: Dictionary = DataLoader.commissions.get(GameState.active_commission, {})
	var item_id: String = String(commission.get("item", "?"))
	var npc: String = String(commission.get("npc", "?"))
	commission_title.text = String(commission.get("title", "?"))
	if int(GameState.inventory.get(item_id, 0)) > 0:
		commission_body.text = "%s ready - take it to the %s" % [DataLoader.item_name(item_id), npc]
	else:
		commission_body.text = "Forge a %s for the %s\nNeeds %s" % [
			DataLoader.item_name(item_id), npc, DataLoader.recipe_text(item_id)]


func _show_dialogue(speaker: String, line: String) -> void:
	speaker_label.text = speaker
	line_label.text = line
	dialogue_panel.visible = true
	_dialogue_token += 1
	var token: int = _dialogue_token
	var seconds: float = maxf(DIALOGUE_MIN_SECONDS, line.length() * DIALOGUE_SECONDS_PER_CHAR)
	await get_tree().create_timer(seconds).timeout
	if token == _dialogue_token:
		dialogue_panel.visible = false
