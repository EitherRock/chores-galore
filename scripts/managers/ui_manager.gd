#extends Node
#class_name UIManager
#
#@onready var book_ui = $BookUI
#@onready var prompt_ui = $PromptUI
#
#var current_ui_open = false
#
#func open_book(data):
	#if current_ui_open:
		#return
	#
	#current_ui_open = true
	#book_ui.show_text(data)
	#get_tree().paused = true
#
#func close_book():
	#book_ui.hide()
	#current_ui_open = false
	#get_tree().paused = false
