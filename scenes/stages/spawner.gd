extends Node2D

# --- Node References ---
# %EnemiesContainer should be an empty Node2D.
# %EnemyMarker1 should be a Marker2D OUTSIDE of the container.
@onready var enemies_container: Node2D = %EnemiesContainer
@onready var enemy_marker_1: Marker2D = %EnemyMarker1

# --- Configuration ---
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy_3.tscn")
@export var spawn_count: int = 5
@export var interval: float = 3.0

# Tracks the current valid session. Incrementing this "kills" old loops.
var current_spawn_session: int = 0

func _ready() -> void:
	# Initial validation to ensure the scene is set up correctly
	if not is_instance_valid(enemy_marker_1) or not is_instance_valid(enemies_container):
		print(">>> SPAWNER ERROR: Missing required nodes in _ready.")
		return

	# Connect to the global death signal
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(reset_spawner)

	start_spawn_enemy_marker_1()

# --- Reset Logic ---

func reset_spawner() -> void:
	# 1. Invalidate all currently running 'await' loops
	current_spawn_session += 1 
	print(">>> SPAWNER: Resetting to Session ", current_spawn_session)
	
	# 2. Delete all existing enemy instances
	clear_enemies()
	
	# 3. Restart the sequence
	respawn_all()

func clear_enemies() -> void:
	if is_instance_valid(enemies_container):
		for enemy in enemies_container.get_children():
			# Meticulous: Only children of the container are deleted. 
			# Since the marker is outside, it remains safe.
			enemy.queue_free()

func respawn_all() -> void:
	# A single frame delay allows the engine to register the deletions
	await get_tree().process_frame
	start_spawn_enemy_marker_1()

# --- Spawning Logic ---	

func start_spawn_enemy_marker_1() -> void:
	# Capture the ID of the session that started this loop
	var my_session = current_spawn_session
	
	print(">>> SPAWNER: Starting Session ", my_session)
	
	for i in range(spawn_count):
		# Meticulous Guard: If the session ID changed (due to a reset), kill this loop.
		if my_session != current_spawn_session:
			print(">>> SPAWNER: Stopping ghost loop from Session ", my_session)
			return
			
		# Ensure the marker still exists before accessing its position
		if not is_instance_valid(enemy_marker_1): 
			return
		
		spawn_enemy(enemy_marker_1.global_position)
		
		# Wait for the next interval
		await get_tree().create_timer(interval).timeout

func spawn_enemy(pos: Vector2) -> void:
	if not enemy_scene or not is_instance_valid(enemies_container): 
		return
	
	var new_enemy = enemy_scene.instantiate()
	new_enemy.global_position = pos
	
	# Use call_deferred to prevent errors during physics calculations
	enemies_container.add_child.call_deferred(new_enemy)
