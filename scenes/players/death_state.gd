extends State

func enter() -> void:
	# 1. Stop all current momentum
	parent.velocity = Vector2.ZERO
	
	# 2. Play the death animation
	# This uses your play_animation logic which handles light/dark suffixes
	parent.play_animation("death")
	
	# 3. Disable the hitbox just in case it was active
	parent.hitbox_shape.disabled = true
	
	print(">>> PLAYER STATE: Entered Death State")

@warning_ignore("unused_parameter")
func process_physics(delta: float) -> State:
	# 4. Meticulous Logic: Keep velocity at zero during the animation
	# This prevents gravity or external forces from sliding the corpse.
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	return null

# Note: We don't transition out of this state via process_physics.
# The Level/Stage script will handle the move_to_checkpoint call.
