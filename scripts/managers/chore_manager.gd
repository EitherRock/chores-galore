extends Node

enum ChoreType { PUT_AWAY, CLEAN, PASS }

signal chore_progress_updated(chore_key: String, current: int, required: int)
signal chore_completed(chore_key: String)
signal chores_selected(chosen: Array)

const CHORE_OPTIONS := {
	"put_away_books": {
		"type": ChoreType.PUT_AWAY,
		"name": "Put Away Books",
		"container_scene": "res://environment/book_shelf.tscn",
		"item_scene": "res://environment/books.tscn",
		"item_type": "book",
		"min": 3,
		"max": 10
	},
	"throw_away_trash": {
		"type": ChoreType.PASS,
		"name": "Throw Away Trash"
	},
	"put_away_toys": {
		"type": ChoreType.PASS,
		"name": "Put Away Toys"
	}
}

var selected_chores: Array = []  # Stores chore keys
var _chore_data: Dictionary = {}  # Stores current progress and requirements
var _is_selected: bool = false

@export var max_chores: int = 3

func select_chores() -> void:
	if _is_selected:
		return
	
	selected_chores.clear()
	_chore_data.clear()
	
	while selected_chores.size() < max_chores:
		var available = CHORE_OPTIONS.keys()
		var random_key = available[randi() % available.size()]
		
		if random_key not in selected_chores:
			selected_chores.append(random_key)
			_chore_data[random_key] = {
				"current": 0,
				"required": _get_random_requirement(random_key)
			}
			print("Selected: ", random_key, " requires: ", _chore_data[random_key]["required"])
	
	_is_selected = true
	chores_selected.emit(selected_chores)

func _get_random_requirement(chore_key: String) -> int:
	var options = CHORE_OPTIONS[chore_key]
	if options.has("min"):
		return randi_range(options["min"], options["max"])
	return 0

func get_chore_data(chore_key: String) -> Dictionary:
	if _chore_data.has(chore_key):
		return {
			"key": chore_key,
			"name": CHORE_OPTIONS[chore_key]["name"],
			"type": CHORE_OPTIONS[chore_key]["type"],
			"current": _chore_data[chore_key]["current"],
			"required": _chore_data[chore_key]["required"],
			"item_type": CHORE_OPTIONS[chore_key].get("item_type", ),
			"item_scene": CHORE_OPTIONS[chore_key].get("item_scene", )
		}
	return {}

func get_all_chore_data() -> Array:
	var result = []
	for key in selected_chores:
		result.append(get_chore_data(key))
	return result

func item_placed(item_type: String) -> void:
	print("=== item_placed called with type: ", item_type)
	
	for chore_key in selected_chores:
		var required_item = CHORE_OPTIONS[chore_key].get("item_type", "")
		print("Checking chore: ", chore_key, " requires: ", required_item)
		
		if required_item != item_type:
			continue
		
		var data = _chore_data[chore_key]
		print("Current data for ", chore_key, ": ", data)
		
		if data["current"] < data["required"]:
			data["current"] += 1
			print("Emitting progress update: ", chore_key, " current: ", data["current"], " required: ", data["required"])
			chore_progress_updated.emit(chore_key, data["current"], data["required"])
			
			if data["current"] >= data["required"]:
				chore_completed.emit(chore_key)
			break
		else:
			print("Already at required count")
func is_chore_selected(chore_key: String) -> bool:
	return chore_key in selected_chores

func get_required_count(chore_key: String) -> int:
	return _chore_data.get(chore_key, {}).get("required", 0)

func reset() -> void:
	selected_chores.clear()
	_chore_data.clear()
	_is_selected = false
