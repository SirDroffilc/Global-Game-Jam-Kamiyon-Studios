extends Sprite2D

func _ready() -> void:
	# Create a tween to handle the fading effect
	var tween = get_tree().create_tween()
	
	# Transition the self_modulate alpha to 0 over 0.4 seconds
	tween.tween_property(self, "self_modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Automatically delete the ghost when the fade is done
	tween.finished.connect(queue_free)

func set_property(p_position: Vector2, p_scale: Vector2, p_texture: Texture2D, p_h_flip: bool, p_v_frames: int, p_h_frames: int, p_frame: int) -> void:
	# Copy the exact visual state of the player at this moment
	position = p_position
	scale = p_scale
	texture = p_texture
	flip_h = p_h_flip
	vframes = p_v_frames
	hframes = p_h_frames
	frame = p_frame
