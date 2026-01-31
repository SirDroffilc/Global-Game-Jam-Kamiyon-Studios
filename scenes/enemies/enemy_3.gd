extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 100
@export var damage: int = 75
@export var dash_speed: float = 900.0 # Increased slightly for a snappier feel
@export var retreat_speed: float = 300.0 
@export var dash_stop_distance: float = 10.0 # Distance to stop right in front of player
@onready var current_health: int = base_health

# --- Loot Attributes ---
enum DropType { ATTACK, HEAL }
var assigned_drop: DropType
@export var attack_boost_amount: int = 10
@export var heal_amount: int = 50

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

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	item_drop.visible = false
	item_collision.disabled = true

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
			move_velocity.x = 0
			if player:
				animated_sprite.flip_h = (player.global_position.x - global_position.x) > 0
				_handle_hitbox_flip(animated_sprite.flip_h)
				
		EnemyState.DASHING:
			animated_sprite.play("run")
			if player:
				var dist_x = player.global_position.x - global_position.x
				
				# Check if we have reached the player
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

func _handle_hitbox_flip(is_flipped: bool) -> void:
	attack_hitbox.scale.x = 1 if not is_flipped else -1

# --- Attack Pattern Sequence ---
func _on_attack_timer_timeout() -> void:
	if is_active and is_on_floor() and not is_dying and current_state == EnemyState.IDLE:
		start_attack_sequence()

func start_attack_sequence() -> void:
	# Face the player before starting the dash
	if player:
		animated_sprite.flip_h = (player.global_position.x - global_position.x) > 0
		_handle_hitbox_flip(animated_sprite.flip_h)
		
	current_state = EnemyState.DASHING 

func _on_dash_finished() -> void:
	if is_dying or current_state != EnemyState.DASHING: return
	
	current_state = EnemyState.ATTACKING 
	velocity.x = 0 # Immediate stop
	animation_player.play("attack_sequence")

func start_retreat() -> void:
	# Called by AnimationPlayer Method Track
	current_state = EnemyState.RETREATING 
	get_tree().create_timer(0.6).timeout.connect(_on_retreat_finished)

func _on_retreat_finished() -> void:
	current_state = EnemyState.IDLE 

# --- Combat Logic ---
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if current_state == EnemyState.ATTACKING:
		if body.has_method("take_damage"):
			body.take_damage(damage)

# --- Standard Logic ---
func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying: return
	current_health -= amount
	flash_hurt()
	if attacker_pos != Vector2.ZERO:
		var knockback_dir = (global_position - attacker_pos).normalized()
		knockback_velocity = Vector2(knockback_dir.x, -0.1).normalized() * knockback_strength 
	if current_health <= 0:
		die()

func flash_hurt() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color("8c8c8c")
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func _on_visible_on_screen_notifier_screen_entered() -> void:
	is_active = true
	attack_timer.start()

func _on_visible_on_screen_notifier_screen_exited() -> void:
	is_active = false
	attack_timer.stop()

func die() -> void:
	is_dying = true
	is_active = false
	animation_player.stop()
	velocity = Vector2.ZERO 
	collision_layer = 0
	collision_mask = 0
	attack_hitbox.monitoring = false
	if has_node("Hurtbox"): $Hurtbox.queue_free()
	animated_sprite.play("death")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		_spawn_loot()

func _spawn_loot() -> void:
	assigned_drop = DropType.values().pick_random()
	animated_sprite.visible = false
	item_drop.visible = true
	item_collision.set_deferred("disabled", false)
	var tween = create_tween()
	item_drop.scale = Vector2.ZERO
	tween.tween_property(item_drop, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _on_item_drop_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_apply_loot_bonus()
		queue_free()

func _apply_loot_bonus() -> void:
	if assigned_drop == DropType.ATTACK:
		PlayerManager.base_damage += attack_boost_amount
		print(">>> LOOT: Attack +", attack_boost_amount)
	else:
		PlayerManager.add_health(heal_amount)
		print(">>> LOOT: Healed +", heal_amount)
