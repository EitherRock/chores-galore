extends StaticBody3D

class_name WaterSource

@onready var plug = $DrainPlug/Plug
@onready var drain_marker = $DrainPlug/DrainMarker
@onready var water_particles: GPUParticles3D = $WaterFaucetFlow
@export var is_water_running: bool = false

@export var interact_prompt = 'Turn On'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	water_particles.emitting = false
	plug.chain_ready.connect(_on_chain_ready)
	plug.attachment_created.connect(_on_attachment_created)


func _on_chain_ready():
	print('chain is ready')

func _on_attachment_created(attachment):
	print('attachment ',attachment)
	#attachment.collision_mask &= ~1
	attachment.gravity_scale = 0
	attachment.global_position = drain_marker.global_position + Vector3(0, 1, 0)

func interact():
	if is_water_running:
		interact_prompt = 'Turn On'
		water_particles.emitting = false
		is_water_running = false
	else:
		interact_prompt = 'Turn Off'
		water_particles.emitting = true
		is_water_running = true
