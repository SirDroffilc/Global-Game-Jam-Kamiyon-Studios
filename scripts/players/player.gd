class_name Player
extends CharacterBody2D

# --- Signals ---
signal element_toggled(is_light: bool) 

var is_light: bool = false

# --- Node References ---
@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox: Area2D = $AnimatedSprite/MeleeWeaponHitbox 
@onready var hitbox_shape: CollisionShape2D = $AnimatedSprite/MeleeWeaponHitbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var arrow_start_position: Marker2D = $AnimatedSprite/ArrowStartPosition

# --- Dash & Jump Logic ---
@onready var dash_state: State = $StateMachine/DashState
@export var dash_available: bool = true # Ground-reset charge
@export var dash_cooldown: float = 1.5 
var dash_cooldown_timer: float = 0.0
@export var can_double_jump: bool = true # Track double jump charge
@export var toggle_cooldown: float = 0.1 # Minimum time between toggles
var toggle_cooldown_timer: float = 0.0

# --- Light State Timer Settings ---
@export var max_light_time: float = 5.0
@export var min_light_time: float = max_light_time / 4.0
@export var light_timer: float = 5.0
@export var recharge_rate: float = 1.0

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

# --- Movement "Juice" Logic ---
var was_on_floor: bool = false
var dust_spawn_timer: float = 0.0
@export var dust_interval: float = 0.35

# --- Lifecycle ---

func _ready() -> void:
	state_machine.init(self)
	is_light = false	
	PlayerManager.is_light = is_light
	update_physics_layers()
	
	if not hitbox.area_entered.is_connected(_on_melee_weapon_hitbox_area_entered):
		hitbox.area_entered.connect(_on_melee_weapon_hitbox_area_entered)
	
	hitbox_shape.set_deferred("disabled", true)
	PlayerManager.reset_health()
	
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_death)

func _process(delta: float) -> void:
	if shake_trauma > 0:
		shake_trauma = max(shake_trauma - shake_decay * delta, 0)
		_execute_shake()
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# --- Light State Timer Logic ---
	if is_light:
		light_timer -= delta
		if light_timer <= 0:
			light_timer = 0
			print(">>> LIGHT EXHAUSTED: Forcing Dark State")
			toggle_element_state() # Forcibly switch back
	else:
		# Recharge logic while in Dark state
		if light_timer < max_light_time:
			light_timer += delta * recharge_rate
			light_timer = min(light_timer, max_light_time)
			
	# 1. Decay Timers
	if ranged_cooldown_timer > 0: ranged_cooldown_timer -= delta
	if jump_buffer_timer > 0: jump_buffer_timer -= delta
	if dash_cooldown_timer > 0: dash_cooldown_timer -= delta
	if toggle_cooldown_timer > 0: toggle_cooldown_timer -= delta
	
	recoil_physics_velocity = recoil_physics_velocity.move_toward(Vector2.ZERO, recoil_friction * delta)
	
	# 2. Ground Logic
	if is_on_floor():
		dash_available = true
		can_double_jump = true 
		if not was_on_floor:
			AudioManager.play_omni("PlayerLand")
	
	# 3. Dash Gatekeeper
	if Input.is_action_just_pressed("dash"):
		if dash_available and dash_cooldown_timer <= 0:
			state_machine.change_state(dash_state)
	
	# 4. Jump Logic
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		if is_on_floor(): 
			AudioManager.play_omni("PlayerJump")

	# 5. Run Particles
	if is_on_floor() and abs(velocity.x) > 10.0:
		dust_spawn_timer += delta
		if dust_spawn_timer >= dust_interval:
			AudioManager.play_omni("PlayerRun")
			dust_spawn_timer = 0
	else:
		dust_spawn_timer = 0
	
	was_on_floor = is_on_floor()
	handle_flipping()
	state_machine.process_physics(delta)

# --- Signal Handlers ---

func _on_melee_weapon_hitbox_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target.has_method("take_damage"):
		apply_shake(0.2)
		spawn_attack_slash() 
		var slash_sfx_list = ["PlayerSlash1", "PlayerSlash2", "PlayerSlash3"]
		AudioManager.play_omni(slash_sfx_list.pick_random())
		target.take_damage(PlayerManager.get_damage(), global_position)

# --- Visual Helpers ---

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

func spawn_hit_particles(pos: Vector2, color: Color = Color.WHITE) -> void:
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	
	# Look: Large, explosive circles
	particles.amount = 8
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.lifetime = 0.4 # Quick and snappy
	
	# Motion: High initial burst, then slows down
	particles.spread = 120.0
	particles.gravity = Vector2(0, 500) # Heavy gravity
	particles.initial_velocity_min = 250.0 # Faster burst
	particles.initial_velocity_max = 400.0
	particles.damping_min = 50.0 # Air resistance
	particles.damping_max = 100.0
	
	# Shape: Growing then shrinking
	particles.scale_amount_min = 4.0 # Much larger
	particles.scale_amount_max = 8.0
	
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0.2)) # Start small
	curve.add_point(Vector2(0.2, 1.0)) # Snap to large quickly
	curve.add_point(Vector2(1, 0)) # Fade out to nothing
	particles.scale_amount_curve = curve
	
	particles.color = color
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

func spawn_dust_particles() -> void:
	# Use this for jumping/walking
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position + Vector2(0, 10) # Position at feet
	
	particles.amount = 6
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.8
	
	# Motion: Smoke-like drift
	particles.direction = Vector2(0, -1) # Upwards
	particles.spread = 45.0
	particles.gravity = Vector2(0, -20) # Slight floaty lift
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	
	# Look: Large soft "smoke" circles
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	
	# Smoke Alpha Curve (Fades out)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 0.8)) # Start visible
	gradient.add_point(1.0, Color(1, 1, 1, 0))   # Fade to transparent
	particles.color_ramp = gradient
	
	# Scale Curve (Expands like real smoke)
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(1, 1.5)) # Gets bigger as it disappears
	particles.scale_amount_curve = curve
	
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

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

func spawn_shoot_smoke() -> void:
	var smoke = CPUParticles2D.new()
	get_tree().current_scene.add_child(smoke)
	smoke.global_position = animated_sprite.global_position
	smoke.amount = 12
	smoke.one_shot = true
	smoke.explosiveness = 1.0
	smoke.lifetime = 0.3
	smoke.gravity = Vector2(0, -80) 
	smoke.initial_velocity_min = 40.0
	smoke.initial_velocity_max = 70.0
	smoke.color = Color.DIM_GRAY
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	smoke.scale_amount_curve = curve
	smoke.emitting = true
	smoke.finished.connect(smoke.queue_free)

# --- Combat Actions ---

func shoot_arrow() -> void:
	if arrow_scene:
		var mouse_pos = get_global_mouse_position()
		var side_flipped = mouse_pos.x < global_position.x
		if animated_sprite.flip_h != side_flipped:
			animated_sprite.flip_h = side_flipped
			_update_child_positions(side_flipped)
		
		ranged_cooldown_timer = ranged_cooldown
		apply_shake(0.15) 
		AudioManager.play_omni("PlayerShoot")
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
	var recoil_tween = create_tween()
	animated_sprite.offset = -direction * recoil_sprite_strength
	recoil_tween.tween_property(animated_sprite, "offset", Vector2.ZERO, recoil_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func take_damage(amount: int) -> void:
	
	if PlayerManager.current_health <= 0 or (state_machine.current_state and state_machine.current_state.name == "DeathState"):
		return
		
	PlayerManager.subtract_health(amount)
	AudioManager.play_omni("PlayerHurt")
	flash_hurt()
	apply_shake(0.4) 
	spawn_hit_particles(global_position, Color.BLACK) # THE BLACK PARTICLES ARE HERE

func flash_hurt() -> void:
	var tween = create_tween()
	# Using RAW values above 1.0 creates a bright "White Flash" even with bloom
	# We use self_modulate to avoid affecting the health bar or other children
	animated_sprite.self_modulate = Color(0.311, 0.311, 0.311, 1.0) 
	tween.tween_property(animated_sprite, "self_modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)

# --- State Helpers ---

func handle_flipping() -> void:
	if state_machine.current_state and state_machine.current_state.name == "DeathState": return
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
	
	resolve_collision_overlap()

func resolve_collision_overlap() -> void:
	if not test_move(global_transform, Vector2.ZERO):
		return

	var original_pos = global_position
	var max_search_range : int = 16*100
	
	# Bitmask for Layer 5 (Neutral Objects) is 16
	var neutral_layer_mask : int = 16 

	for distance in range(1, max_search_range + 1):
		var directions = [
			Vector2.UP * distance,
			Vector2.DOWN * distance,
			Vector2.LEFT * distance,
			Vector2.RIGHT * distance
		]
		
		for offset in directions:
			var target_pos = original_pos + offset
			
			# 1. Check if the target spot is physically empty
			global_position = target_pos
			if not test_move(global_transform, Vector2.ZERO):
				
				# 2. VALIDATION: Check if we passed through a Neutral layer to get here
				# We use a shape_collide or a simple line check back to the start
				if not _is_neutral_blocking_path(original_pos, target_pos, neutral_layer_mask):
					# SUCCESS: Spot is empty AND we didn't phase through Neutral ground
					animate_collision_snap(original_pos - global_position)
					return
	
	# If no legal spots found, revert
	global_position = original_pos
	print(">>> COLLISION ERROR: No legal escape found (Neutral layers blocked path).")

func _is_neutral_blocking_path(start: Vector2, end: Vector2, mask: int) -> bool:
	# Create a temporary raycast query 
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start, end, mask)
	query.collide_with_areas = false # We only care about tilemap physics
	
	var result = space_state.intersect_ray(query)
	
	# If the result is NOT empty, we hit a Neutral wall/floor
	return not result.is_empty()

func animate_collision_snap(offset: Vector2) -> void:
	# 1. Immediately offset the sprite so it looks like it stayed in the wall
	animated_sprite.offset = offset
	
	# 2. Create a fast, punchy tween to slide the sprite back to center
	var tween = create_tween()
	tween.tween_property(animated_sprite, "offset", Vector2.ZERO, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# 3. Optional: Add a small scale "squeeze" to make it feel like they popped out
	animated_sprite.scale = Vector2(1.2, 0.8) # Squash
	tween.parallel().tween_property(animated_sprite, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)

func play_animation(anim_base_name: String) -> void:
	var final_base_name = anim_base_name
	
	if anim_base_name == "attack":
		# Logic check:
		# If is_light: "shoot"
		# If !is_light: "attack" + "1" -> "attack1"
		final_base_name = "shoot" if is_light else "attack" + str(combo_count)
		if not is_light: apply_shake(0.2)
		
	# Suffix adds the underscore: "_dark" or "_light"
	var suffix = "_light" if is_light else "_dark"
	var anim_to_play = final_base_name + suffix
	
	# Final string check: "attack1" + "_dark" = "attack1_dark"
	
	# Safety check for AnimatedSprite (fallback)
	if not animated_sprite.sprite_frames.has_animation(anim_to_play): 
		anim_to_play = final_base_name
		
	# Meticulous routing:
	# Use AnimationPlayer for Melee (Dark Attack)
	if not is_light and anim_base_name == "attack": 
		if animation_player.has_animation(anim_to_play):
			animation_player.play(anim_to_play)
			print("animation_player playing ", anim_to_play)
		else:
			push_error("AnimationPlayer missing: " + anim_to_play)
	else:
		# Use AnimatedSprite for everything else
		animation_player.stop()
		if anim_base_name != "attack": 
			hitbox_shape.set_deferred("disabled", true)
		if animated_sprite.sprite_frames.has_animation(anim_to_play): 
			animated_sprite.play(anim_to_play)

func toggle_element_state() -> void:	
	is_light = !is_light
	PlayerManager.is_light = is_light
	update_physics_layers()
	_trigger_element_flash(is_light)
	_spawn_toggle_burst(is_light)
	AudioManager.play_omni("switch_element")
	apply_shake(0.2) 
	element_toggled.emit(is_light)

	# Check if we are in an attack/shoot state
	var current = state_machine.current_state.name
	if current.contains("Attack") or current.contains("Shoot"):
		combo_count = 0
		state_machine.change_state(state_machine.initial_state)
	else:
		if state_machine.current_state: 
			play_animation(state_machine.current_state.animation_name)

func _trigger_element_flash(is_light_state: bool) -> void:
	var canvas = CanvasLayer.new(); add_child(canvas)
	var rect = ColorRect.new(); canvas.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(1, 1, 1, 0.14) if is_light_state else Color(0.18, 0.18, 0.18, 0.12)
	create_tween().tween_property(rect, "modulate:a", 0.0, 0.6).finished.connect(canvas.queue_free)

func _spawn_toggle_burst(is_light_state: bool) -> void:
	var particles = CPUParticles2D.new(); get_tree().current_scene.add_child(particles)
	particles.global_position = animated_sprite.global_position
	particles.amount = 5; particles.one_shot = true; particles.explosiveness = 1.0
	particles.spread = 180.0; particles.gravity = Vector2.ZERO; particles.initial_velocity_min = 150.0
	particles.color = Color(2, 2, 1.5, 0.8) if is_light_state else Color(0, 0, 0, 0.65)
	var curve = Curve.new(); curve.add_point(Vector2(0, 1)); curve.add_point(Vector2(1, 0))
	particles.scale_amount_curve = curve; particles.emitting = true; particles.finished.connect(particles.queue_free)

# --- Shake Logic ---

func apply_shake(amount: float) -> void:
	shake_trauma = clamp(shake_trauma + amount, 0.0, max_shake_trauma)

func _execute_shake() -> void:
	var amount = pow(shake_trauma, 2)
	camera.offset.x = max_shake_offset.x * amount * randf_range(-1, 1)
	camera.offset.y = max_shake_offset.y * amount * randf_range(-1, 1)

func _on_death() -> void:
	if state_machine.current_state and state_machine.current_state.name != "DeathState":
		state_machine.change_state($StateMachine/DeathState)
	AudioManager.play_omni("PlayerDeath"); apply_shake(0.25)
	print("player died")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("skill1"): 
		if toggle_cooldown_timer <= 0:
			# Check if we are trying to turn on Light but have no energy
			if not is_light and light_timer <= min_light_time:
				print(">>> Cannot switch: Light state not charged!")
				return
				
			toggle_element_state()
			toggle_cooldown_timer = toggle_cooldown
			
	state_machine.process_input(event)

func get_speed() -> float: return PlayerManager.get_speed()
func get_jump_velocity() -> float: return PlayerManager.get_jump_velocity()
