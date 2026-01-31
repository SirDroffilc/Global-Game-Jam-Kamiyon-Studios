extends State
class_name DashState

@export_group("Dash Physics")
@export var dash_speed: float = 900.0 
@export var dash_duration: float = 0.10 # Increased slightly for better visual trail

@export_group("Visuals")
@export var ghost_interval: float = 0.10 # How fast ghosts spawn
var ghost_timer: float = 0.0

@export_group("Transitions")
@export var idle_state: State
@export var run_state: State
@export var jump_state: State

var dash_timer: float = 0.0

func enter() -> void:
	super()
	# 1. Initialize Timers
	dash_timer = 0.0
	ghost_timer = 0.0
	
	# 2. Start Cooldown on the Player
	parent.dash_cooldown_timer = parent.dash_cooldown
	
	# 3. Apply Velocity
	var dir = -1 if parent.animated_sprite.flip_h else 1
	parent.velocity.x = dir * dash_speed
	parent.velocity.y = 0 
	
	# 4. Apply Dash Visuals
	parent.play_animation("dash")
	parent.animated_sprite.modulate = Color(15, 15, 15, 1) # Turn player pure white
	parent.spawn_ghost() # Initial ghost
	AudioManager.play_omni("PlayerDash")

func process_physics(delta: float) -> State:
	dash_timer += delta
	ghost_timer += delta
	
	# Maintain dash height
	parent.velocity.y = 0 
	
	# Spawn Afterimages
	if ghost_timer >= ghost_interval:
		parent.spawn_ghost()
		ghost_timer = 0
	
	parent.move_and_slide()
	
	if dash_timer >= dash_duration:
		return _choose_next_state()
	
	return null

func exit() -> void:
	# Meticulously clean up the player's appearance
	parent.animated_sprite.modulate = Color.WHITE
	parent.velocity.x = 0

func _choose_next_state() -> State:
	if not parent.is_on_floor():
		return jump_state
		
	var dir = Input.get_axis("move_left", "move_right")
	return run_state if dir != 0 else idle_state
