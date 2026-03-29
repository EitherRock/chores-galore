extends RigidBody3D
class_name GrabableRigidBody

var grabbed_by: int = -1
var is_grabbed: bool = false

func _ready():
	# Set initial authority to the server
	set_multiplayer_authority(1)
	
	# Store original gravity
	set_meta("original_gravity", gravity_scale)
	
	# Make sure physics is enabled on the server
	if is_multiplayer_authority():
		freeze = false
		set_physics_process(true)
	
	#print("GrabableRigidBody ready: ", name, " authority: ", get_multiplayer_authority())

@rpc('any_peer', 'call_local', 'reliable')
func grab_request(player_id: int):
	if Util.debug:
		print("grab_request called on ", name, " by player ", player_id, " authority: ", is_multiplayer_authority())
	
	if not is_multiplayer_authority():
		print('object is not authority, cannot process grab')
		return
	
	if grabbed_by == -1:
		grabbed_by = player_id
		if Util.debug:
			print('object grabbed by: ', grabbed_by)
		is_grabbed = true
		
		# Disable collisions with player while grabbed
		set_collision_mask_value(2, false)
		set_collision_layer_value(2, false)
		
		if Util.debug:
			print("Sending grab_response to player: ", player_id)
		
		# Get the player node
		var player_node = get_node("/root/Main/World/" + str(player_id))
		
		if player_node:
			# Check if we're sending to ourselves
			if player_id == multiplayer.get_unique_id():
				# Call directly on the same peer
				player_node.grab_response(get_path(), true)
			else:
				# Use RPC for remote peer
				player_node.grab_response.rpc_id(player_id, get_path(), true)
	else:
		print('object already grabbed by: ', grabbed_by)
		var player_node = get_node("/root/Main/World/" + str(player_id))
		if player_node:
			if player_id == multiplayer.get_unique_id():
				player_node.grab_response(get_path(), false)
			else:
				player_node.grab_response.rpc_id(player_id, get_path(), false)
			
			
@rpc('any_peer', 'call_local', 'reliable')
func release_request(player_id: int):
	print("release_request called on ", name, " by player ", player_id)
	
	if not is_multiplayer_authority():
		return
	
	if grabbed_by == player_id:
		print('object released by: ', player_id)
		grabbed_by = -1
		is_grabbed = false
		
		# Re-enable collisions
		set_collision_mask_value(2, true)
		set_collision_layer_value(2, true)
		
		# Restore gravity
		gravity_scale = get_meta("original_gravity", 1.0)
		
		# Notify the releasing player
		get_node("/root/Main/World/" + str(player_id)).release_response.rpc_id(player_id, true)


@rpc("any_peer", "reliable", "call_local")
func apply_force_from_grab(force: Vector3):
	# This runs on whoever has authority (should be server)
	if is_multiplayer_authority() and is_grabbed:
		apply_central_force(force)
