class_name SceneRoot
extends Node2D
## Root script for walkable scenes (village, forge interior). After a Door
## scene change, places the player at the requested spawn point.

func _ready() -> void:
	var player := get_node_or_null("Player") as Node2D
	if player != null and GameState.next_spawn.is_finite():
		player.position = GameState.next_spawn
	GameState.next_spawn = Vector2.INF
