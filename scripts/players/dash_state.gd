extends State

@export var idle_state: State
@export var run_state: State
@export var jump_state: State

@export var dash_speed: float = 350.0  # Slightly faster than normal run
@export var dash_duration: float = 0.2
var dash_timer: float = 0.0

func enter() -> void:
	super()
	parent.can_dash = false
	dash_timer = dash_duration
	AudioManager.play_omni("EnemyTackle") # Requested sound
	
	parent.play_animation("dash") 
	# Or if no dash anim exists, keep running but with trail effect (later)

func process_physics(delta: float) -> State:
	dash_timer -= delta
	
	if dash_timer <= 0:
		if not parent.is_on_floor():
			return jump_state # Fall state effectively
		return idle_state if Input.get_axis("move_left", "move_right") == 0 else run_state

	# Maintain dash direction or updated input
	var dir = Input.get_axis("move_left", "move_right")
	# If no input, dash forward (facing direction)
	if dir == 0:
		dir = -1 if parent.animated_sprite.flip_h else 1
		
	parent.velocity.y = 0 # Gravity defiance during dash? Usually yes for air dash
	parent.velocity.x = dir * dash_speed
	
	parent.move_and_slide()
	
	return null
