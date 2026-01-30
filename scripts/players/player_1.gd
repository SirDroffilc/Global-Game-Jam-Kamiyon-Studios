class_name Player
extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -300.0

var is_light: bool = true # Start as Light

@onready var state_machine: StateMachine = $StateMachine1
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready() -> void:
	state_machine.init(self)
	update_physics_layers()
	

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_skill"):
		toggle_element_state()
	
	state_machine.process_input(event)

# --- Utility Functions ---

func toggle_element_state() -> void:	
	is_light = !is_light
	update_physics_layers()
	
	if state_machine.current_state:
		if is_light:
			play_animation(state_machine.current_state.animation_name)
		else:
			play_animation(state_machine.current_state.animation_name)

func update_physics_layers() -> void:
	# Reset layers (0 is no layers)
	collision_layer = 0
	collision_mask = 0
	
	if is_light:
		set_collision_layer_value(2, true) # Layer 2: Light Player
		set_collision_mask_value(3, true)  # Mask 3: Dark Objects (Floor)
	else:
		set_collision_layer_value(1, true) # Layer 1: Dark Player
		set_collision_mask_value(4, true)  # Mask 4: Light Objects (Floor)

func play_animation(anim_base_name: String) -> void:
	# Dynamically builds the string: e.g., "idle" + "_light"
	var suffix = "_light" if is_light else "_dark"
	animated_sprite.play(anim_base_name + suffix)
