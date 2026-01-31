extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 200
@onready var current_health: int = base_health

# --- Meticulous Knockback Variables ---
# Strength: Initial launch force. 150-200 is a good range for a "short" knockback.
@export var knockback_strength: float = 120.0 
# Friction: How fast it stops. 1500+ prevents the enemy from sliding too far.
@export var knockback_friction: float = 1800.0 

var knockback_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0 # Reset vertical velocity when grounded
	
	# 2. Handle Knockback Decay
	# move_toward ensures we hit exactly zero and stop sliding.
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	# 3. Combine Gravity/Movement with Knockback
	# We use a temporary variable so we don't permanently overwrite 'velocity'
	var total_velocity = velocity + knockback_velocity
	
	# 4. Execute Movement
	var old_vel = velocity
	velocity = total_velocity
	move_and_slide()
	velocity = old_vel

# Updated to accept attacker_pos to calculate directional force
func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	current_health -= amount
	print("Enemy hit! Health remaining: ", current_health)
	
	# Apply Knockback Logic
	if attacker_pos != Vector2.ZERO:
		# Calculate the horizontal direction away from the attacker
		var knockback_dir = (global_position - attacker_pos).normalized()
		
		# We set a small upward 'hop' (-0.1) to break floor friction
		var impact_vector = Vector2(knockback_dir.x, -0.1).normalized()
		knockback_velocity = impact_vector * knockback_strength 
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Enemy defeated!")
	# Standard practice: Play death animation here before queue_free
	queue_free()
