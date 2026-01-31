extends State

@export var idle_state: State
@export var attack_speed_multiplier: float = 0.4 # Move at 40% speed while attacking
var attack_input_received: bool = false

func enter() -> void:
	# 1. Increment combo (1 -> 2 -> 3 -> 1)
	parent.combo_count = (parent.combo_count % 3) + 1
	parent.can_combo = false
	attack_input_received = false
	
	print(">>> ATTACK STATE: Starting Combo Step ", parent.combo_count)
	
	parent.play_animation("attack")
	
	if not parent.animation_player.animation_finished.is_connected(_on_animation_finished):
		parent.animation_player.animation_finished.connect(_on_animation_finished)

func process_input(event: InputEvent) -> State:
	if event.is_action_pressed("attack"):
		attack_input_received = true
	return null

func process_physics(delta: float) -> State:
	# 1. Transition to next combo step if buffered
	if attack_input_received and parent.can_combo:
		return self 
		
	# 2. Allow lateral movement while attacking
	var direction = Input.get_axis("move_left", "move_right")
	var target_speed = direction * parent.get_speed() * attack_speed_multiplier
	
	# Apply a slightly higher friction so the movement feels heavy
	parent.velocity.x = move_toward(parent.velocity.x, target_speed, 10.0)
	
	# Apply standard physics/gravity
	parent.velocity += parent.get_gravity() * delta
	parent.move_and_slide()
	
	return null

func _on_animation_finished(_anim_name: String) -> void:
	parent.combo_count = 0
	parent.state_machine.change_state(idle_state)

func exit() -> void:
	parent.hitbox_shape.disabled = true
	# Safety reset
	if parent.animation_player.animation_finished.is_connected(_on_animation_finished):
		parent.animation_player.animation_finished.disconnect(_on_animation_finished)
