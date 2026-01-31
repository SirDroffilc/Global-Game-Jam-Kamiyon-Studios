class_name State
extends Node

@export var animation_name: String
var parent: Player  

func enter() -> void:
	parent.play_animation(animation_name)

func exit() -> void:
	pass

func process_input(event: InputEvent) -> State:
	return null

func process_physics(delta: float) -> State:
	return null
