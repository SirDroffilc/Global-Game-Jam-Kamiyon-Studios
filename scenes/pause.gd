extends Control

# Inside pause_menu.gd
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Use 'set_input_as_handled' so the Level script doesn't also see this press
		get_viewport().set_input_as_handled()
		resume_game()

func _on_resume_pressed() -> void:
	resume_game()

func resume_game() -> void:
	get_tree().paused = false
	# Instead of hide(), we queue_free() because the Level script 
	# instantiates a new one every time Esc is pressed.
	queue_free() 

func _on_settings_pressed() -> void:
	# Usually opens a sub-menu or a popup
	pass 

func _on_quit_pressed() -> void:
	# IMPORTANT: Always unpause before changing scenes!
	resume_game()
	queue_free()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
