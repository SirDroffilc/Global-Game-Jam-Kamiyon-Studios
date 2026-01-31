extends State

@export var idle_state: State
@export var jump_state: State
@export var attack_state: State
@export var shoot_state: State
@export var dash_state: State

func process_physics(delta: float) -> State:
	# 1. IMMEDIATE TRANSITION CHECKS
	if Input.is_action_just_pressed("attack"): # Left Click
		if parent.is_light:
			return shoot_state
		else:
			return attack_state

	if Input.is_action_just_pressed("jump") and parent.is_on_floor():
		return jump_state
	
	if Input.is_action_just_pressed("dash") and parent.can_dash:
			return dash_state
		
	# 2. MOVEMENT LOGIC
	parent.velocity += parent.get_gravity() * delta
	
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed() #
	
	# 3. VISUALS
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0 #
		
	# 4. PHYSICS EXECUTION
	parent.move_and_slide()
	
	# 5. POST-PHYSICS TRANSITION
	if dir == 0:
		return idle_state
		
	return null
