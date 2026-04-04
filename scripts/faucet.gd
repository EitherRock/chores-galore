extends Area3D

@export var interact_prompt: String = "Turn faucet"
@export var is_running: bool = false:
	set(value):
		if is_running == value:
			return
		is_running = value
		# This will run on ALL peers when the value changes
		if is_running:
			turn_on()
		else:
			turn_off()

@onready var water_particles: GPUParticles3D = %WaterFaucetFlow

func interact():
	if not multiplayer.is_server():
		rpc_id(1, "request_toggle_faucet")
		return
	
	# Server toggles and tells ALL clients
	toggle_faucet.rpc(not is_running)

@rpc("any_peer", "call_local", "reliable")
func request_toggle_faucet():
	if multiplayer.is_server():
		toggle_faucet.rpc(not is_running)

# Changed from "authority" to "any_peer" so it runs on all clients
@rpc("any_peer", "call_local", "reliable")
func toggle_faucet(new_state: bool):
	is_running = new_state  # The setter will handle visuals

func turn_on():
	print("Turning ON water on peer: ", multiplayer.get_unique_id())
	water_particles.emitting = true

func turn_off():
	print("Turning OFF water on peer: ", multiplayer.get_unique_id())
	water_particles.emitting = false

#extends Area3D
#
#@export var is_running: bool = false
#@onready var water_particles: GPUParticles3D = %WaterFaucetFlow
##@onready var sound: AudioStreamPlayer3D = $RunningWaterSound
#
#func turn_on():
	#is_running = true
	#water_particles.emitting = true
	##if sound:
		##sound.play()
#
#func turn_off():
	#is_running = false
	#water_particles.emitting = false
	##if sound:
		##sound.stop()
#
#func interact():
	#if is_running:
		#turn_off()
	#else:
		#turn_on()
