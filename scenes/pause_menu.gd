extends Control

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide() 

func _on_settings_pressed() -> void:
	# Usually opens a sub-menu or a popup
	pass 

func _on_quit_pressed() -> void:
	# IMPORTANT: Always unpause before changing scenes, 
	# otherwise the Main Menu might start frozen!
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
