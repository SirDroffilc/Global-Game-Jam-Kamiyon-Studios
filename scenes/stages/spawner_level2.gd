extends Node2D

# --- Node References ---
@onready var enemies_container: Node2D = %EnemiesContainer
@onready var enemy_marker_1: Marker2D = %EnemyMarker1
@onready var enemy_marker_2: Marker2D = %EnemyMarker2
@onready var enemy_marker_3: Marker2D = %EnemyMarker3
@onready var enemy_marker_4: Marker2D = %EnemyMarker4
@onready var enemy_marker_5: Marker2D = %EnemyMarker5
@onready var enemy_marker_6: Marker2D = %EnemyMarker6
@onready var enemy_marker_7: Marker2D = %EnemyMarker7

# --- Configuration ---
@export_group("Enemy Scenes")
@export var enemy_1_scene: PackedScene = preload("res://scenes/enemies/enemy_1.tscn")
@export var enemy_2_scene: PackedScene = preload("res://scenes/enemies/enemy_2.tscn")
@export var enemy_3_scene: PackedScene = preload("res://scenes/enemies/enemy_3.tscn")
@export var enemy_4_scene: PackedScene = preload("res://scenes/enemies/enemy_4.tscn")

@export_group("Spawn Settings")
# Individual spawn counts for each enemy type
@export var enemy_1_count: int = 20
@export var enemy_2_count: int = 20
@export var enemy_3_count: int = 5
@export var enemy_4_count: int = 1

@export_group("Spawn Intervals")
@export var interval_fast: float = 8.0    # Enemy 1 & 2
@export var interval_medium: float = 30.0  # Enemy 3
@export var interval_slow: float = 120.0   # Enemy 4 (2 Minutes)

# Tracks the current valid session. Incrementing this "kills" old loops.
var current_spawn_session: int = 0

func _ready() -> void:
	# Validation
	var markers = [enemy_marker_1, enemy_marker_2, enemy_marker_3, enemy_marker_4]
	if markers.any(func(m): return not is_instance_valid(m)) or not is_instance_valid(enemies_container):
		print(">>> SPAWNER ERROR: Missing required nodes in _ready.")
		return

	# Connect to the global death signal
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(reset_spawner)

	start_all_spawners()

# --- Reset Logic ---

func reset_spawner() -> void:
	current_spawn_session += 1 
	print(">>> SPAWNER: Resetting to Session ", current_spawn_session)
	clear_enemies()
	respawn_all()

func clear_enemies() -> void:
	if is_instance_valid(enemies_container):
		for enemy in enemies_container.get_children():
			enemy.queue_free()

func respawn_all() -> void:
	await get_tree().process_frame
	start_all_spawners()

# --- Spawning Logic ---	

func start_all_spawners() -> void:
	# Meticulous Note: Now passing the specific counts for each loop
	run_spawn_loop(enemy_1_scene, enemy_1_count, interval_fast, enemy_marker_1, "Enemy 1")
	run_spawn_loop(enemy_2_scene, enemy_2_count, interval_fast, enemy_marker_2, "Enemy 2")
	run_spawn_loop(enemy_3_scene, enemy_3_count, interval_medium, enemy_marker_3, "Enemy 3")
	run_spawn_loop(enemy_4_scene, enemy_4_count, interval_slow, enemy_marker_4, "Enemy 4")
	run_spawn_loop(enemy_3_scene, 10, interval_medium, enemy_marker_5, "Enemy 1")
	run_spawn_loop(enemy_3_scene, 10, interval_medium, enemy_marker_6, "Enemy 2")
	run_spawn_loop(enemy_3_scene, 5, interval_medium, enemy_marker_7, "Enemy 3")

func run_spawn_loop(enemy_scene: PackedScene, count: int, interval: float, marker: Marker2D, debug_name: String) -> void:
	var my_session = current_spawn_session
	
	print(">>> SPAWNER: Starting loop for ", debug_name, " in Session ", my_session, " (Total Spawns: ", count, ")")
	
	# Using the specific count passed from start_all_spawners
	for i in range(count):
		# Wait for the interval
		await get_tree().create_timer(interval).timeout
		
		# GUARD: If the session changed (player died/reset), kill this specific loop.
		if my_session != current_spawn_session:
			return
			
		if not is_instance_valid(marker): 
			return
		
		spawn_enemy(enemy_scene, marker.global_position)

func spawn_enemy(scene: PackedScene, pos: Vector2) -> void:
	if not scene or not is_instance_valid(enemies_container): 
		return
	
	var new_enemy = scene.instantiate()
	new_enemy.global_position = pos
	enemies_container.add_child.call_deferred(new_enemy)
