extends Control

func _ready():
	# 1. Connect the signal: "When any animation finishes, run the _on_animation_finished function"
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	
	# 2. Start the cutscene
	$AnimationPlayer.play("intro_sequence")

# This function runs automatically as soon as the animation hits the end
func _on_animation_finished(anim_name: StringName):
	if anim_name == "intro_sequence":
		_start_game()

func _start_game():
	get_tree().change_scene_to_file("res://scenes/stages/stage_1.tscn")

# Keep the skip functionality just in case the player is impatient!
func _input(event):
	if event.is_action_pressed("ui_accept"): 
		_start_game()
