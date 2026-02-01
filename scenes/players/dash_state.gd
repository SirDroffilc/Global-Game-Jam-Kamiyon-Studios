extends State
class_name DashState

@export_group("Dash Physics")
@export var dash_speed: float = 900.0 
@export var dash_duration: float = 0.10 
var dash_timer: float = 0.0

@export_group("Visuals")
@export var ghost_interval: float = 0.05 
var ghost_timer: float = 0.0

@export_group("Transitions")
@export var idle_state: State
@export var run_state: State
@export var jump_state: State 

func enter() -> void:
	super()
	if parent:
		# 1. Consume ground charge and START time cooldown
		parent.dash_available = false 
		parent.dash_cooldown_timer = parent.dash_cooldown 
		
		# 2. Reset local dash timers
		dash_timer = 0.0
		ghost_timer = 0.0
		
		# 3. Apply physics and visuals
		var dir = -1 if parent.animated_sprite.flip_h else 1
		parent.velocity.x = dir * dash_speed
		parent.velocity.y = 0 
		
		parent.play_animation("dash")
		parent.animated_sprite.modulate = Color(15, 15, 15, 1) 
		parent.spawn_ghost() 
		AudioManager.play_omni("PlayerDash")

func process_physics(delta: float) -> State:
	dash_timer += delta
	ghost_timer += delta
	
	parent.velocity.y = 0 
	
	if ghost_timer >= ghost_interval:
		parent.spawn_ghost()
		ghost_timer = 0
	
	parent.move_and_slide()
	
	if dash_timer >= dash_duration:
		return _choose_next_state()
	
	return null

func exit() -> void:
	parent.animated_sprite.modulate = Color.WHITE 
	parent.velocity.x = 0 

func _choose_next_state() -> State:
	# Recovery logic: ensure gravity is enabled if ending in air
	if not parent.is_on_floor():
		return jump_state 
		
	var dir = Input.get_axis("move_left", "move_right")
	return run_state if dir != 0 else idle_state
