extends State
class_name FallState

@export var idle_state: State
@export var run_state: State
@export var jump_state: State
@export var double_jump_state: State
@export var attack_state: State
@export var shoot_state: State
@export var dash_state: State

func enter() -> void:
	super()
	# We don't apply any velocity here. 
	# We just play the "fall" or "jump" animation.
	parent.play_animation("jump") 

func process_physics(delta: float) -> State:
	# 1. Apply Normal Gravity
	parent.velocity += parent.get_gravity() * delta

	# 2. Air Combat Check
	if Input.is_action_just_pressed("attack"):
		return shoot_state if (parent.is_light and parent.ranged_cooldown_timer <= 0) else attack_state

	# 3. Horizontal Movement
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	
	parent.move_and_slide()

	# 4. Gated Dash Transition
	if Input.is_action_just_pressed("dash"):
		if parent.dash_available and parent.dash_cooldown_timer <= 0:
			return dash_state

	# 5. Gated Double Jump Check
	if Input.is_action_just_pressed("jump"):
		if parent.can_double_jump:
			return double_jump_state
	
	# 6. Landing Logic
	if parent.is_on_floor():
		return run_state if dir != 0 else idle_state
		
	return null
