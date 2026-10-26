extends Node
## Dev tool: generates scenes/forge_interior.tscn (room, furnace, anvil, exit).
## Run headless: godot --headless --path . res://tools/build_forge_interior.tscn
## Re-running OVERWRITES the scene — make layout changes here.

const TILE: int = 16
# Room in tile coords: x 10..29, y 5..16 (320x192 px).
const ROOM_X: int = 10
const ROOM_Y: int = 5
const ROOM_W: int = 20
const ROOM_H: int = 12

const FLOOR_VARIANTS: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
]
const WALL_TOP := Vector2i(1, 10)
const WALL_BOTTOM := Vector2i(1, 11)

const PACK := "res://assets/packs/free_pack/"


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1947

	var room := Node2D.new()
	room.name = "ForgeInterior"
	room.set_script(load("res://scenes/components/scene_root.gd"))

	# --- Tiles: top wall band (2 rows), floor below ---
	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = load("res://assets/tiles/forge_tileset.tres")
	room.add_child(tiles)
	tiles.owner = room
	for y in range(ROOM_Y, ROOM_Y + ROOM_H):
		for x in range(ROOM_X, ROOM_X + ROOM_W):
			var coord: Vector2i
			if y == ROOM_Y:
				coord = WALL_TOP
			elif y == ROOM_Y + 1:
				coord = WALL_BOTTOM
			elif rng.randf() < 0.12:
				coord = FLOOR_VARIANTS[rng.randi_range(0, FLOOR_VARIANTS.size() - 1)]
			else:
				coord = Vector2i(2, 2)  # plain dark floor
			tiles.set_cell(Vector2i(x, y), 0, coord)

	# --- Furnace (lit brick variant) against the top wall ---
	var furnace := Sprite2D.new()
	furnace.name = "Furnace"
	var furnace_tex := AtlasTexture.new()
	furnace_tex.atlas = load(PACK + "Environment/Structures/Stations/Furnace/Furnace.png")
	furnace_tex.region = Rect2(64, 64, 44, 64)
	furnace.texture = furnace_tex
	furnace.position = Vector2(320, 124)
	room.add_child(furnace)
	furnace.owner = room
	_add_box(room, "FurnaceBlock", Vector2(320, 140), Vector2(48, 22))

	# --- Animated fire at the furnace mouth ---
	var fire := AnimatedSprite2D.new()
	fire.name = "ForgeFire"
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("burn")
	frames.set_animation_speed("burn", 8.0)
	frames.set_animation_loop("burn", true)
	var fire_sheet: Texture2D = load(PACK + "Environment/Structures/Stations/Bonfire/Fire_01-Sheet.png")
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = fire_sheet
		frame.region = Rect2(i * 32, 0, 32, 48)
		frames.add_frame("burn", frame)
	fire.sprite_frames = frames
	fire.animation = &"burn"
	fire.autoplay = "burn"
	fire.position = Vector2(320, 132)
	room.add_child(fire)
	fire.owner = room

	# --- Forge ambience: crackle loop + rising embers ---
	var crackle := AudioStreamPlayer2D.new()
	crackle.name = "ForgeCrackle"
	crackle.set_script(load("res://scenes/components/loop_audio.gd"))
	crackle.stream = load("res://assets/audio/forge_crackle.wav")
	crackle.position = Vector2(320, 132)
	crackle.volume_db = -10.0
	crackle.max_distance = 360.0
	room.add_child(crackle)
	crackle.owner = room

	var embers := CPUParticles2D.new()
	embers.name = "Embers"
	embers.position = Vector2(320, 128)
	embers.amount = 8
	embers.lifetime = 1.4
	embers.direction = Vector2(0, -1)
	embers.spread = 24.0
	embers.initial_velocity_min = 8.0
	embers.initial_velocity_max = 22.0
	embers.gravity = Vector2(0, -14)
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 1.6
	embers.color = Color(1.0, 0.62, 0.22, 0.9)
	room.add_child(embers)
	embers.owner = room

	# --- Anvil station (interactable) ---
	var anvil: Area2D = (load("res://scenes/anvil.tscn") as PackedScene).instantiate()
	anvil.position = Vector2(248, 190)
	room.add_child(anvil)
	anvil.owner = room

	# --- Exit door back to the village ---
	var door: Area2D = (load("res://scenes/components/door.tscn") as PackedScene).instantiate()
	door.name = "ExitDoor"
	door.position = Vector2(320, 264)
	door.set("prompt_text", "E - Leave")
	door.set("target_scene", "res://scenes/village.tscn")
	door.set("spawn_position", Vector2(352, 170))
	room.add_child(door)
	door.owner = room

	# --- Room collision (inside wall faces) ---
	var px_left: float = ROOM_X * TILE
	var px_top: float = ROOM_Y * TILE
	var px_w: float = ROOM_W * TILE
	var px_h: float = ROOM_H * TILE
	_add_box(room, "WallTop", Vector2(px_left + px_w / 2, px_top + 28), Vector2(px_w, 8))
	_add_box(room, "WallBottom", Vector2(px_left + px_w / 2, px_top + px_h + 4), Vector2(px_w, 8))
	_add_box(room, "WallLeft", Vector2(px_left - 4, px_top + px_h / 2), Vector2(8, px_h))
	_add_box(room, "WallRight", Vector2(px_left + px_w + 4, px_top + px_h / 2), Vector2(8, px_h))

	# --- Player ---
	var player: Node2D = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = Vector2(320, 220)
	room.add_child(player)
	player.owner = room

	# --- Save ---
	var packed := PackedScene.new()
	var err: int = packed.pack(room)
	if err == OK:
		err = ResourceSaver.save(packed, "res://scenes/forge_interior.tscn")
	print("build_forge_interior: ", "OK" if err == OK else ("FAILED %d" % err))
	room.free()
	get_tree().quit(0 if err == OK else 1)


func _add_box(parent: Node, body_name: String, pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.position = pos
	var shape_node := CollisionShape2D.new()
	shape_node.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	body.add_child(shape_node)
	parent.add_child(body)
	body.owner = parent
	shape_node.owner = parent
