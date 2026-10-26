extends Node
## Signal bus. Systems emit/listen here instead of holding node paths to each
## other. Registered as autoload "Events".

@warning_ignore("unused_signal")
signal inventory_changed

## Fired by GameState.add_item for things the player visibly picks up or
## forges (not on save load). Drives the floating "+1 Iron Ore" text.
@warning_ignore("unused_signal")
signal item_gained(item_id: String, count: int)

@warning_ignore("unused_signal")
signal gold_changed(total: int)

@warning_ignore("unused_signal")
signal forging_complete(quality: String)

@warning_ignore("unused_signal")
signal commission_accepted(commission_id: String)

@warning_ignore("unused_signal")
signal commission_completed(commission_id: String)

signal dialogue_line(speaker: String, line: String)


## Single entry point for one-line dialogue. Prints to console; the HUD
## dialogue box subscribes to dialogue_line.
func say(speaker: String, line: String) -> void:
	print("[%s] %s" % [speaker, line])
	dialogue_line.emit(speaker, line)
