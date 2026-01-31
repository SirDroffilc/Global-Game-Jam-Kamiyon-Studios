extends State

@export var idle_state: State
@export var run_state: State

func enter() -> void:
	parent.play_animation("shoot")
	parent.shoot_arrow() #
	print("Shoot")
	
	if not parent.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		parent.animated_sprite.animation_finished.connect(_on_animation_finished)

func process_physics(delta: float) -> State:
	# 1. Gravity
	parent.velocity += parent.get_gravity() * delta
	
	# 2. Movement + Physical Recoil
	var dir = Input.get_axis("move_left", "move_right")
	# Meticulously add the recoil_physics_velocity to the movement
	parent.velocity.x = (dir * parent.get_speed()) + parent.recoil_physics_velocity.x
	
	# 3. Handle Jump, Flipping, etc...
	if Input.is_action_just_pressed("jump") and parent.is_on_floor():
		parent.velocity.y = parent.get_jump_velocity()
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()
	return null

func _on_animation_finished() -> void:
	# Check where to go back based on movement
	if Input.get_axis("move_left", "move_right") != 0:
		parent.state_machine.change_state(run_state)
	else:
		parent.state_machine.change_state(idle_state)
