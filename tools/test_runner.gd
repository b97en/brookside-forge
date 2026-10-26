extends Node
## Dev tool: headless smoke test of game wiring. Loads the village, exercises
## interactables and GameState, prints TEST OK / TEST FAIL.
## Run: godot --headless --path . res://tools/test_runner.tscn

func _ready() -> void:
	GameState.save_path = "user://save_test.json"  # never touch the real save
	var failures: Array[String] = []

	# --- Save/load round-trip through the real code path ---
	GameState.gold = 12
	GameState.inventory = {"iron_ore": 3}
	GameState.completed_commissions = ["farmer_scythe"]
	GameState.active_commission = "farmer_horseshoes"
	GameState.save_game()
	GameState.save_enabled = false  # the reset below must not overwrite the file
	GameState.gold = 0
	GameState.inventory = {}
	GameState.completed_commissions = []
	GameState.active_commission = ""
	GameState.save_enabled = true
	GameState.load_game()
	if GameState.gold != 12 or GameState.inventory.get("iron_ore", 0) != 3 \
			or GameState.active_commission != "farmer_horseshoes" \
			or GameState.completed_commissions != ["farmer_scythe"]:
		failures.append("save/load round-trip failed: %d %s '%s' %s" % [
			GameState.gold, GameState.inventory, GameState.active_commission,
			GameState.completed_commissions])
	DirAccess.remove_absolute(GameState.save_path)
	GameState.save_enabled = false
	GameState.gold = 0
	GameState.inventory = {}
	GameState.completed_commissions = []
	GameState.active_commission = ""

	# --- Data: recipes and commission ordering ---
	if DataLoader.recipe("scythe").get("iron_ore", 0) != 2:
		failures.append("scythe recipe wrong: %s" % DataLoader.recipe("scythe"))
	if DataLoader.recipe_text("scythe") != "2 Iron Ore":
		failures.append("recipe_text wrong: '%s'" % DataLoader.recipe_text("scythe"))
	var order: Array[String] = DataLoader.commission_ids_in_order()
	if order != ["farmer_scythe", "farmer_horseshoes", "farmer_gate_hinges"]:
		failures.append("commission order wrong: %s" % str(order))
	for id in order:
		var c: Dictionary = DataLoader.commissions[id]
		if not DataLoader.items.has(String(c.get("item", ""))):
			failures.append("commission %s names unknown item" % id)
	if GameState.next_commission_id() != "farmer_scythe":
		failures.append("next_commission_id should start at farmer_scythe")
	GameState.completed_commissions = ["farmer_scythe", "farmer_horseshoes", "farmer_gate_hinges"]
	if GameState.next_commission_id() != "farmer_scythe" or not GameState.completed_commissions.is_empty():
		failures.append("next_commission_id did not cycle after all done")

	var village: Node = (load("res://scenes/village.tscn") as PackedScene).instantiate()
	add_child(village)
	await get_tree().process_frame

	# Ore node mining
	var ore := village.get_node_or_null("OreNode") as OreNode
	if ore == null:
		failures.append("OreNode missing from village")
	else:
		if ore.player_animation != "collect":
			failures.append("OreNode should request the collect animation")
		ore.interact()
		ore.interact()
		if GameState.inventory.get("iron_ore", 0) != 2:
			failures.append("expected 2 iron_ore, got %s" % GameState.inventory)

	# GameState item removal
	if not GameState.remove_item("iron_ore", 1):
		failures.append("remove_item failed")
	if GameState.remove_item("iron_ore", 5):
		failures.append("remove_item allowed overdraw")

	# Door configured
	var door := village.get_node_or_null("ForgeDoor") as Door
	if door == null:
		failures.append("ForgeDoor missing from village")
	elif door.target_scene != "res://scenes/forge_interior.tscn":
		failures.append("ForgeDoor target wrong: %s" % door.target_scene)

	# Player has interaction area and the mining animations
	var player := village.get_node_or_null("Player") as Player
	if player == null or player.get_node_or_null("InteractionArea") == null:
		failures.append("Player InteractionArea missing")
	else:
		for anim in ["collect_down", "collect_side", "collect_up"]:
			if not player.sprite.sprite_frames.has_animation(anim):
				failures.append("Player missing animation %s" % anim)
			elif player.sprite.sprite_frames.get_animation_loop(anim):
				failures.append("Player animation %s must not loop (interaction waits on it)" % anim)
		# Floating text spawns on item gain and cleans itself up.
		GameState.add_item("iron_ore")
		if _count_labels(player) == 0:
			failures.append("floating text not spawned on item gain")
		await get_tree().create_timer(1.3).timeout
		if _count_labels(player) != 0:
			failures.append("floating text not freed")
		GameState.inventory.clear()

	village.queue_free()

	# --- Forge interior: anvil + mini-game shell + recipes ---
	var interior: Node = (load("res://scenes/forge_interior.tscn") as PackedScene).instantiate()
	add_child(interior)
	await get_tree().process_frame

	var anvil := _find_by_class(interior, "Anvil") as Anvil
	if anvil == null:
		failures.append("Anvil missing from forge interior")
	else:
		GameState.inventory.clear()
		GameState.active_commission = ""
		anvil.interact()  # no ore -> should refuse
		await get_tree().process_frame
		if _find_by_class(self, "ForgeMinigame") != null:
			failures.append("minigame opened without ore")

		GameState.add_item("iron_ore")  # scythe needs 2 -> still refuse
		anvil.interact()
		await get_tree().process_frame
		if _find_by_class(self, "ForgeMinigame") != null:
			failures.append("minigame opened with 1 ore (scythe needs 2)")

		GameState.add_item("iron_ore")
		anvil.interact()
		await get_tree().process_frame
		var minigame := _find_by_class(self, "ForgeMinigame") as ForgeMinigame
		if minigame == null:
			failures.append("minigame did not open with ore")
		elif not get_tree().paused:
			failures.append("world not paused during minigame")
		else:
			if minigame.title.text != "FORGING: SCYTHE":
				failures.append("minigame title wrong: '%s'" % minigame.title.text)
			if not minigame.hint.text.begins_with("Strike 1 of 4"):
				failures.append("minigame hint wrong: '%s'" % minigame.hint.text)
			minigame._finish("good")
			await get_tree().process_frame
			if get_tree().paused:
				failures.append("world still paused after minigame")
			if GameState.inventory.get("iron_ore", 0) != 0:
				failures.append("ore not consumed: %s" % GameState.inventory)
			if GameState.inventory.get("scythe", 0) != 1:
				failures.append("scythe not produced: %s" % GameState.inventory)

	# --- Commission loop end-to-end (board -> forge -> deliver -> next job) ---
	GameState.inventory.clear()
	GameState.gold = 0
	GameState.active_commission = ""
	GameState.forged_quality = ""
	GameState.completed_commissions = []

	var board := (load("res://scenes/notice_board.tscn") as PackedScene).instantiate() as NoticeBoard
	var farmer := (load("res://scenes/npc.tscn") as PackedScene).instantiate() as Npc
	add_child(board)
	add_child(farmer)
	await get_tree().process_frame

	farmer.interact()  # before accepting: pointed at the board
	board.interact()
	if GameState.active_commission != "farmer_scythe":
		failures.append("commission not accepted: '%s'" % GameState.active_commission)
	board.interact()  # second read: shows current job, must not re-accept

	farmer.interact()  # no scythe yet -> waiting line, no pay
	if GameState.gold != 0:
		failures.append("farmer paid before delivery")

	# Forge the scythe via the anvil (commission decides the item).
	GameState.add_item("iron_ore", 2)
	var anvil2 := _find_by_class(interior, "Anvil") as Anvil
	anvil2.interact()
	await get_tree().process_frame
	var mg2 := _find_by_class(self, "ForgeMinigame") as ForgeMinigame
	if mg2 == null:
		failures.append("commission test: minigame did not open")
	else:
		mg2._finish("perfect")
		await get_tree().process_frame
		if GameState.inventory.get("scythe", 0) != 1:
			failures.append("commission item not forged: %s" % GameState.inventory)
		if GameState.forged_quality != "perfect":
			failures.append("forged_quality not stored: '%s'" % GameState.forged_quality)

	farmer.interact()  # deliver
	if GameState.gold != 70:
		failures.append("expected 70 gold for perfect scythe, got %d" % GameState.gold)
	if GameState.active_commission != "" or GameState.inventory.get("scythe", 0) != 0:
		failures.append("commission not cleared after delivery")
	if GameState.completed_commissions != ["farmer_scythe"]:
		failures.append("delivery not recorded: %s" % GameState.completed_commissions)

	# Second job: the board must move on to the horseshoes (1 ore).
	board.interact()
	if GameState.active_commission != "farmer_horseshoes":
		failures.append("board did not advance to horseshoes: '%s'" % GameState.active_commission)
	GameState.add_item("iron_ore", 1)
	anvil2.interact()
	await get_tree().process_frame
	var mg3 := _find_by_class(self, "ForgeMinigame") as ForgeMinigame
	if mg3 == null:
		failures.append("horseshoes: minigame did not open with 1 ore")
	else:
		if mg3.title.text != "FORGING: HORSESHOES":
			failures.append("horseshoes title wrong: '%s'" % mg3.title.text)
		mg3._finish("poor")
		await get_tree().process_frame
		if GameState.inventory.get("horseshoes", 0) != 1 or GameState.inventory.has("iron_ore"):
			failures.append("horseshoes not forged from 1 ore: %s" % GameState.inventory)
	farmer.interact()
	if GameState.gold != 80:
		failures.append("expected 80 gold after poor horseshoes, got %d" % GameState.gold)
	if GameState.completed_commissions != ["farmer_scythe", "farmer_horseshoes"]:
		failures.append("second delivery not recorded: %s" % GameState.completed_commissions)

	# --- Mini-game scoring ---
	get_tree().paused = false
	var scoring := (load("res://scenes/forge_minigame.tscn") as PackedScene).instantiate() as ForgeMinigame
	scoring.freeze_time = 0.01
	add_child(scoring)
	await get_tree().process_frame
	var captured: Array[String] = []
	scoring.finished.connect(func(q: String) -> void: captured.append(q))
	for phase in [0.5, 0.5, 0.52, 0.62]:  # perfect, perfect, perfect-edge?, good
		scoring._phase = phase
		scoring._do_strike()
		await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(1.3).timeout  # result display delay
	if captured != ["perfect"]:
		failures.append("scoring: expected [perfect], got %s" % str(captured))
	if get_tree().paused:
		failures.append("scoring: tree left paused")

	# --- HUD reflects state ---
	var hud: CanvasLayer = get_node("/root/Hud")
	GameState.add_gold(5)
	GameState.add_item("iron_ore")
	await get_tree().process_frame
	if not String(hud.get_node("%GoldLabel").text).contains(str(GameState.gold)):
		failures.append("HUD gold label stale: '%s'" % hud.get_node("%GoldLabel").text)
	if not String(hud.get_node("%InventoryLabel").text).contains("Iron Ore"):
		failures.append("HUD inventory label stale: '%s'" % hud.get_node("%InventoryLabel").text)
	board.interact()  # gate hinges
	await get_tree().process_frame
	var card_body: String = String(hud.get_node("%CommissionBody").text)
	if not card_body.contains("2 Iron Ore"):
		failures.append("HUD commission card lacks recipe: '%s'" % card_body)
	Events.say("Tester", "hello")
	await get_tree().process_frame
	if not hud.get_node("%DialoguePanel").visible:
		failures.append("dialogue panel not shown on say()")

	if failures.is_empty():
		print("TEST OK")
	else:
		for f in failures:
			print("TEST FAIL: ", f)
	get_tree().quit(0 if failures.is_empty() else 1)


func _find_by_class(node: Node, klass: String) -> Node:
	if node.get_script() != null and node.get_script().get_global_name() == klass:
		return node
	for child in node.get_children():
		var found: Node = _find_by_class(child, klass)
		if found != null:
			return found
	return null


func _count_labels(node: Node) -> int:
	var n: int = 0
	for child in node.get_children():
		if child is Label:
			n += 1
	return n
