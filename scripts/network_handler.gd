extends Node

const IP_ADDRESS: String = 'localhost'
const PORT: int = 42069

var peer: ENetMultiplayerPeer

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer

func start_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

@rpc('any_peer', 'reliable')
func request_authority(node_path: NodePath, new_owner: int):
	var node = get_node(node_path)
	print('node: ', node)
	node.set_multiplayer_authority(new_owner)
	if node.has_method('update_freeze'):
		node.update_freeze()
		print('test')
