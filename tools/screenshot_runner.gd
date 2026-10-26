extends Node
## Dev tool: loads a scene, waits for it to render, saves a screenshot, quits.
## Usage: godot --path . res://tools/screenshot_runner.tscn ++ res://scenes/village.tscn [zoom]
## Output: _archive/shot.png (gdignored folder). Not part of the game.

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/village.tscn"
	var zoom: float = float(args[1]) if args.size() > 1 else 0.0

	var scene: Node = (load(scene_path) as PackedScene).instantiate()
	add_child(scene)

	if zoom > 0.0:
		# Overview camera: fit the whole map instead of following the player.
		var cam := Camera2D.new()
		cam.zoom = Vector2(zoom, zoom)
		cam.position = Vector2(480, 272)
		add_child(cam)
		cam.make_current()

	if args.size() > 2 and args[2] == "demo":
		# Populate the HUD with representative state for visual checks.
		GameState.save_enabled = false
		GameState.add_gold(42)
		GameState.add_item("iron_ore", 2)
		GameState.active_commission = "farmer_scythe"
		Events.commission_accepted.emit("farmer_scythe")
		Events.say("Farmer Garside", "Hay won't wait forever, smith. How's that scythe coming?")

	await get_tree().create_timer(0.5).timeout
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("res://_archive/shot.png")
	print("screenshot saved: _archive/shot.png (", img.get_width(), "x", img.get_height(), ")")
	get_tree().quit()
