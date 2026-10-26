extends Node
## Dev tool: programmatically builds village.tscn and saves it as a normal,
## editor-editable scene. Runs as a scene so autoloads and class_name scripts
## resolve. Run headless:
##   godot --headless --path . res://tools/build_village.tscn
## Re-running OVERWRITES scenes/village.tscn — hand edits to that scene should
## be made here instead (or stop re-running this tool once the layout is final).

const MAP_W: int = 60
const MAP_H: int = 34
const TILE: int = 16

# Atlas coords in village_tileset.tres (source 0 = Floors_Tiles.png).
const GRASS_PLAIN := Vector2i(1, 10)
const GRASS_VARIANTS: Array[Vector2i] = [
	Vector2i(2, 10), Vector2i(3, 10),
]
const DIRT_VARIANTS: Array[Vector2i] = [
	Vector2i(11, 10), Vector2i(12, 10), Vector2i(13, 10),
]
const COBBLE_VARIANTS: Array[Vector2i] = [
	Vector2i(16, 0), Vector2i(17, 0), Vector2i(18, 0),
	Vector2i(15, 1), Vector2i(16, 1), Vector2i(17, 1), Vector2i(18, 1),
]

const PACK := "res://assets/packs/free_pack/"


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1945  # deterministic layout

	var village := Node2D.new()
	village.name = "Village"
	village.set_script(load("res://scenes/components/scene_root.gd"))

	# --- Ground (grass everywhere) ---
	var tile_set: TileSet = load("res://assets/tiles/village_tileset.tres")
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tile_set
	village.add_child(ground)
	ground.owner = village
	for y in MAP_H:
		for x in MAP_W:
			var coord := GRASS_PLAIN
			if rng.randf() < 0.25:
				coord = GRASS_VARIANTS[rng.randi_range(0, GRASS_VARIANTS.size() - 1)]
			ground.set_cell(Vector2i(x, y), 0, coord)

	# --- Paths (dirt horizontal road + branch to forge, cobble apron) ---
	var paths := TileMapLayer.new()
	paths.name = "Paths"
	paths.tile_set = tile_set
	village.add_child(paths)
	paths.owner = village
	for x in MAP_W:  # main road, rows 19-20
		for y in [19, 20]:
			paths.set_cell(Vector2i(x, y), 0, DIRT_VARIANTS[rng.randi_range(0, DIRT_VARIANTS.size() - 1)])
	for y in range(11, 19):  # branch up to the forge door, cols 21-22
		for x in [21, 22]:
			paths.set_cell(Vector2i(x, y), 0, DIRT_VARIANTS[rng.randi_range(0, DIRT_VARIANTS.size() - 1)])
	for y in [9, 10]:  # cobble apron in front of the forge
		for x in range(19, 25):
			paths.set_cell(Vector2i(x, y), 0, COBBLE_VARIANTS[rng.randi_range(0, COBBLE_VARIANTS.size() - 1)])

	# --- Forge building (assembled sprites + collision) ---
	var building := Node2D.new()
	building.name = "ForgeBuilding"
	village.add_child(building)
	building.owner = village

	_add_sprite(building, village, "Wall",
		PACK + "Environment/Structures/Buildings/Walls.png",
		Rect2(0, 192, 96, 48), Vector2(352, 120))
	_add_sprite(building, village, "Roof",
		PACK + "Environment/Structures/Buildings/Roofs.png",
		Rect2(0, 0, 128, 96), Vector2(352, 56))
	_add_sprite(building, village, "Door",
		PACK + "Environment/Structures/Buildings/Props.png",
		Rect2(96, 16, 32, 48), Vector2(352, 122))
	_add_sprite(building, village, "Chimney",
		PACK + "Environment/Structures/Buildings/Props.png",
		Rect2(0, 64, 32, 64), Vector2(392, 32))

	_add_box(building, village, "WallCollision", Vector2(352, 124), Vector2(96, 40))

	# --- Trees ---
	var tree_positions: Array[Vector2] = [
		Vector2(96, 96), Vector2(820, 120), Vector2(140, 440),
		Vector2(760, 430), Vector2(60, 280), Vector2(880, 300),
		Vector2(560, 80),
	]
	var trees := Node2D.new()
	trees.name = "Trees"
	village.add_child(trees)
	trees.owner = village
	for i in tree_positions.size():
		var pos: Vector2 = tree_positions[i]
		_add_sprite(trees, village, "Tree%d" % i,
			PACK + "Environment/Props/Static/Trees/Model_02/Size_02.png",
			Rect2(), pos)
		_add_box(trees, village, "TreeCollision%d" % i, pos + Vector2(0, 30), Vector2(14, 10))

	# --- Map border collision ---
	var border := Node2D.new()
	border.name = "Border"
	village.add_child(border)
	border.owner = village
	var w: float = MAP_W * TILE
	var h: float = MAP_H * TILE
	_add_box(border, village, "Top", Vector2(w / 2, -8), Vector2(w, 16))
	_add_box(border, village, "Bottom", Vector2(w / 2, h + 8), Vector2(w, 16))
	_add_box(border, village, "Left", Vector2(-8, h / 2), Vector2(16, h))
	_add_box(border, village, "Right", Vector2(w + 8, h / 2), Vector2(16, h))

	# --- Interactables: ore node + forge door ---
	var ore: Area2D = (load("res://scenes/ore_node.tscn") as PackedScene).instantiate()
	ore.position = Vector2(800, 264)
	village.add_child(ore)
	ore.owner = village

	var door: Area2D = (load("res://scenes/components/door.tscn") as PackedScene).instantiate()
	door.name = "ForgeDoor"
	door.position = Vector2(352, 150)
	door.set("prompt_text", "E - Enter forge")
	door.set("target_scene", "res://scenes/forge_interior.tscn")
	door.set("spawn_position", Vector2(320, 220))
	village.add_child(door)
	door.owner = village

	# --- Notice board + farmer NPC ---
	var board: Area2D = (load("res://scenes/notice_board.tscn") as PackedScene).instantiate()
	board.position = Vector2(440, 290)
	village.add_child(board)
	board.owner = village

	var farmer: Area2D = (load("res://scenes/npc.tscn") as PackedScene).instantiate()
	farmer.name = "Farmer"
	farmer.position = Vector2(620, 292)
	village.add_child(farmer)
	farmer.owner = village

	# --- Player ---
	var player: Node2D = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = Vector2(480, 340)
	village.add_child(player)
	player.owner = village

	# --- Save ---
	var packed := PackedScene.new()
	var err: int = packed.pack(village)
	if err == OK:
		err = ResourceSaver.save(packed, "res://scenes/village.tscn")
	print("build_village: ", "OK" if err == OK else ("FAILED %d" % err))
	village.free()
	get_tree().quit(0 if err == OK else 1)


func _add_sprite(parent: Node, owner_node: Node, sprite_name: String,
		texture_path: String, region: Rect2, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	if region.size == Vector2.ZERO:
		sprite.texture = load(texture_path)
	else:
		var atlas := AtlasTexture.new()
		atlas.atlas = load(texture_path)
		atlas.region = region
		sprite.texture = atlas
	sprite.position = pos
	parent.add_child(sprite)
	sprite.owner = owner_node


func _add_box(parent: Node, owner_node: Node, body_name: String,
		pos: Vector2, size: Vector2) -> void:
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
	body.owner = owner_node
	shape_node.owner = owner_node
