class_name Player
extends CharacterBody2D

const SPEED: float = 80.0

## Last non-zero movement direction; drives which idle animation plays.
var facing: Vector2 = Vector2.DOWN

var _nearby: Array[Interactable] = []
## True while an interaction animation (mining) plays; movement and further
## interactions wait until it ends.
var _busy: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)
	Events.item_gained.connect(_on_item_gained)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not _busy:
		var target: Interactable = _nearest_interactable()
		if target == null:
			return
		var anim: String = target.player_animation
		if anim.is_empty() or not sprite.sprite_frames.has_animation(anim + "_down"):
			if not anim.is_empty():
				push_warning("Player: no '%s_*' animations; interacting without one" % anim)
			target.interact()
		else:
			_animate_then_interact(target)


func _physics_process(_delta: float) -> void:
	if _busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	move_and_slide()
	_update_animation(input_dir)


## Turns to face the target, plays its animation to the end, then interacts.
## The target's effect (ore appearing) lands at the end of the swing, which
## is what makes gathering feel like doing something rather than a menu pick.
func _animate_then_interact(target: Interactable) -> void:
	_busy = true
	var to_target: Vector2 = target.global_position - global_position
	if to_target.length_squared() > 1.0:
		facing = to_target.normalized()
	sprite.play(target.player_animation + "_" + _facing_suffix())
	await sprite.animation_finished
	_busy = false
	if is_instance_valid(target):
		target.interact()
	_update_animation(Vector2.ZERO)


func _update_animation(input_dir: Vector2) -> void:
	var moving: bool = input_dir != Vector2.ZERO
	if moving:
		facing = input_dir
	sprite.play(("walk_" if moving else "idle_") + _facing_suffix())


## "side" / "up" / "down" for the current facing; also flips the sprite for
## left-facing (all side sheets face right).
func _facing_suffix() -> String:
	if absf(facing.x) > absf(facing.y):
		sprite.flip_h = facing.x < 0.0
		return "side"
	if facing.y < 0.0:
		return "up"
	return "down"


func _on_item_gained(item_id: String, count: int) -> void:
	_spawn_floating_text("+%d %s" % [count, DataLoader.item_name(item_id)])


## A small label that rises from above the player's head and fades out.
func _spawn_floating_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.z_index = 10
	add_child(label)
	label.reset_size()
	label.position = Vector2(-label.size.x / 2.0, -30.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 14.0, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


func _on_area_entered(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable != null:
		_nearby.append(interactable)
		interactable.set_prompt_visible(true)


func _on_area_exited(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable != null:
		_nearby.erase(interactable)
		interactable.set_prompt_visible(false)


func _nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_dist: float = INF
	for interactable in _nearby:
		var dist: float = global_position.distance_squared_to(interactable.global_position)
		if dist < best_dist:
			best_dist = dist
			best = interactable
	return best
