extends RayCast3D

@onready var interaction_prompt_label: Label = $InteractionPrompt
var current_interactable: Node = null

func _process(_delta):
	var collided_object = get_collider()
	print('collided_object: ', collided_object)
	interaction_prompt_label.text = ""
	
	# Check if we're looking at an interactable object
	if collided_object and collided_object.has_method("interact"):
		# Only show prompt if we can interact (server or appropriate authority)
		if can_interact_with(collided_object):
			interaction_prompt_label.text = "[E] " + collided_object.interact_prompt
			current_interactable = collided_object
			
			# Handle interaction input
			if Input.is_action_just_pressed("interact"):
				handle_interaction(collided_object)
	else:
		current_interactable = null

func handle_interaction(interactable: Node):
	# If we're the server, call interact directly
	if multiplayer.is_server():
		interactable.interact()
	else:
		# Client: send request to server
		request_interaction.rpc_id(1, interactable.get_path())

@rpc("any_peer", "call_local", "reliable")
func request_interaction(interactable_path: NodePath):
	# Server receives request from client
	if multiplayer.is_server():
		var interactable = get_node(interactable_path)
		if interactable and interactable.has_method("interact"):
			interactable.interact()
			print("Server processing interaction for: ", interactable.name)

func can_interact_with(interactable: Node) -> bool:
	# Everyone can request interaction, but only server processes it
	# This ensures the prompt shows up for all players
	return true
	
	# Optional: Only show prompt if player is within a certain distance
	# var distance = global_position.distance_to(interactable.global_position)
	# return distance < 3.0

# Optional: Add cooldown to prevent spam
var interaction_cooldown: float = 0.0

func _process_interaction_timer(delta):
	if interaction_cooldown > 0:
		interaction_cooldown -= delta

func can_interact_with_cooldown() -> bool:
	return interaction_cooldown <= 0
