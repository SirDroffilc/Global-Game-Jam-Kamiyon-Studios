class_name Player
extends CharacterBody2D

# We no longer declare 'speed' or 'jump_velocity' here. 
# We fetch them directly from PlayerManager when needed.

var is_light: bool = true # Start as Light

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready() -> void:
	# Initialize the state machine with this player instance
	state_machine.init(self)
	
	# Set initial collision states
	update_physics_layers()
	
	# Meticulous Note: You can also connect to the manager's death signal here
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_death)

func _physics_process(delta: float) -> void:
	# Delegate physics processing to the current state
	state_machine.process_physics(delta)

func _input(event: InputEvent) -> void:
	# P1 Skill: Toggle between Light and Dark
	if event.is_action_pressed("skill1"):
		toggle_element_state()
	
	# Delegate other inputs (movement/jumping) to the state machine
	state_machine.process_input(event)

# --- Utility Functions ---

func toggle_element_state() -> void:	
	is_light = !is_light
	update_physics_layers()
	
	# Refresh the current animation to the correct state suffix (_light or _dark)
	if state_machine.current_state:
		play_animation(state_machine.current_state.animation_name)

func update_physics_layers() -> void:
	# Clear all bits before reassignment to prevent collision overlap
	collision_layer = 0
	collision_mask = 0
	
	if is_light:
		set_collision_layer_value(2, true) # Layer 2: Light Player
		set_collision_mask_value(3, true)  # Mask 3: Dark Objects (Floor)
		set_collision_mask_value(5, true)  # Mask 5: Neutral Objects
	else:
		set_collision_layer_value(1, true) # Layer 1: Dark Player
		set_collision_mask_value(4, true)  # Mask 4: Light Objects (Floor)
		set_collision_mask_value(5, true)  # Mask 5: Neutral Objects

func play_animation(anim_base_name: String) -> void:
	# Appends suffix based on state to match your SpriteFrames naming
	var suffix = "_light" if is_light else "_dark"
	animated_sprite.play(anim_base_name + suffix)

func _on_death() -> void:
	# Transition to death state if defined in your state machine
	if has_node("StateMachine/death"):
		state_machine.change_state($StateMachine/death)

# --- Helper Getters for States ---
# Your states (idle, run, jump) should call these to get values from the Manager

func get_speed() -> float:
	return PlayerManager.get_speed()

func get_jump_velocity() -> float:
	return PlayerManager.get_jump_velocity()
