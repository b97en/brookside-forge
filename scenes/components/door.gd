class_name Door
extends Interactable
## Interactable that moves the player to another scene, spawning them at
## spawn_position in the target.

@export_file("*.tscn") var target_scene: String
@export var spawn_position: Vector2 = Vector2.INF


func _on_interact() -> void:
	GameState.next_spawn = spawn_position
	get_tree().change_scene_to_file.call_deferred(target_scene)
