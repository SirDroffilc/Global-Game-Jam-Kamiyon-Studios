extends State

@export var idle_state: State
@export var run_state: State
@export var double_jump_state: State
@export var attack_state: State
@export var shoot_state: State
@export var dash_state: State

@export var jump_cut_multiplier: float = 0.5 
@export var hold_gravity_multiplier: float = 0.3
@export var max_jump_hold_time: float = 0.3    

var jump_hold_timer: float = 0.0

func enter() -> void:
	super()
	jump_hold_timer = 0.0
	# Meticulous Note: Clear the buffer once we successfully jump
	parent.jump_buffer_timer = 0.0 
	parent.velocity.y = parent.get_jump_velocity()

func process_physics(delta: float) -> State:
	jump_hold_timer += delta
	var current_gravity = parent.get_gravity()
	
	# VARIABLE JUMP HEIGHT LOGIC
	if Input.is_action_pressed("jump") and jump_hold_timer < max_jump_hold_time and parent.velocity.y < 0:
		parent.velocity += current_gravity * hold_gravity_multiplier * delta
	else:
		parent.velocity += current_gravity * delta

	# JUMP CUT (Short Hop)
	if Input.is_action_just_released("jump") and parent.velocity.y < 0:
		parent.velocity.y *= jump_cut_multiplier
		jump_hold_timer = max_jump_hold_time 

	# MOVEMENT
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()

	# DASH TRANSITION
	if Input.is_action_just_pressed("dash") and parent.can_dash:
		return dash_state

	# DOUBLE JUMP CHECK
	# We use raw input here because buffering a double-jump feels "laggy"
	if Input.is_action_just_pressed("jump") and not parent.is_on_floor():
		return double_jump_state
	
	# LANDING & BUFFERED JUMP CHECK
	if parent.is_on_floor():
		# If we land and the buffer is still active, JUMP AGAIN IMMEDIATELY
		if parent.jump_buffer_timer > 0:
			return self # Re-enters JumpState
		
		return run_state if dir != 0 else idle_state
		
	return null
