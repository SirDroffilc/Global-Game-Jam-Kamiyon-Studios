extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 1000
@export var damage_basic: int = 10
@export var damage_dash: int = 20
@export var move_speed: float = 150.0
@export var dash_speed: float = -850.0
@export var follow_distance: float = 50.0 
@onready var current_health: int = base_health

# --- Pattern State ---
var attack_step: int = 0 
var is_active: bool = false
var is_dying: bool = false
var player: CharacterBody2D = null

# --- State Control ---
enum EnemyState { IDLE, MOVING, ATTACKING, DASHING }
var current_state: EnemyState = EnemyState.IDLE 

# --- Knockback Variables ---
@export var knockback_strength: float = 100.0 
@export var knockback_friction: float = 1200.0 
var knockback_velocity: Vector2 = Vector2.ZERO

# --- Visual Effects Attributes ---
@export_group("Dash Visuals")
@export var ghost_interval: float = 0.05 
var ghost_timer: float = 0.0

# --- Audio Attributes ---
var step_timer: float = 0.0
@export var step_interval: float = 0.35

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack1_hitbox: Area2D = $AnimatedSprite2D/Attack1Hitbox
@onready var attack2_hitbox: Area2D = $AnimatedSprite2D/Attack2Hitbox

# --- Lifecycle ---

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	# Start with hitboxes disabled for safety
	#attack1_hitbox.set_deferred("monitoring", false)
	#attack2_hitbox.set_deferred("monitoring", false)

func _physics_process(delta: float) -> void:
	if is_dying: return 

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	var move_velocity = Vector2.ZERO

	match current_state:
		EnemyState.IDLE:
			# METICULOUS: Only play if not already playing to prevent jitter
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
			_face_player()
			
		EnemyState.MOVING:
			if animated_sprite.animation != "run" or not animated_sprite.is_playing():
				animated_sprite.play("run")
				
			# Footsteps Logic
			step_timer -= delta
			if step_timer <= 0:
				AudioManager.play_omni("EnemyWalk")
				step_timer = step_interval
				
			_face_player()
			if player:
				var dist_x = player.global_position.x - global_position.x
				if abs(dist_x) > follow_distance:
					move_velocity.x = sign(dist_x) * move_speed
				else:
					current_state = EnemyState.IDLE
		
		EnemyState.DASHING:
			# Ghost Trail Logic
			ghost_timer += delta
			if ghost_timer >= ghost_interval:
				spawn_ghost()
				ghost_timer = 0
			
			var dash_dir = -1 if animated_sprite.flip_h else 1
			move_velocity.x = dash_dir * dash_speed
			
		EnemyState.ATTACKING:
			# AnimationPlayer has total control here
			move_velocity.x = 0

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	velocity.x = move_velocity.x + knockback_velocity.x
	move_and_slide()

# --- Attack Pattern Logic ---

func _on_attack_timer_timeout() -> void:
	if is_active and not is_dying and current_state != EnemyState.ATTACKING:
		execute_pattern_step()

func execute_pattern_step() -> void:
	_face_player()
	match attack_step:
		0, 1: 
			current_state = EnemyState.ATTACKING
			animated_sprite.stop() # Clean state for AnimationPlayer
			AudioManager.play_omni("EnemySlash")
			animation_player.play("attack1_sequence")
			attack_step += 1
			attack_timer.start(0.3 if attack_step == 1 else 1.0)
			
		2: 
			current_state = EnemyState.ATTACKING
			#spawn_attack_indicator() # Ethereal "Tell" indicator
			animated_sprite.stop()
			animation_player.play("attack2_sequence")
			attack_step = 0 
			attack_timer.start(4.0)

# --- Animation Call Methods (From AnimationPlayer) ---

func start_dash_attack() -> void:
	#AudioManager.play_omni("EnemyDash")
	current_state = EnemyState.DASHING
	ghost_timer = 0

func end_dash_attack() -> void:
	current_state = EnemyState.IDLE
	animated_sprite.play("idle")
	#$Attack2Hitbox/CollisionShape2D.disabled = true
	
func finish_attack() -> void:
	current_state = EnemyState.MOVING
	animated_sprite.play("run")
	#$Attack2Hitbox/CollisionShape2D.disabled = true

# --- Visual Effects Functions ---

func spawn_attack_indicator() -> void:
	var indicator = Sprite2D.new()
	indicator.texture = PlaceholderTexture2D.new()
	indicator.texture.set_size(Vector2(32, 32))
	get_tree().current_scene.add_child(indicator)
	
	indicator.global_position = global_position + Vector2(0, -45)
	indicator.modulate = Color(0.6, 0.6, 0.6, 0.0) 
	indicator.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(indicator, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(indicator, "modulate:a", 0.8, 0.1)
	tween.chain().tween_property(indicator, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(indicator, "scale", Vector2(1.5, 1.5), 0.2)
	tween.chain().tween_callback(indicator.queue_free)

func spawn_ghost() -> void:
	var ghost = Sprite2D.new()
	get_tree().current_scene.add_child(ghost)
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.global_position = global_position
	ghost.flip_h = animated_sprite.flip_h
	ghost.scale = animated_sprite.scale
	ghost.modulate = Color(1.2, 1.2, 1.2, 0.4) 
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_property(ghost, "scale", Vector2.ZERO, 0.2)
	tween.chain().tween_callback(ghost.queue_free)

func _flash_hurt() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color(0.15, 0.15, 0.15, 1.0) 
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

# --- Combat Logic ---

func _on_attack_1_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_basic)
		

func _on_attack_2_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_dash)
		print("dash damage")

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying: return
	current_health -= amount
	_flash_hurt()
	AudioManager.play_omni("EnemyHurt")
	
	if attacker_pos != Vector2.ZERO:
		var knockback_dir = (global_position - attacker_pos).normalized()
		knockback_velocity = Vector2(knockback_dir.x, -0.1).normalized() * knockback_strength 
	
	if current_health <= 0:
		die()

func die() -> void:
	is_dying = true
	attack_timer.stop()
	# Ensure AnimatedSprite is stopped so AnimationPlayer can play 'death' cleanly
	animated_sprite.stop()
	$Hurtbox.queue_free()
	AudioManager.play_omni("EnemyDeath")
	animated_sprite.play("death")
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	queue_free()

# --- Helpers ---

func _face_player() -> void:
	if player:
		var side = (player.global_position.x - global_position.x) > 0
		animated_sprite.flip_h = side
		attack1_hitbox.scale.x = 1 if not side else -1
		attack2_hitbox.scale.x = 1 if not side else -1
		$CollisionShape2D.position.x = 48.0 if not side else -48.0
		$Hurtbox.position.x = 48.0 if not side else -48.0

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not is_active:
		AudioManager.play_omni("BossGrowl") # Play aggro sound once
	is_active = true
	current_state = EnemyState.MOVING
	attack_timer.start()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	#attack_timer.stop()
	pass
	
