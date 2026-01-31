extends State

# Inside death_state.gd

# Inside death_state.gd
func enter() -> void:
	parent.velocity = Vector2.ZERO
	parent.play_animation("death")
	# Defer any manual disability here too just to be safe
	parent.hitbox_shape.set_deferred("disabled", true)

@warning_ignore("unused_parameter")
func process_physics(delta: float) -> State:
	# 4. Meticulous Logic: Keep velocity at zero during the animation
	# This prevents gravity or external forces from sliding the corpse.
	parent.velocity = Vector2.ZERO
	parent.move_and_slide()
	return null

# Note: We don't transition out of this state via process_physics.
# The Level/Stage script will handle the move_to_checkpoint call.
