extends StaticBody3D

@export var speed := 5.0 # radians per second

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(speed * delta)
