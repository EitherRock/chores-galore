extends Area3D

@export var is_running: bool = false
@onready var water_particles: GPUParticles3D = %WaterFaucetFlow
#@onready var sound: AudioStreamPlayer3D = $RunningWaterSound

func turn_on():
	is_running = true
	water_particles.emitting = true
	#if sound:
		#sound.play()

func turn_off():
	is_running = false
	water_particles.emitting = false
	#if sound:
		#sound.stop()

func interact():
	if is_running:
		turn_off()
	else:
		turn_on()
