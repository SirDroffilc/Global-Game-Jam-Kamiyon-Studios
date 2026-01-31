extends State

@export var idle_state: State
@export var run_state: State
@export var attack_state: State # Added for Dark Melee
@export var shoot_state: State  # Added for Light Ranged
@export var dash_state: State

@export var jump_multiplier: float = 0.7 

func enter() -> void:
	parent.play_animation("jump") 
	parent.velocity.y = parent.get_jump_velocity() * jump_multiplier #

func process_physics(delta: float) -> State:
	# 1. AIR ATTACK CHECK
	if Input.is_action_just_pressed("dash") and parent.can_dash:
		return dash_state
		
	if Input.is_action_just_pressed("attack"):
		if parent.is_light:
			return shoot_state
		else:
			return attack_state

	# 2. PHYSICS
	parent.velocity += parent.get_gravity() * delta
	
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()
	if Input.is_action_just_pressed("skill3"):
		return dash_state
	# 3. TRANSITIONS
	if parent.is_on_floor():
		if dir != 0:
			return run_state
		return idle_state
		
	return null
