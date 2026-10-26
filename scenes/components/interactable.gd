class_name Interactable
extends Area2D
## Base for anything the player can press E on. The player's InteractionArea
## finds these; this node just shows a prompt and reacts when triggered.
## Subclasses override _on_interact().

signal interacted

@export var prompt_text: String = "E"
## Optional player animation prefix (e.g. "collect") played facing this
## node before interact() fires. Empty = interact immediately. The player
## scene must have <prefix>_down / _side / _up animations.
@export var player_animation: String = ""

var _prompt: Label


func _ready() -> void:
	_prompt = Label.new()
	_prompt.text = prompt_text
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_color", Color.WHITE)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 2)
	_prompt.visible = false
	add_child(_prompt)
	# Centre the prompt above this node once its size is known.
	_prompt.reset_size()
	_prompt.position = Vector2(-_prompt.size.x / 2.0, -28.0)


func set_prompt_visible(value: bool) -> void:
	_prompt.visible = value


func interact() -> void:
	interacted.emit()
	_on_interact()


func _on_interact() -> void:
	pass
