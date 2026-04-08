extends Node3D

@onready var pickup_items = $SpawnMarkers/PickUpItems
@onready var dish_items = $SpawnMarkers/Dishes
@onready var chore_board = %ChoreBoard

@export var chore_data: Array = [] :
	set(value):
		chore_data = value
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		ChoreManager.chores_selected.connect(_on_chores_selected)
		
		if ChoreManager.selected_chores.size() > 0:
			_on_chores_selected()
			call_deferred('_spawn_pickup_items')
	
func _on_chores_selected():
	chore_data = ChoreManager.get_all_chore_data()



func _spawn_pickup_items():
	var pickup_markers: Array = pickup_items.get_children()
	pickup_markers.shuffle() # randomize marker order
	
	var dish_markers: Array = dish_items.get_children()
	dish_markers.shuffle() # randominze dish order
	
	var test_chore_types: Array = [ChoreManager.ChoreType.PUT_AWAY, ChoreManager.ChoreType.CLEAN]
	
	for chore in chore_data:
		# Check valid chore
		var marker_index := 0
		var markers: Array
		
		if chore.get('type') == ChoreManager.ChoreType.PUT_AWAY:
			markers = pickup_markers
		
		elif chore.get('type') == ChoreManager.ChoreType.CLEAN:
			markers = dish_markers
		
		if chore.get("type") in test_chore_types and chore.has("item_scene") and not chore["item_scene"].is_empty():
			var scene = load(chore["item_scene"])
			for i in range(chore['required']):
				#if chore.get("type") == ChoreManager.ChoreType.PUT_AWAY:
				if marker_index >= markers.size():
					print("Not enough markers for chores")
					return
			
				var marker = markers[marker_index]
				marker_index += 1
				
				if not marker.is_inside_tree():
					await marker.ready

				var item = scene.instantiate()
			
				# Set position (use global for safety)
				add_child(item)
				item.global_position = marker.global_position
				#print("Spawned item at:", marker.name)
