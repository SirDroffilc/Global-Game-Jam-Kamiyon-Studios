extends State

@export var idle_state: State
@export var run_state: State
@export	var jump_state: State

func enter() -> void:
	parent.play_animation("shoot")
	parent.shoot_arrow()
	print(">>> COMBAT: Shoot")
	# REMOVED: Signal connections are gone. We handle this in physics now.

func process_physics(delta: float) -> State:
	# 1. Physics Logic
	parent.velocity += parent.get_gravity() * delta
	var dir = Input.get_axis("move_left", "move_right")
	parent.velocity.x = (dir * parent.get_speed()) + parent.recoil_physics_velocity.x
	
	if Input.is_action_just_pressed("jump") and parent.is_on_floor():
		return jump_state
	
	if dir != 0:
		parent.animated_sprite.flip_h = dir < 0
		
	parent.move_and_slide()

	var current_anim = parent.animated_sprite.animation
	
	if not parent.animated_sprite.is_playing():
		# Fallback safety: if animation stopped or changed unexpectedly
		return _get_exit_state(dir)
	
	var frames = parent.animated_sprite.sprite_frames
	var frame_count = frames.get_frame_count(current_anim)
	var current_frame = parent.animated_sprite.frame
	
	if current_frame >= frame_count - 1:
		return _get_exit_state(dir)

	return null

func _get_exit_state(dir: float) -> State:
	if dir != 0:
		return run_state
	return idle_state

func exit() -> void:
	# Keep this clean, but we no longer need signal disconnects
	pass
