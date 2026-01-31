extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 5.0 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = false 

func _ready() -> void:
	animated_sprite.play("creation")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Cleanup timer
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if is_active:
		position += direction * speed * delta

func _on_animation_finished() -> void:
	if animated_sprite.animation == "creation":
		is_active = true
		animated_sprite.play("looping")

func _on_area_entered(area: Area2D) -> void:
	# 1. Meticulous Check: Only hit areas belonging to an Enemy
	# This prevents the arrow from vanishing when hitting ItemDrop areas.
	if area.is_in_group("Enemy") or area.get_parent().is_in_group("Enemy"):
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(PlayerManager.get_damage(), global_position)
		
		# Only vanish if we actually hit a valid target
		#print("area entered: ", area)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# 2. Meticulous Check: Ignore the Player
	if body.is_in_group("Player"):
		return
		
	# 3. Vanish if hitting the world/environment
	# This ensures arrows don't fly through walls.
	#print("body entered: ", body)
	queue_free()
