extends State

@export var idle_state: State
@export var jump_state: State
@export var attack_state: State

func process_physics(delta: float) -> State:
	# 1. IMMEDIATE TRANSITION CHECKS
	if Input.is_action_just_pressed("attack"):
		return attack_state

	if Input.is_action_just_pressed("jump") and parent.is_on_floor():
		return jump_state
	
	# 2. MOVEMENT LOGIC
	# Apply gravity for consistent physics.
	parent.velocity += parent.get_gravity() * delta
	
	var dir = Input.get_axis("move_left", "move_right")
	
	# Access speed through the Player script's helper for centralized data management.
	parent.velocity.x = dir * parent.get_speed()
	
	# 3. VISUALS
	# Flip the AnimatedSprite based on direction. 
	# This also flips the child Hitbox automatically.
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	# 4. PHYSICS EXECUTION
	parent.move_and_slide()
	
	# 5. POST-PHYSICS TRANSITION
	# If the player stops providing input, return to Idle.
	if dir == 0:
		return idle_state
		
	return null
