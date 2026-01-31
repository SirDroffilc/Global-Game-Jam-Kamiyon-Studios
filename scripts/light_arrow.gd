extends Area2D

@export var speed: float = 600.0
@export var lifetime: float = 5.0 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = false # Arrow stays still during 'creation'

func _ready() -> void:
	# 1. Start the 'creation' animation sequence
	animated_sprite.play("creation")
	
	# 2. Connect the signal (AnimatedSprite2D version)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Cleanup timer
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# 3. Movement is locked until is_active is true
	if is_active:
		position += direction * speed * delta

func _on_animation_finished() -> void:
	# 4. Check which animation just ended
	if animated_sprite.animation == "creation":
		is_active = true
		animated_sprite.play("looping") # Switch to the looping flight frames

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().has_method("take_damage"):
		# Passing global_position for the enemy's knockback calculation
		area.get_parent().take_damage(PlayerManager.get_damage(), global_position)
		queue_free() 

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
