extends State

@export var idle_state: State
@export var run_state: State

# The multiplier to make this jump weaker (e.g., 0.7 = 70% strength)
@export var jump_multiplier: float = 0.7 

func enter() -> void:
	# We use a unique animation name like "double_jump" or reuse "jump"
	# If using suffix logic, it will play "jump_light" or "jump_dark"
	parent.play_animation("jump") 
	
	# Apply the weaker jump velocity
	parent.velocity.y = parent.get_jump_velocity() * jump_multiplier

func process_physics(delta: float) -> State:
	parent.velocity += parent.get_gravity() * delta
	
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()
	
	# Transition back to ground states
	# Note: We don't check for another jump here, so the player can't triple jump.
	if parent.is_on_floor():
		if dir != 0:
			return run_state
		return idle_state
		
	return null
