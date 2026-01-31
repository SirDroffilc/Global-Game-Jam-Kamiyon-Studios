extends State
class_name DashState

@export var dash_speed: float = 900.0 
@export var dashing = false
@export var dash_duration: float = 0.075 
var dash_timer: float = 0.0

@export var idle_state: State
@export var run_state: State
@export var jump_state: State

func enter() -> void:
	super()
	parent.can_dash = false 
	
	dash_timer = 0.0
	var dir = -1 if parent.animated_sprite.flip_h else 1
	parent.velocity.x = dir * dash_speed
	parent.velocity.y = 0 
	parent.play_animation("dash")
	
func process_physics(delta: float) -> State:
	dash_timer += delta
	parent.velocity.y = 0 
	parent.move_and_slide()
	
	if dash_timer >= dash_duration:
		return _choose_next_state()
	return null

func _choose_next_state() -> State:
	# When the dash ends, if we are in the air, return to jump_state
	# This allows the player to fall or use their double-jump
	if parent.is_on_floor():
		var dir = Input.get_axis("move_left", "move_right")
		return run_state if dir != 0 else idle_state
	
	# Returning to JumpState refreshes the ability to use air logic
	return run_state
	
func exit() -> void:
	# This prevents the character from 'sliding' after the dash ends
	# Set to 0 for an instant stop, or a lower value for a 'drift' feel.
	parent.velocity.x = 0
