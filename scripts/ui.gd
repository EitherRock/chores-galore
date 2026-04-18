extends Control

signal server_started

@onready var book_ui = $BookUI

var current_ui_open = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_server_pressed() -> void:
	NetworkHandler.start_server()
	server_started.emit()
	hide()


func _on_client_pressed() -> void:
	NetworkHandler.start_client()
	hide()


func open_book(data: Dictionary):
	if current_ui_open:
		return
	
	current_ui_open = true
	book_ui.show_text(data)
	get_tree().paused = true

func close_book():
	book_ui.visible = false
	current_ui_open = false
	get_tree().paused = false
	

func load_book(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	
	var data = JSON.parse_string(content)
	return data

func _input(event: InputEvent) -> void:
	if current_ui_open and event.is_action_pressed('close'):
		close_book()
		
	if current_ui_open and event.is_action_pressed('turn page'):
		book_ui.next_page()
	
	if current_ui_open and event.is_action_pressed('turn page back'):
		book_ui.prev_page()
