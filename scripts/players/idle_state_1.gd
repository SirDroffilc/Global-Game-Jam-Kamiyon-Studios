extends State

@export var run_state: State
@export var jump_state: State

func process_physics(delta: float) -> State:
	parent.velocity += parent.get_gravity() * delta
	parent.move_and_slide()
	
	if Input.is_action_just_pressed("p1_jump") and parent.is_on_floor():
		return jump_state
	
	if Input.get_axis("p1_move_left", "p1_move_right") != 0:
		return run_state
		
	return null
