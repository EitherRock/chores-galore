extends Node3D

@onready var chore_board = %ChoreBoard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$LivingRoom/BookShelf.item_placed.connect(_on_item_placed)
	#ChoreManager.chores_selected.connect(_on_selected)
	

#func _on_selected():
	#print('chores have been seelcted')

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_item_placed() -> void:
	print('Item has been placed!')
