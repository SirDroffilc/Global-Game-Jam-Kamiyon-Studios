extends TextureRect

@export var bounce_height: float = 20.0
@export var bounce_speed: float = 0.5
@export var fade_duration: float = 1.0

func _ready() -> void:
	# Fade In
	modulate.a = 0
	create_tween().tween_property(self, "modulate:a", 1.0, fade_duration)
	
	# Looping Bounce
	var start_y = position.y
	var bounce = create_tween().set_loops()
	bounce.tween_property(self, "position:y", start_y + bounce_height, bounce_speed).set_trans(Tween.TRANS_SINE)
	bounce.tween_property(self, "position:y", start_y, bounce_speed).set_trans(Tween.TRANS_SINE)
