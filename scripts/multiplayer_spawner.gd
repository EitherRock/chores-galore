extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	
func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return
	
	var player: Node = network_player.instantiate()
	player.name = str(id)
	
	get_node(spawn_path).call_deferred('add_child', player) 
	

func spawn_server_player() ->void:
	var server_id = multiplayer.get_unique_id()
	var player: Node = network_player.instantiate()
	player.name = str(server_id)
	
	get_node(spawn_path).call_deferred('add_child', player)


func _on_ui_server_started() -> void:
	if multiplayer.is_server():
		spawn_server_player()
		ChoreManager.select_chores()
		
