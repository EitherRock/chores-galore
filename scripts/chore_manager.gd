extends Node
enum {PUT_AWAY, CLEAN, PASS}

signal chore_progress_updated(chore_key: String, current: int, required: int)
signal chore_completed(chore_key: String)
signal chores_selected(chosen_chore_list: Array)

var chore_options: Dictionary = {
	'put_away_books': {
		'type': PUT_AWAY,
		'string': 'Put Away Books',
		'container': 'res://environment/book_shelf.tscn',
		'item_type': 'book',
		'min_cap': 3,
		'max_cap': 10,
		'current': 0,
		'required': 0
	},
	'throw_away_trash': {'type': PASS, 'string': 'Throw Away Trash', 'current': 0},
	'put_away_toys':{'type': PASS, 'string': 'Put Away Toys', 'current': 0}
}

var chosen_chores: Array = []
var chores_chosen: bool = false
@export var max_chores: int = 2


func set_up_chores():
	pass

func choose_chores():
	if chores_chosen:
		return
		
	print("=== choose_chores called by: ", multiplayer.get_unique_id(), " is_server: ", multiplayer.is_server())
	chosen_chores.clear()
	var chore_data_to_sync = []
	
	while len(chosen_chores) < max_chores:
		var keys = chore_options.keys()
		var random_pick = keys[randi() % keys.size()]
		if random_pick not in chosen_chores:
			chosen_chores.append(random_pick)
			
			
			if chore_options[random_pick].has('min_cap'):
				var required = randi_range(chore_options[random_pick]['min_cap'], chore_options[random_pick]['max_cap'])
				chore_options[random_pick]['required'] = required
				print('Chore ', random_pick, ' requires: ', required)
			
			chore_options[random_pick]['current'] = 0
			chore_data_to_sync.append({
				"key": random_pick,
				"required": chore_options[random_pick].get('required', 0),
				"current": 0,
				'max_cap': chore_options[random_pick].get('max_cap', 0)
			})
			
	chores_chosen = true
	chores_selected.emit(chosen_chores)

	_sync_chores_to_clients.rpc(chore_data_to_sync)

@rpc("reliable")
func _sync_chores_to_clients(synced_chore_data: Array):
	print("CLIENT: _sync_chores_to_clients received: ", synced_chore_data)
	
	chosen_chores.clear()
	
	for chore_data in synced_chore_data:
		var chore_key = chore_data["key"]
		chosen_chores.append(chore_key)
		
		if chore_options.has(chore_key):
			# Preserve all existing properties, update required and current
			chore_options[chore_key]['required'] = chore_data["required"]
			chore_options[chore_key]['current'] = 5
			#chore_options[chore_key]['current'] = chore_data["current"]
			chore_options[chore_key]['max_cap'] = chore_data["max_cap"]
			# Make sure max_cap exists (it should from the original dict)
			print("CLIENT: Set ", chore_key, " required: ", chore_data["required"], " max_cap: ", chore_options[chore_key].get('max_cap', 'MISSING'))
			print("CLIENT: After update - ", chore_key, " required: ", chore_options[chore_key]['required'])
	print("CLIENT: chosen_chores: ", chosen_chores)
	
	# Add a small delay to ensure all data is processed
	await get_tree().process_frame
	
	# Emit signal so chore board can update
	chores_selected.emit(chosen_chores)

func get_required_count(chore_key: String) -> int:
	var chore = chore_options[chore_key]
	print("get_required_count - chore_key: ", chore_key, " chore: ", chore)
	if chore.has('max_cap'):
		var required = chore.get('required', 0)
		print("get_required_count returning: ", required)
		return required
	return 0

func item_placed(item_type: String):
	print("=== item_placed called with: ", item_type)
	for chore_key in chosen_chores:
		var chore = chore_options[chore_key]
		print("Checking chore: ", chore_key, " item_type: ", chore.get('item_type'), " current: ", chore.get('current', 0), " required: ", get_required_count(chore_key))
		if chore.get('item_type') == item_type and chore.get('current', 0) < get_required_count(chore_key):
			chore['current'] += 1
			print("Emitting progress update for: ", chore_key, " new current: ", chore['current'])
			chore_progress_updated.emit(chore_key, chore['current'], get_required_count(chore_key))
			
			if chore['current'] >= get_required_count(chore_key):
				chore_completed.emit(chore_key)
				print('chore completed: ', chore['string'])
			break

func get_chore_info(chore_key: String) -> Dictionary:
	return chore_options.get(chore_key, {})
