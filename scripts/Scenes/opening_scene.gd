extends Control

func _ready():
	# 1. Connect the signal: "When any animation finishes, run the _on_animation_finished function"
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	
	AudioManager.play_music("CutSceneMusic")
	
	# 2. Start the cutscene
	$AnimationPlayer.play("intro_sequence")

# This function runs automatically as soon as the animation hits the end
func _on_animation_finished(anim_name: StringName):
	if anim_name == "intro_sequence":
		_start_game()

func _start_game():
	AudioManager.stop_music(1.0)
	get_tree().change_scene_to_file("res://scenes/stages/level_2.tscn")

# Keep the skip functionality just in case the player is impatient!
func _input(event):
	if event.is_action_pressed("ui_accept"): 
		AudioManager.play_omni("StartGame")
		_start_game()
