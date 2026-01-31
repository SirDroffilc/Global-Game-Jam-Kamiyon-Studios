extends Node

# --- Signals ---
signal health_changed(new_health: int)
signal player_died

# --- Attributes ---
var base_health: int = 100
var current_health: int = 100:
	set(value):
		current_health = clamp(value, 0, base_health)
		health_changed.emit(current_health)
		if current_health <= 0:
			player_died.emit()

var base_damage: int = 10
var speed: float = 150.0
var jump_velocity: float = -300.0
var consumption_timer_cooldown: float = 10.0

# --- Getters ---
func get_speed() -> float:
	return speed

func get_jump_velocity() -> float:
	return jump_velocity

func get_damage() -> int:
	return base_damage

func get_health() -> int:
	return current_health

# --- Setters & Logic ---
func subtract_health(amount: int) -> void:
	current_health -= amount

func add_health(amount: int) -> void:
	current_health += amount

func set_speed(new_speed: float) -> void:
	speed = new_speed

func set_jump_velocity(new_velocity: float) -> void:
	jump_velocity = new_velocity

# Inside PlayerManager.gd
func reset_health() -> void:
	current_health = base_health
	print(">>> PlayerManager: Health reset to ", current_health)
	
