class_name Player
extends CharacterBody2D

# --- Signals ---
signal element_toggled(is_light: bool) 

var is_light: bool = true

# --- Node References ---
@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox: Area2D = $AnimatedSprite/MeleeWeaponHitbox 
@onready var hitbox_shape: CollisionShape2D = $AnimatedSprite/MeleeWeaponHitbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var arrow_start_position: Marker2D = $AnimatedSprite/ArrowStartPosition

# --- Camera Shake Settings ---
@onready var camera: Camera2D = get_viewport().get_camera_2d() 
@export var shake_decay: float = 5.0
@export var max_shake_offset: Vector2 = Vector2(250, 250) 
@export var max_shake_trauma: float = 0.25 
var shake_trauma: float = 0.0

# --- Combat & Recoil Attributes ---
@export var ranged_cooldown: float = 0.5 
var ranged_cooldown_timer: float = 0.0 

@export_group("Recoil Settings")
@export var recoil_sprite_strength: float = 12.0
@export var recoil_physics_strength: float = 150.0
@export var recoil_friction: float = 1200.0
@export var recoil_duration: float = 0.12
var recoil_physics_velocity: Vector2 = Vector2.ZERO 

@export var arrow_scene: PackedScene = preload("res://scenes/players/light_arrow.tscn")

# --- Movement Attributes ---
var combo_count: int = 0
var can_combo: bool = false 

@export var jump_buffer_time: float = 0.15 
var jump_buffer_timer: float = 0.0
var can_dash: bool = true 

@export_group("Dash Settings")
@export var dash_cooldown: float = 1.0 
var dash_cooldown_timer: float = 0.0

# --- Movement "Juice" Logic ---
var was_on_floor: bool = false
var dust_spawn_timer: float = 0.0
@export var dust_interval: float = 0.15

# --- Lifecycle ---
func _ready() -> void:
	state_machine.init(self)
	update_physics_layers()
	
	if not hitbox.area_entered.is_connected(_on_melee_weapon_hitbox_area_entered):
		hitbox.area_entered.connect(_on_melee_weapon_hitbox_area_entered)
	
	hitbox_shape.set_deferred("disabled", true)
	PlayerManager.reset_health()
	PlayerManager.is_light = is_light
	
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_death)

func _process(delta: float) -> void:
	if shake_trauma > 0:
		shake_trauma = max(shake_trauma - shake_decay * delta, 0)
		_execute_shake()
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if ranged_cooldown_timer > 0: ranged_cooldown_timer -= delta
	if jump_buffer_timer > 0: jump_buffer_timer -= delta
	if dash_cooldown_timer > 0: dash_cooldown_timer -= delta
	
	recoil_physics_velocity = recoil_physics_velocity.move_toward(Vector2.ZERO, recoil_friction * delta)
	
	if is_on_floor() and not was_on_floor:
		spawn_dust_particles(8, 1.0, 150.0)
	
	if is_on_floor() and abs(velocity.x) > 10.0:
		dust_spawn_timer += delta
		if dust_spawn_timer >= dust_interval:
			spawn_dust_particles(2, 0.2, 40.0)
			dust_spawn_timer = 0
	else:
		dust_spawn_timer = 0
	
	was_on_floor = is_on_floor()
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		if is_on_floor(): spawn_dust_particles(5, 0.5, 80.0)

	if is_on_floor(): can_dash = true
	
	handle_flipping()
	state_machine.process_physics(delta)

# --- Signal Handlers ---

func _on_melee_weapon_hitbox_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target.has_method("take_damage"):
		apply_shake(0.2)
		target.take_damage(PlayerManager.get_damage(), global_position)

# --- Visual Effects Functions ---

func spawn_shoot_smoke() -> void:
	var smoke = CPUParticles2D.new()
	get_tree().current_scene.add_child(smoke)
	var dir_mult = -1 if animated_sprite.flip_h else 1
	smoke.global_position = animated_sprite.global_position
	smoke.amount = 12
	smoke.one_shot = true
	smoke.explosiveness = 1.0
	smoke.lifetime = 0.3
	smoke.spread = 50.0
	smoke.gravity = Vector2(0, -80) 
	smoke.initial_velocity_min = 40.0
	smoke.initial_velocity_max = 70.0
	smoke.color = Color.DIM_GRAY
	smoke.scale_amount_min = 3.0
	smoke.scale_amount_max = 6.0
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	smoke.scale_amount_curve = curve
	smoke.emitting = true
	smoke.finished.connect(smoke.queue_free)

func spawn_attack_slash() -> void:
	var slash = CPUParticles2D.new()
	get_tree().current_scene.add_child(slash)
	var dir_mult = -1 if animated_sprite.flip_h else 1
	slash.global_position = global_position + Vector2(25 * dir_mult, -5)
	slash.amount = 8
	slash.explosiveness = 1.0
	slash.one_shot = true
	slash.lifetime = 0.4
	slash.direction = Vector2(dir_mult, 0)
	slash.spread = 20.0
	slash.gravity = Vector2.ZERO
	slash.initial_velocity_min = 200.0
	slash.initial_velocity_max = 400.0
	slash.damping_min = 100.0
	slash.color = Color(15, 15, 15, 1) 
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	slash.scale_amount_curve = curve
	slash.emitting = true
	slash.finished.connect(slash.queue_free)

func spawn_ghost() -> void:
	var ghost = Sprite2D.new()
	get_tree().current_scene.add_child(ghost)
	ghost.global_position = global_position
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.flip_h = animated_sprite.flip_h
	ghost.scale = animated_sprite.scale
	ghost.modulate = Color(15, 15, 15, 0.7)
	var tween = create_tween()
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(ghost.queue_free)

# --- Combat Actions ---

func shoot_arrow() -> void:
	if arrow_scene:
		# Meticulous Face-Cursor Logic
		var mouse_pos = get_global_mouse_position()
		var side_flipped = mouse_pos.x < global_position.x
		
		# Update sprite and child positions based on mouse direction
		if animated_sprite.flip_h != side_flipped:
			animated_sprite.flip_h = side_flipped
			_update_child_positions(side_flipped)
		
		ranged_cooldown_timer = ranged_cooldown
		apply_shake(0.15) 
		spawn_shoot_smoke()
		
		var arrow_instance = arrow_scene.instantiate()
		arrow_instance.global_position = arrow_start_position.global_position
		
		var shoot_dir = (mouse_pos - arrow_instance.global_position).normalized()
		arrow_instance.direction = shoot_dir
		arrow_instance.rotation = shoot_dir.angle()
		get_tree().current_scene.add_child(arrow_instance)
		_apply_recoil(shoot_dir)

func _apply_recoil(direction: Vector2) -> void:
	recoil_physics_velocity = -direction * recoil_physics_strength
	var recoil_vector = -direction * recoil_sprite_strength
	var recoil_tween = create_tween()
	animated_sprite.offset = recoil_vector
	recoil_tween.tween_property(animated_sprite, "offset", Vector2.ZERO, recoil_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func take_damage(amount: int) -> void:
	PlayerManager.subtract_health(amount)
	flash_hurt()
	apply_shake(0.4) 
	spawn_hit_particles(global_position, Color.BLACK)

func flash_hurt() -> void:
	var flash_color: Color = Color(20, 20, 20, 1) 
	var duration: float = 0.15 
	var hurt_tween = create_tween()
	animated_sprite.modulate = flash_color
	hurt_tween.tween_property(animated_sprite, "modulate", Color.WHITE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- Utility Functions ---

func spawn_dust_particles(amount: int, explosiveness: float, speed: float) -> void:
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position + Vector2(0, 10) 
	particles.amount = amount
	particles.explosiveness = explosiveness
	particles.one_shot = true
	particles.lifetime = 0.4
	particles.direction = Vector2(0, -1)
	particles.gravity = Vector2(0, -100)
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.color = Color(1, 1, 1, 0.6)
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	particles.scale_amount_curve = curve
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

func spawn_hit_particles(pos: Vector2, color: Color = Color.WHITE) -> void:
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	particles.amount = 8
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.gravity = Vector2(0, 400)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	particles.scale_amount_curve = curve
	particles.color = color
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

# --- State & Movement Logic ---

func handle_flipping() -> void:
	if state_machine.current_state and state_machine.current_state.name == "DeathState": return
	
	# Skip auto-flipping if we are currently shooting/ranged aiming logic
	# Or keep it as a fallback for movement
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

# --- SWITCH STATE Visual Effects Functions ---

func toggle_element_state() -> void:	
	is_light = !is_light
	PlayerManager.is_light = is_light
	update_physics_layers()
	
	_trigger_element_flash(is_light)
	_spawn_toggle_burst(is_light)
	apply_shake(0.2) 
	
	element_toggled.emit(is_light)
	
	if state_machine.current_state:
		play_animation(state_machine.current_state.animation_name)
		

func _trigger_element_flash(is_light_state: bool) -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var rect = ColorRect.new()
	canvas.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var flash_color = Color(1.0, 1.0, 1.0, 0.137) if is_light_state else Color(0.176, 0.176, 0.176, 0.122)
	rect.color = flash_color
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, 0.60).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(canvas.queue_free)

func _spawn_toggle_burst(is_light_state: bool) -> void:
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = animated_sprite.global_position
	particles.amount = 5
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.lifetime = 0.6
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 300.0
	particles.damping_min = 100.0
	var p_color = Color(2, 2, 1.5, 0.8) if is_light_state else Color(0.0, 0.0, 0.0, 0.655)
	particles.color = p_color
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	particles.scale_amount_curve = curve
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

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

func play_animation(anim_base_name: String) -> void:
	var final_base_name = anim_base_name
	if anim_base_name == "attack":
		final_base_name = "shoot" if is_light else "attack" + str(combo_count)
		if not is_light: apply_shake(0.2)
	var suffix = "_light" if is_light else "_dark"
	var anim_to_play = final_base_name + suffix
	if not animated_sprite.sprite_frames.has_animation(anim_to_play): anim_to_play = final_base_name
	if not is_light and anim_base_name == "attack": animation_player.play(anim_to_play)
	else:
		animation_player.stop()
		if anim_base_name != "attack": hitbox_shape.set_deferred("disabled", true)
		if animated_sprite.sprite_frames.has_animation(anim_to_play): animated_sprite.play(anim_to_play)

func apply_shake(amount: float) -> void:
	shake_trauma = clamp(shake_trauma + amount, 0.0, max_shake_trauma)

func _execute_shake() -> void:
	var amount = pow(shake_trauma, 2)
	camera.offset.x = max_shake_offset.x * amount * randf_range(-1, 1)
	camera.offset.y = max_shake_offset.y * amount * randf_range(-1, 1)

func _on_death() -> void:
	if state_machine.current_state and state_machine.current_state.name != "DeathState":
		state_machine.change_state($StateMachine/DeathState)
	apply_shake(0.25)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("skill1"): toggle_element_state()
	state_machine.process_input(event)

func get_speed() -> float: return PlayerManager.get_speed()
func get_jump_velocity() -> float: return PlayerManager.get_jump_velocity()
