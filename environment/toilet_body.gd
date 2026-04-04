extends StaticBody3D

class_name Toilet

signal toilet_flushed

@onready var water_mesh = $WaterMesh
@onready var flush_particles = $FlushParticles
@onready var fill_sound = $FillSound
@onready var flush_sound = $FlushSound

@export var flush_speed: float = 0.5  # Seconds to empty
@export var refill_speed: float = 0.1  # Seconds to refill
@export var interact_prompt = 'Flush'

@export var current_water_level: float = 3.1
@export var max_water_level: float = 3.1
@export var min_water_level: float = 2.52
@export var refill_delay: float = 1.0
var is_flushing: bool = false
var is_refilling: bool = false

func _ready():
	update_water_visuals()

func interact():
	if not multiplayer.is_server():
		rpc_id(1, "request_flush")
		return
	
	flush_toilet()

func flush_toilet():
	if is_flushing or is_refilling:
		return
	
	print("Flushing toilet!")
	is_flushing = true
	
	# Play flush effect on all clients
	rpc("play_flush_effect")

@rpc("reliable", "call_local")
func play_flush_effect():
	if flush_particles:
		flush_particles.emitting = true
	if flush_sound:
		flush_sound.play()

func _process(delta):
	if not multiplayer.is_server():
		return
	
	if is_flushing:
		current_water_level -= delta * flush_speed
		
		if current_water_level <= min_water_level:
			current_water_level = min_water_level
			is_flushing = false
			is_refilling = true
			rpc("stop_flush_effect")
			print("Toilet empty - refilling")
	
	elif is_refilling:
		await get_tree().create_timer(refill_delay).timeout
		current_water_level += delta * refill_speed
		
		if current_water_level >= max_water_level:
			current_water_level = max_water_level
			is_refilling = false
			print("Toilet refilled")
	
	# Update visuals every frame
	update_water_visuals()

func update_water_visuals():
	if water_mesh:
		# Scale water based on level
		water_mesh.scale.y = current_water_level
		
		# Position water so it rises from bottom
		var max_height = 0.5  # Adjust to your toilet bowl
		water_mesh.position.y = (current_water_level * max_height) / 2

@rpc("reliable", "call_local")
func stop_flush_effect():
	if flush_particles:
		flush_particles.emitting = false

@rpc("any_peer", "call_local")
func request_flush():
	if multiplayer.is_server():
		flush_toilet()
