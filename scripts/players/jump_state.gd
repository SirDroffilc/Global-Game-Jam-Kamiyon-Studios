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
	AudioManager.play_omni("PlayerJump")

func process_physics(delta: float) -> State:
	jump_hold_timer += delta
	var current_gravity = parent.get_gravity()
	
	# 1. Air Attack Check
	if Input.is_action_just_pressed("attack"):
		return shoot_state if (parent.is_light and parent.ranged_cooldown_timer <= 0) else attack_state

	# 2. Physics & Jump Height
	if Input.is_action_pressed("jump") and jump_hold_timer < max_jump_hold_time and parent.velocity.y < 0:
		parent.velocity += current_gravity * hold_gravity_multiplier * delta
	else:
		parent.velocity += current_gravity * delta

	if Input.is_action_just_released("jump") and parent.velocity.y < 0:
		parent.velocity.y *= jump_cut_multiplier
		jump_hold_timer = max_jump_hold_time 

	# 3. Movement
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	parent.move_and_slide()

	# 4. Gated Dash Transition
	if Input.is_action_just_pressed("dash"):
		if parent.dash_available and parent.dash_cooldown_timer <= 0:
			return dash_state

	# 5. Gated Double Jump Check
	if Input.is_action_just_pressed("jump") and not parent.is_on_floor():
		if parent.can_double_jump: # Check the charge
			return double_jump_state
	
	# 6. Landing
	if parent.is_on_floor():
		return run_state if dir != 0 else idle_state
		
	return null
