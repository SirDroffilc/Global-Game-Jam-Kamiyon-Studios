class_name StateMachine
extends Node

@export var initial_state: State
var current_state: State

func init(player: Player) -> void:
	for child in get_children():
		child.parent = player
	change_state(initial_state)

# This is called by Player's _physics_process
func process_physics(delta: float) -> void:
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)

# This is called by Player's _input
func process_input(event: InputEvent) -> void:
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)

func change_state(new_state: State) -> void:
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
