extends MeshInstance3D

@export var fill_speed: float = 0.05
@export var max_water_height: float = 1.04
var current_water_height: float = 0.0
var is_water_running: bool = false 
var is_drain_plugged: bool = false

@onready var parent = get_parent()
@onready var start_position: Vector3

func _ready() -> void:
	start_position = position
	
	# Only server connects to parent signals
	if multiplayer.is_server():
		parent.water_running.connect(_on_water_running)
		parent.drain_plugged.connect(_on_drain_plugged)

func _process(delta: float) -> void:
	if multiplayer.is_server():
		# Server updates water logic
		update_water_logic(delta)

	# Update position for ALL peers (server AND clients)
	position.y = start_position.y + current_water_height

func update_water_logic(delta: float):
	if is_water_running and is_drain_plugged:
		visible = true
		# Water rising
		if current_water_height < max_water_height:
			current_water_height += fill_speed * delta
			current_water_height = min(current_water_height, max_water_height)
			
			# Sync to clients
			if multiplayer.get_peers().size() > 0:
				sync_water_height.rpc(current_water_height)
	else:
		# Water draining
		if current_water_height > 0:
			current_water_height -= fill_speed * delta * 1.5
			current_water_height = max(current_water_height, 0)
			
			# Sync to clients
			if multiplayer.get_peers().size() > 0:
				sync_water_height.rpc(current_water_height)
		else:
			visible = false

@rpc("reliable", "call_local")
func sync_water_height(height: float):
	current_water_height = height

func _on_water_running(is_running: bool):
	print('Water is now running on server')
	is_water_running = is_running
	
	if multiplayer.get_peers().size() > 0:
		sync_water_state.rpc(is_water_running, is_drain_plugged)

func _on_drain_plugged(is_plugged: bool):
	print('Drain is now plugged on server')
	is_drain_plugged = is_plugged
	
	if multiplayer.get_peers().size() > 0:
		sync_water_state.rpc(is_water_running, is_drain_plugged)

@rpc("reliable", "call_local")
func sync_water_state(water_running: bool, drain_plugged: bool):
	is_water_running = water_running
	is_drain_plugged = drain_plugged
