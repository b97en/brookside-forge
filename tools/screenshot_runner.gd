extends Node
## Dev tool: loads a scene, waits for it to render, saves a screenshot, quits.
## Usage: godot --path . res://tools/screenshot_runner.tscn ++ <scene> [zoom] [options]
##   zoom      > 0 fits the whole map with an overview camera (0 = follow player)
##   demo      fills the HUD with representative state (gold, ore, commission)
##   minigame  opens the anvil mini-game and lands a perfect strike (implies
##             demo; use with forge_interior.tscn)
##   out=PATH  output path under res:// (default _archive/shot.png)
## Saved at 2x with nearest-neighbour scaling so the pixel art stays crisp in
## docs. Needs a display (not --headless). Not part of the game.

const SCALE: int = 2


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/village.tscn"
	var zoom: float = float(args[1]) if args.size() > 1 else 0.0
	var options: PackedStringArray = args.slice(2)
	var out_path: String = "res://_archive/shot.png"
	for option: String in options:
		if option.begins_with("out="):
			out_path = "res://" + option.trim_prefix("out=")
	var minigame_mode: bool = "minigame" in options

	var scene: Node = (load(scene_path) as PackedScene).instantiate()
	add_child(scene)
	# Let the HUD's deferred first-run hint fire, then clear it, so shots don't
	# depend on whether this machine has a save file.
	await get_tree().process_frame
	Hud.dialogue_panel.visible = false

	if zoom > 0.0:
		# Overview camera: fit the whole map instead of following the player.
		var cam := Camera2D.new()
		cam.zoom = Vector2(zoom, zoom)
		cam.position = Vector2(480, 272)
		add_child(cam)
		cam.make_current()

	if "demo" in options or minigame_mode:
		# Populate the HUD with representative state for visual checks.
		GameState.save_enabled = false
		GameState.add_gold(42)
		GameState.add_item("iron_ore", 2)
		GameState.active_commission = "farmer_scythe"
		Events.commission_accepted.emit("farmer_scythe")
		if not minigame_mode:
			Events.say("Farmer Garside", "Hay won't wait forever, smith. How's that scythe coming?")

	if minigame_mode:
		# Wait out the "+2 Iron Ore" pickup text before opening the anvil.
		await get_tree().create_timer(1.0).timeout
		(_find_by_class(scene, "Anvil") as Anvil).interact()
		await get_tree().create_timer(0.3).timeout
		var minigame := _find_by_class(self, "ForgeMinigame") as ForgeMinigame
		minigame._phase = 0.5  # dead centre of the glowing zone
		# process_frame fires before _process runs, so wait two frames for the
		# marker to be drawn at the new phase before striking.
		for i in 2:
			await get_tree().process_frame
		minigame._do_strike()
		# Long enough for the flash to fade, short enough to catch the sparks.
		await get_tree().create_timer(0.18).timeout
	else:
		await get_tree().create_timer(0.5).timeout

	var img: Image = get_viewport().get_texture().get_image()
	img.resize(img.get_width() * SCALE, img.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	img.save_png(out_path)
	print("screenshot saved: ", out_path, " (", img.get_width(), "x", img.get_height(), ")")
	get_tree().quit()


func _find_by_class(node: Node, klass: String) -> Node:
	if node.get_script() != null and node.get_script().get_global_name() == klass:
		return node
	for child in node.get_children():
		var found: Node = _find_by_class(child, klass)
		if found != null:
			return found
	return null
