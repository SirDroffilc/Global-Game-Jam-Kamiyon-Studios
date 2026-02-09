extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 100
@export var damage: int = 15
@export var walk_speed: float = 100.0 
@export var dash_speed: float = 800.0 
@export var retreat_speed: float = 100.0 
@export var stopping_distance: float = 50.0 
@export var dash_stop_distance: float = 10.0 
@onready var current_health: int = base_health

# --- Visual Effects Attributes ---
@export_group("Dash Visuals")
@export var ghost_interval: float = 0.05 
var ghost_timer: float = 0.0

# --- Loot Attribute (Heal) ---
@export var heal_amount: int = 20

# --- State Control ---
enum EnemyState { IDLE, DASHING, ATTACKING, RETREATING }
var current_state: EnemyState = EnemyState.IDLE 

var is_active: bool = false
var is_dying: bool = false
var player: CharacterBody2D = null

# --- Knockback Variables ---
@export var knockback_strength: float = 80.0 
@export var knockback_friction: float = 1200.0 
var knockback_velocity: Vector2 = Vector2.ZERO

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var item_drop: Area2D = $ItemDrop
@onready var item_collision: CollisionShape2D = $ItemDrop/CollisionShape2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var enemy_health_bar: TextureProgressBar = $EnemyHealthBar

# --- Lifecycle ---

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	item_drop.body_entered.connect(_on_item_drop_body_entered)
	item_drop.visible = false
	item_collision.disabled = true
	
	enemy_health_bar.max_value = base_health
	enemy_health_bar.value = base_health
	enemy_health_bar.visible = false
	
	retreat_speed = randf_range(50.0, 300.0)

func _physics_process(delta: float) -> void:
	if is_dying: 
		# Meticulous: Apply gravity while dying so the corpse falls
		velocity += get_gravity() * delta
		move_and_slide()
		return 

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	var move_velocity = Vector2.ZERO

	match current_state:
		EnemyState.IDLE:
			if is_active and player:
				var dist_x = player.global_position.x - global_position.x
				
				# METICULOUS: Chase Logic (similar to Enemy1)
				if abs(dist_x) > stopping_distance:
					move_velocity.x = sign(dist_x) * walk_speed
					animated_sprite.play("run") # Assuming 'run' is your walking animation
					
					if not AudioManager.is_playing_omni("EnemyWalk"):
						AudioManager.play_omni("EnemyWalk")
				else:
					move_velocity.x = 0
					animated_sprite.play("idle")
					AudioManager.stop_omni("EnemyWalk")
				
				# Always face the player while idling/walking
				animated_sprite.flip_h = dist_x > 0
				_handle_hitbox_flip(animated_sprite.flip_h)
			else:
				move_velocity.x = 0
				animated_sprite.play("idle")
				
		EnemyState.DASHING:
			animated_sprite.play("run")
			ghost_timer += delta
			if ghost_timer >= ghost_interval:
				spawn_ghost()
				ghost_timer = 0
			
			if player:
				var dist_x = player.global_position.x - global_position.x
				if abs(dist_x) <= dash_stop_distance:
					_on_dash_finished()
				else:
					move_velocity.x = sign(dist_x) * dash_speed
			
		EnemyState.ATTACKING:
			move_velocity.x = 0
			
		EnemyState.RETREATING:
			animated_sprite.play("run")
			var retreat_dir = -1 if animated_sprite.flip_h else 1
			move_velocity.x = retreat_dir * retreat_speed

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	velocity.x = move_velocity.x + knockback_velocity.x
	move_and_slide()

# --- Visual Effects Functions ---

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
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(ghost.queue_free)

func flash_hurt() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color(0.153, 0.153, 0.153, 1.0) 
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.15)

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
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	particles.scale_amount_curve = curve
	particles.color = color
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

# --- Attack Pattern Sequence ---

func _on_attack_timer_timeout() -> void:
	# Only start a dash if the enemy has walked close enough to the player
	if is_active and is_on_floor() and not is_dying and current_state == EnemyState.IDLE:
		var dist_x = player.global_position.x - global_position.x
		if abs(dist_x) <= stopping_distance + 50.0: # Meticulous: Allow a small buffer for the dash trigger
			start_attack_sequence()

func start_attack_sequence() -> void:
	if player:
		animated_sprite.flip_h = (player.global_position.x - global_position.x) > 0
		_handle_hitbox_flip(animated_sprite.flip_h)
		
	current_state = EnemyState.DASHING 
	AudioManager.play_omni("EnemyDash")
	ghost_timer = 0 

func _on_dash_finished() -> void:
	if is_dying or current_state != EnemyState.DASHING: return
	current_state = EnemyState.ATTACKING 
	velocity.x = 0 
	AudioManager.play_omni("EnemySlash")
	animation_player.play("attack_sequence")

func start_retreat() -> void:
	current_state = EnemyState.RETREATING 
	AudioManager.play_omni("EnemyWalk")
	get_tree().create_timer(0.6).timeout.connect(_on_retreat_finished)

func _on_retreat_finished() -> void:
	current_state = EnemyState.IDLE 

# --- Combat Logic ---

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if current_state == EnemyState.ATTACKING:
		if body.has_method("take_damage"):
			body.take_damage(damage)

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying: 
		return
	
	current_health -= amount
	
	if not enemy_health_bar.visible:
		enemy_health_bar.visible = true
	enemy_health_bar.value = current_health
	
	flash_hurt()
	AudioManager.play_omni("EnemyHurt")
	spawn_hit_particles(global_position, Color.DIM_GRAY)
	
	if attacker_pos != Vector2.ZERO:
		var knockback_dir = (global_position - attacker_pos).normalized()
		knockback_velocity = Vector2(knockback_dir.x, -0.1).normalized() * knockback_strength 
	
	if current_health <= 0:
		die()

# --- Death & Loot Logic ---

func die() -> void:
	is_dying = true
	is_active = false
	enemy_health_bar.visible = false
	velocity = Vector2.ZERO 
	
	# Meticulous: Clear physics layers so player can overlap with loot
	collision_layer = 0
	#collision_mask = 0
	$Hurtbox.queue_free()
	
	AudioManager.play_omni("EnemyDeath")
	animated_sprite.play("death")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		_spawn_loot()

# --- Loot Implementation ---
func _spawn_loot() -> void:
	animated_sprite.visible = false
	item_drop.visible = true
	if item_drop.has_method("play_animation"):
		item_drop.play_animation()

	item_collision.set_deferred("disabled", false)
	
	var tween = create_tween()
	item_drop.scale = Vector2.ZERO
	tween.tween_property(item_drop, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _on_item_drop_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		AudioManager.play_omni("ShardAbsorb")
		_apply_loot_bonus()
		queue_free()

func _apply_loot_bonus() -> void:
	PlayerManager.add_health(heal_amount)

# --- Helpers ---

func _handle_hitbox_flip(is_flipped: bool) -> void:
	attack_hitbox.scale.x = 1 if not is_flipped else -1

func _on_visible_on_screen_notifier_screen_entered() -> void:
	is_active = true
	attack_timer.start()

func _on_visible_on_screen_notifier_screen_exited() -> void:
	attack_timer.stop()
