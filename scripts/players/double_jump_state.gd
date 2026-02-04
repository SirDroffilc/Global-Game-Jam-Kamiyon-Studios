extends State

@export var idle_state: State
@export var run_state: State
@export var attack_state: State
@export var shoot_state: State
@export var dash_state: State

@export var jump_multiplier: float = 0.7 

func enter() -> void:
	# Consume the charge immediately so it cannot be used again in the same air-time
	parent.can_double_jump = false
	parent.play_animation("jump") 
	AudioManager.play_omni("PlayerJump")
	parent.velocity.y = parent.get_jump_velocity() * jump_multiplier

func process_physics(delta: float) -> State:
	# 1. Gated Dash Transition
	if Input.is_action_just_pressed("dash"):
		if parent.dash_available and parent.dash_cooldown_timer <= 0:
			return dash_state
		
	# 2. Air Attack Check
	if Input.is_action_just_pressed("attack"): 
		if parent.is_light:
			if parent.ranged_cooldown_timer <= 0:
				return shoot_state
			else:
				return null # Ignore the input if cooling down
		else:
			return attack_state

	# 3. Physics & Horizontal Movement
	parent.velocity += parent.get_gravity() * delta
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	
	parent.move_and_slide()

	# 4. Transitions
	if parent.is_on_floor():
		return run_state if dir != 0 else idle_state
		
	return null
