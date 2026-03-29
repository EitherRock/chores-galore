extends StaticBody3D

@onready var chore_list: Node3D = $ChoreList
@onready var title: Label3D = $Title
@onready var sync: MultiplayerSynchronizer = $ChoreSync

var chore_labels: Dictionary = {}

# This variable will be synced across all clients
@export var chore_data: Array = []:
	set(value):
		#print("chore_data setter called with: ", value)
		chore_data = value
		_update_all_labels()

func _ready() -> void:
	#print("ChoreBoard _ready - is_server: ", multiplayer.is_server())
	
	# Set authority on the synchronizer (server has authority)
	if multiplayer.is_server():
		sync.set_multiplayer_authority(1)
	
	# Connect to ChoreManager only on server
	if multiplayer.is_server():
		print("Server: Connecting to ChoreManager signals")
		ChoreManager.chores_selected.connect(_on_chores_selected)
		ChoreManager.chore_progress_updated.connect(_on_chore_progress_updated)
		ChoreManager.chore_completed.connect(_on_chore_completed)
		
		# Check if chores already selected
		if ChoreManager.chosen_chores.size() > 0:
			print("Server: Chores already in ChoreManager, building chore_data")
			_build_and_set_chore_data(ChoreManager.chosen_chores)
	else:
		print("Client: Waiting for sync")
		_setup_empty_display()

func _build_and_set_chore_data(chosen: Array):
	var full_data = []
	for chore_key in chosen:
		var chore = ChoreManager.chore_options[chore_key]
		full_data.append({
			"key": chore_key,
			"required": chore.get('required', 0),
			"current": chore.get('current', 0),
			"name": chore['string'],
			"type": chore['type']
		})
	print("Building chore data: ", full_data)
	chore_data = full_data

func _setup_empty_display():
	print("Setting up empty display")
	var start_position = title.position
	var horizontal_offset: float = 0.6
	var spacing: float = 0.1
	var current_y = start_position.y - (spacing * 2)
	
	for i in range(3):
		var chore_label = Label3D.new()
		chore_label.name = "placeholder_" + str(i)
		chore_label.text = "Waiting for chores..."
		chore_label.font_size = 12
		chore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		chore_label.position = Vector3(
			start_position.x - horizontal_offset, 
			current_y, 
			start_position.z
		)
		chore_list.add_child(chore_label)
		current_y -= spacing

func _on_chores_selected(chosen: Array):
	print("Server: _on_chores_selected received: ", chosen)
	_build_and_set_chore_data(chosen)

func _update_all_labels():
	#print("Updating all labels with chore_data: ", chore_data)
	
	for child in chore_list.get_children():
		child.queue_free()
	
	chore_labels.clear()
	
	if chore_data.size() == 0:
		return
	
	var start_position = title.position
	var horizontal_offset: float = 0.6
	var spacing: float = 0.1
	var current_y = start_position.y - (spacing * 2)
	
	for data in chore_data:
		var chore_label = Label3D.new()
		chore_label.name = data["key"] + '_label'
		
		if data["type"] == ChoreManager.PUT_AWAY:
			chore_label.text = "{name}: {current}/{required}".format({
				"name": data["name"],
				"current": data["current"],
				"required": data["required"]
			})
		else:
			chore_label.text = data["name"]
			
		chore_label.font_size = 12
		chore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		chore_label.position = Vector3(
			start_position.x - horizontal_offset, 
			current_y, 
			start_position.z
		)
		
		chore_list.add_child(chore_label)
		chore_labels[data["key"]] = chore_label
		
		current_y -= spacing

func _on_chore_progress_updated(chore_key: String, current: int, required: int):
	print("Progress update: ", chore_key, " - ", current, "/", required)
	
	# Update the data in chore_data
	for i in range(chore_data.size()):
		if chore_data[i]["key"] == chore_key:
			chore_data[i]["current"] = current
			# Trigger sync and update labels by reassigning
			chore_data = chore_data
			break
	
	# Also update the label directly for immediate feedback
	if chore_labels.has(chore_key):
		for data in chore_data:
			if data["key"] == chore_key:
				chore_labels[chore_key].text = "{name}: {current}/{required}".format({
					"name": data["name"],
					"current": current,
					"required": required
				})
				break

func _on_chore_completed(chore_key: String):
	print("Chore completed on board: ", chore_key)
	
	for i in range(chore_data.size()):
		if chore_data[i]["key"] == chore_key:
			chore_data[i]["completed"] = true
			chore_data = chore_data
			break
	
	if chore_labels.has(chore_key):
		var label = chore_labels[chore_key]
		label.text = "✓ " + label.text
		label.modulate = Color.GREEN
#extends StaticBody3D
#
#@onready var chore_list: Node3D = $ChoreList
#@onready var title: Label3D = $Title
#@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
#
#var chore_labels: Dictionary = {}
#var labels_ready: bool = false
#
#@export var chore_data: Array = []:
	#set(value):
		#chore_data = value
		#if labels_ready:
			#_upate_all_labels()
	#
#
#func _ready() -> void:
	#if multiplayer.is_server():
		#sync.set_multiplayer_authority(1)
	#
	#if multiplayer.is_server():
		## Only connect to signals on all clients
		#print(ChoreManager.chosen_chores)
		#ChoreManager.chores_selected.connect(_on_chores_selected)
		#ChoreManager.chore_progress_updated.connect(_on_chore_progress_updated)
		#ChoreManager.chore_completed.connect(_on_chore_completed)
		#
		#if ChoreManager.chosen_chores.size() > 0:
			#_on_chores_selected(ChoreManager.chosen_chores)
	#else:
		#print('Client waiting for chore data from sync')
		#_setup_empty_labels()
#
#func _on_chores_selected(chosen: Array):
	#print("Server: Setting up chore data: ", chosen)
	## Store the chore keys in the synced variable
	#chore_data = chosen

#func _setup_empty_labels(chosen_chores: Array):
	#var start_position = title.position
	#
	#for child in chore_list.get_children():
		#child.queue_free()
		#
	#chore_labels.clear()
	#
	#var horizontal_offset: float = 0.6
	#var spacing: float = 0.1
	#var current_y = start_position.y - (spacing * 2)
	#
	#for chore_key in chosen_chores:
		#var chore = ChoreManager.chore_options[chore_key]
		#
		#var chore_label = Label3D.new()
		#chore_label.name = chore_key + '_label'
		#
		#if chore['type'] == ChoreManager.PUT_AWAY:
			#var required = ChoreManager.get_required_count(chore_key)
			#var current = chore.get('current', 0)
			#chore_label.text = "{string}: {current}/{required}".format({
				#"string": chore['string'],
				#"current": current,
				#"required": required
			#})
		#else:
			#chore_label.text = chore['string']
			#
		#chore_label.font_size = 12
		#chore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		#chore_label.position = Vector3(
			#start_position.x - horizontal_offset, 
			#current_y, 
			#start_position.z
		#)
		#
		#chore_list.add_child(chore_label)
		#chore_labels[chore_key] = chore_label
		#
		#current_y -= spacing
#
#func _on_chore_progress_updated(chore_key: String, current: int, required: int):
	#print("Progress update: ", chore_key, " - ", current, "/", required)
	#
	#if not labels_ready:
		#return
	#
	## Update locally
	#_update_label_text(chore_key, current, required)
	#
	## Sync to all other clients (if we're the server)
	#if multiplayer.is_server():
		#update_chore_label.rpc(chore_key, current, required)
#
#@rpc("reliable", "call_local")
#func update_chore_label(chore_key: String, current: int, required: int):
	#if not labels_ready:
		#return
		#
	## This runs on all clients
	#_update_label_text(chore_key, current, required)
#
#func _update_label_text(chore_key: String, current: int, required: int):
	#var label = chore_list.find_child(chore_key + "_label")
	#if label:
		#var chore = ChoreManager.chore_options[chore_key]
		#label.text = "{string}: {current}/{required}".format({
			#"string": chore['string'],
			#"current": current,
			#"required": required
		#})
		#print("Updated label for: ", chore_key, " to: ", label.text)
#
#func _on_chore_completed(chore_key: String):
	#print("Chore completed on board: ", chore_key)
	#
	#if not labels_ready:
		#return
	#
	#_update_label_completed(chore_key)
	#
	#if multiplayer.is_server():
		#complete_chore_label.rpc(chore_key)
#
#@rpc("reliable", "call_local")
#func complete_chore_label(chore_key: String):
	#if not labels_ready:
		#return
	#_update_label_completed(chore_key)
#
#func _update_label_completed(chore_key: String):
	#var label = chore_list.find_child(chore_key + "_label")
	#if label:
		#label.text = "✓ " + label.text
		#label.modulate = Color.GREEN
