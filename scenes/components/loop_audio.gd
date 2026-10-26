class_name LoopAudio
extends AudioStreamPlayer2D
## Plays its stream on loop (WAVs import unlooped; this restarts on finish).

func _ready() -> void:
	finished.connect(play)
	play()
