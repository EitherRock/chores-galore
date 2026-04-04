extends Node3D

@onready var left_eye = $LeftEye
@onready var right_eye = $RightEye
@onready var left_pupil = $LeftEye/Pupil
@onready var right_pupil = $RightEye/Pupil

# Eye movement settings
@export var movement_radius: float = 0.015  # Max distance from center
@export var movement_speed: float = 8.0
@export var rest_duration: float = 2.0
@export var look_at_chance: float = 0.4
@export var look_at_duration: float = 1.5

# 🔥 NEW: Exaggeration controls
@export var horizontal_strength: float = 2.5
@export var vertical_strength: float = 2.0

# Cylinder settings
@export var cylinder_radius: float = 0.4

# Blinking settings
@export var blink_enabled: bool = false
@export var blink_interval_min: float = 10.0
@export var blink_interval_max: float = 20.0
@export var blink_closed_duration: float = 0.1

# Internal variables
var target_offset: Vector2 = Vector2.ZERO
var current_offset: Vector2 = Vector2.ZERO
var is_blinking: bool = false
var is_looking: bool = false
var available_targets: Array = []
var original_pupil_scales: Dictionary = {}
var left_original_position: Vector3
var right_original_position: Vector3

func _ready():
	# Store original pupil positions (including Z)
	left_original_position = left_pupil.position
	right_original_position = right_pupil.position
	
	print("Original pupil positions (Z locked):")
	print("Left pupil: ", left_original_position)
	print("Right pupil: ", right_original_position)
	
	# Store original scales
	original_pupil_scales[left_pupil] = left_pupil.scale
	original_pupil_scales[right_pupil] = right_pupil.scale
	
	calculate_safe_movement_radius()
	find_available_targets()
	start_eye_movement()
	
	if blink_enabled:
		start_blinking()

func calculate_safe_movement_radius():
	var max_radius = cylinder_radius * 0.8
	if movement_radius > max_radius:
		movement_radius = max_radius

func find_available_targets():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player != get_parent() and is_instance_valid(player):
			available_targets.append(player)
	
	var objects = get_tree().get_nodes_in_group("look_targets")
	available_targets.append_array(objects)

func start_eye_movement():
	while true:
		await get_tree().create_timer(randf_range(0.5, rest_duration)).timeout
		
		if is_blinking:
			continue
		
		var should_look = randf() < look_at_chance and available_targets.size() > 0
		
		if should_look and not is_looking:
			look_at_random_target()
		else:
			random_movement()

func random_movement():
	var angle = randf_range(0, TAU)
	var distance = randf_range(0, movement_radius * 0.8)
	
	var offset = Vector2(
		cos(angle) * distance * horizontal_strength,
		sin(angle) * distance * vertical_strength
	)
	
	# Clamp to allowed radius
	if offset.length() > movement_radius:
		offset = offset.normalized() * movement_radius
	
	target_offset = offset

func look_at_random_target():
	if available_targets.is_empty():
		random_movement()
		return
	
	var target = available_targets[randi() % available_targets.size()]
	
	if not is_instance_valid(target):
		find_available_targets()
		return
	
	look_at_target(target)
	
	is_looking = true
	await get_tree().create_timer(look_at_duration).timeout
	
	target_offset = Vector2.ZERO
	await get_tree().create_timer(randf_range(0.3, 0.8)).timeout
	is_looking = false

func look_at_target(target: Node3D):
	if not is_instance_valid(target):
		return
	
	var direction = (target.global_position - global_position).normalized()
	var local_direction = global_transform.basis.inverse() * direction
	
	# 🔥 Use X and Z now
	var dir2D = Vector2(local_direction.x, local_direction.z)
	
	if dir2D.length() > 1.0:
		dir2D = dir2D.normalized()
	
	dir2D.x *= horizontal_strength
	dir2D.y *= vertical_strength
	
	if dir2D.length() > 1.0:
		dir2D = dir2D.normalized()
	
	target_offset = dir2D * movement_radius

func start_blinking():
	while true:
		var wait_time = randf_range(blink_interval_min, blink_interval_max)
		await get_tree().create_timer(wait_time).timeout
		
		if not is_blinking:
			await perform_blink()

func perform_blink():
	if is_blinking:
		return
	
	is_blinking = true
	
	var left_original = original_pupil_scales[left_pupil].y
	var right_original = original_pupil_scales[right_pupil].y
	
	left_pupil.scale.y = 0.01
	right_pupil.scale.y = 0.01
	
	await get_tree().create_timer(blink_closed_duration).timeout
	
	left_pupil.scale.y = left_original
	right_pupil.scale.y = right_original
	
	is_blinking = false

func _process(delta):
	if not is_blinking:
		current_offset = current_offset.lerp(target_offset, movement_speed * delta)
		
		left_pupil.position = Vector3(
			left_original_position.x + current_offset.x,
			left_original_position.y, # 🔒 LOCK Y
			left_original_position.z + current_offset.y
		)

		
		right_pupil.position = Vector3(
			right_original_position.x + current_offset.x,
			right_original_position.y, # 🔒 LOCK Y
			right_original_position.z + current_offset.y
		)


# Debug
func _input(event):
	if event.is_action_pressed("ui_text_backspace") and OS.is_debug_build():
		print("=== Eye Debug Info ===")
		print("Offset: ", current_offset)
		print("Left pupil: ", left_pupil.position)
		print("Z locked at: ", left_original_position.z)
