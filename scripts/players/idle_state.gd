extends State

@export var run_state: State
@export var jump_state: State

func process_physics(delta: float) -> State:
	# 1. Apply Gravity: Using the native Vector2 gravity from CharacterBody2D.
	parent.velocity += parent.get_gravity() * delta
	
	# 2. Movement: Execute the slide logic. In Idle, velocity.x is usually 0.
	parent.move_and_slide()
	
	# 3. Transition to Jump: Check for the "jump" input.
	if Input.is_action_just_pressed("jump") and parent.is_on_floor():
		return jump_state
	
	# 4. Transition to Run: Check for horizontal movement input.
	if Input.get_axis("move_left", "move_right") != 0:
		return run_state
		
	return null
