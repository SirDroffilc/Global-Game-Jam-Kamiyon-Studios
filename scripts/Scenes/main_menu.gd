extends Control

@onready var start_button = $VBoxContainer/Start
@onready var anim_player = $AnimationPlayer
@onready var transition_bg = $TransitionLayer/ColorRect

# Configure the hover settings
var hover_scale = Vector2(1.1, 1.1)
var normal_scale = Vector2(1.0, 1.0)
var duration = 0.1 # Seconds

func _ready() -> void:
	# Loop through all buttons in your VBoxContainer to set them up
	for button in $VBoxContainer.get_children():
		if button is Button:
			# 1. Set the pivot to the center so it scales outward
			button.pivot_offset = button.size / 2
			
			# 2. Connect the hover signals via code
			button.mouse_entered.connect(_on_button_hovered.bind(button))
			button.mouse_exited.connect(_on_button_unhovered.bind(button))

func _on_button_hovered(button: Button) -> void:
	# Create a smooth pop-out animation
	var tween = create_tween()
	tween.tween_property(button, "scale", hover_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_button_unhovered(button: Button) -> void:
	# Smoothly return to normal size
	var tween = create_tween()
	tween.tween_property(button, "scale", normal_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_start_pressed() -> void:
	start_button.disabled = true
	# Optional: Reset scale on click so it doesn't stay big during the fade
	start_button.scale = normal_scale 
	
	anim_player.play("fade_to_black")
	await anim_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/opening_scene.tscn")
	
func _on_settings_pressed() -> void:
	pass

func _on_credits_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
