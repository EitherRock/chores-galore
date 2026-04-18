extends GrabableRigidBody
class_name Item

signal picked_up
signal placed
signal interacted(item)

enum ItemType { BOOK, DISH }

@export var item_type: String = 'BOOK'
@export var item_name: String = "Item"
@export var can_interact: bool = true
@export var interact_prompt: String = ""

func on_picked_up() -> void:
	picked_up.emit()

func on_placed() -> void:
	placed.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if item_type == 'BOOK':
		interact_prompt = 'Read'


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if not can_interact:
		return
	
	if item_type == 'BOOK':
		var ui = get_tree().get_first_node_in_group("ui_manager")
		var book_data = ui.load_book('res://scripts/managers/courting_by_the_cornfield.json')
		ui.open_book(book_data)
