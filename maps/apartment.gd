extends Node3D

@onready var pickup_items = $SpawnMarkers/PickUpItems
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
	var markers: Array = pickup_items.get_children()
	markers.shuffle() # randomize marker order
	
	var marker_index := 0
	
	for chore in chore_data:
		#print('printing chore ', chore)
		# Check valid chore
		if chore.get("type") == ChoreManager.ChoreType.PUT_AWAY and chore.has("item_scene") and not chore["item_scene"].is_empty():
			var scene = load(chore["item_scene"])
			for i in range(chore['required']):
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
