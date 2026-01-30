extends State

@export var idle_state: State
@export var jump_state: State

func process_physics(delta: float) -> State:
	parent.velocity += parent.get_gravity() * delta
	
	var dir = Input.get_axis("p1_move_left", "p1_move_right")
	parent.velocity.x = dir * parent.speed
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()
	
	if Input.is_action_just_pressed("p1_jump") and parent.is_on_floor():
		return jump_state
	
	if dir == 0:
		return idle_state
		
	return null
