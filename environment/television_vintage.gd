extends RigidBody3D


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#update_freeze()
	#
func update_freeze():
	freeze = not is_multiplayer_authority()
	#if multiplayer.is_server():
		#set_multiplayer_authority(1)
	#
	#if not is_multiplayer_authority():
		#freeze = true

@export var replicated_position : Vector3
@export var replicated_rotation : Vector3
@export var replicated_linear_velocity : Vector3
@export var replicated_angular_velocity : Vector3

func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	if is_multiplayer_authority():
		replicated_position = position
		replicated_rotation = rotation
		replicated_linear_velocity = linear_velocity
		replicated_angular_velocity = angular_velocity
	else:
		position = replicated_position
		rotation = replicated_rotation
		linear_velocity = replicated_linear_velocity
		angular_velocity = replicated_angular_velocity
		
