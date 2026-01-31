extends Camera2D

@export var player: CharacterBody2D
@export var lead_distance: float = 200.0
@export var smooth_speed: float = 5.0

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Determine where the camera WANTs to be
	var target_pos = player.global_position
	
	# Add a 'Lead' based on where the player is looking/moving
	if player.velocity.x > 0:
		target_pos.x += lead_distance
	elif player.velocity.x < 0:
		target_pos.x -= lead_distance

	# Meticulously interpolate the camera position for "delayed" smoothness
	# lerp = Linear Interpolation (Start, End, Weight)
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
