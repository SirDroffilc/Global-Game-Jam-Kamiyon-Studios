extends State

@export var idle_state: State

func enter() -> void:
	# 1. Start the animation via the player helper
	parent.play_animation("attack") 
	
	# 2. Use the AnimationPlayer signal for completion
	if not parent.animation_player.animation_finished.is_connected(_on_animation_finished):
		parent.animation_player.animation_finished.connect(_on_animation_finished)

func exit() -> void:
	# Safety reset: Ensure the hitbox is off if hit by an enemy mid-attack
	parent.hitbox_shape.disabled = true
	
	if parent.animation_player.animation_finished.is_connected(_on_animation_finished):
		parent.animation_player.animation_finished.disconnect(_on_animation_finished)

func process_physics(delta: float) -> State:
	parent.velocity += parent.get_gravity() * delta
	# Add 'weight' to the attack by slowing the player down
	parent.velocity.x = move_toward(parent.velocity.x, 0, 15)
	parent.move_and_slide()
	return null

func _on_animation_finished(_anim_name: String) -> void:
	# Switch back to Idle once the timeline is done
	parent.state_machine.change_state(idle_state)
