extends CharacterBody3D
class_name Player

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

# Grab physics tuning
@export var grab_spring_strength: float = 45.0    # Higher = more responsive
@export var grab_damping_strength: float = 18.0   # Higher = less swing
@export var grab_angular_damping: float = 0.92    # Higher = less spin

var held_object: GrabableRigidBody = null
var is_grabbing: bool = false
var grab_request_pending: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
	if not is_multiplayer_authority():
		set_physics_process(false)

func _ready():
	add_to_group("players")
	
	if not is_multiplayer_authority():
		$Camera3D.current = false
	else:
		$Camera3D.current = true
		
		var marker = MeshInstance3D.new()
		marker.mesh = SphereMesh.new()
		marker.scale = Vector3(0.1, 0.1, 0.1)
		marker.material_override = StandardMaterial3D.new()
		marker.material_override.albedo_color = Color.RED
		grab_point.add_child(marker)
		
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
	if not is_multiplayer_authority():
		return
	
	if event.is_action_pressed('grab'):
		if held_object:
			release_object()
		else:
			try_grab()
	
	if event.is_action_released('grab') and held_object:
		release_object()

@rpc("any_peer", "reliable")
func test_rpc(message: String):
	print("TEST RPC RECEIVED on player ", name, ": ", message)

func try_grab():
	# Perform raycast to find grabable object
	if ray.is_colliding():
		var body = ray.get_collider()
		if body is GrabableRigidBody:
			# Send grab request to the object (server will process it)
			body.grab_request.rpc_id(1, multiplayer.get_unique_id())
			grab_request_pending = true

@rpc("any_peer", "reliable")
func grab_response(object_path: NodePath, success: bool):
	# Called by the GrabableRigidBody when grab is processed
	if success:
		var body = get_node(object_path)
		if body and body is GrabableRigidBody:
			held_object = body
			is_grabbing = true
			grab_request_pending = false
			print("Successfully grabbed: ", body.name)
			
			# Disable gravity on held object
			body.gravity_scale = 0
	else:
		# Grab failed
		grab_request_pending = false
		print("Grab failed")

func release_object():
	if not held_object:
		return
	
	print("Releasing object: ", held_object.name)
	# Send release request to the object
	held_object.release_request.rpc_id(1, multiplayer.get_unique_id())
	held_object = null
	is_grabbing = false
	
	grab_point.position = Vector3(0, 0, -hold_distance)

@rpc("any_peer", "reliable", 'call_local')
func release_response(success: bool):
	# Called by the GrabableRigidBody when release is processed
	if success:
		print("Successfully released object")
	else:
		print("Release failed")

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		# Non-authority client - just handle movement locally for responsiveness
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
			
		move_and_slide()
		return
	
	# Authority player (this client's player)
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
		
	# Update held object position with improved physics
	if held_object and is_grabbing:
		var target_pos = grab_point.global_transform.origin
		var current_pos = held_object.global_transform.origin
		var dir = target_pos - current_pos
		
		# Spring force (pulls toward target)
		var spring_force = dir * (grab_spring_strength * held_object.mass)
		
		# Damping force (resists velocity to stop swinging)
		var damping_force = -held_object.linear_velocity * (grab_damping_strength * held_object.mass)
		
		var total_force = spring_force + damping_force
		
		# Apply force - direct if server, RPC if client
		if multiplayer.is_server():
			held_object.apply_force_from_grab(total_force)
		else:
			held_object.apply_force_from_grab.rpc_id(1, total_force)
		
		# Angular damping to prevent spinning
		held_object.angular_velocity = held_object.angular_velocity * grab_angular_damping
	
	grab_point.position.z = -hold_distance
	
	move_and_slide()

# Helper function to find player by ID
func _find_player_by_id(player_id: int) -> Player:
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p is Player and p.name.to_int() == player_id:
			return p
	return null
