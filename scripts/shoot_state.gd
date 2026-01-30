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
	# 1. Continue Gravity
	parent.velocity += parent.get_gravity() * delta
	
	# 2. Allow horizontal movement while shooting
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = dir * parent.get_speed()
	
	# 3. Handle Sprite Flipping based on movement (or mouse)
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
