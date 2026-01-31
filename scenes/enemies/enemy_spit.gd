extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 3.0 # Destroy if it misses

var direction: Vector2 = Vector2.ZERO
var damage: int = 0

func _ready() -> void:
	# Self-destruct timer to prevent infinite projectiles
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Move in a constant straight line
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
		# Rotate the sprite to face the direction of travel
		rotation = direction.angle()

# This is called by Enemy2 when the projectile is spawned
func launch(dir: Vector2, incoming_damage: int) -> void:
	direction = dir
	damage = incoming_damage

func _on_body_entered(body: Node2D) -> void:
	# Check if we hit the player
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Always destroy the projectile on impact
		queue_free()
	
	# Optional: Destroy if hitting walls/environment
	# if body is TileMap: queue_free()
