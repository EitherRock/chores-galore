extends RayCast3D

@onready var interaction_prompt_label: Label = $InteractionPrompt

func _process(_delta):
	var collided_object = get_collider()
	print('collided_object ', collided_object)
	interaction_prompt_label.text = ""
	
	if collided_object and collided_object.has_method("interact"):
		interaction_prompt_label.text = "[E] " + collided_object.interact_prompt
		
		if Input.is_action_just_pressed("interact"):
			collided_object.interact()
