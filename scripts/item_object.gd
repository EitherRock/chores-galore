extends GrabableRigidBody
class_name Item

signal picked_up
signal placed

@export var item_type: String = "book"
@export var item_name: String = "Item"

func on_picked_up() -> void:
	picked_up.emit()

func on_placed() -> void:
	placed.emit()
