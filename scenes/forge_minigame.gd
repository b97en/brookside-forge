class_name ForgeMinigame
extends Control
## Timing mini-game: a marker ping-pongs across a bar; strike (SPACE) when it
## is inside the glowing zone. Several strikes per item, speeding up each time.
## Aggregate accuracy decides quality: poor / good / perfect.
## Pauses the world while open; emits finished + Events.forging_complete.

signal finished(quality: String)

const QUALITY_PERFECT_FRACTION: float = 0.85  # of max score
const QUALITY_GOOD_FRACTION: float = 0.5

const STRIKE_SOUNDS: Dictionary = {
	2: preload("res://assets/audio/strike_perfect.wav"),
	1: preload("res://assets/audio/strike_good.wav"),
	0: preload("res://assets/audio/strike_miss.wav"),
}

@export var strike_count: int = 4
@export var base_speed: float = 1.1  ## bar-widths per second on strike 1
@export var speed_ramp: float = 0.4  ## extra speed per subsequent strike
@export var perfect_half_width: float = 0.05  ## fraction of bar
@export var good_half_width: float = 0.16
@export var freeze_time: float = 0.3  ## marker freeze after a strike

## Set by the anvil before adding to the tree; shown in the title.
var item_name: String = ""

var _strike: int = 0
var _total_score: int = 0
var _phase: float = 0.0  # marker position 0..1
var _direction: float = 1.0
var _accepting_input: bool = false

var _marker: ColorRect
var _pips: Array[ColorRect] = []
var _audio: AudioStreamPlayer
var _sparks: CPUParticles2D
var _flash: ColorRect

@onready var bar: Control = %Bar
@onready var feedback: Label = %Feedback
@onready var pips_box: HBoxContainer = %Pips
@onready var panel: PanelContainer = %Panel
@onready var title: Label = %Title
@onready var hint: Label = %Hint


func _ready() -> void:
	get_tree().paused = true
	_build_bar()
	_build_pips()
	_build_juice()
	feedback.text = ""
	if not item_name.is_empty():
		title.text = "FORGING: %s" % item_name.to_upper()
	_update_hint()
	_accepting_input = true


func _update_hint() -> void:
	hint.text = "Strike %d of %d  -  SPACE in the glowing zone" % [
		mini(_strike + 1, strike_count), strike_count]


func _process(delta: float) -> void:
	if not _accepting_input:
		return
	var speed: float = base_speed + speed_ramp * float(_strike)
	_phase += speed * delta * _direction
	if _phase >= 1.0:
		_phase = 1.0
		_direction = -1.0
	elif _phase <= 0.0:
		_phase = 0.0
		_direction = 1.0
	_marker.position.x = _phase * (bar.size.x - _marker.size.x)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("strike") and _accepting_input:
		_do_strike()


func _do_strike() -> void:
	_accepting_input = false
	var offset: float = absf(_phase - 0.5)
	var score: int = 0
	if offset <= perfect_half_width:
		score = 2
	elif offset <= good_half_width:
		score = 1
	_total_score += score
	_pips[_strike].color = [Color(0.45, 0.2, 0.18), Color(0.85, 0.55, 0.2), Color(1.0, 0.85, 0.3)][score]
	_strike += 1

	_audio.stream = STRIKE_SOUNDS[score]
	_audio.play()
	if score > 0:
		_sparks.position = Vector2(_marker.position.x + _marker.size.x / 2.0, bar.size.y * 0.5)
		_sparks.amount = 16 if score == 2 else 8
		_sparks.restart()

	match score:
		2:
			_show_feedback("PERFECT!", Color(1.0, 0.85, 0.3))
			_shake_panel(4.0)
			_flash_screen()
		1:
			_show_feedback("Good", Color(0.85, 0.55, 0.2))
		0:
			_show_feedback("Miss...", Color(0.5, 0.35, 0.3))

	await get_tree().create_timer(freeze_time).timeout

	if _strike >= strike_count:
		_finish_forging()
	else:
		# Fresh run-up from alternating edges, so each strike reads slightly
		# differently and the player has to watch rather than count.
		_direction = -1.0 if _strike % 2 == 1 else 1.0
		_phase = 1.0 if _direction < 0.0 else 0.0
		_update_hint()
		_accepting_input = true


func _finish_forging() -> void:
	var max_score: float = float(strike_count * 2)
	var quality: String
	if float(_total_score) >= max_score * QUALITY_PERFECT_FRACTION:
		quality = "perfect"
	elif float(_total_score) >= max_score * QUALITY_GOOD_FRACTION:
		quality = "good"
	else:
		quality = "poor"
	_show_feedback("Quality: %s" % quality.to_upper(), Color.WHITE)
	await get_tree().create_timer(1.1).timeout
	_finish(quality)


func _finish(quality: String) -> void:
	get_tree().paused = false
	if quality == "perfect":
		_shake_camera()
	finished.emit(quality)
	Events.forging_complete.emit(quality)
	queue_free()


func _shake_camera() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	# Tween owned by the camera so it survives this node's queue_free.
	var tween := camera.create_tween()
	for i in 4:
		var jolt := Vector2(randf_range(-3, 3), randf_range(-3, 3)) * (1.0 - i / 4.0)
		tween.tween_property(camera, "offset", jolt, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)


func _build_bar() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.11, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg)

	var good := ColorRect.new()
	good.color = Color(0.62, 0.36, 0.16)
	_place_zone(good, good_half_width)
	bar.add_child(good)

	var perfect := ColorRect.new()
	perfect.color = Color(1.0, 0.61, 0.19)
	_place_zone(perfect, perfect_half_width)
	bar.add_child(perfect)

	_marker = ColorRect.new()
	_marker.color = Color.WHITE
	_marker.size = Vector2(4, bar.custom_minimum_size.y)
	bar.add_child(_marker)


func _place_zone(zone: ColorRect, half_width: float) -> void:
	var w: float = bar.custom_minimum_size.x
	zone.position = Vector2((0.5 - half_width) * w, 0)
	zone.size = Vector2(half_width * 2.0 * w, bar.custom_minimum_size.y)


func _build_pips() -> void:
	for i in strike_count:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 6)
		pip.color = Color(0.3, 0.22, 0.2)
		pips_box.add_child(pip)
		_pips.append(pip)


func _build_juice() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -6.0
	add_child(_audio)

	_sparks = CPUParticles2D.new()
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 1.0
	_sparks.amount = 12
	_sparks.lifetime = 0.5
	_sparks.direction = Vector2(0, -1)
	_sparks.spread = 70.0
	_sparks.initial_velocity_min = 50.0
	_sparks.initial_velocity_max = 130.0
	_sparks.gravity = Vector2(0, 320)
	_sparks.scale_amount_min = 1.0
	_sparks.scale_amount_max = 2.0
	_sparks.color = Color(1.0, 0.75, 0.3)
	bar.add_child(_sparks)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func _flash_screen() -> void:
	_flash.color.a = 0.25
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_flash, "color:a", 0.0, 0.15)


func _show_feedback(text: String, color: Color) -> void:
	feedback.text = text
	feedback.add_theme_color_override("font_color", color)
	feedback.pivot_offset = feedback.size / 2.0
	feedback.scale = Vector2(1.4, 1.4)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(feedback, "scale", Vector2.ONE, 0.15)


func _shake_panel(strength: float) -> void:
	var origin: Vector2 = panel.position
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "position", origin + Vector2(strength, 0), 0.04)
	tween.tween_property(panel, "position", origin - Vector2(strength, 0), 0.04)
	tween.tween_property(panel, "position", origin, 0.04)
