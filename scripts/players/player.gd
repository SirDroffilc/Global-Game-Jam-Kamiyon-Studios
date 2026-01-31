class_name Player
extends CharacterBody2D

# --- Signals ---
signal element_toggled(is_light: bool) # The HUD will listen to this

var is_light: bool = true

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox: Area2D = $AnimatedSprite/MeleeWeaponHitbox 
@onready var hitbox_shape: CollisionShape2D = $AnimatedSprite/MeleeWeaponHitbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var arrow_start_position: Marker2D = $AnimatedSprite/ArrowStartPosition

# --- Camera Shake ---
@onready var camera: Camera2D = get_viewport().get_camera_2d() 
@export var shake_decay: float = 5.0
@export var max_shake_offset: Vector2 = Vector2(250, 250) 
var shake_trauma: float = 0.0

@export var arrow_scene: PackedScene = preload("res://scenes/players/light_arrow.tscn")

# --- Combat & Movement ---
var combo_count: int = 0
var can_combo: bool = false 

@export var jump_buffer_time: float = 0.15 
var jump_buffer_timer: float = 0.0
var can_dash: bool = true 

func _ready() -> void:
	state_machine.init(self)
	update_physics_layers()
	hitbox_shape.set_deferred("disabled", true)
	PlayerManager.reset_health()
	
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_death)

func _process(delta: float) -> void:
	if shake_trauma > 0:
		shake_trauma = max(shake_trauma - shake_decay * delta, 0)
		_execute_shake()
	else:
		if camera and camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if is_on_floor():
		can_dash = true
	
	handle_flipping()
	state_machine.process_physics(delta)

# --- Input Handling ---
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("skill1"):
		toggle_element_state()
	
	state_machine.process_input(event)

# --- Flipping & Positioning ---
func handle_flipping() -> void:
	if state_machine.current_state and state_machine.current_state.name == "DeathState":
		return
	
	var move_dir = Input.get_axis("move_left", "move_right")
	
	if move_dir != 0:
		var side_flipped = move_dir < 0
		if animated_sprite.flip_h != side_flipped:
			animated_sprite.flip_h = side_flipped
			_update_child_positions(side_flipped)

func _update_child_positions(is_flipped: bool) -> void:
	var side_multiplier = -1 if is_flipped else 1
	arrow_start_position.position.x = abs(arrow_start_position.position.x) * side_multiplier
	hitbox.position.x = abs(hitbox.position.x) * side_multiplier

# --- Element / State Logic ---
func toggle_element_state() -> void:	
	is_light = !is_light
	update_physics_layers()
	
	# Emit signal to inform the UI
	element_toggled.emit(is_light)
	
	if state_machine.current_state:
		play_animation(state_machine.current_state.animation_name)

func update_physics_layers() -> void:
	collision_layer = 0
	collision_mask = 0
	
	if is_light:
		set_collision_layer_value(2, true) 
		set_collision_mask_value(4, true) 
		set_collision_mask_value(5, true) 
	else:
		set_collision_layer_value(1, true) 
		set_collision_mask_value(3, true) 
		set_collision_mask_value(5, true)

# --- Animations & Effects ---
func play_animation(anim_base_name: String) -> void:
	var final_base_name = anim_base_name
	
	if anim_base_name == "attack":
		if not is_light:
			final_base_name = "attack" + str(combo_count)
			apply_shake(0.2)
		else:
			final_base_name = "shoot"
	
	var suffix = "_light" if is_light else "_dark"
	var anim_to_play = final_base_name + suffix
	
	if not animated_sprite.sprite_frames.has_animation(anim_to_play):
		anim_to_play = final_base_name

	if not is_light and anim_base_name == "attack":
		animation_player.play(anim_to_play)
	else:
		animation_player.stop()
		
		if anim_base_name != "attack":
			hitbox_shape.set_deferred("disabled", true)
		
		if animated_sprite.sprite_frames.has_animation(anim_to_play):
			animated_sprite.play(anim_to_play)

# --- Damage & Shake ---
func take_damage(amount: int) -> void:
	PlayerManager.subtract_health(amount)
	flash_hurt()
	apply_shake(0.4) 

func flash_hurt() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color(10, 0.2, 0.2, 1) 
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func apply_shake(amount: float) -> void:
	shake_trauma = min(shake_trauma + amount, 1.0)

func _execute_shake() -> void:
	var amount = pow(shake_trauma, 2)
	camera.offset.x = max_shake_offset.x * amount * randf_range(-1, 1)
	camera.offset.y = max_shake_offset.y * amount * randf_range(-1, 1)

# --- Combat Actions ---
func shoot_arrow() -> void:
	if arrow_scene:
		apply_shake(0.03) 
		var arrow_instance = arrow_scene.instantiate()
		arrow_instance.global_position = arrow_start_position.global_position
		var mouse_pos = get_global_mouse_position()
		var shoot_dir = (mouse_pos - arrow_instance.global_position).normalized()
		arrow_instance.direction = shoot_dir
		arrow_instance.rotation = shoot_dir.angle()
		get_tree().current_scene.add_child(arrow_instance)

func _on_melee_weapon_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent().has_method("take_damage"):
		apply_shake(0.2)
		area.get_parent().take_damage(PlayerManager.get_damage(), global_position)

func _on_death() -> void:
	if state_machine.current_state and state_machine.current_state.name != "DeathState":
		state_machine.change_state($StateMachine/DeathState)

func get_speed() -> float:
	return PlayerManager.get_speed()

func get_jump_velocity() -> float:
	return PlayerManager.get_jump_velocity()
