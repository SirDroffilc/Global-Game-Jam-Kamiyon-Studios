extends State

@export var run_state: State
@export var jump_state: State
@export var attack_state: State

func process_physics(delta: float) -> State:
	# 1. IMMEDIATE TRANSITION CHECKS
	# We check for these before processing physics to ensure high responsiveness.
	if Input.is_action_just_pressed("attack"):
		return attack_state
	
	if Input.is_action_just_pressed("jump") and parent.is_on_floor():
		return jump_state
	
	# Check if the player has started moving
	var dir = Input.get_axis("move_left", "move_right")
	if dir != 0:
		return run_state

	# 2. PHYSICS PROCESSING
	# Apply gravity even while idle to keep the player snapped to the floor.
	parent.velocity += parent.get_gravity() * delta
	
	# In Idle, we typically want the horizontal velocity to stay at 0.
	parent.velocity.x = move_toward(parent.velocity.x, 0, 20)
	
	parent.move_and_slide()
		
	return null
