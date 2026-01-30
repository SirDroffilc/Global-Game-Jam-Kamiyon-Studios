extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 5.0 # Seconds before the arrow disappears

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Automatically destroy the arrow after a few seconds to save memory
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move in a straight line toward the target
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	# Check if we hit an enemy
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(PlayerManager.get_damage())
		queue_free() # Destroy arrow on hit

func _on_body_entered(_body: Node2D) -> void:
	# Destroy arrow if it hits a wall/tilemap
	queue_free()
