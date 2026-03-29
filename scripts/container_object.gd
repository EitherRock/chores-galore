extends StaticBody3D
class_name ContainerObject

signal item_placed
signal container_full

@export var allowed_item_type: String = 'book'
@export var chore_key: String = ""

var inventory: Array = []
var max_capacity: int = 5
var chores_ready: bool = false

func _ready():
	var area3d = $Area3D
	area3d.body_entered.connect(_on_body_entered)
	
	# Connect to ChoreManager to know when chores are selected
	if ChoreManager:
		ChoreManager.chores_selected.connect(_on_chores_selected)
		
		# If chores already selected, set capacity immediately
		if ChoreManager.chosen_chores.size() > 0:
			_on_chores_selected(ChoreManager.chosen_chores)

func _on_chores_selected(chosen: Array):
	print("Container received chores_selected: ", chosen)
	
	# Check if this chore is in the selected list
	if chore_key in chosen:
		max_capacity = ChoreManager.get_required_count(chore_key)
		print("Container ", name, " max capacity set to: ", max_capacity, " for chore: ", chore_key)
		chores_ready = true
	else:
		print("Container ", name, " chore not selected: ", chore_key)

func can_accept(item) -> bool:
	return item.item_type == allowed_item_type and len(inventory) < max_capacity
	
func add_item(item) -> bool:
	if not can_accept(item):
		return false
	
	inventory.append(item)
	item.freeze = true
	
	item_placed.emit()
	
	if ChoreManager and chores_ready:
		ChoreManager.item_placed(allowed_item_type)
	
	if len(inventory) >= max_capacity:
		container_full.emit()
	
	return true

func is_full() -> bool:
	return len(inventory) >= max_capacity

func _on_body_entered(body: Node3D) -> void:
	if 'item_type' in body:
		var item = body
		if can_accept(item):
			if multiplayer.is_server():
				add_item(item)
			else:
				request_add_item.rpc_id(1, item.get_path())

@rpc("any_peer", "reliable")
func request_add_item(item_path: NodePath):
	if not multiplayer.is_server():
		return
	
	var item = get_node(item_path)
	if item and can_accept(item):
		add_item(item)

#extends StaticBody3D


#class_name ContainerObject
#
#signal item_placed
#signal container_full
#
#@export var allowed_item_type: String = 'book'
#@export var chore_key: String
#
#var inventory: Array = []
#var max_capacity: int = 5
#
#func _ready():
	#var area3d = $Area3D
	#area3d.body_entered.connect(_on_body_entered)
	#
	#if chore_key != "" and ChoreManager:
		#max_capacity = ChoreManager.get_required_count(chore_key)
		#print("Container max capacity set to: ", max_capacity, " for chore: ", chore_key)
#
#func can_accept(item) -> bool:
	#return item.item_type == allowed_item_type and len(inventory) < max_capacity
	#
#func add_item(item) -> bool:
	#if not can_accept(item):
		#return false
	#
	#inventory.append(item)
	#
	#item.freeze = true
	##item.visible = false
	#
	#item_placed.emit()
	#
	#if ChoreManager:
		#ChoreManager.item_placed(allowed_item_type)
	#
	#if len(inventory) >= max_capacity:
		#container_full.emit()
	#
	#return true
	#
#
#func is_full() -> bool:
	#return len(inventory) >= max_capacity
#
#
#func _on_body_entered(body: Node3D) -> void:
	#print('yup')
	## Check if the body has the item_type property (meaning it's an Item)
	#if 'item_type' in body:
	##if is_instance_of(body, Item):
		#print('somethign entered')
	#
		#var item = body
		#if can_accept(item):
			## Send to server for multiplayer
			#if multiplayer.is_server():
				#add_item(item)
			#else:
				#request_add_item.rpc_id(1, item.get_path())
#
#
#@rpc("any_peer", "reliable")
#func request_add_item(item_path: NodePath):
	#if not multiplayer.is_server():
		#return
	#
	#var item = get_node(item_path)
	#if item and can_accept(item):
		#add_item(item)
