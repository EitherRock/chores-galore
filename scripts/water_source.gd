extends StaticBody3D

class_name WaterSource

signal water_running(is_running)
signal drain_plugged(is_plugged)

@onready var plug = $DrainPlug/Plug
@onready var drain_marker = $DrainPlug/DrainMarker
@onready var water_particles: GPUParticles3D = $WaterFaucetFlow
@export var is_plugged: bool = true
@export var is_toilet: bool = false


# Use a property with setter to automatically sync visuals
@export var is_water_running: bool = false:
	set(value):
		if is_water_running == value:
			return
		is_water_running = value
		water_running.emit(is_water_running)
		# This runs on ALL peers when the value changes
		update_water_visuals()

@export var interact_prompt = 'Turn On'

func _ready() -> void:
	# Initialize visuals based on current state
	update_water_visuals()
	drain_plugged.emit(is_plugged)
	
	# Connect signals if they exist
	if plug and plug.has_signal("chain_ready"):
		plug.chain_ready.connect(_on_chain_ready)
	if plug and plug.has_signal("attachment_created"):
		plug.attachment_created.connect(_on_attachment_created)

func _on_chain_ready():
	print('chain is ready on peer: ', multiplayer.get_unique_id())

func _on_attachment_created(attachment):
	print('attachment ', attachment, ' on peer: ', multiplayer.get_unique_id())
	if attachment:
		attachment.gravity_scale = 0
		attachment.global_position = drain_marker.global_position + Vector3(0, 1, 0)

func interact():
	# Only the server can change water state
	if not multiplayer.is_server():
		# Client: send request to server
		rpc_id(1, "request_toggle_water")
		return
	
	# Server: toggle water and sync to all clients
	toggle_water.rpc(!is_water_running)

@rpc("any_peer", "call_local", "reliable")
func request_toggle_water():
	# Server receives request from client
	if multiplayer.is_server():
		toggle_water.rpc(!is_water_running)

@rpc("reliable", "call_local")
func toggle_water(new_state: bool):
	# This runs on ALL peers (server AND all clients)
	is_water_running = new_state


func update_water_visuals():
	# Update visuals based on current state
	if water_particles:
		water_particles.emitting = is_water_running
	
	# Update the interact prompt text based on state
	if is_water_running:
		interact_prompt = 'Turn Off'
	else:
		interact_prompt = 'Turn On'
	
	# Debug output to verify sync
	#print("Water visual update on peer: ", multiplayer.get_unique_id(), 
		  #" - Water running: ", is_water_running)
