extends Node3D

@export var clean_time: float = 3.0
@onready var splatter: Decal = $PlateBody/Splatter
@export var clean_progress: float = 0.0

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
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _update_clean():
	ChoreManager.item_placed('dish')
