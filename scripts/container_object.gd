extends StaticBody3D
class_name ContainerObject

signal item_placed(item: Item)
signal container_full

@export var chore_key: String = ""
@export var allowed_item_type: String = ""

var inventory: Array[Item] = []
var max_capacity: int = 0
var _is_ready: bool = false

func _ready() -> void:
	if not multiplayer.is_server():
		set_physics_process(false)
	
	$Area3D.body_entered.connect(_on_body_entered)
	
	if chore_key.is_empty():
		push_warning("Container has no chore_key set!")
		return
	
	if ChoreManager:
		if ChoreManager.is_chore_selected(chore_key):
			_setup()
		else:
			ChoreManager.chores_selected.connect(_on_chores_selected)

func _setup() -> void:
	max_capacity = ChoreManager.get_required_count(chore_key)
	_is_ready = true
	print("Container ready: ", name, " capacity: ", max_capacity)

func _on_chores_selected(_selected: Array) -> void:
	if chore_key in _selected:
		_setup()

func can_accept(item: Item) -> bool:
	return item.item_type == allowed_item_type and inventory.size() < max_capacity and _is_ready

func add_item(item: Item) -> bool:
	print('adding item')
	if not can_accept(item):
		return false
	
	inventory.append(item)
	item.on_placed()
	item_placed.emit(item)
	
	ChoreManager.item_placed(allowed_item_type)
	
	if inventory.size() >= max_capacity:
		container_full.emit()
	
	return true

func _on_body_entered(body: Node3D) -> void:
	if not body is Item:
		print('not item')
		return
	
	var item = body as Item
	if not can_accept(item):
		return
	
	if multiplayer.is_server():
		add_item(item)
		print('item added')
	else:
		_request_add_item.rpc_id(1, item.get_path())

@rpc("any_peer", "reliable")
func _request_add_item(item_path: NodePath) -> void:
	if not multiplayer.is_server():
		return
	
	var item = get_node(item_path)
	if item and can_accept(item):
		add_item(item)
