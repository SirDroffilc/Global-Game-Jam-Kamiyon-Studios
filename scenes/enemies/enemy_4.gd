extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 30
@export var damage_basic: int = 30
@export var damage_dash: int = 45
@export var move_speed: float = 150.0
@export var dash_speed: float = -850.0
@export var follow_distance: float = 60.0 
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

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack1_hitbox: Area2D = $Attack1Hitbox
@onready var attack2_hitbox: Area2D = $Attack2Hitbox

func _ready() -> void:
	print(">>> ENEMY 4: Spawned at ", global_position, " - Health: ", current_health)
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		print(">>> ENEMY 4 WARNING: Player group not found!")

func _physics_process(delta: float) -> void:
	if is_dying: return 

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	var move_velocity = Vector2.ZERO

	match current_state:
		EnemyState.IDLE:
			animated_sprite.play("idle")
			_face_player()
			
		EnemyState.MOVING:
			animated_sprite.play("run")
			_face_player()
			if player:
				var dist_x = player.global_position.x - global_position.x
				if abs(dist_x) > follow_distance:
					move_velocity.x = sign(dist_x) * move_speed
				else:
					current_state = EnemyState.IDLE
		
		EnemyState.DASHING:
			var dash_dir = -1 if animated_sprite.flip_h else 1
			move_velocity.x = dash_dir * dash_speed
			
		EnemyState.ATTACKING:
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
			animation_player.play("attack1_sequence")
			attack_step += 1
			attack_timer.start(1.0 if attack_step == 1 else 1.5)
			
		2: 
			current_state = EnemyState.ATTACKING
			animation_player.play("attack2_sequence")
			attack_step = 0 
			attack_timer.start(3.0)

# --- Animation Call Methods ---

func start_dash_attack() -> void:
	current_state = EnemyState.DASHING

func end_dash_attack() -> void:
	current_state = EnemyState.IDLE

func finish_attack() -> void:
	current_state = EnemyState.MOVING


func _on_attack_1_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_basic)

func _on_attack_2_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_dash)

# --- THE DAMAGE HANDLER ---

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying: 
		print(">>> ENEMY 4: Received damage but is already dying.")
		return
		
	print(">>> ENEMY 4: HIT! Amount: ", amount, " | Current Health: ", current_health)
	
	current_health -= amount
	_flash_hurt()
	
	if attacker_pos != Vector2.ZERO:
		var knockback_dir = (global_position - attacker_pos).normalized()
		knockback_velocity = Vector2(knockback_dir.x, -0.1).normalized() * knockback_strength 
	
	if current_health <= 0:
		print(">>> ENEMY 4: Health depleted. Starting death sequence.")
		die()

func die() -> void:
	is_dying = true
	attack_timer.stop()
	animated_sprite.play("death")
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

# --- Helpers ---

func _face_player() -> void:
	if player:
		var side = (player.global_position.x - global_position.x) > 0
		animated_sprite.flip_h = side
		attack1_hitbox.scale.x = 1 if not side else -1
		attack2_hitbox.scale.x = 1 if not side else -1

func _flash_hurt() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color(10, 10, 10, 1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	is_active = true
	current_state = EnemyState.MOVING
	attack_timer.start()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	is_active = false
	attack_timer.stop()
