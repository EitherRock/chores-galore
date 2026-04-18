extends Node3D

@export var clean_time: float = 3.0
@onready var splatter: Decal = $PlateBody/Splatter
@export var clean_progress: float = 0.0

@onready var plate: RigidBody3D = $PlateBody
@export var broken_plate: PackedScene


func clean():
	if !is_instance_valid(splatter):
		return
	
	clean_progress += get_process_delta_time() / clean_time
	clean_progress = clamp(clean_progress, 0.0, 1.0)
	
	# Fade using modulate alpha
	var color = splatter.modulate
	color.a = 1.0 - clean_progress
	splatter.modulate = color
	splatter.scale = Vector3.ONE * (1.0 - clean_progress * 0.3)

	
	if clean_progress >= 1.0:
		splatter.queue_free()
		_update_clean()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	

#func _physics_process(_delta: float) -> void:
	#if not is_instance_valid(plate):
		#return
	#
	#if plate.linear_velocity.length() > 5 and not is_grabbed:
		#print('broken plate')
		#break_plate()

func break_plate():
	var broken = broken_plate.instantiate()
	add_child(broken)
	
	
	broken.global_transform = plate.global_transform
	for child in broken.get_children():
		child.linear_velocity = plate.linear_velocity
		child.angular_velocity = plate.angular_velocity
		
	plate.queue_free()
	
func _update_clean():
	ChoreManager.item_placed('dish')


func _on_plate_body_impact(collider, impulse) -> void:
	if collider is StaticBody3D or collider is RigidBody3D:
		if impulse.length() > 1:
			break_plate()
