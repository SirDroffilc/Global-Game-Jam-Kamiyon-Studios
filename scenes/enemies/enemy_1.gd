extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 30
@export var damage: int = 50
@export var walk_speed: float = 50.0 
@export var stopping_distance: float = 60.0 
@onready var current_health: int = base_health

# --- Loot Attributes ---
enum DropType { ATTACK, HEAL }
var assigned_drop: DropType
@export var attack_boost_amount: int = 5
@export var heal_amount: int = 25

# --- Attack Attributes ---
@export var tackle_force_x: float = 450.0 
@export var tackle_force_y: float = -250.0 
var is_attacking: bool = false
var is_dying: bool = false
var tackle_cooldown_timer: float = 0.0 
var has_dealt_damage: bool = false 

# --- Visibility & Target ---
var is_active: bool = false
var player: CharacterBody2D = null

# --- Knockback Variables ---
@export var knockback_strength: float = 150.0 
@export var knockback_friction: float = 1500.0 
var knockback_velocity: Vector2 = Vector2.ZERO

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var tackle_hitbox: Area2D = $TackleHitbox
@onready var item_drop: Area2D = $ItemDrop
@onready var item_collision: CollisionShape2D = $ItemDrop/CollisionShape2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	# Connect death animation signal
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Initial loot state: Hidden and physically disabled
	item_drop.visible = false
	item_collision.disabled = true

func _physics_process(delta: float) -> void:
	if is_dying: return 

	# Handle gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
		# Reset horizontal momentum after landing if an attack was finished
		if is_attacking and tackle_cooldown_timer <= 0:
			is_attacking = false
			velocity.x = 0 

	# Manage attack cooldown
	if tackle_cooldown_timer > 0:
		tackle_cooldown_timer -= delta

	var move_velocity = Vector2.ZERO
	
	# Following/Chasing Logic
	if is_active and player and not is_attacking:
		var dist_to_player = player.global_position.x - global_position.x
		
		if abs(dist_to_player) > stopping_distance:
			move_velocity.x = sign(dist_to_player) * walk_speed
			animated_sprite.flip_h = dist_to_player > 0
			_handle_hitbox_flip(dist_to_player > 0)
			if not AudioManager.is_playing_omni("EnemyWalk"):
				AudioManager.play_omni("EnemyWalk")
			animated_sprite.play("walk")
		else:
			move_velocity.x = 0
			animated_sprite.play("idle")
			animated_sprite.flip_h = dist_to_player > 0
			_handle_hitbox_flip(dist_to_player > 0)

	# Apply and decay knockback momentum
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	if not is_attacking:
		velocity.x = move_velocity.x + knockback_velocity.x
	else:
		velocity.x += knockback_velocity.x 
		
	move_and_slide()

func _handle_hitbox_flip(is_flipped: bool) -> void:
	# Flips the tackle area scale to match sprite orientation
	tackle_hitbox.scale.x = 1 if not is_flipped else -1

# --- Attack Logic ---
func _on_attack_timer_timeout() -> void:
	if is_active and player and is_on_floor() and not is_dying and not is_attacking:
		perform_tackle()

func perform_tackle() -> void:
	is_attacking = true
	has_dealt_damage = false 
	tackle_cooldown_timer = 0.2 
	
	animated_sprite.play("attack")
	
	var attack_dir = 1 if animated_sprite.flip_h else -1
	velocity.x = attack_dir * tackle_force_x
	velocity.y = tackle_force_y

func _on_tackle_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and not has_dealt_damage and not is_dying:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			has_dealt_damage = true

# --- Damage & Death ---
func _on_visible_on_screen_notifier_screen_entered() -> void:
	is_active = true

func _on_visible_on_screen_notifier_screen_exited() -> void:
	is_active = false

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying: return
	
	current_health -= amount
	AudioManager.play_omni("EnemyHurt")
	flash_hurt()
	spawn_hit_particles(global_position, Color.DIM_GRAY)
	
	if attacker_pos != Vector2.ZERO:
		var knockback_dir = (global_position - attacker_pos).normalized()
		var impact_vector = Vector2(knockback_dir.x, -0.1).normalized()
		knockback_velocity = impact_vector * knockback_strength 
		
	if current_health <= 0:
		die()

func flash_hurt() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color("0b0b0bff")
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func die() -> void:
	is_dying = true
	is_active = false
	velocity = Vector2.ZERO 
	
	# Meticulous: Clear physics layers so player can overlap with loot
	collision_layer = 0
	collision_mask = 0
	tackle_hitbox.monitoring = false
	
	AudioManager.play_omni("EnemyDeath")
	animated_sprite.play("death")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		_spawn_loot()

# --- Loot Implementation ---
func _spawn_loot() -> void:
	# 1. Randomize drop type
	assigned_drop = DropType.values().pick_random()
	
	# 2. Swap Visibility: Hide enemy corpse, show item
	animated_sprite.visible = false
	item_drop.visible = true
	
	# 3. Enable collision via set_deferred to avoid physics thread errors
	item_collision.set_deferred("disabled", false)
	
	# 4. Tween "Pop" for visual feedback
	var tween = create_tween()
	item_drop.scale = Vector2.ZERO
	tween.tween_property(item_drop, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	
	print(">>> LOOT DROPPED: ", DropType.keys()[assigned_drop])

func _on_item_drop_body_entered(body: Node2D) -> void:
	# This function handles the actual pickup
	if body.is_in_group("Player"):
		AudioManager.play_omni("ShardAbsorb")
		_apply_loot_bonus()
		
		# Finally free the node from the tree once loot is claimed
		queue_free()

func _apply_loot_bonus() -> void:
	if assigned_drop == DropType.ATTACK:
		PlayerManager.base_damage += attack_boost_amount
		print(">>> LOOT COLLECTED: Attack +", attack_boost_amount)
	else:
		PlayerManager.add_health(heal_amount)
		print(">>> LOOT COLLECTED: Healed +", heal_amount)
		
func spawn_hit_particles(pos: Vector2, color: Color = Color.WHITE) -> void:
	# 1. Create the particle node
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	
	# 2. Shape and Look
	particles.amount = 8                  # Number of circles
	particles.explosiveness = 1.0         # All fire at once
	particles.one_shot = true             # Don't loop
	particles.lifetime = 0.5              # How long they last
	
	# 3. Physics & Motion
	particles.spread = 180.0              # Explode in all directions
	particles.gravity = Vector2(0, 400)   # Make them 'fall' after exploding
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	
	# 4. Creating the "Circle" via Code
	# We use a simple built-in texture or a generated one. 
	# For "pure code," we can use a small white square and round it with scale curves.
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	# Create a Scale Curve (particles shrink as they fall)
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1)) # Start full size
	curve.add_point(Vector2(1, 0)) # End at zero
	particles.scale_amount_curve = curve
	
	# 5. Color and Cleanup
	particles.color = color
	particles.emitting = true
	
	# Automatically delete the node after it finishes
	particles.finished.connect(particles.queue_free)
