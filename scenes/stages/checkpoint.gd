extends Area2D

# We will use a signal to tell the stage this specific checkpoint was hit
signal checkpoint_activated(pos: Vector2)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Emit the position of this checkpoint
		checkpoint_activated.emit(global_position)
		print("new checkpoint")
		
		# Optional: Disable collision so it doesn't trigger repeatedly
		# set_deferred("monitoring", false)
