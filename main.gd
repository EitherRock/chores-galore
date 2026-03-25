extends Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()

#extends Node3D
#
#@onready var world = $World
#var player_scene = preload('res://player.tscn')
#
## Optional: set this to true in editor to host, false in exported client
#@export var is_host := true
#@export var server_ip := "127.0.0.1"
#
#
#func _ready():
	#if is_host:
		#start_host()
	#else:
		#join_game(server_ip)
#
#
#func start_host():
	#var peer = ENetMultiplayerPeer.new()
	#peer.create_server(7777)
	#multiplayer.multiplayer_peer = peer
#
	## Connect BEFORE spawning local player
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
#
	#print("Hosting Server")
#
	## Spawn local player AFTER peer_connected fires
	#_on_peer_connected(multiplayer.get_unique_id())
#
#
#func join_game(ip := "127.0.0.1"):
	## Connect signals BEFORE creating the client peer
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
#
	#var peer = ENetMultiplayerPeer.new()
	#peer.create_client(ip, 7777)
	#multiplayer.multiplayer_peer = peer
	#print("Joining Server")
#
#
#func _on_peer_connected(id):
	#print("Player Joined:", id)
	#if world.has_node(str(id)):
		## Already exists
		#return
	#
	#if id == multiplayer.get_unique_id():
		#spawn_player(id)
#
#
#func _on_peer_disconnected(id):
	#print("Player Left:", id)
	#if world.has_node(str(id)):
		#world.get_node(str(id)).queue_free()
#
#
#func spawn_player(id):
	#print('spawning')
	#var player = player_scene.instantiate()
	#player.name = str(id)
	#print(world)
	#print(player)
	#world.add_child(player)
	## Wait one frame to ensure node is fully in the tree before setting authority
	#await get_tree().process_frame
	#player.set_multiplayer_authority(id)
