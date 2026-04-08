extends StaticBody3D
class_name ChoreBoard

@onready var _chore_list: Node3D = $ChoreList
@onready var _title: Label3D = $Title
@onready var _sync: MultiplayerSynchronizer = $ChoreSync

var _labels: Dictionary = {}

@export var chore_data: Array = [] :
	set(value):
		chore_data = value
		_refresh_display()

func _ready() -> void:
	if multiplayer.is_server():
		_sync.set_multiplayer_authority(1)
		ChoreManager.chores_selected.connect(_on_chores_selected)
		ChoreManager.chore_progress_updated.connect(_on_progress_updated)
		
		if ChoreManager.selected_chores.size() > 0:
			_on_chores_selected(ChoreManager.selected_chores)

func _on_chores_selected(_selected: Array) -> void:
	chore_data = ChoreManager.get_all_chore_data()

func _on_progress_updated(chore_key: String, current: int, required: int) -> void:
	print("=== ChoreBoard _on_progress_updated received: ", chore_key, " current: ", current, " required: ", required)
	
	# Find and update the data in the array
	for i in range(chore_data.size()):
		if chore_data[i]["key"] == chore_key:
			chore_data[i]["current"] = current
			break
	
	# Update the label directly without triggering setter
	if _labels.has(chore_key):
		var data = null
		for d in chore_data:
			if d["key"] == chore_key:
				data = d
				break
		
		if data:
			_labels[chore_key].text = "{name}: {current}/{required}".format({
				"name": data["name"],
				"current": current,
				"required": required
			})
			print("Label updated directly to: ", _labels[chore_key].text)

func _refresh_display() -> void:
	
	for child in _chore_list.get_children():
		child.queue_free()
	
	_labels.clear()
	
	if chore_data.is_empty():
		_show_placeholder()
		return
	
	var y_pos = _title.position.y - 0.2
	
	for data in chore_data:
		var label = _create_label(data)
		label.position = Vector3(-0.63, y_pos, 0.028)
		_chore_list.add_child(label)
		_labels[data["key"]] = label
		y_pos -= 0.1
		
func _create_label(data: Dictionary) -> Label3D:
	var label = Label3D.new()
	label.name = data["key"] + "_label"
	label.font_size = 12
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	if data["type"] in ChoreManager.CHORE_TYPES:
		label.text = "{name}: {current}/{required}".format({
			"name": data["name"],
			"current": data["current"],
			"required": data["required"]
		})
	else:
		label.text = data["name"]
	
	return label

func _show_placeholder() -> void:
	var label = Label3D.new()
	label.text = "Waiting for chores..."
	label.font_size = 12
	label.position = Vector3(0.2, 0, 0.0)
	_chore_list.add_child(label)
