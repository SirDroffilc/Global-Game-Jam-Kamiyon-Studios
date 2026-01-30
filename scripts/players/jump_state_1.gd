extends State

@export var idle_state: State
@export var run_state: State

func enter() -> void:
	# Call base class enter to play the "jump_light/dark" animation
	super()
	parent.velocity.y = parent.jump_velocity

func process_physics(delta: float) -> State:
	parent.velocity += parent.get_gravity() * delta
	
	var dir = Input.get_axis("p1_move_left", "p1_move_right")
	parent.velocity.x = dir * parent.speed
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()
	
	# Transition back to floor states
	if parent.is_on_floor():
		if dir != 0:
			return run_state
		return idle_state
		
	return null
