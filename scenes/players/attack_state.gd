extends State

@export var idle_state: State

func enter() -> void:
	super() # Plays the "attack_light/dark" animation
	
	# Enable the hitbox shape now that the swing has started
	parent.hitbox_shape.disabled = false
	
	if not parent.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		parent.animated_sprite.animation_finished.connect(_on_animation_finished)

func exit() -> void:
	# Disable the hitbox as soon as the state exits or is interrupted
	parent.hitbox_shape.disabled = true
	if parent.animated_sprite.animation_finished.is_connected(_on_animation_finished):
		parent.animated_sprite.animation_finished.disconnect(_on_animation_finished)

func process_physics(delta: float) -> State:
	parent.velocity += parent.get_gravity() * delta
	# Keep the player somewhat stationary during the attack swing
	parent.velocity.x = move_toward(parent.velocity.x, 0, 15)
	parent.move_and_slide()
	return null

func _on_animation_finished() -> void:
	# Return to idle once the attack animation completes
	parent.state_machine.change_state(idle_state)
