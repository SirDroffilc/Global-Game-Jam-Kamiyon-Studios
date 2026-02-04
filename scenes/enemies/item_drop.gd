extends Area2D
class_name ItemDrop

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var velocity: Vector2 = Vector2.ZERO
var spawned := false
var is_on_floor := false

func _ready() -> void:
	play_animation()

func play_animation():
	animated_sprite.play("default")

func _physics_process(delta: float) -> void:
	if spawned and not is_on_floor:
		# Apply gravity
		velocity.y += gravity * delta
		position += velocity * delta
		
		# Meticulous Check: Raycast or simple check to stop at ground
		# For now, we will handle stopping via the Enemy script or a simple floor check
		_check_floor_collision()

func _check_floor_collision() -> void:
	# Using the overlapping bodies to see if we hit a TileMap or StaticBody
	for body in get_overlapping_bodies():
		if body is TileMap or body is StaticBody2D:
			is_on_floor = true
			velocity = Vector2.ZERO
