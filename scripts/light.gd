extends GrabableRigidBody

@onready var light_source: OmniLight3D = $Light

@export var is_light_on: bool = true:
	set(value):
		if is_light_on == value:
			return
		is_light_on = value
		# This runs on ALL peers when the value changes
		update_visuals()

var interact_prompt: String = 'Turn Off'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if not multiplayer.is_server():
		rpc_id(1, "request_interact")
		return
	
	toggle_light.rpc(!is_light_on)
		
@rpc("reliable", "call_local")
func toggle_light(new_state: bool):
	# This runs on ALL peers (server AND all clients)
	is_light_on = new_state
	
@rpc("any_peer", "call_local")
func request_interact():
	if multiplayer.is_server():
		toggle_light.rpc(!is_light_on)
		
func update_visuals():
	if is_light_on:
		interact_prompt = 'Turn Off'
		light_source.light_energy = 1.0
	else:
		interact_prompt = 'Turn On'
		light_source.light_energy = 0.0
