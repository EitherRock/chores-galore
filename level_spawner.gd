extends MultiplayerSpawner

@export var network_level: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func spawn_level() -> void:
	if !multiplayer.is_server(): return
	
	var level: Node = network_level.instantiate()
	
	get_node(spawn_path).call_deferred('add_child', level) 
	for child in $"..".get_children():
		print(child)

func _on_ui_server_started() -> void:
	spawn_level()
