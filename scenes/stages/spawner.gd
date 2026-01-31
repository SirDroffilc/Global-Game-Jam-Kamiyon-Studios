extends Node2D

# 1. Use Unique Names (%) to prevent 'null instance' errors
@onready var enemies_container: Node2D = %EnemiesContainer
@onready var enemy_marker_1: Marker2D = %EnemyMarker1

# 2. Preload your Enemy scene
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy_2.tscn")

# --- Configuration ---
@export var spawn_count: int = 1
@export var interval: float = 3.0

func _ready() -> void:
	# Meticulous Null Check: If the marker is missing, stop before crashing
	if enemy_marker_1 == null:
		print(">>> ERROR: Spawner cannot find %EnemyMarker1. Check Unique Names!")
		return
		
	start_spawn_sequence()

func start_spawn_sequence() -> void:
	print(">>> SPAWNER: Starting sequence at ", enemy_marker_1.name)
	
	for i in range(spawn_count):
		# Now enemy_marker_1 is guaranteed to be valid
		spawn_enemy(enemy_marker_1.global_position)
		
		# Wait for the next interval
		await get_tree().create_timer(interval).timeout

func spawn_enemy(pos: Vector2) -> void:
	if not enemy_scene: return
	
	var new_enemy = enemy_scene.instantiate()
	new_enemy.global_position = pos
	
	# Use call_deferred to avoid physics flushing errors
	enemies_container.add_child.call_deferred(new_enemy)
	
	print(">>> SPAWNER: Enemy spawned successfully.")
