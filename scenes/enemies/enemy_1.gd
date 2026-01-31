extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 200
@export var damage: int = 50
@export var walk_speed: float = 50.0 
@export var stopping_distance: float = 60.0 
@onready var current_health: int = base_health

# --- Attack Attributes ---
@export var tackle_force_x: float = 450.0 
@export var tackle_force_y: float = -250.0 
var is_attacking: bool = false
var is_dying: bool = false
var tackle_cooldown_timer: float = 0.0 
var has_dealt_damage: bool = false # Meticulous: Prevent multiple hits in one tackle

# --- Visibility & Target ---
var is_active: bool = false
var player: CharacterBody2D = null

# --- Meticulous Knockback Variables ---
@export var knockback_strength: float = 120.0 
@export var knockback_friction: float = 1800.0 
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var tackle_hitbox: Area2D = $TackleHitbox

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dying: return 

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
		if is_attacking and tackle_cooldown_timer <= 0:
			is_attacking = false
			velocity.x = 0 

	if tackle_cooldown_timer > 0:
		tackle_cooldown_timer -= delta

	var move_velocity = Vector2.ZERO
	
	if is_active and player and not is_attacking:
		var dist_to_player = player.global_position.x - global_position.x
		
		if abs(dist_to_player) > stopping_distance:
			move_velocity.x = sign(dist_to_player) * walk_speed
			animated_sprite.flip_h = dist_to_player > 0
			_handle_hitbox_flip(dist_to_player > 0) # Meticulous: Flip the hitbox too
			animated_sprite.play("walk")
		else:
			move_velocity.x = 0
			animated_sprite.play("idle")
			animated_sprite.flip_h = dist_to_player > 0
			_handle_hitbox_flip(dist_to_player > 0)

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	if not is_attacking:
		velocity.x = move_velocity.x + knockback_velocity.x
	else:
		velocity.x += knockback_velocity.x 
		
	move_and_slide()

# Helper to ensure the tackle hitbox stays in front of the enemy
func _handle_hitbox_flip(is_flipped: bool) -> void:
	# Since enemy faces Left by default, flip_h = true means facing Right
	tackle_hitbox.scale.x = 1 if not is_flipped else -1

# --- Attack Logic ---
func _on_attack_timer_timeout() -> void:
	if is_active and player and is_on_floor() and not is_dying and not is_attacking:
		perform_tackle()

func perform_tackle() -> void:
	is_attacking = true
	has_dealt_damage = false # Reset hit flag for new tackle
	tackle_cooldown_timer = 0.2 
	animated_sprite.play("attack")
	
	var attack_dir = 1 if animated_sprite.flip_h else -1
	velocity.x = attack_dir * tackle_force_x
	velocity.y = tackle_force_y

# --- Meticulous Tackle Hit Logic ---
func _on_tackle_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and not has_dealt_damage and not is_dying:
		if body.is_in_group("Player"):
			# 1. Apply damage via PlayerManager
			PlayerManager.subtract_health(damage)
			has_dealt_damage = true # Ensure only one hit per tackle
			
			# 2. Print health as requested
			print("--- TACKLE HIT! Player Health: ", PlayerManager.get_health(), " ---")

# --- Signals & Death ---
func _on_visible_on_screen_notifier_screen_entered() -> void:
	is_active = true

func _on_visible_on_screen_notifier_screen_exited() -> void:
	is_active = false

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying: return
	current_health -= amount
	if attacker_pos != Vector2.ZERO:
		var knockback_dir = (global_position - attacker_pos).normalized()
		var impact_vector = Vector2(knockback_dir.x, -0.1).normalized()
		knockback_velocity = impact_vector * knockback_strength 
	if current_health <= 0:
		die()

func die() -> void:
	is_dying = true
	is_active = false
	velocity = Vector2.ZERO 
	animated_sprite.play("death")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		queue_free()
