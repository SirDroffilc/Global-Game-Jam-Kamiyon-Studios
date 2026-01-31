extends State

@export var run_state: State
@export var jump_state: State
@export var attack_state: State
@export var shoot_state: State
@export var dash_state: State

func process_physics(delta: float) -> State:
	if Input.is_action_just_pressed("dash") and parent.can_dash:
		if dash_state != null:
			return dash_state

	if Input.is_action_just_pressed("attack"): # Left Click Input
		if parent.is_light:
			# Transitions to Ranged mode (Bow and Arrow)
			return shoot_state
		else:
			# Transitions to Melee mode (Sword/Dark element)
			return attack_state
	
	# Handle vertical movement
	if Input.is_action_just_pressed("jump") and parent.is_on_floor():
		return jump_state
	
	# Check for horizontal movement to transition to RunState
	var dir = Input.get_axis("move_left", "move_right")
	if dir != 0:
		return run_state
	if Input.is_action_just_pressed("dash"):
		return dash_state
	# 2. PHYSICS PROCESSING
	# Maintain gravity so the player remains grounded during the idle state.
	parent.velocity += parent.get_gravity() * delta
	
	# Gradually bring the player to a halt if they have residual momentum.
	parent.velocity.x = move_toward(parent.velocity.x, 0, 20)
	
	# Apply final physics calculations.
	parent.move_and_slide()
		
	return null
