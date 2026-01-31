extends CharacterBody2D

# --- Attributes ---
@export var base_health: int = 15
@onready var current_health: int = base_health

func _physics_process(delta: float) -> void:
	# Basic gravity so the enemy stays on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

# This function is called when the Player's attack hits the Hurtbox
func take_damage(amount: int) -> void:
	current_health -= amount
	print("Enemy hit! Health remaining: ", current_health)
	
	# Optional: Play a "hit" animation here
	# $AnimatedSprite.play("hit")
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Enemy defeated!")
	# You can play a death animation or spawn particles here before queue_free
	queue_free()
