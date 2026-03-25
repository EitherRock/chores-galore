extends CharacterBody3D

# First Person camera
@export var mouse_sensitivity := 0.002
var yaw := 0.0
var pitch := 0.0

# Movement and Gravity
@export var speed := 6.0
@export var jump_velocity := 4.5
var gravity = ProjectSettings.get_setting('physics/3d/default_gravity')

# Grabby Grabby
@onready var ray = $Camera3D/RayCast3D
@onready var grab_point = $Camera3D/GrabPoint
@export var drag_sensitivity := 0.01
@export var drag_limit := 2.0
@export var hold_distance := 2.0

var held_object: RigidBody3D = null

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	if not is_multiplayer_authority():
		$Camera3D.current = false
	else:
		$Camera3D.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)
		
		rotation.y = yaw
		$Camera3D.rotation.x = pitch
		
	# Move held object around
	if event is InputEventMouseMotion and held_object:
		# Left/Right
		grab_point.position.x += event.relative.x * drag_sensitivity
		
		# Up/Down
		grab_point.position.y -= event.relative.y * drag_sensitivity
		
		grab_point.position.x = clamp(grab_point.position.x, -drag_limit, drag_limit)
		grab_point.position.y = clamp(grab_point.position.y, -drag_limit, drag_limit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('grab'):
		if held_object:
			release_object()
		else:
			try_grab()

func try_grab():
	if ray.is_colliding():
		var body = ray.get_collider()
		if body is RigidBody3D:
			held_object = body
			held_object.gravity_scale = 0
			NetworkHandler.request_authority(body.get_path(), multiplayer.get_unique_id())

func release_object():
	NetworkHandler.request_authority(held_object.get_path(), 1)
	held_object.gravity_scale = 1
	held_object = null

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	var input_dir = Input.get_vector('left', 'right', 'forward', 'backward')
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	if Input.is_action_just_pressed('jump') and is_on_floor():
		velocity.y = jump_velocity
		
	if held_object:
		var target_pos = grab_point.global_transform.origin
		var dir = target_pos - held_object.global_transform.origin
		held_object.linear_velocity = dir * 10.0
	
	grab_point.position.z = -hold_distance
	
	move_and_slide()
