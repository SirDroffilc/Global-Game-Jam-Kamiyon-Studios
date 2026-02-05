extends Node2D

# --- Meticulous Scene References ---
@export var enemy1_scene: PackedScene = preload("res://scenes/enemies/enemy_1.tscn")
@export var enemy2_scene: PackedScene = preload("res://scenes/enemies/enemy_2.tscn")
@export var enemy3_scene: PackedScene = preload("res://scenes/enemies/enemy_3.tscn")

@onready var spawn_point: Marker2D = $SpawnPoint1
@onready var container: Node2D = get_tree().current_scene.find_child("DangerAreaEnemies", true, false)
@onready var door: TileMapLayer = $Door

# --- Persistence & Logic State ---
var is_resetting: bool = false
var is_cleared: bool = false # Stays true once the door is opened

func _ready() -> void:
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_player_died)
	
	# Only spawn if the area hasn't been cleared yet
	if not is_cleared:
		spawn_all()

func spawn_all():
	spawn_area_enemies(enemy1_scene, 4, 1.0)
	spawn_area_enemies(enemy2_scene, 7, 1.0)
	spawn_area_enemies(enemy3_scene, 5, 1.0)
	
func spawn_area_enemies(scene: PackedScene, count: int, interval: float) -> void:
	if not scene or not container or is_cleared:
		return
	
	is_resetting = false # Reset the flag at start of spawn
		
	for i in range(count):
		# Meticulous check: Stop spawning if player died during the interval
		if is_resetting: 
			return
			
		var enemy = scene.instantiate()
		container.add_child(enemy)
		
		# Connect to detect when the enemy is defeated
		enemy.tree_exited.connect(_check_area_cleared)
		
		enemy.global_position = spawn_point.global_position
		enemy.global_position.x += randf_range(-100, 100)
		
		if interval > 0:
			await get_tree().create_timer(interval).timeout

func _check_area_cleared() -> void:
	# Small delay to ensure the node is fully removed from the count
	await get_tree().process_frame
	
	# If this was the last enemy and we aren't currently resetting the level
	if not is_cleared and not is_resetting and container.get_child_count() == 0:
		_open_door()

func _open_door() -> void:
	is_cleared = true
	print(">>> AREA SPAWNER: Area Cleared! Opening Door...")
	
	# Smoothly move the door upward
	var tween = create_tween()
	tween.tween_property(door, "position:y", -64, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_player_died() -> void:
	# If the area is cleared, we don't reset or respawn anything here
	if is_cleared:
		return
		
	is_resetting = true
	
	# Clear existing enemies
	if container:
		for child in container.get_children():
			child.queue_free()
	
	_reset_spawn.call_deferred()

func _reset_spawn() -> void:
	# Wait for cleanup before spawning new wave
	await get_tree().create_timer(0.1).timeout
	spawn_all()
