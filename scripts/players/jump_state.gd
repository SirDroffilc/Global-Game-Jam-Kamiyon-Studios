extends State

@export var idle_state: State
@export var run_state: State
@export var double_jump_state: State # New export for the transition

func enter() -> void:
	super()
	# Pull the initial jump velocity from the Manager
	parent.velocity.y = parent.get_jump_velocity()

func process_physics(delta: float) -> State:
	parent.velocity += parent.get_gravity() * delta
	
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()
	
	# Transition to Double Jump:
	# If the jump button is pressed again while we are NOT on the floor.
	if Input.is_action_just_pressed("jump") and not parent.is_on_floor():
		return double_jump_state
	
	# Transition back to ground states
	if parent.is_on_floor():
		if dir != 0:
			return run_state
		return idle_state
		
	return null
