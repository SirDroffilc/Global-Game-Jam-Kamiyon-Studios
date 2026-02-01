extends Area2D

# --- Animation Settings ---
@export var bounce_height: float = 10.0
@export var bounce_duration: float = 1.0

func _ready() -> void:
	_start_bounce_tween()

func _start_bounce_tween() -> void:
	# Create a tween and set it to loop indefinitely
	var tween = create_tween().set_loops().set_parallel(false)
	
	# Move Up
	tween.tween_property(self, "position:y", position.y - bounce_height, bounce_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# Move Down (Back to start)
	tween.tween_property(self, "position:y", position.y, bounce_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

# --- Existing Logic ---

func _on_body_entered(body: Node2D) -> void:
	# Ensure only the player triggers the collection
	if body.is_in_group("Player"):
		PlayerManager.shards_count += 1
		PlayerManager.emit_signal("shards_count_changed")
		print(PlayerManager.shards_count, " shards")
		
		# Optional: Play a sound or spawn particles here before freeing
		queue_free()
