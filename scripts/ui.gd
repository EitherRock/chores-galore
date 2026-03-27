extends Control

signal server_started

func _on_server_pressed() -> void:
	NetworkHandler.start_server()
	server_started.emit()
	hide()


func _on_client_pressed() -> void:
	NetworkHandler.start_client()
	hide()
