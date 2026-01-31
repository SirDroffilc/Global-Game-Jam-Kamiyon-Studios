extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 50
@export var damage: int = 30
@export var fly_speed: float = 60.0 
@export var stopping_distance_x: float = 200.0 # Renamed for clarity
@export var stopping_distance_y: float = -100.0 # New vertical buffer
@onready var current_health: int = base_health

# --- Loot Attributes ---
enum DropType { ATTACK, HEAL }
var assigned_drop: DropType
@export var attack_boost_amount: int = 5
@export var heal_amount: int = 25

# --- Attack Attributes ---
@export var spit_scene: PackedScene = preload("res://scenes/enemies/enemy_spit.tscn")
var is_dying: bool = false
var time_passed: float = 0.0

# --- Visibility & Target ---
var is_active: bool = false
var player: CharacterBody2D = null

# --- Meticulous Knockback Variables ---
@export var knockback_strength: float = 120.0 
@export var knockback_friction: float = 1000.0 
var knockback_velocity: Vector2 = Vector2.ZERO

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_marker: Marker2D = $AttackMarker
@onready var attack_timer: Timer = $AttackTimer
@onready var item_drop: Area2D = $ItemDrop
@onready var item_collision: CollisionShape2D = $ItemDrop/CollisionShape2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		print(">>> ERROR: Enemy 2 could not find Player group!")
		
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	item_drop.visible = false
	item_collision.disabled = true

func _physics_process(delta: float) -> void:
	if is_dying: return 

	time_passed += delta
	var move_velocity = Vector2.ZERO
	
	if is_active and player:
		# Calculate separate X and Y distances
		var diff_x = player.global_position.x - global_position.x
		var diff_y = player.global_position.y - global_position.y
		
		# --- Adjusted Movement Logic ---
		# Move on X-axis if beyond horizontal stopping distance
		if abs(diff_x) > stopping_distance_x:
			move_velocity.x = sign(diff_x) * fly_speed
		
		# Move on Y-axis if beyond vertical stopping distance
		# We use (diff_y + stopping_distance_y) to aim for a spot ABOVE the player
		var target_y_offset = diff_y + stopping_distance_y
		if abs(target_y_offset) > 20.0: # Small buffer to prevent jitter
			move_velocity.y = sign(target_y_offset) * fly_speed
		
		# Set animations
		if move_velocity.length() > 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("idle")
		
		# Housefly "Wobble"
		var fly_wobble = Vector2(0, sin(time_passed * 5.0) * 40.0)
		move_velocity += fly_wobble

		# Face the player
		animated_sprite.flip_h = diff_x > 0
		_handle_marker_flip(diff_x > 0)

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	velocity = move_velocity + knockback_velocity
	move_and_slide()

func _handle_marker_flip(is_flipped: bool) -> void:
	attack_marker.position.x = abs(attack_marker.position.x) * (1 if is_flipped else -1)

# --- Attack Logic ---
func _on_attack_timer_timeout() -> void:
	if is_active and player and not is_dying:
		perform_spit_attack()

# Inside Enemy2.gd - perform_spit_attack function
func perform_spit_attack() -> void:
	animated_sprite.play("attack")
	
	if spit_scene:
		var spit = spit_scene.instantiate()
		spit.global_position = attack_marker.global_position
		
		# Calculate straight-line direction toward player
		var shoot_dir = (player.global_position - global_position).normalized()
		
		# Add to the main stage so it doesn't move with the fly
		get_tree().current_scene.add_child(spit)
		
		# Pass direction and current enemy damage to the spit
		if spit.has_method("launch"):
			spit.launch(shoot_dir, damage)

# --- Damage & Death ---
func _on_visible_on_screen_notifier_screen_entered() -> void:
	is_active = true
	attack_timer.start()

func _on_visible_on_screen_notifier_screen_exited() -> void:
	is_active = false
	attack_timer.stop()

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying: return
	current_health -= amount
	flash_hurt()
	if attacker_pos != Vector2.ZERO:
		var knockback_dir = (global_position - attacker_pos).normalized()
		knockback_velocity = knockback_dir * knockback_strength 
	if current_health <= 0:
		die()

func flash_hurt() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color("8c8c8c")
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func die() -> void:
	is_dying = true
	is_active = false
	attack_timer.stop()
	velocity = Vector2.ZERO 
	collision_layer = 0
	collision_mask = 0
	$Hurtbox.queue_free()
	animated_sprite.play("death")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		_spawn_loot()

# --- Loot Implementation ---
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
		print(">>> LOOT COLLECTED: Attack +", attack_boost_amount)
	else:
		PlayerManager.add_health(heal_amount)
		print(">>> LOOT COLLECTED: Healed +", heal_amount)
