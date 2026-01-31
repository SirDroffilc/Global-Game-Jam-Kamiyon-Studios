extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
const MAIN_SCENE_PATH: String = "res://scenes/MainScene.tscn"

func _ready() -> void:
	# Connect the signal from your AnimationPlayer child
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_anim_name: String) -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
